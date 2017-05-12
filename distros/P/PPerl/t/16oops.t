#!perl -w
use strict;
use Test;
plan tests => 1;

`./pperl -Iblib/lib -Iblib/arch --prefork 1 t/oops.plx`;
skip("closure 'bug'", `./pperl t/oops.plx` != `./pperl t/oops.plx`);
`./pperl -k t/oops.plx`;
