use Test::More;
use Test::Mojo;
use lib 't/lib';

my $module = 'Mojolicious::Plugin::Routes::Restful';
use_ok($module);

my $t = Test::Mojo->new("RoutesAdvanced");

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
    4_1=> {
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
    4_2 =>{replace=> {
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
    }}
};

my $project_new = {
    name  => 'project 3',
    type  => 'test type 3',
    owner => 'Bloggs 3',
};



  # $t->get_ok("/V_1/myapp/paper")->status_is(200); #->json_is( '/1' => $project->{2} );
  # $t->get_ok("/V_1/myapp/paper/1")->status_is(200);#->json_is( $project->{1} );

  # $t->get_ok("/V_1/myapp/project/1/my_details")->status_is(200); #->json_is( '/1' => $project->{2} );
  # $t->get_ok("/V_1/myapp/project/1/my_details/2")->status_is(404);#->json_is( $project->{1} );
  # $t->get_ok("/V_1/myapp/project/1/planning")->status_is(200);#->json_is( $project->{1} );
  # $t->get_ok("/V_1/myapp/project/1/planning/2")->status_is(404);#->json_is( $project->{1} );
  
  $t->get_ok("/V_1/myapp/project/1/view_users")->status_is(200);#->json_is( $project->{1} );

  $t->get_ok("/V_1/myapp/project/1/view_users/1")->status_is(200);#->json_is( $project->{1} );
  
#it is only a test really

done_testing;
