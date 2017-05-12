use strict;

my $perl = `which perl`;

chomp $perl;

open IN, $perl || die "$0: $!\n";

my $buf;
my $template = 'n*';

while ( sysread IN, $buf, 603 )
{
  my $out = unpack $template, $buf;
  syswrite STDOUT, $buf;
  syswrite STDERR,  $out;
}
