use strict;
use warnings;

use Test::More tests => 501;

BEGIN { use_ok 'Range::Object::Interval' };

my $tests = eval do { local $/; <DATA>; };
die "Data eval error: $@" if $@;

die "Nothing to test!" unless $tests;

require 't/tests.pl';

run_tests( $tests );

__DATA__
[
    'Range::Object::Interval' => [
        # Custom code
        undef,

        # Interval length
        15,

        # Invalid input
        [ qw(99:99 9999 00:00:00 03:48 00:00/05:16) ],

        # Valid input
        [ qw(00:00/00:15 10:00 01:30/02:30 15:15/15:45 23:45) ],

        # Valid in() items
        [ qw(00:00 00:15 10:00 01:30 01:45 02:00 02:15 02:30
             15:15 15:30 15:45 23:45) ],

        # Not in() input
        [ qw(00:30 01:15 02:45 15:00 23:00 23:15 23:30) ],

        # Not in() output
        [ qw(00:30 01:15 02:45 15:00 23:00 23:15 23:30) ],

        # List context range() output
        [ qw(00:00 00:15 01:30 01:45 02:00 02:15 02:30 10:00
             15:15 15:30 15:45 23:45) ],

        # Scalar context range() output
        '00:00,00:15,01:30,01:45,02:00,02:15,02:30,10:00,'.
        '15:15,15:30,15:45,23:45',

        # List collapsed() output
        [ { start => '00:00', end => '00:15', count => 2 },
          { start => '01:30', end => '02:30', count => 5 }, '10:00',
          { start => '15:15', end => '15:45', count => 3 }, '23:45', ],

        # Scalar collapsed() output
        '00:00/00:15,01:30/02:30,10:00,15:15/15:45,23:45',

        # Initial size()
        12,

        # Interval specific military() output in list context
        [ { start => 0,    end => 15,   count => 2 },
          { start => 130,  end => 230,  count => 5 }, 1000,
          { start => 1515, end => 1545, count => 3 }, 2345, ],

        # Interval specific military() output in scalar context
        '0/15,130/230,1000,1515/1545,2345',

        # add() input
        [ qw(12:15/13:15) ],

        # Valid in() items after add()
        [ qw(00:00 00:15 01:30 01:45 02:00 02:15 02:30 10:00
             12:15 12:30 12:45 13:00 13:15 15:15 15:30 15:45 23:45) ],

        # Not in() input after add()
        [ qw(00:30 00:45 01:00 01:15 02:45 09:45 10:15 12:00
             13:30 13:45 14:00 14:15 14:30 14:45 15:00 16:00 23:30) ],

        # Not in output after add()
        [ qw(00:30 00:45 01:00 01:15 02:45 09:45 10:15 12:00
             13:30 13:45 14:00 14:15 14:30 14:45 15:00 16:00 23:30) ],

        # List context range() output after add()
        [ qw(00:00 00:15 01:30 01:45 02:00 02:15 02:30 10:00
             12:15 12:30 12:45 13:00 13:15 15:15 15:30 15:45 23:45) ],

        # Scalar context range() output after add()
        '00:00,00:15,01:30,01:45,02:00,02:15,02:30,10:00,12:15,'.
        '12:30,12:45,13:00,13:15,15:15,15:30,15:45,23:45',

        # List context collapsed() output after add()
        [ { start => '00:00', end => '00:15', count => 2 },
          { start => '01:30', end => '02:30', count => 5 }, '10:00',
          { start => '12:15', end => '13:15', count => 5 },
          { start => '15:15', end => '15:45', count => 3 }, '23:45', ],

        # Scalar context collapsed() output after add()
        '00:00/00:15,01:30/02:30,10:00,12:15/13:15,15:15/15:45,23:45',

        # size() after add()
        17,

        # Interval specific military() output after add(), list
        [ { start => 0,    end => 15,   count => 2 },
          { start => 130,  end => 230,  count => 5 }, 1000,
          { start => 1215, end => 1315, count => 5 },
          { start => 1515, end => 1545, count => 3 }, 2345 ],

        # Interval specific military() output after add(), scalar
        '0/15,130/230,1000,1215/1315,1515/1545,2345',

        # remove() input
        [ '00:00/03:00', '02:00/06:00', '03:00/08:00' ],

        # Valid in() items after remove()
        [ qw(10:00 12:15 12:30 12:45 13:00 13:15 15:15 15:30 15:45 23:45) ],

        # Not in() input after remove()
        [ qw(00:00 00:15 00:30 00:45 01:00 01:15 01:30 01:45 02:00
             02:15 02:30 02:45 03:00 03:15 03:30 03:45 04:00 04:15
             04:30 04:45 05:00 05:15 05:30 05:45 06:00 06:15 06:30
             06:45 07:00 07:15 07:30 07:45 08:00 08:15 08:30 08:45
             09:00 09:15 09:30 09:45 10:15 10:30 10:45 11:00 11:15
             11:30 11:45 12:00 13:30 13:45 14:00 14:15 14:30 14:45
             15:00 16:00 23:30) ],

        # Not in() output after remove()
        [ qw(00:00 00:15 00:30 00:45 01:00 01:15 01:30 01:45 02:00
             02:15 02:30 02:45 03:00 03:15 03:30 03:45 04:00 04:15
             04:30 04:45 05:00 05:15 05:30 05:45 06:00 06:15 06:30
             06:45 07:00 07:15 07:30 07:45 08:00 08:15 08:30 08:45
             09:00 09:15 09:30 09:45 10:15 10:30 10:45 11:00 11:15
             11:30 11:45 12:00 13:30 13:45 14:00 14:15 14:30 14:45
             15:00 16:00 23:30) ],

        # List context range() output after remove()
        [ qw(10:00 12:15 12:30 12:45 13:00 13:15 15:15 15:30 15:45 23:45) ],

        # Scalar context range() output after remove()
        '10:00,12:15,12:30,12:45,13:00,13:15,15:15,15:30,15:45,23:45',

        # List context collapsed() output after remove()
        [ '10:00',
          { start => '12:15', end => '13:15', count => 5 },
          { start => '15:15', end => '15:45', count => 3 }, '23:45' ],

        # Scalar context collapsed() outpuf after remove()
        '10:00,12:15/13:15,15:15/15:45,23:45',

        # size() after remove()
        10,

        # Interval specific military() output after remove(), list
        [ 1000, { start => 1215, end => 1315, count => 5 },
                { start => 1515, end => 1545, count => 3 }, 2345, ],

        # Interval specific military() output after remove(), scalar
        '1000,1215/1315,1515/1545,2345',
    ],
    'Range::Object::Interval' => [
        # Custom code
        undef,

        # Interval length
        30,

        # Invalid input
        [ qw(00:15 01:31 03:48 00:00/00:45) ],

        # Valid input
        [ qw(00:00/00:30 09:00 01:30/02:30 15:00/16:00 23:30) ],

        # Valid in() items
        [ qw(09:00 01:30 02:00 02:30 15:00 15:30 16:00 23:30 00:00 00:30) ],

        # Not in() input
        [ qw(01:00 03:00 16:30 23:00) ],

        # Not in() output
        [ qw(01:00 03:00 16:30 23:00) ],

        # List context range() output
        [ qw(00:00 00:30 01:30 02:00 02:30 09:00 15:00 15:30 16:00 23:30) ],

        # Scalar context range() output
        '00:00,00:30,01:30,02:00,02:30,09:00,15:00,15:30,16:00,23:30',

        # List context collapsed() output
        [ { start => '00:00', end => '00:30', count => 2 },
          { start => '01:30', end => '02:30', count => 3 }, '09:00',
          { start => '15:00', end => '16:00', count => 3 }, '23:30', ],

        # Scalar context collapsed() output
        '00:00/00:30,01:30/02:30,09:00,15:00/16:00,23:30',

        # Initial size()
        10,

        # Interval specific military() output, list context
        [ { start => 0,    end => 30,   count => 2 },
          { start => 130,  end => 230,  count => 3 }, 900,
          { start => 1500, end => 1600, count => 3 }, 2330, ],

        # Interval specific military() output, scalar context
        '0/30,130/230,900,1500/1600,2330',

        # add() input
        [ qw(12:00/13:30) ],

        # Valid in() items after add()
        [ qw(00:00 00:30 01:30 02:00 02:30 09:00 12:00 12:30 13:00
             13:30 15:00 15:30 16:00 23:30) ],

        # Not in() input() after add()
        [ qw(01:00 03:00 03:30 04:00 04:30 05:00 05:30 06:00 06:30
             07:00 07:30 08:00 08:30 10:00 10:30 11:00 11:30 14:00
             14:30 16:30 17:00 17:30 18:00 18:30 19:00 19:30 20:00
             20:30 21:00 21:30 22:00 22:30 23:00) ],

        # Not in() output after add()
        [ qw(01:00 03:00 03:30 04:00 04:30 05:00 05:30 06:00 06:30
             07:00 07:30 08:00 08:30 10:00 10:30 11:00 11:30 14:00
             14:30 16:30 17:00 17:30 18:00 18:30 19:00 19:30 20:00
             20:30 21:00 21:30 22:00 22:30 23:00) ],

        # List context range() output after add()
        [ qw(00:00 00:30 01:30 02:00 02:30 09:00 12:00 12:30 13:00
             13:30 15:00 15:30 16:00 23:30) ],

        # Scalar context range() output after add()
        '00:00,00:30,01:30,02:00,02:30,09:00,12:00,12:30,13:00,'.
        '13:30,15:00,15:30,16:00,23:30',

        # List context collapsed() output after add()
        [ { start => '00:00', end => '00:30', count => 2 },
          { start => '01:30', end => '02:30', count => 3 }, '09:00',
          { start => '12:00', end => '13:30', count => 4 },
          { start => '15:00', end => '16:00', count => 3 }, '23:30', ],

        # Scalar context collapsed() output after add()
        '00:00/00:30,01:30/02:30,09:00,12:00/13:30,15:00/16:00,23:30',

        # size() after add()
        14,

        # Interval specific military() output in list context
        [ { start => 0,    end => 30,   count => 2 },
          { start => 130,  end => 230,  count => 3 }, 900,
          { start => 1200, end => 1330, count => 4 },
          { start => 1500, end => 1600, count => 3 }, 2330, ],

        # Interval specific military() output in scalar context
        '0/30,130/230,900,1200/1330,1500/1600,2330',

        # remove() input
        [ '00:00/01:00;08:00/10:00', '20:00/23:30' ],

        # Valid in() items after remove()
        [ qw(01:30 02:00 02:30 12:00 12:30 13:00 13:30 15:00 15:30 16:00) ],

        # Not in() input after remove()
        [ qw(00:00 00:30 01:00 03:00 03:30 04:00 04:30 05:00 05:30
             06:00 06:30 07:00 07:30 08:00 08:30 09:00 09:30 10:00
             10:30 11:00 11:30 14:00 14:30 16:30 17:00 17:30 18:00
             18:30 19:00 19:30 20:00 20:30 21:00 21:30 22:00 22:30
             23:00 23:30) ],

        # Not in() output after remove()
        [ qw(00:00 00:30 01:00 03:00 03:30 04:00 04:30 05:00 05:30
             06:00 06:30 07:00 07:30 08:00 08:30 09:00 09:30 10:00
             10:30 11:00 11:30 14:00 14:30 16:30 17:00 17:30 18:00
             18:30 19:00 19:30 20:00 20:30 21:00 21:30 22:00 22:30
             23:00 23:30) ],

        # List context range() output after remove()
        [ qw(01:30 02:00 02:30 12:00 12:30 13:00 13:30 15:00 15:30 16:00) ],

        # Scalar context range() output after remove()
        '01:30,02:00,02:30,12:00,12:30,13:00,13:30,15:00,15:30,16:00',

        # List context collapsed() output after remove()
        [ { start => '01:30', end => '02:30', count => 3 },
          { start => '12:00', end => '13:30', count => 4 },
          { start => '15:00', end => '16:00', count => 3 }, ],

        # Scalar context collapsed() output after remove()
        '01:30/02:30,12:00/13:30,15:00/16:00',

        # size() after remove()
        10,

        # Interval specific military() output after remove(), list
        [ { start => 130,  end => 230,  count => 3 },
          { start => 1200, end => 1330, count => 4 },
          { start => 1500, end => 1600, count => 3 }, ],

        # Interval specific military() output after remove(), scalar
        '130/230,1200/1330,1500/1600',
    ],
    'Range::Object::Interval' => [
        # Custom code
        undef,

        # Interval length
        60,

        # Invalid input
        [ qw(00:15 00:30 00:45 03:00/05:45) ],

        # Valid input -- FIRST ARGUMENT MANDATORY
        [ qw(00:00/01:00 02:00/05:00 08:00/13:00 23:00) ],

        # Valid in() items
        [ qw(00:00 01:00 02:00 03:00 04:00 05:00 08:00
             09:00 10:00 11:00 12:00 13:00 23:00) ],

        # Not in() input
        [ qw(06:00 07:00 14:00 15:00 16:00 17:00 18:00
             19:00 20:00 21:00 22:00) ],

        # Not in() output
        [ qw(06:00 07:00 14:00 15:00 16:00 17:00 18:00
             19:00 20:00 21:00 22:00) ],

        # List context range() output
        [ qw(00:00 01:00 02:00 03:00 04:00 05:00 08:00
             09:00 10:00 11:00 12:00 13:00 23:00) ],

        # Scalar context range() output
        '00:00,01:00,02:00,03:00,04:00,05:00,08:00,09:00,'.
        '10:00,11:00,12:00,13:00,23:00',

        # List context collapsed() output
        [ { start => '00:00', end => '05:00', count => 6 },
          { start => '08:00', end => '13:00', count => 6 }, '23:00' ],

        # Scalar context collapsed() output
        '00:00/05:00,08:00/13:00,23:00',

        # Initial size()
        13,

        # Interval specific military() output, list context
        [ { start => 0,   end => 500,  count => 6 },
          { start => 800, end => 1300, count => 6 }, 2300, ],

        # Interval specific military() output, scalar context
        '0/500,800/1300,2300',

        # add() input
        [ qw(14:00/22:00) ],

        # Valid in() items after add()
        [ qw(00:00 01:00 02:00 03:00 04:00 05:00 08:00 09:00 10:00
             11:00 12:00 13:00 14:00 15:00 16:00 17:00 18:00 19:00
             20:00 21:00 22:00 23:00) ],

        # Not in() input after add()
        [ qw(06:00 07:00) ],

        # Not in() output after add()
        [ qw(06:00 07:00) ],

        # List context range() output after add()
        [ qw(00:00 01:00 02:00 03:00 04:00 05:00 08:00 09:00 10:00
             11:00 12:00 13:00 14:00 15:00 16:00 17:00 18:00 19:00
             20:00 21:00 22:00 23:00) ],

        # Scalar context range() output after add()
        '00:00,01:00,02:00,03:00,04:00,05:00,08:00,09:00,10:00,'.
        '11:00,12:00,13:00,14:00,15:00,16:00,17:00,18:00,19:00,'.
        '20:00,21:00,22:00,23:00',

        # List context collapsed() output after add()
        [ { start => '00:00', end => '05:00', count => 6  },
          { start => '08:00', end => '23:00', count => 16 }, ],

        # Scalar context collapsed() output after add()
        '00:00/05:00,08:00/23:00',

        # size() after add()
        22,

        # Interval specific military() output after add(), list
        [ { start => 0,   end => 500,  count => 6 },
          { start => 800, end => 2300, count => 16 }, ],

        # Interval specific military() output after add(), scalar
        '0/500,800/2300',

        # remove() input
        [ '06:00/10:00;10:00/12:00,11:00/13:00', '13:00/16:00' ],

        # Valid in() items after remove()
        [ qw(00:00 01:00 02:00 03:00 04:00 05:00 17:00
             18:00 19:00 20:00 21:00 22:00 23:00) ],

        # Not in() input after remove()
        [ qw(06:00 07:00 08:00 09:00 10:00 11:00 12:00
             13:00 14:00 15:00 16:00) ],

        # Not in() output after remove()
        [ qw(06:00 07:00 08:00 09:00 10:00 11:00 12:00 
             13:00 14:00 15:00 16:00) ],

        # List context range() output after remove()
        [ qw(00:00 01:00 02:00 03:00 04:00 05:00 17:00
             18:00 19:00 20:00 21:00 22:00 23:00) ],

        # Scalar context range() output after remove()
        '00:00,01:00,02:00,03:00,04:00,05:00,17:00,'.
        '18:00,19:00,20:00,21:00,22:00,23:00',

        # List context collapsed() output after remove()
        [ { start => '00:00', end => '05:00', count => 6 },
          { start => '17:00', end => '23:00', count => 7 }, ],

        # Scalar context collapsed() output after remove()
        '00:00/05:00,17:00/23:00',

        # size() after remove()
        13,

        # Interval specific military() output after remove(), list
        [ { start => 0,    end => 500,  count => 6 },
          { start => 1700, end => 2300, count => 7 }, ],

        # Scalar context military() output after remove(), scalar
        '0/500,1700/2300',
    ],
]
