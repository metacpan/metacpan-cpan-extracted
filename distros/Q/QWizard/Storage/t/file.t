# This is -*- perl -*-

use QWizard::Storage::File;

$stobj = new QWizard::Storage::File(file => 'testfile.dat');

do "t/tests.pl";

if ($stobj) {
    # noop: avoid perl warnings about var not being used again
}
