#!/usr/bin/perl -w
#Author Jan Hulala 
#Based on amf_packet_dumper.pl

use strict;
use warnings;
use Storable::AMF;
use Data::Dumper;

sub deparse {
  my ($buf, $class, $data) = (shift, {}, {});
  my ($enc, $size, $mar, $len);
  ($size, $@) = (length $buf, '');
  $class->{headers} = $class->{bodies} = [];
  $class->{encoding} = $enc = 3 * (unpack('n', (substr $buf, 0, 2, '')) == 3);
  for (1..unpack('n', substr $buf, 0, 2, '')) {
    $data->{name} = substr($buf, 0, unpack('n', substr $buf, 0, 2, ''), '');
    $data->{required} = ord(substr($buf, 0, 1, ''));
    substr $buf, 0, 4, '';
    $mar = (ord $buf == 0x11) ? ord(substr $buf, 0, 1, '') : $enc;
    ($data->{data}, $len) = ($mar > 0) ? Storable::AMF3::deparse_amf($buf) : Storable::AMF0::deparse_amf($buf);
    $@ ? return : substr $buf, 0, $len, '';
    push @{ $class->{headers} }, $data and $data = {};
  }
  for (1..unpack('n', substr $buf, 0, 2, '')) {
    $data->{target} = substr($buf, 0, unpack('n', substr $buf, 0, 2, ''), '');
    $data->{response} = substr($buf, 0, unpack('n', substr $buf, 0, 2, ''), '');
    substr $buf, 0, 4, '';
    substr $buf, 0, 1, '' if (($mar = ord $buf) == 0x0A && $enc == 3) || ($enc != 3 && $mar == 0x11);
    for (1..(($mar == 0x0A) ? unpack("N", substr $buf, 0, 4, '') : 1)) {
      substr $buf, 0, 1, '' if $mar == 0x0A;
      ($data->{data}, $len) = (($mar == 0x0A) || ($enc != 3 && $mar == 0x11) || ($enc == 3)) ?
        Storable::AMF3::deparse_amf($buf) : Storable::AMF0::deparse_amf($buf);
      $@ ? return : substr $buf, 0, $len, '';
    }
    push @{ $class->{bodies} }, $data and $data = {};
  }
  return ($class, $size - length $buf);
}

sub _die{ print "Failed: $!\n" and exit 1 }

my ($buf, $obj, $len);
($#ARGV < 2) && ($#ARGV >= 0) ? (open AMF, $ARGV[0] or _die) : (print "Usage: amf2human binFile [--ascii | --nodump]\n" and exit);
binmode AMF and read(AMF, $buf, 32768) and close AMF or _die;
$buf =~ s/(.)/{ ($1 =~ m#([\!-\~])#i) && ($#ARGV == 1) && ($ARGV[1] eq '--ascii') ?
  print "$1" : printf(" %02X ", ord($1)); $1 }/ges and print "\n\n" if ($#ARGV == 0) || ($ARGV[1] ne '--nodump');
while (length $buf) {
  ($obj, $len) = deparse($buf);
  (!ref($obj) || $@) ? $buf =~ s/(.)/{ printf("Skipped: 0x%02X\n", ord($1)); $@ ? '' : $1 }/es : print Dumper($obj);
  substr $buf, 0, $len, '' if !$@;
}
