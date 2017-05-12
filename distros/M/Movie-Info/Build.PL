use strict;
use Module::Build;



my $build = Module::Build->new(
    module_name => "Movie::Info",
    license     => 'perl',
    requires    => {
				'File::Which' => 0, 
		    },
    create_makefile_pl => 'passthrough',
    dynamic_config => 1,
    scripts     => [ 'bin/movieinfo' ],
   );



$build->create_build_script;
