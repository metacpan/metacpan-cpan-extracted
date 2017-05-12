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

#our $rulebook;

our $rule2; $rule2=[];

rule('rule1', 
	'hi', 
	thrifty('c', {min=>3,max=>5}),	# at least 3 and no more than 5 letter 'c' characters.
	'b');



{

print Dumper $main::rulebook;

#print Dumper $main::thrifty_1;

my $thriftyrule = $main::rulebook->{thrifty_1};

my $thriftysubrule=$thriftyrule->[0];

my $thriftyhref=$thriftysubrule->[2];

print Dumper $thriftyhref;

ok($thriftyhref->{quantifier} eq 'thrifty', "checking hashref->{quantifier} is the word thrifty.");
ok($thriftyhref->{min} eq '3', "checking hashref->{min} is ");
ok($thriftyhref->{max} eq '5', "checking hashref->{max} is ");


}

__DATA__

$VAR1 = {
          'rule1_rulefragment_1' => [
                                      [
                                        'rule',
                                        'rule1_rulefragment_1',
                                        {
                                          'methodname' => 'rule',
                                          'filename' => 't/gnaw_rule_thrifty.t',
                                          'payload' => 'rule1_rulefragment_1',
                                          'linenum' => 21,
                                          'quantifier' => '',
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'lit',
                                        'b',
                                        {
                                          'methodname' => 'lit',
                                          'filename' => 't/gnaw_rule_thrifty.t',
                                          'payload' => 'b',
                                          'linenum' => 21,
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
                           'filename' => 't/gnaw_rule_thrifty.t',
                           'linenum' => 21,
                           'payload' => 'rule1',
                           'quantifier' => '',
                           'package' => 'main'
                         }
                       ],
                       [
                         'lit',
                         'h',
                         {
                           'methodname' => 'lit',
                           'filename' => 't/gnaw_rule_thrifty.t',
                           'linenum' => 21,
                           'payload' => 'hi',
                           'package' => 'main'
                         }
                       ],
                       [
                         'lit',
                         'i',
                         {
                           'methodname' => 'lit',
                           'filename' => 't/gnaw_rule_thrifty.t',
                           'linenum' => 21,
                           'payload' => 'hi',
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
                           'filename' => 't/gnaw_rule_thrifty.t',
                           'payload' => 'thrifty_1',
                           'linenum' => 21,
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
                               'filename' => 't/gnaw_rule_thrifty.t',
                               'linenum' => 21,
                               'payload' => 'thrifty_1',
                               'quantifier' => 'thrifty'
                             }
                           ],
                           [
                             'lit',
                             'c',
                             {
                               'methodname' => 'lit',
                               'filename' => 't/gnaw_rule_thrifty.t',
                               'linenum' => 21,
                               'payload' => 'c',
                               'package' => 'main'
                             }
                           ]
                         ]
        };
$VAR1 = {
          'min' => 3,
          'max' => 5,
          'package' => 'main',
          'methodname' => 'rule',
          'filename' => 't/gnaw_rule_thrifty.t',
          'linenum' => 21,
          'payload' => 'thrifty_1',
          'quantifier' => 'thrifty'
        };


