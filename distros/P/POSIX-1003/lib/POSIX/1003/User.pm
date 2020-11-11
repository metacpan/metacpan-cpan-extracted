# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::User;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

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

my @constants;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%user' ]
  );

my  $user;
our %user;

BEGIN {
    $user = user_table;
    push @constants, keys %$user;
    tie %user, 'POSIX::1003::ReadOnlyTable', $user;
}


#------------------

#------------------

#------------------


1;
