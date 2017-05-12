#! perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
require MyTest;

use Test::More;

my $app = MyApp->new({
  plugins => [
    {'Foo' => { attr1 => 'test' } },
    {'Baz' => {}} ,
    '+MyApp::OtherPlugin::Bar',
  ] ,
});

isa_ok( $app , 'MyApp' );

my $plugins = $app->plugin_hash;

ok( $plugins->{'MyApp::OtherPlugin::Bar'}->can('bar') , 'Bar does bar' );
ok( $plugins->{Baz}->can('baz')                       , 'Baz does baz' );
ok( $plugins->{Foo}->can('foo')                       , 'Foo does foo' );

ok( ! $plugins->{'MyApp::OtherPlugin::Bar'}->can('common') , 'Bar does not do common' );

ok( $plugins->{Baz}->can('common') , 'Baz does common' );
ok( $plugins->{Foo}->can('common') , 'Foo does common' );

is( $app->plugin_hash->{Foo}->foo() , 'Foo' , 'Foo::foo says Foo' );

is_deeply( $app->plugin_run_method( 'common' ) , [ qw/ Common Common /] ,
    'expected result from plugin_run_method' );

my $plugin_list = $app->plugin_list;

isa_ok( $plugin_list->[0], "MyApp::Plugin::Foo");
isa_ok( $plugin_list->[1], "MyApp::Plugin::Baz");
isa_ok( $plugin_list->[2], "MyApp::OtherPlugin::Bar");

done_testing;
