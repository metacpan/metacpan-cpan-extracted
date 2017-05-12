package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build );
use File::Spec;

sub new
{
  my($class, %args) = @_;
  
  if($^O ne 'dos' && $^O ne 'VMS' && $^O ne 'MSWin32' && eval { getppid; 1 })
  {
    unless(-e File::Spec->catfile('', 'proc', getppid, 'cmdline'))
    {
      $args{requires}->{'Unix::Process'} = 0;
    }
  }

  if($^O eq 'MSWin32')
  {
    $args{requires}->{'Win32::Getppid'} = 0;
    $args{requires}->{'Win32::Process::List'} = 0;
  }

  my $self = $class->SUPER::new(%args);
  
  $self;
}

1;
