# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008';

requires 'Carp';
requires 'Config::Abstraction', '0.38';
requires 'ExtUtils::MakeMaker', '6.64';
requires 'File::Spec';
requires 'Log::Abstraction', '0.26';
requires 'Params::Get', '0.13';
requires 'Return::Set';
requires 'Scalar::Util';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'Errno';
	requires 'File::Temp';
	requires 'File::stat';
	requires 'IO::Handle';
	requires 'IPC::System::Simple';
	requires 'POSIX';
	requires 'Readonly';
	requires 'Test::DescribeMe';
	requires 'Test::Mockingbird', '0.10';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::NoWarnings';
	requires 'Time::HiRes';
	requires 'YAML::XS';
	requires 'autodie';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
