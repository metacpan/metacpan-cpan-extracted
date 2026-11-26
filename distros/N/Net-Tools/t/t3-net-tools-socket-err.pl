#!/usr/bin/perl
use strict;
use lib '../lib', 'lib';
use Test::More;
use Errno qw( EPIPE EAGAIN );
use Net::Tools::Socket::Err;

is( $SOCK_ERR,    undef, 'state not set at start' );
is( $SOCK_ERRSTR, undef, 'text not set at start' );

my @codes = ( SOCK_E_AGAIN, SOCK_E_EOF, SOCK_E_TOOBIG, SOCK_E_EMPTY, SOCK_E_MSGLEN,
              SOCK_E_SHORT, SOCK_E_TIMEOUT, SOCK_E_PROTO, SOCK_E_SYS, SOCK_E_INVAL );

my %seen;
for my $c ( @codes )
  {
  ok( $c < 0, "code $c is negative" );
  ok( ! $seen{ $c }++, "code $c is unique" );
  ok( exists $SOCK_ERRSTR{ $c } && length $SOCK_ERRSTR{ $c }, "code $c has text" );
  }
is( scalar( keys %SOCK_ERRSTR ), scalar( @codes ), 'text map has exactly the codes' );

is( sock_err( SOCK_E_EOF, 'RET' ), 'RET', 'sock_err() returns its second argument' );
is( sock_err( SOCK_E_EOF ), undef, 'sock_err() returns undef without second argument' );
is( $SOCK_ERR,    SOCK_E_EOF,               'code is set' );
is( $SOCK_ERRSTR, $SOCK_ERRSTR{ SOCK_E_EOF() }, 'text is set' );

# third argument is extra text appended to the SOCK_E_* text
is( sock_err( SOCK_E_PROTO, 'R', 'bad type' ), 'R', 'sock_err() with extra text returns its second argument' );
is( $SOCK_ERR,    SOCK_E_PROTO, 'sock_err() with extra text sets the code' );
is( $SOCK_ERRSTR, $SOCK_ERRSTR{ SOCK_E_PROTO() } . ': bad type', 'sock_err() appends extra text after ": "' );
sock_err( SOCK_E_PROTO, undef, '' );
is( $SOCK_ERRSTR, $SOCK_ERRSTR{ SOCK_E_PROTO() }, 'sock_err() with empty extra text adds nothing' );
sock_err( SOCK_E_PROTO, undef, undef );
is( $SOCK_ERRSTR, $SOCK_ERRSTR{ SOCK_E_PROTO() }, 'sock_err() with undef extra text adds nothing' );
sock_err( -999, undef, 'more' );
is( $SOCK_ERRSTR, 'unknown error code [-999]: more', 'sock_err() appends extra text to an unknown code too' );

$! = EPIPE;
my $epipe = "$!";
is( sock_err_sys( 'R' ), 'R', 'sock_err_sys() returns its argument' );
is( $SOCK_ERR,      EPIPE,   'sock_err_sys() sets errno value' );
is( $SOCK_ERRSTR,   $epipe,  'sock_err_sys() sets errno text' );
is( sock_err_name(), 'EPIPE', 'sock_err_name() of errno value' );
is( sock_err_name( EAGAIN ), 'EAGAIN', 'sock_err_name() prefers EAGAIN over EWOULDBLOCK' );
is( sock_err_name( 99999 ), 'ERRNO_99999', 'sock_err_name() of unknown errno value' );
sock_err( EPIPE );
is( $SOCK_ERRSTR, $epipe, 'sock_err() with positive errno value sets errno text' );
is( $!, $epipe, 'sock_err() keeps $!' );

$! = 0;
sock_err_sys();
is( $SOCK_ERR, SOCK_E_SYS, 'sock_err_sys() without errno is SOCK_E_SYS' );

sock_err( -999 );
is( $SOCK_ERR, -999, 'unknown code is kept' );
like( $SOCK_ERRSTR, qr/unknown error code \[-999\]/, 'unknown code has generic text' );

is( sock_err_name(),      'SOCK_E_UNKNOWN', 'sock_err_name() of unknown code' );
is( sock_err_name( SOCK_E_EOF ),     'SOCK_E_EOF',     'sock_err_name() of given code' );
is( sock_err_name( SOCK_E_TIMEOUT ), 'SOCK_E_TIMEOUT', 'sock_err_name() of given timeout code' );
my %names;
$names{ sock_err_name( $_ ) }++ for @codes;
is( scalar( keys %names ), scalar( @codes ), 'every code has its own name' );

is( sock_err_clear(), 1, 'sock_err_clear() returns 1' );
is( $SOCK_ERR,    undef, 'code cleared' );
is( $SOCK_ERRSTR, undef, 'text cleared' );
is( sock_err_name(), undef, 'sock_err_name() is undef when not set' );

ok( ! eval { $SOCK_ERRSTR{ SOCK_E_EOF() } = 'x'; 1 }, 'text map values are locked' );
ok( ! eval { $SOCK_ERRSTR{ -999 } = 'x'; 1 },          'text map keys are locked' );
ok( ! eval { delete $SOCK_ERRSTR{ SOCK_E_EOF() }; 1 }, 'text map entries cannot be deleted' );
ok( ! eval { my $x = $SOCK_ERRSTR{ -999 }; 1 },   'text map unknown key cannot be read' );

done_testing();
