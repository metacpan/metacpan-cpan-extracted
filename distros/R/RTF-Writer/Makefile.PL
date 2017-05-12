
# Time-stamp: "2003-10-14 18:28:06 ADT"
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

require 5.005; # we need m/...\z/
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'RTF::Writer',
    'VERSION_FROM' => 'lib/RTF/Writer.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/RTF/Writer.pod',
    'PREREQ_PM'     => {
       'Exporter' => 0,
       'Carp'   => 0,
       'File::Path'  => 0, # the tests use it
       #'utf8'   => 0,
       'Image::Size' => 0, # I /think/ any version'll do
       'strict' => 0,
       'UNIVERSAL' => 0,
    },
    'dist'         => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);

package MY;

sub libscan
{ # Determine things that should *not* be installed
    my($self, $path) = @_;
    return '' if $path =~ m/~/;
    $path;
}

__END__
