use strict;
use warnings;
use Test::More tests => 3;
use Statistics::Benford;

{
    my $stats = Statistics::Benford->new;
    isa_ok($stats, 'Statistics::Benford', 'new()');
}

{
    my $stats = Statistics::Benford->new;
    isa_ok($stats, 'Statistics::Benford', 'new(10, 0, 1)');
}

{
    my @methods = qw(
        distribution dist difference diff signif z
    );
    can_ok('Statistics::Benford', @methods);
}
