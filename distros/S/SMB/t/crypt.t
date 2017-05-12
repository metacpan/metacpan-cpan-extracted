#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use lib '../lib', 'lib';

use bytes;

use_ok('SMB::Crypt', qw(des_crypt56 md4 md5 hmac_md5));

sub hexvec ($) { join('.', map { sprintf "%02X", ord($_) } split '', $_[0]) }

is(hexvec(des_crypt56("12345678", "abcdefg")), '12.7C.57.81.AA.AF.7B.54', "des_crypt56");
is(hexvec(md4("my text")), '0A.2B.10.16.D5.E5.C0.F8.C3.FD.19.8B.22.12.1F.68', "md4");
is(hexvec(md5("my text")), 'D3.B9.6C.E8.C9.FB.4E.9B.D0.19.8D.03.BA.68.52.C7', "md5");
is(hexvec(hmac_md5("my text", "key")), '6A.46.52.FD.CF.BF.E2.0A.2A.1E.D2.04.1E.18.D6.32', "hmac_md5");

