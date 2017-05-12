#!/usr/bin/perl

use strict;
use utf8;

binmode STDOUT, ":utf8";

use Net::IDN::Encode;

my @email = (
  'postmaster@例．テスト',
  'info＠müller.example.net',
);

foreach (@email) {
  printf "%s: toASCII=<%s>, toUnicode=<%s>\n",
	$_, email_to_ascii($_), email_to_unicode($_);
}
