package Mite::Source;

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

use feature ':5.10';
use Mouse;
use Mite::Types;

use Mite::Compiled;
use Mite::Class;
use Method::Signatures;

has file =>
  is            => 'ro',
  isa           => 'Path',
  coerce        => 1,
  required      => 1;

has classes =>
  is            => 'ro',
  isa           => 'HashRef[Mite::Class]',
  default       => sub { {} };

has compiled =>
  is            => 'ro',
  isa           => 'Mite::Compiled',
  lazy          => 1,
  default       => method {
      return Mite::Compiled->new( source => $self );
  };

has project =>
  is            => 'rw',
  isa           => 'Mite::Project',
  # avoid a circular dep with Mite::Project
  weak_ref      => 1;

method has_class($name) {
    return defined $self->classes->{$name};
}

method compile() {
    return $self->compiled->compile();
}

# Add an existing class instance to this source
method add_classes(@classes) {
    for my $class (@classes) {
        $self->classes->{$class->name} = $class;
        $class->source($self);
    }

    return;
}

# Create or reuse a class instance for this source give a name
method class_for($name) {
    return $self->classes->{$name} ||= Mite::Class->new(
        name    => $name,
        source  => $self,
    );
}

1;
