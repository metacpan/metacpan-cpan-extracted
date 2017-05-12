use Module::Build;
use 5.20.0;
Module::Build->new
    ( module_name => 'Perl6::Pod',
    license => 'perl',
   prereq => {
	'XML::Flow'=>'0',
	'Encode'=>0,
	'Pod::Usage'=>0,
	'Getopt::Long'=>0,
	'Test::Class'=>0,
	'Filter::Simple'=>0,
	'Regexp::Grammars'=>'1.044',
	'Tie::UnionHash'=>'0.02'
	     },
    requires => {
            'perl' => '5.18.4',
    },
    script_files=>[qw!
	scripts/pod6any
	scripts/pod6docbook
	scripts/pod6xhtml
	scripts/pod6latex
    !],
   dist_version_from=>'lib/Perl6/Pod.pm',
    meta_merge=>{
     resources=> {
        repository => 'git://github.com/zag/p5-Perl6-Pod.git',
        bugtracker=>'http://rt.cpan.org/Public/Dist/Display.html?Name=Perl6::Pod'
    }
    },
   dist_author=>'Zahatski Aliaksandr zag@cpan.org',
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
