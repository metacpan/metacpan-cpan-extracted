# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Proc;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

my @constants;
my @functions = qw/
 abort

 WEXITSTATUS WIFEXITED WIFSIGNALED WIFSTOPPED
 WSTOPSIG WTERMSIG 

 getpid getppid
 _exit pause setpgid setsid tcgetpgrp tcsetpgrp
 ctermid cuserid getcwd nice
 /;

our @IN_CORE  = qw/wait waitpid/;
push @functions, @IN_CORE;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%proc' ]
  );

my  $proc;
our %proc;

BEGIN {
    $proc = proc_table;
    push @constants, keys %$proc;
    tie %proc, 'POSIX::1003::ReadOnlyTable', $proc;
}


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

# getpid and getppid implemented in XS

sub nice($)       {goto &POSIX::nice}


sub times5()      {goto &POSIX::times}


sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $proc->{$name};
    sub() {$val};
}

1;
