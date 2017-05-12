use Module::Build;
use 5.8.0;
Module::Build->new
    ( module_name => 'Pod::ToDocBook',
    license => 'perl',
   prereq => {
	'XML::ExtOn'=>'0.12',
	'XML::Flow'=>'0',
	'XML::SAX::Writer' => '0',
	'Pod::Parser'=>'0',
	'Encode'=>0,
	'Text::ParseWords'=>0,
	     },
   dist_version_from=>'lib/Pod/ToDocBook.pm',
   dist_author=>'Zahatski Aliaksandr zag@cpan.org',
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
