# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package POSIX::1003::User;
use vars '$VERSION';
$VERSION = '0.98';

use base 'POSIX::1003::Module';

my @constants = qw/
 /;

our @IN_CORE  = qw/
  getpwnam  getpwuid  getpwent
  getgrnam  getgrgid  getgrent
  getlogin
  /;

my @functions = qw/
  getuid    setuid
  geteuid   seteuid
            setreuid
  getresuid setresuid

  getgid    setgid
  getegid   setegid
            setregid
  getresgid setresgid
  getgroups setgroups
  /;

push @functions, @IN_CORE;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  );


#------------------

#------------------

#------------------


1;
