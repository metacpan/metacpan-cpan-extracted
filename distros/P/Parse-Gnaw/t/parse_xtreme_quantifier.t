#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';

use Data::Dumper;


use Test::More;

plan tests => 1;


use lib 'lib';

use Parse::Gnaw;
use Parse::Gnaw::LinkedList;





rule('rule3', 'g', thrifty('h','+'), 'i');

rule('rule2', 'd', thrifty('e','+'), call('rule3'), 'f');

rule('rule1', 'a', call('rule2'), 'b', call('rule3'), 'c' );

print Dumper $rulebook;


my $my_ll_string=Parse::Gnaw::LinkedList->new('adeeeghhhifbghhhic');

$my_ll_string->display();



ok($my_ll_string->parse('rule1'), "should match");

__DATA__

$VAR1 = {
          'rule2_rulefragment_2' => [
                                      [
                                        'rule',
                                        'rule2_rulefragment_2',
                                        {
                                          'methodname' => 'rule',
                                          'filename' => 't/parse_xtreme_quantifier.t',
                                          'payload' => 'rule2_rulefragment_2',
                                          'linenum' => 26,
                                          'quantifier' => '',
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'lit',
                                        'f',
                                        {
                                          'methodname' => 'lit',
                                          'filename' => 't/parse_xtreme_quantifier.t',
                                          'linenum' => 26,
                                          'payload' => 'f',
                                          'package' => 'main'
                                        }
                                      ]
                                    ],
          'rule2_rulefragment_1' => [
                                      [
                                        'rule',
                                        'rule2_rulefragment_1',
                                        {
                                          'methodname' => 'rule',
                                          'filename' => 't/parse_xtreme_quantifier.t',
                                          'payload' => 'rule2_rulefragment_1',
                                          'linenum' => 26,
                                          'quantifier' => '',
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'call',
                                        'rule3',
                                        {
                                          'methodname' => 'call',
                                          'filename' => 't/parse_xtreme_quantifier.t',
                                          'linenum' => 26,
                                          'payload' => 'rule3',
                                          'then_call' => 'rule2_rulefragment_2',
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
                           'filename' => 't/parse_xtreme_quantifier.t',
                           'linenum' => 28,
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
                           'filename' => 't/parse_xtreme_quantifier.t',
                           'linenum' => 28,
                           'payload' => 'a',
                           'package' => 'main'
                         }
                       ],
                       [
                         'call',
                         'rule2',
                         {
                           'methodname' => 'call',
                           'filename' => 't/parse_xtreme_quantifier.t',
                           'payload' => 'rule2',
                           'linenum' => 28,
                           'then_call' => 'rule1_rulefragment_1',
                           'package' => 'main'
                         }
                       ]
                     ],
          'rule2' => [
                       [
                         'rule',
                         'rule2',
                         {
                           'methodname' => 'rule',
                           'filename' => 't/parse_xtreme_quantifier.t',
                           'linenum' => 26,
                           'payload' => 'rule2',
                           'quantifier' => '',
                           'package' => 'main'
                         }
                       ],
                       [
                         'lit',
                         'd',
                         {
                           'methodname' => 'lit',
                           'filename' => 't/parse_xtreme_quantifier.t',
                           'linenum' => 26,
                           'payload' => 'd',
                           'package' => 'main'
                         }
                       ],
                       [
                         'call',
                         'thrifty_2',
                         {
                           'min' => 1,
                           'max' => -999,
                           'then_call' => 'rule2_rulefragment_1',
                           'package' => 'main',
                           'methodname' => 'rule',
                           'filename' => 't/parse_xtreme_quantifier.t',
                           'payload' => 'thrifty_2',
                           'linenum' => 26,
                           'quantifier' => 'thrifty'
                         }
                       ]
                     ],
          'rule3_rulefragment_1' => [
                                      [
                                        'rule',
                                        'rule3_rulefragment_1',
                                        {
                                          'methodname' => 'rule',
                                          'filename' => 't/parse_xtreme_quantifier.t',
                                          'payload' => 'rule3_rulefragment_1',
                                          'linenum' => 24,
                                          'quantifier' => '',
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'lit',
                                        'i',
                                        {
                                          'methodname' => 'lit',
                                          'filename' => 't/parse_xtreme_quantifier.t',
                                          'payload' => 'i',
                                          'linenum' => 24,
                                          'package' => 'main'
                                        }
                                      ]
                                    ],
          'rule3' => [
                       [
                         'rule',
                         'rule3',
                         {
                           'methodname' => 'rule',
                           'filename' => 't/parse_xtreme_quantifier.t',
                           'linenum' => 24,
                           'payload' => 'rule3',
                           'quantifier' => '',
                           'package' => 'main'
                         }
                       ],
                       [
                         'lit',
                         'g',
                         {
                           'methodname' => 'lit',
                           'filename' => 't/parse_xtreme_quantifier.t',
                           'linenum' => 24,
                           'payload' => 'g',
                           'package' => 'main'
                         }
                       ],
                       [
                         'call',
                         'thrifty_1',
                         {
                           'min' => 1,
                           'max' => -999,
                           'then_call' => 'rule3_rulefragment_1',
                           'package' => 'main',
                           'methodname' => 'rule',
                           'filename' => 't/parse_xtreme_quantifier.t',
                           'payload' => 'thrifty_1',
                           'linenum' => 24,
                           'quantifier' => 'thrifty'
                         }
                       ]
                     ],
          'thrifty_2' => [
                           [
                             'rule',
                             'thrifty_2',
                             {
                               'min' => 1,
                               'max' => -999,
                               'package' => 'main',
                               'methodname' => 'rule',
                               'filename' => 't/parse_xtreme_quantifier.t',
                               'linenum' => 26,
                               'payload' => 'thrifty_2',
                               'quantifier' => 'thrifty'
                             }
                           ],
                           [
                             'lit',
                             'e',
                             {
                               'methodname' => 'lit',
                               'filename' => 't/parse_xtreme_quantifier.t',
                               'linenum' => 26,
                               'payload' => 'e',
                               'package' => 'main'
                             }
                           ]
                         ],
          'thrifty_1' => [
                           [
                             'rule',
                             'thrifty_1',
                             {
                               'min' => 1,
                               'max' => -999,
                               'package' => 'main',
                               'methodname' => 'rule',
                               'filename' => 't/parse_xtreme_quantifier.t',
                               'linenum' => 24,
                               'payload' => 'thrifty_1',
                               'quantifier' => 'thrifty'
                             }
                           ],
                           [
                             'lit',
                             'h',
                             {
                               'methodname' => 'lit',
                               'filename' => 't/parse_xtreme_quantifier.t',
                               'linenum' => 24,
                               'payload' => 'h',
                               'package' => 'main'
                             }
                           ]
                         ],
          'rule1_rulefragment_1' => [
                                      [
                                        'rule',
                                        'rule1_rulefragment_1',
                                        {
                                          'methodname' => 'rule',
                                          'filename' => 't/parse_xtreme_quantifier.t',
                                          'payload' => 'rule1_rulefragment_1',
                                          'linenum' => 28,
                                          'quantifier' => '',
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'lit',
                                        'b',
                                        {
                                          'methodname' => 'lit',
                                          'filename' => 't/parse_xtreme_quantifier.t',
                                          'payload' => 'b',
                                          'linenum' => 28,
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'call',
                                        'rule3',
                                        {
                                          'methodname' => 'call',
                                          'filename' => 't/parse_xtreme_quantifier.t',
                                          'linenum' => 28,
                                          'payload' => 'rule3',
                                          'then_call' => 'rule1_rulefragment_2',
                                          'package' => 'main'
                                        }
                                      ]
                                    ],
          'rule1_rulefragment_2' => [
                                      [
                                        'rule',
                                        'rule1_rulefragment_2',
                                        {
                                          'methodname' => 'rule',
                                          'filename' => 't/parse_xtreme_quantifier.t',
                                          'payload' => 'rule1_rulefragment_2',
                                          'linenum' => 28,
                                          'quantifier' => '',
                                          'package' => 'main'
                                        }
                                      ],
                                      [
                                        'lit',
                                        'c',
                                        {
                                          'methodname' => 'lit',
                                          'filename' => 't/parse_xtreme_quantifier.t',
                                          'linenum' => 28,
                                          'payload' => 'c',
                                          'package' => 'main'
                                        }
                                      ]
                                    ]
        };
Dumping LinkedList object
LETPKG => Parse::Gnaw::Blocks::Letter # package name of letter objects
CONNMIN1 => 0 # max number of connections, minus 1
HEADING_DIRECTION_INDEX => 0
HEADING_PREVNEXT_INDEX  => 0
FIRSTSTART => 

	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a82564)
	payload: 'FIRSTSTART'
	from: unknown
	connections:
		 [ ........... , ........... ]

LASTSTART => 

	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a823e8)
	payload: 'LASTSTART'
	from: unknown
	connections:
		 [ ........... , ........... ]

CURRPTR => 

	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a82564)
	payload: 'FIRSTSTART'
	from: unknown
	connections:
		 [ ........... , ........... ]


letters, by order of next_start_position()

	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a79768)
	payload: 'a'
	from: file t/parse_xtreme_quantifier.t, line 33, column 0
	connections:
		 [ ........... , (0x9a7edf4) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a7edf4)
	payload: 'd'
	from: file t/parse_xtreme_quantifier.t, line 33, column 1
	connections:
		 [ (0x9a79768) , (0x9a84ecc) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a84ecc)
	payload: 'e'
	from: file t/parse_xtreme_quantifier.t, line 33, column 2
	connections:
		 [ (0x9a7edf4) , (0x9a7f074) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a7f074)
	payload: 'e'
	from: file t/parse_xtreme_quantifier.t, line 33, column 3
	connections:
		 [ (0x9a84ecc) , (0x9a7f114) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a7f114)
	payload: 'e'
	from: file t/parse_xtreme_quantifier.t, line 33, column 4
	connections:
		 [ (0x9a7f074) , (0x9a871c0) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a871c0)
	payload: 'g'
	from: file t/parse_xtreme_quantifier.t, line 33, column 5
	connections:
		 [ (0x9a7f114) , (0x9a7c24c) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a7c24c)
	payload: 'h'
	from: file t/parse_xtreme_quantifier.t, line 33, column 6
	connections:
		 [ (0x9a871c0) , (0x9a84db4) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a84db4)
	payload: 'h'
	from: file t/parse_xtreme_quantifier.t, line 33, column 7
	connections:
		 [ (0x9a7c24c) , (0x9a82a8c) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a82a8c)
	payload: 'h'
	from: file t/parse_xtreme_quantifier.t, line 33, column 8
	connections:
		 [ (0x9a84db4) , (0x9a866f8) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a866f8)
	payload: 'i'
	from: file t/parse_xtreme_quantifier.t, line 33, column 9
	connections:
		 [ (0x9a82a8c) , (0x9a854a8) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a854a8)
	payload: 'f'
	from: file t/parse_xtreme_quantifier.t, line 33, column 10
	connections:
		 [ (0x9a866f8) , (0x9a78e6c) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a78e6c)
	payload: 'b'
	from: file t/parse_xtreme_quantifier.t, line 33, column 11
	connections:
		 [ (0x9a854a8) , (0x9a7959c) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a7959c)
	payload: 'g'
	from: file t/parse_xtreme_quantifier.t, line 33, column 12
	connections:
		 [ (0x9a78e6c) , (0x9a8573c) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a8573c)
	payload: 'h'
	from: file t/parse_xtreme_quantifier.t, line 33, column 13
	connections:
		 [ (0x9a7959c) , (0x9a78f5c) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a78f5c)
	payload: 'h'
	from: file t/parse_xtreme_quantifier.t, line 33, column 14
	connections:
		 [ (0x9a8573c) , (0x9a82258) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a82258)
	payload: 'h'
	from: file t/parse_xtreme_quantifier.t, line 33, column 15
	connections:
		 [ (0x9a78f5c) , (0x9a82bcc) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a82bcc)
	payload: 'i'
	from: file t/parse_xtreme_quantifier.t, line 33, column 16
	connections:
		 [ (0x9a82258) , (0x9a88f14) ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a88f14)
	payload: 'c'
	from: file t/parse_xtreme_quantifier.t, line 33, column 17
	connections:
		 [ (0x9a82bcc) , ........... ]


	letterobject: Parse::Gnaw::Blocks::Letter=ARRAY(0x9a823e8)
	payload: 'LASTSTART'
	from: unknown
	connections:
		 [ ........... , ........... ]













