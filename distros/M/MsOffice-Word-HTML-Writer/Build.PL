use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MsOffice::Word::HTML::Writer',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami@cpan.org>',
    dist_version_from   => 'lib/MsOffice/Word/HTML/Writer.pm',
    requires => {
        'utf8'              => 0,
        'Test::More'        => 0,
	'Carp'              => 0,
        'MIME::Base64'      => 0,
        'MIME::Types'       => 0,
	'Module::Build'     => 0,
        'Params::Validate'  => 0,
        'Scalar::Util'      => 0,
    },
    add_to_cleanup      => [ 'MsOffice-Word-HTML-Writer-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/MsOffice-Word-HTML-Writer',
       }
     },
);

$builder->create_build_script();



