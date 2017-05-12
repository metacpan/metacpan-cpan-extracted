use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'ModPerl::ParamBuilder',
    license             => 'perl',
    dist_author         => 'Frank Wiles <frank@revsys.com>',
    dist_version_from   => 'lib/ModPerl/ParamBuilder.pm',
    requires => {
        'Apache2::CmdParms'     =>  0,
        'Apache2::Module'       =>  0,
        'Apache2::ServerUtil'   =>  0,
    },
    add_to_cleanup      => [ 'ModPerl-ParamBuilder-*' ],
);

$builder->create_build_script();
