use strict;

use Test::More tests => 3;

use Netscape::Bookmarks::Separator;

my $sep1 = Netscape::Bookmarks::Separator->new();
isa_ok( $sep1, 'Netscape::Bookmarks::Separator' );

my $sep2 = Netscape::Bookmarks::Separator->new();
isa_ok( $sep2, 'Netscape::Bookmarks::Separator' );

is( $sep1, $sep2, 'Separator objects are the same' );

