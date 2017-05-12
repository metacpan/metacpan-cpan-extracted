use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Printer::Label::Template::Processor',
    license           => 'perl',
    dist_author       => 'Christian Morel <cmorel@hotmail.com>',
    dist_version_from => 'lib/Printer/Label/Template/Processor.pm',
    requires          => {
        'Carp'             => 0,
        'File::Slurp'      => 0,
        'Net::FTP'         => 0,
        'Net::Printer'     => 0,
        'Template'         => 0,
        'Params::Validate' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup => [ 'Printer-Label-Template-Processor-*' ],
);

$builder->create_build_script();

