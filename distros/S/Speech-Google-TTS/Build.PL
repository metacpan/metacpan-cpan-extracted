use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Speech::Google::TTS',
    license             => 'perl',
    dist_author         => 'Niels Dettenbach <nd@syndicat.com>',
    dist_version_from   => 'lib/Speech/Google/TTS.pm',
    build_requires => {
        'Test::More' 		=> 0,
	'File::Temp'		=> 0,
	'LWP::UserAgent' 	=> 0,
	'LWP::ConnCache'	=> 0,
	'CGI::Util'		=> 0,
    },
    add_to_cleanup     => [ 'Speech::Google::TTS-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
