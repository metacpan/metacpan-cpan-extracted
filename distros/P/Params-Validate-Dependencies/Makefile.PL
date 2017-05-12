use ExtUtils::MakeMaker;
use Config;
WriteMakefile(
  NAME         => 'Params::Validate::Dependencies',
    META_MERGE => {
        license => 'other',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-Params-Validate-Dependencies',
            bugtracker => 'https://github.com/DrHyde/perl-modules-Params-Validate-Dependencies/issues',
        }
    },
  VERSION_FROM => 'lib/Params/Validate/Dependencies.pm',
  PREREQ_PM    => {
    'PadWalker'         => 1.96,
    'Scalar::Util'      => 1.25,
    'Params::Validate'  => 1.07,
    'Clone',            => 0.38,
    'Test::Differences' => 0,
    'Test::More'        => 0.88, # done_testing
    'Test::Exception'   => 0,
    # Modern Data::Domain only works on 5.10 to 5.22
    (($] > 5.010 && $] < 5.024) ? ('Data::Domain' => 1.02) : ())
  },
  dist => {
    PREOP => qq{$Config{perlpath} -E 'die("Can not make dist on 5.24 cos of D::D dep\\n") if($] > 5.022)'}
  }
);
