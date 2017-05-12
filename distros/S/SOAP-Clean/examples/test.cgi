#! /usr/bin/env perl

# This file is placed in the public domain.

use SOAP::Clean::CGI;

new SOAP::Clean::CGI
  ->urn('urn:test')
  ->name('arithmetic-test')
  ->full_name('SOAP::Clean Test Arithmetic')
  ->descr("./test.sh -x[in x:int] -y[in y:int] > [out file result:int]")
  ->in_order(qw(x y))
  ->go();

