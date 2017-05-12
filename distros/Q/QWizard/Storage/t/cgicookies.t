# This is -*- perl -*-

use QWizard::Storage::CGICookie;

$stobj = new QWizard::Storage::CGICookie();

$maxtests = 2;
do "t/tests.pl";

if ($stobj && $maxtests) {
    # noop: avoid perl warnings about var not being used again
}
