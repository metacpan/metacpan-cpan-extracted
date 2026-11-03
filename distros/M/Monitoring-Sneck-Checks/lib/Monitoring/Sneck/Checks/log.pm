package Monitoring::Sneck::Checks::log;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file write_file);

=head1 NAME

Monitoring::Sneck::Checks::log - checks new lines in a log for a regex

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    auth_fails|perl:log -f /var/log/auth.log -r 'Failed password' -c 10
    kernel_errors|perl:log -f /var/log/messages -r 'I/O error|Medium Error' -x 'cd0' -H 3600

=head1 DESCRIPTION

Reads the lines added to a log since it was last run and counts those
matching any --regex and none of --exclude, the same as check_log. The
count is checked against the ranges, so by default any is WARNING.

Where it got to is kept in a state file, one per log and set of
regexes and excludes unless --state is given. A log that was rotated,
a new inode,
or truncated, smaller than before, is read from the start. The first
time, it starts at the end, so what was already there is not counted,
unless --from-start is given. Only whole lines are read, so a line
still being written is left for next time.

A match is only seen by the one run that reads it, so the next run is
OK again, which a poll can easily miss. --hold keeps reporting the
last matches for that many seconds after.

Running it by hand, such as through sneck_check, moves the state on as
well, so give it a --state of its own for that.

Not being able to read the log or the state, or write the state, is
UNKNOWN.

=head1 OPTIONS

- -f, --file :: The log. Required.

- -r, --regex :: A regex for lines to count. May be given more than
once, any matching is enough. Required.

- -x, --exclude :: A regex for lines not to count. May be given more
than once.

- -w, --warning :: Range for the number of lines.
Default :: 0

- -c, --critical :: Range for the number of lines.

- -H, --hold :: Seconds to keep reporting matches for.
Default :: 0

- -n, --lines :: How many matching lines to list after the status
line, once it is not OK.
Default :: 5

- -s, --state :: The state file.
Default :: under /var/cache/sneck.checks, named by --file, --regex, and --exclude

- --from-start :: The first time, read the whole log.

=cut

sub option_spec {
	return (
		'file|f=s', 'regex|r=s@', 'exclude|x=s@', 'warning|w=s', 'critical|c=s',
		'hold|H=i', 'lines|n=i',  'state|s=s',    'from-start'
	);
}

sub defaults { return { warning => '0', hold => 0, lines => 5 } }

sub required { return ( 'file', 'regex' ) }

sub ranges { return ( 'warning', 'critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $name ( 'regex', 'exclude' ) {
		foreach my $regex ( @{ $options->{$name} // [] } ) {
			push( @problems, '--' . $name . ' "' . $regex . '" is not a valid regex' ) if !eval { qr/$regex/; 1 };
		}
	}

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $file       = $self->opt('file');
	my $state_file = $self->state_file;
	my $state      = $self->read_state($state_file);
	return $self->finish( $self->UNKNOWN, 'can not read the state in ' . $state_file ) if !defined($state);

	my @stat = stat($file);
	return $self->finish( $self->UNKNOWN, 'can not read ' . $file . ', ' . $! ) if !defined( $stat[0] );
	my $first_time = !defined( $state->{inode} );
	my $offset     = $state->{offset} // 0;
	if ( $first_time && !$self->opt('from-start') ) {
		$offset = $stat[7];
	} elsif ( !$first_time && ( $state->{inode} != $stat[1] || $state->{device} != $stat[0] || $stat[7] < $offset ) ) {
		$offset = 0;
	}

	my ( $lines, $read_to ) = $self->read_lines( $file, $offset );
	return $self->finish( $self->UNKNOWN, 'can not read ' . $file . ', ' . $read_to ) if !defined($lines);

	my @regexes  = @{ $self->opt('regex') };
	my @excludes = @{ $self->opt('exclude') // [] };
	my @matched;
	foreach my $line ( @{$lines} ) {
		next if !grep { $line =~ /$_/ } @regexes;
		next if grep  { $line =~ /$_/ } @excludes;
		push( @matched, $line );
	}

	my $now       = time;
	my %new_state = ( inode => $stat[1], device => $stat[0], offset => $read_to );
	if ( defined( $matched[0] ) ) {
		%new_state = (
			%new_state,
			matched_at    => $now,
			matched       => scalar(@matched),
			matched_lines => [ @matched[ 0 .. ( $#matched < 49 ? $#matched : 49 ) ] ]
		);
	} elsif ( defined( $state->{matched_at} ) && $now - $state->{matched_at} < $self->opt('hold') ) {
		%new_state = ( %new_state, map { $_ => $state->{$_} } ( 'matched_at', 'matched', 'matched_lines' ) );
	}
	my $problem = $self->write_state( $state_file, \%new_state );
	return $self->finish( $self->UNKNOWN, $problem ) if defined($problem);

	# held matches are reported as they were, saying when
	my $count = scalar(@matched);
	my @shown = @matched;
	my $held  = '';
	if ( !$count && defined( $new_state{matched_at} ) ) {
		$count = $new_state{matched};
		@shown = @{ $new_state{matched_lines} };
		$held  = ', held from ' . ( $now - $new_state{matched_at} ) . ' seconds ago';
	}

	$self->perfdata(
		label    => 'lines',
		value    => scalar(@matched),
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0
	);
	my $code    = $self->threshold_status( $count, $self->opt('warning'), $self->opt('critical') );
	my $message = $count . ' matching line' . ( $count == 1 ? '' : 's' ) . ' in ' . $file . $held;
	$message = $message . ', starting at the end of it' if $first_time && !$self->opt('from-start');
	my @details = ();
	if ( $code != $self->OK ) {
		@details = splice( @shown, 0, $self->opt('lines') );
		push( @details, 'and ' . ( $count - scalar(@details) ) . ' more' ) if $count > scalar(@details);
	}

	return $self->finish( $code, $message, @details );
} ## end sub check

=head2 state_file

Returns the state file, --state or one under the state directory
named by --file, --regex, and --exclude.

=cut

sub state_file {
	my ($self) = @_;

	return $self->opt('state') if defined( $self->opt('state') );
	require Digest::SHA;
	my $name = $self->opt('file') =~ s{[^A-Za-z0-9_.-]+}{_}gr;

	return
		  $Monitoring::Sneck::Checks::base::STATE_DIR . '/log'
		. $name . '-'
		. substr(
			Digest::SHA::sha256_hex(
				join( "\0", $self->opt('file'), @{ $self->opt('regex') }, "\0", @{ $self->opt('exclude') // [] } )
			),
			0, 12
		) . '.json';
} ## end sub state_file

=head2 read_lines

Reads the whole lines of a file from a offset.

- file :: The file.

- offset :: Where to start.

Returns a array ref of the lines, without line endings, and the offset
after the last whole line. Or undef and why if it can not be read.

=cut

sub read_lines {
	my ( $self, $file, $offset ) = @_;

	open( my $fh, '<:raw', $file ) or return ( undef, $! );
	seek( $fh, $offset, 0 )        or return ( undef, $! );
	my $content = do { local $/; <$fh> }
		// '';
	close($fh);

	my $last_newline = rindex( $content, "\n" );
	return ( [], $offset ) if $last_newline < 0;
	my $whole = substr( $content, 0, $last_newline + 1 );

	return ( [ split( /\r?\n/, $whole ) ], $offset + length($whole) );
} ## end sub read_lines

1;
