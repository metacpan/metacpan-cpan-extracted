use 5.008001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $BUILD_REQUIRES = {
 'ExtUtils::MakeMaker' => 0,
 'Test::More'          => 0,
};  
    
sub build_req {
 my $tometa = ' >> $(DISTVNAME)/META.yml;';
 my $build_req = 'echo "build_requires:" ' . $tometa;
 foreach my $mod ( sort { lc $a cmp lc $b } keys %$BUILD_REQUIRES ) {
  my $ver = $BUILD_REQUIRES->{$mod};
  $build_req .= sprintf 'echo "    %-30s %s" %s', "$mod:", $ver, $tometa;
 }
 return $build_req;
}

WriteMakefile(
    NAME          => 'Sub::Nary',
    AUTHOR        => 'Vincent Pit <perl@profvince.com>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Sub/Nary.pm',
    ABSTRACT_FROM => 'lib/Sub/Nary.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'B'        => 0,
        'Carp'     => 0,
        'XSLoader' => 0
    },
    dist          => {
        PREOP        => 'pod2text lib/Sub/Nary.pm > $(DISTVNAME)/README; '
                        . build_req,
        COMPRESS     => 'gzip -9f', SUFFIX => 'gz'
    },
    clean         => { FILES => 'Sub-Nary-* *.gcov *.gcda *.gcno cover_db' }
);

1;

package MY;

sub postamble {
 my $cv = join ' -coverage ', 'cover',
                            qw/statement branch condition path subroutine time/;
 <<POSTAMBLE;
cover test_cover:
	$cv -test
POSTAMBLE
}
