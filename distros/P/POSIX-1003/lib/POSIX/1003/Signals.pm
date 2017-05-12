# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package POSIX::1003::Signals;
use vars '$VERSION';
$VERSION = '0.98';

use base 'POSIX::1003::Module';

my @states  = qw/
    SIG_BLOCK SIG_DFL SIG_ERR
    SIG_IGN SIG_SETMASK SIG_UNBLOCK
 /;

my @functions = qw/
    raise sigaction signal sigpending sigprocmask sigsuspend signal
    signal_names strsignal
 /;

my (@signals, @actions);
my @constants = @states;

our %EXPORT_TAGS =
  ( signals   => \@signals
  , actions   => \@actions
  , status    => \@states
  , constants => \@constants
  , functions => \@functions
  , tables    => [ '%signals' ]
  );

our @IN_CORE = qw/kill/;

my $signals;
our %signals;

BEGIN {
    # initialize the :signals export tag
    $signals = signals_table;

    push @constants, keys %$signals;
    push @signals, grep !/^SA_/, keys %$signals;
    push @actions, grep /^SA_/, keys %$signals;

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
