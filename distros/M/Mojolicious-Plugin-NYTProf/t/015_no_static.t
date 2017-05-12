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

{
  use Mojolicious::Lite;

  plugin NYTProf => {
    nytprof => {
      profiles_dir => $prof_dir,
    },
  };
}

my $t = Test::Mojo->new;

$t->get_ok('/some_static_file')
  ->status_is(200)
  ->content_is("well hello there!\n");

ok(
	! Mojolicious::Plugin::NYTProf::_profiles(catfile($prof_dir,'profiles')),
	'no profiles generated for static file'
);

done_testing();
