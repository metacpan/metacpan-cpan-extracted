package Railsish::Dispatcher;
our $VERSION = '0.21';

# ABSTRACT: The first handler for requests.

use strict;
use warnings;

use Railsish::Router;
use YAML::Any;
use Hash::Merge qw(merge);
use Encode;
use Railsish::CoreHelpers;
use Railsish::TextHelpers qw(camelcase);
use MIME::Base64;
use Crypt::CBC;
use JSON::XS;

sub dispatch {
    my ($class, $request) = @_;
    my $path = $request->request_uri;

    my $format = "html";
    if ($path =~ s/\.([a-z]+)$//) {
        $format = $1;
    }

    my $method = lc($request->method);
    if ($method eq 'post') {
        if (my $m = $request->param("_method")) {
            $method = lc($m);
        }
    }
    my $matched = Railsish::Router->match(
        $path, conditions => { method => $method }
    );

    my $response = HTTP::Engine::Response->new;
    unless($matched) {
        $response->body("internal server error: unknown route");
        $response->status(500);
        return $response;
    }

    my $mapping = $matched->mapping;

    my $controller = $mapping->{controller};
    my $action = $mapping->{action} || "index";

    my $controller_class = camelcase(lc($controller)) . "Controller";
    my $sub = $controller_class->can($action);

    die "action $action is not defined in $controller_class." unless $sub;

    my %params = _preprocessed_parameters($request);

    my $params = merge(\%params, $mapping);

    $Railsish::Controller::params = $params;
    $Railsish::Controller::request = $request;
    $Railsish::Controller::response = $response;
    $Railsish::Controller::controller = $controller;
    $Railsish::Controller::action = $action;
    $Railsish::Controller::format = $format;

    my $session = $Railsish::Controller::session = _load_session($request);

    logger->debug(Dump({
        request_path => $path,
        method => $method,
        controller => $controller,
        action => $action,
        params => $params,
        format => $format,
        session => $session
    }));

    $sub->();

    _store_session($response, $session);

    return $response;
}

sub _preprocessed_parameters {
    my ($request) = @_;
    my %params = %{$request->parameters};
    for (keys %params) {
        $params{$_} = Encode::decode_utf8( $params{$_} );

        if (/^(\w+)\[(\w+)\]$/) {
            $params{$1} ||= {};
            $params{$1}->{$2}= delete $params{$_};
        }
    }

    return %params;
}

sub _load_session {
    my ($request) = @_;

    # XXX: the -key here should be given from app config.
    my $cipher = Crypt::CBC->new(-key => "railsish", -cipher => "Rijndael");
    my $session = {};
    my $session_cookie = $request->cookies->{_railsish_session};
    if ($session_cookie) {
        my $ciphertext_base64   = $session_cookie->value;
        my $ciphertext_unbase64 = decode_base64($ciphertext_base64);
        my $json = $cipher->decrypt($ciphertext_unbase64);
        $session = decode_json($json);
    }
    return $session;
}

sub _store_session {
    my ($response, $session) = @_;
    my $cipher = Crypt::CBC->new(-key => "railsish", -cipher => "Rijndael");
    my $json = encode_json($session);
    my $ciphertext = $cipher->encrypt($json);
    my $ciphertext_base64 = encode_base64($ciphertext, '');
    $response->cookies->{_railsish_session} = {
        value => $ciphertext_base64
    };
}

1;


__END__
=head1 NAME

Railsish::Dispatcher - The first handler for requests.

=head1 VERSION

version 0.21

=head1 DESCRIPTION

This class contains the first handler for requests.

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

