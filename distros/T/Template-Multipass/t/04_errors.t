#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use ok 'Template::Multipass';

{
    my $t = Template::Multipass->new(
        MULTIPASS => {
            VARS      => {
                one   => 1,
                two   => 2,
                three => 3,
            },
        },
    );

    my $tmpl = '<% one %>, {% two } %}, [% three %]';

    ok( !$t->process( \$tmpl, { one => "uno", two => "dos", three => "tres" }, \( my $out ) ), "error" );
    like( $t->error, qr/unexpected token \(}\)/, "parse error" );
    is( $out, undef, "no output" );
}

{
    my $t = Template::Multipass->new(
        MULTIPASS => {
            VARS      => {
                one   => 1,
                two   => 2,
                three => 3,
            },
        },
    );

    my $tmpl = '<% one %>, {% two %}, [% three } %]';

    ok( !$t->process( \$tmpl, { one => "uno", two => "dos", three => "tres" }, \( my $out ) ), "error" );
    like( $t->error, qr/unexpected token \(}\)/, "parse error" );
    is( $out, undef, "no output" );

}
