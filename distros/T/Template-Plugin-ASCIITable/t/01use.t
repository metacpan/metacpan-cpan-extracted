#!/usr/bin/perl
use Test::More tests=>22;
use strict;
use warnings;
use Template;

my $t=Template->new();

my $input=<<'EOT';
[% USE ASCIITable %]
EOT

my $output='';

ok($t->process(\$input,{},\$output),'empty template');
is($output,"\n",'empty template output');

$input=<<'EOT';
[%- USE table=ASCIITable -%]
[%- table.cols('a','b','c') -%]
[%- table.rows([1,2,3],[4,5,6]) -%]
[%- table.draw %]
EOT
$output='';
ok($t->process(\$input,{},\$output),'simple table');
is($output,<<'OUT','simple output');
.-----------.
| a | b | c |
+---+---+---+
| 1 | 2 | 3 |
| 4 | 5 | 6 |
'---+---+---'
OUT

$input=<<'EOT';
[%- USE table=ASCIITable(cols=>['a','b','c'],show=>'rowline') -%]
[%- table.rows([1,2,3],[4,5,6]) -%]
[%- table.draw %]
EOT
$output='';
ok($t->process(\$input,{},\$output),'rowline');
is($output,<<'OUT','rowline output');
.-----------.
| a | b | c |
+---+---+---+
| 1 | 2 | 3 |
+---+---+---+
| 4 | 5 | 6 |
'---+---+---'
OUT

$input=<<'EOT';
[%- USE table=ASCIITable -%]
[%- table.rows([1,2,3234],[4,'x',6345]) -%]
[%- table.cols('a',['b','auto',5,1],['c','left',3]) %]
[%- table.draw %]
EOT
$output='';
ok($t->process(\$input,{},\$output),'widths');
is($output,<<'OUT','widths output');
.-----------------.
| a | b     | c   |
+---+-------+-----+
| 1 |     2 | 323 |
| 4 | x     | 634 |
'---+-------+-----'
OUT

$input=<<'EOT';
[%- USE table=ASCIITable(style=>'ReST-simple') -%]
[%- table.rows([1,2,3234],[4,'x',6345]) -%]
[%- table.cols('a','b','c') -%]
[%- table.draw %]
EOT
$output='';
ok($t->process(\$input,{},\$output),'style simple');
is($output,<<'OUT','style simple output');
=== === ======
 a   b   c    
=== === ======
 1   2   3234 
 4   x   6345 
=== === ======
OUT

$input=<<'EOT';
[%- USE table=ASCIITable(style=>'ReST-grid') -%]
[%- table.rows([1,2,3234],[4,'x',6345]) -%]
[%- table.cols('a','b','c') -%]
[%- table.draw %]
EOT
$output='';
ok($t->process(\$input,{},\$output),'style grid');
is($output,<<'OUT','style grid output');
+---+---+------+
| a | b | c    |
+===+===+======+
| 1 | 2 | 3234 |
+---+---+------+
| 4 | x | 6345 |
+---+---+------+
OUT

$input=<<'EOT';
[%- USE table=ASCIITable(style=>'default') -%]
[%- table.cols('a','b','c') -%]
[%- table.rows([1,2,3],[4,5,6]) -%]
[%- table.draw %]
EOT
$output='';
ok($t->process(\$input,{},\$output),'style default');
is($output,<<'OUT','style default output');
.-----------.
| a | b | c |
+---+---+---+
| 1 | 2 | 3 |
| 4 | 5 | 6 |
'---+---+---'
OUT

$input=<<'EOT';
[%- USE table=ASCIITable(style=>'default') -%]
[%- table.cols('a') -%]
[%- table.addCols('b','c') -%]
[%- table.addRows([1,2,3]) -%]
[%- table.addRows([4,5,6]) -%]
[%- table.draw %]
EOT
$output='';
ok($t->process(\$input,{},\$output),'add');
is($output,<<'OUT','add output');
.-----------.
| a | b | c |
+---+---+---+
| 1 | 2 | 3 |
| 4 | 5 | 6 |
'---+---+---'
OUT

$input=<<'EOT';
[%- USE table=ASCIITable(style=>
  [[' /',' \\','-','T'],
   ['#','#','#'],
   ['>','<','=','+'],
   ['|','|','-'],
   [' \\','/ ','_','"'],
   [':',';','.','*']]) -%]
[%- table.cols('a','b','c') -%]
[%- table.rows([1,2,3],[4,5,6]) -%]
[%- table.hide('firstline') -%]
[%- table.show('rowline') -%]
[%- table.draw %]
EOT
$output='';
ok($t->process(\$input,{},\$output),'style by hand');
is($output,<<'OUT','style by hand output');
# a # b # c #
>===+===+===<
| 1 - 2 - 3 |
:...*...*...;
| 4 - 5 - 6 |
 \__"___"__/ 
OUT

$input=<<'EOT';
[%- USE table=ASCIITable(allow=>'html') -%]
[%- table.cols('a','b','c') -%]
[%- table.rows(['<b>1</b>',2,3],[4,5,6]) -%]
[%- table.draw %]
EOT
$output='';
ok($t->process(\$input,{},\$output),'html');
is($output,<<'OUT','html output');
.-----------.
| a | b | c |
+---+---+---+
| <b>1</b> | 2 | 3 |
| 4 | 5 | 6 |
'---+---+---'
OUT

$input=<<'EOT';
[%- USE table=ASCIITable(allow=>'html') -%]
[%- table.cols('a','b','c') -%]
[%- table.rows(['<b>1</b>',2,3],[4,5,6]) -%]
[%- table.deny('html') -%]
[%- table.draw %]
EOT
$output='';
ok($t->process(\$input,{},\$output),'no html');
is($output,<<'OUT','no html output');
.------------------.
| a        | b | c |
+----------+---+---+
| <b>1</b> | 2 | 3 |
|        4 | 5 | 6 |
'----------+---+---'
OUT

diag($t->error());
