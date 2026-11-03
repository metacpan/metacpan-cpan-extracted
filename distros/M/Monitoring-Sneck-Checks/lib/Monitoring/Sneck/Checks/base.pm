package Monitoring::Sneck::Checks::base;

use 5.014;
use strict;
use warnings;
use File::Slurp  qw(read_file write_file);
use Getopt::Long ();
use IO::Select   ();
use POSIX        ();
use Time::HiRes  ();

=head1 NAME

Monitoring::Sneck::Checks::base - what Monitoring::Sneck::Checks checks are built on

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

use constant {
	OK       => 0,
	WARNING  => 1,
	CRITICAL => 2,
	UNKNOWN  => 3,
};

# Status names, by code.
our @STATUS_NAMES = ( 'OK', 'WARNING', 'CRITICAL', 'UNKNOWN' );

# How bad each code is, for worst. CRITICAL, then WARNING, then UNKNOWN.
our %SEVERITY = ( 0 => 0, 3 => 1, 1 => 2, 2 => 3 );

# A number in a range or option, such as 10, -2, or 0.5.
our $NUMBER = qr/-?(?:[0-9]+\.?[0-9]*|\.[0-9]+)/;

# The OS, as in $^O, for checks that read it differently per OS. Set by tests.
our $OS = $^O;

# Where Linux's proc file system is. Set by tests.
our $PROC = '/proc';

# How each comparison of a expect is put in messages, before the value wanted.
our %EXPECT_WORDS
	= ( '=' => '', '!=' => 'anything but ', '<' => 'under ', '<=' => 'at most ', '>' => 'over ', '>=' => 'at least ' );

# Where checks keep state between runs. Set by tests.
our $STATE_DIR = '/var/cache/sneck.checks';

=head1 SYNOPSIS

    package Monitoring::Sneck::Checks::example;

    use strict;
    use warnings;
    use parent 'Monitoring::Sneck::Checks::base';

    sub option_spec { return ( 'file|f=s', 'warning|w=s', 'critical|c=s' ) }
    sub defaults    { return { warning => '10', critical => '20' } }
    sub required    { return ('file') }
    sub ranges      { return ( 'warning', 'critical' ) }

    sub check {
        my ($self) = @_;

        my @lines = split( /\n/, ... );
        my $code  = $self->threshold_status( scalar(@lines), $self->opt('warning'), $self->opt('critical') );
        $self->perfdata( label => 'lines', value => scalar(@lines), warning => $self->opt('warning') );

        return $self->finish( $code, scalar(@lines) . ' lines in ' . $self->opt('file') );
    }

    1;

=head1 WRITING A CHECK

A check is a subclass named Monitoring::Sneck::Checks::$name. It is
made by L</new>, which parses its args, and then L</check> is called,
which returns the code. Those it may provide are below. Only check is
needed.

- check :: Does the check. Returns OK, WARNING, CRITICAL, or UNKNOWN,
usually through L</finish>. Dying is UNKNOWN.

- option_spec :: The options it takes, as a list of L<Getopt::Long>
specs. The first name of each is what L</opt> knows it by.
-t and --timeout are added.

- defaults :: A hash ref of defaults for its options.

- required :: A list of the options that must be given.

- ranges :: A list of the options that are ranges, see L</RANGES>,
checked by new.

- validate :: Given the hash ref of options, returns a list of what is
wrong with them, for what option_spec and ranges can not catch.

- label :: What starts its output, such as HTTP. The upper cased name
by default.

Output is written through L</out> and L</err>, not print, which keeps
the order of the two. Anything printed is caught as well, so it never
ends up in sneck's own output. A check must not exit, as it runs inside
sneck.

Modules only some checks use should be loaded with require in the
check, as every check runs in the same process.

=head1 COMMON OPTIONS

- -t, --timeout :: Seconds to wait on the network. Each lookup or
connection gets this, not the check as a whole.
Default :: a second under what it is run with, and at least one

=head1 RANGES

Thresholds are nagios style ranges. A value outside of the range
alerts, or inside of it if it starts with @.

- 10 :: Under 0 or over 10.

- 10: :: Under 10.

- ~:10 :: Over 10, ~ being negative infinity.

- 10:20 :: Under 10 or over 20.

- @10:20 :: 10 to 20.

=head1 METHODS

=head2 new

Makes the check and parses its args. Dies on bad args, which is
UNKNOWN.

- args :: Array ref of args, or a string of them.
Default :: []

- timeout :: Seconds it is run with.
Default :: 30

    my $check = Monitoring::Sneck::Checks::http->new( args => [ '-H', 'www.example.org' ], timeout => 30 );

=cut

sub new {
	my ( $class, %opts ) = @_;

	my $self = bless(
		{
			run_timeout => $opts{timeout} // 30,
			options     => {},
			perfdata    => [],
			stdout      => '',
			stderr      => '',
			combined    => '',
		},
		$class
	);
	$self->{options} = $self->parse_args( $opts{args} // [] );

	return $self;
} ## end sub new

=head2 parse_args

Parses args as said by option_spec, defaults, required, and ranges.
Used by new. Dies listing every problem.

- args :: Array ref of args, or a string of them, which L<Getopt::Long>
splits like a shell would. A string with unbalanced quotes dies.

Returns a hash ref of option names to values.

    my $options = $check->parse_args( [ '-H', 'www.example.org', '-w', '2' ] );
    my $options = $check->parse_args(q{-H www.example.org -s 'Welcome home'});

=cut

sub parse_args {
	my ( $self, $args ) = @_;

	if ( !ref($args) && !$self->quotes_balanced($args) ) {
		die("args have unbalanced quotes\n");
	}

	my @problems;
	my %parsed;
	my @left;
	{
		local $SIG{__WARN__} = sub { my $problem = $_[0]; $problem =~ s/\s+\z//; push( @problems, $problem ) };
		my $saved_config = Getopt::Long::Configure( 'bundling', 'no_ignore_case', 'no_auto_abbrev', 'permute' );
		if ( ref($args) eq 'ARRAY' ) {
			@left = @{$args};
			Getopt::Long::GetOptionsFromArray( \@left, \%parsed, 'timeout|t=s', $self->option_spec );
		} else {
			my ( $parsed_ok, $rest )
				= Getopt::Long::GetOptionsFromString( $args, \%parsed, 'timeout|t=s', $self->option_spec );
			@left = @{$rest};
		}
		Getopt::Long::Configure($saved_config);
	} ## end block
	foreach my $left (@left) {
		push( @problems, 'unexpected arg "' . $left . '"' );
	}

	my %options = ( %{ $self->defaults }, %parsed );
	foreach my $name ( $self->required ) {
		if ( !defined( $options{$name} ) || ( ref( $options{$name} ) eq 'ARRAY' && !defined( $options{$name}[0] ) ) ) {
			push( @problems, '--' . $name . ' is required' );
		}
	}
	if ( defined( $options{timeout} ) && ( $options{timeout} !~ /\A$NUMBER\z/ || $options{timeout} <= 0 ) ) {
		push( @problems, '--timeout must be a number over 0' );
	}
	foreach my $name ( $self->ranges ) {
		if ( defined( $options{$name} ) && !eval { $self->parse_range( $options{$name} ); 1 } ) {
			my $problem = $@;
			$problem =~ s/\s+\z//;
			push( @problems, '--' . $name . ' ' . $problem );
		}
	}
	push( @problems, $self->validate( \%options ) );
	die( join( ', ', @problems ) . "\n" ) if defined( $problems[0] );

	return \%options;
} ## end sub parse_args

=head2 quotes_balanced

Returns 1 if every ' and " in the text is closed, else 0. A backslash
escapes the next character, in or out of quotes, the same as
L<Getopt::Long> splitting a string goes by.

    $check->quotes_balanced(q{-s 'Welcome home'});    # 1
    $check->quotes_balanced(q{-s 'Welcome});          # 0
    $check->quotes_balanced(q{-s "it's"});            # 1

=cut

sub quotes_balanced {
	my ( $self, $text ) = @_;

	# eat unquoted runs, escaped characters, and whole quoted parts, until something does not close
	my $balanced_to = 0;
	while ( $text =~ /\G(?:[^'"\\]+|\\.|'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")/gcs ) {
		$balanced_to = pos($text);
	}

	return $balanced_to == length($text) ? 1 : 0;
} ## end sub quotes_balanced

=head2 option_spec

Returns the L<Getopt::Long> specs of the check's options. None for base.

=cut

sub option_spec { return () }

=head2 defaults

Returns a hash ref of defaults for the check's options. None for base.

=cut

sub defaults { return {} }

=head2 required

Returns the options that must be given. None for base.

=cut

sub required { return () }

=head2 ranges

Returns the options that are ranges. None for base.

=cut

sub ranges { return () }

=head2 validate

Returns a list of what is wrong with the options, given as a hash ref.
Nothing for base.

=cut

sub validate { return () }

=head2 check

Does the check. Dies for base, as each check has its own.

=cut

sub check {
	die( ( ref( $_[0] ) || $_[0] ) . " has no check\n" );
}

=head2 label

Returns what starts the check's output, the upper cased name, such as
HTTP for Monitoring::Sneck::Checks::http.

=cut

sub label {
	my $label = ref( $_[0] ) || $_[0];
	$label =~ s/\A.*:://;
	return uc($label);
}

=head2 opt

Returns the value of a option, or undef if it was not given and has no
default.

    my $host = $check->opt('hostname');

=cut

sub opt {
	return $_[0]{options}{ $_[1] };
}

=head2 timeout

Returns the seconds to wait on the network, see L</COMMON OPTIONS>.

=cut

sub timeout {
	my ($self) = @_;

	return $self->{options}{timeout} + 0 if defined( $self->{options}{timeout} );
	my $timeout = $self->{run_timeout} - 1;

	return $timeout < 1 ? 1 : $timeout;
}

=head2 out

Adds to the output.

    $check->out( "a line\n" );

=cut

sub out {
	my ( $self, @text ) = @_;

	my $text = join( '', @text );
	$self->{stdout}   = $self->{stdout} . $text;
	$self->{combined} = $self->{combined} . $text;

	return;
}

=head2 err

Adds to the errors.

    $check->err( "could not read it\n" );

=cut

sub err {
	my ( $self, @text ) = @_;

	my $text = join( '', @text );
	$self->{stderr}   = $self->{stderr} . $text;
	$self->{combined} = $self->{combined} . $text;

	return;
}

=head2 finish

Writes the status line and returns the code, so a check can end with
return $self->finish(...).

- code :: OK, WARNING, CRITICAL, or UNKNOWN.

- message :: What it found.

- details :: Lines to add after the status line, the nagios long output.

The line is the label, status, and message, with any perfdata after a |.

    return $self->finish( $self->OK, '200 OK in 0.120 seconds' );
    # HTTP OK - 200 OK in 0.120 seconds | time=0.120s;1;2;0

=cut

sub finish {
	my ( $self, $code, $message, @details ) = @_;

	my $line = $self->label . ' ' . $self->status_name($code) . ' - ' . $message;
	if ( defined( $self->{perfdata}[0] ) ) {
		$line = $line . ' | ' . join( ' ', @{ $self->{perfdata} } );
	}
	$self->out( map { $_ . "\n" } ( $line, @details ) );

	return $code;
} ## end sub finish

=head2 status_name

Returns the name of a code, such as CRITICAL for 2.

=cut

sub status_name {
	return $STATUS_NAMES[ $_[1] ] // 'UNKNOWN';
}

=head2 worst

Returns the worst of the codes given, CRITICAL, then WARNING, then
UNKNOWN, then OK. OK if none are given.

    my $code = $check->worst( $check->OK, $check->UNKNOWN, $check->WARNING );
    # WARNING

=cut

sub worst {
	my ( $self, @codes ) = @_;

	my $worst = OK;
	foreach my $code (@codes) {
		$worst = $code if $SEVERITY{$code} > $SEVERITY{$worst};
	}

	return $worst;
} ## end sub worst

=head2 parse_range

Parses a range, see L</RANGES>. Dies if it is not valid.

Returns a hash ref of start, undef for negative infinity, end, undef for
infinity, and inside, 1 if it starts with @.

    my $range = $check->parse_range('@10:20');
    # { start => 10, end => 20, inside => 1 }

=cut

sub parse_range {
	my ( $self, $text ) = @_;

	die("is not a range\n") if !defined($text) || ref($text);
	my $spec   = $text;
	my $inside = ( $spec =~ s/\A\@// ) ? 1 : 0;
	my ( $start, $end );
	if ( $spec =~ /\A($NUMBER)\z/ ) {
		( $start, $end ) = ( 0, $1 );
	} elsif ( $spec ne ':' && $spec =~ /\A(~|$NUMBER)?:($NUMBER)?\z/ ) {
		$start = $1 // 0;
		$end   = $2;
		$start = undef if $start eq '~';
	} else {
		die( '"' . $text . '" is not a valid range' . "\n" );
	}
	if ( defined($start) && defined($end) && $start > $end ) {
		die( '"' . $text . '" starts after it ends' . "\n" );
	}

	return { start => $start, end => $end, inside => $inside };
} ## end sub parse_range

=head2 in_alert

Returns 1 if a value alerts for a range, else 0.

    $check->in_alert( 15, '10' );    # 1
    $check->in_alert( 15, '10:' );   # 0

=cut

sub in_alert {
	my ( $self, $value, $range ) = @_;

	$range = $self->parse_range($range) if ref($range) ne 'HASH';
	my $within = ( !defined( $range->{start} ) || $value >= $range->{start} )
		&& ( !defined( $range->{end} ) || $value <= $range->{end} );

	return ( $within xor !$range->{inside} ) ? 1 : 0;
}

=head2 threshold_status

Returns CRITICAL if a value alerts for the critical range, WARNING if
for the warning one, else OK. A undef range is skipped.

    my $code = $check->threshold_status( $seconds, $check->opt('warning'), $check->opt('critical') );

=cut

sub threshold_status {
	my ( $self, $value, $warning, $critical ) = @_;

	return CRITICAL if defined($critical) && $self->in_alert( $value, $critical );
	return WARNING  if defined($warning)  && $self->in_alert( $value, $warning );

	return OK;
}

=head2 perfdata

Adds perfdata, which finish puts after the status line.

- label :: The name, quoted if it needs it.

- value :: The value.

- uom :: The unit, such as s, B, or %.

- warning, critical, min, max :: As in the nagios plugin guidelines.

Returns the perfdata as text.

    $check->perfdata( label => 'time', value => '0.120', uom => 's', warning => 1, critical => 2, min => 0 );
    # time=0.120s;1;2;0

=cut

sub perfdata {
	my ( $self, %perf ) = @_;

	my $label = $perf{label};
	if ( $label =~ /[\s'=]/ ) {
		$label =~ s/'/''/g;
		$label = "'" . $label . "'";
	}
	my $text = $label . '=' . $perf{value} . ( $perf{uom} // '' );
	$text = $text . ';' . join( ';', map { $_ // '' } @perf{ 'warning', 'critical', 'min', 'max' } );
	$text =~ s/;+\z//;
	push( @{ $self->{perfdata} }, $text );

	return $text;
} ## end sub perfdata

=head2 is_host

Returns 1 if the text is a IP or hostname, else 0.

    $check->is_host('www.example.org');    # 1
    $check->is_host('not a host');         # 0

=cut

sub is_host {
	my ( $self, $host ) = @_;

	require Data::Validate::IP;
	require Data::Validate::Domain;
	return 0 if !defined($host);
	return 1 if Data::Validate::IP::is_ip($host);
	return 1 if Data::Validate::Domain::is_hostname($host);

	return 0;
} ## end sub is_host

=head2 user_agent

Returns a L<LWP::UserAgent> using the timeout, not following
redirects, and checking certificates.

- insecure :: 1 to not check certificates.

- ca_file :: The CA file to check them against.

- max_redirect :: Redirects to follow.
Default :: 0

    my $user_agent = $check->user_agent( insecure => $check->opt('insecure') );

=cut

sub user_agent {
	my ( $self, %opts ) = @_;

	require LWP::UserAgent;
	my %ssl_opts = ( verify_hostname => $opts{insecure} ? 0 : 1 );
	$ssl_opts{SSL_verify_mode} = 0              if $opts{insecure};
	$ssl_opts{SSL_ca_file}     = $opts{ca_file} if defined( $opts{ca_file} );

	return LWP::UserAgent->new(
		agent        => 'Monitoring::Sneck::Checks/' . $VERSION,
		timeout      => $self->timeout,
		max_redirect => $opts{max_redirect} // 0,
		keep_alive   => 0,
		ssl_opts     => \%ssl_opts,
	);
} ## end sub user_agent

=head2 resolver

Returns a L<Net::DNS::Resolver> using the timeout.

- servers :: Array ref of the servers to ask. The system's if not
given.

- tcp :: 1 to ask over TCP.

- no_recurse :: 1 to not ask for recursion, for asking authoritative
servers.

    my $resolver = $check->resolver( servers => ['192.0.2.53'] );

=cut

sub resolver {
	my ( $self, %opts ) = @_;

	require Net::DNS;
	my $resolver = Net::DNS::Resolver->new(
		udp_timeout => $self->timeout,
		tcp_timeout => $self->timeout,
		retry       => 2,
		usevc       => $opts{tcp}        ? 1 : 0,
		recurse     => $opts{no_recurse} ? 0 : 1,
	);
	if ( ref( $opts{servers} ) eq 'ARRAY' && defined( $opts{servers}[0] ) ) {
		$resolver->nameservers( @{ $opts{servers} } );
	}

	return $resolver;
} ## end sub resolver

=head2 cert_details

Returns details on a certificate, a Net::SSLeay X509, as a hash ref.

- subject :: The common name, or the whole subject if it has none.

- issuer :: The same, for the issuer.

- not_before, not_after :: When it is good from and to, as time since epoch.

- days_left :: Whole days until not_after, negative once past it.

- names :: Array ref of its subject alternative names, such as DNS:www.example.org.

    my $details = $check->cert_details( $socket->peer_certificate );

=cut

sub cert_details {
	my ( $self, $cert ) = @_;

	require IO::Socket::SSL::Utils;
	my $hash = IO::Socket::SSL::Utils::CERT_asHash($cert);
	my $name = sub {
		my ($fields) = @_;
		return $fields->{commonName} if defined( $fields->{commonName} );
		return join( ', ', map { $_ . '=' . $fields->{$_} } sort( keys( %{$fields} ) ) );
	};

	return {
		subject    => $name->( $hash->{subject} ),
		issuer     => $name->( $hash->{issuer} ),
		not_before => $hash->{not_before},
		not_after  => $hash->{not_after},
		days_left  => POSIX::floor( ( $hash->{not_after} - time ) / 86400 ),
		names      => [ map { $_->[0] . ':' . $_->[1] } @{ $hash->{subjectAltNames} // [] } ],
	};
} ## end sub cert_details

=head2 cert_status

Works out the status of a certificate from when it is good to.

- details :: From L</cert_details>.

- warning :: Days left at or under which it is WARNING.

- critical :: Days left at or under which it is CRITICAL.

Returns the code and a message. Expired or not good yet is CRITICAL.

    my ( $code, $message ) = $check->cert_status( $details, 30, 14 );
    # ( 1, '"www.example.org" expires in 20 days, 2026-11-21 12:00:00 UTC' )

=cut

sub cert_status {
	my ( $self, $details, $warning, $critical ) = @_;

	my $now  = time;
	my $name = '"' . $details->{subject} . '"';
	if ( $details->{not_before} > $now ) {
		return ( CRITICAL, $name . ' is not good until ' . $self->utc_time( $details->{not_before} ) );
	}
	if ( $details->{not_after} <= $now ) {
		return ( CRITICAL, $name . ' expired ' . $self->utc_time( $details->{not_after} ) );
	}

	my $days_left = POSIX::floor( ( $details->{not_after} - $now ) / 86400 );
	my $message
		= $name
		. ' expires in '
		. $days_left . ' day'
		. ( $days_left == 1 ? '' : 's' ) . ', '
		. $self->utc_time( $details->{not_after} );
	return ( CRITICAL, $message ) if defined($critical) && $days_left <= $critical;
	return ( WARNING,  $message ) if defined($warning)  && $days_left <= $warning;

	return ( OK, $message );
} ## end sub cert_status

=head2 utc_time

Returns a time since epoch as text, such as 2026-11-21 12:00:00 UTC.

=cut

sub utc_time {
	return POSIX::strftime( '%Y-%m-%d %H:%M:%S UTC', gmtime( $_[1] ) );
}

=head2 read_socket

Reads from a socket until done says so, it closes, or the timeout
passes.

- socket :: The socket, plain or TLS.

- done :: A code ref given what has been read so far, returning true
once it is enough.

Returns what was read.

    my $greeting = $check->read_socket( $socket, sub { $_[0] =~ /^\d{3} [^\n]*\n/m } );

=cut

sub read_socket {
	my ( $self, $socket, $done ) = @_;

	my $received = '';
	my $select   = IO::Select->new($socket);
	my $deadline = Time::HiRes::time + $self->timeout;
	while (1) {
		my $remaining = $deadline - Time::HiRes::time;
		last if $remaining <= 0;

		# TLS may already have data read in that select can not see
		my $pending = $socket->can('pending') ? $socket->pending : 0;
		last if !$pending && !$select->can_read($remaining);
		my $read = sysread( $socket, my $buffer, 4096 );
		last if !$read;
		$received = $received . $buffer;
		last if $done->($received);
	} ## end while (1)

	return $received;
} ## end sub read_socket

=head2 pem_certs

Reads the certificates in a PEM file. Dies if it can not be read.

Returns a array ref of a Net::SSLeay X509 for each, in order, undef
for any that can not be parsed. Empty if there are none. Free them
with L<IO::Socket::SSL::Utils/CERT_free>.

    my $certs = $check->pem_certs('/usr/local/etc/ssl/www-chain.pem');

=cut

sub pem_certs {
	my ( $self, $file ) = @_;

	require IO::Socket::SSL::Utils;
	my $content = read_file( $file, err_mode => 'quiet' );
	die( 'can not read ' . $file . ', ' . $! . "\n" ) if !defined($content);

	my @certs;
	foreach my $pem ( $content =~ /(-----BEGIN CERTIFICATE-----.+?-----END CERTIFICATE-----)/gs ) {
		my $cert = eval { IO::Socket::SSL::Utils::PEM_string2cert($pem) };
		push( @certs, $cert ? $cert : undef );
	}

	return \@certs;
} ## end sub pem_certs

=head2 run_command

Runs a command, without a shell, and waits for it, with stdin from
/dev/null. Dies if it can not be run.

- command :: The program and its args, as a list.

Returns its exit code and its stdout and stderr together. A command
killed by a signal has a exit of 128 plus the signal.

If the check times out while the command runs, the command, and
anything it started, is sent TERM, then KILL if it is still there half
a second later, so a hung command does not hold the check up past its
timeout. For that it is run in a process group of its own.

    my ( $exit, $output ) = $check->run_command( '/usr/sbin/pkg', 'audit' );

=cut

sub run_command {
	my ( $self, @command ) = @_;

	# a forking pipe open sets up the child's fd 1 itself, which matters as run has STDOUT
	# pointed at a in-memory handle, so the rest is done on fds as well
	my $pid = open( my $out, '-|' ) // die( 'can not fork for ' . $command[0] . ', ' . $! . "\n" );
	if ( !$pid ) {
		# its own process group, so _stop_command can take anything it starts down with it
		POSIX::setpgid( 0, 0 );
		POSIX::dup2( 1, 2 );
		my $null = POSIX::open( '/dev/null', POSIX::O_RDONLY() );
		POSIX::dup2( $null, 0 ) if defined($null);
		{ no warnings 'exec'; exec( { $command[0] } @command ); }
		my $why = "\0" . 'can not run ' . $command[0] . ', ' . $!;
		POSIX::write( 1, $why, length($why) );
		POSIX::_exit(127);
	} ## end if ( !$pid )

	# the timeout alarm dies out of the read, and closing the pipe waits for the command,
	# so a hung one is stopped first or the close would wait as long as it does
	my $output = eval { local $/; <$out> };
	if ( $@ ne '' ) {
		my $died = $@;
		_stop_command($pid);
		close($out);
		die($died);
	}
	$output //= '';
	close($out);
	my $exit = ( $? & 127 ) ? 128 + ( $? & 127 ) : $? >> 8;
	die( substr( $output, 1 ) . "\n" ) if $exit == 127 && $output =~ /\A\0can not run /;

	return ( $exit, $output );
} ## end sub run_command

# Stops a command run_command started, once the check timed out while
# waiting on it. TERM first, then KILL if it has not gone after half a
# second, so closing the pipe to it, which waits for it, can not hang.
# Both go to its process group as well as to it, as the group takes
# anything it started with it, and it may not have made the group yet.
#
# Args...
#
#     - pid :: The process ID of the command.
#
# Returns nothing. A command that exits on TERM is reaped here, which
# the close after it copes with.
#
# Example...
#
#     _stop_command($pid);
sub _stop_command {
	my ($pid) = @_;

	kill( 'TERM',  $pid );
	kill( '-TERM', $pid );
	foreach ( 1 .. 10 ) {
		return if waitpid( $pid, POSIX::WNOHANG() ) != 0;
		Time::HiRes::sleep(0.05);
	}
	kill( 'KILL',  $pid );
	kill( '-KILL', $pid );

	return;
} ## end sub _stop_command

=head2 split_expect

Splits a expect, a name, a comparison, and a value, as sysctl and
config_value take. The comparison is =, !=, <, <=, >, or >=.

Returns the name, comparison, and value, or a empty list if it is not
valid.

    my ( $name, $comparison, $value ) = $check->split_expect('kern.securelevel>=1');
    # ( 'kern.securelevel', '>=', '1' )

=cut

sub split_expect {
	my ( $self, $expect ) = @_;

	return ( $1, $2, $3 ) if $expect =~ m{\A([A-Za-z0-9_][A-Za-z0-9_./-]*?)(!=|<=|>=|=|<|>)(.*)\z};

	return ();
}

=head2 expect_met

Checks a value against a expect.

- value :: The value it has.

- comparison :: =, !=, <, <=, >, or >=.

- wanted :: The value wanted. For = and !=, values split by |, any of
which is enough for =, and none of which may match for !=. Runs of
space in them are squashed. A empty one, as all of "name=" or the last
of "name=a|", is met by a empty value. The others compare as numbers,
and a value that is not a number does not meet them.

- no_case :: 1 to compare = and != without case.

Returns 1 if it is met, else 0.

    $check->expect_met( '1', '=', '1|2' );    # 1
    $check->expect_met( '5', '<', '3' );      # 0
    $check->expect_met( '',  '=', '' );       # 1

=cut

sub expect_met {
	my ( $self, $value, $comparison, $wanted, $no_case ) = @_;

	if ( $comparison eq '=' || $comparison eq '!=' ) {
		my $have  = $no_case ? lc($value) : $value;
		my $found = grep { ( $no_case ? lc($_) : $_ ) eq $have } map { s/\s+/ /gr } _split_wanted($wanted);
		return ( $comparison eq '=' ? $found : !$found ) ? 1 : 0;
	}
	return 0 if $value !~ /\A-?[0-9]+(?:\.[0-9]+)?\z/;
	return ( $value < $wanted  ? 1 : 0 ) if $comparison eq '<';
	return ( $value <= $wanted ? 1 : 0 ) if $comparison eq '<=';
	return ( $value > $wanted  ? 1 : 0 ) if $comparison eq '>';

	return $value >= $wanted ? 1 : 0;
} ## end sub expect_met

=head2 expect_wanted

Returns what a expect wants as text, for messages, a empty value shown
as "".

    $check->expect_wanted( '>=', '1' );     # 'at least 1'
    $check->expect_wanted( '=',  'a|b' );   # 'a or b'
    $check->expect_wanted( '=',  '' );      # '""'

=cut

sub expect_wanted {
	my ( $self, $comparison, $wanted ) = @_;

	return $EXPECT_WORDS{$comparison} . join( ' or ', map { $self->shown($_) } _split_wanted($wanted) );
}

=head2 shown

Returns a value as it is to be shown in messages, which is as it is,
other than a empty one being "".

    $check->shown('022');    # '022'
    $check->shown('');       # '""'

=cut

sub shown {
	return $_[1] eq '' ? '""' : $_[1];
}

# Splits what a expect wants on |, keeping empty ones, which split on
# its own drops, as name= and name=a| want a empty value.
#
# Args...
#
#     - wanted :: The value wanted, such as 'a|b', 'a|', or ''.
#
# Returns the list of values, at least one.
#
# Example...
#
#     _split_wanted('a|b');    # ( 'a', 'b' )
#     _split_wanted('a|');     # ( 'a', '' )
#     _split_wanted('');       # ( '' )
sub _split_wanted {
	my ($wanted) = @_;

	return $wanted eq '' ? ('') : split( /\|/, $wanted, -1 );
}

=head2 read_state

Reads state kept between runs, as JSON.

- file :: The state file.

Returns a hash ref of it, a empty one if there is none yet, or undef
if it can not be read or is not a JSON object.

    my $state = $check->read_state( $Monitoring::Sneck::Checks::base::STATE_DIR . '/interface-em0.json' );

=cut

sub read_state {
	my ( $self, $file ) = @_;

	return {} if !-e $file;
	require JSON;
	my $saved = read_file( $file, err_mode => 'quiet' );
	my $state = eval { JSON->new->decode( $saved // '' ) };

	return ref($state) eq 'HASH' ? $state : undef;
} ## end sub read_state

=head2 write_state

Writes the state, through a temporary file renamed into place, making
the directory if needed.

- file :: The state file.

- state :: Hash ref of the state.

Returns undef, or what went wrong.

=cut

sub write_state {
	my ( $self, $file, $state ) = @_;

	require File::Basename;
	require JSON;
	my $dir = File::Basename::dirname($file);
	if ( !-d $dir && !mkdir( $dir, 0700 ) ) {
		return 'can not make ' . $dir . ', ' . $!;
	}
	if ( !write_file( $file, { err_mode => 'quiet', atomic => 1 }, JSON->new->canonical->encode($state) ) ) {
		return 'can not write ' . $file . ', ' . $!;
	}

	return undef;
} ## end sub write_state

=head2 os

Returns the OS, as in $^O, such as linux or freebsd.

=cut

sub os {
	return $OS;
}

=head2 sysctl

Returns the value of a sysctl, through L<BSD::Sysctl>, which is only
loaded when this is used, so only needed on the BSDs. Dies if it is not
there.

    my $cpus = $check->sysctl('hw.ncpu');

=cut

sub sysctl {
	my ( $self, $name ) = @_;

	require BSD::Sysctl;
	my $value = BSD::Sysctl::sysctl($name);
	die( 'no sysctl ' . $name . "\n" ) if !defined($value);

	return $value;
}

=head2 proc_file

Returns the content of a file under Linux's /proc, such as meminfo.
Dies if it can not be read.

    my $meminfo = $check->proc_file('meminfo');

=cut

sub proc_file {
	my ( $self, $file ) = @_;

	my $content = read_file( $PROC . '/' . $file, err_mode => 'quiet' );
	die( 'can not read ' . $PROC . '/' . $file . ', ' . $! . "\n" ) if !defined($content);

	return $content;
}

1;
