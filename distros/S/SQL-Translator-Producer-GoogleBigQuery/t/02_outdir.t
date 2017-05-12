use strict;
use Test::More 0.98;

use SQL::Translator;
use File::Temp qw/tempdir/;
use File::Spec;
use JSON::PP qw/decode_json/;

my $outdir = tempdir(CLEANUP => 1);

sub slurp {
    my $file = shift;
    open my $fh, '<', $file or die $!;
    local $/;
    return <$fh>;
}

sub test_schema {
    my ($table_name, $schema) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    subtest $table_name => sub {
        my $file = File::Spec->catfile($outdir, "$table_name.json");
        ok -f $file, "$file is exists";
        my $body    = slurp($file);
        my $content = eval { decode_json($body) };
        is $@, '', 'no error to decode json' or diag $@;
        is_deeply($content, $schema, 'schema is valid.');
    };
}

my $t = SQL::Translator->new();
$t->parser('MySQL');
$t->filename(File::Spec->catfile('t', 'schema', 'mysql.sql')) or die $t->error;

$t->producer('GoogleBigQuery', outdir => $outdir);
$t->translate or die $t->error;

test_schema author => [
    {
        name => 'id',
        type => 'integer',
    },
    {
        name => 'name',
        type => 'string',
    },
];
test_schema module => [
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
];

done_testing;
