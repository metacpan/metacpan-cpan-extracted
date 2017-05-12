use strict;
use warnings;

use Test::Most;
plan qw/no_plan/;

use MooseX::MakeImmutable::Finder;

my $finder;

{
    $finder = MooseX::MakeImmutable::Finder->new(manifest => <<_END_);
t::Test::Alpha
t::Test::Bravo
t::Test::Charlie
_END_

    cmp_deeply([$finder->found], bag(qw/
    t::Test::Alpha
    t::Test::Bravo
    t::Test::Bravo::Moose
    t::Test::Charlie
    /));
}

{
    $finder = MooseX::MakeImmutable::Finder->new(include_inner => 0, manifest => <<_END_);
t::Test::Alpha
t::Test::Bravo
t::Test::Charlie
_END_

    cmp_deeply([$finder->found], bag(qw/
    t::Test::Alpha
    t::Test::Bravo
    t::Test::Charlie
    /));
}

    $finder = MooseX::MakeImmutable::Finder->new(manifest => <<_END_);
t::Test::Alpha::+
t::Test::Bravo
t::Test::Charlie
_END_

{
    cmp_deeply([$finder->found], bag(qw/
    t::Test::Alpha
    t::Test::Alpha::A
    t::Test::Alpha::C
    t::Test::Bravo
    t::Test::Bravo::Moose
    t::Test::Charlie
    /));

    $finder = MooseX::MakeImmutable::Finder->new(include_inner => 0, manifest => <<_END_);
t::Test::Alpha
t::Test::Bravo::+
t::Test::Charlie::+
_END_

    cmp_deeply([$finder->found], bag(qw/
    t::Test::Alpha
    t::Test::Bravo
    t::Test::Bravo::Moose
    t::Test::Charlie
    t::Test::Charlie::D
    /));
}

{
    $finder = MooseX::MakeImmutable::Finder->new(exclude => sub { ! m/Bravo/ }, manifest => <<_END_);
t::Test::Alpha
t::Test::Bravo::+
t::Test::Charlie::+
_END_

    cmp_deeply([$finder->found], bag(qw/
    t::Test::Bravo
    t::Test::Bravo::Moose
    /));
}

{
    $finder = MooseX::MakeImmutable::Finder->new(exclude => [ qr/Bravo/, qw/t::Test::Charlie/ ], manifest => <<_END_);
t::Test::Alpha
t::Test::Bravo::+
t::Test::Charlie::+
_END_

    cmp_deeply([$finder->found], bag(qw/
    t::Test::Alpha
    t::Test::Alpha::A
    t::Test::Alpha::C
    t::Test::Charlie::D
    /));
}

{
    $finder = MooseX::MakeImmutable::Finder->new(exclude => [ qr/Bravo/, qr/^t::Test::Alpha::/ ], manifest => <<_END_);
t::Test::Alpha
t::Test::Bravo::+
t::Test::Charlie::+
_END_

    cmp_deeply([$finder->found], bag(qw/
    t::Test::Alpha
    t::Test::Charlie
    t::Test::Charlie::D
    /));
}

{
    $finder = MooseX::MakeImmutable::Finder->new(manifest => <<_END_);
t::Test::*
_END_

    cmp_deeply([$finder->found], bag(qw/
    t::Test::Alpha
    t::Test::Alpha::A
    t::Test::Alpha::C
    t::Test::Bravo
    t::Test::Bravo::Moose
    t::Test::Charlie
    t::Test::Charlie::D
    /));
}
