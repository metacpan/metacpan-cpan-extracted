package OAuthomatic::Internal::Util;
# ABSTRACT: internal helper routines (form parsing and filling)


use strict;
use warnings;
use Exporter::Shiny qw(fill_httpmsg_form parse_http_msg_form fill_httpmsg_text
                       serialize_json fill_httpmsg_json parse_http_msg_json);

use HTTP::Request;
use HTTP::Response;
use HTTP::Body;
use URI;
use URI::QueryParam;
use Encode;
use utf8;
use JSON qw/decode_json encode_json from_json to_json/;
use Try::Tiny;
use Scalar::Util qw(reftype);
use namespace::sweep;

# FIXME: throw on errors


sub fill_httpmsg_form {
    my ($http_message, $params) = @_;

    my $body_form = URI->new('http:');
    $body_form->query_form_hash($params);
    $http_message->content($body_form->query());
    $http_message->content_type("application/x-www-form-urlencoded; charset=utf-8");
    return;
}


sub parse_http_msg_form {
    my ($http_message, $force_form) = @_;

    my $content_type = $http_message->content_type;
    my $charset = $http_message->content_type_charset;

    if($http_message->content_is_text) {
        if($force_form) {
            $content_type = 'application/x-www-form-urlencoded';
        }
    }

    my $body = HTTP::Body->new(
        $content_type,
        $http_message->content_length);
    $body->add($http_message->content);
    my $params = $body->param;

    # HTTP::Body does not decode
    if($charset) {
        if($charset =~ /^UTF-?8$/x) {
            for my $value (values %$params) {
                unless ( ref $value && ref $value ne 'ARRAY' ) {
                    utf8::decode($_) for ( ref($value) ? @{$value} : $value );
                }
            }
        } else {
            foreach my $key (keys %$params) {
                my $value = $params->{$key};
                unless( ref($value) ) {
                    $params->{$key} = decode($charset, $value);
                } elsif( ref($value) eq 'ARRAY') {
                    my @fixed = map { decode($charset, $_) } @$value;
                    $params->{$key} = \@fixed;
                }
            }
        }
    }

    return $params;

    # For comparison: this usually works OK too (albeit is too magic for my taste)
    # use CGI qw();
    # my %vars = CGI->new($http_message->content)->Vars;
    # return \%vars;
}


sub fill_httpmsg_text {
    my ($http_message, $text, $content_type) = @_;

    my $text_ref = ref($text) ? $text : \$text;
    $http_message->content_type($content_type);

    if(utf8::is_utf8($$text_ref)) {
        my $charset = $http_message->content_type_charset;
        # For UTF-8 we may leave things as-is, binary encoding matches
        unless($charset eq 'UTF-8') {
            $text = encode($charset, $$text_ref, Encode::FB_WARN); # FIXME: maybe throw...
            $text_ref = \$text;
        }
    }

    $http_message->content($$text_ref);
    return;
}



sub serialize_json {
    my $json = shift;

    if(reftype($json) =~ /^(?:HASH|ARRAY)$/) {
        return encode_json($json);    # FIXME rethrow exception as sth better
    }
    elsif(! ref($json) || reftype($json) eq 'SCALAR') {
        return $json;
    }
    else {
        OAuthomatic::Error::Generic->throw(
           ident => "Can not serialize to JSON",
           extra => "Provided type is neither hash/array ref, nor already serialized string");
    }
    return;
}


sub fill_httpmsg_json {
    my ($http_message, $json) = @_;

    fill_httpmsg_text($http_message, serialize_json($json), "application/json; charset=utf-8");
    return;
}


sub parse_http_msg_json {
    my ($http_message, $force) = @_;

    my $content_type = $http_message->content_type;
    # my $charset = $http_message->content_type_charset;

    unless( $force || $content_type =~ m{^(application/(?:x-)?json|text/plain)$}x ) {
        return;
    }

    # FIXME: throw sensible exceptions on errors (preserve object...)
    # FIXME: isn't charset needed here?
    return from_json($http_message->decoded_content);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::Internal::Util - internal helper routines (form parsing and filling)

=head1 VERSION

version 0.0201

=head1 DESCRIPTION

Internally used by L<OAuthomatic>

=head1 EXPORTS FUNCTIONS

=head2 fill_httpmsg_form($http_message, $params)

Serializes $params (dict ref) as form data and sets $http_message (HTTP::Request or HTTP::Response)
content with that data.

=head2 parse_http_msg_form($http_message, $:force_form)

Parses content as message, returns hashref (empty if parsing failed,
content type is not parseable etc). Supports a few content types (as
HTTP::Body).

With $force_form parses also things with incorrect content type.

=head2 fill_httpmsg_text($http_message, $text, $content_type)

Fills given HTTP::Message content with given text, using encoding
specified inside content type to serialize if text is provided as perl
unicode string (and appending text as is if it is binary string).

Set's also content_type (here it should be full, with charset).

$text can also be specified as reference to string.

=head2 serialize_json($json)

Serializes JSON to utf-8 encoded string.  If $json is already string or string-ref, leaves it as is.

Function defined to keep conventions in one place.

=head2 fill_httpmsg_json($http_message, $json)

Serializes $params (dict ref) as json data and sets $http_message
(HTTP::Request or HTTP::Response) content with that data.

In case $json is already scalar or scalar ref, passes it on assuming
it is already serialized.

=head2 parse_http_msg_json($http_message, $:force)

Parses content as message, returns hashref (empty if parsing failed,
content type is not parseable etc). 

With $force parses also things with incorrect content type.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
