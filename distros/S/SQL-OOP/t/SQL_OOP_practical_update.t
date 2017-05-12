package Temp;
use strict;
use warnings;
use base 'Test::Class';
use Test::More;
use SQL::OOP;
use SQL::OOP::Join;
use SQL::OOP::Where;
use SQL::OOP::Update;
use SQL::OOP::Dataset;

__PACKAGE__->runtests;

sub default_cond_and_flex_cond : Test(4) {
    
    my $users = _update_user('jamadam', ['point' => '10']);
    is($users->to_string, q{UPDATE "user" SET "point" = ? WHERE "userid" = ?});
    my @bind = $users->bind;
    is(scalar @bind, 2);
    is(shift @bind, 10);
    is(shift @bind, 'jamadam');
}

sub default_cond_and_flex_cond_undef : Test(4) {
    
    my $users = _update_user('jamadam', ['point' => undef]);
    is($users->to_string, q{UPDATE "user" SET "point" = ? WHERE "userid" = ?});
    my @bind = $users->bind;
    is(scalar @bind, 2);
    is(shift @bind, undef);
    is(shift @bind, 'jamadam');
}

sub _update_user {
    
    my ($userid, $dataset_ref) = @_;
    my $sql = SQL::OOP::Update->new();
    $sql->set(
        $sql->ARG_TABLE     => SQL::OOP::ID->new('user'),
        $sql->ARG_DATASET   => SQL::OOP::Dataset->new($dataset_ref),
        $sql->ARG_WHERE     => SQL::OOP::Where->cmp('=', 'userid', $userid),
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
