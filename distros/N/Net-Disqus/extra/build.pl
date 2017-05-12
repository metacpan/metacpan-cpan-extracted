#!/usr/bin/perl
use strict;
use IO::File;
use JSON::XS;
use Data::Dumper;

my $interfaces;
my $fh = IO::File->new('./interfaces.json');
{ 
    local $/;
    $interfaces = <$fh>;
}
$fh->close();

my $json = decode_json($interfaces);

$Data::Dumper::Indent = 0;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

$fh = IO::File->new('./Interfaces.pm-template');
my $out = IO::File->new('>../lib/Net/Disqus/Interfaces.pm');
while(<$fh>) {
    $out->print($_);
}
$fh->close();
$out->print('sub INTERFACES { return ', Dumper($json), "; }\n\n1;\n");
$out->close();
