#!/usr/bin/perl
BEGIN
{
    use Test::More qw( no_plan );
    use strict;
    use warnings;
    use lib './lib';
    use Module::Generic;
};

my $o = Module::Generic->new;
my $a = $o->_get_args_as_array;
is( ref( $a ), 'ARRAY', '_get_args_as_array => array ref' );
$a = $o->_get_args_as_array(qw( Hello there ));
ok( ( scalar( @$a ) == 2 and "@$a" eq 'Hello there' ), '_get_args_as_array' );
$a = $o->_get_args_as_array([qw( Hello there )]);
ok( ( scalar( @$a ) == 2 and "@$a" eq 'Hello there' ), '_get_args_as_array' );

ok( $o->_is_class_loadable( 'lib' ), '_is_class_loadable' );
# $o->debug(3);
ok( !$o->_is_class_loadable( 'lib', 99 ), '_is_class_loadable with version' );
ok( !$o->_is_class_loadable( 'NotExist' ), '_is_class_loadable for non-existing module' );
ok( $o->_is_class_loadable( 'Module::Generic::Exception' ), '_is_class_loadable' );

# DateTime
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
];

$o->debug(3);
for( my $i = 0; $i < scalar( @$dates ); $i++ )
{
    my $def = $dates->[$i];
    my $dt = $o->_parse_timestamp( $def->{test} );
    diag( "Failed to get the datetime object -> ", $o->error ) if( !defined( $dt ) );
    isa_ok( $dt, 'DateTime', "DateTime object for $def->{test}" );
    is( "$dt", $def->{expect}, "stringification for $def->{test}" );
}

done_testing();
