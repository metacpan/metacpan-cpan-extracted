
package Data::IO;

use 5;
use strict;
use warnings;

our $VERSION = '0.0006';

use YAML qw(LoadFile);

use base qw(Class::Accessor);

sub _read_yaml {
    shift;
    my $yml = shift;
    return LoadFile $yml; # XXX error handling ?!
}

sub _read_perl {
    shift;
    my $pl = shift;
    return do $pl; # XXX error handling ?!
}


1;