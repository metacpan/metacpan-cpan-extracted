use strict;
use warnings;

use Test::More tests => 15;
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


        {
            package Photo;
    
            use Abstract::Meta::Class ':all';
            use Persistence::ORM ':all';
            entity 'photo';

            column 'id'   => has('$.id');
            column 'name' => has('$.name');
            lob    'blob_content' => (attribute => has('$.image'), fetch_method => LAZY);
        }

        {
            package EagerPhoto;
    
            use Abstract::Meta::Class ':all';
            use Persistence::ORM ':all';
            entity 'photo';

            column 'id'   => has('$.id');
            column 'name' => has('$.name');
            lob    'blob_content' => (attribute => has('$.image'), fetch_method => EAGER);
        }


my $entity_manager;
isa_ok($photo_entity, $class);
$entity_manager = Persistence::Entity::Manager->new(name => 'my_manager', connection_name => 'test');
$entity_manager->add_entities($photo_entity);



SKIP: {
    
    ::skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 12)
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
        my ($photo) = $entity_manager->find(photo => 'Photo', id => 10);
        isa_ok($photo, 'Photo');
        my $lob = _load_file('t/bin/data2.bin');
        ok(! $photo->{'$.image'}, 'should not have value');
        is($photo->image, $lob, 'should fetch lob - eager method')
    }
    
    {
       xml_dataset_ok('init');
        my ($photo) = $entity_manager->find(photo => 'EagerPhoto', id => 10);
        isa_ok($photo, 'EagerPhoto');
        my $lob = _load_file('t/bin/data2.bin');
        ok($photo->{'$.image'}, 'should have value');
        is($photo->image, $lob, 'should fetch lob - lazy method')
    }

    {
        xml_dataset_ok('init');
        my $lob = _load_file('t/bin/data1.bin');
        my $photo = Photo->new(id => "1", name => "photo1", image => $lob);
        $entity_manager->insert($photo);
        expected_xml_dataset_ok('insert');
        $photo->set_image(undef);
        $entity_manager->update($photo);
        my ($photo_0) = $entity_manager->find(photo => 'Photo', id => 0);
        
        $photo_0->name('photo0');
        $photo_0->set_image($lob);
        $entity_manager->update($photo_0);
        expected_xml_dataset_ok('update');
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