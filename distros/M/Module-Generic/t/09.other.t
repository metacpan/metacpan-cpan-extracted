#!/usr/bin/perl
BEGIN
{
    use Test::More qw( no_plan );
    use strict;
    use warnings;
    use lib './lib';
    use Module::Generic;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

my $o = Module::Generic->new( debug => $DEBUG );
my $a = $o->_get_args_as_array;
is( ref( $a ), 'ARRAY', '_get_args_as_array => array ref' );
$a = $o->_get_args_as_array(qw( Hello there ));
ok( ( scalar( @$a ) == 2 and "@$a" eq 'Hello there' ), '_get_args_as_array' );
$a = $o->_get_args_as_array([qw( Hello there )]);
ok( ( scalar( @$a ) == 2 and "@$a" eq 'Hello there' ), '_get_args_as_array' );

my $stack = &get_frames_stack( $o );
diag( "Frames stack is: ", $stack->as_string ) if( $DEBUG );
isa_ok( $stack, 'Devel::StackTrace', '_get_stack_trace returned object is Devel::StackTrace' );
my $frame = $stack->frame(0);
isa_ok( $frame, 'Devel::StackTrace::Frame' );
is( $frame->filename, __FILE__, 'last frame filename' );

ok( $o->_is_class_loadable( 'lib' ), '_is_class_loadable' );
# $o->debug(3);
ok( !$o->_is_class_loadable( 'lib', 99 ), '_is_class_loadable with version' );
ok( !$o->_is_class_loadable( 'NotExist' ), '_is_class_loadable for non-existing module' );
ok( $o->_is_class_loadable( 'Module::Generic::Exception' ), '_is_class_loadable' );
ok( $o->_is_class_loaded( 'Module::Generic::File' ), '_is_loaded Module::Generic::File' );
ok( !$o->_is_class_loaded( 'My::Module' ), '_is_loaded My::Module' );
my $rv = $o->_load_class( 'Module::Generic::File', qw( file cwd ), { caller => 'main' } );
diag( "Unable to load Module::Generic::File: ", $o->error ) if( $DEBUG && !defined( $rv ) );
ok( $rv, '_load_class Module::Generic::File' );

# DateTime
subtest 'parse datetime' => sub
{
    my $dates = [
        {
        test    => '2019-10-03 19-44+0000',
        expect  => '2019-10-03 19-44+0000',
        },
        {
        test    => '2019-10-03 19:44:01+0000',
        expect  => '2019-10-03 19:44:01+0000',
        },
        {
        test    => '2019-06-19 23:23:57.000000000+0900',
        expect  => '2019-06-19 23:23:57.000000000+0900',
        },
        {
        test    => '2019-06-20 11:02:36.306917+09',
        expect  => '2019-06-20 11:02:36.306917+0900',
        },
        {
        test    => '2019-06-20T11:08:27',
        expect  => '2019-06-20T11:08:27',
        },
        {
        test    => '2019-06-20 02:03:14',
        expect  => '2019-06-20 02:03:14',
        },
        {
        test    => '2019-06-20',
        expect  => '2019-06-20',
        },
        {
        test    => '2019/06/20',
        expect  => '2019/06/20',
        },
        {
        test    => '2016.04.22',
        expect  => '2016.04.22',
        },
        {
        test    => '1626475051',
        expect  => '1626475051',
        },
        {
        test    => '2014, Feb 17',
        expect  => '2014, Feb 17',
        },
        {
        test    => '17 Feb, 2014',
        expect  => '17 Feb, 2014',
        },
        {
        test    => 'February 17, 2009',
        expect  => 'February 17, 2009',
        },
        {
        test    => '15 July 2021',
        expect  => '15 July 2021',
        },
        {
        test    => '22 April 2016',
        expect  => '22 April 2016',
        },
        {
        test    => '22.04.2016',
        expect  => '22.04.2016',
        },
        {
        test    => '22-04-2016',
        expect  => '22-04-2016',
        },
        {
        test    => '17. 3. 2018.',
        expect  => '17. 3. 2018.',
        },
        {
        test    => '20030613',
        expect  => '20030613',
        },
        {
        test    => '17.III.2020',
        expect  => '17.III.2020',
        },
        {
        test    => '17. III. 2018.',
        expect  => '17. III. 2018.',
        },
        # proposed new HTTP format
        {
        test    => 'Thu, 03 Feb 1994 00:00:00 GMT',
        expect  => 'Thu, 03 Feb 1994 00:00:00 GMT'
        },
        # old rfc850 HTTP format
        {
        test    => 'Thursday, 03-Feb-94 00:00:00 GMT',
        expect  => 'Thursday, 03-Feb-94 00:00:00 GMT',
        },
        # broken rfc850 HTTP format
        {
        test    => 'Thursday, 03-Feb-1994 00:00:00 GMT',
        expect  => 'Thursday, 03-Feb-1994 00:00:00 GMT',
        },
        # common logfile format
        {
        test    => '03/Feb/1994 00:00:00 0000',
        expect  => '03/Feb/1994 00:00:00 0000',
        },
        # common logfile format
        {
        test    => '03/Feb/1994 01:00:00 +0100',
        expect  => '03/Feb/1994 01:00:00 +0100',
        },
        # common logfile format
        {
        test    => '02/Feb/1994 23:00:00 -0100',
        expect  => '02/Feb/1994 23:00:00 -0100',
        },
        # HTTP format (no weekday)
        {
        test    => '03 Feb 1994 00:00:00 GMT',
        expect  => '03 Feb 1994 00:00:00 GMT',
        },
        # old rfc850 (no weekday)
        {
        test    => '03-Feb-94 00:00:00 GMT',
        expect  => '03-Feb-94 00:00:00 GMT',
        },
        # broken rfc850 (no weekday)
        {
        test    => '03-Feb-1994 00:00:00 GMT',
        expect  => '03-Feb-1994 00:00:00 GMT',
        },
        # broken rfc850 (no weekday, no seconds)
        {
        test    => '03-Feb-1994 00:00 GMT',
        expect  => '03-Feb-1994 00:00 GMT',
        },
        # VMS dir listing format
        {
        test    => '03-Feb-1994 00:00',
        expect  => '03-Feb-1994 00:00',
        }
    ];

    for( my $i = 0; $i < scalar( @$dates ); $i++ )
    {
        my $def = $dates->[$i];
        my $dt = $o->_parse_timestamp( $def->{test} );
        diag( "Failed to get the datetime object -> ", $o->error ) if( !defined( $dt ) );
        isa_ok( $dt, 'DateTime', "DateTime object for $def->{test}" );
        is( "$dt", $def->{expect}, "stringification for $def->{test}" );
    }
};

my $ip4 = [qw(
    10.0.2.1 192.168.0.31/32 128.0.0.0/1 0.0.0.0/0 192.168.0.1 192.168.0.0/24
    255.0.128.23
    1.1.1.1
    255.255.255.255
    255.0.128.23
)];

my $ip4_fail = [qw(
    256.0.128.23
    255.0.1287.23
    255.a.127.23
    255 0 127 23
    255,0,127,23
    255012723
)];

my $ip6 = [qw(
    2001:db8:2::1
    fe80:0:120::/44
    1:1:000f:01:65:e:1111:eeee
    2001:0db8:85a3:0000:0000:8a2e:0370:7334
    2001:db8:85a3:0:0:8a2e:370:7334
    2001:DB8:85A3:0:0:8A2E:370:7334
    2001:Db8:85A3:0:0:8a2E:370:7334
    2001:db8:85a3::8a2e:370:7334
    2001:db8::8a2e:370:7334
    ::8a2e:370:7334
    ::370:7334
    ::7334
    ::
)];

my $ip6_fail = [qw(
    ::ffff:192.168.0.0/120
    ::ffff:192.168.0.1
    2001:0db8:85a3:0000:0000:8a2e:0370:7334:1234
    2001:0db8:85a3:0000:0000:8a2e:0370
    20013:db8:85a3:0:0:8a2e:370:7334
    2001:0db8:85a3:0000:0000:8a2e:0370:7334:
    :2001:0db8:85a3:0000:0000:8a2e:0370:7334
    2001:db8:85a3:0::8a2e:370:7334
    2001::8a2e:370::7334
    2001:::8a2e:370:7334
    2001.db8.85a3.0.0.8a2e.370.7334
)];

diag( "Testing good IPv4 address" ) if( $DEBUG );
for( @$ip4 )
{
    ok( $o->_is_ip( $_ ), "good ip -> $_" );
}

diag( "Testing bad IPv4 address" ) if( $DEBUG );
for( @$ip4_fail )
{
    ok( !$o->_is_ip( $_ ), "bad ip -> $_" );
}

diag( "Testing good IPv6 address" ) if( $DEBUG );
for( @$ip6 )
{
    ok( $o->_is_ip( $_ ), "good ip -> $_" );
}

diag( "Testing bad IPv6 address" ) if( $DEBUG );
for( @$ip6_fail )
{
    ok( !$o->_is_ip( $_ ), "bad ip -> $_" );
}


sub get_frames_stack
{
    my $obj = shift( @_ );
    return( $obj->_get_stack_trace );
}

done_testing();
