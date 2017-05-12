use strict;
use warnings;

use Test::More tests => 2;

diag(' '); # Wraps message to next line
diag('To prevent skipping the following tests, set the following environment varibles:');
diag('FMS_HOST - Your accessible FileMaker Server. Must be a valid formatted URI.');
diag('FMS_USER - Valid Username.');
diag('FMS_PASS - Password.');
diag('If you do not set these vars, the tests will just skip where necessary and you will not get complete coverage.');
diag('It is recommended to use a test or development server for this suite, just in case.');

BEGIN
{
    use_ok( 'Net::FileMaker::XML' ) || print "Bail out!";
    use_ok('Net::FileMaker::XML::Database');
}

