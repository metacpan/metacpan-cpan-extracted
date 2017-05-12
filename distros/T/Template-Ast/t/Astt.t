#: Astt.t
#: Test script for Astt.pl
#: Template-Ast v0.01
#: Copyright (c) Agent Zhang
#: 2005-07-15 2005-07-15

use strict;
#use warnings;

use File::Compare;
use Test::More tests => 5;
use Template::Ast;

my $dir = '.';
my $bindir = '../script';
if (-d 't') {
    $dir = 't';
    $bindir = 'script';
}
my $astt = "perl $bindir/astt.pl";

#ok(system("$astt -o $dir/Archive1.pod -t $dir/pod.tt $dir/Archive1.ast") == 0);
#is(compare("$dir/Archive1.pod", "$dir/Archive1.pod~"), 0);

#ok(system("$astt -t $dir/pod.tt $dir/Archive2.ast > $dir/Archive2.pod") == 0);
#is(compare("$dir/Archive2.pod", "$dir/Archive2.pod~"), 0);

my $ast1 = {
    version => '0.05',
    alu => { capacity => 1024, sels => [qw(ADD SUB)], delay => 1 },
};

my $ast2 = {
    alu => { sels => [qw(MUL DIV)], delay => 3, word_size => 32 },
    ram => { delay => 2, word_size => 16 },
};

ok(Template::Ast->write({ast => $ast1}, "$dir/ast1"));
ok(Template::Ast->write({ast => $ast2}, "$dir/ast2"));
ok(system("$astt -o $dir/ast -t $dir/ast.tt $dir/ast1 $dir/ast2") == 0);
my $temp = Template::Ast->read("$dir/ast");
ok($temp);

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
};

ok(eq_hash($temp, $ast));
