package # hide from PAUSE
    Package::Stash;
use strict;
use warnings;

use Package::Stash::XS;

our $IMPLEMENTATION = 'XS';

BEGIN {
    my $ps = Package::Stash::XS->new(__PACKAGE__);
    my $ps_xs = Package::Stash::XS->new('Package::Stash::XS');
    for my $method ($ps_xs->list_all_symbols('CODE')) {
        my $sym = '&' . $method;
        $ps->add_symbol($sym => $ps_xs->get_symbol($sym));
    }
}

1;
