package Mojo::WebSocketProxy::Backend::JobAsync;

use strict;
use warnings;

use parent qw(Mojo::WebSocketProxy::Backend);

no indirect;

use DataDog::DogStatsd::Helper qw(stats_inc);
use IO::Async::Loop::Mojo;
use Job::Async;
use JSON::MaybeUTF8 qw(encode_json_utf8 decode_json_utf8);
use Log::Any qw($log);
use MojoX::JSON::RPC::Client;

our $VERSION = '0.13';    ## VERSION

__PACKAGE__->register_type('job_async');

=head1 NAME

Mojo::WebSocketProxy::Backend::JobAsync

=head1 DESCRIPTION

A subclass of L<Mojo::WebSocketProxy::Backend> which dispatches RPC requests
via L<Job::Async>.

=cut

=head1 CLASS METHODS

=head2 new

Returns a new instance. Required params:

=over 4

=item loop => IO::Async::Loop

Containing L<IO::Async::Loop> instance.

=item jobman => Job::Async

Optional L<Job::Async> instance.

=item client => Job::Async::Client

Optional L<Job::Async::Client> instance. Will be constructed from
C<< $jobman->client >> if not provided.

=back

=cut

sub new {
    my ($class, %args) = @_;
    # Avoid holding these - we only want the Job::Async::Client instance, and everything else
    # should be attached to the loop (which sticks around longer than we expect to).
    delete $args{loop};
    delete $args{jobman};

    my $self = bless \%args, $class;

    return $self;
}

=head1 METHODS

=cut

=head2 client

    $client = $backend->client

Returns the L<Job::Async::Client> instance.

=cut

sub client { return shift->{client} }

=head2 call_rpc

Implements the L<Mojo::WebSocketProxy::Backend/call_rpc> interface.

=cut

sub call_rpc {
    my ($self, $c, $req_storage) = @_;
    my $method = $req_storage->{method};
    my $msg_type = $req_storage->{msg_type} ||= $req_storage->{method};

    # We'd like to provide some flexibility for people trying to integrate this into
    # other systems, so any combination of Job::Async::Client, Job::Async and/or IO::Async::Loop
    # instance can be provided here.
    $self->{client} //= do {
        # We don't hold a ref to this, since that might introduce unfortunate cycles
        $self->{loop} //= do {
            require IO::Async::Loop::Mojo;
            local $ENV{IO_ASYNC_LOOP} = 'IO::Async::Loop::Mojo';
            IO::Async::Loop->new;
        };
        $self->{loop}->add(my $jobman = Job::Async->new);

        # Let's not pull it in unless we have it already, but we do want to avoid sharing number
        # sequences in forked workers.
        Math::Random::Secure::srand() if Math::Random::Secure->can('srand');
        my $client_job = $jobman->client(redis => $self->{redis});
        $client_job->start->retain;
        $client_job;
    };

    $req_storage->{call_params} ||= {};
    my $rpc_response_cb = $self->get_rpc_response_cb($c, $req_storage);

    my $before_get_rpc_response_hook = delete($req_storage->{before_get_rpc_response}) || [];
    my $after_got_rpc_response_hook  = delete($req_storage->{after_got_rpc_response})  || [];
    my $before_call_hook             = delete($req_storage->{before_call})             || [];
    my $params = $self->make_call_params($c, $req_storage);
    $log->debugf("method %s has params = %s", $method, $params);
    $_->($c, $req_storage) for @$before_call_hook;
    $self->client->submit(
        name   => $req_storage->{name},
        params => encode_json_utf8($params)
        )->on_ready(
        sub {
            my ($f) = @_;
            $log->debugf('->submit completion: ', $f->state);

            $_->($c, $req_storage) for @$before_get_rpc_response_hook;

            # unconditionally stop any further processing if client is already disconnected

            return Future->done unless $c and $c->tx;

            my $api_response;

            if ($f->is_done) {
                my $result = MojoX::JSON::RPC::Client::ReturnObject->new(rpc_response => decode_json_utf8($f->get));

                $_->($c, $req_storage, $result) for @$after_got_rpc_response_hook;

                $api_response = $rpc_response_cb->($result->result);
                stats_inc("rpc_queue.client.jobs.success", {tags => ["rpc:" . $req_storage->{name}, 'clientID:' . $self->client->id]});
            } else {
                my ($failure) = $f->failure;
                $log->warnf("method %s failed: %s", $method, $failure);
                stats_inc("rpc_queue.client.jobs.fail",
                    {tags => ["rpc:" . $req_storage->{name}, 'clientID:' . $self->client->id, 'error:' . $failure]});

                $api_response = $c->wsp_error($msg_type, 'WrongResponse', 'Sorry, an error occurred while processing your request.');
            }

            return unless $api_response;

            $c->send({json => $api_response}, $req_storage);
        })->retain;
    return;
}

1;
