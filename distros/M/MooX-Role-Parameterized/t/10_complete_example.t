use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';

{

    package RoleA;

    use Moo::Role;
}

{

    package RoleB;

    use Moo::Role;

    sub r { }
}

{

    package RoleC;

    use Moo::Role;

    sub r { die "ops" }
}

{

    package CompleteClassA;

    use Moo;
    use CompleteExample;

    CompleteExample->apply(
        {
            attr     => 'a',
            method   => 'b',
            requires => 'r',
            with     => 'RoleA',
            after    => [ r => sub { die "ops" } ],
        }
    );

    sub r { }
}

{

    package CompleteClassB;

    use Moo;
    use CompleteExample;

    CompleteExample->apply(
        {
            attr     => 'a',
            method   => 'b',
            requires => 'r',
            with     => 'RoleB',
            before   => [ r => sub { die "ops before" } ],
        }
    );
}

{

    package CompleteClassC;

    use Moo;
    use CompleteExample;

    CompleteExample->apply(
        {
            attr     => 'a',
            method   => 'b',
            requires => 'r',
            with     => 'RoleC',
            around   => [ r => sub { 1024 } ],
        }
    );
}

my $a = CompleteClassA->new;
my $b = CompleteClassB->new;
my $c = CompleteClassC->new;

ok $a->does('RoleA'), 'CompleteClassA should does RoleA';
ok $b->does('RoleB'), 'CompleteClassB should does RoleB';
ok $c->does('RoleC'), 'CompleteClassC should does RoleC';

throws_ok { $a->r } qr/ops/, 'should call after callback';
throws_ok { $b->r } qr/ops/, 'should call before callback';
is $c->r, 1024, 'should call around callback';

done_testing;
