use strict;
use warnings;
use Test::More 0.88;

use Moose::Util::TypeConstraints;
use MooseX::Types::Structured qw(Dict Tuple);
use MooseX::Types::Moose qw(Int);

my $deeper_tc = subtype
  as Dict[
    a => Tuple[
        Dict[
            a1a => Tuple[Int],
            a1b => Tuple[Int],
        ],
        Dict[
            a2a => Tuple[Int],
            a2b => Tuple[Int],
        ],
    ],
    b => Tuple[
        Dict[
            b1a => Tuple[Int],
            b1b => Tuple[Int],
        ],
        Dict[
            b2a => Tuple[Int],
            b2b => Tuple[Int],
        ],
    ],
  ];

my $struc_to_validate = {
    a=>[
        {
            a1a=>[1],
            a1b=>[2]
        },
        {
            a2a=>['AA'],
            a2b=>[4]
        }
    ],
    b=>[
        {
            b1a=>[5],
            b1b=>['BB']
        },
        {
            b2a=>[7],
            b2b=>[8]
        }
    ]
};

ok my $message = $deeper_tc->validate($struc_to_validate),
'got error message of some sort';

done_testing();

## warn $message;
