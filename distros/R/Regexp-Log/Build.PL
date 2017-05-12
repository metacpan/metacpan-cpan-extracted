use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Regexp::Log',
    license           => 'perl',
    dist_author       => 'Philippe "BooK" Bruhat <book@cpan.org>',
    dist_version_from => 'lib/Regexp/Log.pm',
    add_to_cleanup    => ['Regexp-Log-*'],
    requires          => { 'Test::More' => 0, },
);

$builder->create_build_script();
