# $Id: Linux.pm,v 1.1 2008/04/03 00:09:14 cvs Exp $

package #
Devel::AssertOS::Linux;

use Devel::CheckOS;

$VERSION = '1.0';

sub os_is { $^O eq 'linux' ? 1 : 0; }

Devel::CheckOS::die_unsupported() unless(os_is());

1;
