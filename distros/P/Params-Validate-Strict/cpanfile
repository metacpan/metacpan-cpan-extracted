# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008';

requires 'Carp';
requires 'Encode';
requires 'Exporter';
requires 'ExtUtils::MakeMaker', '6.64';
requires 'List::Util', '1.33';
requires 'Params::Get', '0.13';
requires 'Readonly::Values::Boolean';
requires 'Scalar::Util';
requires 'Unicode::GCString';
requires 'strict';
requires 'warnings';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'File::Glob';
	requires 'File::Slurp';
	requires 'File::stat';
	requires 'IPC::Run3';
	requires 'IPC::System::Simple';
	requires 'JSON::MaybeXS';
	requires 'POSIX';
	requires 'Readonly';
	requires 'Test::Compile';
	requires 'Test::DescribeMe';
	requires 'Test::Mockingbird', '0.10';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::Warnings';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
