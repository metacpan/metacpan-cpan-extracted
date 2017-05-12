package Net::validMX;

use strict;
use Net::DNS;

use vars qw(
    $VERSION
    @ISA
    @EXPORT_OK
);

BEGIN {
    require DynaLoader;
    require Exporter;

    @ISA     = qw(Exporter DynaLoader);
    $VERSION = '2.2.0';
}

sub version      { $VERSION; }

@EXPORT_OK = qw(check_valid_mx get_output_result check_email_and_mx check_email_validity);

sub get_output_result {
  my ($email, $rv, $reason) = @_;
  my ($output);

  $output = "$email\n\tValid MX? ".&Net::validMX::int_to_truefalse($rv);
  if ($reason ne '') {
    $output .= " - $reason";
  }
  $output .=  "\n\n";

  return $output;
}

sub check_valid_mx {
  #Based on Idea from Les Miksell and much input from Jan Pieter Cornet
  #KAM 9-12-05 updated 10-24-05 & 11-3-05.
  #takes the sender, extracts the domain name and performs multiple MX tests to see if the domain has valid
  #MX exchange records 

  my ($sender) = @_;
  my ($res, $packet, @answer, $SenderDomain, @answer2, @answer3, $rv, $reason, $i, @unsorted_answer, $debug);
  my ($check_implicit_mx, $allow_ip_address_as_mx);

  #CONSTANTS
  $debug = 0;
  $allow_ip_address_as_mx = 1;

  #FLAGS
  $check_implicit_mx = 0;


  #Setup a DNS Resolver Resource
  $res = Net::DNS::Resolver->new;

  if (defined ($res)) {
    $check_implicit_mx = 0;
    $res->defnames(0);		       #Turn off appending the default domain for names that have no dots just in case
    $res->searchlist();		       #Set the search list to undefined just in case

				       #We have also set the timeout to only 4 seconds which means we might get network delays
                                       #which we do not want to handle as an error.
    $res->tcp_timeout(4);              #Number of Seconds before query will fail
    $res->udp_timeout(4);              #Number of Seconds before query will fail

    #Strip domain name from an email address
    $SenderDomain = $sender;
    $SenderDomain =~ s/(^<|>$)//g;
    $SenderDomain =~ s/^ *//g;
    $SenderDomain =~ s/ *$//g;
    $SenderDomain =~ s/.*\@//g;

    print "\nDEBUG: Extracted Sender Domain: $SenderDomain from $sender\n" if $debug;

    #Deny Explicit IP Address Domains
    if ($SenderDomain =~ /^\[.*\]$/) {
      $reason = "Use of IP Address $SenderDomain instead of a hostname is not allowed";
      print "DEBUG: Test Failed - $reason\n" if $debug;
      return (0, $reason);  
    }

    #Perform the DNS Query - Changed to Send instead of Query method to utilize the ancount method
    $packet = $res->send($SenderDomain,'MX');

    #Net::DNS::Resolver had an error
    if (!defined $packet) {
      print "DEBUG: There was an error retrieving the MX Records for $SenderDomain\n" if $debug;
      print "DEBUG: Test Passed by Default\n" if $debug;
      return(1, 'Test Passed due to a Resolution Problem retrieving the MX Records');
    }

    print "DEBUG: Number of Answers in the MX resolution packet is: ".$packet->header->ancount."\n" if $debug;
    #Parse the Query
    if ($packet->header->ancount > 0) {
      if (defined ($packet->answer)) {
        @answer = $packet->answer;

        for ($i = 0; $i < scalar(@answer); $i++) {
          if ($answer[$i]->type ne 'MX') {
            #DISCARD ANSWER IF THE RECORD IS NOT AN MX RECORD SUCH AS THE CNAME FOR londo.cysticercus.com
            print "DEBUG: Discarding one non-MX answer of type: ".$answer[$i]->type."\n" if $debug;
          } else {
            push @unsorted_answer, $answer[$i];
          }
        }

        undef @answer;

        print "DEBUG: Number of Answers Left to Check after discarding all but MX: ".scalar(@unsorted_answer)."\n" if $debug;
        if (scalar(@unsorted_answer) < 1) {
          $check_implicit_mx++;
        } else {
          #Sort to put answers into ascending order by mail exchange preference 
          @answer = sort {$a->preference <=> $b->preference} @unsorted_answer;
        }

        #LOOP THROUGH THE ANSWERS WE HAVE 
        for ($i = 0; $i < scalar(@answer); $i++) {
          undef $packet;
          print "DEBUG: $i - MX Answer - Type: ".$answer[$i]->type." - Exchange: ".$answer[$i]->exchange." - Length: ".length($answer[$i]->exchange)."\n" if $debug;

          #localhost isn't a valid MX so return false
          if ($answer[$i]->exchange eq 'localhost') {
            $reason = 'Invalid use of Localhost as an MX record';
            print "DEBUG: Test Failed - $reason\n" if $debug;
            return (0, $reason);
          } 

          #IF the exchange is blank and the priority is 0 and it's the last answer, let's fail 
          if ($answer[$i]->exchange eq '' && int($answer[$i]->preference) == 0 && $i == $#answer) {
            #Test if there is a Blank MX record in the first slot Per Jan-Pieter Cornet recommendation
            #and based on http://ietfreport.isoc.org/all-ids/draft-delany-nullmx-00.txt
            $reason = 'Domain is publishing a blank MX record at Priority 0';
            print "DEBUG: Test Failed - $reason\n" if $debug;
            return (0, $reason);
          }

          #resolve the exchange record
          if ($answer[$i]->exchange ne '' and $answer[$i]->exchange !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
            $packet = $res->send($answer[$i]->exchange, 'A'); 
 
            if (!defined ($packet)) {
              #THERE WAS AN ERROR TRYING TO RESOLVE THE MAIL EXCHANGE
              print "DEBUG: Test Passed by Default\n" if $debug;
              return (1, 'Test Passed due to a Resolution Problem');
            }
            print "DEBUG: $i - Number of Answers in the MX->A resolution packet is: ".$packet->header->ancount."\n" if $debug; 
          }

          if (defined $packet && $packet->header->ancount > 0) {
            @answer2 = $packet->answer;

            print "DEBUG: $i - Resolution type of ".$answer[$i]->exchange.": ".$answer2[0]->type."\n" if $debug; 
            if ($answer2[0]->type eq "A") {
              print "DEBUG: $i - A Name Address for ".$answer[$i]->exchange.": ".$answer2[0]->address."\n" if $debug;
              ($rv, $reason) = &invalid_mx($answer2[0]->address);
              if ($rv == 1 or ($rv == 2 && $i == $#answer)) {
                if ($rv == 2) {
                  $reason .= ' - All MX Records Failed';
                } 
                print "DEBUG: Test Failed - $reason\n" if $debug; 
                return (0, $reason);
              } elsif ($rv < 1) {
                print "DEBUG: Test Passed ".$answer2[0]->address." looks good\n" if $debug;
                return (1, '');
              }
            } elsif ($answer2[0]->type eq "CNAME") {
              $packet = $res->send($answer2[0]->cname,'A');

              if (!defined ($packet)) {
                #THERE WAS AN ERROR TRYING TO RESOLVE THE CNAME FOR THE MAIL EXCHANGE
                print "DEBUG: Test Passed by Default\n" if $debug;
                return (1, 'Test Passed due to a Resolution Problem');
              }

              if ($packet->header->ancount > 0) {
                if (defined ($packet->answer)) {
                  @answer3 = $packet->answer; 
                  print "DEBUG: $i - CNAME Resolution of Type: ".$answer3[0]->type." - Address: ".$answer3[0]->address."\n" if $debug;
                  if ($answer3[0]->type eq "A") {
                    ($rv, $reason) = &invalid_mx($answer3[0]->address);
                    if ($rv == 1 or ($rv == 2 && $i == $#answer)) {
                      if ($rv == 2) {
                        $reason .= ' - All MX Records Failed';
                      } 
                      print "DEBUG: Test Failed - $reason\n" if $debug;
                      return (0, $reason);
                    } elsif ($rv < 1) {
                      print "DEBUG: Test Passed ".$answer3[0]->address." looks good\n" if $debug;
                      return (1,'');
                    }
                  } else {
                    #CNAMEs aren't RFC valid for MX's so if they chained two together, I'm not recursively resolving anymore levels, I'm just failing it
                    $reason = 'Invalid use of CNAME for MX record';
                    print "DEBUG: Test Failed - $reason\n" if $debug;
                    return (0, $reason);
                  }
                }
              } else {
                if ($allow_ip_address_as_mx > 0 && $answer[$i]->exchange =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
                  ($rv, $reason) = &invalid_mx($answer[$i]->exchange);
                  if ($rv) {
                    return (0, $reason);
                  } else {
                    print "DEBUG: Test Passed - Allowing IP Address as Hostname\n" if $debug;
                    return (1, '');
                  }
                }

                #MX RECORD IS A CNAME WHICH DOES NOT RESOLVE
                $reason = "MX Record: ".$answer2[0]->cname." does not resolve";
                print "DEBUG: Test Failed - $reason\n" if $debug;
                return (0, $reason);
              }
            }
          } else {
            #IF THIS IS THE LAST MX RECORD AND THE EXCHANGE IS BLANK, WE FAIL IT
            if ($answer[$i]->exchange eq '') {
              if ($i == $#answer) {
                $reason = 'Domain is publishing only invalid and/or blank MX records'; 
                print "DEBUG: Test Failed - $reason\n" if $debug;
                return (0, $reason);
              }
            } else {
              #PERHAPS WE'LL ALLOW AN IP ADDRESS AS AN MX FOR MORONS WHO CONFIGURE DNS INCORRECTLY
              if ($allow_ip_address_as_mx > 0 && $answer[$i]->exchange =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
                ($rv, $reason) = &invalid_mx($answer[$i]->exchange);
                if ($rv) {
                  return (0, $reason);
                } else {
                  print "DEBUG: Test Passed - Allowing IP Address as Hostname\n" if $debug;
                  return (1, '');
                }
              }

              #MX RECORD RETURNED DOES NOT RESOLVE
              $reason = "MX Record: ".$answer[$i]->exchange." does not resolve";
              print "DEBUG: Test Failed - $reason\n" if $debug;
              return (0, $reason);
            }
          }
        }
      }
    } else {
      ($rv, $reason) = $check_implicit_mx++;
    }

    print "DEBUG: Checking Implicit MX is set to $check_implicit_mx\n" if $debug;

    if ($check_implicit_mx > 0) {
      ($rv, $reason) = &check_implicit_mx($SenderDomain, $res, $debug);
      if (defined $rv) {
        return ($rv, $reason);
      }
    }
  } else {
    print "DEBUG: There was an error setting up a Net::DNS::Resolver resource\n" if $debug;
    print "DEBUG: Test Passed by Default\n" if $debug;
    return (1, 'Test Passed due to a Resolution Problem');
  }

  print "DEBUG: Test Passed\n" if $debug;
  return (1,'');
}

sub check_implicit_mx ($$) {
  my ($SenderDomain, $res, $debug) = @_;
 
  my ($rv, $reason, $packet, @answer, @answer2);

  print "DEBUG: Checking for Implicit MX Records\n" if $debug;
  #NO MX RECORDS RETURNED - CHECK FOR IMPLICIT MX RECORD BY A RECORD per Jan-Pieter Cornet recommendation
  $packet = $res->send($SenderDomain,'A');
  if (!defined ($packet)) {
    #THERE WAS AN ERROR - NO IMPLICIT A RECORD COULD BE RESOLVED
    print "DEBUG: Test Passed by Default\n" if $debug;
    return (1, 'Test Passed due to a Resolution Problem');
  }

  print "DEBUG: Number of Answers in the Implicit A record resolution packet is: ".$packet->header->ancount."\n" if $debug;
  if ($packet->header->ancount > 0) {
    @answer = $packet->answer;
    if ($answer[0]->type eq "A") {
      print "DEBUG: $SenderDomain has no MX Records - Using Implicit A Record: ".$answer[0]->address."\n" if $debug;
      ($rv, $reason) = &invalid_mx($answer[0]->address);
      if ($rv) {
        print "DEBUG: Test Failed - $reason\n" if $debug;
        return (0, $reason);
      } else {
        print "DEBUG: Test Passed ".$answer[0]->address." looks good\n" if $debug;
        return (1, '');
      }
    } elsif ($answer[0]->type eq "CNAME") {
      #IS THIS REALLY A NECESSARY TEST?  SHOULD WE BE TESTING FOR IMPLICIT CNAME RECORDS?
      print "DEBUG: $SenderDomain has no MX Records - Using CNAME to Check for Implicit A Record: ".$answer[0]->cname."\n" if $debug;
      $packet = $res->send($answer[0]->cname,'A');

      if (!defined ($packet)) {
        #THERE WAS AN ERROR TRYING TO RESOLVE THE CNAME FOR THE MAIL EXCHANGE
        print "DEBUG: Test Passed by Default\n" if $debug;
        return (1, '');
      }

      if ($packet->header->ancount > 0) {
        if (defined ($packet->answer)) {
          @answer2 = $packet->answer;
          if ($answer2[0]->type eq "A") {
             print "DEBUG: CNAME Resolution of Type: ".$answer2[0]->type." - Address: ".$answer2[0]->address."\n" if $debug;
            ($rv, $reason) = &invalid_mx($answer2[0]->address);
            if ($rv > 0) {
              print "DEBUG: Test Failed - $reason\n" if $debug;
              return (0, $reason);
            } else {
              print "DEBUG: Test Passed ".$answer2[0]->address." looks good\n" if $debug;
              return (1, '');
            }
          } else {
            #CNAMEs aren't RFC valid for MX's so if they chained two together, I'm not recursively resolving anymore levels, I'm just failing it
            $reason = 'Invalid use of CNAME for Implicit MX record';
            print "DEBUG: Test Failed - $reason\n" if $debug;
            return (0, $reason);
          }
        }
      }
    }
  } else {
    $reason = "No MX or A Records Exist for $SenderDomain";
    print "DEBUG: Test Failed - $reason\n" if $debug;
    return (0, $reason);
  }
  return undef;
}

sub invalid_mx {
  my ($ip) = @_;
  my ($flag_intranets);

  #0/8, 255/8, 127/8 aren't a valid MX so return false - added per Matthew van Eerde recomendation
  if ($ip =~ /^(255|127|0)\./) {
    return (1, "Invalid use of 0/8, 255/8 or 127/8 ($ip) as an MX record");
  }

  $flag_intranets = 1;

  #10/8 
  if ($flag_intranets && $ip =~ /^10\./) {
    return (2, "Invalid use of private IP (e.g. $ip) range for MX");
  }
  #172.16/12 - Fixed per Matthen van Eerde
  if ($flag_intranets && $ip =~ /^172\.(16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)\./) {
    return (2, "Invalid use of private IP (e.g. $ip) range for MX");
  }
  #192.168/16
  if ($flag_intranets && $ip =~ /^192\.168\./) {
    return (2, "Invalid use of private IP (e.g. $ip) range for MX");
  }

  #DHCP auto-discover added per Matthew van Eerde recomendation 169.254/16
  if ($ip =~ /^169\.254\./) {
    return (1, "Invalid use of a DHCP auto-discover IP range ($ip) as an MX record");
  }

  #Multicast 224/8 through 239/8 added per Matthew van Eerde recomendation
  if ($ip =~ /^(224|225|226|227|228|229|230|231|232|233|234|235|236|237|238|239)\./) {
    return (1, "Invalid use of a Multicast IP range ($ip) as an MX record");
  } 

  #Experimental block - Former Class E - 240.0.0.0/4 courtesy of Mark Damrose
  if ($ip =~ /^2[45]\d\./) {
    return (1, "Invalid use of an experimental IP ($ip) as an MX record");
  } 

  #Reserved for benchmark tests of interconnect devices 192.18.0.0/15 courtesy of Mark Damrose
  if ($ip =~ /^192\.1[89]\./) {
    return (1, "Invalid use of a reserved IP ($ip) as an MX record");
  } 

  #Reserved for documentation or published examples 192.0.2.0/24 courtesy of Mark Damrose
  if ($ip =~ /^192\.0\.2\./) {
    return (1, "Invalid use of a reserved IP ($ip) as an MX record");
  } 

  
  return (0,'');
}

sub int_to_truefalse {
  my ($int) = @_;

  if ($int) {
    return "True";
  } else {
    return "False";
  }
}

sub check_email_and_mx {
  my ($email) = @_;
  my ($rv, $fail_reason, $status, $debug);

  $debug = 0;

  $email || return 0;
  
  print "DEBUG: e-mail address is: $email<br>\n" if $debug;
  
  # SANITIZE THE E-MAIL ADDRESS OF SPACES
  $email =~ s/ //g;

  # CHECK FOR STUPID AOL USERS
  $email =~ s/\@aol\.?$/\@aol.com/i;

  print "DEBUG: e-mail address is now: $email<br>\n" if $debug;
  
  # CHECK FOR A VALIDLY CONSTRUCTED E-MAIL ADDRESS
  ($rv) = &Net::validMX::check_email_validity($email);
  
  if ($rv < 1) {
    return($rv, "Failed check_email_validity", $email);
  }

  # CHECK FOR VALID MX RECORD
  ($rv, $fail_reason) = &Net::validMX::check_valid_mx($email);

  if ($rv < 1) {
    return($rv, $fail_reason, $email);
  }

  return($rv, "Passed", $email);
}

sub check_email_validity {
  my ($email) = @_;

  #allows an email address that contains -()/!#$%&*+~. A through Z a through Z and 0 through 9 in a format of [valid]@([valid].[valid]...).[valid] 
  if ($email =~ /\.\./) {
    return 0;
  }

  if ($email =~ /^[-()\/!#$%&*+~_A-Za-z0-9\.]+@[-()\/!#$%&*+~_A-Za-z0-9\.]+\.[-()\/!#$%&*+~_A-Za-z0-9\.]+$/) {
    return 1;
  }
  return 0;

}

1;

__END__

=head1 NAME

Net::ValidMX - PERL Module to use DNS and/or regular expressions to verify if an email 
address could be valid.

=head1 SYNOPSIS

Net::ValidMX - I wanted the ability to use DNS to verify if an email address
COULD be valid by checking for valid MX records.  This could be used for sender 
verification for emails with a program such as MIMEDefang or for websites to 
verify email addresses prior to registering users and/or sending a confirmation email.

=head1 PRE-REQUISITE MODULES

Net::DNS v0.53 or greater.
Test::More.

=head1 INSTALLATION

To install this package, uncompress the distribution, change to the directory 
where the files are present and type:

	perl Makefile.PL
	make
	make test
	make install

=head1 USE

To use the module in your programs you will use the line:

	use Net::ValidMX;

=head2 check_valid_mx

To check if an email address could be valid by checking the DNS, call
the function check_valid_mx with a single email address as the only argument:

	($rv, $reason) = &Net::validMX::check_valid_mx('kevin.mcgrail@thoughtworthy.com');

check_valid_mx will return a true/false integer as the first value and a descriptive text message as warranted.

NOTE: In the event of a DNS resolution problem, we do NOT return a failure.  We return a success to prevent DNS outages and delays from producing too many false positives.


=head2 check_email_validity

To check if an email address is formatted correctly, call the function
check_email_validity with a single email address as the only argument:

	$rv = &Net::validMX::check_valid_mx('kevin.mcgrail@thoughtworthy.com');

check_email_validity will return a true/false integer where > 0 indicates that the email address looks valid.


=head2 check_email_and_mx

To check if an email address is formatted correctly, sanitize the email address some common end-user errors(*) and run check_valid_mx all from a single function, 
use the function check_email_and_mx with a single email address as the only argument:

        ($rv, $reason, $sanitized_email) = &Net::validMX::check_valid_mx('kevin.mcgrail@thoughtworthy.com');

check_email_and_mx will return a true/false integer where > 0 indicates that the email address looks valid, a descriptive text message 
as warranted, and a sanitized version of the email address argument .

(*) Common end-user errors that are fixed: 

=item All spaces are stripped.  Many users seem to enter things like Bob and Carol @ a big isp.com.

=item Emails ending in @aol. or @aol

=head2 EXAMPLE

The distribution contains an example program to demonstrate working functionality as well to utilize as a command line interface
to query one or more email addresses.

Run the program with the space-seperated email addresses to test as your arguments:

	perl example/check_email_and_mx.pl kevin.mcgrail@thoughtworthy.com 
or
	perl example/check_email_and_mx.pl kevin.mcgrail@thoughtworthy.com google@google.com president@whitehouse.gov

If you supply only one email address argument, the program will exit with a exit status of 0 for a success and 1 for a failure:

	perl example/check_email_and_mx.pl kevin.mcgrail@failed || echo 'This email is no good'     

=head2 MIMEDEFANG

We are using this routine with MIMEDefang and have been for many months via the filter_sender hooks.  For example, make a function that excludes authorized senders for your particular setup and add the following code snippets to your mimedefang-filter:

sub filter_initialize {
  #for Check Valid MX
  use Net::validMX qw(check_valid_mx);
}

sub is_authorized_sender {
  my ($sender, $RelayAddr) = @_;

  if ([test for authorized user]) {
    return 1;
  } else {
    return 0;
  }
}

sub filter_sender {
  my ($sender, $ip, $hostname, $helo) = @_;
  my ($rv, $reason);
  #md_syslog('warning', "Testing $sender, $ip, $hostname, $helo");

  if (&is_authorized_sender($sender, $RelayAddr)) {
    return ('CONTINUE', "ok");
  }

  if ($sender ne '<>') {
    ($rv, $reason) = &check_valid_mx($sender);
    unless ($rv) {
      md_syslog('warning', "Rejecting $sender - Invalid MX: $reason.");
      return ('REJECT', "Sorry; $sender has an invalid MX record: $reason.");
    }
  }
}


=head1 COPYRIGHT 

Copyright (c) 2006 Kevin A. McGrail.  All rights reserved.

This distribution, including all of the files in the Net::validMX package, is free software; you can redistribute it and/or modify it under the Perl Artistic License v1.0 available at http://www.perlfoundation.org/legal/licenses/artistic-1_0.html

L<perlartistic>

=head1 AUTHOR INFORMATION

Kevin A. McGrail
kevin.mcgrail@thoughtworthy.com

=head1 UPDATE HISTORY

=over 4

=item v1.0  Released Oct 11, 2005.  Original release for MIMEDefang filter.

=item v2.0  Released Nov 3, 2005.  Incorporated many user updates.

=item v2.1  Released May 23, 2006.  Switched to a perl Library (Net::validMX).  Small efficiency change to short-circuit the DNS resolution of an IP address.

=item v2.2  Under Development.  Clarified the LICENSE by pointing readers to the README.  Added functions check_email_and_mx & check_email_validity.  Expanded documentation and added check_email_and_mx & check_email_validity calls to example.  Cleaned up distribution production.  Changed logic to check MX records that resolve to IPs to see if it is privatized first.

=back

=head1 HOMEPAGE

Releases can be found at http://www.thoughtworthy.com/downloads/ and
on CPAN at http://search.cpan.org/~kmcgrail/.

=head1 CAVEATS

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 TODO

=over 4

=item - I'd like to have the example script automatically built to have the correct #!/usr/bin/perl line and possibly installed in /usr/local/bin.

=head1 SOLVED TODO ITEMS

=item - I'd like to convert the example script(s) into test script(s).  

ANSWER: Test::More was a great way to achieve this!

=item - I'd like to know more info on what/how to make a META.yml file.

ANSWER: I was using MakeMaker v6.03.  Instead I upgraded to 6.30 and make dist or make distdir then created the META.yml file.  I also used a trick from Net::DNS' Makefile.PL to add the license, author and abstract data directly to the META.yml file.

=item - I'd like to make it so that the Makefile.PL creates a README on the fly from the pod in the library instead of pod2text lib/Net/validMX.pm > README.

ANSWER: Thanks to Andreas J. Koenig for a post he wrote that dealt with my exact problem.  I added the PREOP and DIST_DEFAULT to the Makefile.PL.  I then modified this to use the same MANIFEST trick that is used for metafile and I'm happy with the end result.

=back

=head1 CREDITS

Based on an idea from Les Miksell and much input from Jan Pieter Cornet.  Additional thanks to David F. Skoll, Matthew van Eerde, and Mark Damrose
for testing and suggestions.  And sincere apologies in advance if I missed anyone!

=cut
