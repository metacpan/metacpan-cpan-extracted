# This -*- perl -*- script writes the Makefile for Module::Versions::Report
# Time-stamp: "2003-06-21 23:27:37 AHDT"
require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'Module-Versions-Report',
   VERSION_FROM  => 'lib/Module/Versions/Report.pm',
   LICENSE       => 'perl',
   ABSTRACT      => 'report versions of all modules in memory',
   'dist'        => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);

package MY;

sub libscan
{ # Determine things that should *not* be installed
    my($self, $path) = @_;
    return '' if $path =~ m/~/;
    $path;
}

__END__

