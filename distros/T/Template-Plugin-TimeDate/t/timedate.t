use strict;
use warnings;
use Template;
use Test::More tests => 12;
BEGIN { use_ok('Template::Plugin::TimeDate') };

###############################################################################
# Make sure that TT works.
check_tt: {
    my $tt = Template->new( TRIM=>1 );
    my $template = qq{hello world};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $template, 'TT works' );
}

###############################################################################
# Load TimeDate plugin.
load_plugin: {
    my $tt = Template->new( TRIM=>1 );
    my $template = qq{
[%- USE TimeDate -%]
hello world
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, 'hello world', 'TT plugin loaded' );
}

###############################################################################
# Get current time (as seconds since the epoch).
get_now: {
    my $tt = Template->new( TRIM=>1 );
    my $epoch = time();
    my $template = qq{
[%- USE TimeDate -%]
[%- TimeDate.now -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $epoch, 'get current time' );
}

###############################################################################
# Query current time (as seconds since the epoch).
query_time: {
    my $tt = Template->new( TRIM=>1 );
    my $epoch = time();
    my $template = qq{
[%- USE TimeDate -%]
[%- TimeDate.epoch -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $epoch, 'query time' );
}

###############################################################################
# Parse a given date/time, with embedded time zone.
parse_with_embedded_timezone: {
    my $tt = Template->new( TRIM=>1 );
    my $when   = '2007-09-02 12:34:56 EDT';
    my $expect = Date::Parse::str2time($when);
    my $template = qq{
[%- USE TimeDate -%]
[%- TimeDate.parse('$when').epoch -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expect, 'parse date/time with embedded time zone' );
}

###############################################################################
# Format date/time, with explicit time zone.
format_with_explicit_timezone: {
    my $tt = Template->new( TRIM=>1 );
    my $when     = '2007-09-02 12:34:56 EDT';
    my $zone_out = 'GMT';
    my $format   = '%Y-%m-%d %H:%M:%S %Z';
    my $expect   = '2007-09-02 16:34:56 GMT';
    my $template = qq{
[%- USE TimeDate -%]
[%- TimeDate.parse('$when').format('$format','$zone_out') -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expect, 'format date/time with explicit time zone' );
}

###############################################################################
# Parse/format with explicit time zones.
parse_format_explicit_timezone: {
    my $tt = Template->new( TRIM=>1 );
    my $when     = '2007-09-02 12:34:56';
    my $zone_in  = 'CDT';
    my $zone_out = 'GMT';
    my $format   = '%Y-%m-%d %H:%M:%S %Z';
    my $expect   = '2007-09-02 17:34:56 GMT';
    my $template = qq{
[%- USE TimeDate -%]
[%- TimeDate.parse('$when','$zone_in').format('$format','$zone_out') -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expect, 'parse/format with explicit time zone' );
}

###############################################################################
# Default name
default_name: {
    my $tt = Template->new( TRIM=>1 );
    my $when   = '2007-09-02 12:34:56 EDT';
    my $expect = Date::Parse::str2time($when);
    my $template = qq{
[%- USE TimeDate -%]
[%- CALL TimeDate.parse('$when') -%]
[%- TimeDate.epoch %]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expect, 'default name for TimeDate object' );
}

###############################################################################
# Parse on instantiation
parse_on_instantiation: {
    my $tt = Template->new( TRIM=>1 );
    my $when   = '2007-09-02 12:34:56 EDT';
    my $expect = Date::Parse::str2time($when);
    my $template = qq{
[%- USE mydate = TimeDate('$when') -%]
[%- mydate.epoch -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expect, 'parse on instantiation' );
}

###############################################################################
# Multiple TimeDate objects
multiple_timedate_objects: {
    my $tt = Template->new( TRIM=>1 );
    my $when_one = '2007-09-02 12:34:56 EDT';
    my $when_two = '2006-12-31 00:00:00 GMT';
    my $zone_out = 'PDT';
    my $format   = '%Y-%m-%d %H:%M:%S';
    my $expect   = '2007-09-02 09:34:56|2006-12-30 17:00:00';
    my $template = qq{
[%- USE one = TimeDate -%]
[%- USE two = TimeDate -%]
[%- one.parse('$when_one').format('$format','$zone_out') -%]
|
[%- two.parse('$when_two').format('$format','$zone_out') -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expect, 'multiple timedate objects' );
}

###############################################################################
# Alternate method names
alternate_method_names: {
    my $tt = Template->new( TRIM=>1 );
    my $when     = '2007-09-02 12:34:56 EDT';
    my $zone_out = 'GMT';
    my $format   = '%Y-%m-%d %H:%M:%S %Z';
    my $expect   = '2007-09-02 16:34:56 GMT';
    my $template = qq{
[%- USE TimeDate -%]
[%- TimeDate.str2time('$when').time2str('$format','$zone_out') -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expect, 'alternate method names' );
}
