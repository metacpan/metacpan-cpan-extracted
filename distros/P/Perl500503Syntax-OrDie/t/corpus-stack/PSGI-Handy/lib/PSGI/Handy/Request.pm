package PSGI::Handy::Request;
######################################################################
#
# PSGI::Handy::Request - tiny PSGI env wrapper for Perl 5.5.3+
#
# Wraps a PSGI %env and exposes method, path, query/body parameters
# (merged), headers, cookies and the raw body. Query- and body-parameter
# parsing and percent-decoding are implemented here in pure Perl, so this
# module has no dependencies outside the Perl core.
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

# --------------------------------------------------------------------
# new($env) - wrap a PSGI environment hash reference
# --------------------------------------------------------------------
sub new {
    my ($class, $env) = @_;
    ref($env) eq 'HASH' or croak "new: a PSGI env hash reference is required";
    my $self = { env => $env };
    return bless $self, $class;
}

# --- request line -----------------------------------------------------
sub method {
    my $self = shift;
    my $m = $self->{env}{REQUEST_METHOD};
    return defined $m ? $m : '';
}

sub path {
    my $self = shift;
    my $p = $self->{env}{PATH_INFO};
    return defined $p ? $p : '';
}

sub query_string {
    my $self = shift;
    my $q = $self->{env}{QUERY_STRING};
    return defined $q ? $q : '';
}

sub content_type {
    my $self = shift;
    my $t = $self->{env}{CONTENT_TYPE};
    return defined $t ? $t : '';
}

sub content_length {
    my $self = shift;
    my $l = $self->{env}{CONTENT_LENGTH};
    return (defined $l && $l ne '') ? int($l) : 0;
}

sub env {
    my $self = shift;
    return $self->{env};
}

# --- headers ----------------------------------------------------------
# Accepts 'Content-Type', 'content_type', 'X-Forwarded-For', etc.
sub header {
    my ($self, $name) = @_;
    return undef unless defined $name;
    my $key = uc($name);
    $key =~ s/-/_/g;
    if ($key eq 'CONTENT_TYPE' || $key eq 'CONTENT_LENGTH') {
        return $self->{env}{$key};
    }
    return $self->{env}{'HTTP_' . $key};
}

# --- raw body (read once from psgi.input, then cached) ---------------
sub body {
    my $self = shift;
    return $self->{_body} if exists $self->{_body};
    my $buf = '';
    my $len = $self->content_length;
    my $input = $self->{env}{'psgi.input'};
    if ($len > 0 && $input) {
        # psgi.input->read may return fewer bytes than requested, so loop
        # until CONTENT_LENGTH bytes are read or the stream ends.
        my $chunk;
        my $got = 0;
        while ($got < $len) {
            my $n = $input->read($chunk, $len - $got);
            last unless $n;        # EOF or error: keep what we have
            $buf .= $chunk;
            $got += $n;
        }
    }
    $self->{_body} = $buf;
    return $buf;
}

# --- parameters (query string merged with urlencoded body) -----------
sub param {
    my ($self, $name) = @_;
    $self->_build_params;
    return undef unless defined $name;
    my $v = $self->{_params}{$name};
    return undef unless $v;
    return $v->[0];
}

sub param_all {
    my ($self, $name) = @_;
    $self->_build_params;
    return () unless defined $name;
    my $v = $self->{_params}{$name};
    return () unless $v;
    return @$v;
}

sub param_names {
    my $self = shift;
    $self->_build_params;
    return keys %{ $self->{_params} };
}

# Flat hash reference: name => first value.
sub params {
    my $self = shift;
    $self->_build_params;
    my %flat;
    my $k;
    for $k (keys %{ $self->{_params} }) {
        $flat{$k} = $self->{_params}{$k}[0];
    }
    return { %flat };
}

# --- cookies ----------------------------------------------------------
sub cookie {
    my ($self, $name) = @_;
    $self->_parse_cookies;
    return undef unless defined $name;
    return $self->{_cookies}{$name};
}

sub cookies {
    my $self = shift;
    $self->_parse_cookies;
    my %copy = %{ $self->{_cookies} };
    return { %copy };
}

# --- internals --------------------------------------------------------
sub _build_params {
    my $self = shift;
    return if $self->{_params};
    my %merged;

    my %q = _parse_query($self->query_string);
    _merge_into(\%merged, { %q });

    my $method = uc($self->method);
    my $ct     = $self->content_type;
    if (($method eq 'POST' || $method eq 'PUT' || $method eq 'PATCH')
        && $ct =~ m{\Aapplication/x-www-form-urlencoded}i) {
        my %p = _parse_query($self->body);
        _merge_into(\%merged, { %p });
    }

    $self->{_params} = \%merged;
}

# Normalise parse_query output (scalar or arrayref values) into a store
# whose values are always array references, appending on duplicate keys.
sub _merge_into {
    my ($merged, $parsed) = @_;
    my $k;
    for $k (keys %$parsed) {
        my $v = $parsed->{$k};
        my @vals = (ref($v) eq 'ARRAY') ? @$v : ($v);
        if ($merged->{$k}) {
            push @{ $merged->{$k} }, @vals;
        }
        else {
            $merged->{$k} = [ @vals ];
        }
    }
}

# --- pure-Perl query parsing and percent-decoding -------------------
# Parse an application/x-www-form-urlencoded string into a hash whose
# values are array references (so repeated keys are preserved in order).
# '+' becomes a space and %XX byte escapes are decoded.
sub _parse_query {
    my ($string) = @_;
    my %out;
    return %out unless defined $string && length $string;
    my $pair;
    for $pair (split /&/, $string) {
        next if $pair eq '';
        my ($k, $v) = split /=/, $pair, 2;
        next unless defined $k;
        $v = defined $v ? $v : '';
        $k = _url_decode($k);
        $v = _url_decode($v);
        if ($out{$k}) { push @{ $out{$k} }, $v; }
        else          { $out{$k} = [ $v ]; }
    }
    return %out;
}

# Percent-decode one form-encoded token. 5.005_03 safe: tr///, s///e with
# chr/hex, and $1 only (no //, no \x{...}, no @- / @+).
sub _url_decode {
    my ($s) = @_;
    return '' unless defined $s;
    $s =~ tr/+/ /;
    $s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return $s;
}

sub _parse_cookies {
    my $self = shift;
    return if $self->{_cookies};
    my %c;
    my $raw = $self->{env}{HTTP_COOKIE};
    if (defined $raw && $raw ne '') {
        my $pair;
        for $pair (split /;\s*/, $raw) {
            my ($k, $v) = split /=/, $pair, 2;
            next unless defined $k;
            $k =~ s/\A\s+//;
            $k =~ s/\s+\z//;
            $v = defined $v ? $v : '';
            $c{$k} = _url_decode($v);
        }
    }
    $self->{_cookies} = { %c };
}

1;

__END__

=head1 NAME

PSGI::Handy::Request - tiny PSGI env wrapper for Perl 5.5.3 and later

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use PSGI::Handy::Request;

    my $req = PSGI::Handy::Request->new($env);

    my $method = $req->method;          # 'GET'
    my $path   = $req->path;            # '/users/42'
    my $id     = $req->param('id');     # query or urlencoded body
    my @tags   = $req->param_all('tag');# multi-value field
    my $ua     = $req->header('User-Agent');
    my $sid    = $req->cookie('sid');
    my $raw    = $req->body;            # raw request body

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</METHODS>

=item * L</DIAGNOSTICS>

=back

=head1 DESCRIPTION

PSGI::Handy::Request wraps a PSGI environment and provides convenient
read access to the request. Query-string and
C<application/x-www-form-urlencoded> body parameters are parsed in pure
Perl and merged (body values appended after query values); multi-value
fields are available through C<param_all>. C<multipart/form-data> is not
parsed in this version; use C<body> for the raw payload.

=head1 METHODS

new, method, path, query_string, content_type, content_length, env,
header, body, param, param_all, param_names, params, cookie,
cookies.

=head1 DIAGNOSTICS

=over 4

=item C<new: a PSGI env hash reference is required>

C<new> was called without a PSGI environment hash reference.

=back

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is distributed under the same terms as Perl itself.

=cut
