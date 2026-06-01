package PSGI::Handy::Response;
######################################################################
#
# PSGI::Handy::Response - tiny PSGI response builder for Perl 5.5.3+
#
# Builds the PSGI three-element response [ $status, \@headers, \@body ]
# with an incremental, chainable API plus class shortcuts for the common
# response types (text, html, json, redirect).
#
# 5.005_03 safe: no //, say, state, our, 3-arg open, lexical FH.
#
######################################################################
use 5.00503;    # Universal Consensus 1998 for primetools
                # Perl 5.005_03 compatibility for historical toolchains
# use 5.008001; # Lancaster Consensus 2013 for toolchains

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use vars qw($VERSION);
$VERSION = '0.01';
$VERSION = $VERSION;
# $VERSION self-assignment suppresses "used only once" warning under strict.
use Carp;

# Byte-accurate length for Content-Length. The bytes pragma does not exist
# on Perl 5.005_03 (and there are no wide-character strings there), so we
# probe for it once and call bytes::length() as a function (no lexical
# pragma needed) on Perls that have it.
my $HAS_BYTES;
BEGIN { $HAS_BYTES = eval { require bytes; 1 } ? 1 : 0; }

sub _byte_length {
    my ($s) = @_;
    return 0 unless defined $s;
    return $HAS_BYTES ? bytes::length($s) : length($s);
}

# Strip CR/LF from header keys and values to prevent header injection.
sub _crlf_safe {
    my ($s) = @_;
    return $s unless defined $s;
    $s =~ s/[\r\n]//g;
    return $s;
}

# --------------------------------------------------------------------
# new(%args) - status => 200, type => 'text/html; charset=utf-8',
#              body => $scalar_or_arrayref
# --------------------------------------------------------------------
sub new {
    my ($class, %args) = @_;
    my $self = {
        status  => (defined $args{status} ? $args{status} : 200),
        headers => [],                       # list of [ key, value ]
        body    => _body_to_array($args{body}),
    };
    bless $self, $class;
    $self->set_header('Content-Type', $args{type}) if defined $args{type};
    return $self;
}

# --- class shortcuts (return a Response object) ---------------------
sub html {
    my ($class, $str, $code) = @_;
    return $class->new(
        status => (defined $code ? $code : 200),
        type   => 'text/html; charset=utf-8',
        body   => $str,
    );
}

sub text {
    my ($class, $str, $code) = @_;
    return $class->new(
        status => (defined $code ? $code : 200),
        type   => 'text/plain; charset=utf-8',
        body   => $str,
    );
}

# JSON string must already be encoded by the caller (e.g. via mb::JSON).
sub json {
    my ($class, $str, $code) = @_;
    !ref($str)
        or croak "json: body must be a pre-encoded JSON string, not a reference";
    return $class->new(
        status => (defined $code ? $code : 200),
        type   => 'application/json',
        body   => $str,
    );
}

sub redirect {
    my ($class, $location, $code) = @_;
    defined $location or croak "redirect: location is required";
    my $self = $class->new(
        status => (defined $code ? $code : 302),
        type   => 'text/plain; charset=utf-8',
        body   => "Redirect to $location",
    );
    $self->set_header('Location', $location);
    return $self;
}

# --- accessors / mutators (mutators return $self for chaining) ------
sub status {
    my $self = shift;
    return $self->{status};
}

sub set_status {
    my ($self, $code) = @_;
    $self->{status} = $code;
    return $self;
}

sub body {
    my $self = shift;
    return $self->{body};
}

sub set_body {
    my ($self, $content) = @_;
    $self->{body} = _body_to_array($content);
    return $self;
}

# Append a header (allows duplicates, e.g. several Set-Cookie lines).
sub header {
    my ($self, $key, $value) = @_;
    push @{ $self->{headers} }, [ _crlf_safe($key), _crlf_safe($value) ];
    return $self;
}

# Replace any existing header(s) of this name, then set it.
sub set_header {
    my ($self, $key, $value) = @_;
    $key   = _crlf_safe($key);
    $value = _crlf_safe($value);
    my $lc = lc($key);
    my @kept = grep { lc($_->[0]) ne $lc } @{ $self->{headers} };
    push @kept, [ $key, $value ];
    $self->{headers} = [ @kept ];
    return $self;
}

sub remove_header {
    my ($self, $key) = @_;
    my $lc = lc($key);
    $self->{headers} = [ grep { lc($_->[0]) ne $lc } @{ $self->{headers} } ];
    return $self;
}

sub content_type {
    my ($self, $type) = @_;
    return $self->set_header('Content-Type', $type);
}

# Add a Set-Cookie header. %opts: path, domain, max_age, expires,
# secure (bool), httponly (bool).
sub cookie {
    my ($self, $name, $value, %opts) = @_;
    defined $name or croak "cookie: name is required";
    $value = '' unless defined $value;
    my $c = $name . '=' . _cookie_encode($value);
    $c .= '; Path='    . $opts{path}    if defined $opts{path};
    $c .= '; Domain='  . $opts{domain}  if defined $opts{domain};
    $c .= '; Max-Age=' . $opts{max_age} if defined $opts{max_age};
    $c .= '; Expires=' . $opts{expires} if defined $opts{expires};
    $c .= '; Secure'   if $opts{secure};
    $c .= '; HttpOnly' if $opts{httponly};
    return $self->header('Set-Cookie', $c);
}

# --------------------------------------------------------------------
# finalize - produce the PSGI array [ $status, \@flat_headers, \@body ]
# Content-Length is computed from the body unless already present.
# --------------------------------------------------------------------
sub finalize {
    my $self = shift;
    my @flat;
    my $has_length = 0;
    my $pair;
    for $pair (@{ $self->{headers} }) {
        push @flat, $pair->[0], $pair->[1];
        $has_length = 1 if lc($pair->[0]) eq 'content-length';
    }
    unless ($has_length) {
        my $len = 0;
        my $chunk;
        for $chunk (@{ $self->{body} }) {
            $len += _byte_length($chunk);
        }
        push @flat, 'Content-Length', $len;
    }
    return [ $self->{status}, \@flat, [ @{ $self->{body} } ] ];
}

# --- internals ------------------------------------------------------
sub _body_to_array {
    my ($content) = @_;
    return []                  unless defined $content;
    return [ @$content ]       if ref($content) eq 'ARRAY';
    return [ $content ];
}

sub _cookie_encode {
    my ($s) = @_;
    $s =~ s/([^A-Za-z0-9_\-.~])/sprintf('%%%02X', ord($1))/eg;
    return $s;
}

1;

__END__

=head1 NAME

PSGI::Handy::Response - tiny PSGI response builder for Perl 5.5.3 and later

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use PSGI::Handy::Response;

    # class shortcuts
    return PSGI::Handy::Response->html('<h1>Hi</h1>')->finalize;
    return PSGI::Handy::Response->text('plain', 404)->finalize;
    return PSGI::Handy::Response->redirect('/login')->finalize;

    # incremental building
    my $res = PSGI::Handy::Response->new;
    $res->set_status(201)
        ->content_type('text/html; charset=utf-8')
        ->header('X-App', 'PSGI::Handy')
        ->cookie('sid', $id, path => '/', httponly => 1)
        ->set_body($html);
    return $res->finalize;   # [ 201, [...], [ $html ] ]

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</METHODS>

=item * L</DIAGNOSTICS>

=back

=head1 DESCRIPTION

PSGI::Handy::Response represents the response side of the PSGI::Handy
micro framework. C<finalize> returns the PSGI three-element array a
PSGI-subset server such as L<HTTP::Handy> expects. C<Content-Length> is
computed from the body at finalize time unless the caller already set it.

Bodies are expected to be byte strings already in the desired encoding;
the class does no character encoding itself.

=head1 METHODS

new, html, text, json, redirect, status, set_status, body, set_body,
header, set_header, remove_header, content_type, cookie, finalize. See
the SYNOPSIS; mutators return the object for chaining.

=head1 DIAGNOSTICS

=over 4

=item C<redirect: location is required>

C<redirect> was called without a target location.

=item C<json: body must be a pre-encoded JSON string, not a reference>

C<json> was given a reference (array or hash). The body must be a JSON
string that the caller has already encoded (for example with C<mb::JSON>).

=item C<cookie: name is required>

C<cookie> was called without a cookie name.

=back

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is distributed under the same terms as Perl itself.

=cut
