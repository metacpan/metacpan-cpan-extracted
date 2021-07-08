
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
}, 'notes.list' );
$r->get( '/notes/paged/:page', {
    page => 1,
    limit => 1,
    controller => 'DBIC',
    action => 'list',
    resultset => 'Notes',
    template => 'notes/list',
}, 'notes.paged' );
$r->any( [ 'GET', 'POST' ], '/notes/new', {
    controller => 'DBIC',
    action => 'set',
    resultset => 'Notes',
    template => 'notes/edit',
    forward_to => 'notes.get',
}, 'notes.create' );
$r->get( '/notes/:id', {
    controller => 'DBIC',
    action => 'get',
    resultset => 'Notes',
    template => 'notes/get',
}, 'notes.get' );
$r->any( [ 'GET', 'POST' ], '/notes/:id/edit', {
    controller => 'DBIC',
    action => 'set',
    resultset => 'Notes',
    template => 'notes/edit',
    forward_to => 'notes.get',
}, 'notes.edit' );
$r->any( [ 'GET', 'POST' ], '/notes/:id/delete', {
    controller => 'DBIC',
    action => 'delete',
    resultset => 'Notes',
    template => 'notes/delete',
    forward_to => 'notes.list',
}, 'notes.delete' );

$t->get_ok( '/notes' )->status_is( 200 )
  ->or( sub { diag shift->tx->res->body } )
  ->text_is( 'li:nth-child(1)' => $notes[0]->title )
  ->text_is( 'li:nth-child(2)' => $notes[1]->title )
  ->text_is( 'li:nth-child(3)' => $notes[2]->title )
  ;

$t->get_ok( '/notes/paged' )->status_is( 200 )
  ->or( sub { diag shift->tx->res->body } )
  ->text_is( 'li:nth-child(1)' => $notes[0]->title )
  ->element_exists_not( 'li:nth-child(2)' => 'only one row shown' )
  ;

$t->get_ok( '/notes/paged/2' )->status_is( 200 )
  ->or( sub { diag shift->tx->res->body } )
  ->text_is( 'li:nth-child(1)' => $notes[1]->title )
  ->element_exists_not( 'li:nth-child(2)' => 'only one row shown' )
  ;

$t->get_ok( '/notes/paged', form => { '$order_by' => 'desc:id' } )->status_is( 200 )
  ->or( sub { diag shift->tx->res->body } )
  ->text_is( 'li:nth-child(1)' => $notes[2]->title )
  ->element_exists_not( 'li:nth-child(2)' => 'only one row shown' )
  ;

$t->get_ok( '/notes/1' )->status_is( 200 )
  ->or( sub { diag shift->tx->res->body } )
  ->text_is( 'h1' => $notes[0]->title )
  ->text_is( 'main' => $notes[0]->description )
  ;

$t->get_ok( '/notes/12938920' )->status_is( 404 )
  ->or( sub { diag shift->tx->res->body } )
  ;

$t->get_ok( '/notes/new' )->status_is( 200 )
  ->element_exists( 'form', 'form exists' )
  ->element_exists( 'input[name=title]', 'title input exists' )
  ->element_exists( 'input[name=csrf_token]', 'CSRF token exists' )
  ->element_exists( 'textarea[name=description]', 'description input exists' )
  ->element_exists( 'input[type=submit]', 'submit button exists' )
  ;

$t->get_ok( '/notes/new?title=New%20Item' )->status_is( 200 )
  ->element_exists( 'form', 'form exists' )
  ->element_exists( 'input[name=csrf_token]', 'CSRF token exists' )
  ->element_exists( 'input[name=title]', 'title input exists' )
  ->element_exists( 'input[name=title][value="New Item"]', 'title input value correct' )
  ->element_exists( 'textarea[name=description]', 'description input exists' )
  ->element_exists( 'input[type=submit]', 'submit button exists' )
  ;

my $csrf_token = $t->tx->res->dom->at( 'input[name=csrf_token]' )->attr( 'value' );
my %data = (
    title => 'New title',
    description => 'My new note',
    csrf_token => $csrf_token,
);
$t->post_ok( '/notes/new', form => \%data )->status_is( 302 )
  ->header_like( Location => qr{^/notes/\d+$} );

# Row in the database exists
my $location = $t->tx->res->headers->location;
my ( $id ) = $location =~ m{^/notes/(\d+)$};
my $row = $schema->resultset( 'Notes' )->find( $id );
ok $row, 'row exists';
is $row->title, $data{title}, 'title is correct';
is $row->description, $data{description}, 'description is correct';

$t->get_ok( "/notes/$id/edit" )->status_is( 200 )
  ->element_exists( 'form', 'form exists' )
  ->element_exists( 'input[name=title][value="' . $row->title . '"]', 'title input exists with value' )
  ->element_exists( 'input[name=csrf_token]', 'CSRF token exists' )
  ->element_exists( 'textarea[name=description]', 'description input exists' )
  ->text_is( 'textarea', $row->description, 'description input value correct' )
  ->element_exists( 'input[type=submit]', 'submit button exists' )
  ;

$t->get_ok( "/notes/$id/edit?title=New%20Item" )->status_is( 200 )
  ->element_exists( 'form', 'form exists' )
  ->element_exists( 'input[name=csrf_token]', 'CSRF token exists' )
  ->element_exists( 'input[name=title]', 'title input exists' )
  ->element_exists( 'input[name=title][value="New Item"]', 'title input value correct' )
  ->element_exists( 'textarea[name=description]', 'description input exists' )
  ->element_exists( 'input[type=submit]', 'submit button exists' )
  ;

$csrf_token = $t->tx->res->dom->at( 'input[name=csrf_token]' )->attr( 'value' );
%data = (
    title => 'Changed',
    description => 'Changed text',
    csrf_token => $csrf_token,
);
$t->post_ok( "/notes/$id/edit", form => \%data )->status_is( 302 )
  ->header_like( Location => qr{^/notes/\d+$} );

# Row in the database is updated
$location = $t->tx->res->headers->location;
( $id ) = $location =~ m{^/notes/(\d+)$};
$row = $schema->resultset( 'Notes' )->find( $id );
ok $row, 'row exists';
is $row->title, $data{title}, 'title is correct';
is $row->description, $data{description}, 'description is correct';
$t->get_ok( "/notes/$id/delete" )->status_is( 200 )
  ->element_exists(
    "form[action=/notes/$id] input[type=submit]",
    'button to cancel exists',
  )
  ->element_exists(
    "form[action=/notes/$id/delete][method=POST] input[type=submit]",
    'button to delete exists',
  )
  ->or( sub { diag shift->tx->res->dom->find( 'form' )->each } )
  ;
%data = (
    csrf_token => $csrf_token,
);
$t->post_ok( "/notes/$id/delete", form => \%data )->status_is( 302 )
  ->header_is( Location => '/notes' )
  ;
ok !$schema->resultset( 'Notes' )->find( $id ), 'row no longer exists';

done_testing;
