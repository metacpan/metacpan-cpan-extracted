#!/usr/bin/perl -w
# $Id: 00signature.t 37 2008-03-09 01:10:00Z maletin $
# $URL: http://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/t/00signature.t $

use strict;
use Test::More;
eval 'use Test::Signature';
plan( skip_all => 'Test::Signature required for signature verification' )
    if $@;
plan( tests => 1 );
signature_ok();
