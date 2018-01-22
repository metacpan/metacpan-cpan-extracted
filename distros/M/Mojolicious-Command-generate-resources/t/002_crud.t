use Mojo::Base -strict;
use Mojo::File qw(path);
use File::Spec::Functions qw(catdir);
use File::Temp qw(tempdir);
use Test::Mojo;
use Test::More;

#our $tempdir = tempdir(TMPDIR => 1, CLEANUP => 1,TEMPLATE => 'resourcesXXXX');
our $tempdir = tempdir(TMPDIR => 1, TEMPLATE => 'resourcesXXXX');
unshift @INC, "$tempdir/blog/lib";

require Mojolicious::Commands;

# help
my $commands = Mojolicious::Commands->new;
my $buffer   = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $commands->run('help', 'generate', 'resources');
}
like $buffer, qr/Usage: APPLICATION generate resources \[OPTIONS\]/,
  'right help output';

# Run the command through an example application
{

  # Install the app to a temporary path
  local $ENV{MOJO_HOME} = "$tempdir/blog";
  path($ENV{MOJO_HOME})->make_path({mode => 0700});
  for (path('t/blog')->list_tree({dir => 1})->each) {
    my $new_path = $_->to_array;
    splice @$new_path, 0, 2;    #t/blog/blog.conf -> blog.conf
    unshift @$new_path, $ENV{MOJO_HOME}; #blog.conf -> $ENV{MOJO_HOME}/blog.conf
    path(catdir(@$new_path))->make_path({mode => 0700}) if -d $_;
    $_->copy_to(catdir(@$new_path)) if -f $_;
  }

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
  like($buffer,
       qr{\[mkdir\].+?templates[\\/]users},
       "made dir templates/users");
  like($buffer,
       qr{\[write\].+?users[\\/]index.html.ep},
       "written templates/users/index.html.ep");

  like($buffer,
       qr{\[write\].+?blog[\\/]TODO},
       "written /blog/TODO ... etc");
  my $home = $cm->app->home;

  # Default arguments
  is_deeply(
            $cm->args,
            {
             lib                  => $home->rel_file('lib'),
             templates_root       => $home->rel_file('templates'),
             home_dir             => $home,
             tables               => [qw(users groups)],
             controller_namespace => $cm->app->routes->namespaces->[0],
             model_namespace      => ref($cm->app) . '::Model',
            },
            'proper default arguments'
           );
}

# TODO: Make requests to the created routes
done_testing();

