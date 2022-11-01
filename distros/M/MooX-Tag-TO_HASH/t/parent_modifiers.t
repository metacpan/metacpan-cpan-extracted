#! perl

use Test2::V0;

use Test::Lib;

# tests and documents the Moo behavior

package Parent_H_bad {
    use Moo;

    with 'MooX::Tag::TO_HASH';

    has order => ( is => 'ro',
                   to_hash => 1,
                   default => sub { [] }
               );

    around TO_HASH => sub {
        my ( $orig, $self, @args ) = @_;
        my $hash = $self->$orig( @args );
        push @{ $hash->{order} }, __PACKAGE__;
        return $hash;
    }
}

package Child_H_bad {
    use Moo;
    extends 'Parent_H_bad';
    with 'MooX::Tag::TO_HASH';

    around TO_HASH => sub {
        my ( $orig, $self, @args ) = @_;
        my $hash = $self->$orig( @args );
        push @{ $hash->{order} }, __PACKAGE__;
        return $hash;
    }

}

is ( Child_H_bad->new->TO_HASH, { order => [ 'Child_H_bad' ] }, "Can't handle override of TO_HASH in child class" );


# tests and documents the Moo behavior

package Parent_J_bad {
    use Moo;

    with 'MooX::Tag::TO_JSON';

    has order => ( is => 'ro',
                   to_json => 1,
                   default => sub { [] }
               );

    around TO_JSON => sub {
        my ( $orig, $self, @args ) = @_;
        my $hash = $self->$orig( @args );
        push @{ $hash->{order} }, __PACKAGE__;
        return $hash;
    }
}

package Child_J_bad {
    use Moo;
    extends 'Parent_J_bad';
    with 'MooX::Tag::TO_JSON';

    around TO_JSON => sub {
        my ( $orig, $self, @args ) = @_;
        my $hash = $self->$orig( @args );
        push @{ $hash->{order} }, __PACKAGE__;
        return $hash;
    }

}

is ( Child_J_bad->new->TO_JSON, { order => [ 'Child_J_bad' ] }, "Can't handle override of TO_JSON in child class" );


package Parent_H {
    use Moo;
    with 'MooX::Tag::TO_HASH';

    has order => ( is => 'ro',
                   to_hash => 1,
                   default => sub { [] }
               );

    sub modify_hashr {
        my ( $self, $hashr ) = @_;
        push @{ $hashr->{order}  } , __PACKAGE__;
    };
}

package Child_H {
    use Moo;

    extends 'Parent_H';
    with 'MooX::Tag::TO_HASH';
    after 'modify_hashr' => sub {
        my ( $self, $hashr ) = @_;
        push @{ $hashr->{order} //= [] } , __PACKAGE__;
    };
}

is ( Child_H->new->TO_HASH, { order => [  'Parent_H', 'Child_H' ] }, "Can handle override of TO_HASH in child class" );


package Parent_J {
    use Moo;
    with 'MooX::Tag::TO_JSON';

    has order => ( is => 'ro',
                   to_json => 1,
                   default => sub { [] }
               );

    sub modify_jsonr {
        my ( $self, $jsonr ) = @_;
        push @{ $jsonr->{order}  } , __PACKAGE__;
    };
}

package Child_J {
    use Moo;

    extends 'Parent_J';
    with 'MooX::Tag::TO_JSON';
    after 'modify_jsonr' => sub {
        my ( $self, $jsonr ) = @_;
        push @{ $jsonr->{order} //= [] } , __PACKAGE__;
    };
}

is ( Child_J->new->TO_JSON, { order => [  'Parent_J', 'Child_J' ] }, "Can handle override of TO_JSON in child class" );




done_testing;
