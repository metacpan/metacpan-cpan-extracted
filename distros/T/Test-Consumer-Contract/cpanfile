# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.014';

requires 'Carp';
requires 'Cwd';
requires 'Exporter';
requires 'File::Basename';
requires 'File::Find';
requires 'File::Spec';
requires 'IPC::System::Simple';   # autodie qw(:all) covers system()
requires 'List::Util';
requires 'Module::Runtime';
requires 'Params::Get', '0.17';
requires 'Params::Validate::Strict', '0.41';
requires 'Readonly';
requires 'Return::Set', '0.05';
requires 'Scalar::Util';
requires 'Sub::Private', '0.06';
requires 'Sub::Protected', '0.03';
requires 'Test::More';   # the module emits TAP itself
requires 'Text::Balanced';
requires 'autodie';
requires 'lib';

on 'test' => sub {
	requires 'Data::Dumper';
	requires 'Errno';
	requires 'File::Path';
	requires 'File::Temp';
	requires 'POSIX';
	requires 'Test::DescribeMe';
	requires 'Test::Most';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
