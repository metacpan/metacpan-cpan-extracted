#!/usr/bin/perl


use lib 'lib';

use Nmap::Scanner;

# $Nmap::Scanner::DEBUG = 1;

die "Missing nmap option string (.e.g -sS -P0 -F)"
    unless @ARGV;
print Nmap::Scanner->new()->scan(join(' ', @ARGV))->as_xml();
