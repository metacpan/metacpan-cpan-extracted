use strict;
use warnings;
if ( $^V =~ /^v5[.](1[13579]|2[13579])/ismx ) {
   print("Perl developer versions are not supported.") and exit;
}
else {
   use Module::Build;
   my $builder = Module::Build->new(
      module_name       => 'Modern::PBP::Perl',
      license           => 'artistic2',
      dist_author       => 'Juergen von Brietzke <juergen.von.brietzke@t-online.de>',
      dist_version_from => 'lib/Modern/PBP/Perl.pm',
      requires => {
         'perl'          => 5.012000,
         'Carp'          => 0,
         'English'       => 0,
         'Exporter'      => 0,
         'IO::File'      => 0,
         'IO::Handle'    => 0,
         'Perl::Version' => 0,
         'feature'       => 0,
         'mro'           => 0,
         'strict'        => 0,
         'version'       => 0,
         'warnings'      => 0,
      },
      build_requires => {
         'Test::More'          => 0,
         'Test::Pod'           => 1.14,
         'Test::Pod::Coverage' => 1.04,
      },
      configure_requires => { 'Module::Build' => 0.42 },
      add_to_cleanup     => [ 'Modern-PBP-Perl-*' ],
   );
   $builder->create_build_script();
}
