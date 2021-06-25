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

done_testing();
