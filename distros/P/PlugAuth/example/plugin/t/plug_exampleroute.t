use strict;
use warnings;
use Test2::Plugin::FauxHomeDir;
use Test::More tests => 3;
use Test::Mojo;
use YAML::XS qw( DumpFile );
use File::Glob qw( bsd_glob );

mkdir bsd_glob('~/etc');
DumpFile( bsd_glob('~/etc/PlugAuth.conf'), {
  plugins => [
    { 'PlugAuth::Plugin::ExampleRoute' => {} },
  ],
});

my $t = Test::Mojo->new("PlugAuth");

$t->get_ok('/hello')
  ->status_is(200)
  ->content_is('hello world!');
