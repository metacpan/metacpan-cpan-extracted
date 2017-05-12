use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MsOffice::Word::HTML::Writer',
    license             => 'perl',
    dist_author         => 'Laurent Dami <laurent.dami AT etat.ge.ch>',
    dist_version_from   => 'lib/MsOffice/Word/HTML/Writer.pm',
    requires => {
        'Test::More'        => 0,
	'Carp'              => 0,
        'MIME::QuotedPrint' => 0,
        'MIME::Base64'      => 0,
        'MIME::Types'       => 0,
	'Module::Build'     => 0,
        'Params::Validate'  => 0,
    },
    add_to_cleanup      => [ 'MsOffice-Word-HTML-Writer-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();



