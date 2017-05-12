use Test::More qw/no_plan/;
use Data::Dumper;
use Test::Mojo;
use FindBin;
use lib "$FindBin::Bin/lib/book/lib";

BEGIN {
    $ENV{MOJO_LOG_LEVEL} ||= 'fatal';
}

use_ok('Book');
my $test = Test::Mojo->new( app => 'Book' );
$test->get_ok('/books');
my $app = $test->app;
can_ok( $app, 'myconfig' );
is_deeply(
    $app->myconfig,
    { status => 'test', book => 'new' },
    'It has the config value'
);

SKIP: {
    eval { require DBD::SQLite };
    skip 'Need DBD::SQLite to run test for bcs plugin' if $@;
    use_ok('Bcs');
    my $btest = Test::Mojo->new( app => 'Bcs' );
    $btest->get_ok('/bcs');
    my $bapp = $btest->app;
    can_ok( $bapp, 'model' );
    isa_ok( $bapp->model, 'Bio::Chado::Schema' );
}

SKIP: {
    eval { require DBD::Oracle };
    skip 'Need DBD::Oracle to run test for bcs plugin' if $@;
    use_ok('BcsOra');
    my $botest = Test::Mojo->new( app => 'BcsOra' );
    $botest->get_ok('/bcsora');
    my $boapp = $botest->app;
    can_ok( $boapp, 'oracle_model' );
    my $schema = $boapp->oracle_model;
    isa_ok( $schema, 'Bio::Chado::Schema' );
    is( $schema->source('Cv::Cvtermsynonym')->has_column('synonym_'),
        1, 'It has oracle specific synonym column' );
    is( $schema->source('Sequence::Feature')->has_column('is_deleted'),
        1, 'It has oracle specific is_deleted column' );
    isnt( $schema->source('Organism::Organism')->has_column('comment'),
        1, 'It do not have specific comment column' );
}
