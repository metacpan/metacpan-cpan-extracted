
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 22;
use strict;
use warnings;
sub slurp ($) { open( my $handle,$_[0] ); local $/; <$handle> }

ok( open( my $handle,'>script' ),"Create script #1: $!" );
print $handle <<'EOD';
$| = 1;
use Sys::RunAlways;
<>;
EOD
ok( close( $handle ),"Close script #1: $!" );

ok( open( my $stdin,"| $^X -I$INC[-1] script 2>2" ),"Run script #1: $!" );
sleep 2;
chomp( my $error = slurp 2 );
is( $error,"Add __END__ to end of script 'script' to be able use the features of Sys::RunAlways","Error message #1" );
ok( !close( $stdin ),"Close pipe #1: $!" );

ok( open( $handle,'>script' ),"Create script #2: $!" );
print $handle <<'EOD';
$| = 1;
use Sys::RunAlways;
<>;
__END__
EOD
ok( close( $handle ),"Close script #2: $!" );

ok( open( my $stdin1,"| $^X -I$INC[-1] script 2>2" ),"Run script #2: $!" );
sleep 2;
chomp( my $error1 = slurp 2 );
like( $error1,qr{'script' has been started at .*},"Error message #2" );

ok( open( my $stdin2,"| $^X -I$INC[-1] script 2>2" ),"Run script #2: $!" );
sleep 2;
chomp( my $error2 = slurp 2 );
is( $error2,"","Error message #2a" );
ok( close( $stdin2 ),"Close pipe #2a: $!" );

print $stdin1 $/;
ok( close( $stdin1 ),"Close pipe #2: $!" );

ok( open( $handle,'>script' ),"Create script #3: $!" );
print $handle <<'EOD';
$| = 1;
use Sys::RunAlways silent => 1;
<>;
__END__
EOD
ok( close( $handle ),"Close script #3: $!" );

ok( open( $stdin1,"| $^X -I$INC[-1] script 2>2" ),"Run script #3: $!" );
sleep 2;
chomp( $error1 = slurp 2 );
is( $error1,"","Error message #3" );

ok( open( $stdin2,"| $^X -I$INC[-1] script 2>2" ),"Run script #3: $!" );
sleep 2;
chomp( $error2 = slurp 2 );
is( $error2,"","Error message #3a" );
ok( close( $stdin2 ),"Close pipe #3a: $!" );

print $stdin1 $/;
ok( close( $stdin1 ),"Close pipe #3: $!" );

is( 2,unlink( qw(script 2) ),"Cleanup" );
