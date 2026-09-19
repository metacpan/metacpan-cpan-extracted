# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.036';

requires 'Carp';
requires 'Compress::Zlib';
requires 'File::Basename';
requires 'File::Find';
requires 'File::Path';
requires 'File::Spec';
requires 'Getopt::Long';
requires 'List::Util';
requires 'Object::Configure';
requires 'POSIX';
requires 'Params::Get';
requires 'Params::Validate::Strict';
requires 'Pod::Usage';
requires 'Readonly';
requires 'Scalar::Util';
requires 'autodie';
requires 'strict';
requires 'warnings';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'File::Copy';
	requires 'File::Temp';
	requires 'IPC::System::Simple';
	requires 'Test::Exception';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird';
	requires 'Test::More';
	requires 'Test::Most';
	requires 'Test::Returns';
	requires 'Test::Without::Module';
	requires 'XML::PP';   # pure-Perl XML parser; no libxml2 dependency required
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
