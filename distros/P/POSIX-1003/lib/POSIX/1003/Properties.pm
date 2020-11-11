# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Properties;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

use Carp 'croak';

my @constants;
my @functions = qw/property property_names/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%property' ]
  );

my  $property;
our %property;

BEGIN {
    $property = property_table;
    push @constants, keys %$property;
    tie %property, 'POSIX::1003::ReadOnlyTable', $property;
}

sub property($);


sub exampleValue($)
{   my ($class, $name) = @_;
    $name =~ m/^_POSIX/ or return;
    my $val = property $name;
    defined $val ? $val : 'undef';
}


sub property($)
{   my $key = shift // return;
    $key =~ /^_POSIX/
        or croak "pass the constant name as string";

    $property->{$key};
}

sub _create_constant($)
{   my ($class, $name) = @_;
    my $value = $property->{$name};
    sub() {$value};
}


sub property_names() { keys %$property }


1;
