use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $module = 'lib/Sub/Parameters.pm';
WriteMakefile(
              'NAME'         => 'Sub::Parameters',
              'VERSION_FROM' => $module, # finds $VERSION
              'dist'         => {
                                 COMPRESS=>'gzip -9f',
                                 SUFFIX=>'gz',
                                 DIST_DEFAULT => 'tardist'
                                },
              PM             => {
                                 'lib/Sub/Parameters.pm'            => '$(INST_LIBDIR)/Parameters.pm',
                                },
              PREREQ_PM      => {
                                 'Test::More'          => 0,
                                 'Devel::LexAlias'     => 0.01,
                                 'Attribute::Handlers' => 0,
                                 'Hook::LexWrap'       => 0,
                                 'Devel::Caller'       => 0.02,
                                 ($] >= 5.007002 ?
                                  ('PadWalker'         => 0.05)
                                  : ()),
                                },
             );

sub MY::postamble {
    return <<EOF
README: $module
\tpod2text $module > README
EOF
}
