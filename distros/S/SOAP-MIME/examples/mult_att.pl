#!/usr/bin/perl

my $NS = 'urn:SOAP_MIME_Test';

use SOAP::Lite;# +trace => qw(debug);
use SOAP::MIME;
use MIME::Entity;

my $ent1 = build MIME::Entity
  'Id'          => "<abcd>",
  'Type'        => "text/xml",
  'Path'        => "attachments/some1.xml",
  'Filename'    => "some1.xml",
  'Disposition' => "attachment";

my $ent2 = build MIME::Entity
  'Id'          => "<1234>",
  'Type'        => "text/xml",
  'Path'        => "attachments/some2.xml",
  'Filename'    => "some2.xml",
  'Disposition' => "attachment";

push @attachments, $ent1;
push @attachments, $ent2;

my $som = SOAP::Lite
  ->readable(1)
  ->uri($NS)
  ->on_action( sub { return "$NS#echo"; } )
  ->parts(@attachments)
  ->proxy('http://localhost/cgi-bin/attachments.cgi')
  ->echo( SOAP::Data->name('whatToEcho' => 'foo bar baz') );

die "An error occured: ".$som->faultstring."\n" if $som->fault;

print "This is what was echoed: ".$som->valueof("//echoResponse/whatToEcho")."\n";

if ($som->parts) {
  print "Attachments found! Here they are:\n";
  foreach $part (@{$som->parts}) {
    print $$part->stringify;
  }
}
