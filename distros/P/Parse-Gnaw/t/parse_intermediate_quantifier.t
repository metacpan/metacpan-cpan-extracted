#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;


use Test::More;

plan tests => 1;


use lib 'lib';

use Parse::Gnaw;
use Parse::Gnaw::LinkedList;

no warnings 'once';


rule('rule1', 'a', thrifty('b', {min=>2,max=>-1}), 'c');

print Dumper $rulebook;


my $ab_string=Parse::Gnaw::LinkedList->new('abbbc');

ok($ab_string->parse($rule1), "should match");


__DATA__

$VAR1 = {
          'rule1_rulefragment_1' => [
                                      [
                                        'rule',
                                        'rule1_rulefragment_1',
                                        {
                                          'methodname' => 'rule',
                                          'filename' => 't/parse_intermediate_quantifier.t',
                                          'payload' => 'rule1_rulefragment_1',
                                          'linenum' => 23,
                                          'quantifier' => '',
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'lit',
                                        'c',
                                        {
                                          'methodname' => 'lit',
                                          'filename' => 't/parse_intermediate_quantifier.t',
                                          'payload' => 'c',
                                          'linenum' => 23,
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
                           'filename' => 't/parse_intermediate_quantifier.t',
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
                           'filename' => 't/parse_intermediate_quantifier.t',
                           'linenum' => 23,
                           'payload' => 'a',
                           'package' => 'main'
                         }
                       ],
                       [
                         'call',
                         'thrifty_1',
                         {
                           'min' => 2,
                           'max' => -1,
                           'then_call' => 'rule1_rulefragment_1',
                           'package' => 'main',
                           'methodname' => 'rule',
                           'filename' => 't/parse_intermediate_quantifier.t',
                           'payload' => 'thrifty_1',
                           'linenum' => 23,
                           'quantifier' => 'thrifty'
                         }
                       ]
                     ],
          'thrifty_1' => [
                           [
                             'rule',
                             'thrifty_1',
                             {
                               'min' => 2,
                               'max' => -1,
                               'package' => 'main',
                               'methodname' => 'rule',
                               'filename' => 't/parse_intermediate_quantifier.t',
                               'linenum' => 23,
                               'payload' => 'thrifty_1',
                               'quantifier' => 'thrifty'
                             }
                           ],
                           [
                             'lit',
                             'b',
                             {
                               'methodname' => 'lit',
                               'filename' => 't/parse_intermediate_quantifier.t',
                               'linenum' => 23,
                               'payload' => 'b',
                               'package' => 'main'
                             }
                           ]
                         ]
        };

