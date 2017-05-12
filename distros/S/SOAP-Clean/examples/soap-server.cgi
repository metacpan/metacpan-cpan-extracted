#! /usr/bin/env perl

# This file is placed in the public domain.

use lib '..';

use SOAP::Clean::CGI;

new SOAP::Clean::CGI
#  ->enc_dec_params(1,"private2.pem","public.pem","enc.tmpl","xmlsec")
#  ->dsig_keys(0,"CAcert.pem","xmlsec")
  ->urn('cgifile:./soap-server.cgi')
  ->name('soap_server')
  ->full_name('SOAP::Clean Test Server')
  ->descr("./soap-server.sh -x[in file x:raw] -y[in y:string] -s[in sleep_for:int=5]"
	  ."    [in file w:xml]"
	  ."    [out file out1:raw] [out file out2:xml] > [out file result:int]")
  ->in_order(qw(sleep_for w x y))
  ->out_order(qw(result out1 out2))
  ->go();

