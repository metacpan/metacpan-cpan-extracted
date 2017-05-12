
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 18;
use strict;
use warnings;
sub slurp ($) { open( my $handle,$_[0] ); local $/; <$handle> }

ok( open( my $handle,'>script' ),"Create script #1: $!" );
print $handle <<'EOD';
use Sys::RunUntil '6s';
$|= 1;
print STDERR "Processing\n";
sleep 3;
print STDERR "Done\n";
EOD
ok( close( $handle ),"Close script #1: $!" );

ok( open( my $stdin,"| $^X -I$INC[-1] script 2>2" ),"Run script #1: $!" );
sleep 9;
ok( close( $stdin ),"Close pipe #1: $!" );
is( slurp 2,"Processing\nDone\n","Error message #1" );

ok( open( $handle,'>script' ),"Create script #2: $!" );
print $handle <<'EOD';
use Sys::RunUntil '6sW';
$|= 1;
print STDERR "Processing\n";
sleep 9;
print STDERR "Done\n";
__END__
EOD
ok( close( $handle ),"Close script #2: $!" );

ok( open( $stdin,"| $^X -I$INC[-1] script 2>2" ),"Run script #2: $!" );
sleep 9;
is( slurp 2,"Processing\n","Error message #2" );

ok( open( $handle,'>script' ),"Create script #3: $!" );
print $handle <<'EOD';
use Sys::RunUntil '3sC';
$|= 1;
print STDERR "Processing\n";
1 while 1;
__END__
EOD
ok( close( $handle ),"Close script #3: $!" );

ok( open( $stdin,"| $^X -I$INC[-1] script 2>2" ),"Run script #3: $!" );
sleep 9;
is( slurp 2,"Processing\n","Error message #3" );

ok( open( $handle,'>script' ),"Create script #4: $!" );
print $handle <<'EOD';
use Sys::RunUntil '3sC';
$|= 1;
print STDERR "Processing\n";
sleep 2;
print STDERR "Done\n";
__END__
EOD
ok( close( $handle ),"Close script #4: $!" );

ok( open( $stdin,"| $^X -I$INC[-1] script 2>2" ),"Run script #4: $!" );
sleep 9;
is( slurp 2,"Processing\nDone\n","Error message #4" );

is( 2,unlink( qw(script 2) ),"Cleanup" );
