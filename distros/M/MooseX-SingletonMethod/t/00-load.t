#!perl -T


# stop innocent warning from Moosex Exporter about being main
package NotMain;
BEGIN {
    use Test::More tests => 1;
	use_ok( 'MooseX::SingletonMethod' );
	diag( "Testing MooseX::SingletonMethod $MooseX::SingletonMethod::VERSION, Perl $], $^X" );
    sub dummy {}
}

package main;
NotMain::dummy;