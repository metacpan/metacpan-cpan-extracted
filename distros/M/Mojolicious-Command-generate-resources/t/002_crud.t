#002_crud.t
use Mojo::Base -strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Mojo::resources;    # load it from "$FindBin::Bin/lib"

our $tempdir = Test::Mojo::resources::tempdir;

# help
my $buffer = '';
{
  my $commands = Mojolicious::Commands->new;
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $commands->run('help', 'generate', 'resources');
}
like $buffer, qr/Usage: APPLICATION generate resources \[OPTIONS\]/,
  'right help output';

# Run the command through an example application
{
  Test::Mojo::resources::install_app();

  # Run the command through the app.
  require Blog;
  $buffer = '';
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  Blog->new->start('generate', 'resources');
  like($buffer,
       qr/Below are the options/,
       "Command is loaded and shows help message");
}

# Default options + one custom generator template (show.html.ep)
{

  $buffer = '';
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  my $blog = Blog->new;
  push @{$blog->renderer->paths}, $blog->home->rel_file('resources_templates');
  my $cm = Mojolicious::Command::generate::resources->new(app => $blog)
    ->run('-t' => 'users,groups');
  like($buffer,
       qr|\[exist\].+?lib.+Controller|,
       "Folder lib/Blog/Controller exists.");
  like($buffer,
       qr|\[write\].+Controller[\\/]Users.pm|,
       "written lib/Blog/Controller/Users.pm");
  like($buffer,
       qr{\[write\].+?Model[\\/]Users.pm},
       "written lib/Blog/Model/Users.pm");
  like($buffer, qr{\[mkdir\].+?templates[\\/]users},
       "made dir templates/users");
  like($buffer,
       qr{\[write\].+?users[\\/]index.html.ep},
       "written templates/users/index.html.ep");
  like($buffer, qr{\[write\].+?blog[\\/]TODO}, "written /blog/TODO ... etc");
  my $home = $cm->app->home;

  # Default arguments
  is_deeply(
            $cm->args,
            {
             lib                  => $home->child('lib'),
             home_dir             => $home,
             api_dir              => $home->child('api'),
             templates_root       => $home->child('templates'),
             tables               => [qw(users groups)],
             controller_namespace => $cm->app->routes->namespaces->[0],
             model_namespace      => ref($cm->app) . '::Model',
            },
            'proper default arguments'
           );
}


# Make requests to the created routes
{
  my $test = Test::Mojo->new('Blog');
  my $blog = $test->app;

# Generate new routes and helpers for the instantiated application.
  my $cm = Mojolicious::Command::generate::resources->new(app => $blog);
  $cm->args->{tables} = [qw(groups users)];
  my $app_routes = $blog->routes;
  for my $r (@{$cm->routes}) {
    my $via = lc $r->{via}[0];
    $app_routes->$via($r->{route})->to($r->{to})->name($r->{name});
  }
  for my $t (@{$cm->args->{tables}}) {
    my $class = "Blog::Model::" . Mojo::Util::camelize $t;
    Mojo::Loader::load_class $class;
    $blog->helper(
      $t => sub {
        state $table = $class->new(sqlite => shift->sqlite);
      }
    );
    ok($blog->renderer->get_helper($t), "\$blog has helper $t");

    #index
    $test->get_ok("/$t")->status_is(200)->element_exists('table')
      ->element_exists(qq|a[href=/$t/create]|);

    #create
    my $g_ok    = $test->get_ok("/$t/create")->status_is(200);
    my $columns = $cm->_column_info($t);
    for my $col (@$columns) {
      my $name = $col->{COLUMN_NAME};
      next if $name eq 'id';
      my $size = $col->{COLUMN_SIZE};
      my $required = $col->{NULLABLE} ? '' : 'required=1';

      # form field is generated properly
      ($col->{TYPE_NAME} =~ /char/i && $size < 256)
        && $g_ok->element_exists("label[for=$name]")
        ->element_exists("input[type=text][name=$name][size=$size]");
      (   $col->{TYPE_NAME} =~ /text/i
       || $col->{TYPE_NAME} =~ /char/i && $col->{COLUMN_SIZE} > 255)
        && $g_ok->element_exists("label[for=$name]")
        ->element_exists("textarea[name=$name][$required]");
      ($col->{TYPE_NAME} =~ /INT|FLOAT|DOUBLE|DECIMAL/i)
        && $g_ok->element_exists("label[for=$name]")
        ->element_exists("input[type=number][name=$name][size=$size]");
    }

    # show
    $test->get_ok("/$t/1")->status_is(404)->content_is('Not Found');

    # store
    my $form = {};
    my $id   = 1;
    if ($t eq 'groups') {
      $form = {name => 'g1', description => 'g1 description'};
      $test->post_ok("/$t" => {Accept => '*/*'}, form => $form)->status_is(302);
      $test->get_ok("/$t/$id")->status_is(200)
        ->content_like(qr/Id:\s$id.+?$form->{name}.+?$form->{description}/sm);
      $test->get_ok("/$t/$id/edit")->status_is(200)
        ->element_exists("input[type=hidden][name=id]");
    }
    elsif ($t eq 'users') {
      $form = {
               username => 'u1',
               group_id => 1,
               name     => 'Краси Беров',
               about    => 'about u1'
              };
      $test->post_ok("/$t" => {Accept => '*/*'}, form => $form)->status_is(302);
      $test->get_ok("/$t/$id")->status_is(200)
        ->content_like(qr/Id:\s$id.+?$form->{group_id}.+?$form->{name}/sm);
      $test->get_ok("/$t/$id/edit")->status_is(200)
        ->element_exists("input[type=hidden][name=id]");
    }

    # update
    $form->{id}   = $id;
    $form->{name} = "$form->{name} edited";
    $test->put_ok("/$t/$id" => {Accept => '*/*'}, form => $form)
      ->status_is(302);
    $test->get_ok("/$t/$id")->status_is(200)->content_like(qr/$form->{name}/);

    # index with item(s)
    $test->get_ok("/$t")->status_is(200)
      ->text_is(
              "table>tbody>tr:last-child>td:first-child>a[href=/$t/$id]" => $id)
      ->content_like(qr/$form->{name}/);

    # remove
    $test->delete_ok("/$t/$id")->status_is(302);

    # empty index again
    $test->get_ok("/$t")->status_is(200)
      ->element_exists_not(
                    "table>tbody>tr:last-child>td:first-child>a[href=/$t/$id]");
  }
}

done_testing();

