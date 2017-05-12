#!perl -T

use Test::More tests => 20;


{
    package A;
    use Moose;
    with 'MooseX::SingletonMethod::Role';
    sub a { 'a' };
}

my $a1 = A->new;
my $a2 = A->new;

$a1->add_singleton_method( b => sub { 'b' } );
$a1->add_singleton_methods( 
    c => sub { 'c' },
    d => sub { 'd' },
);

my $a3 = A->new;

# some intial simple tests

ok $a1->can('a');
is $a1->a, 'a';
ok $a1->can('b');
is $a1->b, 'b';
ok $a1->can('c');
is $a1->c, 'c';
ok $a1->can('d');
is $a1->d, 'd';

ok $a2->can('a');
is $a2->a, 'a';
ok !$a2->can('b');
ok !$a2->can('c');
ok !$a2->can('d');

ok $a3->can('a');
is $a3->a, 'a';
ok !$a3->can('b');
ok !$a3->can('c');
ok !$a3->can('d');

# little extra!
$a3->become_singleton;
$a3->meta->add_method( x => sub { 'x' } );
ok $a3->can('x');
is $a3->x, 'x';

# TBD: much better test arrangement + test class assigns