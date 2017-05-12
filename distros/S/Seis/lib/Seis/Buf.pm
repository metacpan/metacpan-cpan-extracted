package Seis::Buf;
use strict;
use warnings;
use utf8;
use 5.010_001;

package # Hide from PAUSE
    Buf;

sub new {
    my ($class, @args) = @_;
    bless [@args], $class;
}

1;

