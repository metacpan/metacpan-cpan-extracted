# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010';

requires 'Carp';
requires 'Config::Abstraction', '0.38';
requires 'File::Spec';
requires 'File::stat';
requires 'IPC::System::Simple';   # Needed by autodie's :system (via :all)
requires 'List::Util', '1.33';   # any()
requires 'Log::Abstraction', '0.26';
requires 'POSIX';
requires 'Params::Get', '0.13';
requires 'Readonly';
requires 'Return::Set';
requires 'Scalar::Util';
requires 'Time::HiRes';
requires 'autodie';
requires 'mro';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'Errno';
	requires 'File::Temp';
	requires 'IO::Handle';
	requires 'Test::DescribeMe';
	requires 'Test::Exception';
	requires 'Test::Mockingbird', '0.10';
	requires 'Test::More';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::NoWarnings';
	requires 'Test::Returns';
	requires 'Test::Without::Module';
	requires 'YAML::XS';
	recommends 'Test::Memory::Cycle';   # t/function.t skips without it
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
