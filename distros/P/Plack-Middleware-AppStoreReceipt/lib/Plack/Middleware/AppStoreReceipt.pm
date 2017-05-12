package Plack::Middleware::AppStoreReceipt;
# ABSTRACT: The Plack::Middleware that verifies Apple App Store Receipts for In-App Purchases

our $VERSION = '0.03';

use warnings;
use strict;
use parent qw(Plack::Middleware);
use Plack::Request;
use Plack::Util::Accessor qw(route method path receipt_data allow_sandbox shared_secret);
use JSON;
use Try::Tiny;
use Furl;

sub prepare_app {
    my $self = shift;

    $self->allow_sandbox( $self->allow_sandbox || 0 );

    if ( !$self->route ) {
        $self->method( 'POST' ) if !$self->method;
        $self->path( '/receipts/validate' ) if !$self->path;
    } else {
        while (my ($key, $value) = each %{$self->route}) {
            $self->method( uc $key );
            $self->path( $value );
        }
    }
}

sub call {
    my ( $self, $env ) = @_;

    my $vpath = ($env->{'PATH_INFO'} eq $self->path);
    return [
            405,
            [
                'Allow'        => $self->method,
                'Content-Type' => 'text/plain',
            ],
            ['Method not allowed'],
        ] if $vpath && $env->{'REQUEST_METHOD'} ne $self->method;

    my $res = try { $self->app->($env) };

    $res = $self->_verify_receipt($env) if $vpath;

    return $res;
};

sub _verify_receipt {
    my ( $self, $env ) = @_;

    my $plack_req = Plack::Request->new($env);
    my $receipt_data_param = $plack_req->param('receipt_data') || $plack_req->param($self->receipt_data);
    my %params = ("receipt-data" => $receipt_data_param);
    $params{password} = $self->shared_secret if $self->shared_secret;
    my $receipt_data = encode_json (\%params);

    my $res;
    $res = $self->_post_receipt_to_itunes( 'production', $receipt_data, $env );
    if ( $res->[0] == 200 && $self->_is_sandboxed( $self->_parse_success_response( $res ) ) ) {
        #should request to sandbox url since it's sandbox receipt!!
        print "Retrying to post to sandbox environment...\n";
        $res = $self->_post_receipt_to_itunes( 'sandbox', $receipt_data, $env );
    }
    return $res;
}

sub _post_receipt_to_itunes {
    my ( $self, $itunes_env, $receipt_data, $env ) = @_;

    die "sandbox request is not allowed" if $itunes_env eq 'sandbox' && !$self->allow_sandbox;

    my $endpoint = {
        'production' => 'https://buy.itunes.apple.com/verifyReceipt',
        'sandbox'    => 'https://sandbox.itunes.apple.com/verifyReceipt',
    };

    my $furl = Furl->new(
        agent   => 'Furl/2.15',
        timeout => 10,
    );

     my $res = $furl->post(
        $endpoint->{$itunes_env}, # URL
        ['Content-Type' => 'application/json'],                 # headers
        $receipt_data,      # form data (HashRef/FileHandle are also okay)
    );

    return [200, ['Content-Type' => 'application/json'], [$res->content]] if $res->is_success;
    return [500, ['Content-Type' => 'text/plain' ], ["error: ".$res->status_line."\n"]];
}

sub _parse_success_response {
    my ( $self, $res ) = @_;
    return decode_json $res->[2]->[0];
}

sub _is_sandboxed {
    my ( $self, $json ) = @_;
    return ( $json->{'status'} == 21007 ); #should be sandboxed!
}

1;


__END__

=head1 NAME

Plack::Middleware::AppStoreReceipt - Verifying a Receipt with the Apple App Store

=head1 SYNOPSIS

In the app.psgi

    enable "AppStoreReceipt";

That's it.

By default, you can POST 'receipt_data' with a base64 encoded string to /receipts/validate

aka, curl -X POST http://localhost:5000/receipts/validate -d "receipt_data=$base64EncodedString"

Since it's disable a sandbox request by default, therefore to use the sandbox testing environment,
please set allow_sandbox to true

    enable "AppStoreReceipt", allow_sandbox => 1;

Perhaps, you don't like /receipts/validate endpoint, though you are able to change the default route as well
by either

    enable "AppStoreReceipt", route => { 'post' => '/appstore/verify' };
    (to use route, the format is 'route => { $method => $path }')
or
    enable "AppStoreReceipt", method => 'POST', path => '/appstore/verify';

And you can even change the default receipt_data parameter

    enable "AppStoreReceipt", receipt_data => '(name of receipt parameter here)';

If you have a shared secret for iTunes, you may set it as

    enable "AppStoreReceipt", shared_secret => '(shared secret bytes here)';

=head1 DESCRIPTION

This middleware provides an endpoint for an iOS app to validate its reciept data.
Therefore, this middleware ensures that your iOS app does not post the iap receipt to any fake Apple server.

It does post given receipt data to iTunes production first.
If it is a sandbox receipt (told by iTunes production), it will be re-sended to iTunes sandbox again automatically.

=head1 AUTHOR

zdk

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Plack::Middleware>

http://www.macworld.com/article/1167677/hacker_exploits_ios_flaw_for_free_in_app_purchases.html

=cut

