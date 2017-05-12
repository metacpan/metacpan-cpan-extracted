#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Mojo;

use File::Spec::Functions 'catfile';
use FindBin '$Bin';
use File::Path qw'rmtree';

use Mojolicious::Plugin::NYTProf;
Mojolicious::Plugin::NYTProf::_find_nytprofhtml()
	|| plan skip_all => "Couldn't find nytprofhtml in PATH or in same location as $^X";

my $prof_dir = catfile($Bin,"nytprof");

my @existing_profs = glob "$prof_dir/profiles/nytprof*";
unlink $_ for @existing_profs;
my @existing_runs = glob "$prof_dir/html/nytprof*";
rmtree($_) for @existing_runs;

foreach my $force_in_prod ( 0,1 ) {

  {
    use Mojolicious::Lite;

    app->mode('production');

    plugin NYTProf => {
      nytprof => {
        profiles_dir => $prof_dir,
        allow_production => $force_in_prod,
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
    ->content_is("basic stuff\n");

  if ($force_in_prod) {
    ok(
      Mojolicious::Plugin::NYTProf::_profiles(catfile($prof_dir,'profiles')),
      'profiles generated when in production mode with allow_production config'
    );
  } else {
    ok(
      ! Mojolicious::Plugin::NYTProf::_profiles(catfile($prof_dir,'profiles')),
      'no profiles generated when in production mode'
    );
  }
}

done_testing();
