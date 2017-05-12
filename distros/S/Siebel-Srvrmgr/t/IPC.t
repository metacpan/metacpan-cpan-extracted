use warnings;
use strict;
use Test::More tests => 11;
use Capture::Tiny 'capture';
use Config;

my $mod = 'Siebel::Srvrmgr::IPC';
require_ok($mod);
my @expected = qw(safe_open3 check_system);
can_ok( $mod, @expected );

{
    no strict;
    *sym = $Siebel::Srvrmgr::IPC::{EXPORT_OK};
    is_deeply( \@sym, \@expected, 'module exports only expected functions' );
}

SKIP: {

    skip 'check_system does not works on MS Windows', 8
      if ( $Config{osname} eq 'MSWin32' );

    my ( $message, $is_error );
    note('Executing "hostname"');
    my ( $stdout, $stderr, $exit ) = capture { system('hostname'); };
    note("STDOUT: $stdout");
    note("STDERR: $stderr");
    ( $message, $is_error ) =
      Siebel::Srvrmgr::IPC::check_system( ${^CHILD_ERROR_NATIVE} );
    ok( defined($message), 'message is defined' );
    is(
        $message,
        'Child process terminate with call to exit() with return code = 0',
        '"benign" error message after executing hostname'
    );
    ok( defined($is_error), 'confirmation of ok/error is defined' );
    is( $is_error, 0, 'returns false for error' );
    $message = $is_error = undef;
    my @chars = ( "A" .. "Z", "a" .. "z" );
    my $string;
    $string .= $chars[ rand @chars ] for 1 .. 8;
    note('Executing non-existent perl script');
    ( $stdout, $stderr, $exit ) = capture { system( $^X, "$string.pl" ); };
    note("STDOUT: $stdout");
    note("STDERR: $stderr");
    ( $message, $is_error ) =
      Siebel::Srvrmgr::IPC::check_system( ${^CHILD_ERROR_NATIVE} );
    ok( defined($message), 'message is defined' );
    is(
        $message,
        'Child process terminate with call to exit() with return code = 2',
        '"benign" error message after executing hostname'
    );
    ok( defined($is_error), 'confirmation of ok/error is defined' );
    is( $is_error, 1, 'returns true for error' );

}

