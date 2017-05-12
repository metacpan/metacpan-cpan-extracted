use warnings;
use strict;

package Net::OAuth2::Scheme::Mixin::HMac;
BEGIN {
  $Net::OAuth2::Scheme::Mixin::HMac::VERSION = '0.03';
}
# ABSTRACT: implement http_hmac token scheme

use Net::OAuth2::Scheme::Option::Defines;
use Net::OAuth2::Scheme::HmacUtil
  qw(hmac_name_to_len_fn encode_plainstring decode_plainstring timing_indep_eq);
use MIME::Base64 qw(encode_base64 decode_base64);

# HMAC token

# IMPLEMENTATION (transport_)http_hmac
#   (http_hmac_)nonce_length = 8
#   (http_hmac_)ext_body  ($request, 'server'|'client') -> ext
# SUMMARY
#   http_hmac token
# REQUIRES
#   random

Default_Value http_hmac_token_type => 'mac';
Default_Value http_hmac_scheme => 'MAC';
Default_Value http_hmac_nonce_length => 8;
Default_Value http_hmac_ext_body => sub {''};

sub pkg_transport_http_hmac {
    my __PACKAGE__ $self = shift;
    $self->parameter_prefix(http_hmac_ => @_);
    $self->make_alias(http_hmac_header    => 'transport_header');
    $self->make_alias(http_hmac_header_re => 'transport_header_re');
    $self->make_alias(http_hmac_scheme    => 'transport_auth_scheme');
    $self->make_alias(http_hmac_scheme_re => 'transport_auth_scheme_re');

    $self->install(token_type => $self->uses('http_hmac_token_type'));

    my $http_hmac_ext_body = $self->uses('http_hmac_ext_body');
    if ($self->is_resource_server) {
        $self->install( psgi_extract =>
            $self->http_header_extractor
              (parse_auth => sub {
                   my ($auth, $req) = @_;
                   my %attr = ();
                   while ($auth =~ m{\G([^=[:space:]]+)\s*=\s*"([^"]*)"\s*,?\s*}gs) {
                       $attr{$1} = $2;
                   }
                   return () if grep {!defined} (my ($id, $nonce, $mac) = @attr{qw(id nonce mac)});
                   my $ext = defined($attr{ext}) ? $attr{ext} : '';

                   my $uri = $req->uri;
                   my ($host,$port) = split ':',($req->headers->{host} || $uri->host_port);
                   $port ||= $uri->scheme eq 'https' ? 443 : 80;

                   return ($id, $mac, $nonce, $req->method, $uri->path_query, $host, $port,
                           $ext, $http_hmac_ext_body->($req, 'server'));
               }));
    }
    if ($self->is_client) {
        my $random = $self->uses('random');
        my $nonce_length = $self->uses('http_hmac_nonce_length');

        $self->install( accept_needs => [qw(mac_key mac_algorithm mac_received)] );
        $self->install( accept_hook => sub {
            my $params = shift;
            $params->{mac_received} = time();
            return ("unknown_algorithm")
              unless hmac_name_to_len_fn($params->{mac_algorithm});
            return ();
        });

        $self->http_header_inserter
          (make_auth => sub {
               my ($http_req, $token, %o) = @_;

               my @missing;
               my ($key, $alg, $received) =
                 map {defined $o{$_} ? $o{$_} : do { push @missing, @_; undef }}
                   (qw(mac_key mac_algorithm mac_received));
               return ("missing_$missing[0]")
                 if @missing;

               return ("unknown_algorithm")
                 unless my (undef, $alg_fn) = hmac_name_to_len_fn($alg);

               my $nonce = (time() - $received) . ':' . encode_plainstring($random->($nonce_length));

               my $uri = $http_req->uri;

               my ($host,$port) = split ':',($http_req->header('Host') || $uri->host_port);
               $port ||= $uri->scheme eq 'https' ? 443 : 80;

               my $ext = $http_hmac_ext_body->($http_req, 'client');

               my $normalized = join "\n",
                 $nonce, $http_req->method, $uri->path_query, $host, $port, $ext, '';
               return
                 (undef,
                  join ",\n ", qq(id="$token"), qq(nonce="$nonce"),
                     qq(mac=").encode_base64($alg_fn->($key,$normalized), '').qq("),
                       (length($ext) ? (qq(ext="$ext")) : ()));
           });
    }
    return $self;
}

# IMPLEMENTATION (format_)http_hmac
#   (http_hmac_)hmac
# SUMMARY
#   HMAC-HTTP tokens
# REQUIRES
#   v_id_next
#   v_table_insert

sub pkg_format_http_hmac {
    my __PACKAGE__ $self = shift;
    $self->parameter_prefix(http_hmac_ => @_);

    # CANNOT be used for authcodes and refresh tokens
    $self->install(format_no_params => 0);

    my $mac_alg_name = $self->uses('http_hmac_hmac');
    $mac_alg_name =~ y/_/-/;
    my ($mac_alg_keylen, $mac_alg) = hmac_name_to_len_fn($mac_alg_name)
      or $self->croak("unknown/unavailable hmac function: $mac_alg_name");

    if ($self->is_auth_server) {
        my ($random, $v_id_next, $vtable_insert, $token_type) = $self->uses_all
          (qw(random  v_id_next   vtable_insert   token_type));
        $self->install( token_create => sub {
            my ($now, $expires_in, @bindings) = @_;
            my $v_id = $v_id_next->();
            my $key = encode_plainstring($random->($mac_alg_keylen));
            my $error = $vtable_insert->($v_id, $now + $expires_in, $now, $key, @bindings);
            return ($error,
                    ($error ? () :
                     (encode_plainstring($v_id),
                      token_type => $token_type,
                      mac_key => $key,
                      mac_algorithm => $mac_alg_name)));
        });
    }

    if ($self->is_resource_server) {
        $self->install( token_parse => sub {
            my ($v_id, @rest) = @_;
            return (decode_plainstring($v_id), @rest);
        });

        $self->install( token_finish => sub {
            my ($v, $mac, $nonce, $method, $uri, $host, $port, $ext, $ext_body) = @_; # ($validator, @payload)
            my ($expiration, $issuance, $key, @bindings) = @$v;
            $mac = decode_base64($mac);
            my $normalized = join "\n",$nonce,$method,$uri,$host,$port,$ext,$ext_body;
            return ('bad_hash')
              unless
                length($mac) == $mac_alg_keylen &&
                timing_indep_eq($mac, $mac_alg->($key, $normalized), $mac_alg_keylen) &&
                length ($ext) == length($ext_body) &&
                timing_indep_eq($ext, $ext_body);
            return (undef, $issuance, $expiration - $issuance, @bindings);
        });
    }
    return $self;
}

1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::Mixin::HMac - implement http_hmac token scheme

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

This is an internal module that implements HMac-HTTP tokens as described in
L<draft-ietf-oauth-v2-http-mac-00|http://tools.ietf.org/html/draft-ietf-oauth-v2-http-mac-00>
minus the bodyhash functionality (which was in the process of being
discarded last I looked at the mailing list)

See L<Net::OAuth2::Scheme::Factory> for actual option usage.

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

