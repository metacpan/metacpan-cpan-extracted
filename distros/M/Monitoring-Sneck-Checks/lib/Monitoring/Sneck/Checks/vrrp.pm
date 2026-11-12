package Monitoring::Sneck::Checks::vrrp;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);
use Time::HiRes ();

=head1 NAME

Monitoring::Sneck::Checks::vrrp - checks keepalived, freevrrpd, or FreeBSD's CARP being MASTER or BACKUP as it should

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where things are. Set by tests. PID_FILE undef means the first of
# PID_FILES that is there.
our $IFCONFIG = '/sbin/ifconfig';
our $PID_FILE;
our @PID_FILES          = ( '/run/keepalived.pid', '/var/run/keepalived.pid' );
our $DATA_FILE          = '/tmp/keepalived.data';
our $FREEVRRPD_CONF     = '/usr/local/etc/freevrrpd.conf';
our $FREEVRRPD_PID_FILE = '/var/run/freevrrpd.pid';

# The seconds keepalived gets to write its state out.
our $DUMP_WAIT = 3;

=head1 SYNOPSIS

    vrrp|perl:vrrp
    vrrp_primary|perl:vrrp -s master
    vrrp_mixed|perl:vrrp -m VI_WEB -b VI_DB
    carp|perl:vrrp -m em0:1 -b 2
    freevrrpd|perl:vrrp -T freevrrpd -s master

=head1 DESCRIPTION

Checks the state of each VRRP instance of keepalived, each VRID of
freevrrpd, or each CARP vhid on FreeBSD, catching a failover no one
saw, or one that never failed back.

- CRITICAL :: A state other than MASTER or BACKUP, such as FAULT,
INIT, or PARTIAL. One not in the state --master, --backup, or --state
says it should be in. One named by --master or --backup that is not
there. keepalived or freevrrpd not running.

- UNKNOWN :: keepalived not being able to be signalled, as when not run
as root, or not writing its state out. freevrrpd.conf not being
readable.

- OK :: Everything else, including there being nothing to check.

Without --master, --backup, or --state, either of MASTER or BACKUP is
fine, so only FAULT and the like are caught.

A line for each follows the status line, with its interface, ID, and
priority, or advskew for CARP, and addresses for freevrrpd.

=head2 keepalived

keepalived only says what state it is in when sent USR1, at which it
writes /tmp/keepalived.data. So the PID in /run/keepalived.pid, or
/var/run/keepalived.pid, is sent that, and the file read once it has
been written anew, which is waited on for up to three seconds. This
needs root. Instances are named as in keepalived.conf.

=head2 CARP

Read from ifconfig -a, so root is not needed. A vhid is named by its
interface and number, such as em0:1. --master and --backup also take
just the number, which is then every interface with that vhid. FreeBSD
only.

=head2 freevrrpd

freevrrpd has no way of being asked its state. What it does as MASTER
is hold the addresses of the VRID, so each VRID in
/usr/local/etc/freevrrpd.conf is MASTER if every one of its addresses
is on a interface that is up, going by ifconfig -a, BACKUP if none
are, and PARTIAL if only some are. A VRID still starting up, or one
freevrrpd gave up on, looks like BACKUP.

It is running if the PID in /var/run/freevrrpd.pid is. Root is only
needed if freevrrpd.conf, which may have passwords in it, is not
readable otherwise. A VRID is named by its interface and serverid, such
as em0:1, or just the serverid, as for CARP. FreeBSD only.

=head1 OPTIONS

- -T, --type :: What to check, keepalived, freevrrpd, or carp.
Default :: carp on FreeBSD, else keepalived

- -m, --master :: A instance, VRID, or vhid that must be MASTER. May be given
more than once.

- -b, --backup :: A instance, VRID, or vhid that must be BACKUP. May be given
more than once.

- -s, --state :: The state, master or backup, the ones not named by
--master or --backup must be in.

=cut

sub option_spec { return ( 'type|T=s', 'master|m=s@', 'backup|b=s@', 'state|s=s' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	push( @problems, '--type must be keepalived, freevrrpd, or carp' )
		if defined( $options->{type} ) && $options->{type} !~ /\A(?:keepalived|freevrrpd|carp)\z/;
	push( @problems, '--state must be master or backup' )
		if defined( $options->{state} ) && $options->{state} !~ /\A(?:master|backup)\z/i;
	my %as_master = map { $_ => 1 } @{ $options->{master} // [] };
	foreach my $name ( grep { $as_master{$_} } @{ $options->{backup} // [] } ) {
		push( @problems, '"' . $name . '" is given to both --master and --backup' );
	}

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $type = $self->opt('type') // ( $self->os eq 'freebsd' ? 'carp' : 'keepalived' );
	my $instances
		= $type eq 'carp'      ? $self->carp_instances
		: $type eq 'freevrrpd' ? $self->freevrrpd_instances
		:                        $self->keepalived_instances;
	return $self->finish( $self->CRITICAL, $type . ' is not running' ) if !defined($instances);

	# the state each name given must be in
	my %wanted;
	$wanted{$_} = 'MASTER' foreach @{ $self->opt('master') // [] };
	$wanted{$_} = 'BACKUP' foreach @{ $self->opt('backup') // [] };

	my @codes = ( $self->OK );
	my @parts;
	my %have = map { $_ => 1 } map { ( $_->{name}, $_->{alias} // () ) } @{$instances};
	foreach my $name ( grep { !$have{$_} } sort( keys(%wanted) ) ) {
		push( @codes, $self->CRITICAL );
		push( @parts, $name . ' is not there' );
	}

	my %counts = ( MASTER => 0, BACKUP => 0 );
	foreach my $instance ( @{$instances} ) {
		my $state  = $instance->{state};
		my $wanted = $wanted{ $instance->{name} } // $wanted{ $instance->{alias} // '' } // $self->opt('state');
		$wanted = uc($wanted) if defined($wanted);
		$counts{$state}++ if defined( $counts{$state} );

		my $part = $instance->{name} . ' ' . $state;
		if ( !defined( $counts{$state} ) ) {
			push( @codes, $self->CRITICAL );
		} elsif ( defined($wanted) && $state ne $wanted ) {
			push( @codes, $self->CRITICAL );
			$part = $part . ', not ' . $wanted;
		}
		push( @parts, $part );
	} ## end foreach my $instance ( @{$instances} )
	if ( !defined( $parts[0] ) ) {
		my %nothing = ( carp => 'no CARP vhids', freevrrpd => 'no VRIDs', keepalived => 'no VRRP instances' );
		return $self->finish( $self->OK, $nothing{$type} );
	}
	$self->perfdata( label => 'master', value => $counts{MASTER}, min => 0 );
	$self->perfdata( label => 'backup', value => $counts{BACKUP}, min => 0 );

	return $self->finish( $self->worst(@codes), join( ', ', @parts ), map { $_->{detail} } @{$instances} );
} ## end sub check

=head2 keepalived_instances

Has keepalived write its state out and reads its VRRP instances from
it, see L</keepalived>.

Returns undef if keepalived is not running, else a array ref of hash
refs of...

- name :: The instance, as in keepalived.conf.

- state :: MASTER, BACKUP, FAULT, and so on.

- detail :: The line about it for after the status line.

Dies if it can not be signalled or does not write its state out.

=cut

sub keepalived_instances {
	my ($self) = @_;

	my $pid_file = $PID_FILE // ( grep { -e $_ } @PID_FILES )[0];
	my $pid      = defined($pid_file) ? read_file( $pid_file, err_mode => 'quiet' ) : undef;
	return undef if !defined($pid) || $pid !~ /\A\s*([0-9]+)\s*\z/;
	$pid = $1;

	# what the file was before, by inode and mtime, so a old one is not taken for what was asked for
	my @before = Time::HiRes::stat($DATA_FILE);
	if ( !kill( 'USR1', $pid ) ) {
		return undef if $!{ESRCH};
		die( 'can not signal keepalived, PID ' . $pid . ', ' . $! . "\n" );
	}

	# written once it is new and was the same size two looks in a row
	my $give_up = Time::HiRes::time + $DUMP_WAIT;
	my $last_size;
	while (1) {
		Time::HiRes::sleep(0.05);
		my @now      = Time::HiRes::stat($DATA_FILE);
		my $is_new   = @now && ( !@before || $now[1] != $before[1] || $now[9] != $before[9] );
		my $new_size = $is_new ? $now[7] : undef;
		last if $new_size && defined($last_size) && $new_size == $last_size;
		$last_size = $new_size;
		die( 'keepalived, PID ' . $pid . ', did not write ' . $DATA_FILE . "\n" ) if Time::HiRes::time > $give_up;
	}
	my $dump = read_file( $DATA_FILE, err_mode => 'quiet' ) // die( 'can not read ' . $DATA_FILE . ', ' . $! . "\n" );

	# each instance starts with " VRRP Instance = VI_1", then its lines as "   State = MASTER". The first of
	# each line wanted is taken, as the last instance runs on into the sync groups after it.
	my @instances;
	foreach my $about_instance ( split( /^(?=\s*VRRP Instance\s*=)/m, $dump ) ) {
		next if $about_instance !~ /\A\s*VRRP Instance\s*=\s*(\S+)/;
		my $name = $1;
		my %is;
		foreach my $line ( 'State', 'Interface', 'Virtual Router ID', 'Priority', 'Master router' ) {
			( $is{$line} ) = $about_instance =~ /^\s+\Q$line\E\s*=\s*(\S+)/m;
		}
		my $state  = uc( $is{State} // 'unknown' );
		my $detail = $name . ', ' . $state;
		$detail = $detail . ', ' . $is{Interface}                     if defined( $is{Interface} );
		$detail = $detail . ', VRID ' . $is{'Virtual Router ID'}      if defined( $is{'Virtual Router ID'} );
		$detail = $detail . ', priority ' . $is{Priority}             if defined( $is{Priority} );
		$detail = $detail . ', master router ' . $is{'Master router'} if defined( $is{'Master router'} );
		push( @instances, { name => $name, state => $state, detail => $detail } );
	} ## end foreach my $about_instance ( split( /^(?=\s*VRRP Instance\s*=)/m...))

	return \@instances;
} ## end sub keepalived_instances

=head2 carp_instances

Reads the CARP vhids from ifconfig -a.

Returns a array ref of hash refs as for L</keepalived_instances>, name
being the interface and vhid, such as em0:1, with also...

- alias :: The vhid alone.

Dies if not on FreeBSD or ifconfig fails.

=cut

sub carp_instances {
	my ($self) = @_;

	die( 'CARP is only checked on FreeBSD, not ' . $self->os . "\n" ) if $self->os ne 'freebsd';
	my ( $exit, $output ) = $self->run_command( $IFCONFIG, '-a' );
	die( 'ifconfig -a exited ' . $exit . "\n" ) if $exit;

	# a interface is its name and a colon starting a line, then indented lines, among them
	# one such as "carp: MASTER vhid 1 advbase 1 advskew 0" for each vhid
	my @instances;
	foreach my $about_interface ( split( /\n(?=\S)/, $output ) ) {
		next if $about_interface !~ /\A(\S+?):/;
		my $interface = $1;
		while ( $about_interface =~ /^\s+carp: (\S+) vhid ([0-9]+) advbase ([0-9]+) advskew ([0-9]+)/mg ) {
			my ( $state, $vhid, $advbase, $advskew ) = ( uc($1), $2, $3, $4 );
			my $name = $interface . ':' . $vhid;
			push(
				@instances,
				{
					name   => $name,
					alias  => $vhid,
					state  => $state,
					detail => $name . ', ' . $state . ', advbase ' . $advbase . ', advskew ' . $advskew,
				}
			);
		} ## end while ( $about_interface =~ /^\s+carp: (\S+) vhid ([0-9]+) advbase ([0-9]+) advskew ([0-9]+)/mg)
	} ## end foreach my $about_interface ( split( /\n(?=\S)/...))

	return \@instances;
} ## end sub carp_instances

=head2 freevrrpd_instances

Works out the state of each VRID in freevrrpd.conf from the addresses
ifconfig -a shows, see L</freevrrpd>.

Returns undef if freevrrpd is not running, else a array ref of hash
refs as for L</carp_instances>, name being the interface and serverid,
and state MASTER, BACKUP, or PARTIAL.

Dies if not on FreeBSD, freevrrpd.conf can not be read, or ifconfig
fails.

=cut

sub freevrrpd_instances {
	my ($self) = @_;

	die( 'freevrrpd is only checked on FreeBSD, not ' . $self->os . "\n" ) if $self->os ne 'freebsd';
	my $pid = read_file( $FREEVRRPD_PID_FILE, err_mode => 'quiet' );
	return undef if !defined($pid) || $pid !~ /\A\s*([0-9]+)\s*\z/;

	# signal 0 only asks if it is there, which it is even if it is not ours to signal
	return undef if !kill( 0, $1 ) && $!{ESRCH};

	my $conf = read_file( $FREEVRRPD_CONF, err_mode => 'quiet' )
		// die( 'can not read ' . $FREEVRRPD_CONF . ', ' . $! . "\n" );
	my ( $exit, $output ) = $self->run_command( $IFCONFIG, '-a' );
	die( 'ifconfig -a exited ' . $exit . "\n" ) if $exit;

	# the addresses on interfaces that are up, a interface being its name and a colon starting a line,
	# then indented lines. freevrrpd takes its addresses off, and its interface down, as BACKUP.
	my %held;
	foreach my $about_interface ( split( /\n(?=\S)/, $output ) ) {
		next if $about_interface !~ /\A\S+ flags=[0-9a-f]+<([^>]*)>/ || $1 !~ /\bUP\b/;
		$held{$_} = 1 foreach $about_interface =~ /^\s+inet (\S+)/mg;
	}

	# a VRID is what follows each "[VRID]" line, as "option = value" lines
	my @instances;
	my ( $before_first, @vrids ) = split( /^\[VRID\][^\n]*\n/m, $conf );
	foreach my $about_vrid (@vrids) {
		my %is;
		foreach my $option ( 'serverid', 'interface', 'priority', 'addr' ) {
			( $is{$option} ) = $about_vrid =~ /^\s*\Q$option\E\s*=\s*(.*?)\s*$/m;
		}
		next if !defined( $is{serverid} ) || !defined( $is{interface} );

		# such as "10.0.0.1/32, vlan100:192.168.1.1/30", the address being between the device and the prefix
		my @addresses  = map { /\A(?:[^:]+:)?([0-9.]+)/ ? $1 : () } split( /\s*,\s*/, $is{addr} // '' );
		my $held_count = scalar( grep { $held{$_} } @addresses );
		my $state
			= !$held_count                      ? 'BACKUP'
			: $held_count == scalar(@addresses) ? 'MASTER'
			:                                     'PARTIAL';
		my $name = $is{interface} . ':' . $is{serverid};
		push(
			@instances,
			{
				name   => $name,
				alias  => $is{serverid},
				state  => $state,
				detail => $name . ', '
					. $state
					. ', priority '
					. ( $is{priority} // 'unknown' ) . ', '
					. join( ' ', map { $_ . ( $held{$_} ? '' : ' (not held)' ) } @addresses ),
			}
		);
	} ## end foreach my $about_vrid (@vrids)

	return \@instances;
} ## end sub freevrrpd_instances

1;
