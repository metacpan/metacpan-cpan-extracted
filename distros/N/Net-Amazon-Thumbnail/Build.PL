use Module::Build;
use strict;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Net::Amazon::Thumbnail',
    requires           => {
        'Class::Accessor'      	     => '0',
        'File::Spec'                 => '0',
        'Digest::HMAC_SHA1'          => '0',
        'URI'                        => '0',
        'URI::QueryParam'            => '0',
        'LWP::UserAgent'             => '0',
        'Module::Build'              => '0',
        'Test::Exception'            => '0.15',
        'Test::More'                 => '0.01',
        'XML::XPath'                 => '0',
        'XML::XPath::XMLParser'      => '0',
    },
);
$build->create_build_script;
