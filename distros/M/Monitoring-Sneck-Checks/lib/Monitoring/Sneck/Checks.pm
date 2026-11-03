package Monitoring::Sneck::Checks;

use 5.014;
use strict;
use warnings;
use Time::HiRes ();

=head1 NAME

Monitoring::Sneck::Checks - nagios style checks run as Perl inside of sneck

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';

# Seconds a check is given if run is not told otherwise.
our $TIMEOUT = 30;

=head1 SYNOPSIS

    use Monitoring::Sneck::Checks;

    my $return = Monitoring::Sneck::Checks->run(
        check   => 'http',
        args    => [ '-H', 'www.example.org', '-S', '-w', '1', '-c', '2' ],
        timeout => 30,
    );
    print $return->{combined};
    exit( $return->{code} );

Or from a sneck config.

    www|perl:http -H www.example.org -S -w 1 -c 2

=head1 DESCRIPTION

Runs checks written as Perl modules under Monitoring::Sneck::Checks::,
in process, so sneck does not have to start a new program for each.
They return the same exit codes as nagios plugins.

A check is the module Monitoring::Sneck::Checks::$name, subclassing
L<Monitoring::Sneck::Checks::base>, where the shared helpers are. See
that for writing one.

The checks that come with it are...

- accounts :: L<Monitoring::Sneck::Checks::accounts>, local user accounts.

- cciss :: L<Monitoring::Sneck::Checks::cciss>, HP Smart Array controllers, through cciss_vol_status.

- cert_dir :: L<Monitoring::Sneck::Checks::cert_dir>, every certificate in directories.

- cert_file :: L<Monitoring::Sneck::Checks::cert_file>, certificate files.

- checksums :: L<Monitoring::Sneck::Checks::checksums>, files against stored checksums.

- config_value :: L<Monitoring::Sneck::Checks::config_value>, values in config files.

- conntrack :: L<Monitoring::Sneck::Checks::conntrack>, how full the connection tracking table is.

- containers :: L<Monitoring::Sneck::Checks::containers>, Docker or Podman containers.

- debsecan :: L<Monitoring::Sneck::Checks::debsecan>, Debian security fixes, through debsecan.

- disk :: L<Monitoring::Sneck::Checks::disk>, how full file systems are.

- dns :: L<Monitoring::Sneck::Checks::dns>, DNS lookups.

- dns_sync :: L<Monitoring::Sneck::Checks::dns_sync>, a zone's nameservers having the same serial.

- file_age :: L<Monitoring::Sneck::Checks::file_age>, file age and size.

- file_handles :: L<Monitoring::Sneck::Checks::file_handles>, open files against the system limit.

- file_mode :: L<Monitoring::Sneck::Checks::file_mode>, the mode, owner, and group of files.

- hosts :: L<Monitoring::Sneck::Checks::hosts>, /etc/hosts.

- http :: L<Monitoring::Sneck::Checks::http>, HTTP and HTTPS.

- http_json :: L<Monitoring::Sneck::Checks::http_json>, values in a JSON response.

- https_cert :: L<Monitoring::Sneck::Checks::https_cert>, the certificate a TLS server hands out, STARTTLS included.

- interface :: L<Monitoring::Sneck::Checks::interface>, network interfaces being up, at speed, and not erroring.

- jails :: L<Monitoring::Sneck::Checks::jails>, FreeBSD jails and bhyve VMs running.

- kernel_modules :: L<Monitoring::Sneck::Checks::kernel_modules>, kernel modules being loaded or not.

- listening :: L<Monitoring::Sneck::Checks::listening>, what ports are listened on.

- load :: L<Monitoring::Sneck::Checks::load>, the load averages.

- log :: L<Monitoring::Sneck::Checks::log>, new lines in a log for a regex.

- memory :: L<Monitoring::Sneck::Checks::memory>, how much memory is used.

- mount :: L<Monitoring::Sneck::Checks::mount>, file systems being mounted and writable.

- neighbors :: L<Monitoring::Sneck::Checks::neighbors>, how full the ARP and NDP neighbor tables are.

- ntp :: L<Monitoring::Sneck::Checks::ntp>, the local clock against a NTP server.

- oom :: L<Monitoring::Sneck::Checks::oom>, processes killed for running out of memory.

- packages :: L<Monitoring::Sneck::Checks::packages>, packages being installed or not.

- pid_file :: L<Monitoring::Sneck::Checks::pid_file>, the process in a PID file running.

- ping :: L<Monitoring::Sneck::Checks::ping>, ICMP, TCP, or UDP ping.

- pkg_audit :: L<Monitoring::Sneck::Checks::pkg_audit>, FreeBSD packages with known vulnerabilities.

- pressure :: L<Monitoring::Sneck::Checks::pressure>, Linux pressure stall information.

- procs :: L<Monitoring::Sneck::Checks::procs>, how many processes are running.

- rbl :: L<Monitoring::Sneck::Checks::rbl>, DNS block lists.

- reboot_needed :: L<Monitoring::Sneck::Checks::reboot_needed>, a reboot or restarts being needed after updates.

- resolv :: L<Monitoring::Sneck::Checks::resolv>, /etc/resolv.conf.

- sensors :: L<Monitoring::Sneck::Checks::sensors>, temperatures, fans, and voltages.

- service :: L<Monitoring::Sneck::Checks::service>, services running.

- smtp :: L<Monitoring::Sneck::Checks::smtp>, a SMTP server.

- sshd_config :: L<Monitoring::Sneck::Checks::sshd_config>, settings in sshd_config.

- swap :: L<Monitoring::Sneck::Checks::swap>, how much swap is used.

- swraid :: L<Monitoring::Sneck::Checks::swraid>, software RAID, md, gmirror, and graid.

- sysctl :: L<Monitoring::Sneck::Checks::sysctl>, sysctl values.

- systemd_failed :: L<Monitoring::Sneck::Checks::systemd_failed>, failed systemd units.

- tcp :: L<Monitoring::Sneck::Checks::tcp>, TCP services.

- tls_protocols :: L<Monitoring::Sneck::Checks::tls_protocols>, what TLS versions a server takes.

- uptime :: L<Monitoring::Sneck::Checks::uptime>, how long the host has been up.

=head1 TIMEOUTS

Checks are not forked, so they are timed out two ways. Each check hands
its timeout, a second under the one it is run with, to whatever it
talks to the network through, such as L<LWP::UserAgent> or
L<Net::DNS::Resolver>. As a backstop, an alarm fires at the timeout it
is run with, which makes it UNKNOWN. A command the check is running
through L<Monitoring::Sneck::Checks::base/run_command> is killed when
it fires. The alarm can not break into everything, such as some name
lookups in the C library, so the first is what is relied on.

=head1 METHODS

=head2 list

Lists the checks that can be found, every Monitoring::Sneck::Checks::*
module in @INC other than base, by file name, without loading them.
Where two directories have one, the first is used, as require would.

Returns a hash ref of check names to what each is for, the text after
the dash on the NAME line of its POD, or a empty string for one that
has no such line.

    my $checks = Monitoring::Sneck::Checks->list;
    foreach my $name ( sort( keys( %{$checks} ) ) ) {
        print $name . ' :: ' . $checks->{$name} . "\n";
    }
    # accounts :: checks local user accounts
    # ...

=cut

sub list {
	my ($class) = @_;

	my %checks;
	foreach my $dir (@INC) {
		next if ref($dir) || !-d $dir . '/Monitoring/Sneck/Checks';
		foreach my $file ( glob( $dir . '/Monitoring/Sneck/Checks/*.pm' ) ) {
			my ($name) = $file =~ m{/([a-z][a-z0-9_]*)\.pm\z};
			next if !defined($name) || $name eq 'base' || exists( $checks{$name} );
			$checks{$name} = _pod_name_text($file);
		}
	}

	return \%checks;
} ## end sub list

# Reads what a module says it is for, from the NAME section of its POD,
# for list. The file is read, not loaded, so nothing in it runs.
#
# Args...
#
#     - file :: Path to the module file.
#
# Returns the text after the " - " on the NAME line, or a empty string
# if the file can not be read or has no such line.
#
# Example...
#
#     _pod_name_text('/usr/local/lib/perl5/Monitoring/Sneck/Checks/http.pm');
#     # 'checks HTTP and HTTPS'
sub _pod_name_text {
	my ($file) = @_;

	open( my $fh, '<', $file ) or return '';
	my $in_name;
	while ( my $line = <$fh> ) {
		if ( $line =~ /\A=head1 NAME\s*\z/ ) {
			$in_name = 1;
		} elsif ( $line =~ /\A=/ ) {
			$in_name = 0;
		} elsif ( $in_name && $line =~ /\A\S+ - (.+?)\s*\z/ ) {
			close($fh);
			return $1;
		}
	} ## end while ( my $line = <$fh> )
	close($fh);

	return '';
} ## end sub _pod_name_text

=head2 load

Loads a check, which run does for itself. For when the module is
wanted without running it, such as for its POD. Dies if it can not be
loaded, saying why.

- check :: The name of the check, as for L</run>.

Returns the name of the module, such as Monitoring::Sneck::Checks::http.

    my $module = Monitoring::Sneck::Checks->load('http');
    my $pod    = $INC{'Monitoring/Sneck/Checks/http.pm'};

=cut

sub load {
	my ( $class, $name ) = @_;

	if ( !defined($name) || ref($name) || $name !~ /\A[a-z][a-z0-9_]*\z/ ) {
		die(      'check name "'
				. ( $name // '' )
				. '" is not valid, it must be a-z, 0-9, and _, starting with a letter'
				. "\n" );
	}
	if ( $name eq 'base' ) {
		die("base is what checks are built on, not a check\n");
	}

	my $module = 'Monitoring::Sneck::Checks::' . $name;
	if ( !eval { require( 'Monitoring/Sneck/Checks/' . $name . '.pm' ); 1 } ) {
		die( 'failed to load ' . $module . ', ' . $@ );
	}
	if ( !$module->isa('Monitoring::Sneck::Checks::base') ) {
		die( $module . " is not a check, as it is not a Monitoring::Sneck::Checks::base\n" );
	}

	return $module;
} ## end sub load

=head2 run

Runs a check.

- check :: The name of the check, such as http. Made up of a-z, 0-9,
and _, starting with a letter.

- args :: The args for it, as a array ref, or a string, which
L<Getopt::Long> splits like a shell would.
Default :: []

- timeout :: Seconds it is given.
Default :: 30

Returns a hash ref as below.

- code :: The nagios style return code, 0 for OK, 1 for WARNING, 2 for
CRITICAL, and 3 for UNKNOWN, or -1 if the check could not be loaded.
That includes a bad name, base, and a module that is not a check. Bad
args, unbalanced quotes included, timing out, dying, and returning
something other than 0 to 3 are UNKNOWN.

- stdout :: What it printed as output.

- stderr :: Its errors and warnings.

- combined :: Both, in the order they were printed.

    my $return = Monitoring::Sneck::Checks->run( check => 'dns', args => '-H www.example.org' );
    if ( $return->{code} == -1 ) {
        warn( 'could not load it, ' . $return->{stderr} );
    }

=cut

sub run {
	my ( $class, %opts ) = @_;

	my %return = ( code => -1, stdout => '', stderr => '', combined => '' );
	my $module = eval { $class->load( $opts{check} ) };
	if ( !defined($module) ) {
		return _not_loaded( \%return, $@ );
	}

	my $timeout = $opts{timeout} // $TIMEOUT;
	if ( $timeout !~ /\A[0-9]*\.?[0-9]+\z/ || $timeout <= 0 ) {
		$timeout = $TIMEOUT;
	}

	# stray prints and warnings from it or the modules it uses must not reach sneck's own output
	my ( $stray_stdout, $stray_stderr ) = ( '', '' );
	my $check;
	my $code;
	my $died;
	{
		# the handler that dies is only there inside the eval, where the die is caught. A alarm going off
		# as the eval ends, as when the check died on its own just before it would have, must still have a
		# handler, or it would end the process, but one that does nothing, so nothing gets out of here
		local $SIG{ALRM} = sub { };
		$code = eval {
			local $SIG{ALRM} = sub { die( 'timed out after ' . $timeout . " seconds\n" ) };
			local *STDOUT;
			local *STDERR;
			open( STDOUT, '>', \$stray_stdout );
			open( STDERR, '>', \$stray_stderr );
			Time::HiRes::alarm($timeout);
			$check = $module->new( args => $opts{args}, timeout => $timeout );
			my $returned = $check->check;
			Time::HiRes::alarm(0);
			$returned;
		};
		$died = $@;
		Time::HiRes::alarm(0);
	}

	if ( !defined($check) ) {
		$check = bless( { stdout => '', stderr => '', combined => '' }, $module );
	}
	if ( $died ne '' ) {
		$died =~ s/\s+\z//;
		$check->err( $check->label . ' UNKNOWN - ' . $died . "\n" );
		$code = 3;
	} elsif ( !defined($code) || $code !~ /\A[0-3]\z/ ) {
		$check->err( $check->label . ' UNKNOWN - returned "' . ( $code // 'undef' ) . '", not 0, 1, 2, or 3' . "\n" );
		$code = 3;
	}

	$return{code}     = $code + 0;
	$return{stdout}   = $check->{stdout} . $stray_stdout;
	$return{stderr}   = $check->{stderr} . $stray_stderr;
	$return{combined} = $check->{combined} . $stray_stdout . $stray_stderr;

	return \%return;
} ## end sub run

# Fills in the return hash of run for a check that could not be loaded.
#
# Args...
#
#     - return :: The hash ref run returns, with code -1.
#
#     - why :: Why it could not be loaded. A newline is added if missing.
#
# Returns the same hash ref, with why as stderr and combined.
#
# Example...
#
#     return _not_loaded( \%return, 'base is what checks are built on, not a check' );
#     # { code => -1, stdout => '', stderr => "base is ...\n", combined => "base is ...\n" }
sub _not_loaded {
	my ( $return, $why ) = @_;

	$why =~ s/\s+\z//;
	$return->{stderr}   = $why . "\n";
	$return->{combined} = $why . "\n";

	return $return;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/VVelox/Monitoring-Sneck-Checks/issues>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1;
