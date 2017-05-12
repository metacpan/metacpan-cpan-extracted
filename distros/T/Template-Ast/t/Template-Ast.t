#: Template-Ast.t
#: Test script for the Template::Ast module
#: Template-Ast v0.01
#: Copyright (c) 2005 Agent Zhang
#: 2005-07-15 2005-07-17

use strict;
#use warnings;
use Data::Dumper;

use Test::More tests => 25;
use Template::Ast;

#########################

my $dir = '.';
if (-d 't') {
    $dir = 't';
}

my $ast1 = {
    version => '0.05',
    alu => { capacity => 1024, sels => [qw(ADD SUB)], delay => 1 },
    date => '2005-07',
    author => undef,
};

my $ast2 = {
    alu => { sels => [qw(MUL DIV)], delay => 3, word_size => 32 },
    ram => { delay => 2, word_size => 16 },
    date => undef,
    author => 'agent',
};

ok(Template::Ast->write($ast1, "$dir/ast1"));
my $temp = Template::Ast->read("$dir/ast1");
ok($temp);
ok(eq_hash($ast1, $temp));
ok(!eq_hash($ast2, $temp));

ok(Template::Ast->write($ast2, "$dir/ast2"));
$temp = Template::Ast->read("$dir/ast2");
ok($temp);
ok(eq_hash($ast2, $temp));
ok(!eq_hash($ast1, $temp));

$temp = Template::Ast->merge($ast1, $ast2);
my $ast = {
    version => '0.05',
    alu => {
        capacity => 1024,
        sels => [qw(MUL DIV)],
        delay => 3,
        word_size => 32,
    },
    ram => {
        delay => 2,
        word_size => 16,
    },
    date => '2005-07',
    author => 'agent',
};
ok(eq_hash($temp, $ast));
is(
    Data::Dumper->Dump([$temp], ['ast']),
    Template::Ast->dump([$temp], ['ast'])
);
#warn Data::Dumper->Dump([$temp], ['ast']);

$temp = Template::Ast->read("$dir/ast1");
ok($temp);
ok(eq_hash($ast1, $temp));

$temp = Template::Ast->read("$dir/ast2");
ok($temp);
ok(eq_hash($ast2, $temp));

ok(eq_array(Template::Ast->merge([1,2,3], undef), [1,2,3]));
ok(eq_array(Template::Ast->merge(undef, [1,2,3]), [1,2,3]));
ok(!defined Template::Ast->merge(undef, undef));

ok(eq_array(Template::Ast->merge({A=>1,B=>2}, ['C']), ['C']));
ok(eq_array(Template::Ast->merge([1,2,3], [5,6]), [5,6]));
is(Template::Ast->merge([{A=>1},2], 5), 5);

ok(eq_hash(Template::Ast->merge({A=>1,B=>2}, {C=>3}), {A=>1,B=>2,C=>3}));
ok(eq_hash(Template::Ast->merge({A=>1,B=>2}, {B=>3}), {A=>1,B=>3}));
    
ok(eq_hash(Template::Ast->merge(
        {A=>1,B=>{C=>1,D=>2}},
        {B=>{C=>1,D=>3,E=>4}}
), {A=>1,B=>{C=>1,D=>3,E=>4}}));

ok(eq_hash(Template::Ast->merge(
        {A=>1,B=>{C=>[1,2]}},
        {B=>{C=>[3,4]}}
), {A=>1,B=>{C=>[3,4]}}));

$temp = Template::Ast->merge({A=>1,B=>undef}, {A=>undef,B=>2});
ok eq_hash($temp, {A=>1,B=>2});