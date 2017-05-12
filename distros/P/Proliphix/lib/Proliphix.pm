package Proliphix;
use strict;
use Moose;
use LWP::UserAgent;

our $VERSION = '0.01';

my $mk_base = sub { my $self = shift; $self->{base_url}='http://'.$self->ip.':'.$self->{port}; };
has 'ip'    => (is => 'rw', isa=>'Str', trigger=>$mk_base );
has 'port'  => (is => 'rw', isa=>'Int', default=>80, trigger=>$mk_base );
has 'base_url' => (is => 'ro', isa=>'Str' );
has 'password' => (is=>'rw', isa=>'Str');
has 'ua'    => (is => 'rw', isa=>'LWP::UserAgent');
has 'values' => (is =>'rw', isa=>'HashRef' );

our $oid2name = {};
do 'oid_defs.pl';
foreach my $oid (keys %$oid2name) {
  my $name = $oid2name->{$oid};
  has $name => (is=>'rw', isa=>'Value');
}

sub BUILD {
  my $self = shift;
  my $opt = shift || {};
  $self->values({});
  if ($opt->{ip} and $opt->{password}) {
    $self->connect();
  }
}

sub connect {
  my $self = shift;
  my $ua = new LWP::UserAgent;
  $ua->credentials($self->ip.':'.$self->port, 'tstat', admin => $self->password);
  $self->ua($ua);
}

sub get_oids {
  my $self = shift;
  my $oids = shift || [];
  my $req = {};
  map { $req->{'OID'.$_} = '' } @$oids;
  my $response = $self->ua->post($self->base_url.'/get/', $req);
  $self->set_tokens($response->content);
}

sub value {
  my $self = shift;
  my $name = shift;
  return $self->values->{$name} || $self->get_oids([$name]) || undef;
}

sub set_oid {
  my $self = shift;
  my ($oid, $value) = @_;
  $self->set_oids($oid=>$value);
  return $self->values->{$oid};
}

sub set_oids {
  my $self = shift;
  my (%oids) = @_;
  foreach my $oid (keys %oids) { $oids{"OID$oid"} = $oids{$oid}; delete $oids{$oid}; }
  my $response = $self->ua->post($self->base_url.'/pdp/', [%oids, submit=>'Submit']);
  $self->set_tokens($response->content);
}

sub set_tokens {
  my $self = shift;
  my $input = shift;
  foreach my $pair (split(/\&/,$input)) {
    my ($key,$value) = split(/=/,$pair);
    $key=~s/^OID//;
    $self->values->{$key} = $value;
    warn "Error when setting $key\n" if $value=~/^ERROR/;
  }
}

1;


=head1 NAME

Proliphix - Talks to Proliphix network thermostats

=head1 SYNOPSYS

  #!/usr/bin/perl
  use Proliphix;
  
  my $thermostat = new Proliphix(ip=>'mythermaddress', password=>'mythermpassword');
  
  #requests these OIDs (documented in PDF API available from Proliphix) from the thermostat
  $thermostat->get_oids([qw/4.3.2.1 4.1.1 4.1.3/]);
  
  #sets (writable) OIDs in thermostat. Many values are not writable, see Proliphix documentation.
  $thermostat->set_oids('10.1.6'=>$ARGV[0]);
  
  #lists known values in thermostat. Pounding the device too hard will cause trouble so the module
  #holds on to values until another call to get_oids
  $thermostat->values();

=head1 DESCRIPTION

Module to communicate with Proliphix IP network thermostats. Module is a skeleton at best and 
should probably be written differently for a multitude of reasons. I wanted to play around
with Moose and was disappointed that no one else had written this module, so here's a quick
iteration that should handle most cases without too much crying.

=head1 BUGS

Almost certainly. Let me know, I'll probably fix them, or send me a patch.

=head1 SEE ALSO

Documentation and additional information about Proliphix thermostats is available on
the Proliphix website http://www.proliphix.com/

=head1 AUTHOR

John Lifsey, <nebulous@crashed.net>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under the same terms as Perl itself

=cut


