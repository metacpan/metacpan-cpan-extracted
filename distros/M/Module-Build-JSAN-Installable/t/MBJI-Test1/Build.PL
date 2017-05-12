use Module::Build::JSAN::Installable;

my $build = Module::Build::JSAN::Installable->new(
	module_name    => 'Digest.MD5',
	
	create_makefile_pl => 'passthrough',
	
	dist_version   => 0.01,
	dist_author   => 'SamuraiJack <root@symbie.org>',
	dist_abstract  => 'Digest md5',
	
	license        => 'perl',
	
	requires       => {
	    'Cool.JS.Lib' => '1.1',
	    'Another.Cool.JS.Lib' => '1.2'
	},
	
	
    build_requires       => {
        'Building.JS.Lib' => '1.1',
        'Another.Building.JS.Lib' => '1.2'
    },
    
    static_dir  => 'assets'
);

$build->create_build_script;

