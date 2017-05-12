use Module::Build;
my $build = new Module::Build
(
  module_name    => 'Test::Builder::Tester',
  license        => 'perl',
  requires       => {
                      'Test::Builder' => 0.12,
                    },
  recommends     => {
                    },
  create_makefile_pl => 'traditional',
);
$build->create_build_script;

__END__

This is old code from the Makefile.PL.  It should probably
  be converted to run under Module::Build at some point

# this code stolen from Test-More-0.41 in order to test on multiple
# perls.  If you want to run a multiple perl test do

# bash$ export PERL_TEST_ALL=1
# bash$ perl Makefile.PL; make; make test

{
  package MY;

    sub test_via_harness {
        my($self, $orig_perl, $tests) = @_;

        my @perls = ($orig_perl);
        push @perls, qw(perl
                        perl5.7.3
                        perl5.6.1
                        perl5.6.0
                        perl5.005_03
                        perl5.004_05
                        perl5.004
                       )
          if $ENV{PERL_TEST_ALL};

        my $out;
        foreach my $perl (@perls) {
            $out .= $self->SUPER::test_via_harness($perl, $tests) . "\n";
        }
        $out =~ s{-I\$\(PERL_\w*LIB\)}{}g;

        return $out;
    }
}
