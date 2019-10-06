#!perl

use strict;

use Test::More tests => 9;

require_ok('Starlink::AST');

do {
    my $val = Starlink::AST::TuneC('HRDel');
    is($val, '%-%^50+%s70+h%+');

    is(Starlink::AST::StripEscapes($val), 'h');

    Starlink::AST::TuneC('HRDel', 'newval');
    is(Starlink::AST::TuneC('HRDel'), 'newval');

    Starlink::AST::TuneC('HRDel', $val);
    is(Starlink::AST::TuneC('HRDel'), $val);
};

do {
    my $obj = new Starlink::AST::TimeFrame('');
    my ($routine, $file, $line) = $obj->CreatedAt();

    my $copy = $obj->Copy();
    ok(! $obj->Same($copy));

    my $clone = $obj->Clone();
    ok($obj->Same($clone));

    my $str = $obj->ToString();
    my $fromstr = Starlink::AST::FromString($str);

    isa_ok($fromstr, 'Starlink::AST::TimeFrame');
    ok($obj->Equal($fromstr));
};
