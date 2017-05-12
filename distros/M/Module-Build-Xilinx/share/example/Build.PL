use strict;
use warnings;
use Module::Build::Xilinx;

my $b = Module::Build::Xilinx->new(
        dist_name => 'dflipflops',
        dist_version => '0.01',
        dist_author => 'Vikas N Kumar <vikas@cpan.org>',
        dist_abstract => 'This is a test',
        proj_params => {
            family => 'spartan3a',
            device => 'xc3s700a',
            package => 'fg484',
            speed => -4,
            language => 'VHDL',
        },
    );
$b->create_build_script;
$b->dispatch('build');
