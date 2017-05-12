package SQL_OOP_CpmprehensiveTest;
use strict;
use warnings;
use lib qw(lib);
use lib qw(t/lib);
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Dataset;

__PACKAGE__->runtests;

sub retrieve : Test(2) {
    my $dataset = SQL::OOP::Dataset->new();
    $dataset->append(a => 'b', c => 'd');
    is $dataset->retrieve('a'), 'b', 'right value';
    is $dataset->retrieve('c'), 'd', 'right value';
}
