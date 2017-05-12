#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';

use Data::Dumper;


use Test::More;

plan tests => 2;


use lib 'lib';

use Parse::Gnaw;
use Parse::Gnaw::LinkedList;

rule('subrule', 'b', 'c');

rule('firstrule', 'a', call('subrule'), 'd');


print Dumper $rulebook;


my   $match_string=Parse::Gnaw::LinkedList->new('abcdefg');
my $nomatch_string=Parse::Gnaw::LinkedList->new('abcefg');


      ok($match_string->parse($firstrule),  "multirule match");
ok(not($nomatch_string->parse($firstrule)), "multirule does not match");

__DATA__

$VAR1 = {
          'firstrule_rulefragment_1' => [
                                          [
                                            'rule',
                                            'firstrule_rulefragment_1',
                                            {
                                              'methodname' => 'rule',
                                              'filename' => 't/parse_intermediate_multirule.t',
                                              'payload' => 'firstrule_rulefragment_1',
                                              'linenum' => 23,
                                              'quantifier' => '',
                                              'package' => 'main'
                                            }
                                          ],
                                          [
                                            'lit',
                                            'd',
                                            {
                                              'methodname' => 'lit',
                                              'filename' => 't/parse_intermediate_multirule.t',
                                              'payload' => 'd',
                                              'linenum' => 23,
                                              'package' => 'main'
                                            }
                                          ]
                                        ],
          'subrule' => [
                         [
                           'rule',
                           'subrule',
                           {
                             'methodname' => 'rule',
                             'filename' => 't/parse_intermediate_multirule.t',
                             'linenum' => 21,
                             'payload' => 'subrule',
                             'quantifier' => '',
                             'package' => 'main'
                           }
                         ],
                         [
                           'lit',
                           'b',
                           {
                             'methodname' => 'lit',
                             'filename' => 't/parse_intermediate_multirule.t',
                             'linenum' => 21,
                             'payload' => 'b',
                             'package' => 'main'
                           }
                         ],
                         [
                           'lit',
                           'c',
                           {
                             'methodname' => 'lit',
                             'filename' => 't/parse_intermediate_multirule.t',
                             'linenum' => 21,
                             'payload' => 'c',
                             'package' => 'main'
                           }
                         ]
                       ],
          'firstrule' => [
                           [
                             'rule',
                             'firstrule',
                             {
                               'methodname' => 'rule',
                               'filename' => 't/parse_intermediate_multirule.t',
                               'linenum' => 23,
                               'payload' => 'firstrule',
                               'quantifier' => '',
                               'package' => 'main'
                             }
                           ],
                           [
                             'lit',
                             'a',
                             {
                               'methodname' => 'lit',
                               'filename' => 't/parse_intermediate_multirule.t',
                               'linenum' => 23,
                               'payload' => 'a',
                               'package' => 'main'
                             }
                           ],
                           [
                             'call',
                             'subrule',
                             {
                               'methodname' => 'call',
                               'filename' => 't/parse_intermediate_multirule.t',
                               'payload' => 'subrule',
                               'linenum' => 23,
                               'then_call' => 'firstrule_rulefragment_1',
                               'package' => 'main'
                             }
                           ]
                         ]
        };


