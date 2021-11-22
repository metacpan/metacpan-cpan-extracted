package Tester::Controller::Example::Tester;
use Mojo::Base 'Mojolicious::Controller';
sub Tester { shift->render( text => 'OK' ); }
sub Post { shift->render( text => 'OK' ); };
sub Any { shift->render( text => 'OK' ); };
1;
