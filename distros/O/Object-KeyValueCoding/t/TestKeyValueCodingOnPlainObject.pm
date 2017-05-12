package TestKeyValueCodingOnPlainObject;

use strict;
use warnings;

use base qw(
    TestKeyValueCodingOnObject
);

use Test::More;

sub obj { return $_[0]->{obj} ||= _ObjectTestThing->new() }

package _ObjectTestThing;

use strict;
use warnings;

use Object::KeyValueCoding additions => 1;

sub new {
    my ( $class ) = @_;
    return bless {
        bacon => undef,
    }, $class;
}

sub shakespeare    { return $_[0]->{shakespeare}  }
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
    return {
        "john" => 'jonny',
        "bruce" => 'brucey'
    };
}

# try a different style of accessor
sub foo     { return $_[0]->{_foo}  }
sub set_foo { $_[0]->{_foo} = $_[1] }

1;