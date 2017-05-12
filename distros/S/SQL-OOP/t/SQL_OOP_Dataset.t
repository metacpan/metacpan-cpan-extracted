package SQL_OOP_CpmprehensiveTest;
use strict;
use warnings;
use lib qw(t/lib);
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Dataset;

__PACKAGE__->runtests;

sub append_with_hash : Test(5) {
    
    my $dataset = SQL::OOP::Dataset->new();
    $dataset->append(a => 'b');
    $dataset->append(c => 'd');
    is($dataset->to_string_for_insert, q(("a", "c") VALUES (?, ?)));
    is($dataset->to_string_for_update, q("a" = ?, "c" = ?));
    my @bind = $dataset->bind;
    is(scalar @bind, 2);
    is(shift @bind, 'b');
    is(shift @bind, 'd');
}

sub append_with_hashref : Test(5) {
    
    my $dataset = SQL::OOP::Dataset->new();
    $dataset->append(a => 'b');
    $dataset->append(c => 'd');
    is($dataset->to_string_for_insert, q(("a", "c") VALUES (?, ?)));
    is($dataset->to_string_for_update, q("a" = ?, "c" = ?));
    my @bind = $dataset->bind;
    is(scalar @bind, 2);
    is(shift @bind, 'b');
    is(shift @bind, 'd');
}

sub new_with_args : Test(5) {
    
    my $dataset = SQL::OOP::Dataset->new([a => 'b', c => 'd']);
    is($dataset->to_string_for_insert, q(("a", "c") VALUES (?, ?)));
    is($dataset->to_string_for_update, q("a" = ?, "c" = ?));
    my @bind = $dataset->bind;
    is(scalar @bind, 2);
    is(shift @bind, 'b');
    is(shift @bind, 'd');
}

sub undef_value_alive : Test(5) {
    
    my $dataset = SQL::OOP::Dataset->new();
    $dataset->append(a => 'b');
    $dataset->append(c => undef);
    is($dataset->to_string_for_insert, q(("a", "c") VALUES (?, ?)));
    is($dataset->to_string_for_update, q("a" = ?, "c" = ?));
    my @bind = $dataset->bind;
    is(scalar @bind, 2);
    is(shift @bind, 'b');
    is(shift @bind, undef);
}

sub compress_sql {
    
    my $sql = shift;
    $sql =~ s/[\s\r\n]+/ /gs;
    $sql =~ s/[\s\r\n]+$//gs;
    $sql =~ s/\(\s/\(/gs;
    $sql =~ s/\s\)/\)/gs;
    return $sql;
}
