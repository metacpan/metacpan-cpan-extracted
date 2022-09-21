#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use RF::Antenna::Planet::MSI::Format;

binmode(STDOUT, ":utf8");

my $filename   = shift or die("Syntax: $0 filename\n");
my $antenna    = RF::Antenna::Planet::MSI::Format->new->read($filename);
my $header     = $antenna->header;     #isa tied HASH {$=>$, $=>$, ...}
my $horizontal = $antenna->horizontal; #isa ARRAY [[], [], ...]
my $vertical   = $antenna->vertical;   #isa ARRAY [[], [], ...]

printf "Header Count: %s\n", scalar(keys %$header);
foreach my $key (keys %$header) {
  my $value = $header->{$key};
  printf "  Key: %s, Value: %s\n", $key, $value;
}

printf "Horizontal Count: %s\n", scalar(@$horizontal);
foreach my $row (@$horizontal) {
  printf "  Angle: %s°, Loss: %s dB\n", $row->[0]+0, $row->[1]+0;
}

printf "Vertical Count: %s\n", scalar(@$vertical);
foreach my $row (@$vertical) {
  printf "  Angle: %s°, Loss: %s dB\n", $row->[0]+0, $row->[1]+0;
}

__END__

=head1 NAME

perl-RF-Antenna-Planet-MSI-Format-printer.pl - Example Script to Print Contents of Antenna Pattern File

=cut
