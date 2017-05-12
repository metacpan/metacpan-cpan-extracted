use inc::Module::Install 0.97;
use Module::Install::GithubMeta 0.10;

name 'Simulation-DiscreteEvent';
all_from 'lib/Simulation/DiscreteEvent.pm';
author q{Pavel Shaydo <zwon@cpan.org>};
license 'perl';
githubmeta;

test_requires 'Test::More'    => 0.63;
test_requires 'Test::use::ok' => 0;
test_requires 'Test::Most'    => 0;
test_requires 'Math::Random'  => 0;

requires Moose                      => 0;
requires 'Module::Load'             => 0;
requires 'MooseX::MethodAttributes' => 0.19;
requires 'namespace::clean'         => 0.13;

WriteAll;

