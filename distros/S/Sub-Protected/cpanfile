# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008';

requires 'Attribute::Handlers';
requires 'Carp';
requires 'Params::Get';
requires 'Params::Validate::Strict';
requires 'Readonly';
requires 'Return::Set';

on 'test' => sub {
	requires 'IPC::System::Simple';
	requires 'Moo';
	requires 'Test::Exception';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird';
	requires 'Test::Most';
	requires 'Test::Returns';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
