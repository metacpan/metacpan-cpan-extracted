package Net::OpenStack::Swift::Util;

use strict;
use warnings;
use Encode;
use URI::Escape qw//;
use Log::Minimal qw//;
use Exporter 'import';
our @EXPORT_OK = qw(uri_escape uri_unescape debugf);


sub uri_escape {
    my $value = shift;
    if (utf8::is_utf8($value)) {
        return URI::Escape::uri_escape_utf8($value);
    }
    else {
        return URI::Escape::uri_escape($value);
    }
}

sub uri_unescape {
    my $value = shift;
    return URI::Escape::uri_unescape($value);
}

sub debugf {
    my ($message, $value) = @_;
    local $Log::Minimal::TRACE_LEVEL = 1;
    local $Log::Minimal::AUTODUMP    = 1;
    Log::Minimal::debugf($message, $value);
}

1;
