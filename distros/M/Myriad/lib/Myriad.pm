package Myriad;
# ABSTRACT: async microservice framework

use Myriad::Class;

our $VERSION = '1.001';
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad - microservice coördination

=begin markdown

[![Coverage status](https://coveralls.io/repos/github/binary-com/perl-Myriad/badge.svg?branch=master)](https://coveralls.io/github/binary-com/perl-Myriad?branch=master)
[![Test status](https://circleci.com/gh/binary-com/perl-Myriad.svg?style=shield&circle-token=55b191c6582ef5932e57b142fb29d8e13ae19598)](https://app.circleci.com/pipelines/github/binary-com/perl-Myriad)
[![Docker](https://img.shields.io/docker/pulls/deriv/myriad.svg)](https://hub.docker.com/r/deriv/myriad)

=end markdown

=head1 SYNOPSIS

 use Myriad;
 Myriad->new->run;

=head1 DESCRIPTION

Myriad provides a framework for dealing with asynchronous, microservice-based code.
It is intended for use in an environment such as Kubernetes to support horizontal
scaling for larger systems.

Overall this framework encourages - but does not enforce - single-responsibility
in each microservice: each service should integrate with at most one external system,
and integration should be kept in separate services from business logic or aggregation.
This is at odds with common microservice frameworks, so perhaps it would be more accurate
to say that this framework is aimed at developing "nanoservices" instead.

=head2 Do you need this?

If you expect to be dealing with more traffic than a single server can handle,
or you have a development team larger than 30-50 or so, this might be of interest.

For a smaller system with a handful of users, it's I<probably> overkill!

=head1 Modules and code layout

=over 4

=item * L<Myriad::Service> - load this in your own code to turn it into a microservice

=item * L<Myriad::RPC> - the RPC abstraction layer, in C<< $self->rpc >>

=item * L<Myriad::Storage> - abstraction layer for storage, available as C<< $self->storage >> within services

=item * L<Myriad::Subscription> - the subscription handling layer, in C<< $self->subscription >>

=back

Each of the three abstractions has various implementations. You'd set one on startup
and that would provide functionality through the top-level abstraction layer. Service code
generally shouldn't need to care which implementation is applied. There may however be cases
where transactional behaviour differs between implementations, so there is some basic
functionality planned for checking whether RPC/storage/subscription use the same underlying
mechanism for transactional safety.

=head2 Storage

The L<Myriad::Storage> abstract API is a good starting point here.

For storage implementations, we have:

=over 4

=item * L<Myriad::Storage::Redis>

=item * L<Myriad::Storage::PostgreSQL>

=item * L<Myriad::Storage::Memory>

=back

Additional transport mechanisms may be available, see CPAN for details.

=head2 RPC

Simple request/response patterns are handled with the L<Myriad::RPC> layer ("remote procedure call").

Details on the request are in L<Myriad::RPC::Request> and the response to be sent back is in L<Myriad::RPC::Response>.

=over 4

=item * L<Myriad::RPC::Implementation::Redis>

=item * L<Myriad::RPC::Implementation::PostgreSQL>

=item * L<Myriad::RPC::Implementation::Memory>

=back

Additional transport mechanisms may be available, see CPAN for details.

=head2 Subscriptions

The L<Myriad::Subscription> abstraction layer defines the available API here.

Subscription implementations include:

=over 4

=item * L<Myriad::Subscription::Implementation::Redis>

=item * L<Myriad::Subscription::Implementation::PostgreSQL>

=item * L<Myriad::Subscription::Implementation::Memory>

=back

Additional transport mechanisms may be available, see CPAN for details.

=head2 Transports

Note that I<some layers don't have implementations for all transports> - MQ for example does not really provide a concept of "storage".

Each of these implementations is supposed to separate out the logic from the actual transport calls, so there's a separate ::Transport set of classes here:

=over 4

=item * L<Myriad::Transport::Redis>

=item * L<Myriad::Transport::PostgreSQL>

=item * L<Myriad::Transport::Memory>

=back

which deal with the lower-level interaction with the protocol, connection management and so on. More details on that
can be found in L<Myriad::Transport> - but it's typically only useful for people working on the L<Myriad> implementation itself.

=head2 Other classes

Documentation for these classes may also be of use:

=over 4

=item * L<Myriad::Exception> - generic errors, provides L<Myriad::Exception/throw> and we recommend that all service errors implement this rôle

=item * L<Myriad::Plugin> - adds specific functionality to services

=item * L<Myriad::Bootstrap> - startup used in C<myriad.pl> for providing autorestart and other functionality

=item * L<Myriad::Service> - base class for a service

=item * L<Myriad::Registry> - support for registering services and methods within the current process

=item * L<Myriad::Config> - general config support, commandline/file/storage

=back

=head1 METHODS

=cut

use curry;
use Future;

use Myriad::Commands;
use Myriad::Config;
use Myriad::Exception;
use Myriad::Exception::InternalError;
use Myriad::Registry;
use Myriad::RPC;
use Myriad::RPC::Client;
use Myriad::Storage;
use Myriad::Subscription;
use Myriad::Transport::HTTP;
use Myriad::Transport::Memory;
use Myriad::Transport::Redis;

use Future::IO;
use Future::IO::Impl::IOAsync;

use IO::Async::Loop;

use Log::Any::Adapter;

use Net::Async::OpenTracing;

our $REGISTRY;
BEGIN {
    $REGISTRY = Myriad::Registry->new;
}

# Enable Future time trace
$Future::TIMES = 1;

IO::Async::Loop->new->add(
    $REGISTRY
);

# The IO::Async::Loop instance
has $loop;
# Any coderefs to call when the framework starts
has $startup_tasks;
# Any coderefs to call when shutdown is requested
has $shutdown_tasks;
# The Myriad::Config instance
has $config;
# Registered commands for the management interface
has $commands;
# Our temporary Net::Async::Redis instance that should
# really be abstracted away by the ::Transport and
# storage/rpc/subscription abstractions
has $redis;
# The in-memory "transport" instance
has $memory_transport;
# The Myriad::RPC instance to serve RPC requests for
# the services in this process
has $rpc;
# The Myriad::RPC::Client instance to send requests
# to other services.
has $rpc_client;
# The Net::Async::HTTP::Server instance for endpoint
# requests
has $http;
# The Myriad::Subscription instance to emit
# and listen for events
has $subscription;
# The Myriad::Storage instance to manage data
# stored by the service or access other services data.
has $storage;
# Future representing run
has $run;
# Future for passing to things that want to react to
# run, anything outside this file
has $run_without_cancel;
# Future representing shutdown
has $shutdown;
# Future for passing to things that want to react to
# shutdown, pretty much everything outside this file
# should only be able to access this one
has $shutdown_without_cancel;
# The Net::Async::OpenTracing instance
has $tracing;
# Any service definitions which is added by registry
has $services;
# Ryu::Source that can be used to recieve commands events
has $ryu;

# Note that we don't use Object::Pad as heavily within the core framework as we
# would expect in microservices - this is mainly due to complications regarding
# rôle/inheritance behaviour, and at some future point we expect to refactor code
# to move more of these classes over to Object::Pad.

BUILD {
    $startup_tasks = [ ];
    $shutdown_tasks = [ ];
}

=head2 loop

Returns the main L<IO::Async::Loop> instance for this process.

=cut

method loop { $loop //= IO::Async::Loop->new }

=head2 services

Hashref of services that have been added to this instance,
as C<name> => C<Myriad::Service> pairs.

=cut

method services { $services //= {} }

=head2 configure_from_argv

Applies configuration from commandline parameters.

Expects a list of parameters and applies the following logic for each one:

=over 4

=item * if it contains C<::> and a wildcard C<*>, it's treated as a service module base name, and all
modules under that immediate namespace will be loaded

=item * if it contains C<::>, it's treated as a comma-separated list of service module names to load

=item * a C<-> prefix is a standard getopt parameter

=back

=cut

async method configure_from_argv (@args) {
    # Allow config parsing to extract the information
    $config = Myriad::Config->new(
        commandline => \@args
    );

    $self->setup_logging;
    $self->setup_tracing;
    await $self->setup_metrics;

    $commands = Myriad::Commands->new(
        myriad => $self
    );

    # At this point, we expect `@args` to contain only the plain
    # parameters such as the service name or a request to run an RPC
    # method.
    my $method = 'service';
    while(@args) {
        my $arg = shift @args;
        if($commands->can($arg)) {
            $method = $arg;
            await $commands->$method(shift @args, @args);
            last;
        } else {
            await $commands->$method($arg, @args);
            last;
        }
    }

    $self->on_start(async sub {
        await $config->listen_for_updates;
    });
}

method config () { $config }

=head2 transport

Returns the L<Myriad::Transport> instance according to the config value.

it's designed to be used by tests, so be careful before using it in the framework code.

it takes a single param

=over 4

=item * component - the RPC, Subscription or storage in lower case

=back

=cut

method transport ($component) {
    my $config_method = "${component}_transport";
    my $myriad_method = $config->$config_method->as_string . '_transport';
    $self->$myriad_method;
}

=head2 redis

The L<Net::Async::Redis> (or compatible) instance used for service coördination.

=cut

method redis_transport () {
    unless($redis) {
        $self->loop->add(
            $redis = Myriad::Transport::Redis->new(
                $config ? (
                    redis_uri              => $config->transport_redis->as_string,
                    cluster                => ($config->transport_cluster->as_string ? 1 : 0),
                    client_side_cache_size => $config->transport_redis_cache->as_number,
                    max_pool_count         => $config->transport_pool_count->as_number,
                    wait_time              => $config->transport_wait_time->as_number,
                ) : ()
            )
        );

        $self->on_start(async method {
            await $self->redis_transport->start;
        });
    }
    $redis
}

=head2 memory_transport

The L<Myriad::Transport::Memory> instance.

=cut

method memory_transport () {
    unless ($memory_transport) {
        $loop->add(
            $memory_transport = Myriad::Transport::Memory->new
        );
    }

    $memory_transport;
}

=head2 rpc

The L<Myriad::RPC> instance to serve RPC requests.

=cut

method rpc () {
    unless($rpc) {
        $self->loop->add(
            $rpc = Myriad::RPC->new(
                transport => $config ? $config->rpc_transport->as_string : '',
                myriad    => $self,
            )
        );

        $self->on_start(async method {
            $rpc->start->retain->on_fail($self->$curry::weak(sub {
                my ($self, $reason) = @_;
                $self->shutdown_future->fail($reason)
                    unless $self->shutdown_future->is_ready;
            }));
            return;
        });

        $self->on_shutdown(async method {
            await $rpc->stop;
        });
    }
    $rpc
}

=head2 rpc_client

The L<Myriad::RPC::Client> instance to request other services RPC.

=cut

method rpc_client () {
    unless($rpc_client) {
        $self->loop->add(
            $rpc_client = Myriad::RPC::Client->new(
                # We should use same transport as $rpc.
                transport => $config ? $config->rpc_transport->as_string : '',
                myriad => $self,
            )
        );

        $rpc_client->start->retain->on_fail(sub {
            $self->shutdown_future->fail(shift);
        });

        $self->on_shutdown(async method {
            await $rpc_client->stop;
        });
    }
    $rpc_client
}

=head2 http

The L<Net::Async::HTTP::Server> (or compatible) instance used for health checks
and metrics.

=cut

method http () {
    unless($http) {
        $self->loop->add(
            $http = Myriad::Transport::HTTP->new
        );
    }
    $http
}

=head2 subscription

The L<Myriad::Subscription> instance to manage events.

=cut

method subscription () {
    unless ($subscription) {
        $self->loop->add(
            $subscription = Myriad::Subscription->new(
                transport => $config ? $config->subscription_transport->as_string : '' ,
                myriad    => $self,
            )
        );

        $self->on_start(async method {
            $subscription->start->retain->on_fail(sub {
                $self->shutdown_future->fail(shift);
            });
        });

        $self->on_shutdown(async method {
            await $subscription->stop;
        });
    }
    $subscription;
}

=head2 storage

The L<Myriad::Storage> instance to manage data.

=cut

method storage () {
    unless($storage) {
        $storage = Myriad::Storage->new(
            transport => $config ? $config->storage_transport->as_string : '',
            myriad => $self,
        );
    }
    $storage
}

=head2 registry

Returns the common L<Myriad::Registry> representing the current service state.

=cut

method registry () { $REGISTRY }

=head2 add_service

Instantiates and adds a new service to the L</loop>.

Returns the service instance.

=cut

async method add_service ($srv, %args) {
    return await $self->registry->add_service(
        service      => $srv,
        myriad       => $self,
        %args
    );
}

=head2 service_by_name

Looks up the given service, returning the instance if it exists.

Will throw an exception if the service cannot be found.

=cut

method service_by_name ($srv) {
    return $self->registry->service_by_name(
        $srv,
    );
}

=head2 ryu

a source to corresponde to any high level events.

=cut

method ryu () {
    unless($ryu) {
        $self->loop->add(
            $ryu = Ryu::Async->new
        );
    }
    $ryu;
}

=head2 shutdown

Requests shutdown.

=cut

async method shutdown () {
    # if this is regular shutdown $run should be already resolved
    $run->fail('Myriad was unable to start correctly') if $run && !$run->is_ready;

    my $f = $shutdown
        or die 'attempting to shut down before we have started, this will not end well';

    try {
        # Each service may have its own shutdown or cleanup operations
        my @shutdown_operations = map {
            $services->{$_}->shutdown
        } keys $services->%*;

        # We also have generic tasks, such as transport or RPC/subscription
        push @shutdown_operations, map {
            $self->$_
        } splice $shutdown_tasks->@*;

        await Future->wait_any(
            Future->wait_all(
                @shutdown_operations
            ),
            $self->loop->timeout_future(after => 5)
        );

        $f->done unless $f->is_ready;
    } catch ($e) {
        $f->fail($e) unless $f->is_ready;
    }
    return $f->without_cancel;
}

=head2 on_start

Registers a coderef to be called during startup.
The coderef is expected to return a L<Future>.

=cut

method on_start ($code) {
    push $startup_tasks->@*, $code;
    $self;
}

=head2 on_shutdown

Registers a coderef to be called during shutdown.

The coderef is expected to return a L<Future> indicating completion.

=cut

method on_shutdown ($code) {
    push $shutdown_tasks->@*, $code;
    $self
}

=head2 run_future

Returns a copy of the run L<Future>.

This would resolve once the process is running and it's
ready to accept requests.

=cut

method run_future () {
    return $run_without_cancel //= (
        $run //= $self->loop->new_future->set_label('run'),
    )->without_cancel;
}

=head2 shutdown_future

Returns a copy of the shutdown L<Future>.

This would resolve once the process is about to shut down,
triggered by a fault or a Unix signal.

=cut

method shutdown_future () {
    return $shutdown_without_cancel //= (
        $shutdown //= $self->loop->new_future->set_label('shutdown')
    )->without_cancel;
}

=head2 setup_logging

Prepare for logging.

=cut

method setup_logging ($code = undef) {
    state $logging = do {
        my $level = $config->log_level;
        $code ||= sub {
            state $flushed = do {
                STDERR->autoflush(1);
            };
            Log::Any::Adapter->import(
                qw(Stderr),
                log_level => $level->as_string,
            );
        };
        $level->subscribe($code);
        $code->();
    };
    return;
}

=head2 setup_tracing

Prepare L<OpenTracing> collection.

=cut

method setup_tracing () {
    $self->loop->add(
        $tracing = Net::Async::OpenTracing->new(
            host => $config->opentracing_host,
            port => $config->opentracing_port,
            protocol => 'jaeger',
        )
    );
    $self->on_shutdown(async method {
        await $tracing->sync
    });
    return;
}

=head2 setup_metrics

Prepare L<Metrics::Any::Adapter> to collect metrics.

=cut

async method setup_metrics () {
    my $adapter = $config->metrics_adapter;
    my $host = $config->metrics_host;
    my $port = $config->metrics_port;

    try {
        await $loop->resolver->getaddrinfo(host => $host->as_string, timeout => 10);
    } catch ($e) {
        $log->errorf('metrics: unable to resolve host %s - %s', $host->as_string, $e);
        $host->set_string('127.0.0.1');
    }

    # Metrics::Any::Adapter use a lexical variable to identify
    # the adapter instance that doesn't allow easy overrides.
    my $metrics_adapter;
    {
        no warnings 'redefine';
        *Metrics::Any::Adapter::adapter = sub {
            return $metrics_adapter if ${^GLOBAL_PHASE} eq 'DESTRUCT';
            return $metrics_adapter //= Metrics::Any::Adapter->class_for_type(
                $adapter->as_string,
            )->new(
                host => $host->as_string,
                port => $port->as_numeric,
        )   ;
        };
    }

    my $code = sub {
        # Try to resolve the host first
        $loop->resolver->getaddrinfo(host => $host->as_string, timeout => 10)
        ->on_done(sub {
            undef $metrics_adapter;
        })->on_fail(sub {
            $log->errorf('metrics: unable to resolve host %s - %s', $host->as_string, shift);
            $host->set_string('127.0.0.1');
        })->retain();
    };

    $adapter->subscribe($code);
    $host->subscribe($code);
    $port->subscribe($code);

    return;
}

=head2 run

Starts the main loop.

Applies signal handlers for TERM and QUIT, then starts the loop.

=cut

async method run () {
    # Initiate the run future.
    $self->run_future();

    for my $signal (qw(TERM INT QUIT)) {
        $self->loop->attach_signal($signal => $self->$curry::weak(method {
            $log->infof("%s received, exit", $signal);
            $self->shutdown->await;
        }))
    }

    try {
        # Run the startup tasks, order is imporatant
        for my $task ($startup_tasks->@*) {
            await $self->$task;
        }
    } catch ($e) {
        die "Startup tasks failed - $e";
    }

    # Set shutdown future before starting commands.
    $self->shutdown_future();

    $commands->run_cmd->retain()->on_fail(sub {
        $self->shutdown->await();
    });

    # Process is running but there is a possibility
    # the command above failed.
    $run->done unless $run->is_ready;

    await $self->shutdown_future;
}

1;

__END__

=head1 SEE ALSO

Microservices are hardly a new concept, and there's a lot of prior art out there.

Key features that we attempt to provide:

=over 4

=item * B<reliable handling> - requests and actions should be reliable by default

=item * B<atomic storage> - being able to record something in storage as part of the same transaction as acknowledging a message

=item * B<flexible backends> - support for various storage, RPC and subscription implementations, allowing for mix+match

=item * B<zero transport option> - for testing and smaller deployments, you might want to run everything in a single process

=item * B<language-agnostic> - implementations should be possible in languages other than Perl

=item * B<first-class Kubernetes support> - k8s is not required, but when available we should play to its strengths

=item * B<minimal boilerplate> - with an emphasis on rapid prototyping

=back

These points tend to be incompatible with typical HTTP-based microservices frameworks, although this is
offered as one of the transport mechanisms (with some limitations).

=head2 Perl

Here are a list of the Perl microservice implementations that we're aware of:

=over 4

=item * L<https://github.com/jmico/beekeeper> - MQ-based (via STOMP), using L<AnyEvent>

=item * L<https://mojolicious.org> - more of a web framework, but a popular one

=item * L<Async::Microservice> - L<AnyEvent>-based, using HTTP as a protocol, currently a minimal wrapper intended to be used with OpenAPI services

=back

=head2 Java

Although this is the textbook "enterprise-scale platform", Java naturally fits a microservice theme.

=over 4

=item * L<Spring Boot|https://spring.io/guides/gs/spring-boot/> - One of the frameworks that integrates well
with the traditional Java ecosystem, depends on HTTP as a transport. Although there is no unified storage layer,
database access is available through connectors.

=item * L<Micronaut|https://micronaut.io/> - This framework has many integrations with industry-standard
solutions - SQL, MongoDB, Kafka, Redis, gRPC - and they have integration guides for cloud-native solutions
such as AWS or GCP.

=item * L<DropWizard|https://www.dropwizard.io/en/stable/> - A minimal framework that provides a RESTful
interface and storage layer using Hibernate.

=item * L<Helidon|https://helidon.io/> - Oracle's open source attempt, provides support for two types of
transport and SQL access layer using standard Java's packages, built with cloud-native deployment in mind.

=back

=head2 Python

Most of Python's frameworks provide tools to facilitate building logic blocks behind APIs (Flask, Django ..etc).

For work distribution, L<Celery|https://docs.celeryproject.org/en/stable/> is commonly used as a task queue abstraction.

=head2 Rust

=over 4

=item * L<https://rocket.rs/> - although this is a web framework, rather than a complete microservice system,
it's reasonably popular for the request/response part of the equation

=item * L<https://actix.rs/> - another web framework, this time with a focus on the actor pattern

=back

=head2 JS

JS has many frameworks that help to implement the microservice architecture, some are:

=over 4

=item * L<Moleculer|https://moleculer.services/> - generally a full-featured, well-designed microservices framework, highly recommended

=item * L<Seneca|https://senecajs.org/>

=back

=head2 PHP

=over 4

=item * L<Swoft|http://en.swoft.org/> - async support via Swoole's coroutines, HTTP/websockets based with additional support for Redis/database connection pooling and ORM

=back

=head2 Cloud providers

Microservice support at the provider level:

=over 4

=item * L<AWS Lambda|https://aws.amazon.com/lambda> - trigger small containers based on logic, typically combined
with other AWS services for data storage, message sending and other actions

=item * L<Google App Engine> - Google's own attempt

=item * L<Heroku|https://www.heroku.com/> - Allow developers to build a microservices architecture based on the services they provide
like the example they mentioned in this L<blog|https://devcenter.heroku.com/articles/event-driven-microservices-with-apache-kafka>

=back

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>

=head1 CONTRIBUTORS

=over 4

=item * Tom Molesworth C<< TEAM@cpan.org >>

=item * Paul Evans C<< PEVANS@cpan.org >>

=item * Eyad Arnabeh

=item * Nael Alolwani

=back

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.
