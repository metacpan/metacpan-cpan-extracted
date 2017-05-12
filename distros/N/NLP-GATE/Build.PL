use strict;
use warnings;
use Module::Build;

use 5.008001;

my $builder = Module::Build->new(
    module_name         => 'NLP::GATE',
    license             => 'perl',
    dist_author         => 'Johann Petrak <firstnameDOTlastname_AT_jpetrakDOTcom>',
    dist_version_from   => 'lib/NLP/GATE.pm',
    requires => {
        'perl'          => '5.8.1',
        'Test::More'    => '0.92',
        'File::Temp'    => '0.18',
        'FindBin'       => 0,
        'XML::Writer'   => '0.605',
        'XML::LibXML'   => '1.69',

    },
    add_to_cleanup      => [ 'NLP-GATE-*' ],
);

$builder->create_build_script();
