package Plain;

use Test::More tests => 25;
use lib qw ( ./blib/lib/ );
use strict;
use Parse::Plain 3.0;
my ($t1, $t2, $t3, $t4);

ok($] >= 5.005, 'Perl version');

@SUBCLASS::ISA = qw( Parse::Plain );
$t1 = new Parse::Plain './t/tmpl/1.tmpl';
$t2 = new SUBCLASS './t/tmpl/2.tmpl';
$t3 = new SUBCLASS './t/tmpl/3.tmpl';
$t4 = new SUBCLASS './t/tmpl/4.tmpl';
ok(UNIVERSAL::isa($t2, 'Parse::Plain'), 'empty subclass');

# tag functions
$t4->set_tag('nonexisting tag', 'blah-blah');

$t2->set_tag('space', ' ');
$t2->set_tag('DP', '%%');
$t2->set_tag('DCL', '{{');
$t2->set_tag('DCR', '}}');

$t1->set_tag('t', 'T');
$t1->set_tag({'1' => 'un', '2' => 'deux', '3' => 'troi'});
$t1->push_tag('t' => 'U');
$t1->push_tag({'t' => 'V', '1' => 'e'});
$t1->unshift_tag('t' => 'S');
$t1->unshift_tag({'t' => 'R', '1' => '_'});
$t2->gtag('globaltag', 'GT');
$t2->callback('braces', sub {return ('[' . $_[0] . ']');});

is($t2->gtag(['globaltag'])->{'globaltag'}, 'GT', 'gtag(ARRAYREF)');
is($t1->get_tag('t')->[0], 'RSTUV', 'get_tag(SCALAR)');
is($t1->get_tag('3')->[0], 'troi', 'get_tag(SCALAR)');
is(($t1->get_tag('2', '3', '2'))->[1], 'troi', 'get_tag(LIST)');
is($t1->get_tag(['1', '2', '1'])->[2], '_une', 'get_tag(ARRAYREF)');

is($t2->get_tag('DP')->[0], '%%', 'get_tag(\'DP\')');
is($t2->get_tag('DCL')->[0], '{{', 'get_tag(\'DCL\')');
is($t2->get_tag('DCR')->[0], '}}', 'get_tag(\'DCR\')');

# block functions
is($t2->block('bl8')->{'bl8'}, 'block8', 'block(SOURCE)');
is($t2->block_src('bl8')->{'bl8'}, 'block8', 'block_src()');
is($t2->block_res('bl8')->{'bl8'}, undef, 'block_res()');

$t2->parse('bl8');
is($t2->block_src('bl8')->{'bl8'}, 'block8', 'block_src()');
is($t2->block_res('bl8')->{'bl8'}, 'block8', 'block_res()');
is($t2->block('bl8')->{'bl8'}, 'block8', 'block(RESULT)');

$t2->parse('bl8');
is($t2->block('bl8')->{'bl8'}, 'block8block8', 'push_block_res(RESULT)');

$t2->push_block_res({'bl8' => '!'});
$t2->unshift_block_res({'bl8' => '!'});
is($t2->block('bl8')->{'bl8'}, '!block8block8!', 'unshift_block_res(RESULT)');

$t2->block_src({'bl8' => 'BLOCK8'});
$t2->push_block_src({'bl8' => '!'});
$t2->unshift_block_src({'bl8' => '!'});
$t2->parse('bl8');
is($t2->block('bl8')->{'bl8'}, '!block8block8!!BLOCK8!',
    'push/unshift_block_src(RESULT)');

$t2->reset_block_src('bl8');
is($t2->block_src('bl8')->{'bl8'}, 'block8', 'reset_block_src(LIST)');
$t2->reset_block_src(['bl8']);
is($t2->block_src('bl8')->{'bl8'}, 'block8', 'reset_block_src(ARRAYREF)');
$t2->reset_block_src_all();
is($t2->block_src('bl8')->{'bl8'}, 'block8', 'reset_block_src_all()');
is($t2->get_oblock(['bl8'])->{'bl8'}, 'block8', 'get_oblock(ARRAYREF)');

$t2->unparse(['bl8']);
is($t2->block_res('bl8')->{'bl8'}, undef, 'unparse(ARRAYREF)');

$t2->parse('bl8');
$t2->parse('bl7', {}, 1);
$t2->parse('bl6', {}, 1);
$t2->parse('bl5', {}, 1);
$t2->parse('bl7', {}, 1);
$t2->parse('bl4', {}, 1);
$t2->parse('bl4', {}, 1);
$t2->parse('bl3', {'obj' => $t3}, 1);
$t2->parse('bl2', {}, 1);
$t2->parse('bl1', {}, 1);
$t1->set_tag('tag2', $t2);

open(RESULT, '<./t/tmpl/result');
my $result = join('', <RESULT>);
close(RESULT);
$t1->parse;
is($result, $t1->parse(), 'result');

