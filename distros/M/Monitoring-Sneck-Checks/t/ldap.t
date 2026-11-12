#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use Monitoring::Sneck::Checks;

# A stand in for Net::LDAP, so this runs without it or a server. Each call is kept in @CALLS, as
# [ method, args ], and what it returns is set through %BEHAVE.
BEGIN { $INC{'Net/LDAP.pm'} = __FILE__ }

package Net::LDAP;
our @CALLS;
our %BEHAVE;

sub new {
	my ( $class, @args ) = @_;
	push( @CALLS, [ 'new', @args ] );
	if ( $BEHAVE{connect_error} ) {
		$@ = $BEHAVE{connect_error};
		return undef;
	}
	return bless( {}, $class );
}

sub start_tls  { my ( $self, @args ) = @_; push( @CALLS, [ 'start_tls', @args ] ); return _message('start_tls') }
sub bind       { my ( $self, @args ) = @_; push( @CALLS, [ 'bind', @args ] ); return _message('bind') }
sub search     { my ( $self, @args ) = @_; push( @CALLS, [ 'search', @args ] ); return _message('search') }
sub unbind     { push( @CALLS, ['unbind'] ); return _message('unbind') }
sub disconnect { push( @CALLS, ['disconnect'] ); return }

# a message with the code and error set for that step, and the count for a search
sub _message {
	my ($step) = @_;
	return bless(
		{
			code  => $BEHAVE{ $step . '_code' }  // 0,
			error => $BEHAVE{ $step . '_error' } // 'Success',
			count => $BEHAVE{count}              // 1,
		},
		'Net::LDAP::FakeMessage'
	);
} ## end sub _message

package Net::LDAP::FakeMessage;
sub code  { return $_[0]{code} }
sub error { return $_[0]{error} }
sub count { return $_[0]{count} }

package main;

my $run = sub {
	my ( $behave, @args ) = @_;
	@Net::LDAP::CALLS  = ();
	%Net::LDAP::BEHAVE = %{$behave};
	return Monitoring::Sneck::Checks->run( check => 'ldap', args => \@args );
};
my $calls = sub {
	return [ map { $_->[0] } @Net::LDAP::CALLS ];
};
my $args_of = sub {
	my ($method) = @_;
	my ($call)   = grep { $_->[0] eq $method } @Net::LDAP::CALLS;
	my @args     = @{$call};
	shift(@args);
	return \@args;
};

# anonymous, the root DSE
my $return = $run->( {}, '-H', 'ldap.example.org' );
like(
	$return->{stdout},
	qr/\ALDAP OK - ldap\.example\.org:389, bound anonymously, 1 entry found, [0-9.]+ seconds \| time=[0-9.]+s;;;0 entries=1;;1:;0\n\z/,
	'anonymous, root DSE'
);
is_deeply( $calls->(), [ 'new', 'bind', 'search', 'unbind', 'disconnect' ], 'connect, bind, search, unbind' );
is_deeply(
	$args_of->('new'),
	[ 'ldap.example.org', port => 389, scheme => 'ldap', timeout => 29, version => 3 ],
	'plain LDAP on 389'
);
is_deeply( $args_of->('bind'), [], 'anonymous bind' );
is_deeply(
	$args_of->('search'),
	[ base => '', scope => 'base', filter => '(objectClass=*)', attrs => ['1.1'] ],
	'root DSE search, no attributes'
);

# bound, searching, over StartTLS
$return = $run->(
	{ count => 12 },    '-H',
	'ldap.example.org', '-s',
	'-D',               'cn=monitor,dc=example,dc=org',
	'-P',               $FindBin::Bin . '/data/ldap/password',
	'-b',               'ou=people,dc=example,dc=org',
	'--scope',          'one',
	'-f',               '(uid=*)',
	'-E',               '10:',
	'--ca-file',        '/etc/ssl/ca.pem'
);
like(
	$return->{stdout},
	qr/\ALDAP OK - ldap\.example\.org:389, bound as cn=monitor,dc=example,dc=org, 12 entries found, /,
	'bound, searching over StartTLS'
);
is_deeply( $calls->(), [ 'new', 'start_tls', 'bind', 'search', 'unbind', 'disconnect' ], 'StartTLS before binding' );
is_deeply( { @{ $args_of->('start_tls') } }, { verify => 'require', cafile => '/etc/ssl/ca.pem' },
	'StartTLS verifies' );
is_deeply(
	$args_of->('bind'),
	[ 'cn=monitor,dc=example,dc=org', password => 'secret password' ],
	'bound with the first line of --password-file'
);
is_deeply(
	$args_of->('search'),
	[ base => 'ou=people,dc=example,dc=org', scope => 'one', filter => '(uid=*)', attrs => ['1.1'] ],
	'search as given'
);
unlike( $return->{combined}, qr/secret/, 'password never output' );

# LDAPS
$return = $run->( {}, '-H', 'ldap.example.org', '-S', '--insecure' );
is_deeply(
	$args_of->('new'),
	[ 'ldap.example.org', port => 636, scheme => 'ldaps', timeout => 29, version => 3, verify => 'none' ],
	'LDAPS on 636, --insecure'
);
$run->( {}, '-H', 'ldap.example.org', '-S', '-p', '6360', '--password', 'pw', '-D', 'cn=a' );
is( $args_of->('new')->[2], 6360, '--port' );
is_deeply( $args_of->('bind'), [ 'cn=a', password => 'pw' ], '--password' );

# failures
is(
	$run->( { connect_error => 'IO::Socket::IP: connect: Connection refused' }, '-H', 'ldap.example.org' )
		->{stdout},
	"LDAP CRITICAL - ldap.example.org:389, IO::Socket::IP: connect: Connection refused\n",
	'not connecting'
);
is(
	$run->(
		{ start_tls_code => 2, start_tls_error => 'unsupported extended operation' }, '-H',
		'ldap.example.org',                                                           '-s'
	)->{stdout},
	"LDAP CRITICAL - ldap.example.org:389 StartTLS failed, 2 unsupported extended operation\n",
	'StartTLS failing'
);
$return = $run->(
	{ bind_code => 49, bind_error => 'Invalid credentials' },
	'-H', 'ldap.example.org', '-D', 'cn=a', '--password', 'wrong'
);
is( $return->{stdout}, "LDAP CRITICAL - ldap.example.org:389 bind failed, 49 Invalid credentials\n", 'bind failing' );
is_deeply( $calls->(), [ 'new', 'bind', 'disconnect' ], 'disconnects after failing' );
is(
	$run->( { search_code => 32, search_error => 'No such object' }, '-H', 'ldap.example.org', '-b', 'ou=gone' )
		->{stdout},
	"LDAP CRITICAL - ldap.example.org:389 search failed, 32 No such object\n",
	'search failing'
);
like(
	$run->( { search_code => 4, count => 500 }, '-H', 'ldap.example.org', '-b', 'dc=example', '--scope', 'sub' )
		->{stdout},
	qr/\ALDAP OK - ldap\.example\.org:389, bound anonymously, 500 entries found, size limit hit, /,
	'size limit hit is fine'
);
like(
	$run->( { count => 0 }, '-H', 'ldap.example.org' )->{stdout},
	qr/\ALDAP CRITICAL - ldap\.example\.org:389, bound anonymously, 0 entries found, [0-9.]+ seconds, wanted 1: entries \|/,
	'nothing found'
);
is( $run->( {}, '-H', 'ldap.example.org', '-w', '@0:' )->{code}, 1, 'time over --warning' );
is( $run->( {}, '-H', 'ldap.example.org', '-c', '@0:' )->{code}, 2, 'time over --critical' );

# bad options
like(
	$run->( {}, '-H', 'ldap.example.org', '-S', '-s' )->{combined},
	qr/--ssl and --starttls can not both be given/,
	'--ssl and --starttls'
);
like(
	$run->( {}, '-H', 'ldap.example.org', '--password', 'pw' )->{combined},
	qr/--password or --password-file needs --bind-dn/,
	'password without a DN'
);
like(
	$run->( {}, '-H', 'ldap.example.org', '--scope', 'all' )->{combined},
	qr/--scope must be base, one, or sub/,
	'bad --scope'
);
like(
	$run->( {}, '-H', 'ldap.example.org', '-D', 'cn=a', '-P', $FindBin::Bin . '/data/ldap/nope' )->{stdout},
	qr/\ALDAP UNKNOWN - can not read \S+nope, /,
	'--password-file not there'
);

# Net::LDAP not there, blocked even if it is installed
{
	delete local $INC{'Net/LDAP.pm'};
	local @INC = ( sub { die("blocked\n") if $_[1] eq 'Net/LDAP.pm'; return }, @INC );
	is(
		$run->( {}, '-H', 'ldap.example.org' )->{stdout},
		"LDAP UNKNOWN - Net::LDAP is not installed\n",
		'Net::LDAP not installed'
	);
}

done_testing();
