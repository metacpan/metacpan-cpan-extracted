use inc::Module::Install;

name     'Test-Collectd-Plugins';
all_from 'lib/Test/Collectd/Plugins.pm';
author   q{Fabien Wernli <wernli_workingat_in2p3.fr>};
license  'perl';

build_requires 'Test::More';
build_requires 'Test::File::ShareDir';
build_requires 'Parse::Yapp::Driver' => '0.22';
build_requires 'Module::Find';

requires 'namespace::autoclean';
requires 'Package::Alias';
requires 'Parse::Lex';
requires 'Test::Builder' => '0.90';

recommends 'File::ShareDir';

no_index package => 'FakeCollectd';

install_share 'module', 'Test::Collectd::Plugins', 'share';

auto_install;


# generate the Parser
(my $yappbin = $^X ) =~ s!perl([\d\.]*)$!yapp!;
$yappbin = "yapp" unless -x $yappbin;
postamble(qq!
CONFIG_PARSER_DIRNAME = blib/lib/Test/Collectd/Config
CONFIG_PARSER_FILENAME = \$(CONFIG_PARSER_DIRNAME)/Parse.pm

\$(CONFIG_PARSER_FILENAME): parser.yp pm_to_blib
	mkdir -p \$(CONFIG_PARSER_DIRNAME)
	$yappbin -s -m Test::Collectd::Config::Parse -o \$(CONFIG_PARSER_FILENAME) parser.yp

parser: \$(CONFIG_PARSER_FILENAME)

all :: parser
!);

WriteAll;

