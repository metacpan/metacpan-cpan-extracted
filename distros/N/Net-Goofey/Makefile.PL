#
# Skeleton Perl Makefile
#
# Last updated by gossamer on Wed Aug 12 21:41:39 EST 1998
#

require 5;
use strict;

# Check for modules we need.
$| = 1;
my $missing_modules = 0;

print "Checking for Text::LineEditor (only needed for example client) ...";
eval {
    require Text::LineEditor;
};
if ($@) {
    print " missing!\n";
    $missing_modules++;
    print "$@\n";
    sleep(2);  # Don't hurry too much
} else {
    print " got it\n";
}

print <<EOT if $missing_modules;
The missing modules can be obtained from CPAN - you'll need them to
complete the installation.  

Visit <URL:http://www.perl.com/CPAN/> to find a CPAN site near you.

EOT

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::Goofey',
    'VERSION_FROM' => 'lib/Net/Goofey.pm', # finds $VERSION
    'dist'         => {
                         COMPRESS => 'gzip -9f',
                         SUFFIX => 'gz',
                      },
);


sub MY::postamble {
   package MY;

   '

WEBDIR = /home/gossamer/web/netizen/homepage/code
WEB_FILELIST = $(WEBDIR)/file-list

webdist: dist
	@$(MKPATH) $(WEBDIR)/$(DISTNAME)/
	cp $(DISTVNAME).tar.$(SUFFIX) $(WEBDIR)/$(DISTNAME)/
	cp README $(WEBDIR)/$(DISTNAME)/$(DISTVNAME).README

'
}

