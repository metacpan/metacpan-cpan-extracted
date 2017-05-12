use strict;
use warnings;

use Test::More tests => 8;
use Test::DBUnit connection_name => 'test';

my $class;

BEGIN {
    $class = 'Persistence::Entity';
    use_ok($class, ':all');
    use_ok('Persistence::Entity::Manager');
}

my $photo_entity = $class->new(
    name    => 'photo',
    alias   => 'ph',
    primary_key => ['id'],
    columns => [
        sql_column(name => 'id'),
        sql_column(name => 'name', unique => 1),
    ],
    lobs => [
        sql_lob(name => 'blob_content', size_column => 'doc_size'),
    ]
);

isa_ok($photo_entity, $class);
{
    my $entity_manager = Persistence::Entity::Manager->new(name => 'my_manager', connection_name => 'test');
    $entity_manager->add_entities($photo_entity);
}


SKIP: {
    
    ::skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 5)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
      name     => 'test',
      dsn      => $ENV{DB_TEST_CONNECTION},
      username => $ENV{DB_TEST_USERNAME},
      password => $ENV{DB_TEST_PASSWORD},
    ); 

    reset_schema_ok("t/sql/". $connection->dbms_name . "/create_schema.sql");
    {
        xml_dataset_ok('init');
        my $lob = _load_file('t/bin/data1.bin');
        $photo_entity->insert(id => "1", name => "photo1", blob_content => $lob);
        expected_xml_dataset_ok('insert');
    
        $photo_entity->update({name => "photo1", blob_content => undef}, {id => 1,});
        $photo_entity->update({name => "photo0", blob_content => $lob}, {id => 0});
        expected_xml_dataset_ok('update');
    }
    {
        my $lob = _load_file('t/bin/data2.bin');
        my $blob = $photo_entity->fetch_lob('blob_content', {id => 10});
        is($blob, $lob, 'should fetch lob');
    }
}

sub _load_file {
    my ($file) = @_;
    open my $fh, '<', $file
        or die "can't open file $file";
    local $/ = undef;
    my $result = <$fh>;
    close $fh;
    $result;
}