## no critic: ValuesAndExpressions::ProhibitCommaSeparatedStatements

package Sys::RunAlone::Flexible;

our $DATE = '2019-05-24'; # DATE
our $VERSION = '0.002'; # VERSION

# make sure we're strict and verbose as possible
use strict;
use warnings;

# make sure we know how to lock
use Fcntl ':flock';

# process local storage
my $silent;
my $retry;

sub lock {
    no warnings;

    # skipping
    if ( my $skip= $ENV{SKIP_SYS_RUNALONE} ) {
        print STDERR "Skipping " . __PACKAGE__ . " check for '$0'\n"
          if !$silent and $skip > 1;
    }

    # no data handle, we're screwed
    elsif ( tell( *main::DATA ) == -1 ) {
        print STDERR "Add __END__ or __DATA__ to the end of script '$0'"
          . " to be able use the features of Sys::RunAlone::Flexible\n";
        exit 2;
    }

    # we're not alone!
    elsif ( !flock main::DATA, LOCK_EX | LOCK_NB ) {

        # need to retry
        if ($retry) {
            my ( $times, $sleep )= split ',', $retry;
            $sleep ||= 1;
            while ( $times-- ) {
                sleep $sleep;

                # we're alone!
                goto ALLOK if flock main::DATA, LOCK_EX | LOCK_NB;
            }
        }

        # we're done
        print STDERR "A copy of '$0' is already running\n" if !$silent;
        exit 1;
    }

  ALLOK:
}

#-------------------------------------------------------------------------------
#
# Standard Perl functionality
#
#-------------------------------------------------------------------------------
# import
#
#  IN: 1 class (not used)
#      2 .. N options (default: none)

sub import {
    shift;

    # support obsolete form of silencing
    $silent= 1, return if @_ == 1 and $_[0] and $_[0] eq 'silent';

    # huh?
    die "Must specify even number of parameters" if ( @_ & 1 ) == 1;

    # obtain parameters
    my %args= @_;
    $silent= delete $args{silent};
    $silent=  $ENV{SILENT_SYS_RUNALONE} if exists $ENV{SILENT_SYS_RUNALONE};
    $retry=  delete $args{retry};
    $retry=  $ENV{RETRY_SYS_RUNALONE} if exists $ENV{RETRY_SYS_RUNALONE};

    # sanity check
    if ( my @huh= sort keys %args ) {
        die "Don't know what to do with: @huh";
    }

    return;
} #import

{
    # to shut up the 'Too late to run INIT block' warning
    no warnings 'void';
    INIT {
        lock();
    }
}

# satisfy -require-
1;

# ABSTRACT: make sure only one invocation of a script is active at a time

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::RunAlone::Flexible - make sure only one invocation of a script is active at a time

=head1 VERSION

This document describes version 0.002 of Sys::RunAlone::Flexible (from Perl distribution Sys-RunAlone-Flexible), released on 2019-05-24.

=head1 SYNOPSIS

Use like you would use L<Sys::RunAlone>:

 use Sys::RunAlone::Flexible;
 # code of which there may only be on instance running on system

 use Sys::RunAlone::Flexible silent => 1;
 # be silent if other running instance detected

 use Sys::RunAlone::Flexible retry => 50;
 # retry execution 50 times with wait time of 1 second in between

 use Sys::RunAlone::Flexible retry => '55,60';
 # retry execution 55 times with wait time of 60 seconds in between

 use Sys::RunAlone::Flexible 'silent';
 # obsolete form of silent => 1

Use in run-time:

 require Sys::RunAlone::Flexible;
 Sys::RunAlone::Flexible->import(retry => "55,60");

 # then, somewhere in your program
 sub run {
     Sys::RunAlone::Flexible::lock();
 }

=head1 DESCRIPTION

Sys::RunAlone::Flexible is a fork of L<Sys::RunAlone> 0.13. It's just like
Sys::RunAlone but it can be used at run-time too. The main logic is moved from
INIT block to the L<lock> subroutine which you can invoke at run-time. But, if
you "use Sys::RunAlone::Flexible" at compile-time like you would normally use
Sys::RunAlone, the lock() subroutine will still be invoked at INIT phase.

The rest of the documentation is Sys::RunAlone's.

Provide a simple way to make sure the script from which this module is
loaded, is only running once on the server.  Optionally allow for retrying
execution until the other instance of the script has finished.

=head1 THEORY OF OPERATION

The functionality of this module depends on the availability of the DATA
handle in the script from which this module is called (more specifically:
in the "main" namespace).

At compile/INIT time (or when you run L</lock>), it is checked when there is a
DATA handle: if not, it exits with an error message on STDERR and an exit value
of 2.

If the DATA handle is available, and it cannot be C<flock>ed, it exits
with an error message on STDERR and an exit value of 1.  The error message
will be surpressed when C<silent => 1> was specified in the C<use> statement.
This can be overridden with the environment variable C<SILENT_SYS_RUNALONE>.

If there is a DATA handle, and it could be C<flock>ed, execution continues
without any further interference.

=head1 TRYING MORE THAN ONCE

Optionally, it is possibly to specify a number of retries to be done if the
first C<flock> fails.  This can be done by either specifying the retry value
in the C<use> statement as e.g. C<retry => 55>, or with the environment
variable C<RETRY_SYS_RUNALONE>.  There are two forms of the retry value:

=over 4

=item times

 use Sys::RunAlone retry => 55;  # retry 55 times, with 1 second intervals

Specify the number of times to retry, with 1 second intervals.

=item times,seconds

 use Sys::RunAlone retry => '55,60'; # retry 55 times, with 60 second intervals

Specify both the number of retries as well as the number of seconds interval
between tries.

=back

This is particularly useful for minutely and hourly scripts that run a long
and sometimes run into the next period.  Instead of then not doing anything
for the next period, it will start processing again as soon as it is possible.
This makes the chance of catching up so that the period after the next period
everything is in sync again.

=head1 OVERRIDING CHECK

In some cases, the same script may need to be run simultaneously with another
incarnation (but possibly with different parameters).  In order to simplify
this type of usage, it is possible to specify the environment variable
C<SKIP_SYS_RUNALONE> with a true value.

 SKIP_SYS_RUNALONE=1 yourscript.pl

will run the script always.

 SKIP_SYS_RUNALONE=2 yourscript.pl

will actually be verbose about this and say:

 Skipping Sys::RunAlone check for 'yourscript.pl'

=head1 REQUIRED MODULES

 Fcntl (any)

=head1 CAVEATS

=head2 symlinks

Execution of scripts that are (sym)linked to another script, will all be seen
as execution of the same script, even though the error message will only show
the specified script name.  This could be considered a bug or a feature.

=head2 changing a running script

If you change the script while it is running, the script will effectively
lose its lock on the file.  Causing any subsequent run of the same script
to be successful, causing two instances of the same script to run at the
same time (which is what you wanted to prevent by using Sys::RunAlone in
the first place).  Therefore, make sure that no instances of the script are
running (and won't be started by cronjobs while making changes) if you really
want to be 100% sure that only one instance of the script is running at the
same time.

=head1 SYS::RUNALONE ACKNOWLEDGEMENTS

Inspired by Randal Schwartz's mention of using the DATA handle as a semaphore
on the London PM mailing list.

Booking.com for using this heavily in production and allowing me to improve
this module.

=head1 SYS::RUNALONE AUTHOR

 Elizabeth Mattijsen

=head1 SYS::RUNALONE COPYRIGHT

Copyright (c) 2005, 2006, 2008, 2009, 2011, 2012 Elizabeth Mattijsen
<liz@dijkmat.nl>.  Copyright (c) 2017 Ben Tilly <btilly@gmail.com>.  All
rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 FUNCTIONS

=head2 lock

=head1 METHODS

There are no methods.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sys-RunAlone-Flexible>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sys-RunAlone-Flexible>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sys-RunAlone-Flexible>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sys::RunAlone>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
