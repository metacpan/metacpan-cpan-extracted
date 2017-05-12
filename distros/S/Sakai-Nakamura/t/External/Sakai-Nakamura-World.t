#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 16;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Sakai::Nakamura' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Authn' ); }
BEGIN { use_ok( 'Sakai::Nakamura::World' ); }

# test user name:
my $test_world = "world_test_world_$$";

# sling object:
my $nakamura = Sakai::Nakamura->new();
isa_ok $nakamura, 'Sakai::Nakamura', 'sling';
$nakamura->{'URL'}     = $sling_host;
$nakamura->{'User'}    = $super_user;
$nakamura->{'Pass'}    = $super_pass;
$nakamura->{'Verbose'} = $verbose;
$nakamura->{'Log'}     = $log;
# authn object:
my $authn = Sakai::Nakamura::Authn->new( \$nakamura );
isa_ok $authn, 'Sakai::Nakamura::Authn', 'authentication';
ok( $authn->login_user(), "Log in successful" );
# world object:
my $world = Sakai::Nakamura::World->new( \$authn, $verbose, $log );
isa_ok $world, 'Sakai::Nakamura::World', 'world';

ok( defined $world,
    "World Test: Sling World Object successfully created." );

# add world:
ok( $world->add( $test_world ),
    "World Test: World \"$test_world\" added successfully." );

my $upload = "id\nworld_test2_world_$$";
ok( $world->add_from_file(\$upload,0,1), 'Check add_from_file function' );
$upload = "id\nworld_test3_world_$$\nworld_test4_world_$$\nworld_test5_world_$$";
ok( $world->add_from_file(\$upload,0,3), 'Check add_from_file function with three forks' );

# TODO: Test why creation is fine with a non-existent template.
# ok( $world->add( $test_world, 'title', 'description', 'tags', 'public', 'yes', '__bad__world__template__' ),
  #  "World Test: World \"$test_world\" added successfully." );


ok( my $world_config = Sakai::Nakamura::World->config($nakamura), 'check world config function' );
ok( defined $world_config );
throws_ok { Sakai::Nakamura::World->run( $nakamura ) } qr/No world config supplied!/, 'Check run function croaks without config';
ok( Sakai::Nakamura::World->run( $nakamura, $world_config ) );
my $world_name = "nakamura_test5_world_$$";
$world_config->{'add'} = \$world_name;
ok( Sakai::Nakamura::World->run( $nakamura, $world_config ) );
