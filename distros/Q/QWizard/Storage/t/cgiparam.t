# This is -*- perl -*-

use QWizard::Storage::CGIParam;

$stobj = new QWizard::Storage::CGIParam();

do "t/tests.pl";

if ($stobj) {
    # noop: avoid perl warnings about var not being used again
}
