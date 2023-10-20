#!perl
#
# a bad generator for code coverage

use 5.26.0;
use warnings;
use Test2::V0;
use Music::Factory;
use Object::Pad 0.66;

plan(4);

class Music::Factory::Buggy :isa(Music::Factory::Generator) {

    method update ( $epoch, $maxlen ) {
        state $how = 0;
        $how ^= 1;
        if ($how) {
            return $maxlen, undef;
        } else {
            return $maxlen, [];
        }
    }
}

{
    my $line = Music::Factory::AssemblyLine->new(
        events => [],
        gen    => Music::Factory::Buggy->new,
        maxlen => 42,
    );
    my ( $epoch, $evlist, undef ) = $line->update;
    is( $epoch,  42 );
    is( $evlist, [] );

    ( $epoch, $evlist, undef ) = $line->update;
    is( $epoch,  42 );
    is( $evlist, [] );
}
