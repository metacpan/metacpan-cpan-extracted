# 			 The "Artistic License"
# 
# 				Preamble
# 
# The intent of this document is to state the conditions under which a
# Package may be copied, such that the Copyright Holder maintains some
# semblance of artistic control over the development of the package,
# while giving the users of the package the right to use and distribute
# the Package in a more-or-less customary fashion, plus the right to make
# reasonable modifications.
# 
# Definitions:
# 
# 	"Package" refers to the collection of files distributed by the
# 	Copyright Holder, and derivatives of that collection of files
# 	created through textual modification.
# 
# 	"Standard Version" refers to such a Package if it has not been
# 	modified, or has been modified in accordance with the wishes
# 	of the Copyright Holder as specified below.
# 
# 	"Copyright Holder" is whoever is named in the copyright or
# 	copyrights for the package.
# 
# 	"You" is you, if you're thinking about copying or distributing
# 	this Package.
# 
# 	"Reasonable copying fee" is whatever you can justify on the
# 	basis of media cost, duplication charges, time of people involved,
# 	and so on.  (You will not be required to justify it to the
# 	Copyright Holder, but only to the computing community at large
# 	as a market that must bear the fee.)
# 
# 	"Freely Available" means that no fee is charged for the item
# 	itself, though there may be fees involved in handling the item.
# 	It also means that recipients of the item may redistribute it
# 	under the same conditions they received it.
# 
# 1. You may make and give away verbatim copies of the source form of the
# Standard Version of this Package without restriction, provided that you
# duplicate all of the original copyright notices and associated disclaimers.
# 
# 2. You may apply bug fixes, portability fixes and other modifications
# derived from the Public Domain or from the Copyright Holder.  A Package
# modified in such a way shall still be considered the Standard Version.
# 
# 3. You may otherwise modify your copy of this Package in any way, provided
# that you insert a prominent notice in each changed file stating how and
# when you changed that file, and provided that you do at least ONE of the
# following:
# 
#     a) place your modifications in the Public Domain or otherwise make them
#     Freely Available, such as by posting said modifications to Usenet or
#     an equivalent medium, or placing the modifications on a major archive
#     site such as uunet.uu.net, or by allowing the Copyright Holder to include
#     your modifications in the Standard Version of the Package.
# 
#     b) use the modified Package only within your corporation or organization.
# 
#     c) rename any non-standard executables so the names do not conflict
#     with standard executables, which must also be provided, and provide
#     a separate manual page for each non-standard executable that clearly
#     documents how it differs from the Standard Version.
# 
#     d) make other distribution arrangements with the Copyright Holder.
# 
# 4. You may distribute the programs of this Package in object code or
# executable form, provided that you do at least ONE of the following:
# 
#     a) distribute a Standard Version of the executables and library files,
#     together with instructions (in the manual page or equivalent) on where
#     to get the Standard Version.
# 
#     b) accompany the distribution with the machine-readable source of
#     the Package with your modifications.
# 
#     c) give non-standard executables non-standard names, and clearly
#     document the differences in manual pages (or equivalent), together
#     with instructions on where to get the Standard Version.
# 
#     d) make other distribution arrangements with the Copyright Holder.
# 
# 5. You may charge a reasonable copying fee for any distribution of this
# Package.  You may charge any fee you choose for support of this
# Package.  You may not charge a fee for this Package itself.  However,
# you may distribute this Package in aggregate with other (possibly
# commercial) programs as part of a larger (possibly commercial) software
# distribution provided that you do not advertise this Package as a
# product of your own.  You may embed this Package's interpreter within
# an executable of yours (by linking); this shall be construed as a mere
# form of aggregation, provided that the complete Standard Version of the
# interpreter is so embedded.
# 
# 6. The scripts and library files supplied as input to or produced as
# output from the programs of this Package do not automatically fall
# under the copyright of this Package, but belong to whoever generated
# them, and may be sold commercially, and may be aggregated with this
# Package.  If such scripts or library files are aggregated with this
# Package via the so-called "undump" or "unexec" methods of producing a
# binary executable image, then distribution of such an image shall
# neither be construed as a distribution of this Package nor shall it
# fall under the restrictions of Paragraphs 3 and 4, provided that you do
# not represent such an executable image as a Standard Version of this
# Package.
# 
# 7. C subroutines (or comparably compiled subroutines in other
# languages) supplied by you and linked into this Package in order to
# emulate subroutines and variables of the language defined by this
# Package shall not be considered part of this Package, but are the
# equivalent of input as in Paragraph 6, provided these subroutines do
# not change the language in any way that would cause it to fail the
# regression tests for the language.
# 
# 8. Aggregation of this Package with a commercial distribution is always
# permitted provided that the use of this Package is embedded; that is,
# when no overt attempt is made to make this Package's interfaces visible
# to the end user of the commercial distribution.  Such use shall not be
# construed as a distribution of this Package.
# 
# 9. The name of the Copyright Holder may not be used to endorse or promote
# products derived from this software without specific prior written permission.
# 
# 10. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

package Net::validMX;

use strict;
use warnings;

use Net::DNS;

use vars qw(
    $VERSION
    @ISA
    @EXPORT_OK
    $DEBUG
    $ALLOW_IP_ADDRESS_AS_MX
    $FLAG_INTRANETS
    $RESOLUTION_PROBLEM_RETURN
    $QUERY_TIMEOUT
    $RESOLVER);

BEGIN {
    require DynaLoader;
    require Exporter;

    @ISA     = qw(Exporter DynaLoader);
    $VERSION = '2.6.1';
    $DEBUG   = 0;
    $ALLOW_IP_ADDRESS_AS_MX = 1;
    $FLAG_INTRANETS = 1;
    $RESOLUTION_PROBLEM_RETURN = 1;
    $QUERY_TIMEOUT = 4;
    $RESOLVER = undef;
}

sub version      { $VERSION; }

@EXPORT_OK = qw(check_valid_mx get_output_result check_email_and_mx check_email_validity get_domain_from_email);

# Arguments of the public subs: either the historical positional list or
# key => value pairs.  The named form is used when there is an even number
# of arguments and the first one is a known key name, otherwise the
# arguments are mapped onto the positional names.  With $trailing_pairs
# set, the arguments after the positional ones are key => value pairs, as
# in ($email, %params).
sub _args {
  my ($args, $positional, $named_only, $trailing_pairs) = @_;
  my %known = map { $_ => 1 } @$positional, @{$named_only || []};
  my %params;

  if (@$args and @$args % 2 == 0 and defined $args->[0] and not ref $args->[0] and $known{$args->[0]}) {
    %params = @$args;
  } else {
    my @args = @$args;
    foreach my $name (@$positional) {
      last unless @args;
      $params{$name} = shift @args;
    }
    %params = (@args, %params) if ($trailing_pairs and @args);
  }

  return %params;
}

sub _default_resolver {
  my ($query_timeout) = @_;
  my $res = Net::DNS::Resolver->new;

  if (defined ($res)) {
    $res->defnames(0);		       #Turn off appending the default domain for names that have no dots just in case
    $res->searchlist();		       #Set the search list to undefined just in case

				       #We have also set the default timeout to only 4 seconds which means we might get network
                                       #delays which we do not want to handle as an error.
    $res->tcp_timeout($query_timeout);              #Number of Seconds before query will fail
    $res->udp_timeout($query_timeout);              #Number of Seconds before query will fail
  }

  return $res;
}

sub new {
  my ($class, %params) = @_;
  my $self = bless {%params}, $class;

  $DEBUG = $self->{'debug'} if (defined $self->{'debug'} and $self->{'debug'} ne '');
  $ALLOW_IP_ADDRESS_AS_MX = $self->{'allow_ip_address_as_mx'} if (defined $self->{'allow_ip_address_as_mx'} and $self->{'allow_ip_address_as_mx'} ne '');
  $FLAG_INTRANETS = $self->{'flag_intranets'} if (defined $self->{'flag_intranets'} and $self->{'flag_intranets'} ne '');
  $RESOLUTION_PROBLEM_RETURN = $self->{'resolution_problem_return'} if (defined $self->{'resolution_problem_return'} and $self->{'resolution_problem_return'} ne '');
  $QUERY_TIMEOUT = $self->{'query_timeout'} if (defined $self->{'query_timeout'} and $self->{'query_timeout'} ne '');

  return $self;
}

sub get_debug {
  return $DEBUG;
}

sub set_debug {
  my %params = _args(\@_, ['debug']);
  $DEBUG = $params{'debug'};
}

sub get_output_result {
  my %params = _args(\@_, ['email', 'rv', 'reason']);
  my ($email, $rv, $reason) = @params{'email', 'rv', 'reason'};
  my ($output);

  $output = "$email\n\tValid MX? ".Net::validMX::int_to_truefalse($rv);
  if (defined $reason and $reason ne '') {
    $output .= " - $reason";
  }
  $output .=  "\n\n";

  return $output;
}

sub check_valid_mx {
  #Based on Idea from Les Miksell and much input from Jan Pieter Cornet
  #KAM 9-12-05 updated 10-24-05 & 11-3-05.
  #takes the email address, extracts the domain name and performs multiple MX tests to see if the domain has valid
  #MX exchange records 

  my ($res, $packet, @answer, $domain, @answer2, @answer3, $rv, $reason, $i, @unsorted_answer);
  my ($check_implicit_mx, %params, $self, $ref, $resolution_problem_status);

  #print "DEBUG: ref for \$_[0] ".ref($_[0]). "\n";
  #IN OO INSTEAD OF PROCEDURAL MODE?
  if (uc(ref($_[0])) eq 'NET::VALIDMX') {
    $self = shift(@_);
    #foreach $ref (keys %$self) {
    #  print "DEBUG: OO MODE - $ref: $self->{$ref} \n";
    #}
  } 

  #DID WE RECEIVE A HASH INSTEAD OF A SINGLE EMAIL?
  if ($#_ % 2 == 0) {
    ($params{'email'}) = @_;
  } else {
    %params = @_;
  }

  $params{'email'} || $params{'sender'} || return (0, 'A blank email address will not be tested.');

  #CONSTANTS / SETTABLE OPTIONS
  $params{'debug'} = $DEBUG unless (defined $params{'debug'});
  $params{'allow_ip_address_as_mx'} = $ALLOW_IP_ADDRESS_AS_MX unless (defined $params{'allow_ip_address_as_mx'});
  $params{'resolution_problem_return'} = $RESOLUTION_PROBLEM_RETURN unless (defined $params{'resolution_problem_return'});
  $params{'query_timeout'} = $QUERY_TIMEOUT unless (defined $params{'query_timeout'});
  $params{'resolver'} = $self->{'resolver'} if (not defined $params{'resolver'} and defined $self);
  $params{'resolver'} = $RESOLVER unless (defined $params{'resolver'});

  if ($params{'resolution_problem_return'} > 0) {
    $resolution_problem_status = 'Passed';
  } else {
    $resolution_problem_status = 'Failed';
  }

  print "DEBUG: function debug setting is $params{'debug'}\n" if $params{'debug'};
  print "DEBUG: function allow_ip_address_as_mx setting is $params{'allow_ip_address_as_mx'}\n" if $params{'debug'};
  print "DEBUG: function resolution_problem_return setting is $params{'resolution_problem_return'}\n" if $params{'debug'};
  print "DEBUG: function query_timeout setting is $params{'query_timeout'}\n" if $params{'debug'};

  #FLAGS - I THINK THIS HAS A LOGIC ISSUE - I LIKELY MEANT ALLOW_IMPLICIT_MX as an option  FIX
  $check_implicit_mx = 0;

  #Setup a DNS Resolver Resource, a resolver passed by the caller is used as is
  if (defined $params{'resolver'}) {
    $res = $params{'resolver'};
    print "DEBUG: using the resolver passed by the caller, query_timeout is not applied\n" if $params{'debug'};
  } else {
    $res = _default_resolver($params{'query_timeout'});
  }

  if (defined ($res)) {
    $check_implicit_mx = 0;

    #Strip domain name from an email address
    $domain = get_domain_from_email($params{'email'});

    #Deny Explicit IP Address Domains
    if ($domain =~ /^\[.*\]$/) {
      $reason = "Use of IP Address $domain instead of a hostname is not allowed";
      print "DEBUG: Test Failed - $reason\n" if $params{'debug'};
      return (0, $reason);  
    }

    #Perform the DNS Query - Changed to Send instead of Query method to utilize the ancount method
    $packet = $res->send($domain,'MX');

    #Net::DNS::Resolver had an error
    if (!defined $packet) {
      print "DEBUG: There was an error retrieving the MX Records for $domain\n" if $params{'debug'};
      print "DEBUG: Test Passed by Default\n" if $params{'debug'};
      return($params{'resolution_problem_return'}, "Test $resolution_problem_status due to a Resolution Problem retrieving the MX Records");
    }

    print "DEBUG: Number of Answers in the MX resolution packet is: ".$packet->header->ancount."\n" if $params{'debug'};
    #Parse the Query
    if ($packet->header->ancount > 0) {
      if (defined ($packet->answer)) {
        @answer = $packet->answer;

        for ($i = 0; $i < scalar(@answer); $i++) {
          if ($answer[$i]->type ne 'MX') {
            #DISCARD ANSWER IF THE RECORD IS NOT AN MX RECORD SUCH AS THE CNAME FOR londo.cysticercus.com
            print "DEBUG: Discarding one non-MX answer of type: ".$answer[$i]->type."\n" if $params{'debug'};
          } else {
            push @unsorted_answer, $answer[$i];
          }
        }

        undef @answer;

        print "DEBUG: Number of Answers Left to Check after discarding all but MX: ".scalar(@unsorted_answer)."\n" if $params{'debug'};
        if (scalar(@unsorted_answer) < 1) {
          $check_implicit_mx++;
        } else {
          #Sort to put answers into ascending order by mail exchange preference 
          @answer = sort {$a->preference <=> $b->preference} @unsorted_answer;
        }

        #LOOP THROUGH THE ANSWERS WE HAVE 
        for ($i = 0; $i < scalar(@answer); $i++) {
          undef $packet;
          print "DEBUG: $i - MX Answer - Type: ".$answer[$i]->type." - Exchange: ".$answer[$i]->exchange." - Length: ".length($answer[$i]->exchange)."\n" if $params{'debug'};

          #localhost isn't a valid MX so return false
          if ($answer[$i]->exchange eq 'localhost') {
            $reason = 'Invalid use of Localhost as an MX record';
            print "DEBUG: Test Failed - $reason\n" if $params{'debug'};
            return (0, $reason);
          } 

          #IF the exchange is blank and the priority is 0 and it's the last answer, let's fail 
          if (_blank_exchange($answer[$i]) && int($answer[$i]->preference) == 0 && $i == $#answer) {
            #Test if there is a Blank MX record in the first slot Per Jan-Pieter Cornet recommendation
            #and based on http://ietfreport.isoc.org/all-ids/draft-delany-nullmx-00.txt
            $reason = 'Domain is publishing a blank MX record at Priority 0';
            print "DEBUG: Test Failed - $reason\n" if $params{'debug'};
            return (0, $reason);
          }

          #resolve the exchange record
          if (!_blank_exchange($answer[$i]) and $answer[$i]->exchange !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
            $packet = $res->send($answer[$i]->exchange, 'A'); 
 
            if (!defined ($packet)) {
              #THERE WAS AN ERROR TRYING TO RESOLVE THE MAIL EXCHANGE
              print "DEBUG: Test Passed by Default\n" if $params{'debug'};
              return ($params{'resolution_problem_return'}, 'Test '.$resolution_problem_status.' due to a Resolution Problem');
            }
            print "DEBUG: $i - Number of Answers in the MX->A resolution packet is: ".$packet->header->ancount."\n" if $params{'debug'}; 

            #TEST TO SEE IF IT'S AN AAAA IPv6 RECORD - Thanks to Subramanian MOONESAMY sm@megawatt.resistor.net for pointing this out!
            if (defined $packet && $packet->header->ancount < 1) {
              $packet = $res->send($answer[$i]->exchange, 'AAAA');

              if (!defined ($packet)) {
                #THERE WAS AN ERROR TRYING TO RESOLVE THE MAIL EXCHANGE
                print "DEBUG: Test Passed by Default\n" if $params{'debug'};
                return ($params{'resolution_problem_return'}, 'Test '.$resolution_problem_status.' due to a Resolution Problem');
              }
              print "DEBUG: $i - Number of Answers in the MX->AAAA resolution packet is: ".$packet->header->ancount."\n" if $params{'debug'};
            }
          }

          if (defined $packet && $packet->header->ancount > 0) {
            @answer2 = $packet->answer;

            print "DEBUG: $i - Resolution type of ".$answer[$i]->exchange.": ".$answer2[0]->type."\n" if $params{'debug'}; 
            if ($answer2[0]->type =~ /^A{1,4}/) {
              print "DEBUG: $i - A Name Address for ".$answer[$i]->exchange.": ".$answer2[0]->address."\n" if $params{'debug'};
              ($rv, $reason) = invalid_mx($answer2[0]->address);
              if ($rv == 1 or ($rv == 2 && $i == $#answer)) {
                if ($rv == 2) {
                  $reason .= ' - All MX Records Failed';
                } 
                print "DEBUG: Test Failed - $reason\n" if $params{'debug'}; 
                return (0, $reason);
              } elsif ($rv < 1) {
                print "DEBUG: Test Passed ".$answer2[0]->address." looks good\n" if $params{'debug'};
                return (1, '');
              }
            } elsif ($answer2[0]->type eq "CNAME") {
              $packet = $res->send($answer2[0]->cname,'A');

              if (!defined ($packet)) {
                #THERE WAS AN ERROR TRYING TO RESOLVE THE CNAME FOR THE MAIL EXCHANGE
                print "DEBUG: Test Passed by Default\n" if $params{'debug'};
                return ($params{'resolution_problem_return'}, 'Test '.$resolution_problem_status.' due to a Resolution Problem');
              }

              if ($packet->header->ancount > 0) {
                if (defined ($packet->answer)) {
                  @answer3 = $packet->answer; 
                  print "DEBUG: $i - CNAME Resolution of Type: ".$answer3[0]->type." - Address: ".$answer3[0]->address."\n" if $params{'debug'};
                  if ($answer3[0]->type eq "A") {
                    ($rv, $reason) = invalid_mx($answer3[0]->address);
                    if ($rv == 1 or ($rv == 2 && $i == $#answer)) {
                      if ($rv == 2) {
                        $reason .= ' - All MX Records Failed';
                      } 
                      print "DEBUG: Test Failed - $reason\n" if $params{'debug'};
                      return (0, $reason);
                    } elsif ($rv < 1) {
                      print "DEBUG: Test Passed ".$answer3[0]->address." looks good\n" if $params{'debug'};
                      return (1,'');
                    }
                  } else {
                    #CNAMEs aren't RFC valid for MX's so if they chained two together, I'm not recursively resolving anymore levels, I'm just failing it
                    $reason = 'Invalid use of CNAME for MX record';
                    print "DEBUG: Test Failed - $reason\n" if $params{'debug'};
                    return (0, $reason);
                  }
                }
              } else {
                if ($params{'allow_ip_address_as_mx'} > 0 && $answer[$i]->exchange =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
                  ($rv, $reason) = invalid_mx($answer[$i]->exchange);
                  if ($rv) {
                    return (0, $reason);
                  } else {
                    print "DEBUG: Test Passed - Allowing IP Address as Hostname\n" if $params{'debug'};
                    return (1, '');
                  }
                }

                #MX RECORD IS A CNAME WHICH DOES NOT RESOLVE
                $reason = "MX Record: ".$answer2[0]->cname." does not resolve";
                print "DEBUG: Test Failed - $reason\n" if $params{'debug'};
                return (0, $reason);
              }
            }
          } else { # ! $packet->header->ancount > 0

            #IF THIS IS THE LAST MX RECORD AND THE EXCHANGE IS BLANK, WE FAIL IT
            if (_blank_exchange($answer[$i])) {
              if ($i == $#answer) {
                $reason = 'Domain is publishing only invalid and/or blank MX records'; 
                print "DEBUG: Test Failed - $reason\n" if $params{'debug'};
                return (0, $reason);
              }
            } else {
              #PERHAPS WE'LL ALLOW AN IP ADDRESS AS AN MX FOR CLOWNS WHO CONFIGURE DNS INCORRECTLY
              if ($params{'allow_ip_address_as_mx'} > 0 && $answer[$i]->exchange =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
                ($rv, $reason) = invalid_mx($answer[$i]->exchange);
                if ($rv) {
                  return (0, $reason);
                } else {
                  print "DEBUG: Test Passed - Allowing IP Address as Hostname\n" if $params{'debug'};
                  return (1, '');
                }
              }
            }

            # Keep looping, unless this was the last answer in the MX
            # resolution packet.
            # XXX $packet->header->ancount, in the case of corrupt packets,
            # may differ from the actual number of records and may return unwanted failures
            if ($i == $#answer) {

              #MX RECORD RETURNED DOES NOT RESOLVE
              $reason = "MX Record: ".$answer[$i]->exchange." does not resolve";
              print "DEBUG: Test Failed - $reason\n" if $params{'debug'};
              return (0, $reason);
            }
          }

        } # for
      }
    } else {
      ($rv, $reason) = $check_implicit_mx++;
    }

    print "DEBUG: Checking Implicit MX is set to $check_implicit_mx\n" if $params{'debug'};

    if ($check_implicit_mx > 0) {
      ($rv, $reason) = check_implicit_mx($domain, $res, $params{'debug'}, $params{'resolution_problem_return'});
      if (defined $rv) {
        return ($rv, $reason);
      }
    }
  } else {
    print "DEBUG: There was an error setting up a Net::DNS::Resolver resource\n" if $params{'debug'};
    print "DEBUG: Test Passed by Default\n" if $params{'debug'};
    return ($params{'resolution_problem_return'}, 'Test '.$resolution_problem_status.' due to a Resolution Problem');
  }

  print "DEBUG: Test Passed\n" if $params{'debug'};
  return (1,'');
}

# Null MX (RFC 7505), recent Net::DNS versions return '.' instead of ''
sub _blank_exchange {
  my ($rr) = @_;
  my $exchange = $rr->exchange;
  return (!defined $exchange or $exchange eq '' or $exchange eq '.') ? 1 : 0;
}

sub check_implicit_mx {
  my %params = _args(\@_, ['domain', 'resolver', 'debug', 'resolution_problem_return'], ['query_timeout']);
  my ($SenderDomain, $res, $debug, $resolution_problem_return) = @params{'domain', 'resolver', 'debug', 'resolution_problem_return'};

  my ($rv, $reason, $packet, @answer, @answer2, $resolution_problem_status);

  #CONSTANTS/SETTABLE OPTIONS
  $resolution_problem_return ||= $RESOLUTION_PROBLEM_RETURN;
  $res = $RESOLVER unless (defined $res);
  $res = _default_resolver(defined $params{'query_timeout'} ? $params{'query_timeout'} : $QUERY_TIMEOUT) unless (defined $res);
  return ($resolution_problem_return, 'Test '.($resolution_problem_return > 0 ? 'Passed' : 'Failed').' due to a Resolution Problem') unless (defined $res);

  if ($resolution_problem_return > 0) {
    $resolution_problem_status = 'Passed';
  } else {
    $resolution_problem_status = 'Failed';
  }

  print "DEBUG: Checking for Implicit MX Records\n" if $debug;
  #NO MX RECORDS RETURNED - CHECK FOR IMPLICIT MX RECORD BY A RECORD per Jan-Pieter Cornet recommendation
  $packet = $res->send($SenderDomain,'A');
  if (!defined ($packet)) {
    #THERE WAS AN ERROR - NO IMPLICIT A RECORD COULD BE RESOLVED
    print "DEBUG: Test Passed by Default\n" if $debug;
    return ($resolution_problem_return, 'Test '.$resolution_problem_status.' due to a Resolution Problem');
  }

  print "DEBUG: Number of Answers in the Implicit A record resolution packet is: ".$packet->header->ancount."\n" if $debug;
  if ($packet->header->ancount > 0) {
    @answer = $packet->answer;
    if ($answer[0]->type eq "A") {
      print "DEBUG: $SenderDomain has no MX Records - Using Implicit A Record: ".$answer[0]->address."\n" if $debug;
      ($rv, $reason) = invalid_mx($answer[0]->address);
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
            ($rv, $reason) = invalid_mx($answer2[0]->address);
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
  return;
}

sub invalid_mx {
  my %params = _args(\@_, ['ip']);
  my $ip = $params{'ip'};
  my ($flag_intranets);

  #UPDATED MORE ON 11-18-2011 based on RFC 5735

  #0/8, 255/8, 127/8 aren't a valid MX so return false - added per Matthew van Eerde recomendation
  if ($ip =~ /^(255|127|0)\./) {
    return (1, "Invalid use of 0/8, 255/8 or 127/8 ($ip) as an MX record");
  }

  $flag_intranets = $FLAG_INTRANETS;

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

  #fc00::/7
  if ($flag_intranets && $ip =~ /^fc00\:0\:/i) {
    return (2, "Invalid use of unique local address (e.g. $ip) range for MX");
  }

  #fd00::/8
  if ($flag_intranets && $ip =~ /^fd00\:0\:/i) {
    return (2, "Invalid use of private IP (e.g. $ip) range for MX");
  }

  #DHCP auto-discover added per Matthew van Eerde recomendation 169.254/16
  if ($ip =~ /^169\.254\./) {
    return (1, "Invalid use of a DHCP auto-discover IP range ($ip) as an MX record");
  }

  #IPv6 link-local addresses fe80::/10
  if ($ip =~ /^fe80\:0\:/i) {
    return (1, "Invalid use of a link-local IP range ($ip) as an MX record");
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
  my %params = _args(\@_, ['rv']);
  my $int = $params{'rv'};

  if ($int) {
    return "True";
  } else {
    return "False";
  }
}

my @CHECK_VALID_MX_OPTIONS = qw(resolver debug allow_ip_address_as_mx resolution_problem_return query_timeout);

sub check_email_and_mx {
  my %params = _args(\@_, ['email'], \@CHECK_VALID_MX_OPTIONS);
  my $email = $params{'email'};
  my ($rv, $fail_reason, $status, $debug, %mx_options);

  #OPTIONS FORWARDED TO check_valid_mx
  foreach my $option (@CHECK_VALID_MX_OPTIONS) {
    $mx_options{$option} = $params{$option} if (defined $params{$option});
  }

  $debug = 0;

  $email || return 0;
  
  print "DEBUG: e-mail address is: $email<br>\n" if $debug;
  
  # SANITIZE THE E-MAIL ADDRESS OF SPACES
  $email =~ s/ //g;

  # CHECK FOR INCOMPLETE ADDRESSES AT LARGE ISPS
  $email =~ s/\@aol\.?$/\@aol.com/i;
  $email =~ s/\@hotmail\.?$/\@hotmail.com/i;
  $email =~ s/\@gmail\.?$/\@gmail.com/i;

  print "DEBUG: e-mail address is now: $email<br>\n" if $debug;

  # CHECK FOR A VALIDLY CONSTRUCTED E-MAIL ADDRESS
  ($rv) = Net::validMX::check_email_validity($email);
  
  if ($rv < 1) {
    return($rv, "Failed check_email_validity", $email);
  }

  # CHECK FOR VALID MX RECORD
  if (%mx_options) {
    ($rv, $fail_reason) = Net::validMX::check_valid_mx(email => $email, %mx_options);
  } else {
    ($rv, $fail_reason) = Net::validMX::check_valid_mx($email);
  }

  if ($rv < 1) {
    return($rv, $fail_reason, $email);
  }

  return($rv, "Passed", $email);
}

sub check_email_validity {
  my %params = _args(\@_, ['email']);
  my $email = $params{'email'};
  my ($local);

  #allows an email address that contains -()/!#$%&*+~. A through Z a through Z and 0 through 9 in a format of [valid]@([valid].[valid]...).[valid].  = will also be
  #allowed in the username.   Thanks to Paul Whittney for reporting the issue.

  return 0 if not defined $email;

  #PER WIKIPEDIA
  #Per Wikipedia:

  #The format of email addresses is local-part@domain where the local-part may be up to 64 characters long and the domain name may have a maximum of 253 characters - but the maximum 256 characters length of a forward or reverse path restricts the entire email address to be no more than 254 characters.[1] - formally defined in RFC 5322 (sections 3.2.3 and 3.4.1) and by RFC 5321.
 
  #Can't have two dots 
  if ($email =~ /\.\./) {
    return 0;
  }

  #Can't be longer than 254 chars
  if (length($email) > 254) {
    return 0;
  }

  #Can't end in a period
  if ($email =~ /\.$/) {
    return 0;
  }

  if ($email =~ /^(.*)@[-()\/!#$%&*+~_A-Za-z0-9\.]+\.[-()\/!#$%&*+~_A-Za-z0-9\.]+$/) {
 
    $local = $1;
    
    #check local length
    if (length($local) > 64) {
      return 0;
    }
    #no need to check if domain is over 253 chars, as it would not pass both overall length and regex if it was 

    # per RFC 3696 section 3 the local part of an address cannot begin or end with a period
    if ($local =~ /^\./ or $local =~ /\.$/g) {
      return 0;
    }
  
    # PURGE BACKSLASHES
    $local =~ s/\\//g;
  
    # per RFC 3696 section 3 the local part of the email can be quoted, which allows any character to appear if inside quotes
    # PURGE BEGINNING AND END QUOTE IF IT CONTAINS QUOTES
    if ($local =~ /"/) {
      if($local =~ /^".*"$/) {
        $local =~ s/^"//g;
        $local =~ s/"$//g;
      }
  
      # IF IT STILL CONTAINS A QUOTE, IT IS INVALID, OTHERWISE THE LOCAL PART IS VALID
      if ($local =~ /"/) {
        return 0;
      } else {
        return 1;
      }
    }
  
    # check for allowed characters, per RFC 3696 section 3 
    if ($local =~ /^[\@'-`\/!\?=#\$\%&*+~_A-Za-z0-9\.{}|]+$/) {
      return 1;
    } else {
      return 0;
    }

  }
  return 0;

}

#get domain name from an email address
sub get_domain_from_email {
  my %params = _args(\@_, ['email'], ['debug'], 1);
  my $email = $params{'email'};

  my ($domain, $local);

  $domain = $email;

  #REMOVE ANY LEADING/TRAILING <>'s
  $domain =~ s/(^<|>$)//g;
  #REMOVE ANY LEADING/TRAILING SPACE'S
  $domain =~ s/^ *//g;
  $domain =~ s/ *$//g;
  #REMOVE EVERYTHING UP TO THE @ SYMBOL
  $domain =~ s/(.*)\@//g;

  $local = $1;

  print "\nDEBUG: Extracted Sender Domain: $domain / Local: $local from $params{'email'}\n" if $params{'debug'};

  return wantarray ? ($local,$domain) : $domain;
}

sub dns_lookup {
  my %params = _args(\@_, ['domain', 'type']);
  my ($domain, $type) = @params{'domain', 'type'};
  my ($dns, $query);

  $dns = Net::DNS::Resolver->new;
  $query = $dns->search($domain, $type);
  if ($query) {
    return $query->answer;
  } else {
    warn "Error performing $type query for $domain! ". $dns->errorstring;
  }
}

sub check_spf_for_domain {
  my %params = _args(\@_, ['domain'], [], 1);
  my $domain = $params{'domain'};
  my ($dns, $query, $spf_line, @clauses, $found_spf);

  $dns = Net::DNS::Resolver->new;
  $query = $dns->search($domain, 'TXT');
  if (not $query) {
    warn "Error performing TXT query for $domain! ". $dns->errorstring;
    return ("suspect", "no TXT record found");
  }

  foreach my $result ($query->answer) {
    next unless $result->type eq 'TXT';
    $spf_line = $result->txtdata;

    if ($spf_line =~ /^v=spf[12]/i) {
      $found_spf++;

      # split into clauses
      @clauses = split / /, $spf_line;

      foreach my $clause (@clauses) {
        # ignore clauses that reject email - only false accepts are good spam indicators
        next if $clause =~ /^[-~]/;
        if ($clause =~ /^.?all/) {
          # if accepting email from all, rule is clearly useless
          return ("bad", "use of universal pass rule $clause");
        }
      }
    }
  }

  if ($found_spf == 0) {
    return ("suspect", "no TXT record matching SPF format found");
  } elsif ($found_spf > 1) {
    return ("suspect", "multiple TXT records matching SPF format found");
  }

  return ("valid", undef);
}

1;

__END__

=head1 NAME

Net::validMX - PERL Module to use DNS and/or regular expressions to verify if an email 
address could be valid.

=head1 SYNOPSIS

Net::validMX - I wanted the ability to use DNS to verify if an email address
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

	use Net::validMX;

All the functions accept their arguments either as a positional list, as
shown in each section, or as named C<key =E<gt> value> pairs, for example:

	($rv, $reason, $sanitized_email) = Net::validMX::check_email_and_mx(email => 'kevin.mcgrail@peregrinehw.com');
	print Net::validMX::get_output_result(email => $sanitized_email, rv => $rv, reason => $reason);

The named form is used when the first argument is one of the key names
of the function and the number of arguments is even; the positional form
is kept for backward compatibility.

=head2 check_valid_mx

To check if an email address could be valid by checking the DNS, call
the function check_valid_mx with a single email address as the only argument:

	($rv, $reason) = Net::validMX::check_valid_mx('kevin.mcgrail@peregrinehw.com');

check_valid_mx will return a true/false integer as the first value and a descriptive text message as warranted.

NOTE: In the event of a DNS resolution problem, we do NOT return a failure.  We return a success to prevent DNS outages and delays from producing too many false positives.

By default a new Net::DNS::Resolver is created for every call.  To reuse a
resolver (for example one that caches answers) pass it with the C<resolver>
parameter, set it once in C<$Net::validMX::RESOLVER>, or pass it to C<new>
when using the OO interface:

	($rv, $reason) = Net::validMX::check_valid_mx(email => 'kevin.mcgrail@peregrinehw.com', resolver => $res);

	$Net::validMX::RESOLVER = $res;

	my $validmx = Net::validMX->new(resolver => $res);
	($rv, $reason) = $validmx->check_valid_mx(email => 'kevin.mcgrail@peregrinehw.com');

The object only needs a C<send($name, $type)> method returning a
Net::DNS::Packet (or undef on errors).  It is used as is: C<query_timeout>
is not applied to it and it should not append a default domain or a
search list to the names it looks up.


=head2 check_email_validity

To check if an email address is formatted correctly, call the function
check_email_validity with a single email address as the only argument:

	$rv = Net::validMX::check_email_validity('kevin.mcgrail@peregrinehw.com');
	$rv = Net::validMX::check_email_validity(email => 'kevin.mcgrail@peregrinehw.com');

check_email_validity will return a true/false integer where E<gt> 0 indicates that the email address looks valid.


=head2 check_email_and_mx

To check if an email address is formatted correctly, sanitize the email address some common end-user errors(*) and run check_valid_mx all from a single function, 
use the function check_email_and_mx with a single email address as the only argument:

	($rv, $reason, $sanitized_email) = Net::validMX::check_email_and_mx('kevin.mcgrail@peregrinehw.com');

check_email_and_mx will return a true/false integer where E<gt> 0 indicates that the email address looks valid, a descriptive text message
as warranted, and a sanitized version of the email address argument.

With the named form the options of check_valid_mx (C<resolver>, C<debug>,
C<allow_ip_address_as_mx>, C<resolution_problem_return> and C<query_timeout>)
can be passed too, and they are forwarded to check_valid_mx:

	($rv, $reason, $sanitized_email) = Net::validMX::check_email_and_mx(email => 'kevin.mcgrail@peregrinehw.com', resolver => $res);

(*) Common end-user errors that are fixed: 

=over 4

=item All spaces are stripped.  Many users seem to enter things like Bob and Carol @ a big isp.com.

=item Emails ending in @aol. or @aol are fixed to be @aol.com.  Also done for hotmail.com, live.com & gmail.com.  

=back

=cut

=head2 get_domain_from_email

Sub to extract the domain part and local part from an email address.

=over 4

To extract the domain part and local part from an email address, use the function 
get_domain_from_email with a single email address as the only argument:

	$domain = Net::validMX::get_domain_from_email('kevin.mcgrail@peregrinehw.com');

get_domain_from_email will return a string with the domain part of the email address argument.

Optionally, you can also receive the local part as well:

	($local, $domain) = Net::validMX::get_domain_from_email('kevin.mcgrail@peregrinehw.com');

or with named arguments:

	$domain = Net::validMX::get_domain_from_email(email => 'kevin.mcgrail@peregrinehw.com', debug => 1);

=back

=cut

=head2 check_spf_for_domain

Sub to check spf record of a domain.

=over 4

To check if a domain is properly configured to send email, call the function check_spf_for_domain with a domain name as the only argument:

	($rv, $reason) = Net::validMX::check_spf_for_domain('peregrinehw.com');
	($rv, $reason) = Net::validMX::check_spf_for_domain(domain => 'peregrinehw.com');

check_spf_for_domain will return "valid", "suspect", or "bad" as the first value and a descriptive text message as warranted.

=back

=cut

=head2 get_output_result

Sub that returns a formatted string with the reason why an email address is not valid.

To print the reason why an email address is not valid, call the function get_output_result with email address, return code and reason as arguments.

	print Net::validMX::get_output_result($sanitized_email, $rv, $reason);

Note that the positional order (email, return code, reason) is not the
order in which check_email_and_mx returns the same values (return code,
reason, email); it is kept for backward compatibility.  The named form
avoids any confusion:

	print Net::validMX::get_output_result(email => $sanitized_email, rv => $rv, reason => $reason);

=cut

=head2 check_implicit_mx

Sub that checks the implicit MX (the A record) of a domain that has no MX records:

	($rv, $reason) = Net::validMX::check_implicit_mx($domain, $res, $debug, $resolution_problem_return);
	($rv, $reason) = Net::validMX::check_implicit_mx(domain => $domain, resolver => $res);

When no resolver is given, C<$Net::validMX::RESOLVER> or a new Net::DNS::Resolver is used.

=cut

=head2 invalid_mx

Sub that checks if an IP address can not be used as a mail exchanger:

	($rv, $reason) = Net::validMX::invalid_mx('10.0.0.1');
	($rv, $reason) = Net::validMX::invalid_mx(ip => '10.0.0.1');

invalid_mx returns 0 for a usable address, otherwise a value E<gt> 0 and the reason.

=cut

=head2 dns_lookup

Sub that returns the answer records of a DNS query:

	@answer = Net::validMX::dns_lookup('peregrinehw.com', 'MX');
	@answer = Net::validMX::dns_lookup(domain => 'peregrinehw.com', type => 'MX');

=cut

=head2 int_to_truefalse

Sub that returns "True" or "False" for a return code:

	$text = Net::validMX::int_to_truefalse($rv);
	$text = Net::validMX::int_to_truefalse(rv => $rv);

=cut

=head2 set_debug, get_debug, version

	Net::validMX::set_debug(1);
	Net::validMX::set_debug(debug => 1);
	$debug = Net::validMX::get_debug();
	$version = Net::validMX::version();

=cut

=head2 EXAMPLE

=over 4

The distribution contains an example program to demonstrate working functionality as well to utilize as a command line interface
to query one or more email addresses.

Run the program with the space-seperated email addresses to test as your arguments:

	perl example/check_email_and_mx.pl kevin.mcgrail@peregrinehw.com 
or
	perl example/check_email_and_mx.pl kevin.mcgrail@peregrinehw.com google@google.com president@whitehouse.gov

If you supply only one email address argument, the program will exit with a exit status of 0 for a success and 1 for a failure:

	perl example/check_email_and_mx.pl kevin.mcgrail@failed || echo 'This email is no good'     

=back

=cut

=head2 MIMEDEFANG

We are using this routine with MIMEDefang and have been since late 2005 via the filter_sender hooks.  For example, make a function that excludes authorized senders for your particular setup and add the following code snippets to your mimedefang-filter:

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


=head1 SEE ALSO

L<Net::DNS>, L<Email::Valid>, L<Mail::CheckUser>, L<Mail::SPF>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 The McGrail Foundation and Kevin A. McGrail.  All rights reserved.

This distribution, including all of the files in the Net::validMX package, is free software; you can redistribute it and/or modify it under the Perl Artistic License v1.0 available at http://www.perlfoundation.org/legal/licenses/artistic-1_0.html

L<perlartistic>

=head1 AUTHOR INFORMATION

Kevin A. McGrail
kevin.mcgrail-netvalidmx@mcgrail.com

=head1 UPDATE HISTORY

=over 4

=item v1.0  Released Oct 11, 2005.  Original release for MIMEDefang filter.

=item v2.0  Released Nov 3, 2005.  Incorporated many user updates.

=item v2.1  Released May 23, 2006.  Switched to a perl Library (Net::validMX).  Small efficiency change to short-circuit the DNS resolution of an IP address.

=item v2.2  Released May 31, 2006.  Clarified the LICENSE by pointing readers to the README.  Added functions check_email_and_mx & check_email_validity.  Expanded documentation and added check_email_and_mx & check_email_validity calls to example.  Cleaned up distribution production.  Changed logic to check MX records that resolve to IPs to see if it is privatized first.

=item v2.3 & 2.4  Unreleased.  Clarified the license in the Makefile.PL as artistic rather than perl.  Continued documentation cleanup.  Submitted for namespace registration with CPAN.  Added = to chars for a username in the check_email_validity function.  Add test case for Test for DNS where MX1 is private, MX2 is private but MX3 is a valid internet address for a pass.  Began adding overloaded parameters to check_valid_mx to add flexibility to override default settings. Added AAAA records as valid for IPv6 support. Rewrote all tests to rely on test points inside a domain we control so that testing passes in the future.

=item v2.5  Released May 8, 2020.  Numerous bug fixes and moved to The McGrail Foundation.  This product is in active use in production system.

=item v2.5.1 Released April 4, 2023. Documentation bug fixes and ipv6 improvements.

=item v2.5.2 Released September 25, 2023. check_email_validity fixes.

=item v2.6.0 Released November 18, 2026. check_valid_mx can use a resolver passed by the caller.  Null MX records are detected with recent Net::DNS versions, which return '.' as their exchange.

=item v2.6.1 Released November 18, 2026.  All the functions accept named arguments as well as positional ones.  check_email_and_mx forwards the check_valid_mx options.  Documentation fixes and a SEE ALSO section.

=back

=head1 HOMEPAGE

Releases can be found at http://www.mcgrail.com/downloads/Net-validMX and
on CPAN at http://search.cpan.org/~kmcgrail/.

=head1 CAVEATS

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

=head1 CREDITS

=over 4

=encoding utf-8

Based on an idea from Les Miksell and much input from Jan Pieter Cornet.  Additional thanks to David F. Skoll, Matthew van Eerde, and Mark Damrose for testing and suggestions, plus Bill Cole & Karsten Bräckelmann for code contributions.  And sincere apologies in advance if I missed anyone!

=back

=head1 REPOSITORY

L<https://github.com/The-McGrail-Foundation/Net-validMX>

=cut
