#!/usr/bin/perl -sw
##
## Makefile.PL for Net::XWhois.
##
## $Date: 2001/07/14 03:18:56 $
## $Revision: 1.2 $
## $State: Exp $
## $Author: vipul $
##
## Copyright (c) 1998, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use ExtUtils::MakeMaker;

WriteMakefile(

    'VERSION_FROM' => 'lib/Net/XWhois.pm',
    'NAME'         => 'Net::XWhois', 
     
);                                                     

