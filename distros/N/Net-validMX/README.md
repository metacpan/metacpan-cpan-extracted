[![CI for Net::validMX](https://github.com/The-McGrail-Foundation/Net-validMX/actions/workflows/main.yml/badge.svg)](https://github.com/The-McGrail-Foundation/Net-validMX/actions/workflows/main.yml)

NAME
    Net::validMX - PERL Module to use DNS and/or regular expressions to
    verify if an email address could be valid.

SYNOPSIS
    Net::validMX - I wanted the ability to use DNS to verify if an email
    address COULD be valid by checking for valid MX records. This could be
    used for sender verification for emails with a program such as
    MIMEDefang or for websites to verify email addresses prior to
    registering users and/or sending a confirmation email.

PRE-REQUISITE MODULES
    Net::DNS v0.53 or greater. Test::More.

INSTALLATION
    To install this package, uncompress the distribution, change to the
    directory where the files are present and type:

            perl Makefile.PL
            make
            make test
            make install

USE
    To use the module in your programs you will use the line:

            use Net::validMX;

  check_valid_mx
    To check if an email address could be valid by checking the DNS, call
    the function check_valid_mx with a single email address as the only
    argument:

            ($rv, $reason) = Net::validMX::check_valid_mx('kevin.mcgrail@peregrinehw.com');

    check_valid_mx will return a true/false integer as the first value and a
    descriptive text message as warranted.

    NOTE: In the event of a DNS resolution problem, we do NOT return a
    failure. We return a success to prevent DNS outages and delays from
    producing too many false positives.

  check_email_validity
    To check if an email address is formatted correctly, call the function
    check_email_validity with a single email address as the only argument:

            $rv = Net::validMX::check_valid_mx('kevin.mcgrail@peregrinehw.com');

    check_email_validity will return a true/false integer where > 0
    indicates that the email address looks valid.

  check_email_and_mx
    To check if an email address is formatted correctly, sanitize the email
    address some common end-user errors(*) and run check_valid_mx all from a
    single function, use the function check_email_and_mx with a single email
    address as the only argument:

            ($rv, $reason, $sanitized_email) = Net::validMX::check_valid_mx('kevin.mcgrail@peregrinehw.com');

    check_email_and_mx will return a true/false integer where > 0 indicates
    that the email address looks valid, a descriptive text message as
    warranted, and a sanitized version of the email address argument.

    (*) Common end-user errors that are fixed:

    All spaces are stripped. Many users seem to enter things like Bob and
    Carol @ a big isp.com.
    Emails ending in @aol. or @aol are fixed to be @aol.com. Also done for
    hotmail.com, live.com & gmail.com.

  get_domain_from_email
    To extract the domain part and local part from an email address, use the
    function get_domain_from_email with a single email address as the only
    argument:

            $domain = Net::validMX::get_domain_from_email('kevin.mcgrail@peregrinehw.com');

    get_domain_from_email will return a string with the domain part of the
    email address argument.

    Optionally, you can also receive the local part as well:

            ($local, $domain) = Net::validMX::get_domain_from_email('kevin.mcgrail@peregrinehw.com');

  check_spf_for_domain
    To check if a domain is properly configured to send email, call the
    function check_spf_for_domain with a domain name as the only argument:

            ($rv, $reason) = Net::validMX::check_spf_for_domain('peregrinehw.com');

    check_spf_for_domain will return "valid", "suspect", or "bad" as the
    first value and a descriptive text message as warranted.

  EXAMPLE
    The distribution contains an example program to demonstrate working
    functionality as well to utilize as a command line interface to query
    one or more email addresses.

    Run the program with the space-seperated email addresses to test as your
    arguments:

            perl example/check_email_and_mx.pl kevin.mcgrail@peregrinehw.com 
    or
            perl example/check_email_and_mx.pl kevin.mcgrail@peregrinehw.com google@google.com president@whitehouse.gov

    If you supply only one email address argument, the program will exit
    with a exit status of 0 for a success and 1 for a failure:

            perl example/check_email_and_mx.pl kevin.mcgrail@failed || echo 'This email is no good'     

  MIMEDEFANG
    We are using this routine with MIMEDefang and have been since late 2005
    via the filter_sender hooks. For example, make a function that excludes
    authorized senders for your particular setup and add the following code
    snippets to your mimedefang-filter:

    sub filter_initialize {
      #for Check Valid MX
      use Net::validMX qw(check_valid_mx);
    }

    sub is_authorized_sender {
      my ($sender, $RelayAddr) = @_;

      if ([test for authorized user, private IP's, relay from 127.0.0.1, etc.]) {
        return 1;
      } else {
        return 0;
      }
    }

    sub filter_sender {
      my ($sender, $ip, $hostname, $helo) = @_;
      my ($rv, $reason);
      #md_syslog('warning', "Testing $sender, $ip, $hostname, $helo");

      if (is_authorized_sender($sender, $RelayAddr)) {
        return ('CONTINUE', "ok");
      }

      if ($sender ne '<>') {
        ($rv, $reason) = check_valid_mx($sender);
        unless ($rv) {
          md_syslog('warning', "Rejecting $sender - Invalid MX: $reason.");
          return ('REJECT', "Sorry; $sender has an invalid MX record: $reason.");
        }
      }
    }

COPYRIGHT & LICENSE
    Copyright (c) 2020 The McGrail Foundation and Kevin A. McGrail. All
    rights reserved.

    This distribution, including all of the files in the Net::validMX
    package, is free software; you can redistribute it and/or modify it
    under the Perl Artistic License v1.0 available at
    https://www.perlfoundation.org/artistic-license-10.html

    perlartistic

AUTHOR INFORMATION
    Kevin A. McGrail kevin.mcgrail-netvalidmx@pccc.com

UPDATE HISTORY  
    v1.0 Released Oct 11, 2005. Original release for MIMEDefang filter.  
    v2.0 Released Nov 3, 2005. Incorporated many user updates.  
    v2.1 Released May 23, 2006. Switched to a perl Library (Net::validMX).  
    Small efficiency change to short-circuit the DNS resolution of an IP address.    
    v2.2 Released May 31, 2006. Clarified the LICENSE by pointing readers to the README.  
    Added functions check_email_and_mx & check_email_validity.  
    Expanded documentation and added check_email_and_mx &  
    check_email_validity calls to example. Cleaned up distribution production.  
    Changed logic to check MX records that resolve to IPs to see if it is privatized first.  
    v2.3 & 2.4 Unreleased.  
    Clarified the license in the Makefile.PL as artistic rather than perl.  
    Continued documentation cleanup. Submitted for namespace registration with CPAN.  
    Added = to chars for a username in the check_email_validity function.  
    Add test case for Test for DNS where MX1 is private, MX2 is private   
    but MX3 is a valid internet address for a pass.  
    Began adding overloaded parameters to check_valid_mx to add flexibility to override default settings.  
    Added AAAA records as valid for IPv6 support.  
    Rewrote all tests to rely on test points inside a domain we control   
    so that testing passes in the future.  
    v2.5 Released May 8, 2020. Numerous bug fixes and moved to The McGrail  
    Foundation.  
    v2.5.1 Released April 4, 2023. Documentation bug fixes and improved ipv6 support.  
    This product is in active use in production system.  

HOMEPAGE
    Releases can be found at https://mcgrail.com/downloads/Net-validMX/ and  
    on CPAN at https://metacpan.org/pod/Net::validMX.

CAVEATS
    THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
    WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
    MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

CREDITS
    Based on an idea from Les Miksell and much input from Jan Pieter Cornet.
    Additional thanks to David F. Skoll, Matthew van Eerde, and Mark Damrose
    for testing and suggestions, plus Bill Cole & Karsten Bräckelmann for
    code contributions. And sincere apologies in advance if I missed anyone!

