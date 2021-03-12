use strict;
use warnings;

use Test::More 0.88;
use Test::Needs 'Path::Class', 'MooseX::Types::Path::Class';

use ok 'MooseX::Types::URI' => qw(Uri FileUri);

use URI;

foreach my $thing (
  Path::Class::file("foo"),
  Path::Class::dir("foo"),
) {
  my $uri_str = to_Uri($thing);
  isa_ok( $uri_str, "URI" );
  is( $uri_str->path, "foo", "URI" );
  is( $uri_str->scheme, undef, "URI" );

  my $uri_file = to_FileUri($thing);
  isa_ok( $uri_file, "URI::file" );
  is( $uri_file->file, "foo", "filename" );
}

done_testing;
