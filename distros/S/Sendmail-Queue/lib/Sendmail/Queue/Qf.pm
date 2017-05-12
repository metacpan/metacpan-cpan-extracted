package Sendmail::Queue::Qf;
use strict;
use warnings;
use Carp;

use Scalar::Util qw(blessed);
use File::Spec;
use IO::File;
use Time::Local ();
use Fcntl qw( :flock );
use Errno qw( EEXIST );
use Mail::Header::Generator ();
use Storable ();

my $fcntl_struct = 's H60';
my $fcntl_structlockp = pack($fcntl_struct, Fcntl::F_WRLCK,
        "000000000000000000000000000000000000000000000000000000000000");
my $fcntl_structunlockp = pack($fcntl_struct, Fcntl::F_UNLCK,
        "000000000000000000000000000000000000000000000000000000000000");

## no critic 'ProhibitMagicNumbers'

# TODO: should we fail if total size of headers > 32768 bytes, or let sendmail die?

use Sendmail::Queue::Base;
our @ISA = qw( Sendmail::Queue::Base );
__PACKAGE__->make_accessors(qw(
	queue_id
	queue_fh
	queue_directory
	sender
	recipients
	headers
	timestamp
	product_name
	helo
	relay_address
	relay_hostname
	local_hostname
	protocol
	received_header
	priority
	qf_version
	data_is_8bit
	user
	macros
));

=head1 NAME

Sendmail::Queue::Qf - Represent a Sendmail qfXXXXXXXX (control) file

=head1 SYNOPSIS

    use Sendmail::Queue::Qf;

    # Create a new qf file object
    my $qf = Sendmail::Queue::Qf->new({
	queue_directory => $dir
    });

    # Creates a new qf file, locked.
    $qf->create_and_lock();

    $qf->set_sender('me@example.com');
    $qf->add_recipient('you@example.org');

    $qf->set_headers( $some_header_data );

    # Add a received header using the information already provided
    $qf->synthesize_received_header();

    $qf->write( );

    $qf->sync();

    $qf->close();

=head1 DESCRIPTION

Sendmail::Queue::Qf provides a representation of a Sendmail qf file.

=head1 METHODS

=head2 new ( \%args )

Create a new Sendmail::Queue::Qf object.

=cut

sub new
{
	my ($class, $args) = @_;

	my $self = {
		headers        => '',
		recipients     => [],
		product_name   => 'Sendmail::Queue',
		local_hostname => 'localhost',
		timestamp      => time,
		priority       => 30000,
		macros         => {},

		# This code generates V6-compatible qf files to work
		# with Sendmail 8.12.
		qf_version     => '6',
		%{ $args || {} }, };

	bless $self, $class;

	return $self;
}

{
	my @base_60_chars = ( 0..9, 'A'..'Z', 'a'..'x' );
	sub _generate_queue_id_template
	{
		my ($time) = @_;
		$time = time unless defined $time;
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime( $time );

		# First char is year minus 1900, mod 60
		# (perl's localtime conveniently gives us the year-1900 already)
		# 2nd and 3rd are month, day
		# 4th through 6th are hour, minute, second
		# 7th and 8th characters are a random sequence number
		# (to be filled in later)
		# 9th through 14th are the PID
		my $tmpl = join('', @base_60_chars[
			$year % 60,
			$mon,
			$mday,
			$hour,
			$min,
			$sec],
			'%2.2s',
			sprintf('%06d', $$)
		);

		return $tmpl;
	}

	sub _fill_template
	{
		my ($template, $seq_number) = @_;

		return sprintf $template,
			$base_60_chars[ int($seq_number / 60) ] . $base_60_chars[ $seq_number % 60 ];
	}
}

=head2 create_and_lock ( [$lock_both] )

Generate a Sendmail 8.12-compatible queue ID, and create a locked qf
file with that name.  If $lock_both is true, we lock the file using
both fcntl and flock-style locking.

See Bat Book 3rd edition, section 11.2.1 for information on how the
queue file name is generated.

Note that we create the qf file directly, rather than creating an
intermediate tf file and renaming aftewards.  This is all good and well
for creating /new/ qf files -- sendmail does it that way as well -- but
if we ever want to rewrite one, it's not safe.

For future reference, Sendmail queuefile creation in queueup() inside
sendmail/queue.c does things in the same way -- newly-created queue files
are created directly with the qf prefix, then locked, then written.

=cut

sub create_and_lock
{
	my ($self, $lock_both) = @_;

	if( ! -d $self->get_queue_directory ) {
		die q{Cannot create queue file without queue directory!};
	}

	# 7th and 8th is random sequence number
	my $seq = int(rand(3600));

	my $tmpl = _generate_queue_id_template( $self->get_timestamp );

	my $iterations = 0;
	while( ++$iterations < 3600 ) {
		my $qid  = _fill_template($tmpl, $seq);
		my $path = File::Spec->catfile( $self->{queue_directory}, "qf$qid" );

		my $old_umask = umask(002);
		my $fh = IO::File->new( $path, O_RDWR|O_CREAT|O_EXCL );
		umask($old_umask);
		if( $fh ) {
			if( ! flock $fh, LOCK_EX | LOCK_NB ) {
				# Opened but couldn't lock.  This means we probably had:
				# A: open (us, create)
				# B: open (them, for read)
				# B: lock (them, for read)
				# A: lock (us, failed)
				# so, give up on this one and try again
				close($fh);
				unlink($path);
				$seq = ($seq + 1) % 3600;
				next;
			}
			if ($lock_both && !fcntl($fh, Fcntl::F_SETLK, $fcntl_structlockp)) {
				# See above... couldn't lock with fcntl
				close($fh);
				unlink($path);
				$seq = ($seq + 1) % 3600;
				next;
			}
			$self->set_queue_id( $qid );
			$self->set_queue_fh( $fh  );
			last;
		} elsif( $! == EEXIST ) {
			# Try the next one
			$seq = ($seq + 1) % 3600;
		} else {
			die qq{Error creating qf file $path: $!};
		}

	}

	if ($iterations >= 3600 ) {
		die q{Could not create queue file; too many iterations};
	}

	return 1;
}

# _tz_diff and _format_rfc2822_date borrowed from Email::Date.  Why?
# Because they depend on Date::Parse and Time::Piece, and I don't want
# to add them as dependencies.
# Similar functions exist in MIMEDefang as well
sub _tz_diff
{
	my ($time) = @_;

	my $diff  =   Time::Local::timegm(localtime $time)
	            - Time::Local::timegm(gmtime    $time);

	my $direc = $diff < 0 ? '-' : '+';
	$diff     = abs $diff;
	my $tz_hr = int( $diff / 3600 );
	my $tz_mi = int( $diff / 60 - $tz_hr * 60 );

	return ($direc, $tz_hr, $tz_mi);
}

sub _format_rfc2822_date
{
	my ($time) = @_;
	$time = time unless defined $time;

	my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime $time;
	my $day   = (qw[Sun Mon Tue Wed Thu Fri Sat])[$wday];
	my $month = (qw[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec])[$mon];
	$year += 1900;

	my ($direc, $tz_hr, $tz_mi) = _tz_diff($time);

	sprintf '%s, %d %s %d %02d:%02d:%02d %s%02d%02d',
	    $day, $mday, $month, $year, $hour, $min, $sec, $direc, $tz_hr, $tz_mi;
}

=head2 synthesize_received_header ( )

Create a properly-formatted Received: header for this message, using
any data available from the object.

The generated header is saved internally as 'received_header'.

=cut

sub synthesize_received_header
{
	my ($self) = @_;

	my $g = Mail::Header::Generator->new();

	my $user = $self->get_user();
	if(!$user) {
		$user = getpwuid($>);
	}

	$self->{received_header} = $g->received({
		helo           => $self->get_helo(),
		hostname       => $self->get_local_hostname(),
		product_name   => $self->get_product_name(),
		protocol       => ($self->get_protocol || ''),
		queue_id       => $self->get_queue_id(),
		recipients     => $self->get_recipients(),
		relay_address  => $self->get_relay_address(),
		relay_hostname => $self->get_relay_hostname(),
		sender         => $self->get_sender(),
		timestamp      => $self->get_timestamp(),
		user           => $user
	});

	return $self->{received_header};
}

=head2 get_queue_filename

Return the full path name of this queue file.

Will return undef if no queue ID exists, and die if queue directory is
unset.

=cut

sub get_queue_filename
{
	my ($self) = @_;

	if( ! $self->get_queue_directory ) {
		die q{queue directory not set};
	}

	if( ! $self->get_queue_id ) {
		return undef;
	}

	return File::Spec->catfile( $self->get_queue_directory(), 'qf' . $self->get_queue_id() );
}

=head2 add_recipient ( $recipient [, $recipient, $recipient ] )

Add one or more recipients to this object.

=cut

sub add_recipient
{
	my ($self, @recips) = @_;

	push @{$self->{recipients}}, @recips;
}

=head2 write ( )

Writes a qfXXXXXXX file using the object's data.

A path to create this queue file under must be provided, by first
calling ->set_queue_directory()

=cut

sub write
{
	my ($self) = @_;

	my $fh = $self->get_queue_fh;

	if ( ! $fh || ! $fh->opened ) {
		die q{write() cannot write without an open filehandle};
	}

	foreach my $chunk (
		$self->_format_qf_version(),
		$self->_format_create_time(),
		$self->_format_last_processed(),
		$self->_format_times_processed(),
		$self->_format_priority(),
		$self->_format_flag_bits(),
		$self->_format_macros(),
		$self->_format_sender_address(),
		$self->_format_recipient_addresses(),
		$self->_format_headers(),
		$self->_format_end_of_qf(),
	) {
		if( ! $fh->print( $chunk, "\n" ) ) {
			die q{Couldn't print to } . $self->get_queue_filename . ": $!";
		}
	}

	return 1;
}

=head2 sync ( )

Force any data written to the current filehandle to be flushed to disk.
Returns 1 on success, undef if no queue file is open, and will die on error.

=cut

sub sync
{
	my ($self) = @_;

	my $fh = $self->get_queue_fh;

	if( ! $fh->opened ) {
		return undef;
	}

	if( ! $fh->flush ) {
		croak q{Couldn't flush filehandle!};
	}

	if( ! $fh->sync ) {
		croak q{Couldn't sync filehandle!};
	}

	return 1;
}

=head2 close ( )

Returns true on success, false (as undef) if filehandle wasn't open, or if
closing the filehandle fails, and dies if the internal filehandle is missing or
isn't a filehandle.

=cut

sub close
{
	my ($self) = @_;

	my $fh = $self->get_queue_fh;

	if( ! ($fh && blessed $fh && $fh->isa('IO::Handle')) ) {
		croak "get_queue_fh() returned something that isn't a filehandle";
	}

	if( ! $fh->opened ) {
		return undef;
	}

	if( ! $fh->close ) {
		return undef;
	}

	return 1;
}

=head2 clone ( )

Return a clone of this Sendmail::Queue::Qf object, containing everything EXCEPT:

=over 4

=item * recipients

=item * queue ID

=item * open queue filehandle

=item * synthesized Received: header

=back

=cut

sub clone
{
	my ($self) = @_;

	# Localize queue_fh first, as dclone() chokes on GLOB values, and we
	# don't want it cloned anyway.
	local $self->{queue_fh};

	my $clone = Storable::dclone( $self );

	# Now clobber the values that shouldn't persist across a clone.  We
	# set_recipients to [] as that's what the constructor does, and delete
	# the rest.
	$clone->set_recipients([]);
	delete $clone->{$_} for qw( sender queue_id received_header queue_fh );

	return $clone;
}

=head2 unlink ( )

Unlink the queue file.  Returns true (1) on success, false (undef) on
failure.

Unlinking the queue file will only succeed if:

=over 4

=item *

we have a queue directory and queue ID configured for this object

=item *

the queue file is open and locked

=back

Otherwise, we fail to delete.

=cut

sub unlink
{
	my ($self) = @_;

	if( ! $self->get_queue_filename ) {
		# No filename, can't unlink
		return undef;
	}

	if( ! $self->get_queue_fh ) {
		return undef;
	}

	# Only delete the queue file if we have it locked.  Thus, we
	# must call unlink() before close(), or we're no longer holding
	# the lock.
	if( 1 != unlink($self->get_queue_filename) ) {
		return undef;
	}
	$self->get_queue_fh->close;
	$self->set_queue_fh(undef);

	return 1;
}


# Internal methods

sub _clean_email_address
{
	my ($self, $addr) = @_;

	# Sanitize $addr a little.  We want to remove any leading/trailing
	# whitespace, and any < > that might be present
	# FUTURE: do we want to do any other validation or cleaning of address
	# here?
	$addr =~ s/^[<\s]+//;
	$addr =~ s/[>\s]+$//;

	return $addr;
}

sub _format_qf_version
{
	my ($self) = @_;
	return 'V' . $self->get_qf_version();
}

sub _format_create_time
{
	my ($self) = @_;
	return 'T' . $self->get_timestamp();
}

sub _format_last_processed
{
	# Never processed, so zero.
	return 'K0';
}

sub _format_times_processed
{
	return 'N0';
}

sub _format_priority
{
	my ($self) = @_;

	return 'P' . $self->get_priority();
}

sub _format_flag_bits
{
	my ($self) = @_;

	my $flags = '';
	# Possible flag bits for V6 queue file:
	# 	8 = Body has 8-bit data (EF_HAS8BIT)
	# 		- This should be set if the body contains any
	# 		  octets with the high bit set.  This can be detected
	# 		  by running
	# 		  	$data =~ tr/\200-\377//
	# 		  (Sendmail does the C equivalent, char|0x80 in a loop)
	# 		  but... we don't have the data here in the qf object,
	# 		  so it must be set in Sendmail::Queue by calling set_data_is_8bit(1).
	$flags .= '8' if $self->get_data_is_8bit();
	# 	b = delete Bcc: header (EF_DELETE_BCC)
	# 		- for our purposes, we want to reproduce the
	#  		  Bcc: header in the queued mail.  Future uses
	#  		  of this module may wish to set this to have
	#  		  it removed.
	# 	d = envelope has DSN RET= (EF_RET_PARAM)
	# 	n = don't return body (EF_NO_BODY_RETN)
	# 		- these two work together to set the value of
	# 		  the ${dsn_ret} macro.  If we have both d and
	# 		  n flags, it's equivalent to RET=HDRS, and if
	# 		  we have d and no n flag, it's RET=FULL.  No d
	# 		  and no n means a standard DSN, and no d with
	# 		  n means to suppress the body.
	# 		- We will avoid setting this one for now, as
	# 		  whether or not to return headers should be a
	# 		  site policy decision.
	# 	r = response (EF_RESPONSE)
	# 		- this is set if this mail is a bounce,
	# 		  autogenerated return receipt message, or some
	# 		  other return-to-sender type thing.
	# 		- we will avoid setting this, since we're not
	# 		  generating DSNs with this code yet.
	# 	s = split (EF_SPLIT)
	# 		- envelope with multiple recipients has been
	# 		  split into several envelopes
	# 		  (dmo) At this point, I think that this flag
	# 		  means that the envelope has /already/ been
	# 		  split according to number of recipients, or
	# 		  queue groups, or what have you by Sendmail,
	# 		  so we probably want to leave it off.
	# 	w = warning sent (EF_WARNING)
	# 		- message is a warning DSN.  We probably don't
	# 		  want this flag set, but see 'r' flag above.
	# Some details available in $$11.11.7 of the bat book.  Other
	# details require looking at Sendmail sources.
	'F' . $flags;
}

sub __format_single_macro
{
	my ($name, $value) = @_;

	$value = '' unless defined $value;   # //= would be nice, but we have to support 5.8.x

	if( length($name) > 1 ) {
		return "\${$name}$value";
	}
	return "\$$name$value";
}

sub _format_macros
{
	my ($self) = @_;

	my $macro_text = '';

	my %macro_hash = %{ $self->get_macros() || {} };

	if( ! exists $macro_hash{r} ) {
		$macro_hash{r} = $self->get_protocol();
	}

	# ${daemon_flags} macro - shouldn't need any of these, so set a
	# blank one.
	$macro_hash{daemon_flags} = '';

	return join("\n",
		map { __format_single_macro($_, $macro_hash{$_}) }
		sort keys %macro_hash);
}

sub _format_sender_address
{
	my ($self) = @_;

	if( ! defined $self->get_sender() ) {
		die q{Cannot queue a message with no sender address};
	}
	return 'S<' . $self->_clean_email_address( $self->get_sender() ). '>';
}

sub _format_headers
{
	my ($self) = @_;

	my @headers;

	# Ensure we prepend our generated received header, if it
	# exists.
	foreach my $line ( split(/\n/, $self->get_received_header || ''), split(/\n/, $self->get_headers) ) {
		# Sendmail will happily deal with over-length lines in
		# a queue file when transmitting, by breaking each line
		# after 998 characters (to allow for \r\n under the
		# 1000 character RFC limit) and splitting into a new
		# line.  This is ugly and breaks headers, so we do it nicely by
		# adding a continuation \n\t at the first whitespace before 998
		# characters.
		# FUTURE: Note that this fails miserably if there is _no_ whitespace in the header.
		if( length($line) > 998 ) {
			my @tokens = split(/ /, $line);
			my $new_line = shift @tokens;
			foreach my $token (@tokens) {
				if( length($new_line) + length($token) + 1 < 998 ) {
					$new_line .= " $token";
				} else {
					push @headers, $new_line;
					$new_line = "\t$token";
				}
			}
			push @headers, $new_line;
		} else {
			push @headers, $line;
		}
	}

	# It doesn't appear that we need to escape any possible
	# ${whatever} macro expansion in H?? lines, based on
	# tests using 8.13.8 queue files.
	#
	# We do not want any delivery-agent flags between ??.
	# Even Return-Path, which ordinarily has ?P?, we shall
	# ignore flags for, as we want to pass on every header
	# that we originally received.
	return join("\n",
		# Handle already-wrapped lines properly, by appending them
		# as-is (no H?? prepend).  Wrapped lines can begin with any
		# whitespace, but it's most commonly a tab.
		map { /^\s/ ? $_ : "H??$_" } @headers);
}

sub _format_end_of_qf
{
	my ($self) = @_;

	# Dot signifies end of queue file.
	return '.';
}

sub _format_recipient_addresses
{
	my ($self) = @_;

	my $recips = $self->get_recipients();
	if( scalar @$recips < 1 ) {
		die q{Cannot queue a message with no recipient addresses};
	}

	my @out;
	foreach my $recip ( map { $self->_clean_email_address( $_ ) } @{$recips} ) {

		push @out, "rRFC822; $recip";


		# R line: R<flags>:<recipient>
		# Possible flags:
		#   P - Primary address.  Addresses via SMTP or
		#       commandline are always considered primary, so
		#       we need this flag.
		#   S,F,D - DSN Notify on success, failure or delay.
		#       We may not want this notification for the
		#       client queue, but current injection with
		#       sendmail binary does add FD, so we will do so
		#       here.
		#   N - Flag says whether or not notification was
		#       enabled at SMTP time with the NOTIFY extension.
		#       If not enabled, S, F and D have no effect.
		#   A - address is result of alias expansion.  No,
		#       we don't want this
		push @out, "RPFD:$recip";
	}

	return join("\n", @out);
}


1;
__END__

=head1 DEPENDENCIES

=head2 Core Perl Modules

L<Carp>, L<File::Spec>, L<Scalar::Util>, L<Time::Local>, L<Fcntl>, L<Errno>

=head2 Other Modules

L<Mail::Header::Generator>

=head1 INCOMPATIBILITIES

There are no known incompatibilities with this module.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to the author.
Patches are welcome.

=head1 AUTHOR

Dave O'Neill, C<< <support at roaringpenguin.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.  All rights reserved.
