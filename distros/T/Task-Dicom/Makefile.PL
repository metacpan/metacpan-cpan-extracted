# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Install the Dicom modules.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Task-Dicom';
readme_from 'Dicom.pm';
recursive_author_tests('xt');
requires 'DicomPack::IO::DicomWriter' => 0.95;
requires 'Dicom::DCMTK::DCMDump::Get' => 0.03;
requires 'Dicom::DCMTK::DCMQRSCP::Config' => 0.03;
requires 'Dicom::File::Detect' => 0.03;
requires 'Dicom::UID::Generator' => 0.01;
requires 'File::Find::Rule::Dicom' => 0.04;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Task-Dicom';
resources 'homepage' => 'https://github.com/tupinek/Task-Dicom';
resources 'repository' => 'git://github.com/tupinek/Task-Dicom';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.07';

# Run.
WriteAll();
