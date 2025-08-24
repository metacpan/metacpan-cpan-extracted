package Schedule::Easing;

use strict;
use warnings;

our $VERSION='0.1.1';

use Carp qw/carp confess/;

use Schedule::Easing::Block;
use Schedule::Easing::MD5;
use Schedule::Easing::Numeric;

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my %self=(
		schedule=>$opt{schedule}//[],
		_warnExpired=>$opt{_warnExpired}//0,
	);
	return bless(\%self,$class)->init();
}

my %builder=(
	'block'  =>'Schedule::Easing::Block',
	'md5'    =>'Schedule::Easing::MD5',
	'numeric'=>'Schedule::Easing::Numeric',
);

sub init {
	my ($self)=@_;
	if(ref($$self{schedule}) ne 'ARRAY') { confess('Schedule must be an array') }
	foreach my $ease (@{$$self{schedule}}) {
		if(ref($ease) ne 'HASH') { confess('Schedule entry must be a hash') }
		if(my $builder=$builder{$$ease{type}}) {
			$ease=$builder->new(%$ease,_warnExpired=>$$self{_warnExpired});
		}
		else { confess("Unsupported entry type $$ease{type}") }
	}
	return $self;
}

sub matches {
	my ($self,%opt)=@_;
	$opt{ts}//=time();
	my @res;
	foreach my $event (@{$opt{events}}) {
		my $message;
		my $eref=ref($event);
		if(!$eref)              { $message=$event }
		elsif($eref eq 'HASH')  { $message=$$event{message} } # UNTESTED
		elsif($eref eq 'ARRAY') { $message=$$event[0] }       # UNTESTED
		else                    { carp("Invalid event structure ($eref)"); next }
		my $includes=1;
		foreach my $ease (@{$$self{schedule}}) {
			if(my %data=$ease->matches($message)) {
				$includes=$ease->includes($opt{ts},message=>$message,%data);
				last;
			}
		}
		if($includes) { push @res,$event }
	}
	return @res;
}

sub schedule {
	my ($self,%opt)=@_;
	confess('Not yet supported');
	my @res;
	foreach my $event (@{$opt{events}}) {
		my $message;
		my $eref=ref($event);
		if(!$eref)              { $message=$event }
		elsif($eref eq 'HASH')  { $message=$$event{message} } # UNTESTED
		elsif($eref eq 'ARRAY') { $message=$$event[0] }       # UNTESTED
		else                    { carp("Invalid event structure ($eref)"); next }
		my $scheduled=0;
		foreach my $ease (@{$$self{schedule}}) {
			if(my %data=$ease->matches($message)) {
				$scheduled=$ease->schedule(message=>$message,%data);
				last;
			}
		}
		push @res,[$scheduled,$event];
	}
	return @res;
}

1;

__END__

=pod

=head1 NAME

Schedule::Easing - Scheduled ramp-up and linear activation of events

=head1 VERSION

Version 0.1.1

=head1 SYNOPSIS

  use Schedule::Easing;
  
  my $easing=Schedule::Easing->new(
    schedule=>[
      {
        type  =>'md5',
        name  =>'Sample one',
        match =>qr/^prefix (?<digest>\w+ \d+) at time \d+$/,
        tsA   =>123_000,
        tsB   =>456_000,
        begin =>0,
        final =>1,
        ...
      },
      {
        type  =>'linear',
        name  =>'Sample two',
        match =>qr/^prefix \w+ (?<value>\d+) at time \d+$/,
        tsA   =>123_000,
        tsB   =>456_000,
        ymin  =>100, # the minimum <value>
        ymax  =>999, # the maximum <value>
        begin =>0.05,
        final =>0.95,
      },
    ],
  );

  my @matches=$easing->matches(ts=>time(), events=>\@events);

=head1 DESCRIPTION

Easing provides stateless, stable selection of point-in-time events that need to be exposed with increasing frequency over a period of time.  Events may be infrequent or real-time, low or high volume, but must contain some manner of identification for categorization, such as a reported line number or non-random content that can be used to compute a message digest.  As time increases, the percentage of events emitted with be monotonically increasing.

Contrasted with throttling, which suppresses I<any> incoming event in real-time once a threshold is exceeded, easing ensures that new events are uniformly distributed over the configured period of time.  Whereas throttling requires cached statistics, easing can be performed without resident processes or data stores.

As an example, easing permits an alerting system to be configured based on a large number of reported failures I<that already exist>, without immediately shifting from "no alerts" to a large number of unmanageable alerts.  Easing can also be leveraged in A-to-B activation scenarios, supporting staged deployments or similar.

=head2 EXAMPLE

Suppose the following failures and warnings are logged

  [1755487809] WARNING stock exceeded, requested 24 apples
  [1755487826] ERROR invalid type in request, handler.pm line 270
  [1755487863] ERROR invalid type in request, handler.pm line 133
  [1755487887] WARNING stock exceeded, requested 36 plums
  [1755487903] ERROR logging failure for order 8052060, will retry from logger.pm line 323
  [1755487925] ERROR invalid type in request, handler.pm line 485
  [1755487944] WARNING stock exceeded, requested 144 cherries
  [1755487947] ERROR logging failure for order 7463359, will retry from logger.pm line 323
  [1755487969] ERROR logging failure for order 8405888, will retry from logger.pm line 323
  [1755487990] ERROR logging failure for order 5695806, will retry from logger.pm line 323
  [1755488009] INFO stock increased, 144 apples
  [1755488012] WARNING stock exceeded, requested 60 grapes
  [1755488026] ERROR logging failure for order 4762096, will retry from logger.pm line 323
  [1755488049] INFO stock increased, 144 cherries
  [1755488059] ERROR invalid type in request, handler.pm line 19
  [1755488060] ERROR logging failure for order 9096813, will retry from logger.pm line 323
  [1755488187] INFO stock increased, 144 plums
  [1755488245] INFO stock increased, 144 grapes
  [1755488259] ERROR invalid type in request, handler.pm line 299

The first category of errors, Invalid type, could be transmitted based on the line number of the error.  The two timestamps have been chosen for this example (roughly 22 minutes).  At the beginning of the window, no matching lines will emit.  But the middle of the window (11min), lines with numbers 0 through 250 will emit.  At the end and after, all matching lines will emit.

  {
    name=>'Invalid type errors', type=>'numeric',
    match=>qr/ERROR invalid type.*line (?<value>\d+)/,
    ymin=>0, ymax=>500,
    begin=>0.00, final=>1.00,
    tsA=>1755487800, tsB=>1755489160,
  }

The logging failures contain order numbers that can be used to compute a message digest.  Over the configured window of time, messages will appear only if their digest exceeds the percent offset within the window.  At the halfway point (11min), roughly 50% of all messages will be transmitted.

  {
    name=>'Logging failure', type=>'md5',
    match=>qr/ERROR logging failure for order (?<digest>\d+)/,
    begin=>0.00, final=>1.00,
    tsA=>1755487800, tsB=>1755489160,
  },

Finally, all stock messages can be blocked.

  {
    name=>'Ignore stock messages', type=>'block',
    match=>qr/(.*(?:INFO|WARNING) stock.*)/,
  },

With the above configurations, if the sample lines arrive at the given timestamps, the following will be included in the output.

  [1755488026] ERROR logging failure for order 4762096, will retry from logger.pm line 323
  [1755488059] ERROR invalid type in request, handler.pm line 19

If the logging failures occur again for the same order numbers, on retries, they may be included in the output at a later time.  The line-numbered failures will also eventually be included later.  Eventually, both types of errors will always be output, because the C<final> value is set to 1/one.  The stock messages will always be blocked.

As a simple example, this shows the basic values.  In practical use, the configured starting and ending times are likely to span days or weeks, if the errors and warnings will be of a type that requires manual review and correction by individuals.  Presumably errors and warnings of these types are common in the system, don't require immediate action, already have other alarms if they reach a critical state, but nevertheless represent ongoing inefficiencies or technical debt that should be addressed.

=head1 Configuration

The configuration is an array of line matchers and associated easing configuration.  For each input line, configured patterns will be checked in order.  The first matching pattern will compute if the message is to be included based on the easing configuration, and will either be emitted or omitted.  When a line is matched, no additional line matchers will be checked.  If a line matches no configured pattern, I<it is always emitted>.

In general, each easing configuration requires a C<type>, C<match> pattern, two timestamps to configure the window, and a C<begin> and C<final> message rate threshold.

=head2 Window Specification

Most easing types require a start and end, C<tsA> and C<tsB>, to specify the activation window.  Values are Unix epoch seconds.  By default, C<tsA> represents the easing initialization, before which all matching messages will be blocked.  By default, C<tsB> represents the easing conclusion, after which all matching messages will be included.  The common use case is that, between the two times, the rate of included messages will increase linearly from 0% to 100%.

=head2 Message Thresholds

The default thresholds are C<begin=0> and C<final=1>, so message inclusion only begins after C<tsA>, and 100% of messages are included after C<tsB>.

Adjusting the values controls the initial and final message rates.  At C<begin=0.1> and C<final=0.85>, for example, initially 10% of matching messages will be included, and by C<tsB> 85% will be included.  The remaining 15% will never be emitted, unless the configuration is subsequently updated, but note that the content of the 15% omitted will depend on the easing type selected.

For all easing types, if C<final=1>, matching messages are always included after C<tsB>.  When C<finalE<lt>1>, messages that weren't included before C<tsB> will I<never be included> after C<tsB>.

=head2 Easing Types

The value given to each message when comparing against the currently-computed threshold is determined by the easing type.

=head3 Numeric

The numeric type requires that the C<match> configuration include a capture group named C<value> that contains a Perl number:

  match=>qr/ERROR invalid type.*line (?<value>\d+)/,

The captured value is converted to a percentage by configuring the expected range of values:

  ymin=>0
  ymax=>500,

Values outside the range are not an error.  For values below C<ymin>, they will be included starting at C<tsA>.  If a matched value exceeds the configured C<ymax>, it will only be emitted when C<final=1> starting at C<tsB>; if C<finalE<lt>1>, it will never be emitted.

=head3 MD5

The MD5 type requires that the C<match> configuration include one capture group named C<digest>, or multiple groups following the pattern C<digest.*>:

  match=>qr/ERROR logging failure for order (?<digest>\d+)/
  match=>qr/^hello (?<digest0>\w+) (?<digest1>\w+)/

All matching groups are ordered by name, concatenated, and used to compute the message digest.  The digest value is used modulo the time range, C<tsB>-C<tsA>, to determine if the message crosses the current threshold for inclusion.

=head3 Block

For configuration convenience, messages that match C<match> can always be blocked by setting C<type=block>.

=head2 Unmatched Lines

All lines are included by default, so setting C<schedule=[]> is equivalent to cat(1).  Lines are handled by the first easing configuration I<that matches> the line, which will either include or dispense with the line.  If a line matches no easing configuration, it will be included.

=head2 Easing Functions

The easing function computes the threshold, C<p>, for the current timestamp, C<ts>, during the configured window, C<tsA> to C<tsB>, given the C<begin> and C<final> rates.  Roughly speaking, C<p> is the percentage of matching messages that will be included at that time.

The default function is C<linear>, but others can be selected within the easing configuration by indicating a C<shape> and, if applicable, a C<shapeopt> array.

=head3 Linear

The threshold is a linear ramp from C<begin> to C<final>.  This is the default and is equivalent to:

  shape   =>'linear',
  shapeopt=>[],

=head3 Step

The thresholds increase from C<begin> to C<final> in a uniform configured number of steps:

  shape   =>'step',
  shapeopt=>[steps],

When C<steps=1>, no messages will be included until C<tsB>.

When C<steps=2>, there will be a step to the halfway threshold at C<0.5(tsA+tsB)>, and a final step at C<tsB>.

=head3 Polynomial

The thresholds follow the curve with the configured exponent:

  shape   =>'power',
  shapeopt=>[exponent],

Exponents greater than one delay the starting rate at which messages appear.  Fractional exponents less than one will cause an increase in initial message rates.

For example, if C<ts> is in the exact middle of the window, supposing C<begin=0> and C<final=1>, then C<p=0.5> for C<exponent=1>.  At C<exponent=2>, however, C<p=0.25>, so fewer messages are included.  At C<exponent=0.5>, C<p=0.707>, so more messages are included.

=head2 Event Objects

All above examples call C<$easing-E<gt>matches(events=>[event, ...])> using linewise matches.  That is C<event="..."> is a message string.

An array of event objects can be passed instead of simple strings.  An individual C<event> can be a hash of the form C<{message=>"...",...}> or an array of the form C<[message,...]>, and the C<message> will be used for matching purposes.  The returned list will be the entire matching event objects.

=head1 SEE ALSO

L<Algorithm::Easing>

Throttling solutions

=cut
