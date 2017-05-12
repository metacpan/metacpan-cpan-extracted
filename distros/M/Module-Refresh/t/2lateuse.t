#!/usr/bin/perl -w

use strict;

package FOOBAR;

use Test::More qw/no_plan/; 
# can't really have a plan, since we're hoping the test will not be called
use File::Temp 'tempdir';
my $tmp  = tempdir( CLEANUP => 1 );

my $file = $tmp."/".'BeepBeep.pm';
push @INC, $tmp;

write_out(<<'.');
package BeepBeep;
our $Beep;
Test::More::is($Beep++, 0, "This line works exactly once!");
1;
.

use_ok('Module::Refresh');

Module::Refresh->refresh; # This does the first INC scan

use_ok('BeepBeep', "Required our dummy module");

Module::Refresh->refresh;

# BeepBeep should *not* be refreshed here, because it has not
# changed, even if M::R has not seen it before!


sub write_out {
    local *FH;
    open FH, "> $file" or die "Cannot open $file: $!";
    print FH $_[0];
    close FH;
}

END {
    unlink $file;
}

1;
