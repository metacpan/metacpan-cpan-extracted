use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass( code => <<'EOF');
	eval { require Locale::Msgfmt; Locale::Msgfmt->import(); };
	sub process_mo_files {
		die("requires Locale::Msgfmt") if(! $INC{'Locale/Msgfmt.pm'});
		msgfmt({
			in => "share/locale/",
			out => "blib/share/locale/"});
	}
EOF

my $builder = $class->new(
	module_name        => 'Padre::Plugin::Catalyst',
	license            => 'perl',
	dist_author        => 'Breno G. de Oliveira <garu@cpan.org>',
	dist_version_from  => 'lib/Padre/Plugin/Catalyst.pm',
	dist_abstract      => 'Catalyst helper interface for Padre',
	configure_requires => { 'Padre::PluginBuilder' => 0.12, },
	build_requires     => {
		'Test::More'     => 0,
		'Module::Build'  => 0.30,
		'Locale::Msgfmt' => 0.14,
	},
	requires => {
		'Padre'                     => 0.51,
		'Catalyst::Devel'           => 1.0,
		'Catalyst::Runtime'         => 5.70,
		'Module::Pluggable::Object' => 3.9,
		'ExtUtils::Install'         => '1.52',
	},
	recommends => {
		'Task::CatInABox'          => 0.03,
		'Task::Catalyst::Tutorial' => 0.06,
	},
	add_to_cleanup     => ['Padre-Plugin-Catalyst-*'],
	create_makefile_pl => 'traditional',
	meta_merge         => {
		resources => {
			homepage   => 'http://padre.perlide.org/',
			repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Catalyst/',
		}
	},
);

$builder->add_build_element('mo');
$builder->create_build_script();
