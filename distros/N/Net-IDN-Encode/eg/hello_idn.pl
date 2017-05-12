#!/usr/bin/perl

use strict;
use utf8;

binmode STDOUT, ":utf8";

use Net::IDN::Encode;

my @domain = (
  '例．テスト',
  'müller.example.net',
);

foreach (@domain) {
  printf "%s: toASCII=<%s>, toUnicode=<%s>\n",
	$_, domain_to_ascii($_), domain_to_unicode($_);
}
