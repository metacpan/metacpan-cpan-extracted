#
# Makefile.PL
#
# Copyright (C) 1999-2012 Gregor N. Purdy, Sr. All rights reserved.
# This program is free software. It is subject to the same license as Perl.
#
# [ $Id$ ]
#

use ExtUtils::MakeMaker;

WriteMakefile (
  NAME         => 'Scrape::USPS::ZipLookup',
  VERSION_FROM => 'lib/Scrape/USPS/ZipLookup.pm',
  PREREQ_PM    => {
    LWP::UserAgent           => 6.04,
    LWP::Protocol::https     => 6.03,   # To use HTTPS during unit tests
    HTTP::Request::Common    => 6.03,
    HTML::TreeBuilder::XPath => 0.14,   # To scrape data out of HTML
    XML::XPathEngine         => 0.13,
  },
  EXE_FILES    => [
    'script/stdaddr'
  ],
  AUTHOR       => 'Gregor N. Purdy, Sr. (gnp@acm.org)',
  ABSTRACT     => 'Programmatic interaction with the USPS Zip Code Lookup web application',
  dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' }
);

#
# End of file.
#
