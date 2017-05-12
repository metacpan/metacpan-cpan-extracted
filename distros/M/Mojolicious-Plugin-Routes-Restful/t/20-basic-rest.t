use Test::More;
use Test::Mojo;
use lib 't/lib';

my $module = 'Mojolicious::Plugin::Routes::Restful';
use_ok($module);

my $t = Test::Mojo->new("RouteRestful");

my $routes = $t->app->routes;

use Data::Dumper;

my $project = {
    1 => {
        id       => 1,
        name     => 'project 1',
        type     => 'test type 1',
        owner    => 'Bloggs 1',
        users    => [ 'blogs 1', 'major 1' ],
        contacts => [ 'George 1', 'John 1', 'Paul 1', 'Ringo 1' ],
        planning => {
            name  => 'longterm 1',
            build => 1
        }
    },
    update1 => {
        name  => 'project 1a',
        type  => 'test type 1a',
        owner => 'Bloggs 12',
    },
    update_result1 => {
        id       => 1,
        name     => 'project 1a',
        type     => 'test type 1a',
        contacts => [ 'George 1', 'John 1', 'Paul 1', 'Ringo 1' ],
        owner    => 'Bloggs 12',
        users    => [ 'blogs 1', 'major 1' ],
        planning => {
            name  => 'longterm 1',
            build => '1'
        }
    },
    2 => {
        id       => 2,
        name     => 'project 2a',
        type     => 'test type 2a',
        owner    => 'Bloggs 2',
        users    => [ 'blogs 2', 'major 2' ],
        contacts => [ 'George 2', 'John 2', 'Paul 2', 'Ringo 2' ],
        planning => {
            name  => 'longterm 2',
            build => '2'
        }
    },
    4_1 => {
        id       => 4,
        name     => 'project 3',
        type     => 'test type 3',
        owner    => 'Bloggs 3',
        users    => [ 'blogs 3', 'major 3' ],
        contacts => [ 'George 3', 'John 3', 'Paul 3', 'Ringo 3' ],
        planning => {
            name  => 'longterm 3',
            build => '3'
        }
    },
    4_2 => {
        replace => {
            id       => 4,
            name     => 'project 3a',
            type     => 'test type 3a',
            owner    => 'Bloggs 3a',
            users    => [ 'blogs 3a', 'major 3a' ],
            contacts => [ 'George 3a', 'John 3a', 'Paul 3a', 'Ringo 3a' ],
            planning => {
                name  => 'longterm 3a',
                build => '3a'
            }
        }
    }
};

my $project_new = {
    name  => 'project 3',
    type  => 'test type 3',
    owner => 'Bloggs 3',
};

#chet the gets

$t->get_ok("/projects")->status_is(200)->json_is( '/1' => $project->{2} );
$t->get_ok("/projects/1")->status_is(200)->json_is( $project->{1} );
$t->patch_ok( "/projects/1" => form => $project->{update1} )->status_is(200);
$t->get_ok("/projects/1")->status_is(200)
  ->json_is( $project->{update_result1} );    #
$t->get_ok("/projects/4")->status_is(200)->json_is( $project->{4_1} );    #

$t->put_ok( "/projects/4" => form => $project->{3_2} )->status_is(200);
$t->get_ok("/projects/4")->status_is(200)
  ->json_is( $project->{4_2}->{replace} );                                #

$t->post_ok( "/projects" => form => $project_new )->status_is(200)->json_is(
    {
        status => 200,
        new_id => 3
    }
);
$project_new->{id} = '3';
$t->get_ok("/projects/3")->status_is(200)->json_is($project_new);
$t->delete_ok( "/projects/3" => form => $project_new )->status_is(200)
  ->json_is( { status => 200 } );
$t->get_ok("/projects/3")->status_is(404);

$t->patch_ok( "/projects/2/longdetails" => form =>
      { name => 'project 2a', type => 'test type 2a', } )->status_is(200);
$t->get_ok("/projects/2")->status_is(200)->json_is( $project->{2} );    #

$t->patch_ok(
    "/projects/2/planning" => form => {
        planning => {
            name  => 'longterm 2a',
            build => '2a'
        }
    }
)->status_is(200);

$project->{2}->{planning} = {
    name  => 'longterm 2a',
    build => '2a'
};
$t->get_ok("/projects/2")->status_is(200)->json_is( $project->{2} );    #
$t->patch_ok( "/projects/1/details" => form => { owner => 'Blogs3' } )
  ->status_is(200);
$project->{1}->{owner} = 'Blogs3';
$project->{1}->{type}  = 'test type 1a';
$project->{1}->{name}  = 'project 1a';

$t->get_ok("/projects/1")->status_is(200)->json_is( $project->{1} );    #
$t->get_ok("/projects/1/users")->status_is(200)
  ->json_is( $project->{1}->{users} );                                  #
$t->get_ok("/projects/1/contacts")->status_is(200)
  ->json_is( $project->{1}->{contacts} );                               #
$t->get_ok("/projects/1/users/1")->status_is(200)
  ->json_is( $project->{1}->{users}->[0] );                             #
$t->post_ok( "/projects/1/users" => form => { user => 'Yoko' } )->status_is(200)
  ->json_is( { status => 200, new_id => 3 } );
push( @{ $project->{1}->{users} }, 'Yoko' );
$t->get_ok("/projects/1/users/3")->status_is(200)
  ->json_is( $project->{1}->{users}->[2] );
$t->delete_ok("/projects/1/users/3")->status_is(200);
$t->get_ok("/projects/1/users/3")->status_is(404);

$t->get_ok("/projects/2/contacts/1")->status_is(200)
  ->json_is( $project->{2}->{contacts}->[0] );                          #
$t->post_ok( "/projects/2/contacts" => form => { contact => 'Yoko' } )
  ->status_is(200)->json_is( { status => 200, new_id => 5 } );
push( @{ $project->{2}->{contacts} }, 'Yoko' );
$t->get_ok("/projects/2/contacts/5")->status_is(200)
  ->json_is( $project->{2}->{contacts}->[4] );
$t->delete_ok("/projects/2/contacts/3")->status_is(200);
$t->delete_ok("/projects/2/contacts")->status_is(404);
$t->delete_ok("/projects")->status_is(404);
$t->put_ok("/projects/2/contacts")->status_is(404);
$t->put_ok("/projects")->status_is(404);

$t->get_ok("/projects/2/contacts/3")->status_is(404);

#note here '/projects/1/users/' will fail as the data is not shared across APIs
#it is only a test really

done_testing;
