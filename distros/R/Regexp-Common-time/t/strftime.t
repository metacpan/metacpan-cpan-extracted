use strict;
use vars qw(@match $num_tests %RE);
use vars qw(@MONTH @MON @WEEKDAY @DAY);

BEGIN
{
    # Man, this locale stuff is a pain.  Why can't everyone just speak English?!  ;-)

    # Set defaults:
    @MONTH = qw(January February March April May June July August September October November December);
    @MON = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    @WEEKDAY = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
    @DAY = qw(Sun Mon Tue Wed Thu Fri Sat);

    eval
    {
        require POSIX;
        require I18N::Langinfo;

        eval
        {
            @MONTH = map I18N::Langinfo::langinfo($_), I18N::Langinfo::MON_1(), I18N::Langinfo::MON_2(), I18N::Langinfo::MON_3(), I18N::Langinfo::MON_4(), I18N::Langinfo::MON_5(), I18N::Langinfo::MON_6(), I18N::Langinfo::MON_7(), I18N::Langinfo::MON_8(), I18N::Langinfo::MON_9(), I18N::Langinfo::MON_10(), I18N::Langinfo::MON_11(), I18N::Langinfo::MON_12();
        };

        eval
        {
            @MON = map I18N::Langinfo::langinfo($_), I18N::Langinfo::ABMON_1(), I18N::Langinfo::ABMON_2(), I18N::Langinfo::ABMON_3(), I18N::Langinfo::ABMON_4(), I18N::Langinfo::ABMON_5(), I18N::Langinfo::ABMON_6(), I18N::Langinfo::ABMON_7(), I18N::Langinfo::ABMON_8(), I18N::Langinfo::ABMON_9(), I18N::Langinfo::ABMON_10(), I18N::Langinfo::ABMON_11(), I18N::Langinfo::ABMON_12();
        };

        eval
        {
            @WEEKDAY = map I18N::Langinfo::langinfo($_), I18N::Langinfo::DAY_1(), I18N::Langinfo::DAY_2(), I18N::Langinfo::DAY_3(), I18N::Langinfo::DAY_4(), I18N::Langinfo::DAY_5(), I18N::Langinfo::DAY_6(), I18N::Langinfo::DAY_7();
        };

        eval
        {
            @DAY = map I18N::Langinfo::langinfo($_), I18N::Langinfo::ABDAY_1(), I18N::Langinfo::ABDAY_2(), I18N::Langinfo::ABDAY_3(), I18N::Langinfo::ABDAY_4(), I18N::Langinfo::ABDAY_5(), I18N::Langinfo::ABDAY_6(), I18N::Langinfo::ABDAY_7();
        };
    };

    # target, pattern, values, name
    @match = (

              # 'a' : abbreviated weekday name
              [$DAY[0], '\A%a\z', [$DAY[0]], $DAY[0]],
              [$DAY[1], '\A%a\z', [$DAY[1]], $DAY[1]],
              [$DAY[2], '\A%a\z', [$DAY[2]], $DAY[2]],
              [$DAY[3], '\A%a\z', [$DAY[3]], $DAY[3]],
              [$DAY[4], '\A%a\z', [$DAY[4]], $DAY[4]],
              [$DAY[5], '\A%a\z', [$DAY[5]], $DAY[5]],
              [$DAY[6], '\A%a\z', [$DAY[6]], $DAY[6]],
              ["blah$DAY[1]blah", 'blah%ablah', ["blah$DAY[1]blah", $DAY[1]], 'M=Mon blahs'],
              ['*&^@#(','\A%a\z', undef,     '"a" garbage'],

              # 'A' : full weekday name
              [$WEEKDAY[0], '\A%A\z', [$WEEKDAY[0]], $WEEKDAY[0]],
              [$WEEKDAY[1], '\A%A\z', [$WEEKDAY[1]], $WEEKDAY[1]],
              [$WEEKDAY[2], '\A%A\z', [$WEEKDAY[2]], $WEEKDAY[2]],
              [$WEEKDAY[3], '\A%A\z', [$WEEKDAY[3]], $WEEKDAY[3]],
              [$WEEKDAY[4], '\A%A\z', [$WEEKDAY[4]], $WEEKDAY[4]],
              [$WEEKDAY[5], '\A%A\z', [$WEEKDAY[5]], $WEEKDAY[5]],
              [$WEEKDAY[6], '\A%A\z', [$WEEKDAY[6]], $WEEKDAY[6]],
              ["blah$WEEKDAY[1]blah", 'blah%Ablah', ["blah$WEEKDAY[1]blah", $WEEKDAY[1]], 'M=Monday blahs'],
              ['*&^@#(',    '\A%A\z', undef,         '"A" garbage'],

              # 'b' : abbreviated month name
              [$MON[ 0], '\A%b\z', [$MON[ 0]], $MON[ 0]],
              [$MON[ 1], '\A%b\z', [$MON[ 1]], $MON[ 1]],
              [$MON[ 2], '\A%b\z', [$MON[ 2]], $MON[ 2]],
              [$MON[ 3], '\A%b\z', [$MON[ 3]], $MON[ 3]],
              [$MON[ 4], '\A%b\z', [$MON[ 4]], $MON[ 4]],
              [$MON[ 5], '\A%b\z', [$MON[ 5]], $MON[ 5]],
              [$MON[ 6], '\A%b\z', [$MON[ 6]], $MON[ 6]],
              [$MON[ 7], '\A%b\z', [$MON[ 7]], $MON[ 7]],
              [$MON[ 8], '\A%b\z', [$MON[ 8]], $MON[ 8]],
              [$MON[ 9], '\A%b\z', [$MON[ 9]], $MON[ 9]],
              [$MON[10], '\A%b\z', [$MON[10]], $MON[10]],
              [$MON[11], '\A%b\z', [$MON[11]], $MON[11]],

              # 'B' : full month name
              [$MONTH[ 0], '\A%B\z', [$MONTH[ 0]], $MONTH[ 0]],
              [$MONTH[ 1], '\A%B\z', [$MONTH[ 1]], $MONTH[ 1]],
              [$MONTH[ 2], '\A%B\z', [$MONTH[ 2]], $MONTH[ 2]],
              [$MONTH[ 3], '\A%B\z', [$MONTH[ 3]], $MONTH[ 3]],
              [$MONTH[ 4], '\A%B\z', [$MONTH[ 4]], $MONTH[ 4]],
              [$MONTH[ 5], '\A%B\z', [$MONTH[ 5]], $MONTH[ 5]],
              [$MONTH[ 6], '\A%B\z', [$MONTH[ 6]], $MONTH[ 6]],
              [$MONTH[ 7], '\A%B\z', [$MONTH[ 7]], $MONTH[ 7]],
              [$MONTH[ 8], '\A%B\z', [$MONTH[ 8]], $MONTH[ 8]],
              [$MONTH[ 9], '\A%B\z', [$MONTH[ 9]], $MONTH[ 9]],
              [$MONTH[10], '\A%B\z', [$MONTH[10]], $MONTH[10]],
              [$MONTH[11], '\A%B\z', [$MONTH[11]], $MONTH[11]],

              # 'c' : locale-specific format
              # Not sure how to test this.

              # 'C' : century
              ['abcd00', '%C',     ['00'], 'Century 00'],
              ['10'    , '\A%C\z', ['10'], 'Century 10'],
              ['a18',    'a(%C)',  ['18'], 'Century 18'],
              ['(19)',   '\(%C\)', ['(19)', 19], 'Century 19'],
              ['abcd20', '%C\z',   ['20'], 'Century 20'],
              ['a2100',  'a%C',    ['a21','21'], 'Century 21'],

              # 'd' : Day number
              ['01',  '\A%d\z', ['01'], 'Day 01'],
              ['09',  '\A%d\z', ['09'], 'Day 09'],
              ['10',  '\A%d\z', ['10'], 'Day 10'],
              ['21',  '\A%d\z', ['21'], 'Day 21'],
              ['30',  '\A%d\z', ['30'], 'Day 30'],
              ['31',  '\A%d\z', ['31'], 'Day 31'],
              ['00',  '\A%d\z', undef,  'Day 00'],
              ['32',  '\A%d\z', undef,  'Day 32'],
              ['99',  '\A%d\z', undef,  'Day 99'],
              [' 8',  '\A%d\z', undef,  'Day  8'],
              ['8',   '\A%d\z', undef,  'Day 8'],

              # '_d' : Day number
              ['01',  '\A%_d\z', ['01'], '_d Day 01'],
              ['09',  '\A%_d\z', ['09'], '_d Day 09'],
              ['10',  '\A%_d\z', ['10'], '_d Day 10'],
              ['21',  '\A%_d\z', ['21'], '_d Day 21'],
              ['30',  '\A%_d\z', ['30'], '_d Day 30'],
              ['31',  '\A%_d\z', ['31'], '_d Day 31'],
              ['00',  '\A%_d\z', undef,  '_d Day 00'],
              ['32',  '\A%_d\z', undef,  '_d Day 32'],
              ['99',  '\A%_d\z', undef,  '_d Day 99'],
              [' 8',  '\A%_d\z', undef,  '_d Day  8'],
              ['8',   '\A%_d\z', ['8'],  '_d Day 8'],
              ['0',   '\A%_d\z', undef,  '_d Day 0'],

              # 'D' : m/d/y
              ['01/02/03', '%D', ['01/02/03'], '%D 01/02/03'],
              ['00/02/03', '%D', undef,        '%D 00/02/03'],
              ['13/02/03', '%D', undef,        '%D 13/02/03'],
              ['03/31/03', '%D', ['03/31/03'], '%D 03/31/03'],
              ['03/32/03', '%D', undef,        '%D 03/31/03'],

              # 'e' : Day number, leading space
              [' 1',  '%e', [' 1'], 'eDay  1'],
              [' 9',  '%e', [' 9'], 'eDay  9'],
              ['10',  '%e', ['10'], 'eDay 10'],
              ['21',  '%e', ['21'], 'eDay 21'],
              ['30',  '%e', ['30'], 'eDay 30'],
              ['31',  '%e', ['31'], 'eDay 31'],
              [' 0',  '%e', undef,  'eDay  0'],
              ['32',  '%e', undef,  'eDay 32'],
              ['99',  '%e', undef,  'eDay 99'],
              ['08',  '%e', undef,  'eDay 08'],

              # 'h' : same as %b
              [$MON[ 0], '\A%h\z', [$MON[ 0]], 'hJan'],
              [$MON[ 1], '\A%h\z', [$MON[ 1]], 'hFeb'],
              [$MON[ 2], '\A%h\z', [$MON[ 2]], 'hMar'],
              [$MON[ 3], '\A%h\z', [$MON[ 3]], 'hApr'],
              [$MON[ 4], '\A%h\z', [$MON[ 4]], 'hMay'],
              [$MON[ 5], '\A%h\z', [$MON[ 5]], 'hJun'],
              [$MON[ 6], '\A%h\z', [$MON[ 6]], 'hJul'],
              [$MON[ 7], '\A%h\z', [$MON[ 7]], 'hAug'],
              [$MON[ 8], '\A%h\z', [$MON[ 8]], 'hSep'],
              [$MON[ 9], '\A%h\z', [$MON[ 9]], 'hOct'],
              [$MON[10], '\A%h\z', [$MON[10]], 'hNov'],
              [$MON[11], '\A%h\z', [$MON[11]], 'hDec'],

              # 'H' : hour, 00-23
              ['00', '%H', ['00'], 'hour24 00'],
              ['01', '%H', ['01'], 'hour24 01'],
              ['10', '%H', ['10'], 'hour24 10'],
              ['13', '%H', ['13'], 'hour24 13'],
              ['20', '%H', ['20'], 'hour24 20'],
              ['23', '%H', ['23'], 'hour24 23'],
              [' 0', '%H', undef,  'hour24  0'],
              [' 1', '%H', undef,  'hour24  1'],
              ['24', '%H', undef,  'hour24 24'],

              # '_H' : hour, 0-23
              ['00', '%_H', ['00'], '_H hour24 00'],
              ['01', '%_H', ['01'], '_H hour24 01'],
              ['10', '%_H', ['10'], '_H hour24 10'],
              ['13', '%_H', ['13'], '_H hour24 13'],
              ['20', '%_H', ['20'], '_H hour24 20'],
              ['23', '%_H', ['23'], '_H hour24 23'],
              [' 0', '\A%_H\z', undef,  '_H hour24  0'],
              [' 1', '\A%_H\z', undef,  '_H hour24  1'],
              ['0',  '\A%_H\z', ['0'],  '_H hour24 0'],
              ['1',  '\A%_H\z', ['1'],  '_H hour24 1'],
              ['24', '\A%_H\z', undef,  '_H hour24 24'],

              # 'I' : hour, 01-12
              ['01', '%I', ['01'], 'hour12 01'],
              ['10', '%I', ['10'], 'hour12 10'],
              ['12', '%I', ['12'], 'hour12 12'],
              ['13', '%I', undef,  'hour12 13'],
              ['00', '%I', undef,  'hour12 00'],
              [' 0', '%I', undef,  'hour12  0'],
              [' 1', '%I', undef,  'hour12  1'],

              # '_I' : hour, 1-12
              ['01', '%_I', ['01'], '_I hour12 01'],
              ['10', '%_I', ['10'], '_I hour12 10'],
              ['12', '%_I', ['12'], '_I hour12 12'],
              ['13', '\A%_I\z', undef,  '_I hour12 13'],
              ['00', '%_I', undef,  '_I hour12 00'],
              [' 0', '\A%_I\z', undef,  '_I hour12  0'],
              [' 1', '\A%_I\z', undef,  '_I hour12  1'],
              ['0',  '\A%_I\z', undef,  '_I hour12 0'],
              ['1',  '\A%_I\z', ['1'],  '_I hour12 1'],

              # 'j' : day of year, 001-366
              ['001', '%j', ['001'], 'doy 001'],
              ['101', '%j', ['101'], 'doy 101'],
              ['201', '%j', ['201'], 'doy 201'],
              ['301', '%j', ['301'], 'doy 301'],
              ['366', '%j', ['366'], 'doy 366'],
              ['000', '%j', undef,   'doy 000'],
              ['367', '%j', undef,   'doy 367'],
              ['  1', '%j', undef,   'doy   1'],
              [ '27', '%j', undef,   'doy 27' ],

              # 'm' : month number, 01-12
              ['01', '%m', ['01'], 'month num 01'],
              ['10', '%m', ['10'], 'month num 10'],
              ['12', '%m', ['12'], 'month num 12'],
              ['13', '%m', undef,  'month num 13'],
              ['00', '%m', undef,  'month num 00'],
              [' 0', '%m', undef,  'month num  0'],
              [' 1', '%m', undef,  'month num  1'],

              # '_m' : month number, 1-12
              ['01', '%_m', ['01'], '_m month num 01'],
              ['10', '%_m', ['10'], '_m month num 10'],
              ['12', '%_m', ['12'], '_m month num 12'],
              ['13', '\A%_m\z', undef,  '_m month num 13'],
              ['00', '%_m', undef,  '_m month num 00'],
              [' 0', '\A%_m\z', undef,  '_m month num  0'],
              [' 1', '\A%_m\z', undef,  '_m month num  1'],
              ['0',  '\A%_m\z', undef,  '_m month num 0'],
              ['1',  '\A%_m\z', ['1'],  '_m month num 1'],

              # 'M' : minute number, 00-59
              ['00', '%M', ['00'], 'minute 00'],
              ['01', '%M', ['01'], 'minute 01'],
              ['10', '%M', ['10'], 'minute 10'],
              ['20', '%M', ['20'], 'minute 20'],
              ['30', '%M', ['30'], 'minute 30'],
              ['40', '%M', ['40'], 'minute 40'],
              ['50', '%M', ['50'], 'minute 50'],
              ['59', '%M', ['59'], 'minute 59'],
              ['60', '%M', undef,  'minute 60'],
              [' 0', '%M', undef,  'minute  0'],
              [ '1', '%M', undef,  'minute 1' ],

              # '_M' : minute number, 0-59
              ['00', '%_M', ['00'], 'minute 00'],
              ['01', '%_M', ['01'], 'minute 01'],
              ['10', '%_M', ['10'], 'minute 10'],
              ['20', '%_M', ['20'], 'minute 20'],
              ['30', '%_M', ['30'], 'minute 30'],
              ['40', '%_M', ['40'], 'minute 40'],
              ['50', '%_M', ['50'], 'minute 50'],
              ['59', '%_M', ['59'], 'minute 59'],
              ['60', '\A%_M\z', undef,  'minute 60'],
              [' 0', '\A%_M\z', undef,  'minute  0'],
              [' 1', '\A%_M\z', undef,  'minute  1'],
              ['0',  '\A%_M\z', ['0'],  'minute 0' ],
              ['1',  '\A%_M\z', ['1'],  'minute 1' ],

              # Not sure how to test 'p' or 'r'.

              # 'R' : hour24:minute
              ['00:00', '%R', ['00:00'], 'h24:minute 00:00'],
              ['01:00', '%R', ['01:00'], 'h24:minute 01:00'],
              ['10:00', '%R', ['10:00'], 'h24:minute 10:00'],
              ['13:00', '%R', ['13:00'], 'h24:minute 13:00'],
              ['20:00', '%R', ['20:00'], 'h24:minute 20:00'],
              ['23:00', '%R', ['23:00'], 'h24:minute 23:00'],
              [' 0:00', '%R', undef,     'h24:minute  0:00'],
              [' 1:00', '%R', undef,     'h24:minute  1:00'],
              ['24:00', '%R', undef,     'h24:minute 24:00'],
              ['02:00', '%R', ['02:00'], 'h24:minute 02:00'],
              ['02:01', '%R', ['02:01'], 'h24:minute 02:01'],
              ['02:10', '%R', ['02:10'], 'h24:minute 02:10'],
              ['02:20', '%R', ['02:20'], 'h24:minute 02:20'],
              ['02:30', '%R', ['02:30'], 'h24:minute 02:30'],
              ['02:40', '%R', ['02:40'], 'h24:minute 02:40'],
              ['02:50', '%R', ['02:50'], 'h24:minute 02:50'],
              ['02:59', '%R', ['02:59'], 'h24:minute 02:59'],
              ['02:60', '%R', undef,     'h24:minute 02:60'],
              ['02: 0', '%R', undef,     'h24:minute 02: 0'],
              ['02:1' , '%R', undef,     'h24:minute 02:1' ],

              # 'S' : second, 00-61
              ['00', '%S', ['00'], 'second 00'],
              ['01', '%S', ['01'], 'second 01'],
              ['10', '%S', ['10'], 'second 10'],
              ['20', '%S', ['20'], 'second 20'],
              ['30', '%S', ['30'], 'second 30'],
              ['40', '%S', ['40'], 'second 40'],
              ['50', '%S', ['50'], 'second 50'],
              ['59', '%S', ['59'], 'second 59'],
              ['60', '%S', ['60'], 'second 60'],
              ['61', '%S', ['61'], 'second 61'],
              ['62', '%S', undef,  'second 62'],
              [' 0', '%S', undef,  'second  0'],
              [ '1', '%S', undef,  'second 1' ],

              # 'T' : H24:M:S
              ['00:00:00', '%T', ['00:00:00'], 'h24:min:sec 00:00:00'],
              ['01:00:00', '%T', ['01:00:00'], 'h24:min:sec 01:00:00'],
              ['10:00:00', '%T', ['10:00:00'], 'h24:min:sec 10:00:00'],
              ['13:00:00', '%T', ['13:00:00'], 'h24:min:sec 13:00:00'],
              ['20:00:00', '%T', ['20:00:00'], 'h24:min:sec 20:00:00'],
              ['23:00:00', '%T', ['23:00:00'], 'h24:min:sec 23:00:00'],
              [' 0:00:00', '%T', undef,        'h24:min:sec  0:00:00'],
              [' 1:00:00', '%T', undef,        'h24:min:sec  1:00:00'],
              ['24:00:00', '%T', undef,        'h24:min:sec 24:00:00'],
              ['02:00:00', '%T', ['02:00:00'], 'h24:min:sec 02:00:00'],
              ['02:01:00', '%T', ['02:01:00'], 'h24:min:sec 02:01:00'],
              ['02:10:00', '%T', ['02:10:00'], 'h24:min:sec 02:10:00'],
              ['02:20:00', '%T', ['02:20:00'], 'h24:min:sec 02:20:00'],
              ['02:30:00', '%T', ['02:30:00'], 'h24:min:sec 02:30:00'],
              ['02:40:00', '%T', ['02:40:00'], 'h24:min:sec 02:40:00'],
              ['02:50:00', '%T', ['02:50:00'], 'h24:min:sec 02:50:00'],
              ['02:59:00', '%T', ['02:59:00'], 'h24:min:sec 02:59:00'],
              ['02:60:00', '%T', undef,        'h24:min:sec 02:60:00'],
              ['02: 0:00', '%T', undef,        'h24:min:sec 02: 0:00'],
              ['02:1:00' , '%T', undef,        'h24:min:sec 02:1:00' ],
              ['13:45:00', '%T', ['13:45:00'], 'h24:min:sec 13:45:00'],
              ['13:45:01', '%T', ['13:45:01'], 'h24:min:sec 13:45:01'],
              ['13:45:10', '%T', ['13:45:10'], 'h24:min:sec 13:45:10'],
              ['13:45:20', '%T', ['13:45:20'], 'h24:min:sec 13:45:20'],
              ['13:45:30', '%T', ['13:45:30'], 'h24:min:sec 13:45:30'],
              ['13:45:40', '%T', ['13:45:40'], 'h24:min:sec 13:45:40'],
              ['13:45:50', '%T', ['13:45:50'], 'h24:min:sec 13:45:50'],
              ['13:45:59', '%T', ['13:45:59'], 'h24:min:sec 13:45:59'],
              ['13:45:60', '%T', ['13:45:60'], 'h24:min:sec 13:45:60'],
              ['13:45:61', '%T', ['13:45:61'], 'h24:min:sec 13:45:61'],
              ['13:45:62', '%T', undef,        'h24:min:sec 13:45:62'],
              ['13:45: 0', '%T', undef,        'h24:min:sec 13:45: 0'],
              ['13:45:1',  '%T', undef,        'h24:min:sec 13:45:1' ],

              # 'u' : Weekday number, 1-7
              ['0', '%u', undef, 'wkd1-7  0'],
              ['1', '%u', ['1'], 'wkd1-7  1'],
              ['2', '%u', ['2'], 'wkd1-7  2'],
              ['3', '%u', ['3'], 'wkd1-7  3'],
              ['4', '%u', ['4'], 'wkd1-7  4'],
              ['5', '%u', ['5'], 'wkd1-7  5'],
              ['6', '%u', ['6'], 'wkd1-7  6'],
              ['7', '%u', ['7'], 'wkd1-7  7'],
              ['8', '%u', undef, 'wkd1-7  8'],

              # 'U' : week number, 00-53
              ['00', '%U', ['00'], 'week num U 00'],
              ['01', '%U', ['01'], 'week num U 01'],
              ['10', '%U', ['10'], 'week num U 10'],
              ['20', '%U', ['20'], 'week num U 20'],
              ['30', '%U', ['30'], 'week num U 30'],
              ['40', '%U', ['40'], 'week num U 40'],
              ['50', '%U', ['50'], 'week num U 50'],
              ['51', '%U', ['51'], 'week num U 51'],
              ['52', '%U', ['52'], 'week num U 52'],
              ['53', '%U', ['53'], 'week num U 53'],
              ['54', '%U', undef,  'week num U 54'],
              [' 0', '%U', undef,  'week num U  0'],
              [ '1', '%U', undef,  'week num U 1' ],

              # 'V' : week number, 01-53
              ['00', '%V', undef,  'week num V 00'],
              ['01', '%V', ['01'], 'week num V 01'],
              ['10', '%V', ['10'], 'week num V 10'],
              ['20', '%V', ['20'], 'week num V 20'],
              ['30', '%V', ['30'], 'week num V 30'],
              ['40', '%V', ['40'], 'week num V 40'],
              ['50', '%V', ['50'], 'week num V 50'],
              ['51', '%V', ['51'], 'week num V 51'],
              ['52', '%V', ['52'], 'week num V 52'],
              ['53', '%V', ['53'], 'week num V 53'],
              ['54', '%V', undef,  'week num V 54'],
              [' 0', '%V', undef,  'week num V  0'],
              [ '1', '%V', undef,  'week num V 1' ],

              # 'w' : Weekday number, 1-7
              ['',  '%w', undef, 'wkd0-6  ""'],
              ['0', '%w', ['0'], 'wkd0-6  0'],
              ['1', '%w', ['1'], 'wkd0-6  1'],
              ['2', '%w', ['2'], 'wkd0-6  2'],
              ['3', '%w', ['3'], 'wkd0-6  3'],
              ['4', '%w', ['4'], 'wkd0-6  4'],
              ['5', '%w', ['5'], 'wkd0-6  5'],
              ['6', '%w', ['6'], 'wkd0-6  6'],
              ['7', '%w', undef, 'wkd0-6  7'],

              # 'W' : week number, 00-53
              ['00', '%W', ['00'], 'week num W 00'],
              ['01', '%W', ['01'], 'week num W 01'],
              ['10', '%W', ['10'], 'week num W 10'],
              ['20', '%W', ['20'], 'week num W 20'],
              ['30', '%W', ['30'], 'week num W 30'],
              ['40', '%W', ['40'], 'week num W 40'],
              ['50', '%W', ['50'], 'week num W 50'],
              ['51', '%W', ['51'], 'week num W 51'],
              ['52', '%W', ['52'], 'week num W 52'],
              ['53', '%W', ['53'], 'week num W 53'],
              ['54', '%W', undef,  'week num W 54'],
              [' 0', '%W', undef,  'week num W  0'],
              [ '1', '%W', undef,  'week num W 1' ],

              # Not sure how to test 'x' or 'X'

              # 'y' : 2-digit year number
              ['00', '%y', ['00'], '2-digit year 00'],
              ['01', '%y', ['01'], '2-digit year 01'],
              ['90', '%y', ['90'], '2-digit year 90'],
              ['99', '%y', ['99'], '2-digit year 99'],
              ['3',  '%y', undef,  '2-digit year 3'],

              # 'Y' : 4-digit year number
              ['0000', '%Y', ['0000'], '4-digit year 0000'],
              ['1801', '%Y', ['1801'], '4-digit year 1801'],
              ['1990', '%Y', ['1990'], '4-digit year 1990'],
              ['2099', '%Y', ['2099'], '4-digit year 2099'],
              ['30',   '%Y', undef,    '4-digit year 30'],

              # TODO: add some mix&match tests here.

             );

    # How many matches will succeed?
    my $to_succeed = scalar grep $_->[2], @match;

    # Run two tests per match, plus two additional per expected success
    $num_tests = 2 * scalar(@match)  +  2 * $to_succeed;

    # Plus one for the 'use_ok' call
    $num_tests += 1;
}

use Test::More tests => $num_tests;
use_ok('Regexp::Common', 'time');

foreach my $match (@match)
{
    my ($text, $pattern, $matchvars, $testname) = @$match;
    my $did_succeed;
    my $should_succeed = defined $matchvars;
    my @captures;     # Regexp captures

    # FIRST: check whether it succeeded or failed as expected.
    # 'keep' option is OFF; should be no captures.
    @captures = $text =~ /$RE{time}{strftime}{-pat=>$pattern}/;
    $did_succeed = @captures > 0;

    # TEST 1: simple matching
    my $ought  = $should_succeed? 'match' : 'fail';
    my $actual = $did_succeed == $should_succeed?    "${ought}ed" : "did not $ought";
    ok ( ($should_succeed && $did_succeed)
     || (!$should_succeed && !$did_succeed),
         "$testname - $actual as expected (nokeep).");

    # TEST 2: Shouldn't capture anything
    if ($should_succeed)
    {
        SKIP:
        {
            skip "$testname - can't check captures since match unsuccessful", 1 if !$did_succeed;
            skip "$testname - user-controlled captures", 1 if $pattern =~ /\(/;
            is_deeply(\@captures, [1], "$testname - didn't unduly capture");
        }
    }

    # SECOND: use 'keep' option to check captures.
    @captures = $text =~ /$RE{time}{strftime}{-pat=>$pattern}{-keep}/;
    $did_succeed = @captures > 0;

    # TEST 3: matching with 'keep'
    ok ( ($should_succeed && $did_succeed)
     || (!$should_succeed && !$did_succeed),
         "$testname - $actual as expected (keep).");

    # TEST 4: capture variables should be set.
    if ($should_succeed)
    {
        SKIP:
        {
            skip "$testname - can't check captures since match unsuccessful", 1 if !$did_succeed;
            is_deeply(\@captures, $matchvars, "$testname - correct capture variables");
        }
    }
}
