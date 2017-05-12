# -*-perl-*-

# $Id: 50_rule_create_only.t,v 3.1 2004/02/26 02:02:29 lachoy Exp $

use strict;
use lib qw( t/ );
use Test::More tests => 6;

do "t/config.pl";

{
    my %config = (
      test => {
         class      => 'CreateOnlyTest',
         isa        => [ 'SPOPS::Loopback' ],
         rules_from => [ 'SPOPS::Tool::CreateOnly' ],
         field      => [ qw( id_field field_name ) ],
         id_field   => 'id_field',
      },
    );

    # Create our test class using the loopback

    require_ok( 'SPOPS::Initialize' );

    my $class_init_list = eval { SPOPS::Initialize->process({ config => \%config }) };
    ok( ! $@, "Initialize process run $@" );
    is( $class_init_list->[0], 'CreateOnlyTest', 'Object class initialized' );

    # Create an object and save it to see if that works

    my $item = CreateOnlyTest->new({ id_field   => "Foo!",
                                     field_name => "Bar!" });
    eval { $item->save };
    ok( ! $@, "Initial save" );

    # Now modify it and try to update; it should fail

    $item->{id_field} = "changed";
    eval { $item->save };
    ok( $@, "Update of saved object failed (this is good)" );

    # Now fetch an object, modiify it and try to update; it should
    # fail

    my $fetched = CreateOnlyTest->fetch( "sample" );
    $fetched->{field_name} = "changed";
    eval { $fetched->save };
    ok( $@, "Update of fetched object failed (this is good)" );
}
