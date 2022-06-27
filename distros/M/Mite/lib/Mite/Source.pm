package Mite::Source;
use Mite::MyMoo;

=head1 NAME

Mite::Source - Representing the human written .pm file.

=head1 SYNOPSIS

    use Mite::Source;
    my $source = Mite::Source->new( file => $pm_filename );

=head1 DESCRIPTION

NO USER SERVICABLE PARTS INSIDE.  This is a private class.

Represents a .pm file, written by a human, which uses Mite.

It is responsible for information about the source file.

* The Mite classes contained in the source.
* The compiled Mite file associated with it.

It delegates most work to other classes.

This object is necessary because there can be multiple Mite classes in
one source file.

=head1 SEE ALSO

L<Mite::Class>, L<Mite::Compiled>, L<Mite::Project>

=cut

use Mite::Compiled;
use Mite::Class;

has file =>
  is            => ro,
  isa           => Path,
  coerce        => true,
  required      => true;

has classes =>
  is            => ro,
  isa           => HashRef[InstanceOf['Mite::Class']],
  default       => sub { {} };

has compiled =>
  is            => ro,
  isa           => InstanceOf['Mite::Compiled'],
  lazy          => true,
  default       => sub {
      my $self = shift;
      return Mite::Compiled->new( source => $self );
  };

has project =>
  is            => rw,
  isa           => InstanceOf['Mite::Project'],
  # avoid a circular dep with Mite::Project
  weak_ref      => true;

sub has_class {
    my ( $self, $name ) = ( shift, @_ );

    return defined $self->classes->{$name};
}

sub compile {
    my $self = shift;

    return $self->compiled->compile();
}

# Add an existing class instance to this source
sub add_classes {
    my ( $self, @classes ) = ( shift, @_ );

    for my $class (@classes) {
        $self->classes->{$class->name} = $class;
        $class->source($self);
    }

    return;
}

# Create or reuse a class instance for this source give a name
sub class_for {
    my ( $self, $name ) = ( shift, @_ );

    return $self->classes->{$name} ||= Mite::Class->new(
        name    => $name,
        source  => $self,
    );
}

1;
