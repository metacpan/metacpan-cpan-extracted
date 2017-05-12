#
# Skeleton Perl Makefile
#
# Last updated by jmuhlich on Sun Oct 8 09:0950 EST 2000
#

require 5.6.0;

use ExtUtils::MakeMaker;
WriteMakefile
  (
   'NAME'	   => 'Net::ICQ',
   'VERSION_FROM' => 'lib/Net/ICQ.pm',

   'PREREQ_PM' =>
   {
    # only stock perl modules required
   },

   'dist'         =>
   {
    COMPRESS => 'gzip -9f',
    SUFFIX => 'gz',
   },
);

#sub MY::postamble {
#   package MY;
#
#   '
#
#WEBDIR = /home/gossamer/public_html/netizen/code
#WEB_FILELIST = $(WEBDIR)/file-list
#
#webdist: dist
#	@$(MKPATH) $(WEBDIR)/$(DISTNAME)/
#	cp $(DISTVNAME).tar.$(SUFFIX) $(WEBDIR)/$(DISTNAME)/
#	cp README $(WEBDIR)/$(DISTNAME)/$(DISTVNAME).README
#
#'
#}



