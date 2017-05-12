use inc::Module::Install;
name 'Plack-Middleware-Profiler-NYTProf';
all_from 'lib/Plack/Middleware/Profiler/NYTProf.pm';

requires(
    'parent'         => 0,
    'Plack'          => 0,
    'Devel::NYTProf' => '5.06',
    'Time::HiRes'    => 0,
    'File::Which'    => 0,
);
test_requires(
    'Test::More'                   => '0.98',
    'Module::Install::AuthorTests' => 0,
    'File::Temp'                   => 0,
    'File::Spec'                   => 0,
    'Exporter'                     => 0,
);
use_test_base;
auto_include;
WriteAll;
