use strict;

use Test::More tests => 3;
use Test::File;
use Text::Diff qw(diff);

use Netscape::Bookmarks;

my $File = 'bookmark_files/Bookmarks.html';
my $Tmp  = $File . '.tmp';

file_exists_ok( $File );
my $netscape = Netscape::Bookmarks->new( $File );
isa_ok( $netscape, 'Netscape::Bookmarks::Category' );

{
open my $fh, "> $Tmp" 
	or print "bail out! Could not open tmp file: $!";
print $fh $netscape->as_string;
close $fh;
};

my $diff = diff $File, $Tmp, { CONTEXT => 0 };
my $ok   = not $diff;

ok( $ok, 'Files are the same' );

=pod

# what was this test for?  where is this file?

file_exists_ok( "bookmark_files/bookmarks.curtis.html" );
$netscape = Netscape::Bookmarks->new( "bookmark_files/bookmarks.curtis.html" );
isa_ok( $netscape, 'Netscape::Bookmarks::Category' );

=cut

print STDERR "----- bookmarks.t diff is\n$diff" if $diff;

END { unlink $Tmp }

