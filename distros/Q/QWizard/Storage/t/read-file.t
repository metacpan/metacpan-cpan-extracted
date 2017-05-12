# This is -*- perl -*-

use QWizard::Storage::File;

$stobj = new QWizard::Storage::File(file => 'testfile.dat');

$stobj->load_data();

use Test::More tests => 1;

ok($stobj->get('myname','Wesley'), "testing param from read file");
unlink('testfile.dat');
