package TestKeyValueCodingSimple;

use strict;
use warnings;

use base qw(
    Test::Class
);

use Test::More;

sub setUp : Test(startup) {
    my ( $self ) = @_;
    $self->{obj} = _SimpleTestThing->new();
    $self->{obj}->setValueForKey( "william", "shakespeare" );
}

sub test_object_properties : Tests {
    my ( $self ) = @_;
    my $obj = $self->{obj};
    $obj->setValueForKey( "francis", "bacon" );

    ok( $obj->valueForKey( "shakespeare" ) eq "william", "Simple: william shakespeare" );
    ok( $obj->valueForKey( "marlowe" ) eq "christopher", "Simple: christopher marlowe" );
    ok( $obj->valueForKey( "bacon" ) eq "francis", "Simple: francis bacon" );

    ok( !defined $obj->valueForKey( "donne.marlowe" ), "Simple: keypath for key" );
    ok( $obj->valueForKeyPath( "donne.marlowe" ) eq "christopher", "Simple: christopher" );
}


package _SimpleTestThing;

use Object::KeyValueCoding implementation => "Simple";

sub new {
    my ( $class ) = @_;
    return bless {
        bacon => undef,
    }, $class;
}

sub shakespeare    { return $_[0]->{shakespeare} }
sub setShakespeare { $_[0]->{shakespeare} = $_[1] }

sub marlowe { return "christopher" }
sub chaucer {
    my ( $self, $value ) = @_;
    if ( $value eq "geoffrey" ) { return "canterbury" }
    return "tales";
}

sub bacon    { return $_[0]->{bacon} }
sub setBacon { $_[0]->{bacon} = $_[1] }

sub taylorColeridge { return [ "samuel", "xanadu", "kublai khan" ] }

sub _s {
    my ( $self, $value ) = @_;
    return uc($value);
}

sub donne {
    my ( $self ) = @_;
    return $self->{_donne} ||= _SimpleTestThing->new();
}

1;