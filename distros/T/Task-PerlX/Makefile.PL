use inc::Module::Install;
name 'Task-PerlX';
all_from 'lib/Task/PerlX.pm';

requires
    'B::OPCheck'           => 0,
    'B::Hooks::OP::Check'  => 0,
    'B::Hooks::EndOfScope' => 0,
    'B::Hooks::OP::PPAddr'     => 0,
    'B::Hooks::Parser'     => 0,
    'Scope::Guard'         => 0,
    'Devel::Declare'       => 0;

auto_include;
auto_manifest;
auto_install;
WriteAll;
