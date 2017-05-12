package MooseX::Traits::Pluggable;
{
  $MooseX::Traits::Pluggable::VERSION = '0.12';
}

use namespace::autoclean;
use Moose::Role;
use Scalar::Util qw/blessed reftype/;
use List::MoreUtils 'uniq';
use Carp;
use Moose::Util qw/find_meta/;
use Class::Load qw();

our $AUTHORITY = 'id:RKITOVER';

# stolen from MX::Object::Pluggable
has _original_class_name => (
  is => 'ro',
  required => 1,
  isa => 'Str',
  default => sub { blessed $_[0] },
);

has '_trait_namespace' => (
  # no accessors or init_arg
  init_arg => undef,
  (Moose->VERSION >= 0.84 ) ? (is => 'bare') : (),
);

has '_traits_behave_like_roles' => (
  init_arg => undef,
  (Moose->VERSION >= 0.84 ) ? (is => 'bare') : (),
);

has _traits => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub { [] },
);

has _resolved_traits => (
  is => 'ro',
  isa => 'ArrayRef[ClassName]',
  default => sub { [] },
);

sub _find_trait {
    my ($class, $base, $name) = @_;

    my @search_ns = $class->meta->class_precedence_list;

    for my $ns (@search_ns) {
        my $full = "${ns}::${base}::${name}";
        return $full if eval { Class::Load::load_class($full) };
    }

    croak "Could not find a class for trait: $name";
}

my $config_val = sub {
    my ($class, $attr, @args) = @_;

    my $val;

    if ($class->can($attr)) {
        $val = $class->$attr(@args);
    }
    else {
        my $attr_inst = find_meta($class)->find_attribute_by_name($attr);
        if($attr_inst->has_default) {
            $val = $attr_inst->default;
            if (ref($val) && reftype($val) eq 'CODE') {
                $val = $class->$val(@args);
            }
        }
    }

    return $val;
};

sub _transform_trait {
    my ($class, $name) = @_;

    my $base = $config_val->($class, '_trait_namespace', $name);

    return $name unless $base;
    return $1 if $name =~ /^[+](.+)$/;

    $base = [ $base ] if !ref($base) || reftype($base) ne 'ARRAY';

    for my $ns (@$base) {
        if ($ns =~ /^\+(.*)/) {
            my $trait = eval { $class->_find_trait($1, $name) };
            return $trait if defined $trait;
        }

        my $trait = join '::', $ns, $name;
        return $trait if eval { Class::Load::load_class($trait) };
    }

    croak "Could not find a class for trait: $name";
}

sub _resolve_traits {
    my ($class, @traits) = @_;

    return map {
        my $transformed = $class->_transform_trait($_);
        Class::Load::load_class($transformed);
        $transformed;
    } @traits;
}

sub new_with_traits {
    my $class = shift;
    $class->_build_instance_with_traits($class, @_);
}

my $remove_role_methods_conflicting_with_class = sub {
    my ($meta, $orig_class, $resolved_traits) = @_;

    my %class_methods;
    @class_methods{ $orig_class->meta->get_method_list } = ();
    
    delete $class_methods{meta};

    my %trait_methods;
    foreach my $trait (@$resolved_traits) {
        @trait_methods{ $trait->meta->get_method_list } = ();
    }

    delete $trait_methods{meta};

    foreach my $class_method (keys %class_methods) {
        $meta->remove_method($class_method) if exists $trait_methods{$class_method};
    }
};

sub _build_instance_with_traits {
    my ($this_class, $class) = (shift, shift);
    my ($hashref, %args, @others) = 0;
    if (ref($_[-1]) eq 'HASH') {
        %args    = %{ +pop };
        @others  = @_;
        $hashref = 1;
    } else {
        %args    = @_;
    }

    $args{_original_class_name} = $class;

    if (my $traits = delete $args{traits}) {
        my @traits = ref($traits) ? @$traits : ($traits);

        if (@traits) {
            $args{_traits} = \@traits;
            my @resolved_traits = $this_class->_resolve_traits(@traits);
            $args{_resolved_traits} = \@resolved_traits;

            my $meta = $class->meta->create_anon_class(
                superclasses => [ $class->meta->name ],
                roles        => \@resolved_traits,
                cache        => 1,
            );

            # Method attributes in inherited roles may have turned metaclass
            # to lies. CatalystX::Component::Traits related special move
            # to deal with this here.
            $meta = find_meta($meta->name);

            $meta->add_method('meta' => sub { $meta });
            my $orig_class = $class;
            $class = $meta->name;

            if ($config_val->($orig_class, '_traits_behave_like_roles')) {
                $remove_role_methods_conflicting_with_class->($meta, $orig_class, \@resolved_traits);
            }
        }
    }

    my $constructor = $class->meta->constructor_name;
    confess "$class does not have a constructor defined via the MOP?"
      if !$constructor;

    return $class->$constructor($hashref ? (@others, \%args) : %args);
}

sub apply_traits {
    my ($self, $traits, $rebless_params) = @_;

    my @traits = ref($traits) ? @$traits : ($traits);

    if (@traits) {
        my @resolved_traits = $self->_resolve_traits(@traits);

        $rebless_params ||= {};

        $rebless_params->{_traits} = [ uniq @{ $self->_traits }, @traits ];
        $rebless_params->{_resolved_traits} = [
            uniq @{ $self->_resolved_traits }, @resolved_traits
        ];

        for my $trait (@resolved_traits){
            $trait->meta->apply($self, rebless_params => $rebless_params);
        }

        my $orig_class = $self->_original_class_name;

        if ($config_val->($orig_class, '_traits_behave_like_roles')) {
            $remove_role_methods_conflicting_with_class->($self->meta, $orig_class, \@resolved_traits);
        }
    }
}

no Moose::Role;

1;

__END__

=head1 NAME

MooseX::Traits::Pluggable - trait loading and resolution for Moose

=head1 DESCRIPTION

See L<MooseX::Traits> for usage information.

Use C<new_with_traits> to construct an object with a list of traits and
C<apply_traits> to apply traits to an instance.

Adds support for class precedence search for traits and some extra attributes,
described below.

=head1 TRAIT SEARCH

If the value of L<MooseX::Traits/_trait_namespace> starts with a C<+> the
namespace will be considered relative to the C<class_precedence_list> (ie.
C<@ISA>) of the original class.

Example:

  package Class1
  use Moose;

  package Class1::Trait::Foo;
  use Moose::Role;
  has 'bar' => (
      is       => 'ro',
      isa      => 'Str',
      required => 1,
  );

  package Class2;
  use parent 'Class1';
  with 'MooseX::Traits';
  has '+_trait_namespace' => (default => '+Trait');
  has '+_traits_behave_like_roles' => (default => 1);

  package Class2::Trait::Bar;
  use Moose::Role;
  has 'baz' => (
      is       => 'ro',
      isa      => 'Str',
      required => 1,
  );

  package main;
  my $instance = Class2->new_with_traits(
      traits => ['Foo', 'Bar'],
      bar => 'baz',
      baz => 'quux',
  );

  $instance->does('Class1::Trait::Foo'); # true
  $instance->does('Class2::Trait::Bar'); # true

=head1 NAMESPACE ARRAYS

You can search multiple namespaces for traits, for example:

  has '+_trait_namespace' => (
      default => sub { [qw/+Trait +Role ExtraNS::Trait/] }
  );

Will search in the C<class_precedence_list> for C<::Trait::TheTrait>
and C<::Role::TheTrait> and then for C<ExtraNS::Trait::TheTrait>.

=head1 CORRECT ROLE BEHAVIOR

By default, a method from a role will override a class method, this however is
not the behavior one expects when applying a L<Moose> role using the normal
methods.

If you want the behavior to be consistent with L<Moose> L<roles|Moose::Role>,
then use this configuration attribute in your class:

  has '+_traits_behave_like_roles' => (default => 1);

This may or may not become the default in the future, for now you have to ask
for it for backward compatibility reasons.

=head1 EXTRA ATTRIBUTES

=head2 _original_class_name

When traits are applied to your class or instance, you get an anonymous class
back whose name will be not the same as your original class. So C<ref $self>
will not be C<Class>, but C<< $self->_original_class_name >> will be.

=head2 _traits

List of the (unresolved) traits applied to the instance.

=head2 _resolved_traits

List of traits applied to the instance resolved to full package names.

=head1 SEE ALSO

L<MooseX::Traits>, L<MooseX::Object::Pluggable>, L<CatalystX::Component::Traits>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-traits-pluggable at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Traits-Pluggable>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 AUTHOR

Rafael Kitover C<< <rkitover@cpan.org> >>

=head1 CONTRIBUTORS

Tomas Doran, C<< <bobtfish@bobtfish.net> >>
Fitz Elliott, C<< <fitz.elliott@gmail.com> >>
Andreas Marienborg, C<< <andreas.marienborg@gmail.com> >>
Alexander Hartmaier, C<< <abraxxa@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2014 by the aforementioned L</AUTHOR> and L</CONTRIBUTORS>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
