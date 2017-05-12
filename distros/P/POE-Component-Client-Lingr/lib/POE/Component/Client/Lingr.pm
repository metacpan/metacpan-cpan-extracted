package POE::Component::Client::Lingr;

use strict;
our $VERSION = '0.04';

use Data::Visitor::Callback;
use HTTP::Request::Common;
use JSON::Syck;
use POE qw( Component::Client::HTTP );
use URI;

our $APIBase = "http://www.lingr.com/api";
our $Debug = 0;

# scraped from Lingr wiki page
our $Methods = {
    'session.create' => 'POST',
    'session.destroy' => 'POST',
    'auth.login' => 'POST',
    'auth.logout' => 'POST',
    'explore.getHotRooms' => 'GET',
    'explore.getNewRooms' => 'GET',
    'explore.getHotTags' => 'GET',
    'explore.getAllTags' => 'GET',
    'explore.search' => 'GET',
    'explore.searchTags' => 'GET',
    'user.getInfo' => 'GET',
    'user.startObserving' => 'POST',
    'user.observe' => 'GET',
    'user.stopObserving' => 'POST',
    'room.getInfo' => 'GET',
    'room.enter' => 'POST',
    'room.getMessages' => 'GET',
    'room.observe' => 'GET',
    'room.setNickname' => 'POST',
    'room.say' => 'POST',
    'room.exit' => 'POST',
};

sub spawn {
    my($class, %args) = @_;

    my $self = bless {}, $class;

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => {
                _start      => '_start',
                _stop       => '_stop',
                _unregister => '_unregister',

                # API
                register   => 'register',
                unregister => 'unregister',
                notify     => 'notify',
                call       => 'call',
                http_response   => 'http_response',
            },
        ],
        args => [ \%args ],
    )->ID;

    POE::Component::Client::HTTP->spawn(
        Agent => "POE::Component::Client::Lingr/$VERSION",
        Alias => $self->ua_alias,
    );

    $self;
}

sub ua_alias {
    my $self = shift;
    return "lingr_ua_" . $self->session_id;
}

sub session_id { $_[0]->{session_id} }

sub yield {
    my $self = shift;
    $poe_kernel->post($self->session_id, @_);
}

sub _start {
    my($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
    $kernel->alias_set($args->{alias}) if $args->{alias};
}

sub _stop { }

sub register {
    my($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];
    $kernel->refcount_increment($sender->ID, __PACKAGE__);
    $heap->{listeners}->{$sender->ID} = 1;
}

sub unregister {
    my($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];
    $kernel->yield(_unregister => $sender->ID);
}

sub _unregister {
    my($kernel, $heap, $session) = @_[KERNEL, HEAP, ARG0];
    $kernel->refcount_decrement($session, __PACKAGE__);
    delete $heap->{listeners}->{$session};
}

sub notify {
    my($kernel, $heap, $name, $args) = @_[KERNEL, HEAP, ARG0, ARG1];
    $kernel->post($_ => "lingr.$name" => $args) for keys %{$heap->{listeners}};
}

sub call {
    my($kernel, $heap, $method, $args, $self) = @_[KERNEL, HEAP, ARG0, ARG1, OBJECT];

    my $req = create_request($heap, $method, $args);
    $kernel->post($self->ua_alias => request => 'http_response', $req);
}

sub http_response {
    my($kernel, $heap, $session, $request_packet, $response_packet) = @_[KERNEL, HEAP, SESSION, ARG0, ARG1];

    my $request  = $request_packet->[0];
    my $response = $response_packet->[0];

    my $data   = handle_response($kernel, $request, $response) or return;
    my $method = uri_to_method($request->uri);

    # special-case some methods
    if ($method eq 'session.create') {
        $heap->{session} = $data->{session};
    } elsif ($method eq 'room.enter') {
        # create session for room.observe
        POE::Session->create(
            inline_states => {
                _start => \&observer_start,
                _stop  => \&observer_stop,
                response => \&observer_response,
                observe => \&observer_observe,
                notify => \&observer_notify,
            },
            heap => {
                session => $heap->{session},
                ticket  => $data->{ticket},
                counter => $data->{room}->{counter},
                parent  => $session->ID,
            },
        );
    }

    if ($data->{ticket}) {
        $heap->{ticket} = $data->{ticket};
    }

    $kernel->yield(notify => $method, $data);
}

sub observer_start {
    my($kernel, $heap) = @_[KERNEL, HEAP];
    $kernel->alias_set("observer_$heap->{ticket}");

    POE::Component::Client::HTTP->spawn(
        Agent => "POE::Component::Client::Lingr/$VERSION",
        Alias => "lingr_observer_$heap->{ticket}",
    );

    $kernel->yield('observe');
}

sub observer_observe {
    my($kernel, $heap) = @_[KERNEL, HEAP];

    my $req = create_request($heap, 'room.observe', {
        ticket  => $heap->{ticket},
        counter => $heap->{counter},
    });

    $kernel->post("lingr_observer_$heap->{ticket}", request => 'response', $req);
}

sub observer_notify {
    my($kernel, $heap, $name, $args) = @_[KERNEL, HEAP, ARG0, ARG1];
    $kernel->post($heap->{parent}, 'notify', $name, $args);
}

sub observer_response {
    my($kernel, $heap, $request_packet, $response_packet) = @_[KERNEL, HEAP, ARG0, ARG1];

    my $request  = $request_packet->[0];
    my $response = $response_packet->[0];

    my $data = handle_response($kernel, $request, $response) or return;
    $kernel->post($heap->{parent}, 'notify', 'room.observe', $data);

    $heap->{counter} = $data->{counter};
    $kernel->yield('observe');
}

### Utility functions

sub handle_response {
    my($kernel, $request, $response) = @_;

    unless ($response->is_success) {
        $kernel->yield(notify => "error.http" => { code => $response->status_line });
        return;
    }

    warn $response->content if $Debug;

    local $JSON::Syck::ImplicitUnicode = 1;
    my $data = JSON::Syck::Load($response->content);
    unless ($data->{status} eq 'ok'){
        $kernel->yield(notify => "error.response" => $data->{error});
        return;
    }

    return $data;
}

sub create_request {
    my($heap, $method, $args) = @_;

    my @method = map { s/([A-Z])/"_".lc($1)/eg; $_ } split /\./, $method;
    my $uri = URI->new($APIBase . "/" . join("/", @method));

    # downgrade all parameters to utf-8, if they're Unicode
    my $v = Data::Visitor::Callback->new(
        plain_value => sub {
            if (utf8::is_utf8($_)) {
                utf8::encode($_);
            }
        },
        ignore_return_values => 1,
    );

    $v->visit($args);

    my $req_method = $Methods->{$method} || do {
        Carp::carp "Don't know method '$method'. Defaults to GET";
        "GET";
    };

    $args->{format} = 'json';

    if ($method =~ /^room\./ && $heap->{ticket}) {
        $args->{ticket} = $heap->{ticket};
    }

    if ($heap->{session}) {
        $args->{session} = $heap->{session};
    }

    my $req;
    if ($req_method eq 'GET') {
        $uri->query_form(%$args);
        $req = HTTP::Request->new(GET => $uri);
    } else {
        $req = HTTP::Request::Common::POST( $uri, [ %$args ] );
    }

    use Data::Dumper;
    warn Dumper $req if $Debug;

    return $req;
}

sub uri_to_method {
    my $uri = shift;
    $uri =~ s/^\Q$APIBase\E//;
    $uri =~ s/\?.*$//;
    my @method = grep length, map { s/_(\w)/uc($1)/eg; $_ } split '/', $uri;
    return join ".", @method;
}

1;
__END__

=for stopwords Lingr API com lingr.com

=head1 NAME

POE::Component::Client::Lingr - POE chat component for Lingr.com

=head1 SYNOPSIS

  use POE qw(Component::Client::Lingr);

  # See eg/bot.pl for sample client code

=head1 DESCRIPTION

POE::Component::Client::Lingr is a POE component for Lingr API. See
L<http://wiki.lingr.com/dev/show/HomePage> for more details about Lingr API.

This module is in its B<beta quality> and the API and implementation will be
likely changed along with the further development.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<POE>, L<http://wiki.lingr.com/dev/show/HomePage>

=cut
