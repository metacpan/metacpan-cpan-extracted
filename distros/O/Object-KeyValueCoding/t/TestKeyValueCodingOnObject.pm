package TestKeyValueCodingOnObject;

use strict;
use warnings;

use base qw(
    Test::Class
);
use Test::More;

sub setUp : Test(startup) {
    my ( $self ) = @_;
    $self->obj()->setValueForKey( "william", "shakespeare" );
}

sub test_object_properties : Tests {
    my ( $self ) = @_;
    my $obj = $self->obj();
    $obj->setValueForKey( "francis", "bacon" );

    ok( $obj->valueForKey( "shakespeare" ) eq "william", "william shakespeare" );
    ok( $obj->valueForKey( "marlowe" ) eq "christopher", "christopher marlowe" );
    ok( $obj->valueForKey( "bacon" ) eq "francis", "francis bacon" );

    ok( $obj->valueForKey( "_s('donne')" ) eq "DONNE", "john donne" );
    ok( $obj->valueForKey( "donne.john" ) eq "jonny", "jonny" );
    ok( $obj->valueForKey( "_s(donne.john)" ) eq "JONNY", "JONNY" );

    $obj->setValueForKey( ref($obj)->new(), "foo" );
    $obj->setValueForKey( ref($obj)->new(), "foo.foo" );

    $obj->setValueForKey( "will", "foo.shakespeare" );
    $obj->setValueForKey( "bill", "foo.foo.shakespeare" );

    ok( $obj->valueForKey( "shakespeare" ) eq "william", "william shakespeare" );
    ok( $obj->valueForKey( "foo.shakespeare" ) eq "will", "will shakespeare" );
    ok( $obj->valueForKey( "foo.foo.shakespeare" ) eq "bill", "bill shakespeare" );
}

sub test_additions : Tests {
    my ( $self ) = @_;
    my $obj = $self->{obj};
    is_deeply( $obj->valueForKey( "sorted(taylorColeridge)" ), [ "kublai khan", "samuel", "xanadu" ], "sorted" );
    is_deeply( $obj->valueForKey( "reversed(sorted(taylorColeridge))" ), [ "xanadu", "samuel", "kublai khan" ], "reversed" );
    is_deeply( $obj->valueForKey( "sorted(keys(donne))" ), [ "bruce", "john" ], "sorted keys" );
}

sub obj {}

TestKeyValueCodingOnObject->SKIP_CLASS( 1 );

1;