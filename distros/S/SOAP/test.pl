##! perl -d
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::Parser::Expat;
use SOAP::EnvelopeMaker;
use SOAP::Transport::HTTP::CGI;
use SOAP::Parser;
use SOAP::Struct;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#
# test 2 - try to make a SOAP request to soapl.develop.com
#        
#
sub test2() {
    my $soap_perl_server           = 'soapl.develop.com';
    my $test_endpoint_for_mod_perl = '/soap?class=SPTest';
    my $test_endpoint_for_cgi      = '/cgi-bin/soap.pl?class=SPTest';

    print qq[

This test sends a live SOAP call to $soap_perl_server, adding two numbers.
If you're not connected to the Internet, please skip this step.

];
    my $skip_test = ExtUtils::MakeMaker::prompt('Do you want me to skip this test?', 'no');
    return 1 if $skip_test =~ /^\s*y/i;

    print "Testing your connection by pinging $soap_perl_server...\n";

    #
    # first verify that we're connected to the internet
    #
    eval { use Net::Ping; };
    if ($@) {
        print "\n\nCouldn't load the Net::Ping module to test your connection.\n";
        my $skip_test = ExtUtils::MakeMaker::prompt('Do you want me to skip this test?', 'yes');
        return 1 if $skip_test =~ /^\s*y/i;
        print "\nOk, we'll barge on anyway :-)\n";
    }
    else {
        my $icmp = Net::Ping->new('icmp', 5);
        unless ($icmp->ping($soap_perl_server)) {
            print "\n\nCouldn't ping $soap_perl_server, so I'll skip this test.\n";
            return 1;
        }
    }

    print "\nOk, I can ping $soap_perl_server.\n";

    print "\nMaking a SOAP call to $soap_perl_server: add()...\n";

    eval {
#        print "\n\nCalling the CGI version of the server 5 times:\n";
#        for (my $i = 0; $i < 5; ++$i) {
#            make_call($soap_perl_server, 80, $test_endpoint_for_cgi);
#        }
        print "\n\nCalling the mod_perl version of the server 5 times:\n";
        for ($i = 0; $i < 5; ++$i) {
            make_call($soap_perl_server, 80, $test_endpoint_for_mod_perl);
        }
    };
    if ($@) {
        print $@;
        return;
    }
    print "Success!\n";

    1;
}

sub make_call {
  use SOAP::EnvelopeMaker;

  my ($host, $port, $endpoint) = @_;
  my $method_uri  = "urn:soap-perl-test";
  my $method_name = "add";

  my $soap_request = '';
  my $em = SOAP::EnvelopeMaker->new(\$soap_request);

  my $a = 3;
  my $b = 4;
  my $expected_result = $a + $b;

  my $request_body = SOAP::Struct->new(a => $a, b => $b);

  $em->set_body($method_uri, $method_name, 0, $request_body);

  use SOAP::Transport::HTTP::Client;

  my $soap_on_http = SOAP::Transport::HTTP::Client->new();

  my $soap_response = $soap_on_http->send_receive($host, $port, $endpoint,
                                                $method_uri,
                                                $method_name,
                                                $soap_request);

  use SOAP::Parser;
  my $soap_parser = SOAP::Parser->new();
  $soap_parser->parsestring($soap_response);

  $response_body = $soap_parser->get_body();

  if (exists $response_body->{return}) {
    my $c = $response_body->{return};
    unless ($c == $expected_result) { die "Hmm. My math must be getting bad. I expected to get $expected_result, and instead, got $c" }
    print "$a + $b = $c\n";
  }
  else {
    my $faultcode   = $response_body->{faultcode};
    my $faultstring = $response_body->{faultstring};
    my $detail      = $response_body->{detail};
    
    die <<"END_MSG";
Whoops, something bad happened:
  faultcode   = $faultcode
  faultstring = $faultstring
  detail      = $detail
END_MSG
  }
}

use ExtUtils::MakeMaker qw(prompt);

unless (test2()) { print 'not ' }
print "ok test 2\n";


