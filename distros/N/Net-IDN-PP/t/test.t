#!/usr/bin/env perl
use open qw(:std :encoding(UTF-8));
use Test::More;
use vars qw(@ENCODE_TESTS @DECODE_TESTS);
use common::sense;

my $class = q{Net::IDN::PP};

require_ok($class);

@ENCODE_TESTS = (
    [ q{café}                       => q{xn--caf-dma}               ],
    [ q{café.com}                   => q{xn--caf-dma.com}           ],
    [ q{com.café}                   => q{com.xn--caf-dma}           ],
    [ q{CAFÉ}                       => q{xn--caf-dma}               ],
    [ q{müller}                     => q{xn--mller-kva}             ],
    [ q{jürg.xn--mller-kva}         => q{xn--jrg-hoa.xn--mller-kva} ],
    [ qq{\x{1F985}}                 => q{xn--4s9h}                  ],
    [ q{ä ö ü ß}                    => q{xn--   -7kav3ivb}          ],
    [ q{}                           => q{}                          ],
);

@DECODE_TESTS = (
    [ q{xn--caf-dma}                => q{café}                      ],
    [ q{xn--caf-dma.com}            => q{café.com}                  ],
    [ q{com.xn--caf-dma}            => q{com.café}                  ],
    [ q{XN--CAF-DMA}                => q{café}                      ],
    [ q{xn--mller-kva}              => q{müller}                    ],
    [ q{xn--jrg-hoa.xn--mller-kva}  => q{jürg.müller}               ],
    [ q{xn--4s9h}                   => qq{\x{1F985}}                ],
    [ q{xn--   -7kav3ivb}           => q{ä ö ü ß}                   ],
    [ q{}                           => q{}                          ],
);

foreach my $test (@ENCODE_TESTS) {
    is($class->encode($test->[0]), $test->[1], sprintf(q{check that '%s' encodes to '%s'}, $test->[0], $test->[1]));
}

foreach my $test (@DECODE_TESTS) {
   is($class->decode($test->[0]), $test->[1], sprintf(q{check that '%s' decodes to '%s'}, $test->[0], $test->[1]));
}

done_testing;
