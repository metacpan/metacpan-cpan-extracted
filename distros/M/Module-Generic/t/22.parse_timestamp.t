# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use open ':std' => 'utf8';
    use utf8;
    # 2021-11-01T08:12:10
    use Test::Time time => 1635754330;
    use Test::More qw( no_plan );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

BEGIN
{
    use_ok( 'Module::Generic' ) || BAIL_OUT( 'Cannot load Module::Generic' );
};

my $o = Module::Generic->new( debug => $DEBUG );
isa_ok( $o => 'Module::Generic' );
my $ref = $o->_get_datetime_regexp;
ok( defined( $ref ) && ref( $ref ) eq 'HASH', '_get_datetime_regexp' );
SKIP:
{
    skip( "No valid value returned by _get_datetime_regexp", 16 ) if( !defined( $ref ) || ref( $ref ) ne 'HASH' );
    foreach my $k ( qw( incomplete iso8601 http non_standard date_only us_short eu_short us_long eu_long date_only_eu date_roman date_digits japan unix relative all ) )
    {
        ok( exists( $ref->{ $k } ) && ref( $ref->{ $k } ) eq 'Regexp', $k );
    }
};

my $tests =
{
    incomplete => [
        q{2019-10-03 19-44+0000} => {
            year => 2019,
            month => 10,
            day => 3,
            hour => 19,
            minute => 44,
            tz => 'UTC',
        },
        q{2019-10-03 19:44:01+0000} => {
            year => 2019,
            month => 10,
            day => 3,
            hour => 19,
            minute => 44,
            second => 1,
            tz => 'UTC',
        },
    ],
    iso8601 => [
        q{2019-06-19 23:23:57.000000000+0900} => {
            year => 2019,
            month => 6,
            day => 19,
            hour => 23,
            minute => 23,
            second => 57,
            millisecond => 0,
            offset => 32400,
        },
        q{2019-06-20 11:02:36.306917+09} => {
            year => 2019,
            month => 6,
            day => 20,
            hour => 11,
            minute => 2,
            second => 36,
            microsecond => 306917,
            offset => 32400,
            expected => q{2019-06-20 11:02:36.306917+0900},
        },
        q{2019-06-20T11:08:27} =>
        {
            year => 2019,
            month => 6,
            day => 20,
            hour => 11,
            minute => 8,
            second => 27,
        },
        q{2019-06-20 02:03:14} =>
        {
            year => 2019,
            month => 6,
            day => 20,
            hour => 2,
            minute => 3,
            second => 14,
        },
    ],
    http => [
        q{Sun, 06 Oct 2019 06:41:11 GMT} =>
        {
            year => 2019,
            month => 10,
            day => 6,
            hour => 6,
            minute => 41,
            second => 11,
            tz => 'UTC',
        },
    ],
    non_standard => [
        q{12 March 2001 17:07:30 JST} =>
        {
            year => 2001,
            month => 3,
            day => 12,
            hour => 17,
            minute => 7,
            second => 30,
            offset => 32400,
        },
        q{12-March-2001 17:07:30 JST} =>
        {
            year => 2001,
            month => 3,
            day => 12,
            hour => 17,
            minute => 7,
            second => 30,
            offset => 32400,
        },
        q{12/March/2001 17:07:30 JST} =>
        {
            year => 2001,
            month => 3,
            day => 12,
            hour => 17,
            minute => 7,
            second => 30,
            offset => 32400,
        },
        q{12 March 2001 17:07} =>
        {
            year => 2001,
            month => 3,
            day => 12,
            hour => 17,
            minute => 7,
            second => 0,
            tz => 'UTC',
        },
        q{12 March 2001 17:07 JST} =>
        {
            year => 2001,
            month => 3,
            day => 12,
            hour => 17,
            minute => 7,
            second => 0,
            offset => 32400,
        },
        q{12 March 2001 17:07:30+0900} =>
        {
            year => 2001,
            month => 3,
            day => 12,
            hour => 17,
            minute => 7,
            second => 30,
            offset => 32400,
        },
        q{12 March 2001 17:07:30 +0900} =>
        {
            year => 2001,
            month => 3,
            day => 12,
            hour => 17,
            minute => 7,
            second => 30,
            offset => 32400,
        },
        q{Monday, 12 March 2001 17:07:30 JST} =>
        {
            year => 2001,
            month => 3,
            day => 12,
            hour => 17,
            minute => 7,
            second => 30,
            offset => 32400,
        },
        q{Monday, 12 Mar 2001 17:07:30 JST} =>
        {
            year => 2001,
            month => 3,
            day => 12,
            hour => 17,
            minute => 7,
            second => 30,
            offset => 32400,
        },
        q{03/Feb/1994:00:00:00 0000} =>
        {
            year => 1994,
            month => 2,
            day => 3,
            hour => 0,
            minute => 0,
            second => 0,
            tz => 'UTC',
        },
    ],
    date_only => [
        q{2019-06-20} =>
        {
            year => 2019,
            month => 6,
            day => 20,
        },
        q{2019/06/20} =>
        {
            year => 2019,
            month => 6,
            day => 20,
        },
        q{2016.04.22} =>
        {
            year => 2016,
            month => 4,
            day => 22,
        },
    ],
    us_short => [
        q{2014, Feb 17} =>
        {
            year => 2014,
            month => 2,
            day => 17,
        },
    ],
    eu_short => [
        q{17 Feb, 2014} =>
        {
            year => 2014,
            month => 2,
            day => 17,
        },
    ],
    us_long => [
        q{February 17, 2009} =>
        {
            year => 2009,
            month => 2,
            day => 17,
        },
    ],
    eu_long => [
        q{15 July 2021} =>
        {
            year => 2021,
            month => 7,
            day => 15,
        },
    ],
    date_only_eu => [
        q{22.04.2016} =>
        {
            year => 2016,
            month => 4,
            day => 22,
        },
        q{22-04-2016} =>
        {
            year => 2016,
            month => 4,
            day => 22,
        },
        q{17. 3. 2018.} =>
        {
            year => 2018,
            month => 3,
            day => 17,
        },
    ],
    date_roman => [
        q{17.III.2020} =>
        {
            year => 2020,
            month => 3,
            day => 17,
        },
        q{17. III. 2018.} =>
        {
            year => 2018,
            month => 3,
            day => 17,
        },
    ],
    date_digits => [
        q{20030613} =>
        {
            year => 2003,
            month => 6,
            day => 13,
        },
    ],
    japan => [
        q{2021年7月14日} =>
        {
            year => 2021,
            month => 7,
            day => 14,
        },
        q{令和3年7月14日} =>
        {
            year => 2021,
            month => 7,
            day => 14,
            era => '令和',
        },
        q{2021年7月14日14時40分30秒} =>
        {
            year => 2021,
            month => 7,
            day => 14,
            hour => 14,
            minute => 40,
            second => 30,
        },
        q{2021年7月14日14時40分} =>
        {
            year => 2021,
            month => 7,
            day => 14,
            hour => 14,
            minute => 40,
            second => 0,
        },
        q{2021年7月14日14時} =>
        {
            year => 2021,
            month => 7,
            day => 14,
            hour => 14,
            minute => 0,
            second => 0,
        },
        q{令和3年7月14日14時40分30秒} =>
        {
            year => 2021,
            month => 7,
            day => 14,
            era => '令和',
            hour => 14,
            minute => 40,
            second => 30,
        },
        q{令和3年7月14日14時40分} =>
        {
            year => 2021,
            month => 7,
            day => 14,
            era => '令和',
            hour => 14,
            minute => 40,
            second => 0,
        },
        q{令和3年7月14日14時} =>
        {
            year => 2021,
            month => 7,
            day => 14,
            era => '令和',
            hour => 14,
            minute => 0,
            second => 0,
        },
        q{令和３年７月１４日１４時４０分３０秒} =>
        {
            year => 2021,
            month => 7,
            day => 14,
            era => '令和',
            hour => 14,
            minute => 40,
            second => 30,
        },
        q{２０２１年７月１４日１４時４０分３０秒} =>
        {
            year => 2021,
            month => 7,
            day => 14,
            era => '令和',
            hour => 14,
            minute => 40,
            second => 30,
        },
    ],
    unix => [
        q{1669607845} =>
        {
            year => 2022,
            month => 11,
            day => 28,
            hour => 3,
            minute => 57,
            second => 25,
            tz => 'UTC',
            millisecond => 0,
        },
        q{1669607845.5000} =>
        {
            year => 2022,
            month => 11,
            day => 28,
            hour => 3,
            minute => 57,
            second => 25,
            tz => 'UTC',
            millisecond => 500,
        },
    ],
    # Base time stamp: 2021-11-01T08:12:10
    relative => [
        q{+5Y} =>
        {
            year => 2026,
            month => 10,
            day => 31,
            hour => 8,
            minute => 12,
            second => 10,
            expected => q{2026-10-31T08:12:10},
        },
        q{+2M} =>
        {
            year => 2021,
            month => 12,
            day => 31,
            hour => 8,
            minute => 12,
            second => 10,
            expected => q{2021-12-31T08:12:10},
        },
        q{+3D} =>
        {
            year => 2021,
            month => 11,
            day => 4,
            hour => 8,
            minute => 12,
            second => 10,
            expected => q{2021-11-04T08:12:10},
        },
        q{-2h} =>
        {
            year => 2021,
            month => 11,
            day => 1,
            hour => 6,
            minute => 12,
            second => 10,
            expected => q{2021-11-01T06:12:10},
        },
        q{-4m} =>
        {
            year => 2021,
            month => 11,
            day => 1,
            hour => 8,
            minute => 8,
            second => 10,
            expected => q{2021-11-01T08:08:10},
        },
        q{-10s} =>
        {
            year => 2021,
            month => 11,
            day => 1,
            hour => 8,
            minute => 12,
            second => 0,
            expected => q{2021-11-01T08:12:00},
        },
    ],
};

foreach my $type ( sort( keys( %$tests ) ) )
{
    if( $type eq 'japan' && !$o->_load_class( 'DateTime::Format::JP' ) )
    {
        diag( "Skipping tests for \"${type}\", because module DateTime::Format::JP is not installed." );
        next;
    }
    
    # $o->debug( $DEBUG ) if( $type eq 'non_standard' );
    for( my $i = 0; $i < scalar( @{$tests->{ $type }} ); $i += 2 )
    {
        my $str = $tests->{ $type }->[$i];
        my $def = $tests->{ $type }->[$i+1];
        subtest "$type -> $str" => sub
        {
            my $dt = $o->_parse_timestamp( $str, tz => 'UTC' );
            if( !defined( $dt ) && $DEBUG )
            {
                diag( "Error parsing '$str' -> ", $o->error );
            }
            elsif( !ref( $dt ) && !length( $dt ) )
            {
                diag( "Failed to find any suitable pattern matching for '$str'" ) if( $DEBUG );
                if( $type eq 'japan' && $DEBUG )
                {
                    diag( "'japan' regexp is -> ", $ref->{japan} );
                }
            }
            isa_ok( $dt => 'DateTime' );
            SKIP:
            {
                skip( "Failed to instantiate DateTime object for test type $type and date string '$str'", ( scalar( keys( %$def ) ) + 1 ) ) if( !defined( $dt ) || !ref( $dt ) );
                my $fmt = $dt->formatter;
                diag( "Date formtter is '", ( $fmt // '' ), "'" ) if( $DEBUG );
                if( $fmt && $fmt->isa( 'DateTime::Formt::JP' ) )
                {
                    $fmt->{debug} = $DEBUG;
                }
                my $expected = delete( $def->{expected} ) // $str;
                is( "$dt", $expected, 'stringification produces original string' );
                foreach my $k ( sort( keys( %$def ) ) )
                {
                    if( $k eq 'tz' )
                    {
                        is( $dt->time_zone->name, $def->{ $k }, 'time_zone' );
                    }
                    elsif( $k eq 'era' )
                    {
                        # do nothing in fact, because DateTime does not support this
                    }
                    elsif( $dt->can( $k ) )
                    {
                        is( $dt->$k, $def->{ $k }, $k );
                    }
                    else
                    {
                        warn( "Unsupported method '$k' in DateTime for test of type $type and date string '$str'\n" );
                    }
                }
            };
        };
    }
    # $o->debug(0);
}

done_testing();

__END__
