package TestKeyValueCodingNaming;

use strict;
use warnings;

use strict;
use base qw(
    Test::Class
);

use Test::More;

sub setUp : Test(startup) {
    my ( $self ) = @_;
    $self->obj()->set_value_for_key( "william", "shakespeare" );
}

sub test_object_properties : Tests {
    my ( $self ) = @_;
    my $obj = $self->obj();
    $obj->set_value_for_key( "francis", "bacon" );

    ok( $obj->value_for_key( "shakespeare" ) eq "william", "naming: william shakespeare" );
    ok( $obj->value_for_key( "marlowe" ) eq "christopher", "naming: christopher marlowe" );
    ok( $obj->value_for_key( "bacon" ) eq "francis", "naming: francis bacon" );

    ok( $obj->value_for_key( "_s('donne')" ) eq "DONNE", "naming: john donne" );
    ok( $obj->value_for_key( "donne.john" ) eq "jonny", "naming: jonny" );
    ok( $obj->value_for_key( "_s(donne.john)" ) eq "JONNY", "naming: JONNY" );

    $obj->set_value_for_key( ref($obj)->new(), "foo" );
    $obj->set_value_for_key( ref($obj)->new(), "foo.foo" );

    $obj->set_value_for_key( "will", "foo.shakespeare" );
    $obj->set_value_for_key( "bill", "foo.foo.shakespeare" );

    ok( $obj->value_for_key( "shakespeare" ) eq "william", "naming: william shakespeare" );
    ok( $obj->value_for_key( "foo.shakespeare" ) eq "will", "naming: will shakespeare" );
    ok( $obj->value_for_key( "foo.foo.shakespeare" ) eq "bill", "naming: bill shakespeare" );
}

sub test_additions : Tests {
    my ( $self ) = @_;
    my $obj = $self->{obj};
    is_deeply( $obj->value_for_key( "sorted(taylorColeridge)" ), [ "kublai khan", "samuel", "xanadu" ], "naming: sorted" );
    is_deeply( $obj->value_for_key( "reversed(sorted(taylorColeridge))" ), [ "xanadu", "samuel", "kublai khan" ], "naming: reversed" );
    is_deeply( $obj->value_for_key( "sorted(keys(donne))" ), [ "bruce", "john" ], "naming: sorted keys" );
}

sub obj { return $_[0]->{obj} ||= _NamingTestThing->new() }

package _NamingTestThing;

use strict;
use warnings;

use Object::KeyValueCoding additions => 1, naming_convention => "underscore";

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