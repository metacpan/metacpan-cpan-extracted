#!/usr/bin/env perl
# $File: //member/autrijus/RTx-Workflow/Makefile.PL $ $Author: autrijus $
# $Revision: #2 $ $Change: 7971 $ $DateTime: 2003/09/08 00:46:40 $

use 5.006;
use inc::Module::Install;

RTx('MD5Auth');
license('gpl');
author('Autrijus Tang <autrijus@autrijus.org>');

&WriteAll( sign => 1 );
