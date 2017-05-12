#!perl -wT
use strict;
use warnings;
use Test::More;
use Schema::RackTables;


my $module = "Schema::RackTables";
my %latest = ( version => "0.20.11", schema => "0.20.11" );
my @cases = (
    { version => "0.14.5",  schema => "0.14.4" },
    { version => "0.18.0",  schema => "0.18.0" },
    { version => "0.20.10", schema => "0.20.9" },
);

my @db_params = ( "dbi:SQLite:t/racktables.sqlite", "", "" );
$" = "', '";

plan tests => 11 + 8 * @cases;


# test with invalid versions
my $app = eval { $module->new(version => "plonk") };
like $@, qr/^invalid version 'plonk'/, "$module->new(version => 'plonk')";

$app = eval { $module->new(version => "1.2") };
like $@, qr/^invalid version '1.2'/, "$module->new(version => 'plonk')";

$app = eval { $module->new(version => "1.2.3.4") };
like $@, qr/^invalid version '1.2.3.4'/, "$module->new(version => 'plonk')";


# test with latest
$app = eval { $module->new(version => "latest") };
is $@, "", "\$app = $module->new(version => 'latest')";
isa_ok $app, $module, '$app';

SKIP: {
    skip "\$app undefined, aborting this case", 6 unless $app;

    is $app->version, $latest{version},
        "\$app->version = '$latest{version}'";

    is $app->schema_version, $latest{schema},
        "\$app->schema_version = '$latest{schema}'";

    (my $vn = $latest{schema}) =~ s/\./_/g;
    is $app->schema, "$module\::$vn",
        "\$app->schema = '$module\::$vn'";

    my $db = eval { $app->schema->connect(@db_params) };
    is $@, "", "\$db = \$app->connect('@db_params')";
    isa_ok $db, $app->schema, '$db';
    isa_ok $db, "DBIx::Class::Schema", '$db';
}


# test with some well known versions
for my $case (@cases) {
    my $app = eval { $module->new(version => $case->{version}) };
    is $@, "", "\$app = $module->new(version => '$case->{version}')";
    isa_ok $app, $module, '$app';

    SKIP: {
        skip "\$app undefined, aborting this case", 6 unless $app;

        is $app->version, $case->{version},
            "\$app->version = '$case->{version}'";

        is $app->schema_version, $case->{schema},
            "\$app->schema_version = '$case->{schema}'";

        (my $vn = $case->{schema}) =~ s/\./_/g;
        is $app->schema, "$module\::$vn",
            "\$app->schema = '$module\::$vn'";

        my $db = eval { $app->schema->connect(@db_params) };
        is $@, "", "\$db = \$app->connect('@db_params')";
        isa_ok $db, $app->schema, '$db';
        isa_ok $db, "DBIx::Class::Schema", '$db';
    }
}

