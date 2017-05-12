BEGIN {
	my @mip = qw(
		Module::Install::AuthorTests
		Module::Install::Repository
		Module::Install::ReadmeFromPod
	);
	for (@mip) {
		eval "require $_";
		if ($@) {
			eval "require inc::$_";
			if ($@) {
				warn $@;
				printf("# Install following (perl Makefile.PL | cpanm):\n%s", join("\n", @mip));
				exit 1;
			}
		}
	}
};

use inc::Module::Install;
name 'Plack-App-CocProxy';
all_from 'lib/Plack/App/CocProxy.pm';

install_script 'bin/cocproxy';

requires 'Plack';
requires 'Plack::App::Proxy';
requires 'Plack::App::File';
requires 'opts';

requires 'Starlet';

build_requires 'Test::More';
build_requires 'Test::TCP';
build_requires 'Plack::Test';

# Module::Install::AuthorTests
author_tests('xt');

# Module::Install::Repository
auto_set_repository;

# Module::Install::ReadmeFromPod
readme_from 'lib/Plack/App/CocProxy.pm';

auto_include;
WriteAll;
