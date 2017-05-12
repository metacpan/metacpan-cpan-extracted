use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Plugin::Clickable::Email',
    license             => 'bsd',
    dist_author         => 'Nik Clayton <nik@FreeBSD.org>',
    dist_version_from   => 'lib/Template/Plugin/Clickable/Email.pm',
    requires => {
		 'Test::More' => 0,
		 'Email::Find' => 0,
		 'Template' => 0,
    },
    add_to_cleanup      => [ 'Template-Plugin-Clickable-Email-*' ],
);

$builder->create_build_script();
