package POE::Component::Client::Twitter;

use strict;
use warnings;
our $VERSION = '0.01';

use HTTP::Request::Common;
use HTTP::Date ();
use JSON::Any;
use POE qw( Component::Client::HTTP );
use URI;

sub spawn {
    my($class, %args) = @_;

    %args = (
        apiurl   => 'http://twitter.com/statuses',
        apihost  => 'twitter.com:80',
        apirealm => 'Twitter API',
        alias    => 'twitter',
        %args
    );
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
                update     => 'update',
                friend_timeline => 'friend_timeline',
                update_success  => 'update_success',
                friend_timeline_success => 'friend_timeline_success',
                http_response   => 'http_response',
            },
        ],
        args => [ \%args ],
        heap => { args => \%args },
    )->ID;

    POE::Component::Client::HTTP->spawn(
        Agent => __PACKAGE__ . '/' . $VERSION,
        Alias => $self->ua_alias,
    );

    $self;
}

sub ua_alias {
    my $self = shift;
    return "twitter_ua_" . $self->session_id;
}

sub session_id { $_[0]->{session_id} }

sub yield {
    my $self = shift;
    $poe_kernel->post($self->session_id, @_);
}

sub notify {
    my($kernel, $heap, $name, $args) = @_[KERNEL, HEAP, ARG0, ARG1];
    $kernel->post($_ => "twitter.$name" => $args) for keys %{$heap->{listeners}};
}

sub _start {
    my($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
    $kernel->alias_set($args->{alias}) if $args->{alias};
}

sub _stop {}

sub register {
    my($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];
    $kernel->refcount_increment($sender->ID, __PACKAGE__);
    $heap->{listeners}->{$sender->ID} = 1;
    $kernel->post($sender->ID => "registered" => $_[SESSION]->ID);
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

sub update {
    my ($kernel, $heap, $status, $self) = @_[KERNEL,HEAP,ARG0,OBJECT];

    my $req = HTTP::Request::Common::POST(
        $heap->{args}->{apiurl} . '/update.json',
        [ status => $status ],
    );
    $req->authorization_basic($heap->{args}->{username}, $heap->{args}->{password});

    $kernel->post($self->ua_alias => request => 'http_response', $req);
}

sub friend_timeline {
    my ($kernel, $heap, $status, $self) = @_[KERNEL,HEAP,ARG0,OBJECT];

    my $uri = URI->new($heap->{args}->{apiurl} . '/friends_timeline.json');
    $uri->query_form(since => HTTP::Date::time2str($heap->{since})) if $heap->{since};
    $heap->{since} = time;

    my $req = HTTP::Request->new(GET => $uri);
    $req->authorization_basic($heap->{args}->{username}, $heap->{args}->{password});

    $kernel->post($self->ua_alias => request => 'http_response', $req);
}


sub update_success {
    my ($kernel,$heap, $response) = @_[KERNEL,HEAP,ARG0];
    $kernel->yield(notify => 'update_success',
        JSON::Any->jsonToObj($response->content)
    );
}

sub friend_timeline_success { 
   my ($kernel,$heap, $response) = @_[KERNEL,HEAP,ARG0];

   my $data;
   $data = JSON::Any->jsonToObj($response->content) if $response->is_success;
   $kernel->yield(notify => 'friend_timeline_success', $data);
}

sub http_response {
    my($kernel, $heap, $session, $request_packet, $response_packet) = @_[KERNEL, HEAP, SESSION, ARG0, ARG1];

    my $request  = $request_packet->[0];
    my $response = $response_packet->[0];

    my $uri = $request->uri;
    if ($uri =~ /update.json/) {
        unless ($response->is_success) {
            $kernel->yield(notify => 'response_error', $response);
            return;
        }
        $kernel->yield(update_success => $response);
    } elsif ($uri =~ /friends_timeline.json/) {
        $kernel->yield(friend_timeline_success => $response);
    }
}

1;
__END__

=head1 NAME

POE::Component::Client::Twitter - POE chat component for twitter.com

=head1 SYNOPSIS

  use POE::Component::Client::Twitter;

=head1 DESCRIPTION

POE::Component::Client::Twitter is a POE component for Twitter API. See
L<http://groups.google.com/group/twitter-development-talk/web/api-documentation> for more details about Twitter API.

This module is in its B<beta quality> and the API and implementation will be
likely changed along with the further development.

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

L<POE>, L<http://groups.google.com/group/twitter-development-talk/web/api-documentation>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
