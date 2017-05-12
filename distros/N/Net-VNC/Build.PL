#!perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_license     => 1,
    create_readme      => 1,
    license            => 'perl',
    'meta-spec' => {
        version => '2',
        url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    module_name => 'Net::VNC',
    requires    => {
        'Class::Accessor::Fast' => '0',
        'Crypt::DES'            => '0',
        'Image::Imlib2'         => '0',
        'Test::More'            => '0',
    },
    script_files => ['bin/vnccapture'],
    sign         => 1,
);
$build->create_build_script;
