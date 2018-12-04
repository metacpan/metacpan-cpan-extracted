
=head1 DESCRIPTION

This tests the Mojolicious::Plugin::DBIC::Controller::DBIC class

=cut

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin qw( $Bin );
use lib "$Bin/lib";

use Local::Schema;
my $schema = Local::Schema->connect( 'dbi:SQLite::memory:' );
$schema->deploy;

my @notes = $schema->resultset( 'Notes' )->populate([
    {
        title => 'Mojolicious',
        description => 'A Perl 5 web framework',
    },
    {
        title => 'Yancy',
        description => 'A CMS for Mojolicious',
    },
    {
        title => 'Mercury',
        description => 'A WebSocket message broker',
    },
]);

$ENV{MOJO_HOME} = $Bin;
my $t = Test::Mojo->new( 'Mojolicious' );
$t->app->plugin( DBIC => { schema => $schema } );

my $r = $t->app->routes;
$r->get( '/notes', {
    controller => 'DBIC',
    action => 'list',
    resultset => 'Notes',
    template => 'notes/list',
} );
$r->get( '/notes/:id', {
    controller => 'DBIC',
    action => 'get',
    resultset => 'Notes',
    template => 'notes/get',
} );


$t->get_ok( '/notes' )->status_is( 200 )
  ->or( sub { diag shift->tx->res->body } )
  ->text_is( 'li:nth-child(1)' => $notes[0]->title )
  ->text_is( 'li:nth-child(2)' => $notes[1]->title )
  ->text_is( 'li:nth-child(3)' => $notes[2]->title )
  ;

$t->get_ok( '/notes/1' )->status_is( 200 )
  ->or( sub { diag shift->tx->res->body } )
  ->text_is( 'h1' => $notes[0]->title )
  ->text_is( 'main' => $notes[0]->description )
  ;

$t->get_ok( '/notes/12938920' )->status_is( 404 )
  ->or( sub { diag shift->tx->res->body } )
  ;

done_testing;
