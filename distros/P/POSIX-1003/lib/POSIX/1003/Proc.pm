# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package POSIX::1003::Proc;
use vars '$VERSION';
$VERSION = '0.98';

use base 'POSIX::1003::Module';

# Blocks resp. in stdlib.h, limits.h
my @constants = qw/
 EXIT_FAILURE EXIT_SUCCESS CHILD_MAX
 WNOHANG WUNTRACED
  /;
our @IN_CORE  = qw/wait waitpid/;

# Blocks resp. in stdlib.h, sys/wait.h, unistd.h
my @functions = qw/
 abort

 WEXITSTATUS WIFEXITED WIFSIGNALED WIFSTOPPED
 WSTOPSIG WTERMSIG 
  
 _exit pause setpgid setsid tcgetpgrp tcsetpgrp
 ctermid cuserid getcwd nice
 /;
push @functions, @IN_CORE;

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 );


# When the next where automatically imported from POSIX, they are
# considered constant and therefore without parameter.  Therefore,
# these are linked explicitly.
*WIFEXITED   = \&POSIX::WIFEXITED;
*WIFSIGNALED = \&POSIX::WIFSIGNALED;
*WIFSTOPPED  = \&POSIX::WIFSTOPPED;
*WEXITSTATUS = \&POSIX::WEXITSTATUS;
*WTERMSIG    = \&POSIX::WTERMSIG;
*WSTOPSIG    = \&POSIX::WSTOPSIG;

#-------------------------------------

sub cuserid()     {goto &POSIX::cuserid}
sub ctermid()     {goto &POSIX::ctermid}
sub _exit($)      {goto &POSIX::_exit}
sub pause()       {goto &POSIX::pause}
sub setpgid($$)   {goto &POSIX::setpgid}
sub setsid()      {goto &POSIX::setsid}
sub cgetpgrp($)   {goto &POSIX::cgetpgrp}
sub tcsetpgrp($$) {goto &POSIX::tcsetpgrp}


sub nice($)       {goto &POSIX::nice}


sub times5()      {goto &POSIX::times}

1;
