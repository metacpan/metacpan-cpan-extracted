package Net::DNS::Resolver::DoH;
use strict;
use warnings;
our $VERSION = '1.20200220'; # VERSION
## ABSTRACT: Experimental DNS over HTTPS for Net::DNS::Resolver

use base 'Net::DNS::Resolver';

use Net::DNS::Packet;
use Net::DNS::Question;
use Net::DNS::ZoneFile;
use HTTP::Tiny;
use MIME::Base64 qw{ encode_base64url };

sub send {
  my $self        = shift;
  my $packet      = $self->_make_query_packet(@_);
  my $packet_data = $packet->data;
  $self->_reset_errorstring;
  return $self->_send_doh( $packet, $packet_data );
}

sub _defaultdohservers {
  return (
    'https://dns.google/dns-query{dns}',
    'https://cloudflare-dns.com/dns-query/{dns}',
  );
}

sub nameservers {
  my $self = shift;
  $self = $self->_defaultdohservers unless ref($self); ######
  if ( @_ ) {
    my @url;
    foreach my $ns ( grep defined, @_ ) {
      next if ! $ns =~ /https:\/\//;
      next if ! $ns =~ /\{dns\}/;
      push @url, $ns;
    }
    $self->{dohnameservers} = \@url;
  }
  return @{$self->{dohnameservers}} if defined $self->{dohnameservers};
  return @{$self->_defaultdohservers};
}

sub _send_doh {
  my ( $self, $query, $query_data ) = @_;
  my @ns = $self->nameservers();
  my $fallback;
  my $timeout = $self->{tcp_timeout}; ## TODO
  foreach my $url (@ns) {
    my $this_url = $url;
    my $data = encode_base64url( $query_data );
    $this_url =~ s/{dns}/?dns=$data/;
    $self->_diag( 'doh send', "[$url]" );
    my $http = HTTP::Tiny->new(
      'keep_alive' => 0,
    );
    my $response = $http->get( $this_url );
    if ( ! $response->{'success'} ) {
        #        return; #### TODO
    }
    $self->_diag( 'reply from', "[$url]", $response->{status}, length($response->{content}), 'bytes' );

    my $reply = Net::DNS::Packet->decode( \$response->{content}, $self->{debug} );
    $self->errorstring($@);

    #$reply->from($ip);

    if ( $self->{tsig_rr} && !$reply->verify($query) ) {
      $self->errorstring( $reply->verifyerr );
      next;
    }

    my $rcode = $reply->header->rcode;
    return $reply if $rcode eq 'NOERROR';
    return $reply if $rcode eq 'NXDOMAIN';

    #$fallback = $reply; ## TODO

    return $reply;

  }

  #$self->{errorstring} = $fallback->header->rcode if $fallback;  TODO
  #$self->errorstring('query timed out') unless $self->{errorstring};
  #return $fallback;
}

#sub srcaddr { ## TODO

sub bgsend { die 'not implemented' }
sub bgbusy { die 'not implemented' }
sub bgread { die 'not implemented' }
sub bgisready { die 'not implemented' }
sub axfr { die 'not implemented' }

## TODO override methods not available via DoH

1;
