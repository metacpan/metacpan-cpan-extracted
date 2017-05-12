package TestKeyValueCodingUniversal;

use strict;
use warnings;

# This rather salacious line adds key-value coding to
# every class in the system.
use Object::KeyValueCoding target => "UNIVERSAL";

use base qw(
    Test::Class
);

use Test::More;

sub setUp : Test(startup) {
    my ( $self ) = @_;
    $self->{obj} = _UniversalTestThing->new();
    $self->{obj}->setValueForKey( "william", "shakespeare" );
}

sub test_object_properties : Tests {
    my ( $self ) = @_;
    my $obj = $self->valueForKey("obj");
    $self->setValueForKey( "francis", "obj.bacon" );

    ok( $obj->valueForKey( "shakespeare" ) eq "william", "william shakespeare" );
    ok( $obj->valueForKey( "marlowe" ) eq "christopher", "christopher marlowe" );
    ok( $obj->valueForKey( "bacon" ) eq "francis", "francis bacon" );

    ok( $obj->valueForKey( "_s('donne')" ) eq "DONNE", "john donne" );
    ok( $obj->valueForKey( "donne.john" ) eq "jonny", "jonny" );
    ok( $obj->valueForKey( "_s(donne.john)" ) eq "JONNY", "JONNY" );
}

# Note that KeyValueCoding is not mentioned here at all:
package _UniversalTestThing;

use strict;
use warnings;

sub new {
    my ( $class ) = @_;
    return bless {
        bacon => undef,
    }, $class;
}

sub shakespeare    { return $_[0]->{shakespeare} }
sub setShakespeare { $_[0]->{shakespeare} = $_[1] }

sub marlowe { return "christopher" }

sub bacon    { return $_[0]->{bacon} }
sub setBacon { $_[0]->{bacon} = $_[1] }

sub _s {
    my ( $self, $value ) = @_;
    return uc($value);
}

sub donne {
    return {
        "john" => 'jonny',
        "bruce" => 'brucey'
    };
}

1;