package Nephia::Plugin::JSON;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Plugin';
use JSON ();
use Nephia::Response;

our $VERSION = "0.03";

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    my $app = $self->app;
    $app->{json_obj} = JSON->new->utf8;
    return $self;
}

sub exports { qw/json_res encode_json decode_json/ }

sub json_res {
    my ($self, $context) = @_;
    return sub ($) {
        my $content_body = $_[0];
        my $headers = [
            'Content-Type'           => 'application/json; charset=UTF-8',
            'X-Content-Type-Options' => 'nosniff',  ### For IE 9 or later. See http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2013-1297
            'X-Frame-Options'        => 'DENY',     ### Suppress loading web-page into iframe. See http://blog.mozilla.org/security/2010/09/08/x-frame-options/
            'Cache-Control'          => 'private',  ### no public cache
        ]; 
        if ($self->{enable_api_status_header}) {
            $content_body->{status} ||= 200;
            push @$headers, ('X-API-Status', $content_body->{status});
        }
        $context->set(res => Nephia::Response->new(
            200, $headers, 
            $self->app->{json_obj}->encode($content_body)
        ));
    };
}

sub encode_json {
    my ($self, $context) = @_;
    return sub ($) {$self->app->{json_obj}->encode($_[0])};
}

sub decode_json {
    my ($self, $context) = @_;
    return sub ($) {$self->app->{json_obj}->decode($_[0])};
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::JSON - A plugin for Nephia that provides JSON Response DSL

=head1 SYNOPSIS

    use Nephia plugins => ['JSON'];
    app {
        json_res +{ 
            name  => 'ytnobody',
            birth => '1980-11-11',
        };
    };

=head1 DESCRIPTION

Nephia::Plugin::JSON provides three DSL that is about JSON.

=head1 CONFIG

=head2 enable_api_status_header

If you define it as true, json_res returns with 'X-API-Status' header.

    use Nephia plugins => ['JSON' => {enable_api_status_header => 1}];
    ...


=head1 DSL

=head2 json_res $hashref

Returns a Nephia::Response that contains application/json contents.

=head2 encode_json $hashref

Returns JSON string of encoded hashref.

=head2 decode_json $json_str

Returns hashref of decoded JSON.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

