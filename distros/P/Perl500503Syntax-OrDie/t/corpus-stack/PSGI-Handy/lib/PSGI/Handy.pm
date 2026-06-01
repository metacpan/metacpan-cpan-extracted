package PSGI::Handy;
######################################################################
#
# PSGI::Handy - a tiny dependency-free PSGI web framework for Perl 5.005_03+
#
# Glues together a router, request/response objects and a per-request
# context into a single PSGI-subset application. Templates (HP::Handy)
# and a database handle (DB::Handy) are injected, keeping this layer
# decoupled and testable.
#
# PSGI::Handy builds the PSGI $app via to_app(); you serve it with any
# PSGI server (for example HTTP::Handy). This module loads nothing
# outside the Perl core.
#
# 5.005_03 safe: no //, say, state, our, 3-arg open, lexical FH, and no
# named regex captures anywhere in the distribution.
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
use PSGI::Handy::Router;
use PSGI::Handy::Request;
use PSGI::Handy::Response;
use PSGI::Handy::Context;

# --------------------------------------------------------------------
# new(%args)
#   renderer  => CODE or object with render()   (for $c->render)
#   db        => any database handle            (for $c->db)
#   config    => hash reference                 (for $c->config)
#   not_found => CODE handler for 404           (optional)
# --------------------------------------------------------------------
sub new {
    my ($class, %args) = @_;
    my $self = {
        router    => PSGI::Handy::Router->new,
        renderer  => $args{renderer},
        db        => $args{db},
        config    => (defined $args{config} ? $args{config} : {}),
        not_found => $args{not_found},
        before    => [],
        after     => [],
    };
    return bless $self, $class;
}

# --- injected dependencies (getters / setters) ----------------------
sub renderer {
    my $self = shift;
    $self->{renderer} = shift if @_;
    return $self->{renderer};
}

sub db {
    my $self = shift;
    $self->{db} = shift if @_;
    return $self->{db};
}

sub config {
    my ($self, $key) = @_;
    return $self->{config} unless defined $key;
    return $self->{config}{$key};
}

sub router {
    my $self = shift;
    return $self->{router};
}

# --- route registration ---------------------------------------------
sub route {
    my ($self, $method, $pattern, $handler) = @_;
    $self->{router}->add($method, $pattern, $handler);
    return $self;
}

sub get   { my $self = shift; return $self->route('GET',    @_); }
sub post  { my $self = shift; return $self->route('POST',   @_); }
sub put   { my $self = shift; return $self->route('PUT',    @_); }
sub patch { my $self = shift; return $self->route('PATCH',  @_); }
sub del   { my $self = shift; return $self->route('DELETE', @_); }
sub head  { my $self = shift; return $self->route('HEAD',   @_); }

# Register a handler for every common method.
sub any {
    my ($self, $pattern, $handler) = @_;
    my $m;
    for $m (qw(GET POST PUT PATCH DELETE HEAD OPTIONS)) {
        $self->{router}->add($m, $pattern, $handler);
    }
    return $self;
}

# --- hooks ------------------------------------------------------------
# before($c): return a Response/arrayref to short-circuit, else nothing.
# after($c, $out): return a value to replace $out, else it is unchanged.
sub before {
    my ($self, $code) = @_;
    ref($code) eq 'CODE' or croak "before: a code reference is required";
    push @{ $self->{before} }, $code;
    return $self;
}

sub after {
    my ($self, $code) = @_;
    ref($code) eq 'CODE' or croak "after: a code reference is required";
    push @{ $self->{after} }, $code;
    return $self;
}

# --- build the PSGI application -------------------------------------
sub to_app {
    my $self = shift;
    return sub {
        my $env = shift;
        return $self->_dispatch($env);
    };
}

# --------------------------------------------------------------------
# _dispatch - turn one PSGI env into one PSGI response
# --------------------------------------------------------------------
sub _dispatch {
    my ($self, $env) = @_;
    my $req    = PSGI::Handy::Request->new($env);
    my $method = uc($req->method);
    my $path   = $req->path;

    my $found = $self->{router}->match($method, $path);
    if ($method eq 'HEAD' && !($found && $found->{handler})) {
        my $g = $self->{router}->match('GET', $path);    # HEAD falls back to GET
        $found = $g if $g && $g->{handler};
    }

    my $c = PSGI::Handy::Context->new(
        app    => $self,
        req    => $req,
        params => ($found && $found->{params}) ? $found->{params} : {},
    );

    my $out;
    if ($found && $found->{handler}) {
        my $short = $self->_run_before($c);
        if (defined $short) {
            $out = $short;
        }
        else {
            $out = eval { $found->{handler}->($c) };
            if ($@) {
                _log_error($env, $@);
                $out = PSGI::Handy::Response->text('Internal Server Error', 500);
            }
        }
    }
    elsif ($found && $found->{allowed}) {
        my @allow = _augment_allowed($found->{allowed});
        if ($method eq 'OPTIONS') {
            # No explicit OPTIONS route: answer the preflight ourselves.
            $out = PSGI::Handy::Response->text('', 204)
                     ->set_header('Allow', join(', ', @allow));
        }
        else {
            $out = PSGI::Handy::Response->text('Method Not Allowed', 405)
                     ->set_header('Allow', join(', ', @allow));
        }
    }
    else {
        $out = $self->_handle_not_found($c, $env);
    }

    $out = $self->_run_after($c, $out);

    my $psgi = $self->_finalize_output($out);

    # Correct HEAD semantics: keep headers (incl. Content-Length), drop body.
    if ($method eq 'HEAD') {
        return [ $psgi->[0], $psgi->[1], [] ];
    }
    return $psgi;
}

sub _handle_not_found {
    my ($self, $c, $env) = @_;
    if ($self->{not_found}) {
        my $out = eval { $self->{not_found}->($c) };
        if ($@) {
            _log_error($env, $@);
            return PSGI::Handy::Response->text('Not Found', 404);
        }
        return defined $out ? $out : PSGI::Handy::Response->text('Not Found', 404);
    }
    return PSGI::Handy::Response->text('Not Found', 404);
}

# Augment a router 'allowed' list for the Allow header. HEAD is implied
# wherever GET is served (the dispatcher serves HEAD via the GET handler),
# and OPTIONS is always answerable here. Order is preserved; the two
# implied methods are appended once if missing.
sub _augment_allowed {
    my ($allowed) = @_;
    my %seen;
    my @out;
    my $m;
    for $m (@$allowed) {
        push @out, $m unless $seen{$m}++;
    }
    if ($seen{'GET'} && !$seen{'HEAD'}) {
        push @out, 'HEAD';
        $seen{'HEAD'} = 1;
    }
    unless ($seen{'OPTIONS'}) {
        push @out, 'OPTIONS';
        $seen{'OPTIONS'} = 1;
    }
    return @out;
}

sub _run_before {
    my ($self, $c) = @_;
    my $hook;
    for $hook (@{ $self->{before} }) {
        my $r = $hook->($c);
        return $r if defined $r && ref($r);   # a ref means "use this as the response"
    }
    return undef;
}

sub _run_after {
    my ($self, $c, $out) = @_;
    my $hook;
    for $hook (@{ $self->{after} }) {
        my $r = $hook->($c, $out);
        $out = $r if defined $r;
    }
    return $out;
}

# Accept a Response object, a raw PSGI arrayref, or a plain string.
sub _finalize_output {
    my ($self, $out) = @_;
    if (ref($out) eq 'ARRAY') {
        return $out;
    }
    if (UNIVERSAL::isa($out, 'PSGI::Handy::Response')) {
        return $out->finalize;
    }
    if (!ref($out) && defined $out) {
        return PSGI::Handy::Response->html($out)->finalize;
    }
    return PSGI::Handy::Response->text('Internal Server Error', 500)->finalize;
}

sub _log_error {
    my ($env, $msg) = @_;
    my $fh = $env->{'psgi.errors'};
    return unless $fh;
    print {$fh} "[PSGI::Handy] handler error: $msg\n";
}

1;

__END__

=head1 NAME

PSGI::Handy - a tiny dependency-free PSGI web framework for Perl 5.005_03 and later

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use PSGI::Handy;

    my $app = PSGI::Handy->new(
        renderer => \&my_template_renderer,   # or an object with render()
        db       => $dbh,                     # any database handle
    );

    $app->get('/', sub {
        my $c = shift;
        return $c->html('<h1>Hello</h1>');
    });

    $app->get('/users/:id', sub {
        my $c = shift;
        return $c->render('user.html', { id => $c->param('id') });
    });

    $app->post('/users', sub {
        my $c = shift;
        my $name = $c->param('name');
        # ... use $c->db ...
        return $c->redirect('/');
    });

    # PSGI::Handy builds the PSGI app; serve it with any PSGI server:
    my $psgi_app = $app->to_app;   # sub { my $env = shift; ... }

    # for example, with HTTP::Handy as the delivery layer:
    use HTTP::Handy;
    HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</METHODS>

=item * L</DIAGNOSTICS>

=item * L</LIMITATIONS>

=item * L</SEE ALSO>

=back

=head1 DESCRIPTION

PSGI::Handy is the application layer of the "Handy" stack. It wires a
L<PSGI::Handy::Router>, L<PSGI::Handy::Request>,
L<PSGI::Handy::Response> and L<PSGI::Handy::Context> into a single
PSGI-subset C<$app> through C<to_app>. Templates and a database handle
are injected at construction time, so the framework loads nothing
outside the Perl core and stays easy to test. You serve the resulting
C<$app> with any PSGI server, such as L<HTTP::Handy>.

Every handler receives a L<PSGI::Handy::Context> and may return a
Response object, a raw PSGI array reference, or a plain string (treated
as an HTML 200 response).

=head1 METHODS

new, renderer, db, config, router, route, get, post, put, patch, del,
head, any, before, after, to_app.

Routing details (named C<:params>, trailing C<*>, exact matching, 405
handling) are documented in L<PSGI::Handy::Router>.

=head1 DIAGNOSTICS

=over 4

=item C<before: a code reference is required>

The argument to C<before> was not a CODE reference.

=item C<after: a code reference is required>

The argument to C<after> was not a CODE reference.

=back

=head1 LIMITATIONS

The C<$app> returned by C<to_app> always produces the buffered,
three-element PSGI response C<[ $status, \@headers, \@body ]>. The PSGI
delayed-response form (the streaming "responder" callback) is not
generated; this is what "PSGI-subset" means throughout this distribution.

Concurrency and the HTTP version depend on the PSGI server you choose.
No multipart uploads or WebSocket in this version. C<HEAD> requests are
served by the matching C<GET> route with the body removed.

=head1 SEE ALSO

L<HTTP::Handy>, L<HP::Handy>, L<PSGI::Handy::Router>,
L<PSGI::Handy::Request>, L<PSGI::Handy::Response>,
L<PSGI::Handy::Context>

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is distributed under the same terms as Perl itself.

=cut
