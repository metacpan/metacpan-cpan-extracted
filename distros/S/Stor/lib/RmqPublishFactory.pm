package RmqPublishFactory;
use v5.20;

use Mojo::Base -base, -signatures;
use Net::AMQP::RabbitMQ;
use URI;
use Mojo::IOLoop;
use Try::Tiny::Retry ':all';

=head1 NAME

RmqPublishFactory

=head1 SYNOPSIS

    my $rmq_publish = RmqPublishFactory->new(uri => 'amqp://guest:guest@localhost/vhost?exchange=test');
    $rmq_publish->('message');

=head1 DESCRIPTION

=head1 METHODS

=head2 new(%options)

=head3 %options

=head4 uri

https://www.rabbitmq.com/uri-spec.html

=cut

has 'uri';

has 'amqp_uri' => sub ($self) {
    URI->new($self->uri);
};

=head4 exchange

default I<stor>

uri query param C<?exchange=xxx> override this attribute

=cut

has 'exchange' => sub ($self) {

    return $self->amqp_uri->query_param('exchange') // 'stor';
};

=head4 routing_key

default I<sha>

uri query param C<?routing_key=xxx> override this attribute

=cut

has 'routing_key' => sub ($self) {

    return $self->amqp_uri->query_param('routing_key') // 'sha';
};

=head4 routing_key

default I<60>

uri query param C<?heartbeat=xxx> override this attribute

=cut

has 'heartbeat' => sub ($self) {

    return $self->amqp_uri->query_param('heartbeat') // 60;
};

has 'rmq' => sub {
    Net::AMQP::RabbitMQ->new();
};

has 'channel' => 1;

has 'log';

=head2 create()

create new publisher (code)

=cut

sub create ($self) {
    return if !$self->amqp_uri->scheme;
    return if $self->amqp_uri->scheme !~ /^amqp/;

    $self->rmq->connect($self->amqp_uri->as_net_amqp_rabbitmq);
    $self->rmq->channel_open($self->channel);
    $self->rmq->exchange_declare($self->channel, $self->exchange, {exchange_type => 'topic', durable => 1,});

    return sub ($sha) {
        retry {
            $self->rmq->publish($self->channel, $self->routing_key, $sha, { exchange => $self->exchange });
        }
        delay_exp {2, 1e5}
        on_retry {
            try {
                $self->rmq->disconnect();
            }
            catch {
                $self->log->debug("disconnect $_");
            };

            try {
                $self->rmq->connect($self->amqp_uri->as_net_amqp_rabbitmq);
                $self->rmq->channel_open($self->channel);
            }
            catch {
                $self->log->debug("connect/channel_open $_");
            };
        }
        catch {
            $self->log->error($_);
        };
    };
}

=head2 create_mojo_heartbeat()

create recurring mojo handler for heartbeat

=cut

sub create_mojo_heartbeat ($self) {
    Mojo::IOLoop->recurring(
        $self->heartbeat => sub {
            $self->rmq->heartbeat();
        }
    );
}

=head1 contributing

for dependency use [cpanfile](cpanfile)...

for resolve dependency use [carton](https://metacpan.org/pod/Carton) (or Carmel - is more experimental) 

    carton install

for run test use C<minil test>

    carton exec minil test


if you don't have perl environment, is best way use docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton install
    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton exec minil test

=head2 warning

docker run default as root, all files which will be make in docker will be have root rights

one solution is change rights in docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended bash -c "carton install; chmod -R 0777 ."

or after docker command (but you must have root rights)

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;

