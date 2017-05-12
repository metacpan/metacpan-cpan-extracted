#!/usr/bin/perl
#
# SOAP::MIME test service
#
# Author: Byrne Reese <byrne at majordojo dot com>
#

use SOAP::Transport::HTTP;
use SOAP::MIME;

SOAP::Transport::HTTP::CGI
  ->dispatch_to('SOAP_MIME_Test')
  ->handle();

BEGIN {

  package SOAP_MIME_Test;
  use strict;
  use vars qw(@ISA);
  @ISA = qw(SOAP::Server::Parameters);

  sub echo {
    my $self = shift;
    my $envelope = pop;
    foreach my $part (@{$envelope->parts}) {
      print STDERR "Attachments.cgi: attachment found! (".ref($$part).")\n";
    }
    print STDERR "envelope is of type: " . ref($envelope) . "\n";
    my $STRING = $envelope->dataof("//echo/whatToEcho")
      or die SOAP::Fault->faultcode("Client")
        ->faultstring("You must specify a string to echo")
          ->faultactor('urn:SOAP_MIME_Test#echo');

    my $ent = build MIME::Entity
	'Id'          => "<1234>",
	'Type'        => "text/xml",
	'Path'        => "examples/attachments/some2.xml",
	'Filename'    => "some2.xml",
	'Disposition' => "attachment";
    return SOAP::Data->name("whatToEcho" => $STRING),$ent;
  }

}
__END__

=head1 NAME

SOAP::MIME Test Service

=head1 SYNOPSIS

This service tests SOAP::MIME's ability to parse attachments.
