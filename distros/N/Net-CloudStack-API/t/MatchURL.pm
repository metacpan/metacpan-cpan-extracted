package MatchURL;

use strict;
use warnings;

use Carp;
use Digest::SHA 'hmac_sha1';
use MIME::Base64;
use URI::Encode 'uri_encode';

sub match {

  # $check_url is the url returned by Net::Cloudstack->url
  # $base_url, $api_path, $api_key, $secret_key are the same as sent to Net::Cloudstack->new
  # $cmd is the command being run
  # $pairs must be an AoA, each element being [ name, value ]

  my ( $check_url, $base_url, $api_path, $api_key, $secret_key, $cmd, $pairs ) = @_;

  croak '$pairs must be an arrayref'
      if ref $pairs && ref $pairs ne 'ARRAY';

  my @p = ( [ 'apiKey', $api_key ], [ 'command', $cmd ] );

  my ( @pairs, @work );

  for my $pair ( @p, @$pairs ) {

    croak 'elements of $pairs must be arrayrefs'
        unless ref $pair eq 'ARRAY';

    my ( $name, $value ) = @$pair;

    push @pairs, "$name=$value";
    push @work, sprintf "$name=%s", uri_encode( $value, 1 );

  }

  my $work = join '&', map { lc } sort @work;
  my $digest = hmac_sha1( $work, $secret_key );
  my $base64 = encode_base64( $digest );
  chomp $base64;
  my $signature = uri_encode( $base64, 1 );

  my $work_url = sprintf '%s/%s%s&signature=%s', $base_url, $api_path, ( join '&', sort @pairs ), $signature;

  return $check_url eq $work_url;

} ## end sub match

1;
