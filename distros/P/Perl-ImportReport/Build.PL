use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Perl::ImportReport',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/Perl/ImportReport.pm',
    requires => {
        'Test::More' => 0,
        'PPI'        => 0,
        'PPI::Util'  => 0,
    },
    add_to_cleanup      => [ 'Perl-ImportReport-*' ],
);

$builder->create_build_script();
