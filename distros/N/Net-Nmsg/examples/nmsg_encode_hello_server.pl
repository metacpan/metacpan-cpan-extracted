#!/usr/bin/perl

use strict;
use warnings;

# Note: If your output includes the message "<UNABLE TO DECODE>"
# make sure you install the correct perl modules. For example:
#     perl -MCPAN -e "install JSON"

use Net::Nmsg::Input;
use Data::Dumper;

{
  package Encode;

  sub new {
    my $class = shift;
    my($enc, $dec) = @_ ? @_ : (sub { $_[0] }, sub { $_[0] });
    bless { _encode => $enc, _decode => $dec }, $class;
  }

  sub encode { my $self = shift; $self->{_encode}->(@_) }

  sub decode { my $self = shift; $self->{_decode}->(@_) }

}

my %Encoders;

$Encoders{TEXT} = Encode->new;

eval "use JSON qw()";
$Encoders{JSON} = $@ ? 0 :
  Encode->new(\&JSON::encode_json, \&JSON::decode_json);

eval "use YAML qw()";
$Encoders{YAML} = $@ ? 0 : 
  Encode->new(\&YAML::Dump, \&YAML::Load); 
eval "use Data::MessagePack";
$Encoders{MSGPACK} = $@ ? 0 :
  Encode->new(
    sub { Data::MessagePack->pack(@_) },
    sub { Data::MessagePack->unpack(@_) },
  );

eval "use XML::Dumper";
if ($@) {
  $Encoders{XML} = 0;
}
else {
  my $xdump = XML::Dumper->new;
  $Encoders{XML} = Encode->new(
    sub { $xdump->pl2xml(@_) },
    sub { $xdump->xml2pl(@_) },
  );
}
 
sub process {
  my $m = shift;
  print STDERR $m->headers_as_str, "\n";
  my $type = $m->get_type;
  my $enc  = $Encoders{$type};
  print STDERR "type: ", $m->get_type, "\n";
  if ($enc) {
    print STDERR "payload: ", Dumper($enc->decode($m->get_payload));
  }
  elsif (defined $enc) {
    print STDERR "payload: <UNABLE TO DECODE>\n";
  }
  else {
    print STDERR "payload: <UNKNOWN ENCODING>\n";
  }
  print STDERR "\n\n";
}

if (@ARGV == 0) {
  @ARGV = ('127.0.0.1', 9430);
}
if (@ARGV != 2) {
  print STDERR "Usage: $0 [<ADDR> <PORT>]\n";
  exit 1;
}

# Note: IPv6 will work for the address if you have IO::Socket::INET6
my $i = Net::Nmsg::Input->open_sock(@ARGV);
print STDERR "listening on $ARGV[0]/$ARGV[1]\n";

while (1) {
  process($i->read() || next);
}
