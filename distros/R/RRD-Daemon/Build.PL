use Module::Build::Compat;

my $build = 
  Module::Build->new(module_name   => 'RRD::Daemon',
                     dist_abstract => 'perl daemon rrd collector',
                     dist_author   => 'M J Pearce <fluffy@cpan.org>',
                     license       => 'perl',
                     requires      => 
                       +{ 'perl'                      => '5.10.0',
                          'IPC::System::Simple'       => '1.18',
                          'Log::Log4perl'             => '1.23',
                          'Log::Dispatch::FileRotate' => '1.19',
                          'Params::Attr'              => '1.00',
                          'Params::Validate'          => '0.91',
                          'RRDs'                      => '1.3001',
                        },
                    );

$build->create_build_script;
if ( ! -e 'Makefile.PL' ) {
  Module::Build::Compat->create_makefile_pl('passthrough', $build);
  chmod 0644, 'Makefile.PL'
    or die "failed to chmod Makefile.PL: $!\n";
}
