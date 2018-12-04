
=head1 DESCRIPTION

This test ensures that we can inherit from
L<Mojolicious::Plugin::DBIC::Controller::DBIC> and that it continues to
perform as expected.

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
push @{ $r->namespaces }, 'Local::Controller';
$r->get( '/notes', {
    controller => 'Extended',
    action => 'list',
    resultset => 'Notes',
    template => 'notes/list_extended',
} );
$r->get( '/notes/:id', {
    controller => 'Extended',
    action => 'get',
    resultset => 'Notes',
    template => 'notes/get_extended',
} );


$t->get_ok( '/notes' )->status_is( 200 )
  ->or( sub { diag shift->tx->res->body } )
  ->text_is( 'li:nth-child(1)' => $notes[0]->title )
  ->text_is( 'li:nth-child(2)' => $notes[1]->title )
  ->text_is( 'li:nth-child(3)' => $notes[2]->title )
  ->text_is( 'footer' => 'Extended' )
  ;

$t->get_ok( '/notes/1' )->status_is( 200 )
  ->or( sub { diag shift->tx->res->body } )
  ->text_is( 'h1' => $notes[0]->title )
  ->text_is( 'main' => $notes[0]->description )
  ->text_is( 'footer' => 'Extended' )
  ;

$t->get_ok( '/notes/12938920' )->status_is( 404 )
  ->or( sub { diag shift->tx->res->body } )
  ;

done_testing;

