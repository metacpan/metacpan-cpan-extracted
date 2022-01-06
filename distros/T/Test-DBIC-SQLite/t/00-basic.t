#! perl -I.
use t::Test::abeltje;

use Test::DBIC::SQLite;

use File::Temp qw/ tempdir /;
use File::Spec::Functions qw/ catfile /;

{
    note("Check the 'connect_dbic_ok' method");
    my $tbs = Test::DBIC::SQLite->new(
        schema_class      => 'Music::Schema',
        post_connect_hook => \&populate_db
    );
    my $schema = $tbs->connect_dbic_ok();

    ok(
        exists($schema->storage->connect_info->[3]{ignore_version}),
        "ignore_version exists"
    ) or diag(explain($schema->storage->connect_info));

    my @albums = $schema->resultset('Album')->search(
        {'album_artist.name' => 'Madness'},
        {join => 'album_artist'}
    );
    is(@albums, 1, "Found 1 album") or diag(explain([map {$_->name} @albums]));

    my @songs = $albums[0]->search_related('songs', {}, {order => 'track'});
    is(@songs, 14, "Found 14 songs");
    is($songs[1]->name, 'One Step Beyond', "Correct song");
}

{
    note("Check backward-compatible function 'connect_dbic_sqlite_ok'");
    my $schema = connect_dbic_sqlite_ok(
        'Music::Schema',
        ':memory:',
        \&populate_db
    );

    ok(
        exists($schema->storage->connect_info->[3]{ignore_version}),
        "ignore_version exists"
    ) or diag(explain($schema->storage->connect_info));

    my @albums = $schema->resultset('Album')->search(
        {'album_artist.name' => 'Madness'},
        {join => 'album_artist'}
    );
    is(@albums, 1, "Found 1 album");

    my @songs = $albums[0]->search_related('songs', {}, {order => 'track'});
    is(@songs, 14, "Found 14 songs");
    is($songs[1]->name, 'One Step Beyond', "Correct song");
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $dbfile = catfile($dir, "tds-testdb-$$.sqlite3");
    note("Check dbfile is removed on 'drop_dbic_ok($dbfile)'");

    my $tbs = Test::DBIC::SQLite->new(
        schema_class      => 'Music::Schema',
        dbi_connect_info  => $dbfile,
        post_connect_hook => \&populate_db
    );
    my $schema = $tbs->connect_dbic_ok();
    ok(-e $dbfile, "The test database was created as a file");

    $schema->storage->disconnect();
    ok(! $schema->storage->connected(), "Disconnected from storage");
    $tbs->drop_dbic_ok();
    ok(! -e $dbfile, "The test database was removed as a file");
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $dbfile = catfile($dir, "tds-testdb-$$.sqlite3");
    note("Check dbfile is removed on backward-compatible function 'drop_dbic_sqlite_ok($dbfile)'");

    my $schema = connect_dbic_sqlite_ok(
        'Music::Schema',
        $dbfile,
        \&populate_db
    );

    ok(-e $dbfile, "The test database was created as a file");

    $schema->storage->disconnect();
    ok(! $schema->storage->connected(), "Disconnected from storage");
    drop_dbic_sqlite_ok();
    ok(! -e $dbfile, "The test database was removed as a file");
}

abeltje_done_testing();

sub populate_db {
    my ($schema) = @_;
    use Music::FromYAML 'artist_from_yaml';
    artist_from_yaml($schema, 't/madness.yml')
}
