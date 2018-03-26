package Test::Mojo::resources;

use Mojo::Base -strict;
use Mojo::File qw(path);
use Test::Mojo;

require Mojolicious::Commands;

sub tempdir {

  # my $tempdir = '/tmp/mres';
  my $tempdir = File::Temp::tempdir(CLEANUP => 1, TEMPLATE => 'resourcesXXXX');
  unshift @INC, $tempdir . "/blog/lib";
  return $tempdir;
}

# Install the app to a temporary path
sub install_app {
  my $MOJO_HOME = tempdir . "/blog";

  # idempotent
  path($MOJO_HOME)->remove_tree->make_path({mode => 0700});
  for (path('t/blog')->list_tree({dir => 1})->each) {
    my $new_path = $_->to_array;
    splice @$new_path, 0, 2;    #t/blog/blog.conf -> blog.conf
    unshift @$new_path, $MOJO_HOME;    #blog.conf -> $MOJO_HOME/blog.conf
    path(@$new_path)->make_path({mode => 0700}) if -d $_;
    $_->copy_to(path @$new_path) if -f $_;
  }
  return;
}
1;
