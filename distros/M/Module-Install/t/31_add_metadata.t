use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More;
use lib 't/lib';
use MyTest;
use YAML::Tiny;

plan tests => 5;

SCOPE: {
    ok( create_dist('Foo', { 'Makefile.PL' => <<"END_DSL" }), 'create_dist Foo');
use inc::Module::Install;
name          'Foo';
perl_version  '5.005';
all_from      'lib/Foo.pm';
add_metadata  'x_foo' => 'bar';
WriteAll;
END_DSL

    ok( build_dist(), 'build_dist' );
    my $file = file('META.yml');
    ok( -f $file);
    my $yaml = YAML::Tiny::LoadFile($file);
    ok( $yaml->{x_foo} && $yaml->{x_foo} eq 'bar' );
    ok( kill_dist(), 'kill_dist' );
}
