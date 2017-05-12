package TestKeyValueCodingOnMooObject;

use strict;
use warnings;

use strict;
use base qw(
    TestKeyValueCodingOnObject
);

use Test::More;

sub obj { return $_[0]->{obj} ||= _MooTestThing->new() }


package _MooTestThing;

use strict;
use warnings;

use Moo;
use Object::KeyValueCoding additions => 1;

has bacon           => ( is => "rw", );
has shakespeare     => ( is => "rw", );
has foo             => ( is => "rw", );

sub marlowe { return "christopher" }
sub chaucer {
    my ( $self, $value ) = @_;
    if ( $value eq "geoffrey" ) { return "canterbury" }
    return "tales";
}
sub taylorColeridge { return [ "samuel", "xanadu", "kublai khan" ] }

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