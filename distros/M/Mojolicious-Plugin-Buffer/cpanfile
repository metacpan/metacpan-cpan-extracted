# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.26.0';

requires 'autodie';
requires 'Carp';
requires 'Exporter';
requires 'Fcntl';
requires 'File::Path', '2.07';
requires 'File::Spec';
requires 'IPC::System::Simple';
requires 'Mojolicious', '9.00';
requires 'Params::Get', '0.17';
requires 'Params::Validate::Strict', '0.41';
requires 'Readonly', '2.00';
requires 'Return::Set', '0.05';
requires 'Scalar::Util';
requires 'Sub::Private', '0.07';
requires 'Sub::Protected', '0.03';
requires 'Time::HiRes';
requires 'version';

recommends 'CHI';
recommends 'Compress::Zstd';
recommends 'HTML::Packer';
recommends 'IO::Compress::Brotli';
recommends 'Redis';
recommends 'Redis::Fast';

on 'test' => sub {
	requires 'Config';
	requires 'Digest::MD5';
	requires 'Encode';
	requires 'Errno';
	requires 'File::Basename';
	requires 'File::Find';
	requires 'File::Temp';
	requires 'IO::Handle';
	requires 'IO::Socket::INET';
	requires 'POSIX';
	requires 'Storable';
	requires 'Test::More';
	recommends 'IP::Country::Fast';
	recommends 'Redis';
	recommends 'Redis::Fast';
	recommends 'Test::Pod', '1.22';
	recommends 'Test::Pod::Coverage', '1.08';
	recommends 'Test::Without::Module';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod', '1.22';
	requires 'Test::Pod::Coverage', '1.08';
	recommends 'App::Test::Generator';
};
