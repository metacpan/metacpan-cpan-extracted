use strict;
use warnings;
use utf8;
use Test::More;
use PLON;

is(PLON->new->encode(sub { }), 'sub { "DUMMY" }');
like(PLON->new->deparse->encode(sub { 1 }), qr!\Asub \{\s*.*;1;\s*\}\z!);

for my $code ('sub { }', '[sub { }]') {
    eval {
        PLON->new->decode($code)
    };
    like $@, qr/Cannot decode PLON contains CodeRef./;
}

done_testing;

