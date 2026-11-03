package Monitoring::Sneck::Checks::procs;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::procs - checks how many processes are running

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    sshd_running|perl:procs -C sshd
    php_fpm|perl:procs -C php-fpm -w 2:50 -c 1:100
    worker|perl:procs -r 'bin/worker --queue mail' -u www -c 1:1
    zombies|perl:procs -s Z -w 0 -c 5
    java_rss|perl:procs -C java --rss-warning 4096 --rss-critical 6144
    runaway|perl:procs -u www --cpu-warning 80 --cpu-critical 95 -c 0:

=head1 DESCRIPTION

Counts the processes matching all of the filters given, through
L<Proc::ProcessTable>, and checks the count against the ranges. By
default, none matching is CRITICAL. sneck itself is never counted.

--command is the process name. Linux cuts it to 15 characters, so
match longer names with --regex.

--rss-warning and the like check each matching process, the one using
the most being said. CPU is the percent over its whole life, as ps
shows it, not right now, so a process that only just started spinning
takes a while to show it.

=head1 OPTIONS

- -C, --command :: The process name, exactly.

- -r, --regex :: A regex matched against the whole command line, so
matching anywhere in it is enough.

- -u, --user :: The user it runs as, by name or UID.

- -s, --state :: Its state, one of R, running, S, sleeping, D, waiting
on IO, Z, zombie, T, stopped, or I, idle.

- -w, --warning :: Range for the count.

- -c, --critical :: Range for the count.
Default :: 1:

- --rss-warning :: Range of MiB of memory for each process.

- --rss-critical :: Range of MiB of memory for each process.

- --cpu-warning :: Range of percent CPU for each process.

- --cpu-critical :: Range of percent CPU for each process.

- --fd-warning :: Range of percent of its open file limit each process
is using. Linux only, as it reads /proc. UNKNOWN elsewhere.

- --fd-critical :: Range of percent of its open file limit each process
is using. Linux only, the same as --fd-warning.

=cut

sub option_spec {
	return (
		'command|C=s',   'regex|r=s',      'user|u=s',      'state|s=s',      'warning|w=s',  'critical|c=s',
		'rss-warning=s', 'rss-critical=s', 'cpu-warning=s', 'cpu-critical=s', 'fd-warning=s', 'fd-critical=s'
	);
}

sub defaults { return { critical => '1:' } }

sub ranges {
	return (
		'warning',     'critical',     'rss-warning', 'rss-critical',
		'cpu-warning', 'cpu-critical', 'fd-warning',  'fd-critical'
	);
}

# How Proc::ProcessTable names states on Linux and FreeBSD, by the letter ps uses.
our %STATES = (
	R => [ 'run', 'onprocessor' ],
	S => ['sleep'],
	D => [ 'uwait',   'wait', 'lock' ],
	Z => [ 'defunct', 'zombie' ],
	T => ['stop'],
	I => ['idle'],
);

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	push( @problems, '--regex is not a valid regex' )
		if defined( $options->{regex} ) && !eval { qr/$options->{regex}/; 1 };
	if ( defined( $options->{user} ) && $options->{user} !~ /\A[0-9]+\z/ && !defined( getpwnam( $options->{user} ) ) ) {
		push( @problems, '--user "' . $options->{user} . '" is not a user' );
	}
	push( @problems, '--state must be one of ' . join( ', ', sort( keys(%STATES) ) ) )
		if defined( $options->{state} ) && !$STATES{ uc( $options->{state} ) };

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	require Proc::ProcessTable;
	my $regex = $self->opt('regex');
	my $uid   = $self->opt('user');
	$uid = getpwnam($uid) if defined($uid) && $uid !~ /\A[0-9]+\z/;
	my $state = defined( $self->opt('state') ) ? $STATES{ uc( $self->opt('state') ) } : undef;

	my $count = 0;
	my %most  = ( rss => undef, cpu => undef, fd => undef );
	my $fds   = defined( $self->opt('fd-warning') ) || defined( $self->opt('fd-critical') );
	die("--fd-warning and --fd-critical are only for linux\n") if $fds && $self->os ne 'linux';
	my $unreadable = 0;
	foreach my $process ( @{ Proc::ProcessTable->new->table } ) {
		next if $process->pid == $$;
		next if defined( $self->opt('command') ) && ( $process->fname    // '' ) ne $self->opt('command');
		next if defined($regex)                  && ( $process->cmndline // '' ) !~ /$regex/;
		next if defined($uid)                    && $process->uid != $uid;
		next if defined($state)                  && !grep { $_ eq lc( $process->state // '' ) } @{$state};
		$count++;
		my %used = (
			rss => sprintf( '%.1f', ( $process->rss // 0 ) / 1048576 ),
			cpu => sprintf( '%.1f', $process->pctcpu // 0 )
		);
		if ($fds) {
			my $fd = $self->fd_use( $process->pid );
			if ( !defined($fd) ) {
				$unreadable++;
			} else {
				$used{fd} = $fd->{percent};
				$most{fd} = { %{$fd}, value => $fd->{percent}, pid => $process->pid }
					if !defined( $most{fd} ) || $fd->{percent} > $most{fd}{value};
			}
		} ## end if ($fds)
		foreach my $kind ( 'rss', 'cpu' ) {
			$most{$kind} = { value => $used{$kind}, pid => $process->pid }
				if !defined( $most{$kind} ) || $used{$kind} > $most{$kind}{value};
		}
	} ## end foreach my $process ( @{ Proc::ProcessTable->new...})

	my @filters;
	push( @filters, 'named ' . $self->opt('command') )        if defined( $self->opt('command') );
	push( @filters, 'matching /' . $regex . '/' )             if defined($regex);
	push( @filters, 'as ' . $self->opt('user') )              if defined( $self->opt('user') );
	push( @filters, 'in state ' . uc( $self->opt('state') ) ) if defined($state);
	$self->perfdata(
		label    => 'procs',
		value    => $count,
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0
	);
	my $message = $count . ' process' . ( $count == 1 ? '' : 'es' );
	$message = $message . ' ' . join( ', ', @filters ) if defined( $filters[0] );

	# the process using the most is what is checked, as each must be within the ranges
	my @codes = ( $self->threshold_status( $count, $self->opt('warning'), $self->opt('critical') ) );
	foreach my $kind (
		[ 'rss', 'MiB', 'most memory' ],
		[ 'cpu', '%',   'most CPU' ],
		[ 'fd',  '%',   'most of its open file limit' ]
		)
	{
		my ( $name, $unit, $said ) = @{$kind};
		my ( $warning, $critical ) = ( $self->opt( $name . '-warning' ), $self->opt( $name . '-critical' ) );
		next if ( !defined($warning) && !defined($critical) ) || !defined( $most{$name} );
		my $code = $self->threshold_status( $most{$name}{value}, $warning, $critical );
		push( @codes, $code );
		$self->perfdata(
			label    => $name . '_max',
			value    => $most{$name}{value},
			uom      => $unit eq '%' ? '%' : '',
			warning  => $warning,
			critical => $critical,
			min      => 0
		);
		$message
			= $message . ', '
			. $said . ' '
			. $most{$name}{value}
			. ( $unit eq '%' ? '%' : ' ' . $unit ) . ' by '
			. $most{$name}{pid};
		$message = $message . ', ' . $most{$name}{open} . ' of ' . $most{$name}{limit} if $name eq 'fd';
	} ## end foreach my $kind ( [ 'rss', 'MiB', 'most memory'...])
	$message = $message . ', ' . $unreadable . ' could not be read for open files' if $unreadable;

	return $self->finish( $self->worst(@codes), $message );
} ## end sub check

=head2 fd_use

Works out how much of its open file limit a process is using, from
/proc/PID/fd and the soft limit in /proc/PID/limits. Seeing other
users' processes needs root.

Returns a hash ref of open, limit, and percent, or undef if it can not
be read or has no limit.

=cut

sub fd_use {
	my ( $self, $pid ) = @_;

	my $dir = $Monitoring::Sneck::Checks::base::PROC . '/' . $pid;
	opendir( my $fd_dir, $dir . '/fd' ) or return undef;
	my $open = grep { !/\A\.\.?\z/ } readdir($fd_dir);
	closedir($fd_dir);
	my $limits = eval { $self->proc_file( $pid . '/limits' ) } // return undef;
	my ($limit) = $limits =~ /^Max open files\s+([0-9]+)/m;
	return undef if !$limit;

	return { open => $open, limit => $limit, percent => sprintf( '%.1f', $open / $limit * 100 ) };
} ## end sub fd_use

1;
