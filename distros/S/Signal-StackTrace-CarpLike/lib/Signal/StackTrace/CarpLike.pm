########################################################################
# Signal::StackTrace::CarpLike - run a stack dump on a signal.
########################################################################
########################################################################
# housekeeping
########################################################################

package Signal::StackTrace::CarpLike;

use 5.006;

use strict;

use Carp;
use Config;

use Data::Dumper;

########################################################################
# package variables
########################################################################

our $VERSION = 0.01;

my %known_sigz  = ();

@known_sigz{ split ' ', $Config{ sig_name } } = ();

########################################################################
# install the signal handlers
########################################################################

sub import
{
    # discard this package;
    # remainder of the stack are signal names.

    shift;

    if( @_ ) 
    {
        if( my @junk = grep { ! exists $known_sigz{ $_ } } @_ )
        {
            croak "Unknown signals: unknown signals @junk";
        }

        # all the signals are known, install them all
        # with the cluck handler.

        @SIG{ @_ } = ( \&Carp::cluck ) x @_;
    }
    else
    {
        $SIG{ USR1 } = \&Carp::cluck;
    }

    return
}

# keep require happy

1

__END__

=head1 NAME

Signal::StackTrace::CarpLike - install signal handler to print a Carp-like stacktrace

=head1 SYNOPSIS

    # default installs the handler on USR1
    # these have the same result.

    use Signal::StackTrace::CarpLike;
    use Signal::StackTrace::CarpLike qw( USR1 );

    # install the handler on any valid signals

    use Signal::StackTrace::CarpLike qw( HUP );
    use Signal::StackTrace::CarpLike qw( HUP USR1 USR2 );

    # this will fail: FOOBAR is not a valid
    # signal (on any system I know of at least).

    use Signal::StackTrace::CarpLike qw( FOOBAR );

    # use it from the command line
    perl -MSignal::StackTrace::CarpLike=INT hanging-test.t

=head1 DESCRIPTION

This module is a fork of L<Signal::StackTrace>,
which has a uselessly verbose output format. But
its interface is perfect, hence this module, which
just uses L<Carp/cluck>.


This will print a stack trace to STDERR -- 
similar to the sigtrap module but without the 
core dump using simpler syntax.

The module arguemts are signals on which to 
print the stack trace. For normally-terminating
signals (e.g., TERM, QUIT) it is proably a bad
idea in production environments but would be
handy for tracking down errors; for non-trapable
signals (e.g., KILL) this won't do anything.

The import will croak on signal names unknown to 
Config.pm ( see $Config{ sig_name } ).

The stack trace looks something like:

    INT at /Users/sartak/.perl/perls/perl-5.12.3/lib/5.12.3/perl5db.pl line 3749
            eval {...} called at /Users/sartak/.perl/perls/perl-5.12.3/lib/5.12.3/perl5db.pl line 3749
            Term::ReadLine::Gnu::AU::__ANON__[/Users/sartak/.perl/perls/perl-5.12.3/lib/site_perl/5.12.3/darwin-2level/Term/ReadLine/Gnu.pm:719]('Term::ReadLine=HASH(0x10099a6e0)', '\x{1}\x{1b}[4m\x{2}  DB<1> \x{1}\x{1b}[24m\x{2}') called at /Users/sartak/.perl/perls/perl-5.12.3/lib/site_perl/5.12.3/darwin-2level/Term/ReadLine/Gnu.pm line 331
            Term::ReadLine::Gnu::readline('Term::ReadLine=HASH(0x10099a6e0)', '  DB<1> ') called at /Users/sartak/.perl/perls/perl-5.12.3/lib/5.12.3/perl5db.pl line 6494
            DB::readline('  DB<1> ') called at /Users/sartak/.perl/perls/perl-5.12.3/lib/5.12.3/perl5db.pl line 2241
            DB::DB called at -e line 1
    at /Users/sartak/.perl/perls/perl-5.12.3/lib/5.12.3/perl5db.pl line 3749
            eval {...} called at /Users/sartak/.perl/perls/perl-5.12.3/lib/5.12.3/perl5db.pl line 3749
            Term::ReadLine::Gnu::AU::__ANON__[/Users/sartak/.perl/perls/perl-5.12.3/lib/site_perl/5.12.3/darwin-2level/Term/ReadLine/Gnu.pm:719]('Term::ReadLine=HASH(0x10099a6e0)', '\x{1}\x{1b}[4m\x{2}  DB<1> \x{1}\x{1b}[24m\x{2}') called at /Users/sartak/.perl/perls/perl-5.12.3/lib/site_perl/5.12.3/darwin-2level/Term/ReadLine/Gnu.pm line 331
            Term::ReadLine::Gnu::readline('Term::ReadLine=HASH(0x10099a6e0)', '  DB<1> ') called at /Users/sartak/.perl/perls/perl-5.12.3/lib/5.12.3/perl5db.pl line 6494
            DB::readline('  DB<1> ') called at /Users/sartak/.perl/perls/perl-5.12.3/lib/5.12.3/perl5db.pl line 2241
            DB::DB called at -e line 1

=head1 KNOWN BUGS

None, yet.

=head1 SEE ALSO

=over 4

=item perlipc

Dealing with signals in perl.

=item sigtrap

Trapping signals with supplied handlers, getting 
core dumps.

=item Config

$Config{ sig_name } gives the valid signal 
names.

=back

=head1 AUTHOR

Shawn M Moore <sartak@gmail.com>

=head2 ORIGINAL AUTHOR

Steven Lembark <lembark@wrkhors.com> was the original author of
L<Signal::StackTrace> from which this module was forked.

=head1 LICENSE

This code is licensed under the same terms as Perl 5.8
or any later version of perl at the users preference.
