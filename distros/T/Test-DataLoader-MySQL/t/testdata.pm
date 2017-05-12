use Test::DataLoader::MySQL;

my $data = Test::DataLoader::MySQL->init();
$data->add('foo', 1,
           {
               id => 1,
               name => 'aaa',
           },
           ['id']);
$data->add('foo', 2,
           {
               id => 2,
               name => 'bbb',
           },
           ['id']);
