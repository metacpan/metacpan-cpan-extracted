package Mite::Class;
use Mite::MyMoo;

use Path::Tiny;
use mro;

has attributes =>
  is            => ro,
  isa           => HashRef[InstanceOf['Mite::Attribute']],
  default       => sub { {} };

# Super classes as class names
has extends =>
  is            => rw,
  isa           => ArrayRef[Str],
  default       => sub { [] },
  trigger       => sub {
      my $self = shift;

      # Set up our @ISA so we can use mro to calculate the class hierarchy
      $self->_set_isa;

      # Allow $self->parents to recalculate itself
      $self->_clear_parents;
  };

# Super classes as Mite::Classes populated from $self->extends
has parents =>
  is            => ro,
  isa           => ArrayRef[InstanceOf['Mite::Class']],
  # Build on demand to allow the project to load all the classes first
  lazy          => true,
  builder       => '_build_parents',
  clearer       => '_clear_parents';

has name =>
  is            => ro,
  isa           => Str,
  required      => true;

has source =>
  is            => rw,
  isa           => InstanceOf['Mite::Source'],
  # avoid a circular dep with Mite::Source
  weak_ref      => true;

sub project {
    my $self = shift;

    return $self->source->project;
}

sub class {
    my ( $self, $name ) = ( shift, @_ );

    return $self->project->class($name);
}

sub _set_isa {
    my $self = shift;

    my $name = $self->name;

    mro::set_mro($name, "c3");
    no strict 'refs';
    @{$name.'::ISA'} = @{$self->extends};

    return;
}

sub get_isa {
    my $self = shift;

    my $name = $self->name;

    no strict 'refs';
    return @{$name.'::ISA'};
}

sub linear_isa {
    my $self = shift;

    return @{mro::get_linear_isa($self->name)};
}

sub linear_parents {
    my $self = shift;

    my $project = $self->project;

    return map { $project->class($_) } $self->linear_isa;
}

sub chained_attributes {
    my ( $self, @classes ) = ( shift, @_ );

    my %attributes;
    for my $class (reverse @classes) {
        for my $attribute (values %{$class->attributes}) {
            $attributes{$attribute->name} = $attribute;
        }
    }

    return \%attributes;
}

sub all_attributes {
    my $self = shift;

    return $self->chained_attributes($self->linear_parents);
}

sub parents_attributes {
    my $self = shift;

    my @parents = $self->linear_parents;
    shift @parents;  # remove ourselves from the inheritance list
    return $self->chained_attributes(@parents);
}

sub _build_parents {
    my $self = shift;

    my $extends = $self->extends;
    return [] if !@$extends;

    # Load each parent and store its Mite::Class
    my @parents;
    for my $parent_name (@$extends) {
        push @parents, $self->_get_parent($parent_name);
    }

    return \@parents;
}

sub _get_parent {
    my ( $self, $parent_name ) = ( shift, @_ );

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

sub add_attributes {
    state $sig = sig_pos( Object, slurpy ArrayRef[InstanceOf['Mite::Attribute']] );
    my ( $self, $attributes ) = &$sig;

    for my $attribute (@$attributes) {
        $self->attributes->{ $attribute->name } = $attribute;
    }

    return;
}

sub add_attribute {
    shift->add_attributes( @_ );
}


sub extend_attribute {
    my ($self, %attr_args) = ( shift, @_ );

    my $name = delete $attr_args{name};

    my $parent_attr = $self->parents_attributes->{$name};
    croak(sprintf <<'ERROR', $name, $self->name) unless $parent_attr;
Could not find an attribute by the name of '%s' to inherit from in %s
ERROR

    $self->add_attribute($parent_attr->clone(%attr_args));

    return;
}


sub compile {
    my $self = shift;

    my $code = join "\n", '{',
                      $self->_compile_package,
                      $self->_compile_pragmas,
                      $self->_compile_extends,
                      $self->_compile_new,
                      $self->_compile_buildall_method,
                      $self->_compile_meta_method,
                      $self->_compile_attribute_accessors,
                      '1;',
                      '}';
    #::diag $code;
    return $code;
}

sub _compile_package {
    my $self = shift;

    return "package @{[ $self->name ]};";
}

sub _compile_pragmas {
    my $self = shift;

    return <<'CODE';
use strict;
use warnings;
CODE
}

sub _compile_extends {
    my $self = shift;

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

sub _compile_bless {
    my ( $self, $classvar, $selfvar, $argvar, $metavar ) = @_;

    return "bless {}, $classvar";
}

sub _compile_strict_constructor {
    my ( $self, $classvar, $selfvar, $argvar, $metavar ) = @_;
    my $check = Enum->of( keys %{ $self->all_attributes } )->inline_check( '$_' );

    return sprintf 'my @unknown = grep not( %s ), keys %%{%s}; @unknown and require Carp and Carp::croak("Unexpected keys in constructor: " . join(q[, ], sort @unknown));',
        $check, $argvar;
}

sub _compile_new {
    my $self = shift;
    my @vars = ('$class', '$self', '$args', '$meta');

    return sprintf <<'CODE', $self->_compile_meta(@vars), $self->_compile_bless(@vars), $self->_compile_buildargs(@vars), $self->_compile_init_attributes(@vars), $self->_compile_strict_constructor(@vars), $self->_compile_buildall(@vars, '$no_build');
sub new {
    my $class = shift;
    my $meta  = %s;
    my $self  = %s;
    my $args  = %s;
    my $no_build = delete $args->{__no_BUILD__};

    # Initialize attributes
    %s

    # Enforce strict constructor
    %s

    # Call BUILD methods
    %s

    return $self;
}
CODE
}

sub _compile_buildargs {
    my ( $self, $classvar, $selfvar, $argvar, $metavar ) = @_;
    return sprintf '%s->{HAS_BUILDARGS} ? %s->BUILDARGS( @_ ) : { ( @_ == 1 ) ? %%{$_[0]} : @_ }',
        $metavar, $classvar;
}

sub _compile_buildall {
    my ( $self, $classvar, $selfvar, $argvar, $metavar, $nobuildvar ) = @_;
    return sprintf '!%s and @{%s->{BUILD}||[]} and %s->BUILDALL(%s);',
        $nobuildvar, $metavar, $selfvar, $argvar;
}

sub _compile_buildall_method {
    my $self;
    return <<'CODE';
sub BUILDALL {
    $_->(@_) for @{ $Mite::META{ref($_[0])}{BUILD} || [] };
}
CODE
}

sub _compile_meta {
    my ( $self, $classvar, $selfvar, $argvar, $metavar ) = @_;
    return sprintf '( $Mite::META{%s} ||= %s->__META__ )',
        $classvar, $classvar;
}

sub _compile_meta_method {
    return <<'CODE';
sub __META__ {
    no strict 'refs';
    require mro;
    my $class = shift;
    my $linear_isa = mro::get_linear_isa( $class );
    return {
        BUILD => [
            map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
            map { "$_\::BUILD" } reverse @$linear_isa
        ],
        DEMOLISH => [
            map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
            map { "$_\::DEMOLISH" } reverse @$linear_isa
        ],
        HAS_BUILDARGS => $class->can('BUILDARGS'),
    };
}
CODE
}

sub _compile_init_attributes {
    my ( $self, $classvar, $selfvar, $argvar, $metavar ) = @_;

    my @code;
    my $attributes = $self->all_attributes;
    for my $name ( sort keys %$attributes ) {
        push @code, $attributes->{$name}->compile_init( $selfvar, $argvar );
    }

    return join "\n    ", @code;
}

sub _compile_attribute_accessors {
    my $self = shift;

    my $attributes = $self->attributes;
    keys %$attributes or return '';

    my $code = 'my $__XS = !$ENV{MITE_PURE_PERL} && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };' . "\n\n";
    for my $name ( sort keys %$attributes ) {
        $code .= $attributes->{$name}->compile( xs_condition => '$__XS' );
    }

    return $code;
}

1;
