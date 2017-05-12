use warnings;
use strict;

package Net::OAuth2::Scheme::Mixin::Bearer;
BEGIN {
  $Net::OAuth2::Scheme::Mixin::Bearer::VERSION = '0.03';
}
# ABSTRACT: implement bearer token schemes

use Net::OAuth2::Scheme::Option::Defines;
use parent 'Net::OAuth2::Scheme::Mixin::Current_Secret';

use Net::OAuth2::Scheme::HmacUtil
  qw(encode_base64url decode_base64url
     sign_binary unsign_binary
     hmac_name_to_len_fn);


# Bearer tokens
#

# IMPLEMENTATION (transport_)bearer
#   (bearer_)header = 'Authorization';
#   (bearer_)header_re = '^Authorization$';
#   (bearer_)scheme = 'Bearer';
#   (bearer_)scheme_re = '^Bearer$';
#   (bearer_)allow_body = 1;
#   (bearer_)allow_uri = 0;
#   (bearer_)param = 'access_token';
#   (bearer_)param_re = '^access_token$';
#   (bearer_)client_uses_param = 0;
# SUMMARY
#   Bearer token, handle-style


Default_Value bearer_token_type => 'Bearer';
Default_Value bearer_scheme => 'Bearer';
Default_Value bearer_allow_body => 1;
Default_Value bearer_allow_uri => 0;
Default_Value bearer_param => 'access_token';  #as per draft 15 of the bearer spec
Default_Value bearer_client_uses_param => 0;

Define_Group bearer_param_re_set => 'default',
  qw(bearer_param_re);

sub pkg_bearer_param_re_set_default {
    my __PACKAGE__ $self = shift;
    my $param = $self->uses('bearer_param');
    $self->install(bearer_param_re => qr(\A\Q$param\E\z));
    return $self;
}

sub pkg_transport_bearer {
    my __PACKAGE__ $self = shift;
    $self->parameter_prefix(bearer_ => @_);
    $self->make_alias(bearer_header    => 'transport_header');
    $self->make_alias(bearer_header_re => 'transport_header_re');
    $self->make_alias(bearer_scheme    => 'transport_auth_scheme');
    $self->make_alias(bearer_scheme_re => 'transport_auth_scheme_re');

    $self->install(token_type => $self->uses('bearer_token_type'));

    my $allow_body = $self->uses('bearer_allow_body');
    my $allow_uri = $self->uses('bearer_allow_uri');
    my $body_or_uri =
      ($allow_body ? ($allow_uri ? 'dontcare' : 'body') : ($allow_uri ? 'query' : ''));

    if ($self->is_client) {
        $self->install( accept_needs => [] );
        $self->install( accept_hook => sub {return ()} );
        if ($self->uses('bearer_client_uses_param')) {
            $self->croak("bearer_client_uses_param requires bearer_allow_(body|uri)")
                unless $body_or_uri;
            my $param_name = $self->uses('bearer_param');
            $self->http_parameter_inserter($body_or_uri, $param_name, sub { $_[0] });
        }
        else {
            $self->http_header_inserter();
        }
    }

    if ($self->is_resource_server) {
        my $header_extractor = $self->http_header_extractor();

        if ($body_or_uri) {

            my $param_re = $self->uses('bearer_param_re');
            $param_re = qr{$param_re}is unless ref($param_re);

            my $param_name = $self->installed('bearer_param');
            $self->croak("bearer_param_re does not match bearer_param")
              if (defined($param_name) && $param_name !~ $param_re);

            my $param_extractor = $self->http_parameter_extractor($body_or_uri, $param_re);
            $self->install( psgi_extract => sub {
                my $env = shift;
                return ($header_extractor->($env), $param_extractor->($env));
            });
        }
        else {
            $self->install( psgi_extract => $header_extractor );
        }
    }
}

# IMPLEMENTATION (format_)bearer_handle
# SUMMARY
#   Bearer token, handle-style
# REQUIRES
#   v_id_next (v_id_is_random)
#   v_table_insert

sub pkg_format_bearer_handle {
    my __PACKAGE__ $self = shift;

    # yes, we can use this for authcodes and refresh tokens
    $self->install(format_no_params => 1);

    if ($self->is_auth_server) {
        $self->uses(v_id_suggest => 'random');
        my ( $v_id_next, $vtable_insert) = $self->uses_all
          (qw(v_id_next   vtable_insert));

        # Enforce requirements on v_id_next.
        # Since, for this token format, v_ids are used directly,
        # they MUST NOT be predictable.
        $self->ensure(v_id_is_random => 1,
                      'bearer_handle tokens must use random identifiers');

        my $token_type = ($self->is_access ? $self->uses('token_type') : ());
        $self->install( token_create => sub {
            my ($now, $expires_in, @bindings) = @_;
            my $v_id = $v_id_next->();
            my $error = $vtable_insert->($v_id, $expires_in + $now, $now, @bindings);
            return ($error,
                    ($error ? () :
                     (encode_base64url($v_id),
                      ($token_type ? (token_type => $token_type) : ()),
                     )));
        });
    }

    if ($self->is_resource_server) {
        # handle token has no @payload
        $self->install( token_parse => sub {
            return (decode_base64url($_[0]));
        });
        $self->install( token_finish => sub {
            my ($v) = @_;          # ($validator, @payload)
            return ('unrecognized')
              unless my ($expiration, $issuance, @bindings) = @$v;
            return (undef, $issuance, $expiration - $issuance, @bindings);
        });
    }
    return $self;
}


# IMPLEMENTATION format_bearer_signed FOR format
#   (bearer_signed_)hmac
#   (bearer_signed_)nonce_length  [=hmac length/2]
#   (bearer_signed_)fixed
# SUMMARY
#   Bearer token, signed-assertion-style
# REQUIRES
#   current_secret
#   random
#
# Access_token value contains a key identifying a shared secret
# (and possibly also the authserver and the resource), a set
# of values specifying expiration and scope, and a HMAC value to sign
# everything.  Only the shared secret needs to be separately
# communicated.

Default_Value bearer_signed_hmac => 'hmac_sha224';
Default_Value bearer_signed_fixed => [];

sub pkg_format_bearer_signed {
    my __PACKAGE__ $self = shift;
    $self->parameter_prefix(bearer_signed_ => @_);

    # yes, we can use this for authcodes and refresh tokens
    $self->install(format_no_params => 1);

    if ($self->is_auth_server) {
        my $hmac = $self->uses('bearer_signed_hmac');
        my ($hlen,undef) = hmac_name_to_len_fn($hmac)
          or $self->croak("unknown/unavailable hmac function: $hmac");
        my $nonce_len = $self->uses(bearer_signed_nonce_length => $hlen/2);

        $self->uses(current_secret_length => $hlen);
        $self->uses(current_secret_payload => $self->uses('bearer_signed_fixed'));

        my $secret = $self->uses('current_secret');
        my $auto_rekey_check = $self->uses('current_secret_rekey_check');
        my $random = $self->uses('random');

        my $token_type = ($self->is_access ? $self->uses('token_type') : ());

        $self->install( token_create => sub {
            my ($now, $expires_in, @bindings) = @_;
            my ($error) = $auto_rekey_check->($now);
            return (rekey_failed => $error)
              if $error;

            my ($v_id, $v_secret, undef, @fixed) = @{$secret};
            for my $f (@fixed) {
                my $given = shift @bindings;
                return (fixed_parameter_mismatch => $f,$given)
                  if $f ne $given;
            }
            my $nonce = $random->($nonce_len);
            return (undef,
                    encode_base64url(pack 'w/a*a*', $v_id,
                                     sign_binary($v_secret,
                                                 pack('w/a*ww(w/a*)*', $nonce,
                                                      $now, $expires_in,
                                                      @bindings),
                                                 hmac => $hmac,
                                                 extra => $v_id)),
                    ($token_type ? (token_type => $token_type) : ()),
                   );
        });
    }
    if ($self->is_resource_server) {
        # On the resource side we cannot use 'current_secret'
        # since token may have been created with a previous secret,
        # so we just have to take whatever we get from the vtable
        $self->install( token_parse => sub {
            my ($token) = @_; # bearer token, no additional attributes
            my ($v_id, $bin) = unpack 'w/a*a*', decode_base64url($token);
            return ($v_id, $v_id, $bin)
        });
        $self->install( token_finish => sub {
            my ($validator, $v_id, $bin) = @_;
            my (undef, undef, $v_secret, @fixed) = @$validator;
            my ($payload, $error) = unsign_binary($v_secret, $bin, $v_id);
            return ($error) if $error;
            my ($now, $expires_in, @bindings) = unpack 'w/xww(w/a*)*', $payload;
            return (undef, $now, $expires_in, @fixed, @bindings);
        });
    }
    return $self;
}


1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::Mixin::Bearer - implement bearer token schemes

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

This is an internal module that implements two varieties of Bearer tokens.

See L<Net::OAuth2::Scheme::Factory> for actual option usage.

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

