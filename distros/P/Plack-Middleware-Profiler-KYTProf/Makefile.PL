sub use_test_base {
    warn "You need to install Test::Base to run make test from git clone";
}

use inc::Module::Install;

name 'Plack-Middleware-Profiler-KYTProf';
all_from 'lib/Plack/Middleware/Profiler/KYTProf.pm';

requires(
    'parent'         => 0,
    'Plack'          => 0,
    'Devel::KYTProf' => '0.04',
    'Module::Load'   => 0,
);
test_requires(
    'Test::More'     => '0.98',
    'Test::Requires' => 0,
);
use_test_base;
auto_include;
WriteAll;
