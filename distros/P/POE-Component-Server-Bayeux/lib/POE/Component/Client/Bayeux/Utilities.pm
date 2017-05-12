package POE::Component::Client::Bayeux::Utilities;

use strict;
use warnings;
use JSON::Any;
use base qw(Exporter);

our @EXPORT_OK = qw(decode_json_response);

my $json_any = JSON::Any->new();

sub decode_json_response {
    my ($response) = @_;

    my $content = $response->content;
    if ($response->content_type eq 'text/json-comment-filtered') {
        $content =~ s{^\s* /\* \s* (.+?) \s* \*/ \s*$}{$1}x;
    }

    my $object;
    eval {
        $object = $json_any->decode($content);
    };
    if ($@) {
        die "Failed to JSON decode data (error $@).  Content:\n" . $content;
    }

    return $object;
}

1;
