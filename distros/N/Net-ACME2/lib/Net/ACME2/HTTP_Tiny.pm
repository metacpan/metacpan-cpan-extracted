package Net::ACME2::HTTP_Tiny;

=encoding utf-8

=head1 NAME

Net::ACME2::HTTP_Tiny - HTTP client for Net::ACME

=head1 SYNOPSIS

    use Net::ACME2::HTTP_Tiny;

    my $http = Net::ACME2::HTTP_Tiny->new();

    #NOTE: Unlike HTTP::Tiny’s method, this will die() if the HTTP
    #session itself fails--for example, if the network connection was
    #interrupted. These will be Net::ACME2::X::HTTP::Network instances.
    #
    #This also fails on HTTP errors (4xx and 5xx). The errors are
    #instances of Net::ACME2::X::HTTP::Protocol.
    #
    my $resp_obj = $http->post_form( $the_url, \%the_form_post );

=head1 DESCRIPTION

This module largely duplicates the work of C<HTTP::Tiny::UA>, just without the
dependency on C<superclass.pm> (which brings in a mess of other undesirables).

The chief benefit is that C<request()> and related methods will return
instances of C<HTTP::Tiny::UA::Response> rather than simple hashes.

This also always verifies remote SSL connections and always C<die()>s if
either the network connection fails or the protocol indicates an error
(4xx or 5xx).

=cut

use strict;
use warnings;

use parent qw( HTTP::Tiny );

use HTTP::Tiny::UA::Response ();

use Net::ACME2::X ();

# This circular dependency is unfortunate, but PAUSE needs to see a static
# $Net::ACME2::VERSION. (Thanks to Dan Book for pointing it out.)
use Net::ACME2 ();

sub VERSION {

    # HTTP::Tiny gets upset if there’s anything non-numeric
    # (e.g., “-TRIAL1”) in VERSION(). So weed it out here.
    my $version = $Net::ACME2::VERSION;
    $version =~ s<[^0-9].].*><>;

    return $version;
}

#Use this to tweak SSL config, e.g., if you want to cache PublicSuffix.
our @SSL_OPTIONS;

sub new {
    my ( $class, %args ) = @_;

    $args{'SSL_options'} = {
        ( $args{'SSL_options'} ? (%{ $args{'SSL_options'} }) : () ),
        @SSL_OPTIONS,
    };

    my $self = $class->SUPER::new(
        verify_SSL => 1,
        %args,
    );

    return $self;
}

#mocked in tests
*_base_request = HTTP::Tiny->can('request');

sub request {
    my ( $self, $method, $url, $args_hr ) = @_;

    #HTTP::Tiny clobbers $@. The clobbering is useless since the
    #error is in the $resp variable already. Clobbering also risks
    #action-at-a-distance problems, so prevent it here.

    #cf. eval_bug.readme
    my $eval_err = $@;

    my $resp = _base_request( $self, $method, $url, $args_hr || () );

    $@ = $eval_err;

    my $resp_obj = HTTP::Tiny::UA::Response->new($resp);

    #cf. HTTP::Tiny docs
    if ( $resp_obj->status() == 599 ) {
        die Net::ACME2::X->create(
            'HTTP::Network',
            {
                method    => $method,
                url       => $url,
                error     => $resp_obj->content(),
                redirects => $resp->{'redirects'},
            }
        );
    }

    if ( $resp->{'status'} >= 400 ) {
        die Net::ACME2::X->create(
            'HTTP::Protocol',
            {
                method    => $method,
                redirects => $resp->{'redirects'},
                ( map { ( $_ => $resp_obj->$_() ) } qw( content status reason url headers ) ),
            },
        );
    }

    return $resp_obj;
}

1;

