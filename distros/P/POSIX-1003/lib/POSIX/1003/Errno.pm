# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Errno;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

use Carp    'croak';

my @constants;
my @functions = qw/strerror errno errno_names/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%errno' ]
  );

my  $errno;
our %errno;

BEGIN {
    $errno = errno_table;
    push @constants, keys %$errno;
    tie %errno, 'POSIX::1003::ReadOnlyTable', $errno;
}

sub errno($);


sub exampleValue($)
{   my ($class, $name) = @_;
    $name =~ m/^(?:WSA)?E/ or return;
    errno($name) // 'undef';
}


sub strerror($) { _strerror($_[0]) || "Unknown error $_[0]" }


sub errno($)
{   my $key = shift // return;
    $key =~ /^(?:WSA)?E/
        or croak "pass the constant name $key as string";
 
    $errno->{$key};
}

sub _create_constant($)
{   my ($class, $name) = @_;
    my $nr = $errno->{$name} // return sub() {undef};
    sub() {$nr};
}


sub errno_names() { keys %$errno }


1;
