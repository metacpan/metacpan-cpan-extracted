use strict;
use warnings;
use lib 't/lib';
use Net::Route::Parser::Test;
use Net::Route::Table;
use Test::Exception;
use Test::More tests => 3;
use English qw( -no_match_vars );

my $parser_ref = Net::Route::Parser::Test->new();
my $command = $parser_ref->command_line( '/does/not/exist' );

my $message;
if ( $OSNAME eq 'MSWin32' )
{
    $message = qr/'$command' returned non-zero value/;
}
else
{
    $message = qr/Cannot execute '$command'/;
}

diag( "Ignore the following warning (Can't exec...)" );    # Module::Build bug
throws_ok { $parser_ref->from_system() } $message, 'Die message contents on invalid command';

SKIP:
{
    skip "/bin/false doesn't exist", 1 unless -x '/bin/false';
    $command = $parser_ref->command_line( '/bin/false' );

    throws_ok { $parser_ref->from_system() } qr/'$command' returned non-zero value \d+/,
      'Die message contents when command returned non-zero value';
}

SKIP:
{
    skip "No POSIX signals on Windows systems", 1 unless $OSNAME ne 'MSWin32';
    $command = $parser_ref->command_line( "$EXECUTABLE_NAME t/bin/suicide.pl" );
    throws_ok { $parser_ref->from_system() } qr/'$command' died with signal \d+/,
      'Die message contents when command had been killed';
}
