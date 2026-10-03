#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin qw/$Bin/;
use Parse::Crontab;

use lib '../lib';

use Parse::Crontab::English;

my $test_file = "$Bin/crontab.test";

{
    my $obj = Parse::Crontab::English->new ( { file => $test_file } );
    ok ( defined $obj, "Test file $test_file loaded" );

    is ( ref $obj->{ base }{ entries }, 'ARRAY', "Expected an AoA data type" );
    ok ( exists ( $obj->{ summary } ), "Summary exists" );
    is ( 51, scalar keys %{ $obj->{ summary } }, "Check key count in summary" );

    foreach my $ent ( keys %{ $obj->{ summary } } ) {

      foreach my $e ( @{ $obj->{ summary }{ $ent } } ) {

        #  Check for all of the month s of the year ..

        if ( @{ $e->{ mon_range } } == 1 ) {

          like ( $e->{ month_desc }, qr/just the month of \w+/, "Single month" );

        } elsif ( $e->{ mon_range }[ 0 ] == 1 && $e->{ mon_range }[ -1 ] == 12 ) {

          is ( $e->{ month_desc },
            'every month', "Full mon range -> every month" );

        } else {

          like ( $e->{ month_desc }, qr/the following \d+ months:/,
            "Reasonable list of months." );
          # diag ( "Month range is @{ $e->{ mon_range } }" );
        }

        #  Check for all days of the month ..

        if ( @{ $e->{ day_range } } == 1 ) {

          like ( $e->{ day_desc }, qr/Just on day \d+/, 'Single day' );

        } elsif ( $e->{ day_range }[ 0 ] == 1 && $e->{ day_range }[ -1 ] == 31 ) {

          is ( $e->{ day_desc },
            'every day of the month', "Full day range -> every day (month)" );

        } else {

          like ( $e->{ day_desc }, qr/the following \d+ days:/,
            "Reasonable list of days of the week." );
          # diag ( "Day range is @{ $e->{ day_range } }" );
        }

        #  Check for all days of the week ..

        if ( @{ $e->{ dow_range } } == 7 ) {

          is ( $e->{ dow_desc },
            'every day of the week', "Full day range -> every day (week)" );

        } elsif ( @{ $e->{ dow_range } } == 1 ) {

          like ( $e->{ dow_desc },
            qr/just on \w+day/, "Single day of the week (name)" );

        } else {

          like ( $e->{ dow_desc }, qr/the following \d+ days of the week:/,
            "Reasonable list of days of the week." );
          # diag ( "Week day range is @{ $e->{ dow_range } }" );
        }
        # diag ( "DOW-number: $e->{ dow_number }" );
        # diag ( "DOW-name: $e->{ dow_name }" );

#       if ( exists $e->{ dow_name_range } ) {

#         if ( @{ $e->{ dow_range } } == 1 ) {

#           like ( $e->{ dow_name_range }, qr/\w+day/, "A single week day" );

#         } else {

#           #  This only tests for a single range, when we could have output
#           #  more. We might also have a single day, followed by a range.
#           #  Testing is hard.

#           like ( $e->{ dow_name_range },
#             qr/\w+day (and|to) \w+day|(\w+day, )+and \w+day/,
#             "A single range of days or two days, or a commified list" );
#         }
#         # diag ( "DOW-name_range ", $e->{ dow_name_range } );
#       }

        #  Check that something's there for the hours_minutes ..

        ok ( defined $e->{ hours_minutes }, "Hours and minutes defined" );
        # diag ( "H+M: $e->{ hours_minutes }" );

        #  .. and if it's less than every hour, that each hour is present; and

        if ( @{ $e->{ hour_range } } < 24 ) {

          foreach my $h ( @{ $e->{ hour_range } } ) {

            like ( $e->{ hours_minutes }, qr/${h}h00/, "Saw entry for hour $h" );
          }
        }

        #  .. and if it's less than every minute, check for those values too.

        if ( @{ $e->{ min_range } } < 60 ) {

          foreach my $m ( @{ $e->{ min_range } } ) {

            like ( $e->{ hours_minutes }, qr/:0?$m/, "Saw entry for minute $m" );
          }
        }

        #  Check that something's there for the hr_short ..

        ok ( defined $e->{ hm_desc }, "Hours and minutes description defined" );
        # diag ( "HM: $e->{ hm_short }" );

        #  Check for original line ..

        my $orig_line = $obj->{ base }{ entries }[ $e->{ line_num } ];
        ok ( defined $orig_line, "Original line exists" );
      }
    }

    done_testing;
}
