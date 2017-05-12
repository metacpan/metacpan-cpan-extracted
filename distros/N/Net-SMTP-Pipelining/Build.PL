use strict;
use warnings;
use 5.006;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::SMTP::Pipelining',
    license             => 'perl',
    dist_author         => 'Marc Beyer <japh@tirwhan.org>',
    dist_version_from   => 'lib/Net/SMTP/Pipelining.pm',
    requires => {
                 'Test::More' => 0,
                 'version'    => 0,
                 'Net::Cmd'   => 0,
                 'Net::SMTP'  => 0,
                 'IO::Socket' => 0,
             },
    add_to_cleanup      => [ 'Net-SMTP-Pipelining-*' ],
);

$builder->create_build_script();
