use strict;
use warnings;
use Test::More;
use Mojo::Base -signatures;
use Mojolicious;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use File::Temp qw(tempdir);

# ─────────────────────────────────────────────────────────────────────────
# Action::DBIx must DIE (not fail silently) when a plugin's Result class
# cannot be loaded — e.g. a missing dependency such as
# DBIx::Class::TimeStamp. This is what makes the "Can't find source for X"
# class of failures visible at startup instead of at first query.
# ─────────────────────────────────────────────────────────────────────────

my $tmpdir = tempdir(CLEANUP => 1);
my $dbfile = "$tmpdir/test.db";

my $app = Mojolicious->new;
$app->moniker('BrokenTest');
$app->log->level('fatal');

my $loaded = eval {
    $app->plugin('Fondation' => {
        dependencies => [
            {
                'Fondation::Model::DBIx::Async' => {
                    backends => [
                        main => {
                            dsn          => "dbi:SQLite:dbname=$dbfile",
                            schema_class => 'TestDBIxAsyncSchema',
                            workers      => 1,
                        },
                    ],
                    models => {},
                },
            },
            'Fondation::TestDBIxBroken',
        ],
    });
    1;
};

ok(!$loaded, 'plugin loading dies when a Result class cannot load');
like($@, qr/Cannot load Result class/,
    'die message identifies the failing step');
like($@, qr/TestDBIxBroken::Schema::Result::Broken/,
    'die message names the failing Result class');
like($@, qr/Can't locate/,
    'die message includes the underlying error (missing dependency)');

done_testing;
