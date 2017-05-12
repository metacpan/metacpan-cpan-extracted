#!/usr/bin/perl
#
# RTSP::Lite sample code
# 

use RTSP::Lite;

$url = "rtsp://192.168.0.1/realqt.mov";

$rtsp = new RTSP::Lite;
$rtsp->debug(1);


## open the connection

$req = $rtsp->open("192.168.0.1",554) or die "Unable to open: $!";


## SETUP

$rtsp->method("SETUP");

$rtsp->add_req_header("Transport","RTP/AVP;unicast;client_port=6970-6971");

$req =  $rtsp->request($url."/streamid=0");

my $se = $rtsp->get_header("Session");
$session = @$se[0];

print $rtsp->status_message();
print_headers();

## Play

$rtsp->reset();

$rtsp->method("PLAY");
$rtsp->add_req_header("Session","$session");
$rtsp->add_req_header("Range","npt=0.000000-5.200000");

$req = $rtsp->request($url);

print $rtsp->status_message();
print_headers();

## You will get RTP/RTCP packets, you need to have codes for them.

exit;

sub print_headers  {
  my @headers = $rtsp->headers_array();

  my $body = $rtsp->body();

  foreach $header (@headers)
  {
    print "$header\n";
  }
}



