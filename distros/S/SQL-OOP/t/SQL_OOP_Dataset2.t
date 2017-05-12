package SQL_OOP_CpmprehensiveTest;
use strict;
use warnings;
use lib qw(t/lib);
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Dataset;

__PACKAGE__->runtests;

sub append_with_hash : Test(2) {
    
    my $dataset = SQL::OOP::Dataset->new();
    $dataset->append(a => SQL::OOP::Base->new(q{datetime('now', 'localtime')}));
    is($dataset->to_string_for_insert, q(("a") VALUES (datetime('now', 'localtime'))));
    my @bind = $dataset->bind;
    is(scalar @bind, 0);
}

sub append_with_hash2 : Test(2) {
    
    my $dataset = SQL::OOP::Dataset->new();
    $dataset->append(a => SQL::OOP::Base->new(q{datetime('now', 'localtime')}));
    is($dataset->to_string_for_update, q("a" = datetime('now', 'localtime')));
    my @bind = $dataset->bind;
    is(scalar @bind, 0);
}

sub append_with_hash3 : Test(2) {
    
    my $dataset = SQL::OOP::Dataset->new();
    $dataset->append(a => SQL::OOP::Base->new(q{"a" + 1}));
    is($dataset->to_string_for_update, q("a" = "a" + 1));
    my @bind = $dataset->bind;
    is(scalar @bind, 0);
}

sub append_with_hash4 : Test(3) {
    
    my $dataset = SQL::OOP::Dataset->new();
    $dataset->append(a => SQL::OOP::Base->new(q{"a" + ?}, [1]));
    is($dataset->to_string_for_update, q("a" = "a" + ?));
    my @bind = $dataset->bind;
    is(scalar @bind, 1);
    is(shift @bind, '1');
}

sub append_with_hash5 : Test(3) {
    
    my $dataset = SQL::OOP::Dataset->new();
    $dataset->append(
        a => SQL::OOP::Base->new(q{"a" + ?}, [1])
    );
    is($dataset->to_string_for_update, q("a" = "a" + ?));
    my @bind = $dataset->bind;
    is(scalar @bind, 1);
    is(shift @bind, '1');
}

sub compress_sql {
    
    my $sql = shift;
    $sql =~ s/[\s\r\n]+/ /gs;
    $sql =~ s/[\s\r\n]+$//gs;
    $sql =~ s/\(\s/\(/gs;
    $sql =~ s/\s\)/\)/gs;
    return $sql;
}
