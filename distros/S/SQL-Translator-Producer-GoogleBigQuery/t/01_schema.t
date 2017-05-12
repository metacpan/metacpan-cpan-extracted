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

    $t->producer('GoogleBigQuery');
    my $result = $t->translate or die $t->error;
    is_deeply $result => [
        {
            name   => 'author',
            schema => [
                {
                    name => 'id',
                    type => 'integer',
                },
                {
                    name => 'name',
                    type => 'string',
                },
            ],
        },
        {
            name   => 'module',
            schema => [
                {
                    name => 'id',
                    type => 'integer',
                },
                {
                    name => 'name',
                    type => 'string',
                },
                {
                    name => 'author_id',
                    type => 'integer',
                },
            ],
        },
    ];
}

for my $type (qw/mysql sqlite/) {
    subtest $type => sub {
        do_test($type);
    };
}

done_testing;
