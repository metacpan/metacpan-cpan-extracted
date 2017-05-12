#!/usr/bin/perl
#Based upon example found on web

use Test::More tests => 14;
BEGIN { use_ok('Parse::Stallion')};

my $grammar = {
 top => A(qr/^/, 'xml', qr/$/),

 xml => A('plain',M(A('tag','plain'))),

 plain => qr/[^<>&]*/,

 tag => A(qr/\</, {tag1 => qr/\w+/}, M('attributes'),
   O(qr/\s*\/\>/,
    A( qr/\>/, 'xml', qr/\<\//, {tag2=>qr/\w+/}, qr/\>/)
    ),
  E(sub {if ((exists $_[0]->{tag2}) && ($_[0]->{tag2} ne $_[0]->{tag1}))
    {return (undef, 1)}
    return $_[0];
   }),U()
  ),

 attributes => L(qr/\s+\w+\s*\=\s*\"[^"<>]*\"\s*/),

};

my $xml_parser = new Parse::Stallion($grammar);

    my @tests = (
        [1, 'abc'                       ],      # 1
        [1, '<a></a>'                   ],      # 2
        [1, '..<ab>foo</ab>dd'          ],      # 3
        [1, '<a><b>c</b></a>'           ],      # 4
        [1, '<a href="foo"><b>c</b></a>'],      # 5
        [1, '<a empty="" ><b>c</b></a>' ],      # 6
        [1, '<a><b>c</b><c></c></a>'    ],      # 7
        [0, '<'                         ],      # 8
        [0, '<a>b</b>'                  ],      # 9
        [0, '<a>b</a'                   ],      # 10
        [0, '<a>b</a href="">'          ],      # 11
        [1, '<a/>'                      ],      # 12
        [1, '<a />'                     ],      # 13
    );

#    my $count = 1;
    foreach my $t (@tests) {
        my $s = $t->[1];
        my ($M,$r) = $xml_parser->parse_and_evaluate($s);
        my $v = 0;
        if (!($M  xor $t->[0])) {$v = 1};
        is ($v,1, $t->[1]);
#        if (!($M  xor $t->[0])) {
#            print "ok $count - '$s'\n";
#use Data::Dumper;print "M is ".Dumper($M)."\n"; #shows parse tree
#        } else {
#            print "not ok $count - '$s'\n";
#        }
#        $count++;
    }
