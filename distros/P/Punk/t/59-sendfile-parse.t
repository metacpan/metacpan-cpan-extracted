#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk ();

# The Range grammar (psf_parse_range), the ETag shape and the
# Content-Disposition builder, through the Punk::SendFile test shims.
# Result codes: 0 none, 1 ok, 2 unsatisfiable (416), 3 ignore (full 200).

my @table = (
    # header               size   want      off  len   why
    [ 'bytes=0-9',          100, [ 1,   0,  10 ], 'first ten'            ],
    [ 'bytes=10-19',        100, [ 1,  10,  10 ], 'middle'               ],
    [ 'bytes=0-0',          100, [ 1,   0,   1 ], 'a single byte'        ],
    [ 'bytes=99-99',        100, [ 1,  99,   1 ], 'the last byte'        ],
    [ 'bytes=90-',          100, [ 1,  90,  10 ], 'open ended'           ],
    [ 'bytes=0-',           100, [ 1,   0, 100 ], 'open ended from 0'    ],
    [ 'bytes=0-999',        100, [ 1,   0, 100 ], 'last clamped to size' ],
    [ 'bytes=-10',          100, [ 1,  90,  10 ], 'suffix'               ],
    [ 'bytes=-100',         100, [ 1,   0, 100 ], 'suffix = whole file'  ],
    [ 'bytes=-999',         100, [ 1,   0, 100 ], 'suffix clamped'       ],
    [ ' bytes=0-9',         100, [ 1,   0,  10 ], 'leading OWS'          ],
    [ 'BYTES=0-9',          100, [ 1,   0,  10 ], 'unit is case-blind'   ],
    [ 'bytes=0-9 ',         100, [ 1,   0,  10 ], 'trailing OWS'         ],

    [ 'bytes=100-',         100, [ 2 ], 'first at size: unsatisfiable'   ],
    [ 'bytes=200-300',      100, [ 2 ], 'past the end'                   ],
    [ 'bytes=-0',           100, [ 2 ], 'suffix of zero'                 ],
    [ 'bytes=0-',             0, [ 2 ], 'any range on an empty file'     ],
    [ 'bytes=-5',             0, [ 2 ], 'suffix on an empty file'        ],

    [ 'bytes=0-1,5-9',      100, [ 3 ], 'multi-range: ignored'           ],
    [ 'bytes=-5,0-1',       100, [ 3 ], 'multi-range suffix first'       ],
    [ 'bytes=9-0',          100, [ 3 ], 'last < first: invalid, ignored' ],
    [ 'bytes=',             100, [ 3 ], 'no spec'                        ],
    [ 'bytes=-',            100, [ 3 ], 'no digits'                      ],
    [ 'bytes=a-b',          100, [ 3 ], 'not digits'                     ],
    [ 'bytes=0-9zzz',       100, [ 3 ], 'trailing junk'                  ],
    [ 'items=0-9',          100, [ 3 ], 'another unit'                   ],
    [ 'bytes 0-9',          100, [ 3 ], 'no ='                           ],
    [ '',                   100, [ 3 ], 'empty header'                   ],
    [ 'bytes=99999999999999999999-', 100, [ 3 ], 'overflow'              ],
);

for my $case (@table) {
    my ($header, $size, $want, $why) = @$case;
    my @got = Punk::SendFile::_parse_range($header, $size);
    splice @got, scalar @$want;             # off/len only meaningful on ok
    is_deeply \@got, $want, "$why ($header)";
}

# the validator shape
like Punk::SendFile::_etag(0x5f5e100, 1234), qr/^"5f5e100-4d2"$/,
    'ETag is quoted hex mtime dash hex size';

# Content-Disposition
is Punk::SendFile::_disposition('plain.pdf', 0),
    'attachment; filename="plain.pdf"', 'plain ascii attachment';
is Punk::SendFile::_disposition('plain.pdf', 1),
    'inline; filename="plain.pdf"', 'inline token';
is Punk::SendFile::_disposition(undef, 0),
    'attachment', 'no filename, bare token';
is Punk::SendFile::_disposition('we "quote" it.txt', 0),
    'attachment; filename="we \"quote\" it.txt"', 'quotes escaped';
is Punk::SendFile::_disposition("b\x{fc}cher.pdf", 0),
    q{attachment; filename="b__cher.pdf"; filename*=UTF-8''b%C3%BCcher.pdf},
    'non-ascii gets a degraded fallback plus filename*';

done_testing;
