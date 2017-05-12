package Mite::Class;

use feature ':5.10';
use Mouse;
use Mouse::Util::TypeConstraints;
use Method::Signatures;
use Path::Tiny;
use Carp;
use mro;

class_type "Path::Tiny";

has attributes =>
  is            => 'ro',
  isa           => 'HashRef[Mite::Attribute]',
  default       => sub { {} };

# Super classes as class names
has extends =>
  is            => 'rw',
  isa           => 'ArrayRef[Str]',
  default       => sub { [] },
  trigger       => method(...) {
      # Set up our @ISA so we can use mro to calculate the class hierarchy
      $self->_set_isa;

      # Allow $self->parents to recalculate itself
      $self->_clear_parents;
  };

# Super classes as Mite::Classes populated from $self->extends
has parents =>
  is            => 'ro',
  isa           => 'ArrayRef[Mite::Class]',
  # Build on demand to allow the project to load all the classes first
  lazy          => 1,
  builder       => '_build_parents',
  clearer       => '_clear_parents';

has name =>
  is            => 'ro',
  isa           => 'Str',
  required      => 1;

has source =>
  is            => 'rw',
  isa           => 'Mite::Source',
  # avoid a circular dep with Mite::Source
  weak_ref      => 1;

method project() {
    return $self->source->project;
}

method class($name) {
    return $self->project->class($name);
}

method _set_isa {
    my $name = $self->name;

    mro::set_mro($name, "c3");
    no strict 'refs';
    @{$name.'::ISA'} = @{$self->extends};

    return;
}

method get_isa() {
    my $name = $self->name;

    no strict 'refs';
    return @{$name.'::ISA'};
}

method linear_isa() {
    return @{mro::get_linear_isa($self->name)};
}

method linear_parents() {
    my $project = $self->project;

    return map { $project->class($_) } $self->linear_isa;
}

method chained_attributes(@classes) {
    my %attributes;
    for my $class (reverse @classes) {
        for my $attribute (values %{$class->attributes}) {
            $attributes{$attribute->name} = $attribute;
        }
    }

    return \%attributes;
}

method all_attributes() {
    return $self->chained_attributes($self->linear_parents);
}

method parents_attributes() {
    my @parents = $self->linear_parents;
    shift @parents;  # remove ourselves from the inheritance list
    return $self->chained_attributes(@parents);
}

method _build_parents {
    my $extends = $self->extends;
    return [] if !@$extends;

    # Load each parent and store its Mite::Class
    my @parents;
    for my $parent_name (@$extends) {
        push @parents, $self->_get_parent($parent_name);
    }

    return \@parents;
}

method _get_parent($parent_name) {
    my $project = $self->project;

    # See if it's already loaded
    my $parent = $project->class($parent_name);
    return $parent if $parent;

    # If not, try to load it
    require $parent;
    $parent = $project->class($parent_name);
    return $parent if $parent;

    croak <<"ERROR";
$parent loaded but is not a Mite class.
Extending non-Mite classes not yet supported.
Sorry.
ERROR
}

method add_attributes(Mite::Attribute @attributes) {
    for my $attribute (@attributes) {
        $self->attributes->{ $attribute->name } = $attribute;
    }

    return;
}
{
    no warnings 'once';
    *add_attribute = \&add_attributes;
}


method extend_attribute(%attr_args) {
    my $name = delete $attr_args{name};

    my $parent_attr = $self->parents_attributes->{$name};
    croak(sprintf <<'ERROR', $name, $self->name) unless $parent_attr;
Could not find an attribute by the name of '%s' to inherit from in %s
ERROR

    $self->add_attribute($parent_attr->clone(%attr_args));

    return;
}


method compile() {
    return join "\n", '{',
                      $self->_compile_package,
                      $self->_compile_pragmas,
                      $self->_compile_extends,
                      $self->_compile_new,
                      $self->_compile_attributes,
                      '1;',
                      '}';
}

method _compile_package {
    return "package @{[ $self->name ]};";
}

method _compile_pragmas {
    return <<'CODE';
use strict;
use warnings;
CODE
}

method _compile_extends() {
    my $extends = $self->extends;
    return '' unless @$extends;

    my $source = $self->source;

    my $require_list = join "\n\t",
                            map  { "require $_;" }
                            # Don't require a class from the same source
                            grep { !$source || !$source->has_class($_) }
                            @$extends;

    my $isa_list     = join ", ", map { "q[$_]" } @$extends;

    return <<"END";
BEGIN {
    $require_list

    use mro 'c3';
    our \@ISA;
    push \@ISA, $isa_list;
}
END
}

method _compile_bless() {
    return 'bless \%args, $class';
}

method _compile_new() {
    return sprintf <<'CODE', $self->_compile_bless, $self->_compile_defaults;
sub new {
    my $class = shift;
    my %%args  = @_;

    my $self = %s;

    %s

    return $self;
}
CODE
}

method _compile_undef_default($attribute) {
    return sprintf '$self->{%s} //= undef;', $attribute->name;
}

method _compile_simple_default($attribute) {
    return $self->_compile_undef_default($attribute) if !defined $attribute->default;
    return sprintf '$self->{%s} //= q[%s];', $attribute->name, $attribute->default;
}

method _compile_coderef_default($attribute) {
    my $var = $attribute->coderef_default_variable;

    return sprintf 'our %s; $self->{%s} //= %s->(\$self);',
      $var, $attribute->name, $var;
}

method _compile_defaults {
    my @simple_defaults = map { $self->_compile_simple_default($_) }
                              $self->_attributes_with_simple_defaults;
    my @coderef_defaults = map { $self->_compile_coderef_default($_) }
                               $self->_attributes_with_coderef_defaults;

    return join "\n", @simple_defaults, @coderef_defaults;
}

method _attributes_with_defaults() {
    return grep { $_->has_default } values %{$self->all_attributes};
}

method _attributes_with_simple_defaults() {
    return grep { $_->has_simple_default } values %{$self->all_attributes};
}

method _attributes_with_coderef_defaults() {
    return grep { $_->has_coderef_default } values %{$self->all_attributes};
}

method _attributes_with_dataref_defaults() {
    return grep { $_->has_dataref_default } values %{$self->all_attributes};
}

method _compile_attributes() {
    my $code = '';
    for my $attribute (values %{$self->all_attributes}) {
        $code .= $attribute->compile;
    }

    return $code;
}

1;
