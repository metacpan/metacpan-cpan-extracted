use strict;
use warnings;
package TestGlob;
use Sub::Exporter::GlobExporter qw(glob_exporter);
use Sub::Exporter -setup => {
  collectors => {
    '$Alpha' => glob_exporter(Alpha => \*Alpha),
    '$Bravo' => glob_exporter(Bravo => \'_bravo_glob'),
  },
};

sub _bravo_glob { \*Bravo }
1;
