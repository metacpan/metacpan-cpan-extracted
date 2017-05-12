package DBSchema;

# Created by DBIx::Class::Schema::Loader v0.03000 @ 2006-10-02 08:24:09

use strict;
use warnings;

use base 'DBIx::Class::Schema';
use DateTime;

__PACKAGE__->load_namespaces( default_resultset_class => '+DBIx::Class::ResultSet::RecursiveUpdate' );

sub get_test_schema {
    my ( $dsn, $user, $pass ) = @_;
    $dsn ||= 'dbi:SQLite:dbname=t/var/dvdzbr.db';
    warn "testing $dsn";
    my $schema = __PACKAGE__->connect( $dsn, $user, $pass, {} );
    $schema->deploy({ add_drop_table => 1, });
    $schema->populate('User', [
        [ qw/username name password / ],
        [ 'jgda', 'Jonas Alves', ''],
        [ 'isa' , 'Isa', '', ],
        [ 'zby' , 'Zbyszek Lukasiak', ''],
        ]
    );
    $schema->populate('Tag', [
        [ qw/name file / ],
        [ 'comedy', '' ],
        [ 'dramat', '' ],
        [ 'australian', '' ],
        ]
    );
    $schema->populate('Dvd', [
        [ qw/name imdb_id owner current_borrower creation_date alter_date / ],
        [ 'Picnick under the Hanging Rock', 123, 1, 3, '2003-01-16 23:12:01', undef ],
        [ 'The Deerhunter', 1234, 1, 1, undef, undef ],
        [ 'Rejs', 1235, 3, 1, undef, undef ],
        [ 'Seksmisja', 1236, 3, 1, undef, undef ],
        ]
    ); 
    $schema->populate( 'Dvdtag', [
        [ qw/ dvd tag / ],
        [ 1, 2 ],
        [ 1, 3 ],
        [ 3, 1 ],
        [ 4, 1 ],
        ]
    );
    return $schema;
}
    
    
1;

