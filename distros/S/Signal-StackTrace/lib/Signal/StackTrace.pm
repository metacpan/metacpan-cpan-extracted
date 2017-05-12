########################################################################
# Signal::StackTrace - run a stack dump on a signal.
########################################################################
########################################################################
# housekeeping
########################################################################

package Signal::StackTrace;

use 5.006;

use strict;

use Carp;
use Config;

use Data::Dumper;

########################################################################
# package variables
########################################################################

our $VERSION = 0.04;

my %known_sigz  = ();

@known_sigz{ split ' ', $Config{ sig_name } } = ();

# see perldoc -f caller for the correct order.

my @headerz =
qw
(
    Package
    Filename
    Line-No
    Subroutine
    Hasargs
    Wantarray
    Evaltext
    Require
    Hints
    Bitmask
);

########################################################################
# private utility subs
########################################################################

my $print_list
= sub
{
    local $Data::Dumper::Purity     = 0;
    local $Data::Dumper::Terse      = 1;
    local $Data::Dumper::Indent     = 1;
    local $Data::Dumper::Deparse    = 1;
    local $Data::Dumper::Sortkeys   = 1;
    local $Data::Dumper::Deepcopy   = 0;
    local $Data::Dumper::Quotekeys  = 0;

    print STDERR join "\n", map { ref $_ ? Dumper $_ : $_ } @_
};

my $stack_trace
= sub
{
    my %data = ();

    for( my $i = 0 ; my @caller = caller $i ; ++$i )
    {
        @data{ @headerz } = @caller;

        $print_list->( "Caller level $i:", \%data );
    }

    $print_list->( "End of trace" );

    return
};

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
        # with the stack_trace handler.

        @SIG{ @_ } = ( $stack_trace ) x @_;
    }
    else
    {
        $SIG{ USR1 } = $stack_trace;
    }

    return
}

# keep require happy

1

__END__

=head1 NAME

Signal::StackTrace - install signal handler to print a stacktrace.

=head1 SYNOPSIS

    # default installs the handler on USR1
    # these have the same result.

    use Signal::Stacktrace;
    use Signal::Stacktrace qw( USR1 );

    # install the handler on any valid signals

    use Signal::Stacktrace qw( HUP );
    use Signal::Stacktrace qw( HUP USR1 USR2 );

    # this will fail: FOOBAR is not a valid
    # signal (on any system I know of at least).

    use Signal::Stacktrace qw( FOOBAR );

=head1 DESCRIPTION

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

  Caller level 1:
  {
    Bitmask => '',
    Evaltext => undef,
    Filename => '(eval 9)[/usr/lib/perl5/site_perl/5.8.8/i686-linux/Term/ReadKey.pm:411]',
    Hasargs => 0,
    Hints => 0,
    'Line-No' => 7,
    Package => 'Term::ReadKey',
    Require => undef,
    Subroutine => '(eval)',
    Wantarray => 0
  }

  ...

  Caller level 8:
  {
    Bitmask => '',
    Evaltext => undef,
    Filename => '-e',
    Hasargs => 0,
    Hints => 0,
    'Line-No' => 1,
    Package => 'main',
    Require => undef,
    Subroutine => 'DB::DB',
    Wantarray => 1
  }


  End of trace



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

Steven Lembark <lembark@wrkhors.com>

=head1 LICENSE

This code is licensed under the same terms as Perl 5.8
or any later version of perl at the users preference.
