package Object;

use strict;
use warnings;
use Data::Dumper qw(Dumper);

sub new {
    my $pkg = shift;
    return bless {}, $pkg;
}

sub dump {
    my $self = shift;
    return Dumper($self);
}

1;
