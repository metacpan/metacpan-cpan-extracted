#!/usr/bin/perl

use Test::More tests => 2;

BEGIN { use_ok( 'ORM::Error' ); }

our $error = ORM::Error->new;

sub get_error { $error->add_fatal( $_[0] ); }
sub get_complex_error
{
    my $my_error = ORM::Error->new;
    $my_error->add_fatal( $_[0] );
    $error->add( error=>$my_error );
}

$error->add_fatal( 'Error in main' );
$error->add( type=>'fatal', comment=>'Full Error in main' );
get_error( 'Error in main::get_error()' );
get_complex_error( 'Error in main::get_complex_error()' );

package AAA;

$error->add_fatal( 'Error in AAA' );
main::get_error( 'Error in main::get_error()' );

package main;

ok
(
    (
        $error->text eq
        ( "fatal: main->main(): Error in main\n"
        . "fatal: main->main(): Full Error in main\n"
        . "fatal: main->get_error(): Error in main::get_error()\n"
        . "fatal: main->get_complex_error(): Error in main::get_complex_error()\n"
        . "fatal: AAA->main(): Error in AAA\n"
        . "fatal: AAA->main::get_error(): Error in main::get_error()\n" )
    ),
    'complex'
);
