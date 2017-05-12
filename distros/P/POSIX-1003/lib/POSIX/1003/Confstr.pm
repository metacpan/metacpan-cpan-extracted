# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package POSIX::1003::Confstr;
use vars '$VERSION';
$VERSION = '0.98';

use base 'POSIX::1003::Module';

use Carp 'croak';

my @constants;
my @functions = qw/confstr confstr_names/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%confstr' ]
  );

my  $confstr;
our %confstr;
sub confstr($);

BEGIN {
    # initialize the :constants export tag
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
