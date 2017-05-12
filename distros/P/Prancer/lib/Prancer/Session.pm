package Prancer::Session;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.05';

use Storable qw(dclone);

sub new {
    my ($class, $env) = @_;
    my $self = bless({
        'env' => $env,
        '_session' => $env->{'psgix.session'},
        '_options' => $env->{'psgix.session.options'},
    }, $class);

    return $self;
}

sub id {
    my $self = shift;
    return $self->{'_options'}->{'id'};
}

sub has {
    my ($self, $key) = @_;
    return exists($self->{'_session'}->{$key});
}

sub get {
    my ($self, $key, $default) = @_;

    # only return things if the are running in a non-void context
    if (defined(wantarray())) {
        my $value = undef;

        if (exists($self->{'_session'}->{$key})) {
            $value = $self->{'_session'}->{$key};
        } else {
            $value = $default;
        }

        # nothing to return
        return unless defined($value);

        # make a clone to avoid changing things
        # through inadvertent references.
        $value = dclone($value) if ref($value);

        if (wantarray() && ref($value)) {
            # return a value rather than a reference
            if (ref($value) eq "HASH") {
                return %{$value};
            }
            if (ref($value) eq "ARRAY") {
                return @{$value};
            }
        }

        # return a reference
        return $value;
    }

    return;
}

sub set {
    my ($self, $key, $value) = @_;

    my $old = undef;
    $old = $self->get($key) if defined(wantarray());

    if (ref($value)) {
        # make a copy of the original value to avoid inadvertently changing
        # things via references
        $self->{'_session'}->{$key} = dclone($value);
    } else {
        # can't clone non-references
        $self->{'_session'}->{$key} = $value;
    }

    if (wantarray() && ref($old)) {
        # return a value rather than a reference
        if (ref($old) eq "HASH") {
            return %{$old};
        }
        if (ref($old) eq "ARRAY") {
            return @{$old};
        }
    }

    return $old;
}

sub remove {
    my ($self, $key) = @_;

    my $old = undef;
    $old = $self->get($key) if defined(wantarray());

    delete($self->{'_session'}->{$key});

    if (wantarray() && ref($old)) {
        # return a value rather than a reference
        if (ref($old) eq "HASH") {
            return %{$old};
        }
        if (ref($old) eq "ARRAY") {
            return @{$old};
        }
    }

    return $old;
}

sub expire {
    my $self = shift;
    for my $key (keys %{$self->{'_session'}}) {
        delete($self->{'_session'}->{$key});
    }
    $self->{'_options'}->{'expire'} = 1;
    return;
}

1;

=head1 NAME

Prancer::Session

=head1 SYNOPSIS

Sessions are just as important in a web application as GET and POST parameters.
So if you have configured your application for sessions then every request will
include a session object specific to that request.

    sub handler {
        my ($self, $env, $request, $response, $session) = @_;

        # increment this counter every time the user requests a page
        my $counter = $session->get('counter');
        $counter ||= 0;
        ++$counter;
        $session->set('counter', $counter);

        sub (GET + /logout) {
            # blow the user's session away
            $session->expire();

            # then redirect the user
            $response->header('Location' => '/login');
            return $response->finalize(301);
        }
    }

=head1 CONFIGURATION

The basic configuration for the session engine looks like this:

    session:
        state:
            driver: Prancer::Session::State::Cookie
            options:
                session_key: PSESSION
        store:
            driver: Prancer::Session::Store::Storable
            options:
                dir: /tmp/prancer/sessions

The documentation for the state and store drivers will have more information
about the specific options available to them.

=head1 METHODS

=over

=item id

This will return the session id of the current session. This is set and
maintained by the session state package.

=item has I<key>

This will return true if the named key exists in the session object.

    if ($session->has('foo')) {
        print "I see you've set foo already.\n";
    }

It will return false otherwise.

=item get I<key> [I<default>]

The get method takes two arguments: a key and a default value. If the key does
not exist then the default value will be returned instead. If the value that
has been stored in the user's session is a reference then a clone of the value
will be returned to avoid modifying the session in a strange way. Additionally,
this method is context sensitive.

    my $foo = $session->get('foo');
    my %bar = $session->get('bar');
    my @baz = $session->get('baz');

=item set I<key> I<value>

The set method takes two arguments: a key and a value. If the key already
exists in the session then it will be overwritten and the old value will be
returned in a context sensitive way. If the value is a reference then it will
be cloned before being saved into the user's session to avoid any strangeness.

    my $old_foo = $session->set('foo', 'bar');
    my %old_bar = $session->set('bar', { 'baz' => 'bat' });
    my @old_baz = $session->set('baz', [ 'foo', 'bar', 'baz' ]);
    $session->set('whatever', 'do not care');

=item remove I<key>

The remove method takes one argument: the key to remove. The value that was
removed will be returned in a context sensitive way.

=item expire

This will blow the session away.

=back

=head1 SEE ALSO

=over

=item L<Plack::Middleware::Session>
=item L<Prancer::Session::State::Cookie>
=item L<Prancer::Session::Store::Memory>
=item L<Prancer::Session::Store::Storable>
=item L<Prancer::Session::Store::Database>

=back

=cut
