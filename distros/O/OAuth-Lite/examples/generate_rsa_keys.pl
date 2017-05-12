#!/usr/bin/perl

use strict;
use warnings;

use Crypt::OpenSSL::RSA;
use Perl6::Say;

my $rsa = Crypt::OpenSSL::RSA->generate_key(1024);

say $rsa->get_public_key_string();

say $rsa->get_private_key_string();

