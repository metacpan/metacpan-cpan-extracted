###############################################################################
#
#   Module::Build file for Test::AgainstSchema
#
###############################################################################

use 5.008;
use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass(
    class => 'Test::AgainstSchema::Builder',
    code => q|
        sub ACTION_dist
        {
            my $self = shift;

            # Create the text ChangeLog
            $self->do_system('changelog2x',
                             qw(--template text
                                --input ChangeLog.xml
                                --output ChangeLog));
            # Create the text README
            $self->do_system('textile2x',
                             qw(--format plaintext
                                --input README.textile
                                --output README));

            $self->SUPER::ACTION_manifest();
            $self->SUPER::ACTION_dist();
        }
|);

my $builder = $class->new(
    module_name          => 'Test::AgainstSchema',
    license              => 'perl',
    dist_author          => 'Randy J. Ray <rjray@blackperl.com>',
    dist_version         => '0.100',
    build_requires       => {
        'Test::More' => '0.80',
    },
    requires             => {
        'perl'         => '5.008',
        'File::Spec'   => '0.8',
        'XML::LibXML'  => '1.60',
        'Exporter'     => '5.57',
        'Try::Tiny'    => '0.11',
    },
    add_to_cleanup       => [ qw(Test-AgainstSchema-*
                                 ChangeLog
                                 README
                                 MANIFEST
                                 MANIFEST.bak
                                 META.yml
                                 MYMETA.yml
                                 MYMETA.json
                                 Makefile.PL) ],
    meta_merge         =>
    {
        resources =>
        {
            homepage   => 'http://search.cpan.org/dist/Test-AgainstSchema',
            bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Test-AgainstSchema',
            repository => 'https://github.com/rjray/test-againstschema',
        }
    },
    create_makefile_pl   => 'traditional',
    recursive_test_files => 1,
);

$builder->create_build_script();

exit 0;
