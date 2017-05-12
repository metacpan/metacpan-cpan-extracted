# A template for Makefile.PL.
# - Set the $PACKAGE variable to the name of your module.
# - Set $LAST_API_CHANGE to reflect the last version you changed the API 
#   of your module.
# - Fill in your dependencies in PREREQ_PM
# Alternatively, you can say the hell with this and use h2xs.

require 5.004;

use strict;
use ExtUtils::MakeMaker;

my $PACKAGE = 'Module::Info';
(my $PACKAGE_FILE = $PACKAGE) =~ s|::|/|g;
my $LAST_API_CHANGE = 0;

eval "require $PACKAGE";

unless ($@) { # Make sure we did find the module.
    no strict 'refs';
    print <<"CHANGE_WARN" if ${$PACKAGE.'::VERSION'} < $LAST_API_CHANGE;

NOTE: There have been API changes between this version and any older
than version $LAST_API_CHANGE!  Please read the Changes file if you
are upgrading from a version older than $LAST_API_CHANGE.

CHANGE_WARN
}

( my $mmv = ExtUtils::MakeMaker->VERSION ) =~ s/_//g;

WriteMakefile(
    NAME            => $PACKAGE,
    VERSION_FROM    => "lib/$PACKAGE_FILE.pm", # finds $VERSION
    ABSTRACT_FROM   => "lib/$PACKAGE_FILE.pm",
    PREREQ_PM       => {
        'File::Spec' => 0.8,
        'B'          => 0,
        'B::Utils'   => 0.27,
        'strict'     => 0,
        'Carp'       => 0,
    },
    'dist'          => { COMPRESS   => 'gzip -9',
                         SUFFIX     => '.gz',
                         DIST_DEFAULT   => 'all tardist',
                       },
    EXE_FILES       => [qw(bin/pfunc bin/module_info)],
    PL_FILES        => {}, # skip Build.PL
    ($mmv >= 6.31 ? (LICENSE => 'perl') : ()),
    ($mmv >= 6.48 ? (MIN_PERL_VERSION => '5.006') : ()),
    ( $] >= 5.005 ?
      ( AUTHOR          => 'Mattia Barbon <mbarbon@cpan.org>' ) :
      () ),
    ($mmv <= 6.45 ? () : (META_MERGE => {
            resources => {
                repository => 'https://github.com/mbarbon/module-info'
            },
            })
    ),
    ( $mmv >= 6.47 ?
      ( META_MERGE      => { license        => 'perl',
                             dynamic_config => 0,
                             }
        ) :
      () )
);


{
    package MY;

    sub test_via_harness {
        my($self, $orig_perl, $tests) = @_;

        my @perls = ($orig_perl);
        push @perls, qw(bleadperl
                        perl5.6.1
                        perl5.6.0
                        perl5.005_03
                        perl5.004_05
                        perl5.004_04
                        perl5.004
                       )
          if $ENV{PERL_TEST_ALL};

        my $out;
        foreach my $perl (@perls) {
            $out .= $self->SUPER::test_via_harness($perl, $tests);
        }

        return $out;
    }
}
