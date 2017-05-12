#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::More tests => 120;
#use Test::More 'no_plan';

my $CLASS;
BEGIN {
    $CLASS = 'Pg::Priv';
    use_ok $CLASS or die;
}

my @all_privs = qw(r w a d D x t X U C c T);

for my $spec (
    [
        simple => [
            'postgres=arwdDxt/postgres',
        ] => [
            [ 'postgres', 'postgres', [qw(a r w d D x t)] ],
        ],
    ],

    [
        public => [
            '=arwdDxt/postgres',
        ] => [
            [ 'public', 'postgres', [qw(a r w d D x t)] ],
        ],
    ],

    [
        group => [
            'group foo=arw/Fred',
        ] => [
            [ 'foo', 'Fred', [qw(a r w)] ],
        ],
    ],

    [
        double => [
            'david=arwdt/postgres',
            '=r/postgres',
        ] => [
            [ 'david', 'postgres', [qw(a r w d t)] ],
            [ 'public', 'postgres', ['r'] ],
        ],
    ],

    [
        star => [
            'postgres=arwdDxt/postgres',
            'fred=*/postgres',
        ] => [
            [ 'postgres', 'postgres', [qw(a r w d D x t)] ],
            [ 'fred', 'postgres', [qw(a r w d D x t)] ],
        ],
    ],

    [
        bric => [
            'postgres=arwdDxt/postgres',
            'bric=arwd/postgres',
        ] => [
            [ 'postgres', 'postgres', [qw(a r w d D x t)] ],
            [ 'bric', 'postgres', [qw(a r w d)] ],
        ],
    ],

    [
        pgdocs => [
            'miriam=arwdDxt/miriam',
            '=r/miriam',
            'admin=arw/miriam',
        ] => [
            [ 'miriam', 'miriam', [qw(a r w d D x t)] ],
            [ 'public', 'miriam', [qw(r)] ],
            [ 'admin', 'miriam', [qw(a r w)] ],
        ],
    ],

) {
    my ($desc, $acl, $expects) = @{ $spec };
    ok my @privs = $CLASS->parse_acl($acl), "Parse $desc ACL";

    my $count = 0;
    my @expects = @{ $expects }; # shallow copy
    for my $priv (@privs) {
        ++$count;
        my $exp = shift @expects;

        isa_ok $priv, 'Pg::Priv', "$desc ACL priv $count";
        is $priv->to, $exp->[0], qq{$desc ACL priv $count grantee is "$exp->[0]"};
        is $priv->by, $exp->[1], qq{$desc ACL priv $count grantor is "$exp->[1]"};
        ok $priv->can(@{ $exp->[2] }), "$desc ACL priv $count can(@{ $exp->[2] })";

        my %seen;
        @seen{@all_privs} = ();
        delete @seen{ @{ $exp->[2] } };
        if (my @oops = grep { $priv->can($_) } keys %seen) {
            my $s = @oops > 1 ? 's' : '';
            fail qq{$desc ACL priv $count should not have permission$s "@oops"};
        } else {
            @oops = keys %seen;
            pass qq{$desc ACL priv $count should not have permissions "@oops"};
        }
    }

    # Check scalar context.
    ok my $privs = $CLASS->parse_acl($acl), "Parse $desc ACL in scalar context";
    is_deeply [ map { $_->privs } @$privs ],
              [ map { $_->privs } @privs ],
              'Should have same privs in scalar context';
    is_deeply [ map { $_->to } @$privs ],
              [ map { $_->to } @privs ],
              'Should have same grantees in scalar context';
    is_deeply [ map { $_->by } @$privs ],
              [ map { $_->by } @privs ],
              'Should have same grantors in scalar context';

    # Check quote_ident.
    $count = 0;
    @expects = @{ $expects }; # shallow copy again.
    for my $priv ($CLASS->parse_acl($acl, 1)) {
        my $exp = shift @expects;
        my $to  = Pg::Priv::_quote_ident $exp->[0];
        is $priv->to, $to, qq{$desc ACL priv $count quoted grantee is '$to'};
        my $by  = Pg::Priv::_quote_ident $exp->[1];
        is $priv->by, $by, qq{$desc ACL priv $count quoted grantor is '$by'};
    }
}
