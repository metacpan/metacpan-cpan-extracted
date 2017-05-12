use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass( code => <<'EOF');
        eval { require Locale::Msgfmt; Locale::Msgfmt->import(); };
        sub process_mo_files {
                die("requires Locale::Msgfmt") if(!$INC{'Locale/Msgfmt.pm'});
                msgfmt({
                        in => "share/locale/",
                        out => "blib/lib/Padre/Plugin/REPL/share/locale/"});
        }
EOF
my $builder = $class->new(
	module_name       => 'Padre::Plugin::REPL',
	license           => 'perl',
	dist_author       => 'Ryan Niebur <ryanryan52@gmail.com>',
	dist_version_from => 'lib/Padre/Plugin/REPL.pm',
	build_requires    => {
		'Test::More'     => 0,
		'Locale::Msgfmt' => '0.08',
	},
	requires => {
		'Padre'         => 0,
		'Capture::Tiny' => 0,
		'Devel::REPL'   => 0,
		'Class::Unload' => 0,
		'Wx'            => 0,
	},
	add_to_cleanup     => ['Padre-Plugin-REPL-*'],
	create_makefile_pl => 'passthrough',
);

$builder->add_build_element('mo');
$builder->create_build_script();
