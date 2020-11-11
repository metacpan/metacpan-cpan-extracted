# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Signals;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

my @functions = qw/
    raise sigaction signal sigpending sigprocmask sigsuspend signal
    signal_names strsignal
 /;

my (@handlers, @signals, @actions);
my @constants;

our %EXPORT_TAGS =
  ( signals   => \@signals
  , actions   => \@actions
  , handlers  => \@handlers
  , constants => \@constants
  , functions => \@functions
  , tables    => [ '%signals' ]
  );

our @IN_CORE = qw/kill/;

my $signals;
our %signals;

BEGIN {
    $signals = signals_table;

    push @constants, keys %$signals;
    push @handlers, grep /^SIG_/, keys %$signals;
    push @signals,  grep !/^SA_|^SIG_/, keys %$signals;
    push @actions,  grep /^SA_/, keys %$signals;

    tie %signals, 'POSIX::1003::ReadOnlyTable', $signals;
}


# Perl does not support pthreads, so:
sub raise($) { CORE::kill $_[0], $$ }


sub sigaction($$;$)   {goto &POSIX::sigaction }
sub sigpending($)     {goto &POSIX::sigpending }
sub sigprocmask($$;$) {goto &POSIX::sigprocmask }
sub sigsuspend($)     {goto &POSIX::sigsuspend }
sub signal($$)        { $SIG{$_[0]} = $_[1] }


sub strsignal($)      { _strsignal($_[0]) || "Unknown signal $_[0]" }

#--------------------------

sub signal_names() { @signals }


sub sigaction_names() { @actions }

#--------------------------


sub exampleValue($)
{   my ($class, $name) = @_;
    my $val = $signals->{$name};
    defined $val ? $val : 'undef';
}


sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $signals->{$name};
    sub() {$val};
}

1;
