#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;
use lib 'lib';

use Test::More;

plan tests => 5;

use Parse::Gnaw;

# a fully automated rule
rule('rule1', 
	'a', 
	'b');



# a mixed rule, some automated, some manual.
rule('rule2', {heading=>'any'},
	'c', 
	[ 'lit', 'd', __FILE__,__LINE__  ],
	[ 'lit', 'e', __FILE__,__LINE__  ],
);




# multi-character literals get broken up into individual characters 
rule('rule4',
	'hello',
);


{

# print out contents for debug purposes.
print Dumper $rule1;
print Dumper $rule2;
print Dumper $rule4;


# all we're verifying is that "rule" creates arrays of the correct name and size.
# note that first index is the name of the rule.
ok(scalar(@$rule1)==3, "check rule1 is size 3");
ok(scalar(@$rule2)==4, "check rule2 is size 4");
ok(scalar(@$rule4)==6, "check rule4 is size 8");

ok($rule1->[0]->[2]->{payload} eq 'rule1', 	"check that rule1 got correct name");

ok($rule2->[0]->[2]->{payload} eq 'rule2', 	"check that rule2 got correct name");





}

__DATA__

This is trying to show how the code would look for creating rules.

A rule is just a package array. But to reduce the amount of typing,
we declare it inside the "rule" subroutine imported from Parse::Gnaw.
This allows us to pass in literals like 'a', and translate them into
something more machine friendly, like [ 'lit', 'a', {info}]




$VAR1 = [
          [
            'rule',
            'rule1',
            {
              'methodname' => 'rule',
              'filename' => 't/gnaw_rule.t',
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
              'filename' => 't/gnaw_rule.t',
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
              'filename' => 't/gnaw_rule.t',
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
              'filename' => 't/gnaw_rule.t',
              'linenum' => 24,
              'payload' => 'rule2',
              'heading' => 'any',
              'quantifier' => '',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'c',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_rule.t',
              'linenum' => 24,
              'payload' => 'c',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'd',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_rule.t',
              'linenum' => 24,
              'payload' => 'd',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'e',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_rule.t',
              'linenum' => 24,
              'payload' => 'e',
              'package' => 'main'
            }
          ]
        ];
$VAR1 = [
          [
            'rule',
            'rule4',
            {
              'methodname' => 'rule',
              'filename' => 't/gnaw_rule.t',
              'linenum' => 34,
              'payload' => 'rule4',
              'quantifier' => '',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'h',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_rule.t',
              'linenum' => 34,
              'payload' => 'hello',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'e',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_rule.t',
              'linenum' => 34,
              'payload' => 'hello',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'l',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_rule.t',
              'linenum' => 34,
              'payload' => 'hello',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'l',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_rule.t',
              'linenum' => 34,
              'payload' => 'hello',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'o',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_rule.t',
              'linenum' => 34,
              'payload' => 'hello',
              'package' => 'main'
            }
          ]
        ];


