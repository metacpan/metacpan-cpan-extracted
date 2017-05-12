use inc::Module::Install;

all_from        'lib/String/Numeric/XS.pm';
perl_version    '5.006';
bugtracker      'http://rt.cpan.org/Public/Dist/Display.html?Name=String-Numeric-XS';
test_requires   'Test::More' => '0.86';
test_requires   'Test::Exception' => '0';
test_requires   'String::Numeric' => '0';
makemaker_args  INC => '-I.';

requires_external_cc;

WriteAll;

