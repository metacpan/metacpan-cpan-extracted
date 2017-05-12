package Temp;
use strict;
use warnings;
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Join;
use SQL::OOP::Where;
use SQL::OOP::Insert;
use SQL::OOP::Dataset;

__PACKAGE__->runtests;

sub default_cond_and_flex_cond : Test(3) {
    
    my $users = _insert_user('jamadam', ['point' => '10']);
    is($users->to_string, q{INSERT INTO "user" ("point") VALUES (?)});
    my @bind = $users->bind;
    is(scalar @bind, 1);
    is(shift @bind, 10);
}

sub default_cond_and_flex_cond_undef : Test(3) {
    
    my $users = _insert_user('jamadam', ['point' => undef]);
    is($users->to_string, q{INSERT INTO "user" ("point") VALUES (?)});
    my @bind = $users->bind;
    is(scalar @bind, 1);
    is(shift @bind, undef);
}

sub _insert_user {
    
    my ($userid, $dataset_ref) = @_;
    my $sql = SQL::OOP::Insert->new();
    $sql->set(
    $sql->ARG_TABLE     => SQL::OOP::ID->new('user'),
    $sql->ARG_DATASET   => SQL::OOP::Dataset->new($dataset_ref),
    );
    return $sql;
}

sub compress_sql {
    
    my $sql = shift;
    $sql =~ s/[\s\r\n]+/ /gs;
    $sql =~ s/[\s\r\n]+$//gs;
    $sql =~ s/\(\s/\(/gs;
    $sql =~ s/\s\)/\)/gs;
    return $sql;
}
