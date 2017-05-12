#!perl -T

use 5.006;
use strict;
use warnings;
use Data::Dumper;
use lib 'lib';

use warnings FATAL => 'all';
use Test::More;

plan tests => 4;

use Parse::Gnaw;

# a fully automated rule
rule('rule1', 
	'a', 
	'b',
);


# a mixed rule, some automated, some manual.
rule('rule2', 
	'c', 
	call('rule1'),
);



{

print Dumper $rule1;
print Dumper $rule2;

ok(scalar(@$rule1)==3, "check rule1 is size 3");
ok(scalar(@$rule2)==3, "check rule2 is size 3");

ok($rule2->[2]->[0] eq 'call', 		"check the call function turned into a 'call' string");
ok($rule2->[2]->[1] eq 'rule1', 	"check the name of called subroutine got formatted correctly");

# print out contents for debug purposes.


}

__DATA__


$VAR1 = [
          [
            'rule',
            'rule1',
            {
              'methodname' => 'rule',
              'filename' => 't/gnaw_call.t',
              'linenum' => 17,
              'payload' => 'rule1',
              'quantifier' => '',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'a',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_call.t',
              'linenum' => 17,
              'payload' => 'a',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'b',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_call.t',
              'linenum' => 17,
              'payload' => 'b',
              'package' => 'main'
            }
          ]
        ];
$VAR1 = [
          [
            'rule',
            'rule2',
            {
              'methodname' => 'rule',
              'filename' => 't/gnaw_call.t',
              'linenum' => 24,
              'payload' => 'rule2',
              'quantifier' => '',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'c',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_call.t',
              'linenum' => 24,
              'payload' => 'c',
              'package' => 'main'
            }
          ],
          [
            'call',
            'rule1',
            {
              'methodname' => 'call',
              'filename' => 't/gnaw_call.t',
              'payload' => 'rule1',
              'linenum' => 24,
              'package' => 'main'
            }
          ]
        ];

