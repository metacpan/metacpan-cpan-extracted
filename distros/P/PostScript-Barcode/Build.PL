use 5.010;
use strict;
use warnings FATAL => 'all';

use Module::Build;
my $build = Module::Build->new(
    license     => 'perl',
    module_name => 'PostScript::Barcode',
    meta_merge  => {
        resources => {
            repository => 'http://github.com/daxim/PostScript-Barcode',
            bugtracker => 'http://github.com/daxim/PostScript-Barcode/issues',
        },
    },
    configure_requires => {
        'perl'          => '5.010',
        'Module::Build' => '0.35',
    },
    build_requires => {
        'Capture::Tiny'   => 0,
        'File::Temp'      => 0,
        'Image::Size'     => 0,
        'IO::File'        => 0,
        'GTop'            => 0,
        'Module::Load'    => 0,
        'Test::Exception' => 0,
        'Test::More'      => 0,
    },
    requires => {
        'perl'              => '5.010',
        'Alien::BWIPP'      => '0.006',
        'IO::CaptureOutput' => '1.1102',
        'GSAPI'             => '0.5',
        'List::Util'        => 0,
        'Moose'             => '0.93',
        'MooseX::Singleton' => '0.22',
    },
);
$build->create_build_script;

__END__

=encoding UTF-8

=head1 INSTALLATION

=head2 system-wide installation

    perl Build.PL
    ./Build
    ./Build test
    sudo ./Build install

=head2 installation in a private directory

    perl Build.PL --install_base ~/modules_prefix
    ./Build
    ./Build test
    ./Build install

Do not forget to add F<$HOME/modules_prefix/lib/perl5> to your C<@INC>, see
L<perlfaq8/"How do I add a directory to my include path (@INC) at runtime?">.
