use strict;
my %opts = (
	    NAME => 'Apache2::WebStart',
            VERSION_FROM => 'Apache2/WebStart.pm',
#            PMLIBDIRS => [qw(Apache2)],
            PM => {'Apache2/WebStart.pm' => 
                   '$(INST_LIBDIR)/WebStart.pm',
                 },
	    dist   => {
			 SUFFIX   => 'gz',
			 COMPRESS => 'gzip -9f',
			},
	   );

require ModPerl::MM;
ModPerl::MM::WriteMakefile( %opts);
# use Apache::Test to test things, but if not available,
# print out a message to that effect for 'make test'

sub MY::test {
  eval {require Apache::TestMM; import Apache::TestMM qw(test clean)};
  unless ($@) {
    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script('t/TEST');
    return Apache::TestMM->test;
  }
  
  return <<'EOF';
test::
	@echo This test suite requires Apache::Test,
	@echo available from the mod_perl 2 sources
	@echo or from the httpd-test distribution.
EOF

}
