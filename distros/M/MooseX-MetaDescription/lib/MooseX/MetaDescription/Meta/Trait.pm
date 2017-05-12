package MooseX::MetaDescription::Meta::Trait;
use Moose::Role;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

has 'description' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
);

has 'metadescription_classname' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        'MooseX::MetaDescription::Description'
    }
);

has 'metadescription' => (
    is      => 'ro',
    isa     => 'MooseX::MetaDescription::Description',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $metadesc_class = $self->metadescription_classname;
        my $desc           = $self->description;

        Class::MOP::load_class($metadesc_class);

        if (my $traits = delete $desc->{traits}) {
            my $meta = Moose::Meta::Class->create_anon_class(
                superclasses => [ $metadesc_class ],
                roles        => $self->prepare_traits_for_application($traits),
            );
            $meta->add_method('meta' => sub { $meta });
            $metadesc_class = $meta->name;
        }

        return $metadesc_class->new(%$desc, descriptor => $self);
    },
);

# this is for the subclasses to use ...
sub prepare_traits_for_application { $_[1] }

no Moose::Role; 1;

__END__

=pod

=head1 NAME

MooseX::MetaDescription::Meta::Trait - Custom class meta-trait for meta-descriptions

=head1 SYNOPSIS

  package Foo;
  use Moose;

  has 'baz' => (
      # apply this as a trait to your attribute
      traits      => [ 'MooseX::MetaDescription::Meta::Trait' ],
      is          => 'ro',
      isa         => 'Str',
      default     => sub { 'Foo::baz' },
      description => {
          bar   => 'Foo::baz::bar',
          gorch => 'Foo::baz::gorch',
      }
  );

=head1 DESCRIPTION

This is the core of the Meta Description functionality, it is a role that is done
by both L<MooseX::MetaDescription::Meta::Attribute> and L<MooseX::MetaDescription::Meta::Class>
and can be used on it's own as a meta-attribute trait.

=head1 METHODS

=over 4

=item B<description>

The description C<HASH> ref is stored here.

=item B<metadescription_classname>

This provides the name of the metadescription class, currently this
defaults to L<MooseX::MetaDescription::Description>. It is read only
and so can only be specified at instance construction time.

=item B<metadescription>

This is the instance of the class specified in C<metadescription_classname>
it is generated lazily and is also read-only. In general you will never
need to set this yourself, but simply set C<metadescription_classname>
and it will all just work.

=item B<prepare_traits_for_application ($traits)>

This is passed the ARRAY ref of trait names so that they can be pre-processed
before they are applied to the metadescription. It is expected to return
an ARRAY ref of trait names to be applied. By default it simply returns what
it is given.

=item B<meta>

The L<Moose::Role> metaclass.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
