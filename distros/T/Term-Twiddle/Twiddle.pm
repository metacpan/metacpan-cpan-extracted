package Term::Twiddle;

use 5.005;
use strict;
use vars qw( @ISA $VERSION );

$VERSION = '2.73';

use Time::HiRes qw(setitimer ITIMER_REAL);
#$SIG{'ALRM'} = \&_spin;
$SIG{'INT'} = $SIG{'TERM'} = \&_set_alarm(0);

## for normal spinning routines
use vars qw( $thingy $rate $probability $stream $_step );

## for whole line motion routines (e.g., bounce, swish)
use vars qw( $width $delay $_dtime $_offset $_scale $_time $_xpos);

sub new {
    my $self  = {};
    my $proto = shift;
    my $class = ref($proto) || $proto;
    bless $self, $class;

    $self->init(shift);

    return $self;
}

sub init {
    my $self = shift;
    my $args = shift;

    $self->thingy( ( $args->{'thingy'} ? $args->{'thingy'} : [ "\\", "|", "/", "-" ] ) );
    $self->rate( ( $args->{'rate'}   ? $args->{'rate'}   : 0.175 ) );
    $self->probability( ( $args->{'probability'} ? $args->{'probability'} : 0 ) );
    $self->stream( ( $args->{'stream'} ? $args->{'stream'} : *STDOUT ) );

    $self->type( ( $args->{'type'} ? $args->{'type'} : '' ) );
    $self->width( ( $args->{'width'} ? $args->{'width'} : _get_max_width() ) );
    $self->delay( ( $args->{'delay'} ? $args->{'delay'} : undef ) );
}

sub start {
    my $self = shift;
    _set_alarm( $rate );
}

sub stop {
    my $self = shift;
    _set_alarm(0);
}

sub thingy {
    my $self       = shift;
    my $new_thingy = shift;
    $_step = 0;

    return $thingy = ( $new_thingy
		       ? $new_thingy
		       : $thingy );
}

sub rate {
    my $self     = shift;
    my $new_rate = shift;

    return $rate = ( defined $new_rate
		     ? $new_rate
		     : $rate );
}

sub probability {
    my $self     = shift;
    my $new_prob = shift;

    return $probability = ( defined $new_prob
			    ? $new_prob
			    : $probability );
}

sub stream {
    my $self       = shift;
    my $new_stream = shift;

    return $stream = ( defined $new_stream
		       ? $new_stream
		       : $stream );
}

sub random {
    my $self = shift;
    my $prob = shift;
    $prob = ( defined $prob ? $prob : 25 );
    $self->probability($prob);
}

sub type {
    my $self = shift;
    my $type = shift || '';

    if( $type eq 'bounce' ) {
	$_offset = $width/2;
	$_scale  = $_offset/0.9;
	$delay   = 0.01;
	$_dtime  = 0.038;
	$SIG{'ALRM'} = \&_bounce;
    }

    elsif( $type eq 'swish' ) {
	$_offset = $width/2;
	$delay   = 0.0001;
	$_dtime  = 0.1;
	$SIG{'ALRM'} = \&_swish;
    }

    else {
	$SIG{'ALRM'} = \&_spin;
	return 1;
    }
}

sub width {
    my $self      = shift;
    my $new_width = shift;

    $width = ( defined $new_width
	       ? $new_width
	       : $width );

    ## set dependant package vars
    $_offset = $width/2;
    $_scale  = $_offset/0.9;

    return $width;
}

sub delay {
    my $self      = shift;
    my $new_delay = shift;

    return $delay = ( defined $new_delay
		      ? $new_delay
		      : $delay );
}

## send me a SIGALRM in this many seconds (fractions ok)
sub _set_alarm {
    return setitimer(ITIMER_REAL, shift, 0);
}

sub _get_max_width {
    my $width;

    ## suck in Term::Size, if possible
    eval { require Term::Size };

    ## no Term::Size; try using tput to find terminal width
    if( $@ ) {
	## find tput via poor man's "which"
	for my $path ( split /:/, $ENV{'PATH'} ) {
	    next unless -x "$path/tput";
	    $width = `$path/tput cols`;
	    chomp $width;
	    last;
	}
    }

    ## we have Term::Size; use it
    else {
	($width, undef) = &Term::Size::chars(*STDERR);
    }

    ## assign a default if not already assigned
    $width ||= 80;

    return $width;
}

sub _bounce {

  BOUNCE: {
	my $old_fh = select($stream);
	local $| = 1;

	my $oldx = $_xpos;

	## original damped harmonic motion filched from some java
	## somewhere...please forgive me! I can't remember where!
	$_time += $_dtime;
	$_xpos = int( $_offset + ($_scale * ( abs(1.7 * cos $_time) - 0.9 ) ) );

	print $stream ' ' x $_xpos;
	print $stream "*";
	print $stream ' ' x ( $oldx > $_xpos ? $oldx-$_xpos : 0 );
	print $stream "\r";

	select($old_fh);
    }

    $SIG{'ALRM'} = \&_bounce;
    _set_alarm($delay);
}

sub _swish {

  SWISH: {
	my $old_fh = select($stream);
	local $| = 1;

	my $oldx = $_xpos;

	## orignal swishing motion filched from Term::ReadKey test.pl
	## by Kenneth Albanowski <kjahds@kjahds.com>
	$_time += $_dtime;
	$_xpos = int( $_offset * (cos($_time) + 1) );

	print $stream ' ' x $_xpos;
	print $stream "*";
	print $stream ' ' x ( $oldx > $_xpos ? $oldx-$_xpos : 0 );
	print $stream "\r";

	select($old_fh);
    }

    $SIG{'ALRM'} = \&_swish;
    _set_alarm($delay);
}

sub _spin {

  SPIN: {
	my $old_fh = select($stream);
	local $| = 1;
	print $stream $$thingy[$_step],
	  chr(8) x length($$thingy[$_step]);
	select($old_fh);
    }

    $_step = ( $_step+1 > $#$thingy ? 0 : $_step+1 );

    ## randomize if required
    $rate = rand(0.2)
      if $probability && (rand() * 100) < $probability;

    $SIG{'ALRM'} = \&_spin;
    _set_alarm($rate);
}

sub DESTROY {
    shift->stop;
}

1;
__END__

=head1 NAME

Term::Twiddle - Twiddles a thingy while-u-wait

=head1 SYNOPSIS

  use Term::Twiddle;
  my $spinner = new Term::Twiddle;

  $spinner->start;
  system('tar', '-xvf', 'some_phat_tarfile.tar');
  $spinner->stop;

  $spinner->random;  ## makes it appear to really struggle at times!
  $spinner->start;
  &some_long_function();
  $spinner->stop;

=head1 DESCRIPTION

Always fascinated by the spinner during FreeBSD's loader bootstrap,
I wanted to capture it so I could view it any time I wanted to--and I
wanted to make other people find that same joy I did. Now, anytime you
or your users have to wait for something to finish, instead of
twiddling their thumbs, they can watch the computer twiddle its thumbs.

=head2 During Twiddling

Once the twiddler/spinner is in motion you need to do something (e.g.,
unpack a tar file, call some long function, etc.). You can do almost
anything in between B<start> and B<stop> as long as there are no
B<sleep> calls in there (unless the process has been forked, as in a
Perl B<system> call). From Time::HiRes:

    Use of interval timers may interfere with alarm(), sleep(), and
    usleep().  In standard-speak the "interaction is unspecified",
    which means that anything may happen: it may work, it may not.

Try not to do any terminal I/O while the twiddler is going (unless you
don't mind dragging the twiddler around with your cursor).

=head2 Spinner Methods

=over 4

=item B<new>

Creates a new Twiddle object:

    my $spinner = new Term::Twiddle;

Optionally initializes the Twiddle object:

    ## a moderately paced spinner
    my $spinner = new Term::Twiddle( { rate => 0.075 } );

=item B<start>

Starts the twiddler twiddling:

    $spinner->start;

=item B<stop>

Stops the twiddler:

    $spinner->stop;

=item B<thingy>

Creates a new thingy. The argument is a reference to a list of strings
to print (usually single characters) so that animation looks good. The
default spinner sequence looks like this:

    $spinner->thingy( [ "\\", "|", "/", "-" ] );

an arrow could be done like this:
    $spinner->thingy( [
                       "---->",
                       " ----->",
                       "  ----->",
                       "   ----->",
                       "    ----->|",
                       "     ---->|",
                       "      --->|",
                       "       -->|",
                       "        ->|",
                       "         >|",
                       "          |",
                       "           "]);


Look at the test.pl file for this package for more fun thingy ideas.

=item B<rate>

Changes the rate at which the thingy is changing (e.g., spinner is
spinning). This is the time to wait between thingy characters (or
"frames") in seconds. Fractions of seconds are supported. The default
rate is 0.175 seconds.

    $spinner->rate(0.075);  ## faster!

=item B<probability>

Determines how likely it is for each step in the thingy's motion to
change rate of change. That is, each time the thingy advances in its
sequence, a random number from 1 to 100 is generated. If
B<probability> is set, it is compared to the random number. If the
probability is greater than or equal to the randomly generated number,
then a new rate of change is randomly computed (between 0 and 0.2
seconds). 

In short, if you want the thingy to change rates often, set
B<probability> high. Otherwise set it low. If you don't want the rate
to change ever, set it to 0 (zero). 0 is the default.

    ## half of all sequence changes will result in a new rate of change
    $spinner->probability(50);
    $spinner->start;
    do_something;
    $spinner->stop;

The purpose of this is to create a random rate of change for the
thingy, giving the impression that whatever the user is waiting for
is certainly doing a lot of work (e.g., as the rate slows, the
computer is working harder, as the rate increases, the computer is
working very fast. Either way your computer looks good!).

=item B<random>

Invokes the B<probability> method with the argument specified. If no
argument is specified, 25 is the default value. This is meant as a
short-cut for the B<probability> method.

    $spinner->random;

=item B<stream>

Select an alternate stream to print on. By default, STDOUT is printed to.

    $spinner->stream(*STDERR);

=back

=head2 Alternative Spinner Methods

Since version 2.70, B<Term::Twiddle> objects support a couple of new
spinners that aren't so "plain". 2.70 includes a B<bounce>ing ball and
a B<swish>ing object (that's the best name I could think to call it).

The following methods are used to activate and customize these new
spinners.

=over 4

=item B<type>

Use this method to set the type of spinner. The default type (no type)
is whatever B<thingy> is set to. Two other currently supported types
are B<bounce>, and B<swish>. These may be set in the constructor:

    my $sp = new Term::Twiddle({ type => 'bounce' });
    $sp->start;

or you can set it with this B<type> method:

    my $sp = new Term::Twiddle;
    $sp->type('bounce');

There is currently no way to add new B<type>s without some hacking
(it's on the "to do" list).

=item B<width>

This method is only used when B<type> is undefined (i.e., a normal
spinner). B<width> determines how wide the B<bounce> or B<swish>
objects go. B<width> may be set in the constructor:

    my $sp = new Term::Twiddle({ type => 'bounce', width => 60 });
    $sp->start;

or you can set it with this B<width> method:

    my $sp = new Term::Twiddle({ type => 'swish' });
    $sp->width(74);

=item B<delay>

Determines the speed of motion of the object. Usually the default is
fine (and each object has its own default delay option for optimal
aesthetics).

=back

=head1 EXAMPLES

Show the user something while we unpack the archive:

    my $sp = new Term::Twiddle;
    $sp->random;
    $sp->start;
    system('tar', '-zxf', '/some/tarfile.tar.gz');
    $sp->stop;

Show the user a bouncing ball while we modify their configuration
file:

    my $sp = new Term::Twiddle( { type => 'bounce' } );
    $sp->start;

    ## there must not be any 'sleep' calls in this!
    do_config_stuff();

    $sp->stop;

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 CAVEATS

=over 4

=item *

Prolly won't run on platforms lacking B<setitimer>. Will run on
Cygwin/Win32 (reported by Zak Zebrowski--thanks!).

=item *

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item *

Thanks to Tom Christiansen for the timer code (found lurking in an old
FAQ somewhere). He probably never had an idea that it would be part of
one of the most useful modules on CPAN ;o)

The timer code has since been replaced by B<Time::HiRes>'s
B<setitimer> function, but it is good to thank Mr. Christiansen for
his goodness to Perl anyway.

=item *

"Drew" (drew@drewtaylor.com) from rt.cpan.org for suggesting the
removal of 'use warnings' for the faithful 5.005 users.

=item *

Orignal swishing motion filched from B<Term::ReadKey>'s test.pl by
Kenneth Albanowski (kjahds@kjahds.com). Danke!

=back

=head1 SEE ALSO

L<perl>.

=cut
