use Module::Build::Compat;

my $build = 
  Module::Build->new(module_name   => 'Params::Attr',
                     dist_abstract => 'function signature checking via attributes',
                     dist_author   => 'M J Pearce <fluffy@cpan.org>',
                     license       => 'perl',
                     requires      => 
                       +{ 'perl'                => '5.10.0',
                          'Attribute::Handlers' => '0.79', # core
                          'Carp'                => 0,      # core
                          'Params::Validate'    => '0.91',
                          'Scalar::Util'        => '1.19', # core
                          'List::Util'          => '1.19', # core
                        },
                    );

$build->create_build_script;
if ( ! -e 'Makefile.PL' ) {
  Module::Build::Compat->create_makefile_pl('passthrough', $build);
  chmod 0644, 'Makefile.PL'
    or die "failed to chmod Makefile.PL: $!\n";
}
