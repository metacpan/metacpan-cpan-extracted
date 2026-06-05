#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Router::Ragel;

# Documented behaviour: when multiple routes match the same path, the
# most-recently-added route wins. Lock it in so it cannot silently change
# (e.g. across a Ragel version or codegen-flag change).

{
    my $r = Router::Ragel->new
        ->add('/a/b', 'static')
        ->add('/a/:x', 'dynamic') # added last -> wins on /a/b
        ->compile;

    my ($d, @cap) = $r->match('/a/b');
    is $d, 'dynamic', 'last-added dynamic route wins over earlier static /a/b';
    is_deeply \@cap, ['b'], '...and the winning route\'s capture is returned';

    my ($d2, @c2) = $r->match('/a/zzz');
    is $d2, 'dynamic', 'dynamic route still matches a non-overlapping path';
    is_deeply \@c2, ['zzz'], '...with its capture';
}

{
    my $r = Router::Ragel->new
        ->add('/a/:x', 'dynamic')
        ->add('/a/b', 'static') # added last -> wins on /a/b
        ->compile;

    my ($d, @cap) = $r->match('/a/b');
    is $d, 'static', 'reordered: last-added static route now wins on /a/b';
    is scalar(@cap), 0, '...and a static match returns no captures';
}

done_testing;
