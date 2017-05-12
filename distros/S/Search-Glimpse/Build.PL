use 5.006001;
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new
  (
   module_name => 'Search::Glimpse',
   license     => 'perl',
   dist_author => ['Alberto Simões <ambs@cpan.org>'],
   configure_requires => {
                          'Config::AutoConf' => '0.14',
                          'Module::Build'    => '0.3603',
                         },
   build_requires => {
                      'Test::Pod::Coverage' => '0.08',
                      'Test::Pod'           => '1.00',
                      'Test::More'          => 0,
                     },
   requires => {
                'IO::File'            => 0,
               },
  );


eval {
    require Config::AutoConf;
    my @programs = qw.glimpse glimpseindex glimpseserver.;

    for my $p (@programs) {
        my $binary = Config::AutoConf->check_prog($p);
        if (not $binary) {
            warn "A glimpse binary was not found. Please ensure it is in your search path.\n",
              "You can download glimpse from http://webglimpse.net/ (Note: not WebGlimpse)\n";
            exit;
        }
        $builder->config_data($p => $binary);
    }
};
die "Config::AutoConf is needed to configure this module.\n" if $@;

$builder->create_build_script;
