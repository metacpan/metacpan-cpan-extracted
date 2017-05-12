#
# $Id: 01-dict.t,v 0.1 2006/04/27 04:01:27 dankogai Exp $
#
BEGIN {
    if (@ARGV) {
        my $dict = shift;
        symlink( $dict, "t/_dict" ) or die $!;
        system qw(perl t/dict2rx.pl), "t/_dict";
    }
    if ( !-f 't/_dict.rx' ) {
        print qq(1..0 # Skip: _dict.rx not found.\n),
          qq(# "$0 /usr/share/dict/words" to prepare the test\n);
        exit 0;
    }
}

use strict;
use warnings;
use Test::More qw/no_plan/;
use Regexp::Trie;
use Time::HiRes qw/time/;

$| = 1;
my $time2load = time();
print "# loading t/_dict.rx ... ";
my $rx = do 't/_dict.rx';
$time2load = time() - $time2load;
print "done. took $time2load seconds.\n";
open my $dict, "<:raw", "t/dict" or die "$!";
while ( my $line = <$dict> ) {
    chomp $line;
    ok( $line =~ /^$rx$/, $line );
}
