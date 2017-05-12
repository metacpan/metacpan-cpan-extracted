#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Perinci::Examples;
use Perinci::Tx::Util qw(use_other_actions);

package Foo;

sub fixable   {
    my %a = @_;
    [200, "Fixable", undef,
     {undo_actions => [["Foo::fixable",{a=>-$a{a}}]]}];
}
sub fixed     { [304, "Fixed"] }
sub unfixable { [412, "Unfixable"] }
sub error     { [500, "Error"] }

package main;

subtest use_other_actions => sub {
    subtest "all fixed -> fixed" => sub {
        is(use_other_actions(actions=>[["Foo::fixed"=>{}]])->[0], 304);
        is(use_other_actions(actions=>[
            ["Foo::fixed"=>{}],["Foo::fixed"=>{}]])->[0],
           304);
    };

    subtest "contains fixable -> fixable" => sub {
        my $res = use_other_actions(actions=>[
            ["Foo::fixed"=>{}],
            ["Foo::fixable"=>{a=>1}],
            ["Foo::fixed"=>{}],
            ["Foo::fixable"=>{a=>2}],
        ]);
        is($res->[0], 200);
        is_deeply($res->[3]{do_actions},
           [["Foo::fixable", {a=>1}], ["Foo::fixable", {a=>2}]])
            or diag explain $res->[3]{do_actions};
        is_deeply($res->[3]{undo_actions},
           [["Foo::fixable", {a=>-2}], ["Foo::fixable", {a=>-1}]])
            or diag explain $res->[3]{undo_actions};
    };

    subtest "contains unfixable -> unfixable" => sub {
        my $res = use_other_actions(actions=>[
            ["Foo::fixed"=>{}],
            ["Foo::fixable"=>{a=>1}],
            ["Foo::unfixable"=>{}],
        ]);
        is($res->[0], 412);
    };

    subtest "contains error -> error" => sub {
        my $res = use_other_actions(actions=>[
            ["Foo::fixed"=>{}],
            ["Foo::fixable"=>{a=>1}],
            ["Foo::error"=>{}],
        ]);
        is($res->[0], 500);
    };
};

done_testing();
