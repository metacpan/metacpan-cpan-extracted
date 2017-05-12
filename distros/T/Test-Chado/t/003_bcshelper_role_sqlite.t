package TestBcsHelper;

use Moo;
use MooX::late;
use Types::Standard qw/Str/;

has 'namespace' => ( is => 'rw', isa => Str );
with 'Test::Chado::Role::Helper::WithBcs';

1;

package main;
use Test::More qw/no_plan/;
use Test::Exception;
use Bio::Chado::Schema;
use Test::TypeTiny;
use Test::Chado::DBManager::Sqlite;
use Test::Chado::Types qw/HashiFied/;

subtest 'class with BCS helper role' => sub {

    my $dbmanager = Test::Chado::DBManager::Sqlite->new();

    my $helper = new_ok('TestBcsHelper');
    lives_ok { $helper->dbmanager($dbmanager) } 'should set the dbmanager';
    isa_ok( $helper->schema, 'Bio::Chado::Schema' );
    isa_ok($helper->dynamic_schema,'DBIx::Class::Schema');
    lives_ok { $helper->namespace('test-bcs-helper') }
    'should set the namespace';
    can_ok( $helper, qw(dbrow cvrow cvterm_row) );
};

subtest 'dbrow attribute in BCS helper role' => sub {
    my $dbmanager = Test::Chado::DBManager::Sqlite->new();
    $dbmanager->deploy_schema;

    my $helper = TestBcsHelper->new(
        dbmanager => $dbmanager,
        namespace => 'test-bcs-helper'
    );
    should_pass( $helper->dbrow, HashiFied, 'should return hashref' );
    is( $helper->exist_dbrow('default'), 1, 'should have default dbrow' );
    isa_ok( $helper->get_dbrow('default'), 'DBIx::Class::Row' );
    is( $helper->get_dbrow('default')->name,
        'test-bcs-helper-db', 'should match the default db name' );

    my $new_dbrow = $helper->schema->resultset('General::Db')
        ->find_or_create( { 'name' => 'testtemprow' } );
    lives_ok { $helper->set_dbrow( 'tmp', $new_dbrow ) }
    'should create new dbrow';
    is( $helper->exist_dbrow('tmp'), 1, 'should have the created dbrow' );

};

subtest 'db table in BCS helper role' => sub {
    my $dbmanager = Test::Chado::DBManager::Sqlite->new();
    $dbmanager->deploy_schema;

    my $helper = TestBcsHelper->new(
        dbmanager => $dbmanager,
        namespace => 'test-bcs-helper'
    );

    should_pass( $helper->dbrow, HashiFied, 'should return hashref' );
    like( $helper->default_db_id, qr/^\d+$/,
        'should return the default db id' );
    is( $helper->default_db_id,
        $helper->find_db_id('default'),
        'should find the default db id'
    );

    my $new_dbrow = $helper->schema->resultset('General::Db')
        ->find_or_create( { 'name' => 'testtemprow' } );
    isnt( $helper->find_db_id( $new_dbrow->name ),
        1, 'should not find the db id' );

    is( $helper->get_dbrow('default')->db_id,
        $helper->find_or_create_db_id('default'),
        'should find db id from cache'
    );
    is( $new_dbrow->db_id,
        $helper->find_or_create_db_id( $new_dbrow->name ),
        'should find db id from database'
    );
    is( $helper->exist_dbrow( $new_dbrow->name ),
        1, 'should have cached the db id' );
    lives_ok { $helper->find_or_create_db_id('fresh') }
    'should create a new db id';
    is( $helper->exist_dbrow('fresh'), 1,
        'should have cached the new db id' );
};

subtest 'cvrow attribute in BCS helper role' => sub {
    my $dbmanager = Test::Chado::DBManager::Sqlite->new();
    $dbmanager->deploy_schema;

    my $helper = TestBcsHelper->new(
        namespace => 'test-bcs-helper',
        dbmanager => $dbmanager
    );
    should_pass( $helper->cvrow, HashiFied, 'should return hashref' );
    is( $helper->exist_cvrow('default'), 1, 'should have default cvrow' );
    isa_ok( $helper->get_cvrow('default'), 'DBIx::Class::Row' );
    is( $helper->get_cvrow('default')->name,
        'test-bcs-helper-cv', 'should match the default db name' );

    my $new_cvrow = $helper->schema->resultset('Cv::Cv')
        ->find_or_create( { 'name' => 'testtemprow' } );
    lives_ok { $helper->set_cvrow( 'tmp', $new_cvrow ) }
    'should create new cvrow';
    is( $helper->exist_cvrow('tmp'), 1, 'should have the created cvrow' );

};

subtest 'cv table in BCS helper role' => sub {
    my $dbmanager = Test::Chado::DBManager::Sqlite->new();
    $dbmanager->deploy_schema;

    my $helper = TestBcsHelper->new(
        dbmanager => $dbmanager,
        namespace => 'test-bcs-helper'
    );

    should_pass( $helper->cvrow, HashiFied, 'should return hashref' );
    like( $helper->default_cv_id, qr/^\d+$/,
        'should return the default cv id' );
    is( $helper->default_cv_id,
        $helper->find_cv_id('default'),
        'should find the default cv id'
    );

    my $new_cvrow = $helper->schema->resultset('Cv::Cv')
        ->find_or_create( { 'name' => 'testtemprow' } );
    isnt( $helper->find_db_id( $new_cvrow->name ),
        1, 'should not find the cv id' );

    is( $helper->get_cvrow('default')->cv_id,
        $helper->find_or_create_cv_id('default'),
        'should find cv id from cache'
    );
    is( $new_cvrow->cv_id,
        $helper->find_or_create_cv_id( $new_cvrow->name ),
        'should find cv id from database'
    );
    is( $helper->exist_cvrow( $new_cvrow->name ),
        1, 'should have cached the cv id' );
    lives_ok { $helper->find_or_create_cv_id('fresh') }
    'should create a new cv id';
    is( $helper->exist_cvrow('fresh'), 1,
        'should have cached the new db id' );
};

subtest 'cvterm in BCS helper role' => sub {

    my $dbmanager = Test::Chado::DBManager::Sqlite->new();
    $dbmanager->deploy_schema;

    my $helper = TestBcsHelper->new(
        dbmanager => $dbmanager,
        namespace => 'test-bcs-helper'
    );

    my $new_cvterm_row  = create_cvterm_row( $helper, 'tempcvterm' );
    my $new_cvterm_row2 = create_cvterm_row( $helper, 'tempcvterm2' );

    subtest 'manage through attribute' => sub {
        lives_ok { $helper->set_cvterm_row( 'tempcvterm', $new_cvterm_row ) }
        'should set a new cvterm';
        is( $helper->exist_cvterm_row('tempcvterm'),
            1, 'should have cached the cvterm' );
        is( $helper->get_cvterm_row('tempcvterm')->cvterm_id,
            $new_cvterm_row->cvterm_id,
            'should get back the cvterm row'
        );
    };

    subtest 'manage through find_cvterm_id method' => sub {
        is( $helper->find_cvterm_id('tempcvterm'),
            $new_cvterm_row->cvterm_id,
            'should get cvterm from cache'
        );
        is( $helper->find_cvterm_id( 'tempcvterm', 'testchado' ),
            $new_cvterm_row->cvterm_id,
            'should get cvterm from cache with cv namespace'
        );

        is( $helper->find_cvterm_id( 'tempcvterm2', 'testchado' ),
            $new_cvterm_row2->cvterm_id,
            'should get cvterm from database with cv namespace'
        );
        is( $helper->find_cvterm_id( 'tempcvterm2', 'testchado' ),
            $new_cvterm_row2->cvterm_id,
            'should get cvterm from cache with cv namespace'
        );
    };

    subtest 'manage through namespace' => sub {
        my $ids
            = [ sort { $a <=> $b }
                ( $new_cvterm_row->cvterm_id, $new_cvterm_row2->cvterm_id ) ];
        my $ids_from_cache
            = $helper->search_cvterm_ids_by_namespace('testchado');

        is_deeply(
            $ids,
            [ sort { $a <=> $b } @$ids_from_cache ],
            'should get cvterms from database for a cv namespace'
        );

        my $ids_from_cache2
            = $helper->search_cvterm_ids_by_namespace('testchado');
        is_deeply(
            $ids,
            [ sort { $a <=> $b } @$ids_from_cache2 ],
            'should get cvterms from cache for a cv namespace'
        );
    };

    subtest 'manage through find_or_create_cvterm_id method' => sub {
        my $new_cvterm_row3 = create_cvterm_row($helper,'tempcvterm3');
        is( $helper->find_or_create_cvterm_id( 'tempcvterm3', 'testchado' ),
            $new_cvterm_row3->cvterm_id,
            'should retrieve cvterm from database'
        );

        lives_ok {
            $helper->find_or_create_cvterm_id( 'tempcvterm4', 'testchado',
                'testchado', 'tempcvterm4' );
        }
        'should create new cvterm';

        is( $helper->exist_cvterm_row('tempcvterm4'),
            1, 'should cached the new cvterm' );
    };

};

sub create_cvterm_row {
    my ( $helper, $cvterm ) = @_;
    my $new_cvterm_row = $helper->schema->resultset('Cv::Cvterm')->create(
        {   name  => $cvterm,
            cv_id => $helper->schema->resultset('Cv::Cv')
                ->find_or_create( { name => 'testchado' } )->cv_id,
            dbxref => {
                accession => $cvterm,
                db_id     => $helper->schema->resultset('General::Db')
                    ->find_or_create( { name => 'testchado' } )->db_id
            }
        }
    );
    return $new_cvterm_row;
}
