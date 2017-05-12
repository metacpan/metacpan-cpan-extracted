package NewDB;

use strict;
use warnings;

use DBI;
use File::Spec;

sub _file {
    return File::Spec->catfile(File::Spec->tmpdir, 'test.db');
}

sub dbi {
    return "dbi:SQLite:" . _file();
}

sub dbh {
    my $class = shift;

    my $table = _file;

    my $exists = -f $table;

    my $dbh = DBI->connect($class->dbi) or die $DBI::errstr;

    unless ($exists) {
        my $sth = $dbh->prepare(<<"");
            CREATE TABLE session (
                sid          VARCHAR(40) PRIMARY KEY,
                data         TEXT,
                expires      INTEGER UNSIGNED NOT NULL,
                UNIQUE(sid)
            );

        $sth->execute();
    }

    return $dbh;
}

1;
