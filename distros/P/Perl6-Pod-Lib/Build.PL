use Module::Build;
use 5.8.0;
Module::Build->new
    ( module_name => 'Perl6::Pod::Lib',
    license => 'perl',
   prereq => {
	'Perl6::Pod'=>'0.71',
	'Test::Class' => 0
	     },
    script_files=>[qw!
    !],
   dist_version_from=>'lib/Perl6/Pod/Lib.pm',
    meta_merge=>{
     resources=> {
        repository => 'git://github.com/zag/p5-Perl6-Pod-Lib.git',
        bugtracker=>'http://rt.cpan.org/Public/Dist/Display.html?Name=Perl6::Pod::Lib'
    }
    },
   dist_author=>'Zahatski Aliaksandr zag@cpan.org',
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
