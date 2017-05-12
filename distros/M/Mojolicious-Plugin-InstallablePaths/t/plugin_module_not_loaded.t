use strict;
use warnings;

use Test::More;

use lib 't/lib';

use Mojolicious::Plugin::InstallablePaths;
my $plugin = Mojolicious::Plugin::InstallablePaths->new( app_class => 'MyTest::App' );

isa_ok $plugin, 'Mojolicious::Plugin';

{
  local $@;
  eval { $plugin->files_path };
  ok( $@, 'dies when app class is not loaded' );
}

done_testing;

