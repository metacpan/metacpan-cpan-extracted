use strict;
use warnings;

use Test::More tests => 6;
use Test::DBUnit connection_name => 'test';
use Persistence::Meta::XML;

{
    package Photo;
    use Abstract::Meta::Class ':all';
    has '$.id';
    has '$.name';
    has '$.image';
}



use Persistence::Meta::XML;
my $meta = Persistence::Meta::XML->new(persistence_dir => 't/meta/lob/');
$meta->inject('persistence.xml');
my $entity_manager = $meta->inject('persistence.xml');

SKIP: {
    
    ::skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 6)
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
        is($photo->image, $lob, 'should fetch lob - eager method')
    }
    {
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