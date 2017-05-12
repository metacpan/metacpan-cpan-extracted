#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

my %data;

while (<>) {
	chomp;
	s/#.*$//;
	s/^\s+//; s/\s+$//;
	next if /^$/;

	die "format error: $_" unless
		(my ($a, $b) = /^([\w\d\.-]+)\s+([\w\d\.:-]+|[A-Z]+\s+.*)$/);

  my $data = [ ];

  push @$data, 'NONE' if $b eq 'NONE';
  push @$data, 'whois.publicinterestregistry.net' if $b eq 'PIR';
  push @$data, 'whois.afilias-grs.info' if $b eq 'AFILIAS';
 
  if ( $b =~ /^W(?:EB)?/ ) {
    $b =~ s/^W(?:EB)?\s+//;
    push @$data, 'WEB', $b;
  }

	$b =~ s/^VERISIGN\s+//;

  push @$data, $b unless scalar @$data;

  $data{ $a } = $data;
}

print Dumper( \%data );
