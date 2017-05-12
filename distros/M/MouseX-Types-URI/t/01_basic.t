# taken from MooseX-Types-URI/t/basic.t

use strict;
use Test::More;
use URI;
use URI::WithBase;

use MouseX::Types::URI qw(Uri FileUri DataUri);
use Mouse::Util::TypeConstraints;

{
    package Foo;
    use Mouse;

    package Bar;
    use Mouse;

    extends qw(URI);
}

ok( defined &Uri, "Uri" );
ok( defined &FileUri, "FileUri" );
ok( defined &DataUri, "DataUri" );

ok( my $uri = find_type_constraint(Uri), "find Uri" );

my $http = URI->new("http://www.google.com");
my $file = URI->new("file:///tmp/foo");
my $rel  = URI->new("foo");
my $data = URI->new("data:"); $data->data("stuff");
my $base_http = URI::WithBase->new("foo", $http );
my $base_file = URI::WithBase->new("foo", $file );
my $base_rel  = URI::WithBase->new("foo", $rel );

my $http_str = "http://www.google.com";

ok( $uri->check($http), "http uri" );
ok( $uri->check($file), "file uri" );
ok( $uri->check($rel),  "rel uri" );
ok( $uri->check($data), "data uri" );
ok( $uri->check(Bar->new),   "subclass" );
ok( $uri->check($base_http), "http with base" );
ok( $uri->check($base_file), "file with base" );
ok( $uri->check($base_rel),  "rel with base" );

ok( !$uri->check($http_str), "not for string" );
ok( !$uri->check(undef), "not for undef" );
ok( !$uri->check(Foo->new), "not for object" );

ok( my $furi = find_type_constraint(FileUri), "find FileUri" );

ok( $furi->check($file), "file uri" );

ok( !$furi->check($http), "http uri" );
ok( !$furi->check($rel),  "rel uri" );
ok( !$furi->check($data), "data uri" );
ok( !$furi->check(Bar->new),   "subclass" );
ok( !$furi->check($base_http), "http with base" );
ok( !$furi->check($base_file), "file with base" );
ok( !$furi->check($base_rel),  "rel with base" );

ok( !$furi->check($http_str), "not for string" );
ok( !$furi->check(undef), "not for undef" );
ok( !$furi->check(Foo->new), "not for object" );

ok( my $duri = find_type_constraint(DataUri), "find DataUri" );

ok( $duri->check($data), "data uri" );

ok( !$duri->check($http), "http uri" );
ok( !$duri->check($file), "file uri" );
ok( !$duri->check($rel),  "rel uri" );
ok( !$duri->check(Bar->new),   "subclass" );
ok( !$duri->check($base_http), "http with base" );
ok( !$duri->check($base_file), "file with base" );
ok( !$duri->check($base_rel),  "rel with base" );

ok( !$duri->check($http_str), "not for string" );
ok( !$duri->check(undef), "not for undef" );
ok( !$duri->check(Foo->new), "not for object" );

done_testing;
