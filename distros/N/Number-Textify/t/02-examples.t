#!/usr/bin/env perl

use strict;
use warnings;

# use Test::More;
use Test2::V0;

use Number::Textify ();

# times
my $time_converter_full = Number::Textify
  -> new( [ [ 24 * 60 * 60, 'day' ],
            [ 60 * 60, 'hour' ],
            [ 60, 'minute' ],
            [ 0, 'second' ],
          ],
        );

my $time_converter_full_no_zeroes = Number::Textify
  -> new( [ [ 24 * 60 * 60, 'day' ],
            [ 60 * 60, 'hour' ],
            [ 60, 'minute' ],
            [ 0, 'second' ],
          ],
          skip_zeroes => 1,
        );

my $time_converter_short_rounded = Number::Textify
  -> new( [ [ 24 * 60 * 60, 'day' ],
            [ 60 * 60, 'hour' ],
            [ 60, 'minute' ],
            [ 0, 'second' ],
          ],

          rounding => 1,
          formatter => sub { my $rounded_number = sprintf '%.1f', $_[ 0 ];

                             sprintf '%s %s%s',
                               $rounded_number,
                               $_[ 1 ],
                               $rounded_number == 1 ? '' : 's';
                           },
        );


my $time_converter_digital = Number::Textify
  -> new( [ [ 24 * 60 * 60 ],
            [ 60 * 60 ],
            [ 60 ],
            [ 0 ],
          ],

          joiner => ':',
          formatter => sub { sprintf '%02d', $_[ 0 ] },
        );

my $time_converter_digital_neat = Number::Textify
  -> new( [ [ 24 * 60 * 60, '%dd ' ],
            [ 60 * 60, '%02d:' ],
            [ 60, '%02d:' ],
            [ 0, '%02d' ],
          ],

          joiner => '',
          formatter => sub { my $format = $_[ 1 ] // '%02d';
                             sprintf $format,
                               $_[ 0 ];
                           },
          post_process => sub {
            $_[ 0 ] =~ s/^0+//;
            $_[ 0 ];
          },
        );

for my $case
  ( [ 16,
      '16 seconds',
      '16 seconds',
      '16.0 seconds',
      '16',
      '16',
    ],
    [ ( 1 * 60 + 1 ) * 60 + 1,
      '1 hour 1 minute 1 second',
      '1 hour 1 minute 1 second',
      '1.0 hour',
      '01:01:01',
      '1:01:01',
    ],
    [ ( 2 * 60 + 3 ) * 60 + 14,
      '2 hours 3 minutes 14 seconds',
      '2 hours 3 minutes 14 seconds',
      '2.1 hours',
      '02:03:14',
      '2:03:14',
    ],
    [ ( 2 * 60 + 0 ) * 60 + 14,
      '2 hours 0 minutes 14 seconds',
      '2 hours 14 seconds',
      '2.0 hours',
      '02:00:14',
      '2:00:14',
    ],
    [ ( 2 * 60 + 1 ) * 60 + 14,
      '2 hours 1 minute 14 seconds',
      '2 hours 1 minute 14 seconds',
      '2.0 hours',
      '02:01:14',
      '2:01:14',
    ],
    [ ( ( ( 3 * 24 ) + 0 ) * 60 + 24 ) * 60 + 48,
      '3 days 0 hours 24 minutes 48 seconds',
      '3 days 24 minutes 48 seconds',
      '3.0 days',
      '03:00:24:48',
      '3d 00:24:48',
    ],
    [ ( ( ( 5 * 24 ) + 13 ) * 60 + 0 ) * 60 + 24,
      '5 days 13 hours 0 minutes 24 seconds',
      '5 days 13 hours 24 seconds',
      '5.5 days',
      '05:13:00:24',
      '5d 13:00:24',
    ],
    [ ( ( ( 54 * 24 ) + 13 ) * 60 + 0 ) * 60 + 24,
      '54 days 13 hours 0 minutes 24 seconds',
      '54 days 13 hours 24 seconds',
      '54.5 days',
      '54:13:00:24',
      '54d 13:00:24',
    ],
    [ 10_000_000,
      '115 days 17 hours 46 minutes 40 seconds',
      '115 days 17 hours 46 minutes 40 seconds',
      '115.7 days',
      '115:17:46:40',
      '115d 17:46:40',
    ],
  ) {
  is $time_converter_full -> textify( $case -> [ 0 ] ), $case -> [ 1 ],
    sprintf 'presenting %s by %s',
    $case -> [ 1 ],
    ref $time_converter_full,
    ;

  is $time_converter_full_no_zeroes -> textify( $case -> [ 0 ] ), $case -> [ 2 ],
    sprintf 'presenting %s by %s',
    $case -> [ 2 ],
    ref $time_converter_full,
    ;

  is $time_converter_short_rounded -> textify( $case -> [ 0 ] ), $case -> [ 3 ],
    sprintf 'presenting %s by %s',
    $case -> [ 3 ],
    ref $time_converter_full,
    ;

  is $time_converter_digital -> textify( $case -> [ 0 ] ), $case -> [ 4 ],
    sprintf 'presenting %s by %s',
    $case -> [ 4 ],
    ref $time_converter_full,
    ;

  is $time_converter_digital_neat -> textify( $case -> [ 0 ] ), $case -> [ 5 ],
    sprintf 'presenting %s by %s',
    $case -> [ 5 ],
    ref $time_converter_full,
    ;
}


# sizes
my $size_converter = Number::Textify
  -> new( [ [ 1_024 * 1_024 * 1_024, '%.2f GiB' ],
            [ 1_024 * 1_024, '%.2f MiB' ],
            [ 1_024, '%.2f KiB' ],
            [ 0, '%d B' ],
          ],

          rounding => 1,
          formatter => sub { sprintf $_[ 1 ],
                               $_[ 0 ];
                           },
        );

my $size_converter_metric = Number::Textify
  -> new( [ [ 1_000 * 1_000 * 1_000, '%.2f GB' ],
            [ 1_000 * 1_000, '%.2f MB' ],
            [ 1_000, '%.2f KB' ],
            [ 0, '%d B' ],
          ],

          rounding => 1,
          formatter => sub { sprintf $_[ 1 ],
                               $_[ 0 ];
                           },
        );


for my $case
  ( [ 240 * 1_024 * 1_024 * 1_024,
      '240.00 GiB',
      '257.70 GB',
    ],
    [ 240 * 1_000 * 1_000 * 1_000,
      '223.52 GiB',
      '240.00 GB',
    ],
    [ 56_902_548_529,
      '52.99 GiB',
      '56.90 GB',
    ],
    [ 10_000_000,
      '9.54 MiB',
      '10.00 MB',
    ],
  ) {
  is $size_converter -> textify( $case -> [ 0 ] ), $case -> [ 1 ],
    $case -> [ 1 ];

  is $size_converter_metric -> textify( $case -> [ 0 ] ), $case -> [ 2 ],
    $case -> [ 2 ];
}


done_testing;
