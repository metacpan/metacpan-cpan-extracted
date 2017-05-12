use inc::Module::Install;

name 'Task-Toolchain-Test';
abstract 'Install the most common Test toolchain modules';
author 'Curtis "Ovid" Poe <ovid@cpan.org>';
version_from 'lib/Task/Toolchain/Test.pm';
license 'perl';

# All the things we need for Foo
requires 'perl' => '5.006';

requires 'Test::Simple'          => '0.94';
requires 'Test::Harness'         => '3.21';
requires 'Test::Exception'       => '0.29';
requires 'Test::NoWarnings'      => '1.01';
requires 'Test::Builder::Tester' => '1.01';
requires 'Test::Deep'            => '0.106';
requires 'Test::Pod'             => '1.42';
requires 'Test::Pod::Coverage'   => '1.08';
requires 'Test::Kwalitee'        => '1.01';
requires 'Test::Distribution'    => '2.00';
requires 'Test::Warn'            => '0.21';
requires 'Test::Differences'     => '0.500';
requires 'Test::Spelling'        => '0.11';
requires 'Test::MockObject'      => '1.09';
requires 'Test::UseAllModules'   => '0.12';
requires 'Test::Most'            => '0.21';
requires 'Test::Class'           => '0.34';
requires 'Test::Class::Most'     => '0.05';

resources(
    repository => 'http://github.com/Ovid/Task-Toolchain-Test',
    license    => 'http://dev.perl.org/licenses/',
);

# Too many test failures
#requires 'Test::WWW::Mechanize' => '1.26';

WriteAll;
