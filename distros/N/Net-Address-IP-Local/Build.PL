#
# Module::Build build script for Net::Address::IP::Local
#
# (C) 2005-2009 Julian Mehnle <julian@mehnle.net>
# $Id: Build.PL 24 2009-01-14 21:23:40Z julian $
#
###############################################################################

use Module::Build;

my $build = Module::Build->new(
    module_name     => 'Net::Address::IP::Local',
    dist_author     => 'Julian Mehnle <julian@mehnle.net>',
    license         => 'perl',
    requires        => {
        perl                => 0,
        version             => 0,
        Error               => 0,
        IO::Socket::INET    => 0
    },
    recommends      => {
        IO::Socket::INET6   => 0
    },
    create_makefile_pl
                    => 'passthrough',
    sign            => 1
);

$build->create_build_script();
