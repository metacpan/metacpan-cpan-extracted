
use Config;
use Test::More;

my $this_perl = $Config{'perlpath'} || $EXECUTABLE_NAME;
ok( $this_perl, "this_perl: $this_perl" );

my @moduleGlobs = ( 'lib/Qmail/*.pm', 'lib/Qmail/Deliverable/*.pm' );
foreach my $glob ( @moduleGlobs ) {
    foreach my $mod ( glob $glob ) {
        chomp $mod;
        my $cmd = "$this_perl -I lib -c $mod 2>/dev/null 1>/dev/null";
        system $cmd;
        my $exit_code = sprintf ("%d", $CHILD_ERROR >> 8);
        ok( $exit_code == 0, "syntax $mod");
    };
}

use lib 'lib';
use_ok('Qmail::Deliverable');
use_ok('Qmail::Deliverable::Client');

done_testing();
