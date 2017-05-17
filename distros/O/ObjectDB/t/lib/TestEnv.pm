package TestEnv;

use strict;
use warnings;

use TestDBH;

my %TABLES = (
    'person' => <<'',
    CREATE TABLE `person` (
     `id` INTEGER PRIMARY KEY AUTOINCREMENT,
     `name` varchar(40) DEFAULT '',
     `profession` varchar(40),
     `age` INTEGER
    );

    'author' => <<'',
    CREATE TABLE `author` (
     `id` INTEGER PRIMARY KEY AUTOINCREMENT,
     `name` varchar(40)
    );

    'book' => <<'',
    CREATE TABLE `book` (
     `id` INTEGER PRIMARY KEY AUTOINCREMENT,
     `author_id` INTEGER NOT NULL DEFAULT 0,
     `title` varchar(40)
    );

    'book_description' => <<'',
    CREATE TABLE `book_description` (
     `id` INTEGER PRIMARY KEY AUTOINCREMENT,
     `book_id` INTEGER NOT NULL DEFAULT 0,
     `description` varchar(40)
    );

    'tag' => <<'',
    CREATE TABLE `tag` (
     `id` INTEGER PRIMARY KEY AUTOINCREMENT,
     `name` varchar(40)
    );

    'book_tag_map' => <<'',
    CREATE TABLE `book_tag_map` (
     `book_id` INTEGER,
     `tag_id` INTEGER,
     PRIMARY KEY(`book_id`, `tag_id`)
    );

    'thread' => <<'',
    CREATE TABLE `thread` (
     `id` INTEGER PRIMARY KEY AUTOINCREMENT,
     `author_id` INTEGER,
     `title` varchar(40)
    );

    'reply' => <<'',
    CREATE TABLE `reply` (
     `id` INTEGER PRIMARY KEY AUTOINCREMENT,
     `author_id` INTEGER,
     `thread_id` INTEGER,
     `parent_id` INTEGER,
     `content` varchar(40)
    );

    'notification' => <<'',
    CREATE TABLE `notification` (
     `id` INTEGER PRIMARY KEY AUTOINCREMENT,
     `reply_id` INTEGER
    );

    'auto' => <<'',
    CREATE TABLE `auto` (
     `id` INTEGER PRIMARY KEY AUTOINCREMENT,
     `varchar_no_default` varchar(40),
     `varchar_default_empty` varchar(40) DEFAULT '',
     `varchar_default` varchar(40) DEFAULT 'hello',
     `int_no_default` INTEGER,
     `int_default_empty` INTEGER DEFAULT 0,
     `int_default` INTEGER DEFAULT 123,
     `bool_no_default` BOOLEAN,
     `bool_default_false` BOOLEAN DEFAULT 0,
     `bool_default_true` BOOLEAN DEFAULT 1
    );

);

sub prepare_table {
    my $class = shift;
    my ($table) = @_;

    my $dbh = TestDBH->dbh;

    $dbh->do("DROP TABLE IF EXISTS " . $dbh->quote_identifier($table));

    die "Unknown table '$table'" unless exists $TABLES{$table};

    my $sql = $TABLES{$table};

    my $driver = $dbh->{Driver}->{Name};

    if ($driver =~ /mysql/i) {
        $sql =~ s{AUTOINCREMENT}{AUTO_INCREMENT}g;
    } elsif ($driver =~ /Pg/i) {
        $sql =~ s{`}{"}g;
        $sql =~ s{"id" INTEGER PRIMARY KEY AUTOINCREMENT}{"id" SERIAL PRIMARY KEY}g;
        $sql =~ s{BOOLEAN DEFAULT 0}{BOOLEAN DEFAULT 'f'}g;
        $sql =~ s{BOOLEAN DEFAULT 1}{BOOLEAN DEFAULT 't'}g;
    }

    $dbh->do($sql);
}

1;
