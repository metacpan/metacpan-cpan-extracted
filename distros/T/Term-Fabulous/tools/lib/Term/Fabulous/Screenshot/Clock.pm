package Term::Fabulous::Screenshot::Clock;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Carp qw(croak);
use Time::HiRes ();

# One virtual clock for the whole process: the wall clock (time, localtime,
# gmtime, Time::HiRes::time) starts at a fixed moment and moves only when
# the screenshot harness advances it, so every timer, every animation and
# every displayed time is the same on every run.

my $epoch;    # the wall-clock time the clock started at, in seconds
my $elapsed = 0;    # virtual seconds since then

sub is_installed () {
	return defined $epoch;
}

sub now () {
	croak 'Term::Fabulous::Screenshot::Clock: install() was not called' unless is_installed();
	return $epoch + $elapsed;
}

sub elapsed () {
	return $elapsed;
}

sub advance ($seconds) {
	croak "Term::Fabulous::Screenshot::Clock: cannot advance by $seconds seconds" unless $seconds >= 0;
	$elapsed += $seconds;
	return;
}

# Replaces every clock Perl code can read. Must run before any module
# imports a Time::HiRes function, because an import copies the function
# that exists at that moment.
sub install ($start_epoch) {
	croak 'Term::Fabulous::Screenshot::Clock: already installed' if is_installed();
	croak "Term::Fabulous::Screenshot::Clock: '$start_epoch' is not a time in epoch seconds" unless $start_epoch =~ /\A\d+(?:\.\d+)?\z/;
	$epoch = $start_epoch;

	no warnings qw(once redefine);
	*CORE::GLOBAL::time      = sub :prototype() { int now() };
	*CORE::GLOBAL::localtime = sub :prototype(;$) { CORE::localtime( @_ ? $_[0] : int now() ) };
	*CORE::GLOBAL::gmtime    = sub :prototype(;$) { CORE::gmtime( @_    ? $_[0] : int now() ) };
	*CORE::GLOBAL::sleep     = sub :prototype(;$) { my $seconds = $_[0] // 0; advance($seconds); $seconds };

	*Time::HiRes::time          = sub :prototype() { now() };
	*Time::HiRes::clock_gettime = sub :prototype(;$) { now() };
	*Time::HiRes::gettimeofday  = sub :prototype() {
		my $now     = now();
		my $seconds = int $now;
		return wantarray ? ( $seconds, int( ( $now - $seconds ) * 1_000_000 ) ) : $now;
	};
	*Time::HiRes::sleep     = sub :prototype(;@) { my $seconds = $_[0] // 0;        advance($seconds); $seconds };
	*Time::HiRes::usleep    = sub :prototype($) { advance( $_[0] / 1_000_000 );     $_[0] };
	*Time::HiRes::nanosleep = sub :prototype($) { advance( $_[0] / 1_000_000_000 ); $_[0] };
	return;
}

1;

__END__

=head1 NAME

Term::Fabulous::Screenshot::Clock - A virtual clock for reproducible
screenshots

=head1 SYNOPSIS

	use Term::Fabulous::Screenshot::Clock;

	BEGIN { Term::Fabulous::Screenshot::Clock::install(1780306860) }

	say scalar localtime;                             # the fixed start time
	Term::Fabulous::Screenshot::Clock::advance(1.5);
	say Time::HiRes::time() - 1780306860;             # 1.5

=head1 DESCRIPTION

Maintainer tool, not installed. The screenshot harness
(L<Term::Fabulous::Screenshot::Harness>) runs an example program with
this clock installed, so that the time the program reads and the timers
of its event loop depend only on how far the harness has advanced the
clock, never on the real time.

=head1 FUNCTIONS

=head2 install

	Term::Fabulous::Screenshot::Clock::install($epoch_seconds);

Starts the clock at C<$epoch_seconds> and replaces C<time>,
C<localtime>, C<gmtime> and C<sleep> (through C<CORE::GLOBAL>) and
C<Time::HiRes>'s C<time>, C<gettimeofday>, C<clock_gettime>, C<sleep>,
C<usleep> and C<nanosleep>. Sleeping advances the clock and returns at
once. Every clock id of C<clock_gettime> returns the virtual wall-clock
time.

Call it before any other module is loaded: C<CORE::GLOBAL> overrides
only affect code compiled afterwards, and a module that imports a
C<Time::HiRes> function keeps the function it imported. Dies when called
twice.

=head2 now

The virtual wall-clock time in epoch seconds, with fractions.

=head2 elapsed

The virtual seconds since L</install>.

=head2 advance

	Term::Fabulous::Screenshot::Clock::advance($seconds);

Moves the clock forward. Dies on a negative number.

=head2 is_installed

True once L</install> has been called.

=cut
