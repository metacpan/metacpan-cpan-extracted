# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Confstr;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

use Carp 'croak';

my @constants;
my @functions = qw/confstr confstr_names/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%confstr' ]
  );

sub confstr($);
my $confstr;
our %confstr;

BEGIN {
   $confstr = confstr_table;
   push @constants, keys %$confstr;
   tie %confstr, 'POSIX::1003::ReadOnlyTable', $confstr;
}


sub exampleValue($)
{   my ($class, $name) = @_;
    $name =~ m/^_CS_/ or return;
    my $val = confstr $name;
    defined $val ? "'$val'" : 'undef';
}

#-----------------------

sub confstr($)
{   my $key = shift // return;
    $key =~ /^_CS_/
        or croak "pass the constant name as string";

    my $id  = $confstr->{$key} // return;
    _confstr($id);
}

sub _create_constant($)
{   my ($class, $name) = @_;
    my $id = $confstr->{$name} // return sub() {undef};
    sub() {_confstr($id)};
}

#--------------------------

sub confstr_names() { keys %$confstr }

#--------------------------

1;
