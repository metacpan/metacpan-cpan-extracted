package app::multi::new;
use strict;
use warnings;
use OptArgs;
use Data::Dumper;

sub run {
    my $opt = shift;
    $opt->{_caller} = __PACKAGE__;
    print Dumper($opt);
}

1;

