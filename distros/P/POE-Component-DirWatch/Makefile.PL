# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'POE-Component-DirWatch';
author 'Guillermo Roditi <groditi@cpan.org>';
license 'perl';
abstract 'Directory Watcher for POE';

all_from 'lib/POE/Component/DirWatch.pm';

tests 't/*.t';

requires 'POE'             => 0.12;
requires 'Moose'           => 0.24;
requires 'Class::Load'     => 0.20;
requires 'Path::Class'     => 0;
requires 'File::Signature' => 0;
requires 'MooseX::Types::Path::Class' => 0;

recommends 'POE::Component::AIO' => '1.00';

test_requires 'FindBin';
test_requires 'Time::HiRes';
test_requires 'Test::More';

repository 'https://github.com/arcanez/poe-component-dirwatch';
bugtracker 'https://rt.cpan.org/Public/Dist/Display.html?Name=POE-Component-DirWatch';

WriteAll;
