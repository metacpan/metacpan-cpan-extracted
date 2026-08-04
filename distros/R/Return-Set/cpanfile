# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010';

requires 'Carp';
requires 'Exporter';
requires 'Params::Get', '0.13';
requires 'Params::Validate::Strict', '0.37';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'IPC::System::Simple';
	requires 'Test::DescribeMe';
	requires 'Test::Most';
	requires 'Test::Needs';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
