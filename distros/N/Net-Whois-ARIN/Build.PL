#!perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Net::Whois::ARIN',
    requires           => {
        'IO::Socket::INET'   => 0,
        'Test::More'         => 0, 
        'Test::MockObject'   => "1.07", 
    },
);

$build->create_build_script;
