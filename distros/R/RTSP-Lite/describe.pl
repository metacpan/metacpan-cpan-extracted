#!/usr/bin/perl
#
# RTSP::Lite sample code
# 

use RTSP::Lite;

$rtsp = new RTSP::Lite;
$rtsp->open("192.168.0.1",554) or die "Unable to open: $!";

$rtsp->method("DESCRIBE");
$rtsp->request("rtsp://192.168.0.1/realqt.mov");

$status_code = $rtsp->status();
$status_message = $rtsp->status_message();
print "$status_code $status_message\n";
print $rtsp->body();
