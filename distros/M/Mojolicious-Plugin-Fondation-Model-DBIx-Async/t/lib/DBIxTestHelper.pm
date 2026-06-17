package DBIxTestHelper;

# ABSTRACT: Test helpers for Fondation::Model::DBIx::Async.

use strict;
use warnings;
use Mojo::Base -signatures;

use Exporter 'import';
use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

our @EXPORT_OK = qw(build_dbtest_app);

# Build a Fondation app with a single DBIx::Async backend using
# TestDBIxAsyncSchema and the TestDBIxAsync plugin (Action::DBIx
# auto-discovers Result classes).
# Returns ($app, $dbfile).
sub build_dbtest_app ($tempdir) {
    my $dbfile = "$tempdir/test.db";
    my $app = create_test_app($tempdir);

    $app->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::Model::DBIx::Async' => {
                backends => [
                    main => {
                        dsn          => "dbi:SQLite:dbname=$dbfile",
                        schema_class => 'TestDBIxAsyncSchema',
                        workers      => 1,
                    },
                ],
            }},
            'Fondation::TestDBIxAsync',
        ],
    });

    return ($app, $dbfile);
}

1;
