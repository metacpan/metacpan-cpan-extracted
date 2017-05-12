use Module::Build;
use 5.8.0;
Module::Build->new
    ( module_name => 'Perl6::Pod::Slide',
    license => 'perl',
   prereq => {
	'Perl6::Pod'=>'0.59',
	'XML::ExtOn'=>'0.14',
	'Test::Class'=>0,
	     },
    script_files=>[qw!
     scripts/pod6slide
    !],
   dist_version_from=>'lib/Perl6/Pod/Slide.pm',
    meta_merge=>{
     resources=> {
        repository => 'git://github.com/zag/p5-Perl6-Pod-Slide.git',
        bugtracker=>'http://rt.cpan.org/Public/Dist/Display.html?Name=Perl6::Pod::Slide'
    }
    },
   dist_author=>'Zahatski Aliaksandr zag@cpan.org',
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
