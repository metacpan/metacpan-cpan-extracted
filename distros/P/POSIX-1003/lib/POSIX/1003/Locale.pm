# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package POSIX::1003::Locale;
use vars '$VERSION';
$VERSION = '0.98';

use base 'POSIX::1003::Module';

# Blocks from resp. limits.h and local.h
my @constants = qw/
  MB_LEN_MAX

  LC_ALL LC_COLLATE LC_CTYPE LC_MESSAGES LC_MONETARY LC_NUMERIC
  LC_TIME
 /;

my @functions = qw/localeconv setlocale/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  );


1;
