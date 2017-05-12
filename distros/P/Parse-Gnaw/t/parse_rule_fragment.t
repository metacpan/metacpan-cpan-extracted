#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;


use Test::More;

plan tests => 14;


use lib 'lib';

use Parse::Gnaw;
use Parse::Gnaw::LinkedList;

rule('rule3', 'f', thrifty('g','+'), 'h');

rule('rule2', 'c', thrifty('d','+'), call('rule3'), 'e');

rule('rule1', 'a', call('rule2'), 'b', call('rule3'), 'g' );

#print Dumper $rulebook;


ok(exists($rulebook->{rule1}), "checking the rule1 exists in rulebook");
ok(exists($rulebook->{rule1_rulefragment_1}), "checking the rule1_rulefragment_1 exists in rulebook");
ok(exists($rulebook->{rule1_rulefragment_2}), "checking the rule1_rulefragment_2 exists in rulebook");


ok(scalar(@{$rulebook->{rule1}})==3, 			"checking rule1 has 3 elements in it");
ok(scalar(@{$rulebook->{rule1_rulefragment_1}})==3, 	"checking rule1_rulefragment_1 has 3 elements in it");
ok(scalar(@{$rulebook->{rule1_rulefragment_2}})==2, 	"checking rule1_rulefragment_2 has 2 elements in it");


ok($rulebook->{rule1}->[2]->[0] 		eq 'call', 	"checking last element rule1 is call");
ok($rulebook->{rule1_rulefragment_1}->[2]->[0] 	eq 'call', 	"checking last element rule1_rulefragment_1 is call");
ok($rulebook->{rule1_rulefragment_2}->[1]->[0] 	eq 'lit', 	"checking last element rule1_rulefragment_2 is call");

ok($rulebook->{rule1}->[2]->[1] 		eq 'rule2', 	"checking last element rule1 is rule2");
ok($rulebook->{rule1_rulefragment_1}->[2]->[1] 	eq 'rule3', 	"checking last element rule1_rulefragment_1 is rule3");
ok($rulebook->{rule1_rulefragment_2}->[1]->[1] 	eq 'g', 	"checking last element rule1_rulefragment_2 is g");

ok($rulebook->{rule1}->[2]->[2]->{then_call} 			eq 'rule1_rulefragment_1', 	"checking last element rule1 is rule2");
ok($rulebook->{rule1_rulefragment_1}->[2]->[2]->{then_call} 	eq 'rule1_rulefragment_2', 	"checking last element rule1 is rule2");

__DATA__

We're verifying that the rules get fragmented correctly.

Here is what the rulebook looks like from Dumper:

$VAR1 = {
          'rule1' => [
                       [
                         'rule',
                         {
                           'methodname' => 'rule',
                           'filename' => 't/parse_rule_fragment.t',
                           'linenum' => 23,
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
                           'filename' => 't/parse_rule_fragment.t',
                           'linenum' => 23,
                           'payload' => 'a',
                           'package' => 'main'
                         }
                       ],
                       [
                         'call',
                         'rule2',
                         {
                           'methodname' => 'call',
                           'filename' => 't/parse_rule_fragment.t',
                           'payload' => 'rule2',
                           'linenum' => 23,
                           'then_call' => 'rule1_rulefragment_1',
                           'package' => 'main'
                         }
                       ]
                     ],
          'rule1_rulefragment_1' => [
                                      [
                                        'rule',
                                        {
                                          'methodname' => 'rule',
                                          'filename' => 't/parse_rule_fragment.t',
                                          'payload' => 'rule1_rulefragment_1',
                                          'linenum' => 23,
                                          'quantifier' => '',
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'lit',
                                        'b',
                                        {
                                          'methodname' => 'lit',
                                          'filename' => 't/parse_rule_fragment.t',
                                          'payload' => 'b',
                                          'linenum' => 23,
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'call',
                                        'rule3',
                                        {
                                          'methodname' => 'call',
                                          'filename' => 't/parse_rule_fragment.t',
                                          'linenum' => 23,
                                          'payload' => 'rule3',
                                          'then_call' => 'rule1_rulefragment_2',
                                          'package' => 'main'
                                        }
                                      ]
                                    ],
          'rule1_rulefragment_2' => [
                                      [
                                        'rule',
                                        {
                                          'methodname' => 'rule',
                                          'filename' => 't/parse_rule_fragment.t',
                                          'payload' => 'rule1_rulefragment_2',
                                          'linenum' => 23,
                                          'quantifier' => '',
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'lit',
                                        'g',
                                        {
                                          'methodname' => 'lit',
                                          'filename' => 't/parse_rule_fragment.t',
                                          'linenum' => 23,
                                          'payload' => 'g',
                                          'package' => 'main'
                                        }
                                      ]
                                    ]
          'rule2' => [
                       [
                         'rule',
                         {
                           'methodname' => 'rule',
                           'filename' => 't/parse_rule_fragment.t',
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
                           'filename' => 't/parse_rule_fragment.t',
                           'linenum' => 24,
                           'payload' => 'c',
                           'package' => 'main'
                         }
                       ],
                       [
                         'call',
                         'thrifty_1',
                         {
                           'min' => 1,
                           'max' => undef,
                           'then_call' => 'rule2_rulefragment_1',
                           'package' => 'main',
                           'methodname' => 'rule',
                           'filename' => 't/parse_rule_fragment.t',
                           'payload' => 'thrifty_1',
                           'linenum' => 24,
                           'quantifier' => 'thrifty'
                         }
                       ]
                     ],
          'rule2_rulefragment_1' => [
                                      [
                                        'rule',
                                        {
                                          'methodname' => 'rule',
                                          'filename' => 't/parse_rule_fragment.t',
                                          'payload' => 'rule2_rulefragment_1',
                                          'linenum' => 24,
                                          'quantifier' => '',
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'call',
                                        'rule3',
                                        {
                                          'methodname' => 'call',
                                          'filename' => 't/parse_rule_fragment.t',
                                          'linenum' => 24,
                                          'payload' => 'rule3',
                                          'then_call' => 'rule2_rulefragment_2',
                                          'package' => 'main'
                                        }
                                      ]
                                    ],
          'rule2_rulefragment_2' => [
                                      [
                                        'rule',
                                        {
                                          'methodname' => 'rule',
                                          'filename' => 't/parse_rule_fragment.t',
                                          'payload' => 'rule2_rulefragment_2',
                                          'linenum' => 24,
                                          'quantifier' => '',
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'lit',
                                        'e',
                                        {
                                          'methodname' => 'lit',
                                          'filename' => 't/parse_rule_fragment.t',
                                          'linenum' => 24,
                                          'payload' => 'e',
                                          'package' => 'main'
                                        }
                                      ]
                                    ],
          'rule3' => [
                       [
                         'rule',
                         {
                           'methodname' => 'rule',
                           'filename' => 't/parse_rule_fragment.t',
                           'linenum' => 25,
                           'payload' => 'rule3',
                           'quantifier' => '',
                           'package' => 'main'
                         }
                       ],
                       [
                         'lit',
                         'f',
                         {
                           'methodname' => 'lit',
                           'filename' => 't/parse_rule_fragment.t',
                           'linenum' => 25,
                           'payload' => 'f',
                           'package' => 'main'
                         }
                       ],
                       [
                         'call',
                         'thrifty_2',
                         {
                           'min' => 1,
                           'max' => undef,
                           'then_call' => 'rule3_rulefragment_1',
                           'package' => 'main',
                           'methodname' => 'rule',
                           'filename' => 't/parse_rule_fragment.t',
                           'payload' => 'thrifty_2',
                           'linenum' => 25,
                           'quantifier' => 'thrifty'
                         }
                       ]
                     ],
          'rule3_rulefragment_1' => [
                                      [
                                        'rule',
                                        {
                                          'methodname' => 'rule',
                                          'filename' => 't/parse_rule_fragment.t',
                                          'payload' => 'rule3_rulefragment_1',
                                          'linenum' => 25,
                                          'quantifier' => '',
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'lit',
                                        'h',
                                        {
                                          'methodname' => 'lit',
                                          'filename' => 't/parse_rule_fragment.t',
                                          'payload' => 'h',
                                          'linenum' => 25,
                                          'package' => 'main'
                                        }
                                      ]
                                    ],
          'thrifty_1' => [
                           [
                             'rule',
                             {
                               'min' => 1,
                               'max' => undef,
                               'package' => 'main',
                               'methodname' => 'rule',
                               'filename' => 't/parse_rule_fragment.t',
                               'linenum' => 24,
                               'payload' => 'thrifty_1',
                               'quantifier' => 'thrifty'
                             }
                           ],
                           [
                             'lit',
                             'd',
                             {
                               'methodname' => 'lit',
                               'filename' => 't/parse_rule_fragment.t',
                               'linenum' => 24,
                               'payload' => 'd',
                               'package' => 'main'
                             }
                           ]
                         ],
          'thrifty_2' => [
                           [
                             'rule',
                             {
                               'min' => 1,
                               'max' => undef,
                               'package' => 'main',
                               'methodname' => 'rule',
                               'filename' => 't/parse_rule_fragment.t',
                               'linenum' => 25,
                               'payload' => 'thrifty_2',
                               'quantifier' => 'thrifty'
                             }
                           ],
                           [
                             'lit',
                             'g',
                             {
                               'methodname' => 'lit',
                               'filename' => 't/parse_rule_fragment.t',
                               'linenum' => 25,
                               'payload' => 'g',
                               'package' => 'main'
                             }
                           ]
                         ],
        };












