##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::MimeType - analyze and normalize mimetypes and extensions

=head1 SYNOPSIS

 use PApp::MimeType;

 my $mt = (PApp::MimeType::by_extension "jpg")->mimetype;

=head1 DESCRIPTION

Looks up mime types and file extensions, and gives hints which file
extension would be most commonly used.

All mimetypes and extensions returned by this module are
in lowercase. Matches done by this module are done in a
case-independent-manner.

=cut

package PApp::MimeType;

use base Exporter;

$VERSION = 2.2;
@EXPORT_OK = qw(by_extension by_filename by_mimetype clear_mimedb load_mimedb);

my %by_extension;
my %by_mimetype;

=head2 Lookup Functions

These functions look up (existing) mimetype objects and return it. Watch
out, they are not constructors, so either import them to your namespace or
call them like functions (C<PApp::MimeType::by_extension>).

=over 4

=item PApp::MimeType::by_extension $file_extension

Return a C<PApp::MimeType> object by guessing from the file extension
(leading dots are stripped). If no entry could be found for that specific
extension, returns undef.

To get a guarenteed mimetype for any file, use something like this:

   my $content_type =
      (PApp::MimeType::by_extension $ext
          or PApp::MimeType::by_mimetype "application/octet-stream")
      ->mimetype;

=item PApp::MimeType::by_filename $path

Like C<extension>, but strips the filename part away first.

=item PApp::MimeType::by_mimetype $mimetype

Return a C<PApp::MimeType> object by it's mimetype (e.g.
"image/jpeg"). Return C<undef> if none could be found.

=cut

sub by_extension($) {
   my $ext = lc $_[0];

   %by_extension || load_mimedb();

   while () {
      $by_extension{$ext} and return $by_extension{$ext};
      $ext =~ s/^[^.]*\.// or return ();
   }
}

sub by_filename($) {
   my $path = $_[0];

   by_extension +($path =~ /\.([^\/\\]+)$/ ? $1 : $path);
}

sub by_mimetype($) {
   my $mimetype = lc $_[0];

   %by_mimetype || load_mimedb();
   $by_mimetype{$mimetype};
}

=back

=head2 Methods

C<PApp::MimeType> objects are immutable, and support a number of methods.

=over 4

=item $type = $mt->mimetype

Return the normalized mimetype as a string (e.g. "image/pjpeg" objects
would return "image/jpeg").

=item @types = $mt->mimetypes

Return all possible matching mimetypes. The default (suggested) mimetype
is returned first.

=item $extension = $mt->extension

Return the default extension to use (the most common one) for this mimetype.

=item @extensions = $mt->extensions

Return all extensions possibly used by this mimetype, with more common
ones first.

=cut

sub mimetype($) {
   $_[0][0][0];
}

sub mimetypes($) {
   $_[0][0];
}

sub extension($) {
   $_[0][1][0];
}

sub extensions($) {
   $_[0][1];
}

=back

=head2 Database Functions

The mime database is initialized on demand form a default file. If you
want to overwrite or augment it, use the following functions:

=over 4

=item clear_mimedb

Clears the internal mimetypes database

=item load_mimedb [$path]

Appends the mime type data in the given file to the internal mimetypes
database. If C<$path> is omitted, uses the system mimedb.

The format of the mime database file is similar (but not identical) to the
mime.types file used by many servers:

 MIMEDB      := LINE*
 LINE        := ( EMPTY | MIMERECORD ) COMMENT? NL
 COMMENT     := '#' NON-NL*
 EMPTY       := WS*
 MIMERECORD  := MIMETYPES EXTENSIONS
 MIMETYPES   := MIMETYPE ( ',' MIMETYPE )*
 EXTENSIONS  := EXTENSION ( WS* EXTENSION )*
 EXTENSION   := NON-WS-NON-DOT

Mimetypes and extensions are sorted in the order of most-common ot
least-common.

Here is a simple example for text/plain

 text/plain               txt asc

Here is a more complicated example for image/jpeg, which also covers the
wrong but commonly in use (MICROSOFT, DIE DIE DIE) pjpeg-type.

 image/jpeg,image/pjpeg   jpg jpeg jpe pjpg pjpeg

=cut

sub clear_mimedb() {
   %by_extension = %by_mimetype = ();
}

sub load_mimedb(;$) {
   my $path = $_[0];

   unless (defined $path) {
      require PApp::Config;
      $path = "$PApp::Config{LIBDIR}/etc/mimedb";
   }

   open my $db, "<", $path
      or die "$path: $!";

   while (<$db>) {
      s/^\s+//;
      s/(#.*)?[\015\012]*$//;
      if ($_ ne "") {
         my ($types, @exts) = split /\s+/;
         my @types = split /,/, $types;

         my $obj = bless [ [@types], [@exts] ];

         $by_mimetype{lc $_}  = $obj for @{$obj->[0]};
         $by_extension{lc $_} = $obj for @{$obj->[1]};
      }
   }
}

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

