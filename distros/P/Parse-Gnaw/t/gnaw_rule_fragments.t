#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;
use lib 'lib';

use Test::More;

plan tests => 3;

use Parse::Gnaw;

our $rule2; $rule2=[];

rule('rule1', 
	'a', 
	thrifty('c',{min=>3,max=>5}),
	'b');



{


# print out contents for debug purposes.
print Dumper $rulebook;


# all we're verifying is that "rule" creates arrays of the correct name and size.
# note that first index is the name of the rule.
ok(scalar(@$rule1)==3, "check rule1 is size 3");

ok(scalar(@$rule1_rulefragment_1)==2, "check rule1_rulefragment_1 is size 2");

ok(scalar(@$thrifty_1)==2, "check thrifty_1 is size 2");




}

__DATA__

$VAR1 = {
          'rule1_rulefragment_1' => [
                                      [
                                        'rule',
                                        'rule1_rulefragment_1',
                                        {
                                          'methodname' => 'rule',
                                          'filename' => 't/gnaw_rule_fragments.t',
                                          'payload' => 'rule1_rulefragment_1',
                                          'linenum' => 18,
                                          'quantifier' => '',
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'lit',
                                        'b',
                                        {
                                          'methodname' => 'lit',
                                          'filename' => 't/gnaw_rule_fragments.t',
                                          'payload' => 'b',
                                          'linenum' => 18,
                                          'package' => 'main'
                                        }
                                      ]
                                    ],
          'rule1' => [
                       [
                         'rule',
                         'rule1',
                         {
                           'methodname' => 'rule',
                           'filename' => 't/gnaw_rule_fragments.t',
                           'linenum' => 18,
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
                           'filename' => 't/gnaw_rule_fragments.t',
                           'linenum' => 18,
                           'payload' => 'a',
                           'package' => 'main'
                         }
                       ],
                       [
                         'call',
                         'thrifty_1',
                         {
                           'min' => 3,
                           'max' => 5,
                           'then_call' => 'rule1_rulefragment_1',
                           'package' => 'main',
                           'methodname' => 'rule',
                           'filename' => 't/gnaw_rule_fragments.t',
                           'payload' => 'thrifty_1',
                           'linenum' => 18,
                           'quantifier' => 'thrifty'
                         }
                       ]
                     ],
          'thrifty_1' => [
                           [
                             'rule',
                             'thrifty_1',
                             {
                               'min' => 3,
                               'max' => 5,
                               'package' => 'main',
                               'methodname' => 'rule',
                               'filename' => 't/gnaw_rule_fragments.t',
                               'linenum' => 18,
                               'payload' => 'thrifty_1',
                               'quantifier' => 'thrifty'
                             }
                           ],
                           [
                             'lit',
                             'c',
                             {
                               'methodname' => 'lit',
                               'filename' => 't/gnaw_rule_fragments.t',
                               'linenum' => 18,
                               'payload' => 'c',
                               'package' => 'main'
                             }
                           ]
                         ]
        };


