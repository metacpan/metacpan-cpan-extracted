#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Mojo;

use File::Spec::Functions 'catfile';
use FindBin '$Bin';
use File::Path qw'rmtree';
use Algorithm::Combinatorics 'variations_with_repetition';

use Mojolicious::Plugin::NYTProf;
Mojolicious::Plugin::NYTProf::_find_nytprofhtml()
	|| plan skip_all => "Couldn't find nytprofhtml in PATH or in same location as $^X";

my $prof_dir = catfile($Bin,"nytprof");

my @hooks = qw/
  after_build_tx
  before_dispatch
  after_static
  before_routes
  around_action
  before_render
  after_render
  after_dispatch
  around_dispatch
/;

my $iterator = variations_with_repetition(\@hooks, 2);

while (my $pair = $iterator->next) {

  my ($pre, $post) = @{$pair};
  {
    use Mojolicious::Lite;

    plugin NYTProf => {
      nytprof => {
        profiles_dir => $prof_dir,
        pre_hook     => $pre,
        post_hook    => $post,
        disable      => 1,
      },
    };

    any 'some_route' => sub {
      my ($self) = @_;
      $self->render(text => "basic stuff\n");
    };
  }

  my $t = Test::Mojo->new;

  $t->get_ok('/some_route')
    ->status_is(200)
    ->content_is("basic stuff\n","$pre,$post");
}

done_testing();
