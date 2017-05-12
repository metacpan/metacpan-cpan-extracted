use strict;
use warnings;

use Test::More;

use lib 't/lib';
use MyTest::App;

use Mojolicious::Plugin::InstallablePaths;
my $plugin = Mojolicious::Plugin::InstallablePaths->new( app_class => 'MyTest::App' );

isa_ok $plugin, 'Mojolicious::Plugin';

ok( -d $plugin->class_path, 'class_path found' );
ok( -d $plugin->files_path, 'files_path found' );

ok( -d $plugin->find_path('public'), 'find_path on "public" exists' );
ok(  ! $plugin->find_path('template'), 'find_path on non-existent "template" returns undef' );

done_testing;
