use strict;
use inc::Module::Install;

all_from        'lib/String/Numeric.pm';
perl_version    '5.006';
bugtracker      'http://rt.cpan.org/Public/Dist/Display.html?Name=String-Numeric';
test_requires   'Test::More' => '0.86';
test_requires   'Test::Exception' => '0';

WriteAll;

