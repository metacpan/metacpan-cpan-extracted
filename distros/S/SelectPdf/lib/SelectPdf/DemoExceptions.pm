package SelectPdf::DemoException;

use strict;
use overload
    '""' => sub { $_[0]->message() },
    'bool' => sub { 1 },
    fallback => 1;

our $VERSION = '1.6.0';

# Default upgrade URL displayed in demo-mode error messages.
use constant UPGRADE_URL => "https://selectpdf.com/pricing/";

=head1 NAME

SelectPdf::DemoException - Base class for the typed errors raised by the keyless demo endpoint.

=head1 SYNOPSIS

The demo endpoint (used when C<SelectPdf::HtmlToPdfClient> is constructed without an API key) reports
rate limits, rejected URLs and unsupported features as structured JSON. The client turns those into
exception objects that are thrown with C<die>. They stringify to a readable message, so code that only
prints C<$@> keeps working, and they can be inspected programmatically:

    use SelectPdf;

    eval {
        my $client = SelectPdf::HtmlToPdfClient->new(); # keyless demo mode
        $client->convertUrlToFile("https://selectpdf.com", "Test.pdf");
    };

    if (my $err = $@) {
        if (ref $err && $err->isa('SelectPdf::DemoRateLimitException')) {
            # reason is one of: per_ip, daily_cap, concurrency
            print "Demo rate limit (" . $err->reason() . "). Retry after " . $err->retryAfter() . "s. Upgrade: " . $err->upgradeUrl() . "\n";
        }
        elsif (ref $err && $err->isa('SelectPdf::DemoSafetyException')) {
            print "Demo safety guard rejected '" . $err->field() . "' (reason=" . $err->reason() . ").\n";
        }
        elsif (ref $err && $err->isa('SelectPdf::DemoUnsupportedException')) {
            print "Feature '" . $err->field() . "' not available in demo mode. Upgrade: " . $err->upgradeUrl() . "\n";
        }
        else {
            print "An error occurred: $err\n";
        }
    }

The classes are:

=over

=item * C<SelectPdf::DemoRateLimitException> - HTTP 429 or 503, the demo rate limit was reached.

=item * C<SelectPdf::DemoSafetyException> - HTTP 400, a URL field references a non-public host.

=item * C<SelectPdf::DemoUnsupportedException> - HTTP 400 (or raised locally before the request is sent), the feature is not available in demo mode.

=back

All of them derive from C<SelectPdf::DemoException>.

=head1 METHODS

=head2 message

The error message. The object also stringifies to this message.

=head2 statusCode

HTTP status code returned by the server. Zero for a C<SelectPdf::DemoUnsupportedException> raised by the local client guard before the request was sent.

=head2 responseBody

The raw JSON body the server returned, for diagnostics / logging. Undef when the exception was raised by the local client guard.

=cut
sub _new {
    my($type, %args) = @_;
    my $self = { %args };
    bless $self, $type;
    return $self;
}

sub message {
    my($self) = @_;
    return $self->{message};
}

sub statusCode {
    my($self) = @_;
    return $self->{statusCode};
}

sub responseBody {
    my($self) = @_;
    return $self->{responseBody};
}

# Build the typed demo exception that corresponds to a JSON error body returned by the API,
# exactly as the .NET client does (TryBuildDemoException):
#   {"error":"rate_limited","reason":"per_ip","upgrade":"..."}               -> SelectPdf::DemoRateLimitException
#   {"error":"unsafe_url","field":"url","reason":"private_ip"}               -> SelectPdf::DemoSafetyException
#   {"error":"unsupported_in_demo","field":"user_password","upgrade":"..."}  -> SelectPdf::DemoUnsupportedException
#   {"error":"body_too_large","max_bytes":1048576,"upgrade":"..."}           -> plain error message (string)
#
# Returns the exception (object or string) or undef if the body is not a recognized demo error.
sub fromResponse {
    my($class, $statusCode, $body, $retryAfter) = @_;

    return undef if (not defined($body) or $body eq "");

    my $json = eval {
        require JSON;
        JSON->new->allow_nonref->decode($body);
    };
    return undef if (not defined($json) or ref($json) ne 'HASH');

    my $error = _stringField($json, "error");
    return undef if (not defined($error) or $error eq "");

    my $reason = _stringField($json, "reason");
    my $field = _stringField($json, "field");
    my $upgrade = _stringField($json, "upgrade");

    $retryAfter = 0 if (not defined($retryAfter) or $retryAfter !~ m/^\s*\d+\s*$/);
    $retryAfter = int($retryAfter);

    if ($error eq "rate_limited") {
        return SelectPdf::DemoRateLimitException->new($statusCode, $reason, $retryAfter, $upgrade, $body);
    }
    elsif ($error eq "unsafe_url") {
        return SelectPdf::DemoSafetyException->new($statusCode, $field, $reason, $body);
    }
    elsif ($error eq "unsupported_in_demo") {
        return SelectPdf::DemoUnsupportedException->new($statusCode, $field, $upgrade, $body);
    }
    elsif ($error eq "body_too_large") {
        return sprintf("(%s) Demo request body exceeds the demo cap. Upgrade at %s.",
            $statusCode, (defined($upgrade) ? $upgrade : UPGRADE_URL));
    }

    return undef;
}

sub _stringField {
    my($json, $name) = @_;
    my $value = $json->{$name};
    return undef if (not defined($value) or ref($value));
    return "$value";
}

package SelectPdf::DemoRateLimitException;

use strict;
our @ISA = qw(SelectPdf::DemoException);

=head1 NAME

SelectPdf::DemoRateLimitException - Thrown when the demo endpoint refuses a request because of a rate limit (HTTP 429 or 503).

=head1 METHODS

=head2 statusCode

HTTP status code returned by the server (429 or 503).

=head2 reason

Machine-readable rate-limit reason: C<per_ip> (the source IP exceeded its hourly conversion budget),
C<concurrency> (too many demo conversions are running right now) or C<daily_cap> (the global demo budget for today has been reached).

=head2 retryAfter

Seconds the client should wait before retrying (parsed from the C<Retry-After> response header). Zero if absent.

=head2 upgradeUrl

URL the user can visit to upgrade out of demo mode.

=head2 responseBody

The raw JSON body the server returned.

=cut
sub new {
    my($type, $statusCode, $reason, $retryAfter, $upgradeUrl, $body) = @_;

    my $upgrade = (defined($upgradeUrl) and $upgradeUrl ne "") ? $upgradeUrl : SelectPdf::DemoException::UPGRADE_URL;
    $retryAfter = 0 if (not defined($retryAfter));
    my $ra = $retryAfter > 0 ? sprintf(" Retry after %ss.", $retryAfter) : "";

    return $type->SUPER::_new(
        message => sprintf("(%s) Demo rate limit reached (reason=%s).%s Upgrade at %s.",
            $statusCode, (defined($reason) ? $reason : "?"), $ra, $upgrade),
        statusCode => $statusCode,
        reason => (defined($reason) ? $reason : ""),
        retryAfter => $retryAfter,
        upgradeUrl => $upgrade,
        responseBody => $body,
    );
}

sub reason {
    my($self) = @_;
    return $self->{reason};
}

sub retryAfter {
    my($self) = @_;
    return $self->{retryAfter};
}

sub upgradeUrl {
    my($self) = @_;
    return $self->{upgradeUrl};
}

package SelectPdf::DemoSafetyException;

use strict;
our @ISA = qw(SelectPdf::DemoException);

=head1 NAME

SelectPdf::DemoSafetyException - Thrown when the demo safety guard rejects a request because a URL field references a non-public host (HTTP 400).

=head1 METHODS

=head2 statusCode

HTTP status code returned by the server (400).

=head2 field

Which input field was rejected: C<url>, C<html>, C<base_url>, C<header_url>, C<footer_url>.

=head2 reason

Why the field was rejected: C<blocked_host>, C<private_ip>, C<loopback>, C<link_local>, C<cgnat>, C<metadata>, C<multicast>,
C<bad_scheme>, C<bad_url>, C<inline_internal_ref:E<lt>sub-reasonE<gt>>.

=head2 responseBody

The raw JSON body the server returned.

=cut
sub new {
    my($type, $statusCode, $field, $reason, $body) = @_;

    return $type->SUPER::_new(
        message => sprintf("(%s) Demo safety guard rejected %s (reason=%s). Demo conversions cannot fetch internal/private hosts.",
            $statusCode, (defined($field) ? $field : "?"), (defined($reason) ? $reason : "?")),
        statusCode => $statusCode,
        field => (defined($field) ? $field : ""),
        reason => (defined($reason) ? $reason : ""),
        responseBody => $body,
    );
}

sub field {
    my($self) = @_;
    return $self->{field};
}

sub reason {
    my($self) = @_;
    return $self->{reason};
}

package SelectPdf::DemoUnsupportedException;

use strict;
our @ISA = qw(SelectPdf::DemoException);

=head1 NAME

SelectPdf::DemoUnsupportedException - Thrown when the caller tried to use a feature that demo mode does not support,
most commonly PDF passwords (HTTP 400). For paid keys, this exception is never thrown.

=head1 METHODS

=head2 statusCode

HTTP status code returned by the server (400). Zero if the exception was raised by the local client guard before the request was sent.

=head2 field

Which feature is unsupported: C<user_password>, C<owner_password>, C<async>.

=head2 upgradeUrl

URL the user can visit to upgrade out of demo mode.

=head2 responseBody

The raw JSON body the server returned. Undef when raised by the local client guard.

=cut
sub new {
    my($type, $statusCode, $field, $upgradeUrl, $body) = @_;

    my $upgrade = (defined($upgradeUrl) and $upgradeUrl ne "") ? $upgradeUrl : SelectPdf::DemoException::UPGRADE_URL;

    return $type->SUPER::_new(
        message => sprintf("(%s) Feature '%s' is not available in demo mode. Upgrade at %s.",
            $statusCode, (defined($field) ? $field : "?"), $upgrade),
        statusCode => $statusCode,
        field => (defined($field) ? $field : ""),
        upgradeUrl => $upgrade,
        responseBody => $body,
    );
}

# Constructor used by the local client-side guard before the request is sent.
sub newLocal {
    my($type, $field) = @_;

    return $type->SUPER::_new(
        message => sprintf("Feature '%s' is not available in demo mode. Construct SelectPdf::HtmlToPdfClient with a paid API key, or upgrade at %s.",
            (defined($field) ? $field : "?"), SelectPdf::DemoException::UPGRADE_URL),
        statusCode => 0,
        field => (defined($field) ? $field : ""),
        upgradeUrl => SelectPdf::DemoException::UPGRADE_URL,
        responseBody => undef,
    );
}

sub field {
    my($self) = @_;
    return $self->{field};
}

sub upgradeUrl {
    my($self) = @_;
    return $self->{upgradeUrl};
}

1;
