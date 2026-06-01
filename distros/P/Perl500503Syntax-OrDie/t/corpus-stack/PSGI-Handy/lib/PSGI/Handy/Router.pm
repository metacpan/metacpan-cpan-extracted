package PSGI::Handy::Router;
######################################################################
#
# PSGI::Handy::Router - tiny PSGI route dispatcher for Perl 5.5.3+
#
# Maps (HTTP method, PATH_INFO) to a handler code reference, with
# named path parameters (:name) and an optional trailing splat (*).
# Written to run on Perl 5.005_03 and all later versions:
#   - no //, no say, no state, no 3-argument open, no our
#   - no named captures (?<name>) (5.10+); positional captures + a
#     parallel name list are used instead
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
# new - create an empty router
# --------------------------------------------------------------------
sub new {
    my $class = shift;
    my $self = { routes => [] };
    return bless $self, $class;
}

# --------------------------------------------------------------------
# add - register a route
#   $router->add($method, $pattern, $handler);
#   $method  : 'GET', 'POST', ... (case-insensitive, stored upper-case)
#   $pattern : '/users/:id', '/files/*', '/' (must begin with '/')
#   $handler : a CODE reference
# Returns $self for chaining.
# --------------------------------------------------------------------
sub add {
    my ($self, $method, $pattern, $handler) = @_;
    defined $method            or croak "add: method is required";
    defined $pattern           or croak "add: pattern is required";
    ref($handler) eq 'CODE'    or croak "add: handler must be a code reference";
    $pattern =~ m{\A/}         or croak "add: pattern must begin with '/' (got '$pattern')";

    $method = uc($method);
    my ($regex, $names) = _compile($pattern);
    push @{ $self->{routes} }, {
        method  => $method,
        pattern => $pattern,
        regex   => $regex,
        names   => $names,
        handler => $handler,
    };
    return $self;
}

# --------------------------------------------------------------------
# match - look up a route
#   my $r = $router->match($method, $path);
# Returns:
#   - on success           : { handler => CODE, params => HASH }
#   - path matched, method not (405) : { allowed => [ method, ... ] }
#   - no match at all (404) : undef
# First registered matching route wins.
# --------------------------------------------------------------------
sub match {
    my ($self, $method, $path) = @_;
    defined $method or croak "match: method is required";
    defined $path   or croak "match: path is required";
    $method = uc($method);

    my @allowed;
    my $route;
    for $route (@{ $self->{routes} }) {
        my @caps = ($path =~ $route->{regex});
        next unless @caps;                 # this pattern did not match the path

        if ($route->{method} eq $method) {
            my %params;
            my $names = $route->{names};
            my $i;
            for ($i = 0; $i < scalar(@$names); $i++) {
                $params{ $names->[$i] } = $caps[$i];
            }
            return { handler => $route->{handler}, params => { %params } };
        }
        push @allowed, $route->{method};   # remember for a possible 405
    }

    if (@allowed) {
        my %seen;
        my @uniq = grep { !$seen{$_}++ } @allowed;
        return { allowed => \@uniq };
    }
    return undef;
}

# --------------------------------------------------------------------
# routes - return the internal route list (array reference).
# Mainly for introspection and testing.
# --------------------------------------------------------------------
sub routes {
    my $self = shift;
    return $self->{routes};
}

# --------------------------------------------------------------------
# _compile - turn a path pattern into (qr//, \@param_names)
#
# A pattern is split on '/' into segments. Each segment becomes:
#   ':name'  -> ([^/]+)   and records the parameter name 'name'
#   '*' (only as the LAST segment) -> (.*)   recorded as 'splat'
#   anything else -> quotemeta (literal, dots are NOT wildcards)
# The whole thing is anchored with \A ... \z so matching is exact.
# --------------------------------------------------------------------
sub _compile {
    my ($pattern) = @_;
    my @segs = split m{/}, $pattern, -1;   # -1 keeps trailing empty fields
    my @names;
    my @parts;
    my $last = $#segs;
    my $i;
    for ($i = 0; $i <= $last; $i++) {
        my $seg = $segs[$i];
        if ($seg eq '*' && $i == $last) {
            push @parts, '(.*)';
            push @names, 'splat';
        }
        elsif ($seg =~ /\A:([A-Za-z_]\w*)\z/) {
            push @parts, '([^/]+)';
            push @names, $1;
        }
        else {
            push @parts, quotemeta($seg);
        }
    }
    my $source = '\\A' . join('/', @parts) . '\\z';
    my $regex  = qr{$source};
    return ($regex, \@names);
}

1;

__END__

=head1 NAME

PSGI::Handy::Router - tiny PSGI route dispatcher for Perl 5.5.3 and later

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use PSGI::Handy::Router;

    my $router = PSGI::Handy::Router->new;

    $router->add('GET',  '/',            \&home);
    $router->add('GET',  '/users/:id',   \&show_user);
    $router->add('POST', '/users',       \&create_user);
    $router->add('GET',  '/files/*',     \&serve_file);

    my $r = $router->match('GET', '/users/42');
    if ($r && $r->{handler}) {
        # $r->{params} = { id => 42 }
        my $response = $r->{handler}->($env, $r->{params});
    }
    elsif ($r && $r->{allowed}) {
        # path exists but method not allowed -> HTTP 405
        # Allow: join(', ', @{ $r->{allowed} })
    }
    else {
        # no route matched -> HTTP 404
    }

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</METHODS>

=item * L</DIAGNOSTICS>

=item * L</PERL 5.005_03 COMPATIBILITY>

=back

=head1 DESCRIPTION

PSGI::Handy::Router resolves an incoming request, expressed as an HTTP
method and a C<PATH_INFO> string, to a previously registered handler.
It is the routing layer of the PSGI::Handy micro framework and is meant
to feed a single PSGI C<$app> code reference to a PSGI-subset server such
as L<HTTP::Handy>.

It is deliberately small and dependency-free, and is written to run
unchanged on Perl 5.005_03 through current Perl.

=head2 Pattern syntax

=over 4

=item * Literal segments match exactly. A dot is a literal dot, not a
regular-expression wildcard (C</feed.xml> does not match C</feedaxml>).

=item * C<:name> matches a single non-empty path segment (C<[^/]+>) and
stores it in C<params> under C<name>.

=item * A C<*> used as the final segment matches the remainder of the
path, including slashes, and is stored under C<splat>.

=back

Matching is exact (anchored), so a trailing slash is significant:
C</a> and C</a/> are different routes.

=head1 METHODS

=over 4

=item new

Returns a new, empty router.

=item add($method, $pattern, $handler)

Registers a route. C<$handler> must be a code reference. C<$pattern>
must begin with C</>. Returns the router for chaining.

=item match($method, $path)

Returns a hash reference C<{ handler =E<gt> ..., params =E<gt> ... }> on
success, C<{ allowed =E<gt> [...] }> when the path is known but the
method is not (HTTP 405), or C<undef> when nothing matched (HTTP 404).
The first registered matching route wins.

=item routes

Returns the internal array reference of route records. For introspection
and testing.

=back

=head1 DIAGNOSTICS

=over 4

=item C<add: method is required>

C<add> was called without an HTTP method.

=item C<add: pattern is required>

C<add> was called without a path pattern.

=item C<add: handler must be a code reference>

The handler passed to C<add> was not a CODE reference.

=item C<add: pattern must begin with '/' (got '$pattern')>

The path pattern passed to C<add> did not begin with a slash.

=item C<match: method is required>

C<match> was called without an HTTP method.

=item C<match: path is required>

C<match> was called without a path.

=back

=head1 PERL 5.005_03 COMPATIBILITY

No named captures, C<//>, C<say>, C<state>, C<our>, three-argument
C<open>, or lexical file handles are used. Path parameters rely on
positional captures paired with a name list because named captures were
not available until Perl 5.10.

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is distributed under the same terms as Perl itself.

=cut
