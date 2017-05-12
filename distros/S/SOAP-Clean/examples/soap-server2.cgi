#! /usr/bin/env perl

# This file is placed in the public domain.

use lib '..';

use SOAP::Clean::Server;
use SOAP::Clean::CGI;

new SOAP::Clean::CGI
#  ->enc_dec_params(1,"private2.pem","public.pem","enc.tmpl","xmlsec")
#  ->dsig_keys(0,"CAcert.pem","xmlsec")
  ->urn('cgifile:./soap-server.cgi')
  ->name('soap_server')
  ->full_name('SOAP::Clean Test Server')
  ->params(
	   default(in(val('sleep_for','int')),5),
	   in(file('w','xml')),
	   in(file('x','raw')),
	   in(val('y','string')),
	   out(file('result','int')),
	   out(file('out1','raw')),
	   out(file('out2','xml')),
	  )
  ->command(\&make_command)
#  ->in_order(qw(sleep_for w x y))
#  ->out_order(qw(result out1 out2))
  ->go();

sub make_command {
  my (%r) = @_;

  return
    "./soap-server.sh -x$r{x} -y$r{y} -s$r{sleep_for}"
      ."    $r{w} $r{out1} $r{out2} > $r{result}";
}
