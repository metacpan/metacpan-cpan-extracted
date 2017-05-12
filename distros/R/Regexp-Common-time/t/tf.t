use strict;
use warnings;

use vars qw(@match $num_tests);
use vars qw(@MONTH @MON @WEEKDAY @DAY);

BEGIN
{
    # Man, this locale stuff is a pain.  Why can't everyone just speak English?!

    # First set defaults:
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

              # 'day' : abbreviated weekday name
              [$DAY[0], '\Aday\z', [$DAY[0], $DAY[0]], 'Sun'],
              [$DAY[1], '\Aday\z', [$DAY[1], $DAY[1]], 'Mon'],
              [$DAY[2], '\Aday\z', [$DAY[2], $DAY[2]], 'Tue'],
              [$DAY[3], '\Aday\z', [$DAY[3], $DAY[3]], 'Wed'],
              [$DAY[4], '\Aday\z', [$DAY[4], $DAY[4]], 'Thu'],
              [$DAY[5], '\Aday\z', [$DAY[5], $DAY[5]], 'Fri'],
              [$DAY[6], '\Aday\z', [$DAY[6], $DAY[6]], 'Sat'],
              ['*&^@#(','\Aday\z', undef,     '"a" garbage'],
              ["blaz$DAY[1]blaz", 'blazdayblaz', ["blaz$DAY[1]blaz", $DAY[1]], 'Mon blazz'],

              # 'Weekday' : full weekday name
              [$WEEKDAY[0], '\AWeekday\z', [$WEEKDAY[0], $WEEKDAY[0]], 'Sunday'],
              [$WEEKDAY[1], '\AWeekday\z', [$WEEKDAY[1], $WEEKDAY[1]], 'Monday'],
              [$WEEKDAY[2], '\AWeekday\z', [$WEEKDAY[2], $WEEKDAY[2]], 'Tuesday'],
              [$WEEKDAY[3], '\AWeekday\z', [$WEEKDAY[3], $WEEKDAY[3]], 'Wednesday'],
              [$WEEKDAY[4], '\AWeekday\z', [$WEEKDAY[4], $WEEKDAY[4]], 'Thursday'],
              [$WEEKDAY[5], '\AWeekday\z', [$WEEKDAY[5], $WEEKDAY[5]], 'Friday'],
              [$WEEKDAY[6], '\AWeekday\z', [$WEEKDAY[6], $WEEKDAY[6]], 'Saturday'],
              ["blaz$WEEKDAY[1]blaz", 'blazweekdayblaz', ["blaz$WEEKDAY[1]blaz", $WEEKDAY[1]], 'Monday blazz'],
              ['*&^@#(',    '\AWeekday\z', undef,         '"Weekday" garbage'],

              # 'Mon' : abbreviated month name
              [$MON[ 0], '\AMon\z', [$MON[ 0], $MON[ 0]], 'Jan'],
              [$MON[ 1], '\AMon\z', [$MON[ 1], $MON[ 1]], 'Feb'],
              [$MON[ 2], '\AMon\z', [$MON[ 2], $MON[ 2]], 'Mar'],
              [$MON[ 3], '\AMon\z', [$MON[ 3], $MON[ 3]], 'Apr'],
              [$MON[ 4], '\AMon\z', [$MON[ 4], $MON[ 4]], 'May'],
              [$MON[ 5], '\AMon\z', [$MON[ 5], $MON[ 5]], 'Jun'],
              [$MON[ 6], '\AMon\z', [$MON[ 6], $MON[ 6]], 'Jul'],
              [$MON[ 7], '\AMon\z', [$MON[ 7], $MON[ 7]], 'Aug'],
              [$MON[ 8], '\AMon\z', [$MON[ 8], $MON[ 8]], 'Sep'],
              [$MON[ 9], '\AMon\z', [$MON[ 9], $MON[ 9]], 'Oct'],
              [$MON[10], '\AMon\z', [$MON[10], $MON[10]], 'Nov'],
              [$MON[11], '\AMon\z', [$MON[11], $MON[11]], 'Dec'],

              # 'MONTH' : full month name
              [$MONTH[ 0], '\AMONTH\z', [$MONTH[ 0], $MONTH[ 0]], 'January'],
              [$MONTH[ 1], '\AMONTH\z', [$MONTH[ 1], $MONTH[ 1]], 'February'],
              [$MONTH[ 2], '\AMONTH\z', [$MONTH[ 2], $MONTH[ 2]], 'March'],
              [$MONTH[ 3], '\AMONTH\z', [$MONTH[ 3], $MONTH[ 3]], 'April'],
              [$MONTH[ 4], '\AMONTH\z', [$MONTH[ 4], $MONTH[ 4]], 'May'],
              [$MONTH[ 5], '\AMONTH\z', [$MONTH[ 5], $MONTH[ 5]], 'June'],
              [$MONTH[ 6], '\AMONTH\z', [$MONTH[ 6], $MONTH[ 6]], 'July'],
              [$MONTH[ 7], '\AMONTH\z', [$MONTH[ 7], $MONTH[ 7]], 'August'],
              [$MONTH[ 8], '\AMONTH\z', [$MONTH[ 8], $MONTH[ 8]], 'September'],
              [$MONTH[ 9], '\AMONTH\z', [$MONTH[ 9], $MONTH[ 9]], 'Octtober'],
              [$MONTH[10], '\AMONTH\z', [$MONTH[10], $MONTH[10]], 'November'],
              [$MONTH[11], '\AMONTH\z', [$MONTH[11], $MONTH[11]], 'December'],

              # 'dd' : Day number
              ['01',  '\Add\z', ['01', '01'], 'dd Day 01'],
              ['09',  '\Add\z', ['09', '09'], 'dd Day 09'],
              ['10',  '\Add\z', ['10', '10'], 'dd Day 10'],
              ['21',  '\Add\z', ['21', '21'], 'dd Day 21'],
              ['30',  '\Add\z', ['30', '30'], 'dd Day 30'],
              ['31',  '\Add\z', ['31', '31'], 'dd Day 31'],
              ['00',  '\Add\z', undef,        'dd Day 00'],
              ['32',  '\Add\z', undef,        'dd Day 32'],
              ['99',  '\Add\z', undef,        'dd Day 99'],
              [' 8',  '\Add\z', undef,        'dd Day  8'],
              ['8',   '\Add\z', undef,        'dd Day 8'],

              # 'd' : Day number
              ['0',   '\Ad\z', undef,        'd Day 0'],
              ['01',  '\Ad\z', ['01', '01'], 'd Day 01'],
              ['1' ,  '\Ad\z', ['1' , '1' ], 'd Day 1' ],
              ['10',  '\Ad\z', ['10', '10'], 'd Day 10'],
              ['21',  '\Ad\z', ['21', '21'], 'd Day 21'],
              ['30',  '\Ad\z', ['30', '30'], 'd Day 30'],
              ['31',  '\Ad\z', ['31', '31'], 'd Day 31'],
              ['00',  '\Ad\z', undef,        'd Day 00'],
              ['32',  '\Ad\z', undef,        'd Day 32'],
              ['99',  '\Ad\z', undef,        'd Day 99'],
              [' 8',  '\Ad\z', undef,        'd Day  8'],

              # '?d' : Day number
              ['00',  '\A?d\z', undef,        '?d Day 00'],
              [' 0',  '\A?d\z', undef,        '?d Day 09'],
              ['01',  '\A?d\z', undef,        '?d Day 01'],
              ['10',  '\A?d\z', ['10', '10'], '?d Day 10'],
              ['21',  '\A?d\z', ['21', '21'], '?d Day 21'],
              ['30',  '\A?d\z', ['30', '30'], '?d Day 30'],
              ['31',  '\A?d\z', ['31', '31'], '?d Day 31'],
              ['32',  '\A?d\z', undef,        '?d Day 32'],
              ['99',  '\A?d\z', undef,        '?d Day 99'],
              [' 8',  '\A?d\z', [' 8', ' 8'], '?d Day  8'],
              ['8',   '\A?d\z', undef,        '?d Day 8'],

              # Combo: m/d/y
              ['01/02/03', 'mm/dd/yy', ['01/02/03', '01', '02', '03'], 'mm/dd/yy 01/02/03'],
              ['00/02/03', 'mm/dd/yy', undef,                          'mm/dd/yy 00/02/03'],
              ['13/02/03', 'mm/dd/yy', undef,                          'mm/dd/yy 13/02/03'],
              ['03/31/03', 'mm/dd/yy', ['03/31/03', '03', '31', '03'], 'mm/dd/yy 03/31/03'],
              ['03/32/03', 'mm/dd/yy', undef,                          'mm/dd/yy 03/31/03'],


              # 'hh' : hour, 00-23
              ['00', 'hh', ['00', '00'], 'hour24 hh 00'],
              ['01', 'hh', ['01', '01'], 'hour24 hh 01'],
              ['10', 'hh', ['10', '10'], 'hour24 hh 10'],
              ['13', 'hh', ['13', '13'], 'hour24 hh 13'],
              ['20', 'hh', ['20', '20'], 'hour24 hh 20'],
              ['23', 'hh', ['23', '23'], 'hour24 hh 23'],
              [' 0', 'hh', undef,  'hour24 hh  0'],
              [' 1', 'hh', undef,  'hour24 hh  1'],
              ['24', 'hh', undef,  'hour24 hh 24'],

              # 'h' : hour, 0-23
              ['00', 'h', ['00', '00'], 'hour24 h 00'],
              ['01', 'h', ['01', '01'], 'hour24 h 01'],
              ['10', 'h', ['10', '10'], 'hour24 h 10'],
              ['13', 'h', ['13', '13'], 'hour24 h 13'],
              ['20', 'h', ['20', '20'], 'hour24 h 20'],
              ['23', 'h', ['23', '23'], 'hour24 h 23'],
              [' 0', '\Ah\z', undef,      'hour24 h  0'],
              [' 1', '\Ah\z', undef,      'hour24 h  1'],
              ['0',  'h', ['0', '0'],   'hour24 h 0'],
              ['1',  'h', ['1', '1'],   'hour24 h 1'],
              ['24', '\Ah\z', undef,      'hour24 h 24'],

              # '?h' : hour,  0-23
              ['00', '?h', undef,        'hour24 ?h 00'],
              ['01', '?h', undef,        'hour24 ?h 01'],
              ['10', '?h', ['10', '10'], 'hour24 ?h 10'],
              ['13', '?h', ['13', '13'], 'hour24 ?h 13'],
              ['20', '?h', ['20', '20'], 'hour24 ?h 20'],
              ['23', '?h', ['23', '23'], 'hour24 ?h 23'],
              ['0',  '?h', undef,        'hour24 ?h 0'],
              ['1',  '?h', undef,        'hour24 ?h 1'],
              [' 0', '?h', [' 0', ' 0'], 'hour24 ?h  0'],
              [' 1', '?h', [' 1', ' 1'], 'hour24 ?h  1'],
              ['24', '?h', undef,        'hour24 ?h 24'],


              # 'HH' : hour, 01-12
              ['00', 'HH', undef,        'hour12 HH 00'],
              ['01', 'HH', ['01', '01'], 'hour12 HH 01'],
              ['10', 'HH', ['10', '10'], 'hour12 HH 10'],
              ['13', 'HH', undef,        'hour12 HH 13'],
              [' 0', 'HH', undef,  'hour12 HH  0'],
              [' 1', 'HH', undef,  'hour12 HH  1'],

              # 'H' : hour, 1-12
              ['00', 'H', undef,        'hour12 H 00'],
              ['01', 'H', ['01', '01'], 'hour12 H 01'],
              ['10', 'H', ['10', '10'], 'hour12 H 10'],
              ['13', '\AH\z', undef,        'hour12 H 13'],
              [' 0', '\AH\z', undef,      'hour12 H  0'],
              [' 1', '\AH\z', undef,      'hour12 H  1'],
              ['0',  'H', undef,        'hour12 H 0'],
              ['1',  'H', ['1', '1'],   'hour12 H 1'],

              # '?h' : hour,  1-12
              ['00', '?H', undef,        'hour12 ?H 00'],
              ['01', '?H', undef,        'hour12 ?H 01'],
              ['10', '?H', ['10', '10'], 'hour12 ?H 10'],
              ['13', '?H', undef,        'hour12 ?H 13'],
              ['0',  '?H', undef,        'hour12 ?H 0'],
              ['1',  '?H', undef,        'hour12 ?H 1'],
              [' 0', '?H', undef,        'hour12 ?H  0'],
              [' 1', '?H', [' 1', ' 1'], 'hour12 ?H  1'],

              # 'mm{on}' : month number, 01-12
              ['01', 'mm{on}', ['01', '01'], 'month mm 01'],
              ['10', 'mm{on}', ['10', '10'], 'month mm 10'],
              ['12', 'mm{on}', ['12', '12'], 'month mm 12'],
              ['13', 'mm{on}', undef,  'month mm 13'],
              ['00', 'mm{on}', undef,  'month mm 00'],
              [' 0', 'mm{on}', undef,  'month mm  0'],
              [' 1', 'mm{on}', undef,  'month mm  1'],

              # 'm{on}' : month number, 1-12
              ['01', '\Am{on}\z', ['01', '01'], 'month m 01'],
              ['10', 'm{on}',   ['10', '10'], 'month m 10'],
              ['12', 'm{on}',   ['12', '12'], 'month m 12'],
              ['13', '\Am{on}\z', undef,        'month m 13'],
              ['00', 'm{on}',   undef,        'month m 00'],
              [' 0', '\Am{on}\z', undef,        'month m  0'],
              [' 1', '\Am{on}\z', undef,        'month m  1'],

              # '?m{on}' : month number,  1-12
              ['01', '?m{on}', undef,        'month ?m 01'],
              ['10', '?m{on}', ['10', '10'], 'month ?m 10'],
              ['12', '?m{on}', ['12', '12'], 'month ?m 12'],
              ['13', '?m{on}', undef,        'month ?m 13'],
              ['00', '?m{on}', undef,        'month ?m 00'],
              [' 0', '?m{on}', undef,        'month ?m  0'],
              [' 1', '?m{on}', [' 1', ' 1'], 'month ?m  1'],

              # 'mm{in}' : minute number, 00-59
              ['00', '\Amm{in}\z', ['00', '00'], 'minute mm 00'],
              ['01', '\Amm{in}\z', ['01', '01'], 'minute mm 01'],
              ['10', '\Amm{in}\z', ['10', '10'], 'minute mm 10'],
              ['20', '\Amm{in}\z', ['20', '20'], 'minute mm 20'],
              ['30', '\Amm{in}\z', ['30', '30'], 'minute mm 30'],
              ['40', '\Amm{in}\z', ['40', '40'], 'minute mm 40'],
              ['50', '\Amm{in}\z', ['50', '50'], 'minute mm 50'],
              ['59', '\Amm{in}\z', ['59', '59'], 'minute mm 59'],
              ['60', '\Amm{in}\z', undef,        'minute mm 60'],
              [' 0', '\Amm{in}\z', undef,        'minute mm  0'],
              [ '1', '\Amm{in}\z', undef,        'minute mm 1' ],

              # 'm{in}' : minute number, 0-59
              ['00', '\Am{in}\z', ['00', '00'], 'minute m 00'],
              ['01', '\Am{in}\z', ['01', '01'], 'minute m 01'],
              ['10', '\Am{in}\z', ['10', '10'], 'minute m 10'],
              ['20', '\Am{in}\z', ['20', '20'], 'minute m 20'],
              ['30', '\Am{in}\z', ['30', '30'], 'minute m 30'],
              ['40', '\Am{in}\z', ['40', '40'], 'minute m 40'],
              ['50', '\Am{in}\z', ['50', '50'], 'minute m 50'],
              ['59', '\Am{in}\z', ['59', '59'], 'minute m 59'],
              ['60', '\Am{in}\z', undef,        'minute m 60'],
              [' 0', '\Am{in}\z', undef,        'minute m  0'],
              [' 1', '\Am{in}\z', undef,        'minute m  1' ],
              [ '0', '\Am{in}\z', ['0', '0'],   'minute m 0'],
              [ '1', '\Am{in}\z', ['1', '1'],   'minute m 1' ],

              # '?m{in}' : minute number, 0-59
              ['00', '\A?m{in}\z', undef,        'minute ?m 00'],
              ['01', '\A?m{in}\z', undef,        'minute ?m 01'],
              ['10', '\A?m{in}\z', ['10', '10'], 'minute ?m 10'],
              ['20', '\A?m{in}\z', ['20', '20'], 'minute ?m 20'],
              ['30', '\A?m{in}\z', ['30', '30'], 'minute ?m 30'],
              ['40', '\A?m{in}\z', ['40', '40'], 'minute ?m 40'],
              ['50', '\A?m{in}\z', ['50', '50'], 'minute ?m 50'],
              ['59', '\A?m{in}\z', ['59', '59'], 'minute ?m 59'],
              ['60', '\A?m{in}\z', undef,        'minute ?m 60'],
              [' 0', '\A?m{in}\z', [' 0', ' 0'], 'minute ?m  0'],
              [' 1', '\A?m{in}\z', [' 1', ' 1'], 'minute ?m  1'],
              ['0',  '\A?m{in}\z', undef,        'minute ?m 0'],
              ['1',  '\A?m{in}\z', undef,        'minute ?m 1'],

              # 'ss' : second number, 00-59
              ['00', '\Ass\z', ['00', '00'], 'second ss 00'],
              ['01', '\Ass\z', ['01', '01'], 'second ss 01'],
              ['10', '\Ass\z', ['10', '10'], 'second ss 10'],
              ['20', '\Ass\z', ['20', '20'], 'second ss 20'],
              ['30', '\Ass\z', ['30', '30'], 'second ss 30'],
              ['40', '\Ass\z', ['40', '40'], 'second ss 40'],
              ['50', '\Ass\z', ['50', '50'], 'second ss 50'],
              ['59', '\Ass\z', ['59', '59'], 'second ss 59'],
              ['60', '\Ass\z', ['60', '60'], 'second ss 60'],
              ['61', '\Ass\z', ['61', '61'], 'second ss 61'],
              ['62', '\Ass\z', undef,        'second ss 62'],
              [' 0', '\Ass\z', undef,        'second ss  0'],
              [ '1', '\Ass\z', undef,        'second ss 1' ],

              # 's' : second number, 00-61
              ['00', '\As\z', ['00', '00'], 'second s 00'],
              ['01', '\As\z', ['01', '01'], 'second s 01'],
              ['10', '\As\z', ['10', '10'], 'second s 10'],
              ['20', '\As\z', ['20', '20'], 'second s 20'],
              ['30', '\As\z', ['30', '30'], 'second s 30'],
              ['40', '\As\z', ['40', '40'], 'second s 40'],
              ['50', '\As\z', ['50', '50'], 'second s 50'],
              ['59', '\As\z', ['59', '59'], 'second s 59'],
              ['60', '\As\z', ['60', '60'], 'second s 60'],
              ['61', '\As\z', ['61', '61'], 'second s 61'],
              ['62', '\As\z', undef,        'second s 62'],
              [' 0', '\As\z', undef,        'second s  0'],
              [' 1', '\As\z', undef,        'second s  1'],
              [ '0', '\As\z', ['0', '0'],   'second s 0'],
              [ '1', '\As\z', ['1', '1'],   'second s 1' ],

              # '?s' : second number, 0-59
              ['00', '\A?s\z', undef,        'second ?s 00'],
              ['01', '\A?s\z', undef,        'second ?s 01'],
              ['10', '\A?s\z', ['10', '10'], 'second ?s 10'],
              ['20', '\A?s\z', ['20', '20'], 'second ?s 20'],
              ['30', '\A?s\z', ['30', '30'], 'second ?s 30'],
              ['40', '\A?s\z', ['40', '40'], 'second ?s 40'],
              ['50', '\A?s\z', ['50', '50'], 'second ?s 50'],
              ['59', '\A?s\z', ['59', '59'], 'second ?s 59'],
              ['60', '\A?s\z', ['60', '60'], 'second ?s 60'],
              ['61', '\A?s\z', ['61', '61'], 'second ?s 61'],
              ['62', '\A?s\z', undef,        'second ?s 62'],
              [' 0', '\A?s\z', [' 0', ' 0'], 'second ?s  0'],
              [' 1', '\A?s\z', [' 1', ' 1'], 'second ?s  1'],
              ['0',  '\A?s\z', undef,        'second ?s 0'],
              ['1',  '\A?s\z', undef,        'second ?s 1'],

              # Combo: H24:M:S
              ['00:00:00', 'hh:mm:ss', ['00:00:00', '00', '00', '00'], 'hh:mm:ss 00:00:00'],
              ['01:00:00', 'hh:mm:ss', ['01:00:00', '01', '00', '00'], 'hh:mm:ss 01:00:00'],
              ['10:00:00', 'hh:mm:ss', ['10:00:00', '10', '00', '00'], 'hh:mm:ss 10:00:00'],
              ['13:00:00', 'hh:mm:ss', ['13:00:00', '13', '00', '00'], 'hh:mm:ss 13:00:00'],
              ['20:00:00', 'hh:mm:ss', ['20:00:00', '20', '00', '00'], 'hh:mm:ss 20:00:00'],
              ['23:00:00', 'hh:mm:ss', ['23:00:00', '23', '00', '00'], 'hh:mm:ss 23:00:00'],
              [' 0:00:00', 'hh:mm:ss', undef,                          'hh:mm:ss  0:00:00'],
              [' 1:00:00', 'hh:mm:ss', undef,                          'hh:mm:ss  1:00:00'],
              ['24:00:00', 'hh:mm:ss', undef,                          'hh:mm:ss 24:00:00'],
              ['02:00:00', 'hh:mm:ss', ['02:00:00', '02', '00', '00'], 'hh:mm:ss 02:00:00'],
              ['02:01:00', 'hh:mm:ss', ['02:01:00', '02', '01', '00'], 'hh:mm:ss 02:01:00'],
              ['02:10:00', 'hh:mm:ss', ['02:10:00', '02', '10', '00'], 'hh:mm:ss 02:10:00'],
              ['02:20:00', 'hh:mm:ss', ['02:20:00', '02', '20', '00'], 'hh:mm:ss 02:20:00'],
              ['02:30:00', 'hh:mm:ss', ['02:30:00', '02', '30', '00'], 'hh:mm:ss 02:30:00'],
              ['02:40:00', 'hh:mm:ss', ['02:40:00', '02', '40', '00'], 'hh:mm:ss 02:40:00'],
              ['02:50:00', 'hh:mm:ss', ['02:50:00', '02', '50', '00'], 'hh:mm:ss 02:50:00'],
              ['02:59:00', 'hh:mm:ss', ['02:59:00', '02', '59', '00'], 'hh:mm:ss 02:59:00'],
              ['02:60:00', 'hh:mm:ss', undef,                          'hh:mm:ss 02:60:00'],
              ['02: 0:00', 'hh:mm:ss', undef,                          'hh:mm:ss 02: 0:00'],
              ['02:1:00' , 'hh:mm:ss', undef,                          'hh:mm:ss 02:1:00' ],
              ['13:45:00', 'hh:mm:ss', ['13:45:00', '13', '45', '00'], 'hh:mm:ss 13:45:00'],
              ['13:45:01', 'hh:mm:ss', ['13:45:01', '13', '45', '01'], 'hh:mm:ss 13:45:01'],
              ['13:45:10', 'hh:mm:ss', ['13:45:10', '13', '45', '10'], 'hh:mm:ss 13:45:10'],
              ['13:45:20', 'hh:mm:ss', ['13:45:20', '13', '45', '20'], 'hh:mm:ss 13:45:20'],
              ['13:45:30', 'hh:mm:ss', ['13:45:30', '13', '45', '30'], 'hh:mm:ss 13:45:30'],
              ['13:45:40', 'hh:mm:ss', ['13:45:40', '13', '45', '40'], 'hh:mm:ss 13:45:40'],
              ['13:45:50', 'hh:mm:ss', ['13:45:50', '13', '45', '50'], 'hh:mm:ss 13:45:50'],
              ['13:45:59', 'hh:mm:ss', ['13:45:59', '13', '45', '59'], 'hh:mm:ss 13:45:59'],
              ['13:45:60', 'hh:mm:ss', ['13:45:60', '13', '45', '60'], 'hh:mm:ss 13:45:60'],
              ['13:45:61', 'hh:mm:ss', ['13:45:61', '13', '45', '61'], 'hh:mm:ss 13:45:61'],
              ['13:45:62', 'hh:mm:ss', undef,                          'hh:mm:ss 13:45:62'],
              ['13:45: 0', 'hh:mm:ss', undef,                          'hh:mm:ss 13:45: 0'],
              ['13:45:1',  'hh:mm:ss', undef,                          'hh:mm:ss 13:45:1' ],

              # 'yy' : 2-digit year number
              ['00', 'yy', ['00', '00'], '2-digit year 00'],
              ['01', 'yy', ['01', '01'], '2-digit year 01'],
              ['90', 'yy', ['90', '90'], '2-digit year 90'],
              ['99', 'yy', ['99', '99'], '2-digit year 99'],
              ['3',  'yy', undef,  '2-digit year 3'],

              # 'yyyy' : 4-digit year number
              ['0000', 'yyyy', ['0000', '0000'], '4-digit year 0000'],
              ['1801', 'yyyy', ['1801', '1801'], '4-digit year 1801'],
              ['1990', 'yyyy', ['1990', '1990'], '4-digit year 1990'],
              ['2099', 'yyyy', ['2099', '2099'], '4-digit year 2099'],
              ['9999', 'yyyy', ['9999', '9999'], '4-digit year 9999'],
              ['30',   'yyyy', undef,    '4-digit year 30'],

              # 'mmm' : millisecond
              ['000', 'mmm', ['000', '000'], 'millisecond 000'],
              ['101', 'mmm', ['101', '101'], 'millisecond 101'],
              ['190', 'mmm', ['190', '190'], 'millisecond 190'],
              ['999', 'mmm', ['999', '999'], 'millisecond 999'],
              [  '0', 'mmm', undef,          'millisecond 0'],
              [ '01', 'mmm', undef,          'millisecond 01'],

              # 'uuuuuu' : microsecond
              ['000000', 'uuuuuu', ['000000', '000000'], 'microsecond 000000'],
              ['101101', 'uuuuuu', ['101101', '101101'], 'microsecond 101101'],
              ['999999', 'uuuuuu', ['999999', '999999'], 'microsecond 999999'],
              [  '0', 'uuuuuu', undef,                   'microsecond 0'],
              [ '01', 'uuuuuu', undef,                   'microsecond 01'],


             );

    # How many matches will succeed?
    my $to_succeed = scalar grep $_->[2], @match;

    # Run two tests per match, plus two additional per expected success
    $num_tests = 2 * scalar(@match)  +  2 * $to_succeed;
}

use Test::More tests => $num_tests;
use Regexp::Common 'time';

foreach my $match (@match)
{
    my ($text, $pattern, $matchvars, $testname) = @$match;
    my $did_succeed;
    my $should_succeed = defined $matchvars;
    my @captures;     # Regexp captures

    # FIRST: check whether it succeeded or failed as expected.
    # 'keep' option is OFF; should be no captures.
    @captures = $text =~ /$RE{time}{tf}{-pat=>$pattern}/;
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
    @captures = $text =~ /$RE{time}{tf}{-pat=>$pattern}{-keep}/;
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
