package Monitoring::Sneck::Checks::mailq;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::mailq - checks the mail queue of Postfix or Exim

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where postqueue and exim are. Set by tests. Undef means the first of
# their PATHS that is there.
our $POSTQUEUE;
our @POSTQUEUE_PATHS = ( '/usr/sbin/postqueue', '/usr/local/sbin/postqueue' );
our $EXIM;
our @EXIM_PATHS = ( '/usr/sbin/exim4', '/usr/sbin/exim', '/usr/local/sbin/exim' );

# Seconds in each unit exim -bp gives ages in.
our %EXIM_UNITS = ( s => 1, m => 60, h => 3600, d => 86400 );

=head1 SYNOPSIS

    mailq|perl:mailq
    mailq_busy|perl:mailq -w 500 -c 2000 -W 86400
    mailq_exim|perl:mailq -m exim

=head1 DESCRIPTION

Checks how many messages are queued and how old the oldest is, through
postqueue -j for Postfix, 3.1 or newer, or exim -bp for Exim. Without
--mta, Postfix is used if postqueue is there, else Exim.

- CRITICAL :: The count or oldest over its critical.

- WARNING :: The count or oldest over its warning.

- UNKNOWN :: Neither being there, or the command failing, such as
Postfix not running or Exim not run as root or a admin user.

- OK :: Everything else.

The status line says how many are in each Postfix queue, such as
deferred and hold, or how many are frozen for Exim. The oldest
messages follow it, with the reason they are delayed for Postfix.

Exim only gives ages to the minute, hour, or day, depending on how
old.

=head1 OPTIONS

- -m, --mta :: postfix or exim, instead of looking for them.

- -w, --warning :: Range for the count.
Default :: 50

- -c, --critical :: Range for the count.
Default :: 200

- -W, --age-warning :: Range for the age of the oldest, in seconds.
Default :: 14400

- -C, --age-critical :: Range for the age of the oldest, in seconds.

- -l, --list :: How many of the oldest to list after the status line.
Default :: 5

=cut

sub option_spec {
	return ( 'mta|m=s', 'warning|w=s', 'critical|c=s', 'age-warning|W=s', 'age-critical|C=s', 'list|l=i' );
}

sub defaults { return { warning => '50', critical => '200', 'age-warning' => '14400', list => 5 } }

sub ranges { return ( 'warning', 'critical', 'age-warning', 'age-critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	push( @problems, '--mta must be postfix or exim' )
		if defined( $options->{mta} ) && $options->{mta} ne 'postfix' && $options->{mta} ne 'exim';
	push( @problems, '--list must be 0 or more' ) if $options->{list} < 0;

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $postqueue = $POSTQUEUE // ( grep { -x $_ } @POSTQUEUE_PATHS )[0];
	my $exim      = $EXIM      // ( grep { -x $_ } @EXIM_PATHS )[0];
	my $mta       = $self->opt('mta');
	if ( !defined($mta) ) {
		$mta = 'exim'    if defined($exim);
		$mta = 'postfix' if defined($postqueue);
	}
	return $self->finish( $self->UNKNOWN, 'neither Postfix nor Exim found' ) if !defined($mta);

	my $messages;
	if ( $mta eq 'postfix' ) {
		return $self->finish( $self->UNKNOWN, 'postqueue is not there' ) if !defined($postqueue) || !-x $postqueue;
		$messages = $self->postfix_queue($postqueue);
	} else {
		return $self->finish( $self->UNKNOWN, 'exim is not there' ) if !defined($exim) || !-x $exim;
		$messages = $self->exim_queue($exim);
	}

	my $count  = scalar( @{$messages} );
	my @oldest = sort { $b->{age} <=> $a->{age} } @{$messages};
	my $age    = $count ? $oldest[0]{age} : 0;
	my %states;
	$states{ $_->{state} }++ foreach @{$messages};

	my $code = $self->worst(
		$self->threshold_status( $count, $self->opt('warning'),     $self->opt('critical') ),
		$self->threshold_status( $age,   $self->opt('age-warning'), $self->opt('age-critical') )
	);
	$self->perfdata(
		label    => 'messages',
		value    => $count,
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0,
	);
	$self->perfdata(
		label    => 'oldest',
		value    => $age,
		uom      => 's',
		warning  => $self->opt('age-warning'),
		critical => $self->opt('age-critical'),
		min      => 0,
	);

	my @parts = ( $count . ' message' . ( $count == 1 ? '' : 's' ) . ' in the ' . $mta . ' queue' );
	push( @parts, 'oldest ' . _age($age) ) if $count;
	push( @parts, map { $states{$_} . ' ' . $_ } grep { $_ ne 'queued' } sort( keys(%states) ) );

	my @details;
	foreach my $message ( splice( @oldest, 0, $self->opt('list') ) ) {
		my @recipients = @{ $message->{recipients} };
		my $to         = $recipients[0] // 'no one';
		$to = $to . ' and ' . ( @recipients - 1 ) . ' more' if @recipients > 1;
		my $detail = $message->{id} . ' ' . _age( $message->{age} ) . ' ' . $message->{sender} . ' to ' . $to;
		$detail = $detail . ', ' . $message->{reason} if defined( $message->{reason} );
		push( @details, $detail );
	}

	return $self->finish( $code, join( ', ', @parts ), @details );
} ## end sub check

=head2 postfix_queue

Reads the Postfix queue through postqueue -j. Dies if it fails.

- postqueue :: The path to postqueue.

Returns a array ref of hash refs of id, age, in seconds, state, the
queue it is in, such as deferred or hold, sender, <> for a bounce,
recipients, a array ref, and reason, why the first recipient with one
is delayed, or undef.

    my $messages = $check->postfix_queue('/usr/sbin/postqueue');
    # [ { id => '4B7F9A1234', age => 7200, state => 'deferred', sender => 'alice@example.org',
    #     recipients => ['bob@example.net'], reason => 'connect to mx.example.net[192.0.2.25]:25: Connection refused' } ]

=cut

sub postfix_queue {
	my ( $self, $postqueue ) = @_;

	my ( $exit, $output ) = $self->run_command( $postqueue, '-j' );
	die( 'postqueue -j exited ' . $exit . ', ' . ( ( split( /\n/, $output ) )[0] // 'saying nothing' ) . "\n" )
		if $exit;

	require JSON;
	my $json = JSON->new;
	my $now  = time;
	my @messages;
	foreach my $line ( grep { /\S/ } split( /\n/, $output ) ) {
		my $message = eval { $json->decode($line) };
		die( 'postqueue -j printed something not JSON, "' . $line . '"' . "\n" ) if ref($message) ne 'HASH';
		my @recipients = @{ $message->{recipients} // [] };
		my $sender     = $message->{sender} // '';
		my $age        = $now - ( $message->{arrival_time} // $now );
		my ($reason)   = grep { defined($_) && $_ ne '' } map { $_->{delay_reason} } @recipients;
		push(
			@messages,
			{
				id         => $message->{queue_id} // '?',
				age        => $age < 0 ? 0 : $age,
				state      => $message->{queue_name} // '?',
				sender     => $sender eq '' ? '<>' : $sender,
				recipients => [ map { $_->{address} } @recipients ],
				reason     => $reason,
			}
		);
	} ## end foreach my $line ( grep { /\S/ } split( /\n/, $output...))

	return \@messages;
} ## end sub postfix_queue

=head2 exim_queue

Reads the Exim queue through exim -bp. Dies if it fails.

- exim :: The path to exim.

Returns the same as L</postfix_queue>, with a state of frozen or
queued and no reason. Recipients already delivered to are left out.

    my $messages = $check->exim_queue('/usr/sbin/exim4');
    # [ { id => '1i7k9a-0003Zs-Qe', age => 14400, state => 'frozen', sender => '<>',
    #     recipients => ['carol@example.com'], reason => undef } ]

=cut

sub exim_queue {
	my ( $self, $exim ) = @_;

	my ( $exit, $output ) = $self->run_command( $exim, '-bp' );
	# not being a admin is said with a exit of 0 by some versions
	if ( $exit || $output =~ /\Aexim: / ) {
		die( 'exim -bp exited ' . $exit . ', ' . ( ( split( /\n/, $output ) )[0] // 'saying nothing' ) . "\n" );
	}

	my @messages;
	foreach my $line ( split( /\n/, $output ) ) {
		# a message, such as " 4h   12K 1i7k9a-0003Zs-Qe <> *** frozen ***", age, size, id, sender, and flags
		my ( $number, $unit, $id, $sender, $flags ) = $line =~ /\A\s*([0-9]+)([smhd]) +\S+ +(\S+) +<(.*?)>(.*)\z/;
		if ( defined($id) ) {
			push(
				@messages,
				{
					id         => $id,
					age        => $number * $EXIM_UNITS{$unit},
					state      => $flags =~ /\*\*\* frozen \*\*\*/ ? 'frozen' : 'queued',
					sender     => $sender eq ''                    ? '<>'     : $sender,
					recipients => [],
					reason     => undef,
				}
			);
			next;
		} ## end if ( defined($id) )

		# a recipient of the last, D before it if delivered to, +D if to one it was redirected to
		my ( $delivered, $recipient ) = $line =~ /\A\s+(\+?D\s+)?(\S+)\s*\z/;
		push( @{ $messages[-1]{recipients} }, $recipient )
			if defined($recipient) && !defined($delivered) && defined( $messages[0] );
	} ## end foreach my $line ( split( /\n/, $output ) )

	return \@messages;
} ## end sub exim_queue

# Turns seconds into the largest whole unit it fits, as exim -bp does.
#
# Args...
#
#     - seconds :: The seconds.
#
# Returns the text, such as '2d', '4h', '25m', or '40s'.
#
# Example...
#
#     _age(9000);    # '2h'
sub _age {
	my ($seconds) = @_;

	return int( $seconds / 86400 ) . 'd' if $seconds >= 86400;
	return int( $seconds / 3600 ) . 'h'  if $seconds >= 3600;
	return int( $seconds / 60 ) . 'm'    if $seconds >= 60;

	return int($seconds) . 's';
}

1;
