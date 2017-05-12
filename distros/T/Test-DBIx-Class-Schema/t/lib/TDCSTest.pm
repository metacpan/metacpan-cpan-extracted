package # hide from PAUSE
    TDCSTest;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use parent 'DBHelper';

use TDCSTest::Schema;


# lifted from DBIx::Class' DBICTest.pm
sub init_schema {
    my $self = shift;
    my %args = @_;

    return $self->_init_schema(
        %args,
        namespace           => __PACKAGE__,
        schema_class        => 'TDCSTest::Schema',
        db_file             => 't/var/DBIxClass.db',
        sql_file            => 't/lib/sqlite.sql',
    );
}

sub populate_schema {
    my $self    = shift;
    my $schema  = shift;

    # let's have some artists
    $schema->populate(
        'Artist',
        [
            [ qw/artistid personid name/ ],

            [ 1, 1, 'Perlfish' ],
            [ 2, 1, 'Fall Out Code' ],
            [ 3, 1, 'Inside Outers' ],
            [ 4, 1, 'Chisel' ],
        ],
    );

    # let's have some CDs
    $schema->populate(
        'CD',
        [
            [ qw/cdid artistid title year/ ],

            [ 1, 1, 'Something Smells Odd', 1999 ],
            [ 2, 1, 'Always Strict', 2001 ],
            [ 3, 2, 'Refactored Again', 2002 ],
            [ 4, 4, 'Tocata in Chisel', 2011 ],
        ],
    );

    # let's have some Tracks
    $schema->populate(
        'Track',
        [
            [ qw/trackid cdid title position/ ],

            [ 1, 4, 'Chisel Suite (part 1)', 1 ],
            [ 2, 4, 'Chisel Suite (part 2)', 2 ],
            [ 3, 4, 'Chisel Suite (part 3)', 3 ],
        ],
    );

    $schema->populate(
        'Shop',
        [
            [ qw/shopid name/ ],

            [ 1, 'Potify' ],
            [ 2, 'iTunez' ],
            [ 3, 'Media Mangler' ],
        ],
    );

    $schema->populate(
        'Person',
        [
            [ qw/personid first_name/ ],

            [ 1, 'Chisel' ],
            [ 2, 'Darius' ],
        ],
    );
    $schema->populate(
        'Audiophile',
        [
            [ qw/personid shopid/ ],

            [ 1, 1 ],
            [ 2, 3 ],
        ],
    );
}

1;
