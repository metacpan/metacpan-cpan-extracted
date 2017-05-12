use Test::More tests => 6;

use Netscape::Bookmarks;

my $File = 'bookmark_files/mozilla.html';
my $netscape = Netscape::Bookmarks->new( $File );
isa_ok( $netscape, 'Netscape::Bookmarks::Category' );
ok( $netscape->is_category,   "is_category"               );
ok( $netscape->is_collection, "is_collection"             );
is( $netscape->is_link,      0, "Category is not a link"  );
is( $netscape->is_alias,     0, "Alias is not a link"     );
is( $netscape->is_separator, 0, "Separator is not a link" );
