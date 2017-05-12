use inc::Module::Install;

name 'Plack-Middleware-AddDefaultCharset';
all_from 'lib/Plack/Middleware/AddDefaultCharset.pm';

license 'perl';
readme_from 'lib/Plack/Middleware/AddDefaultCharset.pm';

requires 'Plack' => '0.9925';
test_requires 'Test::More' => 0.88;

WriteAll;
