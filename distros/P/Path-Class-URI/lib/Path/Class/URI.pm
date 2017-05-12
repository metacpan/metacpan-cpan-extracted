package Path::Class::URI;

use strict;
use 5.008_001;
our $VERSION = '0.08';

use URI;
use URI::file;
use Exporter::Lite;
use Path::Class;
use Scalar::Util qw(blessed);
use URI::Escape;

our @EXPORT = qw( file_from_uri dir_from_uri );

sub file_from_uri {
    Path::Class::File->from_uri(shift);
}

sub dir_from_uri {
    Path::Class::Dir->from_uri(shift);
}

sub Path::Class::Entity::uri {
    my $self = shift;
    my $escaped_self = $self->new( map { uri_escape($_) } $self->components );
    # escape the components so that URI can see them as path segments
    my $path = $escaped_self->stringify;
    $path =~ tr!\\!/! if $^O eq "MSWin32";
    $path .= '/' if $self->isa('Path::Class::Dir'); # preserve directory if used as base URI
    if ($self->is_absolute) {
        return URI->new("file://$path");
    } else {
        return URI->new("file:$path");
    }
}

sub Path::Class::Entity::from_uri {
    my($class, $uri) = @_;
    $uri = URI->new($uri) unless blessed $uri;;
    $class->new( $uri->file('unix') );
}

1;
__END__

=encoding utf-8

=for stopwords deserializes uri filename UTF-8

=head1 NAME

Path::Class::URI - Serializes and deserializes Path::Class objects as file:// URI

=head1 SYNOPSIS

  use Path::Class;
  use Path::Class::URI;

  my $file = file('bob', 'john.txt');
  my $uri  = $file->uri; # file:bob/john.txt

  file('', 'tmp', 'bar.txt')->uri; # file:///tmp/bar.txt

  my $file = file_from_uri("file:///tmp/bar.txt"); # or URI::file object
  $fh = $file->open;

=head1 DESCRIPTION

Path::Class::URI is an extension to Path::Class to serialize file path
from and to I<file://> form URI objects.

This module encodes and decodes non URI-safe characters using its
literal byte encodings. If you call I<uri> methods on Win32 Path::File
objects, you'll get local filename encodings.

If you want to avoid that and always use UTF-8 filename encodings in
URI, see L<Path::Class::Unicode> bundled in this distribution.

=head1 METHODS

=over 4

=item uri (Path::Class::Entity)

  $uri = $file->uri;
  $uri = $dir->uri;

returns URI object representing Path::Class file and directory.

=item from_uri (Path::Class::Entity)

  $file = Path::Class::File->from_uri($uri);
  $dir  = Path::Class::Dir->from_uri($uri);

Deserializes URI object (or string) into Path::Class objects.

=item file_from_uri, dir_from_uri

Shortcuts for those I<from_uri> methods. Exported by default.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Path::Class>, L<URI::file>

=cut
