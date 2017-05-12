use strict;
use Test::More 0.98;

use SQL::Translator;
use File::Spec;

sub do_test {
    my $type = shift;

    my $parser = {
        mysql  => 'MySQL',
        sqlite => 'SQLite',
    }->{$type};

    my $t = SQL::Translator->new();
    $t->parser($parser);
    $t->filename(File::Spec->catfile('t', 'schema', "$type.sql")) or die $t->error;

    $t->producer('DBIxSchemaDSL');
    my $result = $t->translate or die $t->error;
    is $result, <<'EOD', $type;
use strict;
use warnings;

use DBIx::Schema::DSL;


create_table author => columns {
    integer 'id', not_null, primary_key, auto_increment;
    varchar 'name', size => 255, unique;
    tinyint 'age', not_null, default => 0;
    text 'message', not_null;
};

create_table module => columns {
    integer 'id', not_null, primary_key, auto_increment;
    varchar 'name', size => 255;
    integer 'author_id';

    add_index author_id_idx => [qw/author_id/];

    belongs_to 'author';
};

1;
EOD
}

for my $type (qw/mysql sqlite/) {
    subtest $type => sub {
        do_test($type);
    };
}

done_testing;
