use strict;
use warnings;
use File::HomeDir::Test;
use File::HomeDir;
use Test::More tests => 3;
use Test::Mojo;
use YAML::XS qw( DumpFile );

mkdir File::HomeDir->my_home . '/etc';
DumpFile( File::HomeDir->my_home . '/etc/PlugAuth.conf', {
  plugins => [
    { 'PlugAuth::Plugin::ExampleRoute' => {} },
  ],
});

my $t = Test::Mojo->new("PlugAuth");

$t->get_ok('/hello')
  ->status_is(200)
  ->content_is('hello world!');
