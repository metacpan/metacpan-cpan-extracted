use inc::Module::Install;

name     'Norma';
all_from 'lib/Norma.pm';
author   q{David Chester <davidchester@gmx.net>};
license  'perl';

requires	'DBI';
requires	'Moose';
requires	'Moose::Role';
requires	'Moose::Util::TypeConstraints';
requires	'MooseX::Role::Parameterized';
requires	'MooseX::Role::Parameterized';
requires	'Lingua::EN::Inflect::Number';

test_requires	'Test::More';
test_requires	'Test::Exception';
test_requires	'DBD::SQLite';

default_test_target includes => ['t/lib'];

tests_recursive;

auto_install;

my $default_preop_cmd = q[$(PERL) -I. "-MModule::Install::Admin" -e "dist_preop(q($(DISTVNAME)))"];
my $sync_versions_cmd = q[pushd $(DISTVNAME) $(TO_INST_PM) && perl -pi -e 's/(package Norma::.+)/$$1\nour \$$VERSION = \"$(VERSION)\"\;/' $(TO_INST_PM) && popd];

makemaker_args(
	dist => { PREOP => "$default_preop_cmd; $sync_versions_cmd" }
);

WriteAll( meta => 0 );

