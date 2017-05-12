require 5.005;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile
  (AUTHOR => 'B. K. Oxley (binkley) <binkley@alumni.rice.edu>',
   ABSTRACT => 'Exporter with pragma support',
   NAME => 'Pragmatic',
   VERSION_FROM => 'lib/Pragmatic.pm');

package MY;

# Auto-generate the README from lib/Pramatic.pm:
sub postamble {
  q|
README: $(VERSION_FROM)
	perldoc -t $< > $@

all:: README
|;
}
