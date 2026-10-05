# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.014';

requires 'Attribute::Handlers';
requires 'B::Hooks::EndOfScope';
requires 'Carp';
requires 'IPC::System::Simple';
requires 'Params::Validate::Strict', '0.33';
requires 'Readonly';
requires 'Return::Set';
requires 'Sub::Identify';
requires 'namespace::clean';

on 'test' => sub {
	requires 'File::Spec';
	requires 'File::Temp';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::NoWarnings';
	recommends 'Moo';
	recommends 'Moose';
	recommends 'Test::Mockingbird';
	recommends 'Test::Returns';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
