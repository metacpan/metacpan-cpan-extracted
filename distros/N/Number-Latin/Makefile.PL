# This -*- perl -*- script writes the Makefile for Number::Latin
# Time-stamp: "2001-02-22 16:54:30 MST"
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Number::Latin',
    'VERSION_FROM' => 'Latin.pm', # finds $VERSION
    'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

package MY;

sub libscan
{ # Determine things that should *not* be installed
    my($self, $path) = @_;
    return '' if $path =~ m/~/;
    $path;
}

__END__
