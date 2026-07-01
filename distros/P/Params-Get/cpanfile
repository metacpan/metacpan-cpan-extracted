# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010001';

requires 'Carp';
requires 'Readonly';
requires 'Scalar::Util';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'Error';
	requires 'IPC::System::Simple';
	requires 'Params::Validate::Strict';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird', '0.08';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::Returns';
	requires 'Test::Without::Module';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
