use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name  => 'PITA::Test::Dummy::Perl5::Build',
    license      => 'perl',
    dist_author  => 'Adam Kennedy <adamk@cpan.org>',
    dist_version => '1.04',
)->create_build_script();
