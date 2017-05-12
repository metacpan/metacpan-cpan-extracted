package Pulp;

use warnings;
use strict;
use true;
use Text::ASCIITable;
use FindBin;
use Module::Find 'useall';
use base 'Kelp';

our $VERSION = '0.001';

sub import {
    my ($class, %opts) = @_;
    strict->import();
    warnings->import();
    true->import();
    my $caller = caller;
    my $routes = [];
    my $configs = {};
    my $auto    = 0;
    {
        no strict 'refs';
        push @{"${caller}::ISA"}, 'Kelp';
         # check args
        # v2
        if ($opts{"-v2"}) {
            my $con_tb = Text::ASCIITable->new({ headingText => 'Controllers' });
            $con_tb->setCols('Action', 'Path');
            my @conts = useall "${caller}::Controller";
            for my $mod (@conts) {
                my $actions = $mod->_actions;
                foreach my $action (keys %$actions) {
                    $con_tb->addRow($action, $actions->{$action});
                }
            }

            print $con_tb . "\n";
        }

        # auto load routes?
        my @in_mods;
        if ($opts{"extends"}) {
            @in_mods = useall $opts{"extends"} . "::Route";
        }

        if ($opts{"-auto"} || $opts{"extends"}) {
            $auto = 1;
            my $route_tb = Text::ASCIITable->new;
            $route_tb->setCols('Routes');
            my @mod_routes = useall "${caller}::Route";
            for my $mod (@mod_routes) {
                $route_tb->addRow($mod);
                push @$routes, $mod->get_routes();
            }

            if (@in_mods) {
                for my $mod (@in_mods) {
                    $route_tb->addRow($mod);
                    push @$routes, $mod->get_routes();
                }
            }

            print $route_tb . "\n";
        }

        *{"${caller}::new"} = sub { return shift->SUPER::new(@_); };
        *{"${caller}::maps"} = sub {
            die "Please don't use -auto and maps at the same time\n"
                if $auto;

            my ($route_names) = @_;
            unless (ref $route_names eq 'ARRAY') {
                die "routes() expects an array references";
            }

            my $route_tb = Text::ASCIITable->new;
            $route_tb->setCols('Routes');
            for my $mod (@$route_names) {
                my $route_path = "${caller}::Route::${mod}";
                eval "use $route_path;";
                if ($@) {
                    warn "Could not load route ${route_path}: $@";
                    next;
                }

                $route_tb->addRow($route_path);
                push @$routes, $route_path->get_routes();
            }

            print $route_tb . "\n";
        };

        *{"${caller}::model"} = sub {
            my ($self, $model) = @_;
            return $self->{_models}->{$model};
        };

        *{"${caller}::path_to"} = sub { return $FindBin::Bin; };

        *{"${caller}::cfg"} = sub {
            my ($key, $hash) = @_;
            $configs->{$key} = $hash;
        };

        *{"${caller}::build"} = sub {
            my ($self) = @_;
            my $config = $self->config_hash;
            # config
            if (scalar keys %$configs > 0) {
                for my $key (keys %$configs) {
                    $config->{"+${key}"} = $configs->{$key};
                }
            }
                    
            # models
            if ($config->{models}) {
                $self->{_models} = {};
                my $model_tb = Text::ASCIITable->new;
                $model_tb->setCols('Model', 'Alias');
                unless (ref $config->{models} eq 'HASH') {
                    die "config: models expects a hash reference\n";
                }

                for my $model (keys %{$config->{models}}) {
                    my $name = $model;
                    my $opts = $config->{models}->{$model}; 
                    my $mod  = $opts->{model};
                    eval "use $mod;";
                    if ($@) {
                        die "Could not load model $mod: $@";
                    }

                    my @args = @{$opts->{args}};
                    if (my $ret = $mod->build(@args)) {
                        if (ref $ret) {
                            $model_tb->addRow($mod, $name);
                            # returned a standard hash reference
                            if (ref $ret eq 'HASH') {
                                foreach my $key (keys %$ret) {
                                    if (ref $ret->{$key}) {
                                        $self->{_models}->{"${name}::${key}"} = $ret->{$key};
                                        $model_tb->addRow(ref $ret->{$key}, "${name}::${key}");
                                    }
                                }
                            }
                            else { 
                                $self->{_models}->{"${name}"} = $ret;

                                # is this dbix::class?
                                require mro;
                                my $dbref = ref $ret;
                                if (grep { $_ eq 'DBIx::Class::Schema' } @{mro::get_linear_isa($dbref)}) {
                                    if ($dbref->can('sources')) {
                                        my $use_api = $mod->_use_api;
                                        my @sources = $dbref->sources;
                                        for my $source (@sources) {
                                            $self->{_models}->{"${name}::${source}"} = $ret->resultset($source);
                                            $model_tb->addRow("${dbref}::ResultSet::${source}", "${name}::${source}");

                                            if ($use_api) {
                                                my $lc_source = lc $source;
                                                $self->routes->add(['GET' => "/api/${lc_source}/list" ], { to => sub {
                                                    my ($aself) = @_;
                                                    my @data;
                                                    my @users = $aself->model("${name}::${source}")->all;
                                                    for my $user (@users) {
                                                        my %usr_data = $user->get_columns;
                                                        push @data, \%usr_data;
                                                    }

                                                    return \@data;
                                                }});

                                                $self->routes->add(['GET' => "/api/${lc_source}/find/:id"], { to => sub {
                                                    my ($aself, $id) = @_;
                                                    my %data = $aself->model("${name}::${source}")->find($id)->get_columns;
                                                    return \%data;
                                                }});

                                                $self->routes->add(['GET' => "/api/${lc_source}/search"], { to => sub {
                                                    my ($aself) = @_;
                                                    my @users = $aself->model("${name}::${source}")
                                                        ->search({ map { $_ => $aself->param($_) } $aself->param });
                                                    my @data;
                                                    for my $user (@users) {
                                                        my %usr_data = $user->get_columns;
                                                        push @data, \%usr_data;
                                                    }

                                                    return \@data;
                                                }});
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        else {
                            die "Did not return a valid object from models build(): $name\n";
                        }
                    }
                    else {
                        die "build() failed: $mod";
                    }
                }

                if (scalar keys %{$self->{_models}} > 0) {
                    print $model_tb . "\n";
                }
            }
            # routes
            my $r = $self->routes;
            for my $route (@$routes) {
                for my $url (keys %$route) {
                    if ($route->{$url}->{bridge}) {
                        $r->add([ uc($route->{$url}->{type}) => $url ], { to => $route->{$url}->{coderef}, bridge => 1 });
                    }
                    elsif ($route->{$url}->{type} eq 'any') {
                        $r->add($url, $route->{$url}->{coderef});
                    }
                    else {
                        $r->add([ uc($route->{$url}->{type}) => $url ], $route->{$url}->{coderef});
                    }
                }
            }
        };

        *{"${caller}::detach"} = sub {
            my ($self) = @_;

            my @caller = caller(1);
            my $fullpath = $caller[3];
            my $name;
            if ($fullpath =~ /.+::(.+)$/) {
                $name = $1;
            }

            if ($name) {
                print "[debug] Rendering template: $name\n" if $ENV{KELPX_SWEET_DEBUG};
                $self->template($name, $self->stash);
            }    
        };

        # if 'has' is not available (ie: no Moose, Moo, Mouse, etc), then import our own small version
        unless ($caller->can('has')) {
            *{"${caller}::has"} = \&_has;
        }

        # if 'around' is not available, import a small version of our own
        {
            no warnings 'redefine';
            unless ($caller->can('around')) {
                *{"${caller}::around"} = sub {
                    my ($method, $code) = @_;

                    my $fullpkg  = "${caller}::${method}";
                    my $old_code = \&$fullpkg; 
                    *{"${fullpkg}"} = sub {
                          $code->($old_code, @_);
                    };
                };
            }
        }
    }
}

sub _has {
    my ($acc, %attrs) = @_;
    my $class = caller;
    my $ro = 0;
    my $rq = 0;
    my $df;
    if (%attrs) {
        if ($attrs{is} eq 'ro') { $ro = 1; }
        if ($attrs{required}) { $rq = 1; }
        if ($attrs{default}) { $df = $attrs{default}; }

        if ($df) {
            die "has: default expects a code reference\n"
                unless ref $df eq 'CODE';
        }
    }
    
    {
        no strict 'refs';
        *{"${class}::${acc}"} = sub {
            #if ($attrs{default}) { $_[0]->{$name} = $attrs{default}; }
            if ($rq and not $df) {
                if (not $_[0]->{$acc} and not $_[1]) {
                    die "You attempted to use a field that can't be left blank: ${acc}";
                }
            }

            if ($df) { $_[0]->{$acc} = $df->(); }
        
            if (@_ == 2) {
                die "Can't modify a readonly accessor: ${acc}"
                    if $ro;
                $_[0]->{$acc} = $_[1];
            }
            return $_[0]->{$acc};
        };
    }
}

sub new {
    bless { @_[ 1 .. $#_ ] }, $_[0];
}

=head1 NAME

Pulp - Give your Kelp applications more juice 

=head1 DESCRIPTION

Kelp is good. Kelp is great. But what if you could give it more syntactic sugar and separate your routes from the logic in a cleaner way? Pulp attempts to do just that.

=head1 SIMPLE TUTORIAL

For the most part, your original C<app.psgi> will remain the same as Kelps.

B<MyApp.pm>
  
  package MyApp;
  use Pulp;

  maps ['Main'];

Yep, that's the complete code for your base. You pass C<maps> an array reference of the routes you want to include. 
It will look for them in C<MyApp::Route::>. So the above example will load C<MyApp::Route::Main>.
Next, let's create that file

B<MyApp/Route/Main.pm>

  package MyApp::Route::Main;

  use Pulp::Route;

  get '/' => 'Controller::Root::hello';
  get '/nocontroller' => sub { 'Hello, world from no controller!' };

Simply use C<Pulp::Route>, then create your route definitions here. You're welcome to put your logic inside code refs, 
but that makes the whole idea of this module pointless ;) 
It will load C<MyApp::> then whatever you pass to it. So the '/' above will call C<MyApp::Controller::Root::hello>. Don't worry, 
any of your arguments will also be sent the method inside that controller, so you don't need to do anything else!

Finally, we can create the controller

B<MyApp/Controller/Root.pm>

  package MyApp::Controller::Root;

  use Pulp::Controller;

  sub hello {
      my ($self) = @_;
      return "Hello, world!";
  }

You now have a fully functional Kelp app! Remember, because this module is just a wrapper, you can do pretty much anything L<Kelp> 
can, like C<$self->>param> for example.

=head1 SUGARY SYNTAX

By sugar, we mean human readable and easy to use. You no longer need a build method, then to call ->add on an object for your 
routes. It uses a similar syntax to L<Kelp::Less>. You'll also find one called C<bridge>.

=head2 get

This will trigger a standard GET request.

  get '/mypage' => sub { 'It works' };

=head2 post

Will trigger on POST requests only

  post '/someform' => sub { 'Posted like a boss' };

=head2 any

Will trigger on POST B<or> GET requests

  any '/omni' => sub { 'Hit me up on any request' };

=head2 bridge

Bridges are cool, so please check out the Kelp documentation for more information on what they do and how they work.

  bridge '/users/:id' => sub {
      unless ($self->user->logged_in) {
          return;
      }

      return 1;
  };

  get '/users/:id/view' => 'Controller::Users::view';

=head2 has

If you only want basic accessors and Pulp detects you don't have any OOP frameworks activated with C<has>, then it will import its 
own little method which works similar to L<Moo>'s. Currently, it only supports C<is>, C<required> and C<default>.

  package MyApp;
    
  use Pulp;
  has 'x' => ( is => 'rw', default => sub { "Hello, world" } );

  package MyApp::Controller::Main;
    
  use Pulp::Controller;
  
  sub hello { shift->x; } # Hello, world

=head2 around

Need more power? Want to modify the default C<build> method? No problem. Similar to C<has>, if Pulp detects you have no C<around> method, it will import one. 
This allows you to tap into build if you really want to for some reason.

  package MyApp;

  use Pulp;

  around 'build' => sub {
      my $method = shift;
      my $self   = shift;
      my $routes = $self->routes;
      $routes->add('/manual' => sub { "Manually added" });

      $self->$method(@_);
  };

=head1 MODELS

You can always use an attribute to create a database connection, or separate them using models in a slightly cleaner way.
In your config you supply a hash reference with the models alias (what you will reference it as in code), the full path, and finally any 
arguments it might have (like the dbi line, username and password).

  # config.pl
  models => {
      'LittleDB' => {
          'model' => 'TestApp::Model::LittleDB',
          'args'  => ['dbi:SQLite:testapp.db'],
      },
  },

Then, you create C<TestApp::Model::LittleDB>

  package TestApp::Model::LittleDB;

  use Pulp::Model;
  use DBIx::Lite;

  sub build {
      my ($self, @args) = @_;
      return DBIx::Lite->connect(@args);
  }

As you can see, the C<build> function returns the DB object you want. You can obviously use DBIx::Class or whatever you want here.

That's all you need. Now you can pull that model instance out at any time in your controllers with C<model>.

  package TestApp::Controller::User;

  use Pulp::Controller;

  sub users {
      my ($self) = @_;
      my @users  = $self->model('LittleDB')->table('users')->all;
      return join ', ', map { $_->name } @users;
  }

=head2 Named ResultSets

If you're not using DBIx::Class, you can still have similar styled resultsets. Simply return a standard hash reference instead of a blessed object 
from the C<build> method, like so

  package TestApp::Model::LittleDB;

  use Pulp::Model;
  use DBIx::Lite;

  sub build {
      my ($self, @args) = @_;
      my $schema = DBIx::Lite->connect(@args);
      return {
          'User'       => $schema->table('users'),
          'Product'    => $schema->table('products'),
      };
  }

Then, you can do this stuff in your controllers

  package TestApp::Controller::Assets;

  sub users {
      my  ($self) = @_;
      my @users   = $self->model('LittleDB::User')->all;
      return join "<br>", map { $_->name . " (" . $_->email . ")" } @users;
  }

  sub products {
      my ($self) = @_;
      my @products = $self->model('LittleDB::Product')->all;
      return join "<br>", map { $_->name . " (" . sprintf("%.2f", $_->value) . ")" } @products;
  }


=head2 Models and DBIx::Class

If you enjoy the way Catalyst handles DBIx::Class models, you're going to love this (I hope so, at least). Pulp will automagically 
create models based on the sources of your schema if it detects it's a DBIx::Class::Schema.
Nothing really has to change, Pulp will figure it out on its own.

  package TestApp::Model::LittleDB;

  use Pulp::Model;
  use LittleDB::Schema;

  sub build {
      my ($self, @args) = @_;
      return LittleDB::Schema->connect(@args);
  }

Then just use it as you normally would in Catalyst (except we store it in C<$self>, not C<$c>).

  package TestApp::Controller::User;
  
  use Pulp::Controller;
  
  sub users {
      my ($self) = @_;
      my @users = $self->model('LittleDB::User')->all;
      return join ', ', map { $_->name } @users;
  }

Pulp will loop through all your schemas sources and create models based on your alias, and the sources name. So, C<Alias::SourceName>.

When we start our app, even though we've only added LittleDB, you'll see we have the new ones based on our Schema. Neat!

  .----------------------------------------------------------.
  | Model                                | Alias             |
  +--------------------------------------+-------------------+
  | TestApp::Model::LittleDB             | LittleDB          |
  | LittleDB::Schema::ResultSet::User    | LittleDB::User    |
  | LittleDB::Schema::ResultSet::Product | LittleDB::Product |
  '--------------------------------------+-------------------'

=head2 Automated API generation

Did you know Pulp can automatically create an API for your DBIx::Class schema? Currently this feature is still in beta, and only works with 
searching. Simply pass C<-api> as an import option like so.

  package TestApp::Model::LittleDB;
  
  use Pulp::Model -api => 1;
  ...

This will tell Pulp to do all the work for you, and generates a basic JSON API.
Some of the commands are below:

=head3 list

Lists all rows found for a particular resultset

  # curl http://localhost:5000/api/user/list
  [
     {
        "email" : "admin@company.ltd",
        "name" : "Admin User",
        "id" : 1
     },
     {
        "email" : "user@company.ltd",
        "name" : "Normal User",
        "id" : 2
     }
  ] 

=head3 find

Obtain a single row based on an id.

  # curl http://localhost:5000/api/user/find/2
  {
     "email" : "user@company.ltd",
     "name" : "Normal User",
     "id" : 2
  }

=head3 search

You can also perform a search, passing query parameters as your search arguments. If no parameters are passed, you'll 
get all results back.

  # curl http://localhost:5000/api/user/search?email=admin@company.ltd&id=1
  [
     {
        "email" : "admin@company.ltd",
        "name" : "Admin User",
        "id" : 1
     }
  ]

=head1 VIEWS

OK, so to try and not separate too much, I've chosen not to include views. Just use the standard Kelp modules 
(ie: L<Kelp::Module::Template::Toolkit>). However, there is a convenience method mentioned below.

=head2 detach

This method will call C<template> for you with the added benefit of automatically filling out the filename and including whatever 
is in the stash for you.

  package MyApp::Controller::Awesome;
 
  use Pulp::Controller;

  sub hello {
      my ($self) = @_;
      $self->stash->{name} = 'World';
      $self->detach;
  }

Then, you just create C<hello.tt>.

  <h2>Hello, [% name %]</h2>

While not really required, it does save a bit of typing and can come in quite useful.

=head1 IMPORT OPTIONS

=head2 -auto

Importing -auto will automatically include any route modules within your C<MyApp::Route> namespace.
For example, we have two controllers, C<Main> and C<New>

  package MyApp::Route::Main;

  use Pulp::Route;
  
  get '/' => sub { "Hi" };

  package MyApp::Route::New;
  
  use Pulp::Route;
  
  get '/new/url' => sub { "New one" };
  
Then to kick off our app, all we need is

  package MyApp;
  use Pulp -auto => 1;

That's it. Pulp will complain if you attempt to use C<maps> at the same time, because obviously that's just redundant.

=head1 REALLY COOL THINGS TO NOTE

=head2 Default imports

You should be aware that Pulp will import warnings, strict and true for you. Because of this, there is no requirement to 
add a true value to the end of your file. I chose this because it just makes things look a little cleaner.

=head2 Pulp starter

On installation of Pulp, you'll receive a file called C<pulp>. Simply run this, passing it the name of your module 
and it will create a working test app with minimal boilerplate so you can get started straight away. Just run it as:

  $ pulp MyApp
  $ pulp Something::With::A::Larger::Namespace

=head1 SEE ALSO

L<Kelp> - At the very heart of Pulp is Kelp, a minimalistic web framework created around L<Plack>. Definitely check this out. The excellent documentation will come in handy if you're using Pulp as well.


=head1 AUTHOR

Brad Haywood <brad@perlpowered.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
__END__
