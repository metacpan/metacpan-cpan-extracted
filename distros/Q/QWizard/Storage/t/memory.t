# This is -*- perl -*-

use QWizard::Storage::Memory;

$stobj = new QWizard::Storage::Memory();

do "t/tests.pl";

if ($stobj) {
    # noop: avoid perl warnings about var not being used again
}
