package Mite::Compiled;

=head1 NAME

Mite::Compiled - The extra class file written by Mite.

=head1 SYNOPSIS

    use Mite::Compiled;
    my $compiled = Mite::Compiled->new( source => $source );

=head1 DESCRIPTION

NO USER SERVICABLE PARTS INSIDE.  This is a private class.

Represents the extra file written by Mite containing the compiled code.

There is a one-to-one mapping between a source file and a compiled
file, but there can be many Mite classes in one file.  Mite::Compiled
manages the compliation and ensures classes don't write over each
other.

=head1 SEE ALSO

L<Mite::Source>, L<Mite::Class>, L<Mite::Project>

=cut

use feature ':5.10';
use Mouse;
use Mite::Types;

# Don't load Mite::Source else it will go circular
use Method::Signatures;
use Path::Tiny;

use Mouse::Util::TypeConstraints;
class_type 'Path::Tiny';

has file =>
  is            => 'ro',
  isa           => 'Path',
  coerce        => 1,
  lazy          => 1,
  default       => method {
      return $self->_source_file2compiled_file( $self->source->file );
  };

has source =>
  is            => 'ro',
  isa           => 'Mite::Source',
  # avoid a circular dep with Mite::Source
  weak_ref      => 1,
  required      => 1;

method compile() {
    my $code;
    for my $class (values %{$self->classes}) {
        $code .= $class->compile;
    }

    return $code;
}

method write() {
    return $self->file->spew_utf8($self->compile);
}

method remove() {
    return $self->file->remove;
}

method classes() {
    return $self->source->classes;
}

method _source_file2compiled_file(Defined $source_file) {
    # Changes here must be coordinated with Mite.pm
    return $source_file . '.mite.pm';
}

1;
