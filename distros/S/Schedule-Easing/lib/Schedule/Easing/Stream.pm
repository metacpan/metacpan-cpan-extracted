package Schedule::Easing::Stream;

use strict;
use warnings;
use Carp qw/confess/;

our $VERSION='0.1.2';

# Presumably there can be a single clock/alarm setting.
# If clock=2, then on timeout it will update the timer,
# but clock=2 also means that the batch should be processed at that time, if non-empty.
# Ergo if clock=undef/0, it means there will be no update of the logged time,
# but also the batch will always wait for more.
# Now it would be possible with clock=2 to have resetTime=3, and every two seconds it would count
# down, but that means the logged time would actually only update every 3sec.
# Instead of introducing such complexity, it's just easier to say that things happen every 2sec.
# Now if there is a batch with a timeout of clock=2, it means that the logged time Must Update
# every 2sec, and that may not be desirable.  If the update() function is a no-op, then the
# logged time would never actually change.  Presumably they could provide their own countdown
# function in such cases to control if/when the logged time is actually updated, if every.
# So I think it makes sense, clock=N means alarm(N) will perform update() and input(@batch).

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my %self=(
		fh    =>\*STDIN,
		input =>undef,
		update=>undef,
		lines =>undef,
		sleep =>0,
		clock =>undef,
		regexp=>undef,
		batch =>1,
		(ref($ref)?%$ref:()),
	);
	foreach my $k (grep {exists($self{$_})} keys(%opt)) { $self{$k}=$opt{$k} }
	if(0==grep {defined($_)} @self{qw/lines clock regexp/}) { $self{lines}=1 }
	return bless(\%self,$class);
}

sub sleepwait {
	my ($self)=@_;
	my $fh=$$self{fh};
	if($$self{sleep}&&($$self{sleep}>=1)) {
		my $rin='';
		vec($rin,fileno($fh),1)=1;
		if(!select($rin,'','',0.1)) { sleep($$self{sleep}) }
	}
}

sub processBatch {
	my ($self,$batch,$wait)=@_;
	if(@$batch) { my @copy=@$batch; @$batch=(); &{$$self{input}}(@copy) }
	if($wait) { $self->sleepwait() }
}

sub read {
	my ($self)=@_;
	my $fh=$$self{fh};
	if(ref($$self{input})  ne 'CODE')                   { confess('Input callback must be provided') }
	if($$self{update}&&(ref($$self{update}) ne 'CODE')) { confess('Update must be a callback') }
	#
	my @batch;
	my $countdown=$$self{lines};
	if($$self{clock}&&($$self{clock}>=1)) {
		$SIG{ALRM}=sub {
			$self->processBatch(\@batch,1);
			&{$$self{update}}(time());
			alarm($$self{clock});
		};
		alarm($$self{clock});
	}
	while(<$fh>) {
		if($$self{regexp}&&(my ($ts)=($_=~$$self{regexp}))) {
			$self->processBatch(\@batch,0);
			&{$$self{update}}($ts); 
			$self->processBatch([$_],1);
			$countdown=$$self{lines};
			next;
		}
		push @batch,$_;
		if(1+$#batch<$$self{batch}) { next }
		$self->processBatch(\@batch,1);
		if(defined($countdown)&&(($countdown-=$$self{batch})<=0)) {
			&{$$self{update}}(time());
			$countdown=$$self{lines};
		}
	};
	$self->processBatch(\@batch,0);
	return $self;
}

1;

__END__

=pod

=head1 NAME

Schedule::Easing::Stream - Control timestamp update, queuing, and buffering of input.

=head1 SYNOPSIS

	my $stream=Schedule::Easing::Stream->new(
		fh    =>\*STDIN,
		input =>sub { my (@lines)=@_; ... },
		update=>sub { my ($epoch)=@_; ... },

		### configuration ###
		lines =>5,
		clock =>10,
		regexp=>qr/(\d+)/,
		batch =>16,
		sleep =>4,
	);
	
	$stream->read();

=head1 DESCRIPTION

This stream handler permits quick configuration for various forms of line buffering and queueing, coupled with a mechanism to control associated per-line timestamps.  By default, when passing lines through a stream, each line is processed individually by the C<input> handler and the C<update> callback, if defined, will be called with the current epoch time.  In the default configuration, the handler is equivalent to:

	while(<$fh>) {
		&input(line);
		&update(time());
	}

Ideally the C<input> can be called with batches of lines for better runtime before and, for most applications, it's unnecessary to call for the system C<time()> with every new line of input, particularly when processing historical data, or when data is arriving quickly.

=head1 CONFIGURATION

=head2 Calling Update

By default, the C<update> callback, if defined, is called for every single line of input.  This can be adjusted by setting one or more of C<lines>, C<clock>, or C<regexp>.

=head3 Lines

Setting C<lines=E<gt>N> will invoke C<update> every C<N> lines.  Subsequent lines will retain the new value until the line counter again reached C<N>.  If C<clock> is used, it will not reset the line counter.  If C<regexp> is used and matches a line, it will reset the line counter.

=head3 Clock

Setting C<clock=E<gt>T> uses C<alarm()> to invoke C<update> every C<T> seconds.  This occurs even while waiting for additional input.  Subsequent lines retain the new value until the another C<T> seconds have passed.

=head3 Regular Expression

Setting C<regexp=E<gt>qr/...(re).../> takes the I<epoch seconds> from the input line itself.  When C<re> matches, the value in the I<first capture group> is passed to C<update>.  Subsequent lines use the captured value unless they also match.  If C<lines> is in use, the line counter will be reset.  Any C<clock> alarm is not reset.  

This option is primarily useful for processing of existing, timestamped logs.  Be cautious that using C<regexp> in combination with other contigurations can result in time running backwards or randomly.

=head2 Batching

Setting C<batch=E<gt>M> will collect C<M> lines before calling C<input(@batch)>.  The C<update> callback is called after the batch is processed, so all lines in the batch will have the same timestamp.  This is useful for high-speed data where many lines are read from an existing file, or from a tool producing data, every second.

If C<lines> is set, the line counter is checked only once after C<M> batched lines are processed, after which the line counter will be I<reset>.  Therefore, C<linesE<gt>M> may only perform an C<update> in some of the batches, whereas C<linesE<lt>=M> will call C<update> after every batch.

If C<clock> is set, when the C<alarm()> fires any existing, partial batch will be passed to C<input> first, and then C<update> will be called.  This permits "batching with timeout" to ensure that no batch is held for more than C<clock> seconds, but it can output partial batches.

If C<regexp> is set, it first processes any existing, partial batch, before passing the single matched line to C<input>.

To enforce a fixed batch size despite other settings, the C<input> handler can perform its own batching.

=head2 Sleeping

If C<sleep=E<gt>S> is set, after processing a batch (possibly a single line), the stream handler will wait C<S> seconds if no input is currently available on C<fh>.  For high-speed data, setting C<sleep> may introduce a slight delay to check the state of the C<fh>.  For mixed speed data, be cautious that the chosen C<sleep> does not result in a full input buffer that blocks incoming data.

Sleeping may be interrupted by the C<alarm()> call when C<clock> is set, so there will be no delay before receiving the next line.

When C<regexp> is set, sleeping will not occur for any existing, partial batch, only after the matched line is processed.

=cut
