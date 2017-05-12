#!/usr/bin/perl
#
# Example to compose a SOAP message with attachments.
#
# Author: Byrne Reese <byrne@majordojo.com>
#

use SOAP::Lite trace => 'debug';
use SOAP::MIME;
use MIME::Entity;

my $ent = build MIME::Entity
  Type        => "image/gif",
  Encoding    => "base64",
  Path        => "somefile.gif",
  Filename    => "saveme.gif",
  Disposition => "attachment";

my $som = SOAP::Lite
  ->readable(1)
  ->uri($SOME_NAMESPACE)
  ->parts([ $ent ])
  ->proxy($SOME_HOST)
  ->some_method(SOAP::Data->name("foo" => "bar"));

1;
