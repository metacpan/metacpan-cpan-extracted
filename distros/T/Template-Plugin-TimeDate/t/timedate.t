use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;
use Test::MockTime qw(set_fixed_time);  # NEEDS to be loaded before T:P:TimeDate

use Template;
use Template::Plugin::TimeDate;

###############################################################################
# Set a fixed time, so "time stands still" while running the test.
#
# That way, we don't ever accidentally fail tests due to race conditions
# between calls to "time()" during individual tests.
set_fixed_time(CORE::time());

###############################################################################
# Make sure that TT works.
subtest 'Check TT' => sub {
    my $tt = Template->new( TRIM=>1 );
    my $template = qq{hello world};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $template, 'TT works' );
};

###############################################################################
# Load TimeDate plugin.
subtest 'Load TimeDate plugin' => sub {
    my $tt = Template->new( TRIM=>1 );
    my $template = qq{
[%- USE TimeDate -%]
hello world
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, 'hello world', 'TT plugin loaded' );
};

###############################################################################
# Get current time (as seconds since the epoch).
subtest 'Get current time' => sub {
    my $tt = Template->new( TRIM=>1 );
    my $epoch = time();
    my $template = qq{
[%- USE TimeDate -%]
[%- TimeDate.now -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $epoch, 'get current time' );
};

###############################################################################
# Query current time (as seconds since the epoch).
subtest 'Get current epoch time' => sub {
    my $tt = Template->new( TRIM=>1 );
    my $epoch = time();

    my $template = qq{
[%- USE TimeDate -%]
[%- TimeDate.epoch -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $epoch, 'query time' );
};

###############################################################################
# Parse a given date/time, with embedded time zone.
subtest 'Parse date/time, with embedded timezone' => sub {
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
};

###############################################################################
# Format date/time, with explicit time zone.
subtest 'Format date/time, with explicit timezone' => sub {
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
};

###############################################################################
# Parse/format with explicit time zones.
subtest 'Parse/format date/time, with explicit timezone' => sub {
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
};

###############################################################################
# Default name
subtest 'Default plugin name' => sub {
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
};

###############################################################################
# Parse on instantiation
subtest 'Parse date/time during instantiation' => sub {
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
};

###############################################################################
# Multiple TimeDate objects
subtest 'Multiple TimeDate objects' => sub {
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
};

###############################################################################
# Alternate method names
subtest 'Alternate method names' => sub {
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
};

###############################################################################
done_testing();
