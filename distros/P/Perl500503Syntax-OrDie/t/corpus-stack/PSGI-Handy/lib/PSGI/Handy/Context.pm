package PSGI::Handy::Context;
######################################################################
#
# PSGI::Handy::Context - per-request context object for Perl 5.5.3+
#
# Passed as the single argument to every route handler. Gives access to
# the request, the matched path parameters, a per-request stash, the
# injected database handle, response shortcuts, and template rendering.
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
use PSGI::Handy::Response;

sub new {
    my ($class, %args) = @_;
    my $self = {
        app    => $args{app},
        req    => $args{req},
        params => (defined $args{params} ? $args{params} : {}),
        stash  => {},
    };
    return bless $self, $class;
}

# --- accessors --------------------------------------------------------
sub req {
    my $self = shift;
    return $self->{req};
}

sub app {
    my $self = shift;
    return $self->{app};
}

# All matched path parameters (hash reference).
sub params {
    my $self = shift;
    return $self->{params};
}

# A single value: a matched path parameter wins over query/body params.
sub param {
    my ($self, $name) = @_;
    return undef unless defined $name;
    return $self->{params}{$name} if exists $self->{params}{$name};
    return $self->{req}->param($name);
}

# The injected database handle (whatever was passed to PSGI::Handy->new).
sub db {
    my $self = shift;
    return $self->{app}->db;
}

# Configuration: $c->config or $c->config($key)
sub config {
    my ($self, $key) = @_;
    return $self->{app}->config($key);
}

# --- stash ------------------------------------------------------------
#   $c->stash                 -> hashref of everything
#   $c->stash('key')          -> one value
#   $c->stash(k1 => v1, ...)  -> set, returns $c
sub stash {
    my $self = shift;
    return $self->{stash} if @_ == 0;
    return $self->{stash}{ $_[0] } if @_ == 1;
    my %kv = @_;
    my $k;
    for $k (keys %kv) {
        $self->{stash}{$k} = $kv{$k};
    }
    return $self;
}

# --- response shortcuts (return a PSGI::Handy::Response object) -------
sub html     { my $self = shift; return PSGI::Handy::Response->html(@_); }
sub text     { my $self = shift; return PSGI::Handy::Response->text(@_); }
sub json     { my $self = shift; return PSGI::Handy::Response->json(@_); }
sub redirect { my $self = shift; return PSGI::Handy::Response->redirect(@_); }
sub res      { my $self = shift; return PSGI::Handy::Response->new(@_); }

# --- template rendering ----------------------------------------------
# Uses the renderer injected into PSGI::Handy->new(renderer => ...).
# The renderer is either:
#   - a CODE reference: $renderer->($template, \%vars) -> string
#   - an object with a render() method: $r->render($template, \%vars)
# Stash values are passed to the template, overridden by $vars.
# Returns a PSGI::Handy::Response (text/html).
sub render {
    my ($self, $template, $vars) = @_;
    my $renderer = $self->{app}->renderer;
    defined $renderer
        or croak "render: no renderer configured (pass renderer => ... to PSGI::Handy->new)";

    my %merged = %{ $self->{stash} };
    if ($vars) {
        my $k;
        for $k (keys %$vars) {
            $merged{$k} = $vars->{$k};
        }
    }

    my $out;
    if (ref($renderer) eq 'CODE') {
        $out = $renderer->($template, \%merged);
    }
    elsif (ref($renderer) && UNIVERSAL::can($renderer, 'render')) {
        $out = $renderer->render($template, \%merged);
    }
    else {
        croak "render: renderer must be a code reference or an object with a render() method";
    }

    my $body = defined $out ? "$out" : '';
    return PSGI::Handy::Response->html($body);
}

1;

__END__

=head1 NAME

PSGI::Handy::Context - per-request context object for Perl 5.5.3 and later

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    $app->get('/users/:id', sub {
        my $c = shift;
        my $id  = $c->param('id');          # path parameter
        my $dbh = $c->db;                    # injected database handle
        $c->stash(title => "User $id");
        return $c->render('user.html', { id => $id });
    });

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</DIAGNOSTICS>

=back

=head1 DESCRIPTION

A PSGI::Handy::Context is handed to every route handler as its single
argument. It exposes the request (C<req>), matched path parameters
(C<param>, C<params>), a per-request C<stash>, the injected database
handle (C<db>), configuration (C<config>), response builders (C<html>,
C<text>, C<json>, C<redirect>, C<res>), and template rendering
(C<render>).

=head1 DIAGNOSTICS

=over 4

=item C<render: no renderer configured (pass renderer => ... to PSGI::Handy->new)>

C<render> was called but no renderer was injected into the application.

=item C<render: renderer must be a code reference or an object with a render() method>

The configured renderer is neither a CODE reference nor an object with a C<render> method.

=back

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is distributed under the same terms as Perl itself.

=cut
