#!D:\Programme\indigoperl-5.6\bin\perl.exe -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'D:lib\Schedule\Cron\Nofork.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module Schedule::Cron::Nofork
  eval { require Schedule::Cron::Nofork };
  skip "Need module Schedule::Cron::Nofork to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 44 lib/Schedule/Cron/Nofork.pm

  use Schedule::Cron::Nofork;

  sub dispatcher {
    print "ID:   ",shift,"\n";
    print "Args: ","@_","\n";
  };

  my $cron = new Schedule::Cron::Nofork(\&dispatcher);
  $cron->add_entry("0 11 * * Mon-Fri",\&check_links);
  $cron->run();

;

  }
};
is($@, '', "example from line 44");

};
SKIP: {
    # A header testing whether we find all prerequisites :
    
    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;

};
