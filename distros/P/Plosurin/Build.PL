use Module::Build;
use v5.12;
Module::Build->new
    ( module_name => 'Plosurin',
    license => 'perl',
   prereq => {
	'Regexp::Grammars'=>1.014,
	'HTTP::Server::Simple::WebDAO'=>0.01,
        'Perl6::Pod::Lib'=>0.07,
        'Perl6::Pod'=>0.35
	     },
    script_files=>[qw!
	scripts/plosurin.p5
    !],
   dist_version_from=>'lib/Plosurin.pm',
    meta_merge=>{
     resources=> {
        repository => 'git://github.com/zag/p5-Plosurin.git',
        bugtracker=>'http://rt.cpan.org/Public/Dist/Display.html?Name=Plosurin'
    }
    },
   dist_author=>'Zahatski Aliaksandr zag@cpan.org',
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
