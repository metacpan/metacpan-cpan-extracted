use strict;
use Test::More 0.98;

use SQL::Translator;
use File::Spec;

sub do_test_unsigned {
    my $type = shift;

    my $parser = {
        mysql  => 'MySQL',
        sqlite => 'SQLite',
    }->{$type};

    my $t = SQL::Translator->new();
    $t->parser($parser);
    $t->filename(File::Spec->catfile('t', 'schema', "$type.sql")) or die $t->error;

    $t->producer('DBIxSchemaDSL', { default_unsigned => 1 });
    my $result = $t->translate or die $t->error;
    is $result, <<'EOD', $type;
use strict;
use warnings;

use DBIx::Schema::DSL;

default_unsigned;

create_table author => columns {
    integer 'id', signed, not_null, primary_key, auto_increment;
    varchar 'name', size => 255, unique;
    tinyint 'age', signed, not_null, default => 0;
    text 'message', not_null;
};

create_table module => columns {
    integer 'id', signed, not_null, primary_key, auto_increment;
    varchar 'name', size => 255;
    integer 'author_id', signed;

    add_index author_id_idx => [qw/author_id/];

    belongs_to 'author';
};

1;
EOD
}

sub do_test_not_null {
    my $type = shift;

    my $parser = {
        mysql  => 'MySQL',
        sqlite => 'SQLite',
    }->{$type};

    my $t = SQL::Translator->new();
    $t->parser($parser);
    $t->filename(File::Spec->catfile('t', 'schema', "$type.sql")) or die $t->error;

    $t->producer('DBIxSchemaDSL', { default_not_null => 1 });
    my $result = $t->translate or die $t->error;
    is $result, <<'EOD', $type;
use strict;
use warnings;

use DBIx::Schema::DSL;

default_not_null;

create_table author => columns {
    integer 'id', primary_key, auto_increment;
    varchar 'name', size => 255, null, unique;
    tinyint 'age', default => 0;
    text 'message';
};

create_table module => columns {
    integer 'id', primary_key, auto_increment;
    varchar 'name', size => 255, null;
    integer 'author_id', null;

    add_index author_id_idx => [qw/author_id/];

    belongs_to 'author';
};

1;
EOD
}

sub do_test_both {
    my $type = shift;

    my $parser = {
        mysql  => 'MySQL',
        sqlite => 'SQLite',
    }->{$type};

    my $t = SQL::Translator->new();
    $t->parser($parser);
    $t->filename(File::Spec->catfile('t', 'schema', "$type.sql")) or die $t->error;

    $t->producer('DBIxSchemaDSL', { default_not_null => 1, default_unsigned => 1, });
    my $result = $t->translate or die $t->error;
    is $result, <<'EOD', $type;
use strict;
use warnings;

use DBIx::Schema::DSL;

default_unsigned;
default_not_null;

create_table author => columns {
    integer 'id', signed, primary_key, auto_increment;
    varchar 'name', size => 255, null, unique;
    tinyint 'age', signed, default => 0;
    text 'message';
};

create_table module => columns {
    integer 'id', signed, primary_key, auto_increment;
    varchar 'name', size => 255, null;
    integer 'author_id', signed, null;

    add_index author_id_idx => [qw/author_id/];

    belongs_to 'author';
};

1;
EOD
}

for my $type (qw/mysql sqlite/) {
    subtest $type => sub {
        do_test_unsigned($type);
        do_test_not_null($type);
        do_test_both($type);
    };
}

done_testing;
