# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::OS;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

my @constants;
my @functions = qw/uname/;

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 , tables    => [ '%osconsts' ]
 );

my  $osconsts;
our %osconsts;

BEGIN {
    $osconsts = osconsts_table;
    push @constants, keys %$osconsts;
    tie %osconsts, 'POSIX::1003::ReadOnlyTable', $osconsts;
}


sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $osconsts->{$name};
    sub () {$val};
}

1;
