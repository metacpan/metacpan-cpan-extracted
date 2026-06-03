# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008';

requires 'DateTime::Format::ISO8601';
requires 'Email::Valid';
requires 'JSON::MaybeXS';
requires 'LWP::Protocol::https';
requires 'LWP::UserAgent';
requires 'Mojolicious';
requires 'Params::Get';
requires 'Params::Validate::Strict';
requires 'Readonly';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'FindBin';
	requires 'IPC::System::Simple';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::RequiresInternet';
	requires 'Test::Returns';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
