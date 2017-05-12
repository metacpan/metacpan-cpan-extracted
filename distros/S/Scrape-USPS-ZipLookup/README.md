# NAME

Scrape::USPS::ZipLookup - Standardize U.S. postal addresses.

# SYNOPSIS
  

    #!/usr/bin/perl
    

    use Scrape::USPS::ZipLookup::Address;
    use Scrape::USPS::ZipLookup;
    

    my $addr = Scrape::USPS::ZipLookup::Address->new(
      'Focus Research, Inc.',                # Firm
      '',                                    # Urbanization
      '8080 Beckett Center Drive Suite 203', # Delivery Address
      'West Chester',                        # City
      'OH',                                  # State
      '45069-5001'                           # ZIP Code
    );
    

    my $zlu = Scrape::USPS::ZipLookup->new();
    

    my @matches = $zlu->std_addr($addr);
    

    if (@matches) {
      printf "\n%d matches:\n", scalar(@matches);
      foreach my $match (@matches) {
        print "-" x 39, "\n";
        print $match->to_string;
        print "\n";
      }
      print "-" x 39, "\n";
    }
    else {
      print "No matches!\n";
    }
    

    exit 0;



# DESCRIPTION

The United States Postal Service (USPS) has on its web site an HTML form at
`http://www.usps.com/zip4/`
for standardizing an address. Given a firm, urbanization, street address,
city, state, and zip, it will put the address into standard form (provided
the address is in their database) and display a page with the resulting
address.

This Perl module provides a programmatic interface to this service, so you
can write a program to process your entire personal address book without
having to manually type them all in to the form.

Because the USPS could change or remove this functionality at any time,
be prepared for the possibility that this code may fail to function. In
fact, as of this version, there is no error checking in place, so if they
do change things, this code will most likely fail in a noisy way. If you
discover that the service has changed, please email the author your findings.

If an error occurs in trying to standardize the address, then no array
will be returned. Otherwise, a four-element array will be returned.

To see debugging output, call `$zlu->verbose(1)`.



# FIELDS

This page at the U.S. Postal Service web site contains definitions of some
of the fields: `http://zip4.usps.com/zip4/pu_mailing_industry_def.htm`



# TERMS OF USE

BE SURE TO READ AND FOLLOW THE UNITED STATES POSTAL SERVICE TERMS OF USE PAGE
(AT `http://www.usps.com/homearea/docs/termsofuse.htm` AT THE TIME THIS TEXT
WAS WRITTEN). IN PARTICULAR, NOTE THAT THEY DO NOT PERMIT THE USE OF THEIR WEB
SITE'S FUNCTIONALITY FOR COMMERCIAL PURPOSES. DO NOT USE THIS CODE IN A WAY
THAT VIOLATES THE TERMS OF USE.

As the user of this code, you are responsible for complying with the most
recent version of the Terms of Use, whether at the URL provided above or
elsewhere if the U.S. Postal Service moves it or updates it. As a convenience,
here is a copy of the most relevant paragraph of the Terms of Use as of
2006-07-04:

    Material on this site is the copyrighted property of the United States
    Postal Service¨ (Postal Serviceª). All rights reserved. The information
    and images presented here may not under any circumstances be reproduced
    or used without prior written permission. Users may view and download
    material from this site only for the following purposes: (a) for personal,
    non-commercial home use; (b) where the materials clearly state that these
    materials may be copied and reproduced according to the terms stated in
    those particular pages; or (c) with the express written permission of the
    Postal Service. In all other cases, you will need written permission from
    the Postal Service to reproduce, republish, upload, post, transmit,
    distribute or publicly display material from this Web site. Users agree not
    to use the site for sale, trade or other commercial purposes. Users may not
    use language that is threatening, abusive, vulgar, discourteous or criminal.
    Users also may not post or transmit information or materials that would
    violate rights of any third party or which contains a virus or other harmful
    component. The Postal Service reserves the right to remove or edit any
    messages or material submitted by users. 

The author believes that the example usage given above does not violate
these terms, but sole responsibility for conforming to the terms of use
belongs to the user of this code, not the author.



# BUG REPORTS

When contacting the author with bug reports, please provide a test address that
exhibits the problem, and make sure it is OK to add that address to the test
suite.

Be sure to let me know if you don't want me to mention your name or email
address when I document the changes and contributions to the release. Typically
I put this information in the CHANGES file.



# AUTHOR

Gregor N. Purdy, Sr. `gnp@acm.org`.



# COPYRIGHT

Copyright (C) 1999-2012 Gregor N. Purdy, Sr. All rights reserved.

This program is free software. It is subject to the same license as Perl.