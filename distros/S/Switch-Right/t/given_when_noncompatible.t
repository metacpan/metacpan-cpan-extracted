# THESE TESTS ARE ADAPTED FROM PERL'S OWN TESTSUITE
# THE MODULE DOES NOT IMPLEMENT THE MECHANISMS THEY TEST, SO THEY SHOULD ALL FAIL
# TESTS MARKED "UNRELIABLE" DO NOT FAIL WHEN THEY SHOULD, HENCE THEY ARE NOT TESTING WHAT THEY CLAIM

use v5.36;
use strict;
use warnings;


use Test2::V0;

plan tests => 17;

no feature 'switch';
use Switch::Right;

no warnings qw< void uninitialized >;

sub be_true {1}


todo "Weird scoping of var decls in postfix when" => sub {

    no warnings 'shadow';
    my $x = 0;
    given(my $x = 1) {
        my $x = 2, continue when be_true();
        is($x, undef, "scope after my \$x = ... when ...");
    }
};


todo "given/when in a do block doesn't always work" => sub {
    # Test do { given } as a rvalue

    {
        # Postfix scalar
        my $lexical = 5;
        my @exp = (5, 7, 9);
        for (0, 1, 2) {
            no warnings 'void';
            my $scalar = do { given ($_) {
                $lexical when 0;
                8, 9     when 2;
                6, 7;
            } };
            is($scalar, shift(@exp), "rvalue given - postfix scalar [$_]");
        }
    }
    {
        # Postfix list
        my @things = (12);
        my @exp = ('3 4 5', '6 7', '12');
        for (0, 1, 2) {
            my @list = do { given ($_) {
                3 .. 5  when 0;
                @things when 2;
                6, 7;
            } };
            is("@list", shift(@exp), "rvalue given - postfix list [$_]");
        }
    }
    # THIS TEST IS UNRELIABLE...
    # {
    #     # Switch control
    #     my @exp = ('6 7', '', '6 7');
    #     for (0, 1, 2, 3) {
    #         my @list = do { given ($_) {
    #             continue when $_ <= 1;
    #             break    when 1;
    #             next     when 2;
    #             6, 7;
    #         } };
    #         is("@list", shift(@exp), "rvalue given - switch control [$_]");
    #     }
    # }

    # Test that returned values are correctly propagated through several context
    # levels (see RT #93548).
    {
        my $tester = sub {
            my $id = shift;

            package fmurrr;
            use Switch::Right;

            our ($when_loc, $given_loc, $ext_loc);

            my $ext_lex    = 7;
            our $ext_glob  = 8;
            local $ext_loc = 9;

            given ($id) {
                my $given_lex    = 4;
                our $given_glob  = 5;
                local $given_loc = 6;

                when (0) { 0 }

                when (1) { my $when_lex    = 1 }
                when (2) { our $when_glob  = 2 }
                when (3) { local $when_loc = 3 }

                when (4) { $given_lex }
                when (5) { $given_glob }
                when (6) { $given_loc }

                when (7) { $ext_lex }
                when (8) { $ext_glob }
                when (9) { $ext_loc }

                'fallback';
            }
        };

        my @descriptions = qw<
            constant

            when-lexical
            when-global
            when-local

            given-lexical
            given-global
            given-local

            extern-lexical
            extern-global
            extern-local
        >;

        for my $id (0 .. 9) {
            my $desc = $descriptions[$id];

            my $res = $tester->($id);

            # THIS IS THE NULL HYPOTHESIS, SO DON'T BOTH TESTING IT FOR NON-COMPATIBILITY...
            # is $res, $id, "plain call - $desc";

            $res = do {
                my $id_plus_1 = $id + 1;
                given ($id_plus_1) {
                    do {
                        when (/\d/) {
                            --$id_plus_1;
                            continue;
                            456;
                        }
                    };
                    default {
                        $tester->($id_plus_1);
                    }
                    'XXX';
                }
            };
            is $res, $id, "across continue and default - $desc";
        }
    }

    # THIS TEST IS UNRELIABLE
    # #  Check that values returned from given/when are destroyed at the right time.
    # {
    #     {
    #         package Fmurrr;
    #
    #         sub new {
    #             bless {
    #                 flag => \($_[1]),
    #                 id   => $_[2],
    #             }, $_[0]
    #         }
    #
    #         sub DESTROY {
    #             ${$_[0]->{flag}}++;
    #         }
    #     }
    #
    #     my @descriptions = qw<
    #         when
    #         break
    #         continue
    #         default
    #     >;
    #
    #     for my $id (0 .. 3) {
    #         my $desc = $descriptions[$id];
    #
    #         my $destroyed = 0;
    #         my $res_id;
    #
    #         {
    #             my $res = do {
    #                 given ($id) {
    #                     my $x;
    #                     when (0) { Fmurrr->new($destroyed, 0) }
    #                     when (1) { my $y = Fmurrr->new($destroyed, 1); break }
    #                     when (2) { $x = Fmurrr->new($destroyed, 2); continue }
    #                     when (2) { $x }
    #                     default  { Fmurrr->new($destroyed, 3) }
    #                 }
    #             };
    #             $res_id = $res->{id};
    #         }
    #         $res_id = $id if $id == 1; # break doesn't return anything
    #
    #         is $res_id,    $id, "given/when returns the right object - $desc";
    #         is $destroyed, 1,   "given/when does not leak - $desc";
    #     };
    # }

    # THIS TEST IS UNRELIABLE
    # #  break() must reset the stack
    # {
    #     my @res = (1, do {
    #         given ("x") {
    #             2, 3, do {
    #                 when (/[a-z]/) {
    #                     4, 5, 6, break
    #                 }
    #             }
    #         }
    #     });
    #     is "@res", "1", "break resets the stack";
    # }
};

done_testing();
