package MyTestHelpers;
use strict;
use warnings;
use Rose::DBx::TestDB;
use File::Slurp;
use Rose::DB::Object::Loader;

sub new_db {
    my $db = Rose::DBx::TestDB->new;

    # load the schema
    my $schema = read_file('t/schema.sql');
    my $dbh    = $db->retain_dbh;
    for my $statement ( split( m/;/, $schema ) ) {
        $statement =~ s/\n/ /g;
        next unless $statement =~ m/\S/;

        #diag($statement);
        $dbh->do("$statement;");
    }

    # generate in-memory RDBO classes from the db
    my $loader = Rose::DB::Object::Loader->new(
        db           => $db,
        class_prefix => 'MyTest',
        base_classes => [
            qw(
                Rose::DBx::Object::Indexed
                Rose::DB::Object::Helpers
                Rose::DBx::Object::MoreHelpers
                )
        ]
    );

    $loader->make_classes;

    return $db;
}

1;
