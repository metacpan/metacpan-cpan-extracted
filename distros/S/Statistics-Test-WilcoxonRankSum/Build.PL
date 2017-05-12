use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
                                 module_name         => 'Statistics::WilcoxonRankSum',
                                 license             => 'perl',
                                 dist_author         => 'Ingrid Falk <ingrid dot falk at loria dot fr>',
                                 dist_version_from   => 'lib/Statistics/Test/WilcoxonRankSum.pm',
                                 requires => {
                                              'Test::More' => 0,
                                              'version'    => 0,
                                              'Carp'       => 0,
                                              'Carp::Assert' => 0,
                                              'Class::Std' => 0,
                                              'Contextual::Return' => 0,
                                              'List::Util' => 0,
                                              'Set::Partition' => 0,
                                              'Math::BigFloat' => 0,
                                              'Math::Counting' => 0,
                                              'Statistics::Distributions' => 0,
                                             },
                                 add_to_cleanup      => [ 'Statistics-Test-WilcoxonRankSum-*' ],
                                );

$builder->create_build_script();
