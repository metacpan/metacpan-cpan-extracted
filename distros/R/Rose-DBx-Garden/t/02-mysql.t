use Test::More tests => 25;

SKIP: {

    unless ( $ENV{RDG_TEST} ) {
        skip 'set RDG_TEST=1 to test mysql', 25;
    }

    use_ok('Rose::DB');
    use_ok('Rose::DBx::Garden');
    use File::Temp ('tempdir');
    use Path::Class;

    my $debug = $ENV{PERL_DEBUG} || 0;

    Rose::DB->register_db(
        driver   => 'mysql',
        database => 'rdgc',
        username => 'rdgc',
        password => 'rdgc',
    );
    my $db     = Rose::DB->new;
    my @tables = qw(
        one
        two
        three
        four
        five
        six
        seven
        eight
        nine
        ten
    );

    # create all test tables
    for my $table (@tables) {
        $db->dbh->do("DROP TABLE $table;");
        ok( $db->dbh->do( "
    CREATE TABLE $table (
    id       int primary key,
    name     varchar(16)
    );" ),
            "table $table created"
        );

    }

    # make the garden
    ok( my $garden = Rose::DBx::Garden->new(
            db              => $db,
            find_schemas    => 0,
            garden_prefix   => 'MySQLTest',
            force_install   => 1,
            column_to_label => sub {
                my ( $garden_obj, $col_name ) = @_;
                return join(
                    ' ', map { ucfirst($_) }
                        split( m/_/, $col_name )
                );
            }
        ),
        "garden obj created"
    );

    my $dir
        = $debug
        ? '/tmp/rose_garden'
        : tempdir( 'rose_garden_mysql_XXXX', CLEANUP => 1 );

    ok( $garden->make_garden($dir), "make_garden" );

    # make sure all the files were created.
    # get db name as $garden made it

    # are the files there?
    ok( -s file( $dir, 'MySQLTest.pm' ), "base class exists" );
    for my $table (@tables) {
        my $class = ucfirst($table);
        ok( -s file( $dir, 'MySQLTest', 'Rdgc', $class . '.pm' ),
            "table class $class exists" );
    }

}

