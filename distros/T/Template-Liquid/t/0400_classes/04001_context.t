use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid::Context;
#
my %assigns = (
        array => {array => [10 .. 20]},
        list  => [qw[a b c d]],
        lol => [[], [qw[this that the other]], [qw[fred wilma barney betty]]],
        hash => {hash => {var => 'val'}, list => ['g' .. 'q']},
        70   => 'seventy',
        80      => [1, 2, 3],
        range_1 => 15,
        range_2 => 30
);
my $context = new_ok 'Template::Liquid::Context', [assigns => \%assigns];
#
is_deeply [$context->get('list')], [$assigns{list}], 'list';
is $context->get('list.1'),  $assigns{list}[1],  'list.1';
is $context->get('list.10'), $assigns{list}[10], 'list.10 (undef)';
is $context->get('list.size'), scalar @{$assigns{list}}, 'list.size';
is $context->get('list.first'), $assigns{list}[0],  'list.first';
is $context->get('list.last'),  $assigns{list}[-1], 'list.last';
is $context->get('lol.0.1'), $assigns{lol}[0][1], 'lol.0.1 (undef)';
is $context->get('lol.0.1'), undef, 'lol.0.1 (undef part 2)';
is_deeply [$context->get('hash')], [$assigns{hash}], 'hash';
is_deeply [$context->get('hash.hash')], [$assigns{hash}{hash}], 'hash.hash';
is $context->get('hash.hash.var'), $assigns{hash}{hash}{var}, 'hash.hash.var';
is $context->get('hash.list.0'), $assigns{hash}{list}[0], 'hash.list.0';

# Simple scalars
is $context->get('"hash.list.0"'), 'hash.list.0', '"hash.list.0"';
is $context->get("'hash.list.0'"), 'hash.list.0', "'hash.list.0'";
is $context->get(17),              17,            '#17';
is $context->get(-17),             -17,           '-17';
is $context->get(1.17),            1.17,          '1.17';
is $context->get(70),              'seventy',     '#70';
is $context->get(80.1),            '2',           '80.1';

# Missing hash keys
is $context->get('hash.fake'),      undef, 'hash.fake';
is $context->get('hash.fake.0'),    undef, 'hash.fake.0';
is $context->get('hash.fake.deep'), undef, 'hash.fake.deep';
is $context->get('list.50'),        undef, 'list.50';
is $context->get('list.fake'),      undef, 'list.fake';
is $context->get('hash.2.50'),      undef, 'list.2.50';
is $context->get(), undef, '()';
is $context->get(''),      undef, '(empty string)';
is $context->get('null'),  undef, 'null';
is $context->get('nil'),   undef, 'nil';
is $context->get('blank'), undef, 'blank';
is $context->get('empty'), undef, 'empty';
is $context->get('false'), !1,    'false';
is $context->get('true'),  !!1,   'true';
is_deeply [$context->get('(1..10)')], [[1 .. 10]], '(1..10)';
is_deeply [$context->get('(range_1..range_2)')],
    [[$assigns{range_1} .. $assigns{range_2}]], '(range_1..range_2)';
is_deeply [$context->get('("a".."z")')], [['a' .. 'z']], '("a".."z")';
is $context->get('hash[list][0]'), $assigns{hash}{list}[0], 'hash[list][0]';

# Loosly defined set trickery
ok $context->set('hash.config', 'yay'), q['hash.config' => 'yay'];
is $context->get('hash.config'), 'yay', q[check 'hash.config'];
ok $context->set('hash.config', 'woot'), q['hash.config' new value 'woot'];
is $context->get('hash.config'), 'woot', q[check new value of 'hash.config'];
ok $context->set('perl.env', \%ENV), q['perl.env' => \%ENV];
is_deeply [$context->get('perl.env')], [\%ENV],
    q[check 'perl.env' (scalar => scalar)];
ok $context->set('hash.config', \%ENV), q['hash.config' new value \%ENV];
is_deeply [$context->get('hash.config')], [\%ENV],
    q[check new value of 'hash.config' (scalar => hashref)];
ok $context->set('perl.inc', \@INC), q['perl.inc' => \@INC];
is_deeply [$context->get('perl.inc')], [\@INC], q[check 'perl.inc'];
ok $context->set('hash.config', \@INC), q['hash.config' new value \@INC];
is_deeply [$context->get('hash.config')], [\@INC],
    q[check new value of 'hash.config' (hashref => listref)];
ok $context->set('perl.inc.99', 'New Value'), q['perl.inc.99' => 'New Value'];
is $context->get('perl.inc.99'), 'New Value', q[check 'perl.inc.99'];
ok $context->set('perl.inc.99.string', 'Bug?'),
    q['perl.inc.99.string' => 'Bug?'];
is $context->get('perl.inc.99.string'), 'Bug?', q[check 'perl.inc.99.string'];
ok $context->set('perl.inc.99.string', 'Fix!'),
    q['perl.inc.99.string' new value 'Fix!'];
is $context->get('perl.inc.99.string'), 'Fix!',
    q[check new value of 'perl.inc.99.string'];
ok $context->set('perl.inc.99.string.deeper', 'Fix?'),
    q['perl.inc.99.string.deeper' new value 'Fix?'];
is $context->get('perl.inc.99.string.deeper'), 'Fix?',
    q[check new value of 'perl.inc.99.string.deeper'];
#
done_testing;
