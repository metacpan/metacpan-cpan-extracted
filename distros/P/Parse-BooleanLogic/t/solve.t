
use strict;
use warnings;

use Test::More tests => 43;

use_ok 'Parse::BooleanLogic';

my $p = new Parse::BooleanLogic;

my $cb = sub { return $_[0]->{'v'} };

ok  $p->solve( [{ v => 1 }], $cb ), "true";
ok !$p->solve( [{ v => 0 }], $cb ), "false";

ok !$p->solve( [{v => 0}, 'AND', {v => 0}], $cb ), "0 AND 0";
ok !$p->solve( [{v => 0}, 'AND', {v => 1}], $cb ), "0 AND 1";
ok !$p->solve( [{v => 1}, 'AND', {v => 0}], $cb ), "1 AND 0";
ok  $p->solve( [{v => 1}, 'AND', {v => 1}], $cb ), "1 AND 1";

ok !$p->solve( [{v => 0}, 'OR', {v => 0}], $cb ), "0 OR 0";
ok  $p->solve( [{v => 0}, 'OR', {v => 1}], $cb ), "0 OR 1";
ok  $p->solve( [{v => 1}, 'OR', {v => 0}], $cb ), "1 OR 0";
ok  $p->solve( [{v => 1}, 'OR', {v => 1}], $cb ), "1 OR 1";

ok !$p->solve( [{v => 0}, 'AND', {v => 0}, 'OR', {v => 0}], $cb ), "0 AND 0 OR 0";
ok  $p->solve( [{v => 0}, 'AND', {v => 0}, 'OR', {v => 1}], $cb ), "0 AND 0 OR 1";
ok !$p->solve( [{v => 0}, 'AND', {v => 1}, 'OR', {v => 0}], $cb ), "0 AND 1 OR 0";
ok  $p->solve( [{v => 0}, 'AND', {v => 1}, 'OR', {v => 1}], $cb ), "0 AND 1 OR 1";
ok !$p->solve( [{v => 1}, 'AND', {v => 0}, 'OR', {v => 0}], $cb ), "1 AND 0 OR 0";
ok  $p->solve( [{v => 1}, 'AND', {v => 0}, 'OR', {v => 1}], $cb ), "1 AND 0 OR 1";
ok  $p->solve( [{v => 1}, 'AND', {v => 1}, 'OR', {v => 0}], $cb ), "1 AND 1 OR 0";
ok  $p->solve( [{v => 1}, 'AND', {v => 1}, 'OR', {v => 1}], $cb ), "1 AND 1 OR 1";

ok !$p->solve( [{v => 0}, 'OR', {v => 0}, 'AND', {v => 0}], $cb ), "0 OR 0 AND 0";
ok !$p->solve( [{v => 0}, 'OR', {v => 0}, 'AND', {v => 1}], $cb ), "0 OR 0 AND 1";
ok !$p->solve( [{v => 0}, 'OR', {v => 1}, 'AND', {v => 0}], $cb ), "0 OR 1 AND 0";
ok  $p->solve( [{v => 0}, 'OR', {v => 1}, 'AND', {v => 1}], $cb ), "0 OR 1 AND 1";
ok !$p->solve( [{v => 1}, 'OR', {v => 0}, 'AND', {v => 0}], $cb ), "1 OR 0 AND 0";
ok  $p->solve( [{v => 1}, 'OR', {v => 0}, 'AND', {v => 1}], $cb ), "1 OR 0 AND 1";
ok !$p->solve( [{v => 1}, 'OR', {v => 1}, 'AND', {v => 0}], $cb ), "1 OR 1 AND 0";
ok  $p->solve( [{v => 1}, 'OR', {v => 1}, 'AND', {v => 1}], $cb ), "1 OR 1 AND 1";

ok !$p->solve( [{v => 0}, 'AND', [ {v => 0}, 'OR', {v => 0}]], $cb ), "0 AND (0 OR 0)";
ok !$p->solve( [{v => 0}, 'AND', [ {v => 0}, 'OR', {v => 1}]], $cb ), "0 AND (0 OR 1)";
ok !$p->solve( [{v => 0}, 'AND', [ {v => 1}, 'OR', {v => 0}]], $cb ), "0 AND (1 OR 0)";
ok !$p->solve( [{v => 0}, 'AND', [ {v => 1}, 'OR', {v => 1}]], $cb ), "0 AND (1 OR 1)";
ok !$p->solve( [{v => 1}, 'AND', [ {v => 0}, 'OR', {v => 0}]], $cb ), "1 AND (0 OR 0)";
ok  $p->solve( [{v => 1}, 'AND', [ {v => 0}, 'OR', {v => 1}]], $cb ), "1 AND (0 OR 1)";
ok  $p->solve( [{v => 1}, 'AND', [ {v => 1}, 'OR', {v => 0}]], $cb ), "1 AND (1 OR 0)";
ok  $p->solve( [{v => 1}, 'AND', [ {v => 1}, 'OR', {v => 1}]], $cb ), "1 AND (1 OR 1)";

ok !$p->solve( [{v => 0}, 'OR', [ {v => 0}, 'AND', {v => 0}]], $cb ), "0 OR (0 AND 0)";
ok !$p->solve( [{v => 0}, 'OR', [ {v => 0}, 'AND', {v => 1}]], $cb ), "0 OR (0 AND 1)";
ok !$p->solve( [{v => 0}, 'OR', [ {v => 1}, 'AND', {v => 0}]], $cb ), "0 OR (1 AND 0)";
ok  $p->solve( [{v => 0}, 'OR', [ {v => 1}, 'AND', {v => 1}]], $cb ), "0 OR (1 AND 1)";
ok  $p->solve( [{v => 1}, 'OR', [ {v => 0}, 'AND', {v => 0}]], $cb ), "1 OR (0 AND 0)";
ok  $p->solve( [{v => 1}, 'OR', [ {v => 0}, 'AND', {v => 1}]], $cb ), "1 OR (0 AND 1)";
ok  $p->solve( [{v => 1}, 'OR', [ {v => 1}, 'AND', {v => 0}]], $cb ), "1 OR (1 AND 0)";
ok  $p->solve( [{v => 1}, 'OR', [ {v => 1}, 'AND', {v => 1}]], $cb ), "1 OR (1 AND 1)";

