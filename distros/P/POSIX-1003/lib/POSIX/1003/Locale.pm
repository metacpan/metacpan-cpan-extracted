# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Locale;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

# Blocks from resp. limits.h and local.h
my @constants;
my @functions = qw/localeconv setlocale/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%locale' ]
  );

my  $locale;
our %locale;

BEGIN {
    $locale = locale_table;
    push @constants, keys %$locale;
    tie %locale, 'POSIX::1003::ReadOnlyTable', $locale;
}


sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $locale->{$name};
    sub () {$val};
}


1;
