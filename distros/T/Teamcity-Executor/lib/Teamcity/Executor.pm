package Teamcity::Executor;
use 5.020;
use strict;
use warnings;

our $VERSION = "1.1.0";

use Moose;
use HTTP::Tiny;
use Cpanel::JSON::XS;
use IO::Async::Timer::Periodic;
use Log::Any qw($log);
use Try::Tiny::Retry;

use feature 'signatures';
no warnings 'experimental::signatures';

has credentials => (is => 'ro', isa => 'HashRef');

has build_id_mapping => (is => 'ro', isa => 'HashRef');

has http => (
    is      => 'ro',
    isa     => 'HTTP::Tiny',
    default => sub { HTTP::Tiny->new(timeout => 10) }
);

has loop => (
    is  => 'ro',
    isa => 'IO::Async::Loop',
);

has teamcity_builds => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has poll_interval => (
    is      => 'ro',
    isa     => 'Int',
    default => 10,
);

has teamcity_auth_url => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub ($self) {
        my $url  = $self->credentials->{url};
        my $user = $self->credentials->{user};
        my $pass = $self->credentials->{pass};

        my ($protocol, $address) = $url =~ m{(http[s]://)(.*)};

        return $protocol . $user . ':' . $pass . '@' . $address;
    }
);

sub http_request ($self, $method, $url, $headers = {}, $content = '') {
    my $response;

    # this code handles the teamcity authentification issues (sometimes authentification fails
    # without a reason)
    retry {
        $response = $self->http->request(
            $method, $url,
            {
                headers => $headers,
                content => $content,
            }
        );

        if ($response->{status} == 599) {
            $log->info("Authentification to teamcity failed, retrying.");
            die 'Authentification to teamcity failed';
        }
    };

    if (!$response->{success}) {
        die "HTTP $method request to $url failed: " . "$response->{status}: $response->{reason}";
    }

    return $response;
}

sub run_teamcity_build ($self, $build_type_id, $properties, $build_name, $wait = 1) {
    $build_name //= 'unnamed-build';

    my $build_queue_url = $self->teamcity_auth_url . '/httpAuth/app/rest/buildQueue';

    my $xml_properties = '';

    for my $key (keys %{$properties}) {
        my $value = $properties->{$key};
        $xml_properties .= qq{<property name="$key" value="$value" />\n};
    }

    my $request_body = qq{<build>
            <buildType id="$build_type_id"/>
            <properties>
            $xml_properties
            </properties>
        </build>};

    my $response = $self->http_request(
        'POST',
        $build_queue_url,
        {
            'Content-Type' => 'application/xml',
            'Accept'       => 'application/json',
        },
        $request_body,
    );

    my $json = decode_json $response->{content};

    my $build_id          = $json->{id};
    my $build_detail_href = $json->{webUrl};

    my $f = $self->loop->new_future();

    if ($wait) {
        $self->teamcity_builds->{$build_id} = {
            id          => $build_id,
            status_href => $json->{href},
            href        => $build_detail_href,
            name        => $build_name,
            params      => $properties,
            future      => $f,
        };
    }
    else {
        $f->done({ id => $build_id, href => $build_detail_href, status => '', params => $properties, output => '' });
    }

    return $f, $build_id, $json->{webUrl};
}

sub get_artifact_list ($self, $build_result) {

    # get build result
    my $result_url = $self->teamcity_auth_url . $build_result->{href};
    my $response   = $self->http_request('GET', $result_url, { 'Accept' => 'application/json' },);
    my $json       = decode_json $response->{content};

    # get artifacts summary
    my $artifacts_href = $json->{artifacts}{href};
    my $artifacts_url  = $self->teamcity_auth_url . $artifacts_href;
    $response = $self->http_request('GET', $artifacts_url, { 'Accept' => 'application/json' },);

    $json = decode_json $response->{content};

    my %artifacts;

    # get individual artifacts URLs
    for my $node ($json->{file}->elements) {
        my $content_href  = $node->{content}{href};
        my $metadata_href = $node->{content}{href};
        my $name          = $node->{name};
        $artifacts{$name} = {
            name          => $name,
            content_href  => $content_href,
            metadata_href => $metadata_href,
        };
    }

    return \%artifacts;
}

sub get_artifact_content ($self, $build_result, $artifact_name) {
    my $artifact_list = $self->get_artifact_list($build_result);

    my $content_url = $self->teamcity_auth_url . $artifact_list->{$artifact_name}{content_href};
    my $response = $self->http_request('GET', $content_url);

    return $response->{content};
}

sub run ($self, $build_name, $properties = {}) {

    my $teamcity_job_parameters = join(', ', map { "$_: '$properties->{$_}'" } keys %{$properties});
    $log->info("RUN\t$build_name($teamcity_job_parameters)");

    my ($f, $id, $url) = $self->run_teamcity_build($self->build_id_mapping->{$build_name}, $properties, $build_name,);

    $log->info("\t[$id]\t$url");

    return $f;
}

sub touch ($self, $build_name, $properties = {}) {
    my $teamcity_job_parameters = join(', ', map { "$_: '$properties->{$_}'" } keys %{$properties});
    $log->info("TOUCH\t$build_name($teamcity_job_parameters)");

    my ($f, $id, $url) = $self->run_teamcity_build($self->build_id_mapping->{$build_name}, $properties, $build_name, 0);

    $log->info("\t[$id]\t$url");

    return $f;
}

sub poll_teamcity_results($self) {
    $log->info('.');

    for my $build (values %{$self->teamcity_builds}) {
        my $url = $self->teamcity_auth_url . $build->{status_href};
        my $response = $self->http_request('GET', $url, { 'Accept' => 'application/json' },);

        my $json = decode_json $response->{content};

        my $state  = $json->{state};
        my $status = $json->{status};

        $log->info("$build->{name} [$build->{id}]: QUEUED") if $state eq 'queued';

        next if $state ne 'finished';

        $log->info("RESULT\t$build->{name} [$build->{id}]: $status ($state)");

        my $job_result = {
            id     => $build->{id},
            href   => $build->{href},
            status => $status,
            params => $build->{params},
            output => $json
        };

        if ($status eq 'SUCCESS') {
            $build->{future}->done($job_result);
        }
        else {
            $build->{future}->fail($job_result);
        }

        delete $self->teamcity_builds->{ $build->{id} };
    }
}

sub register_polling_timer($self) {
    my $timer = IO::Async::Timer::Periodic->new(
        interval => $self->poll_interval,
        on_tick  => sub {
            $self->poll_teamcity_results();
        },
    );

    $self->loop->add($timer);
    $timer->start();
}

1;
__END__

=encoding utf-8

=head1 NAME

Teamcity::Executor - Executor of TeamCity build configurations

=head1 SYNOPSIS

    use Teamcity::Executor;
    use IO::Async::Loop;
    use Log::Any::Adapter;

    Log::Any::Adapter->set(
        'Dispatch',
        outputs => [
            [
                'Screen',
                min_level => 'debug',
                stderr    => 1,
                newline   => 1
            ]
        ]
    );

    my $loop = IO::Async::Loop->new;
    my $tc = Teamcity::Executor->new(
        credentials => {
            url  => 'https://teamcity.example.com',
            user => 'user',
            pass => 'password',
        },
        build_id_mapping => {
            hello_world => 'playground_HelloWorld',
            hello_name  => 'playground_HelloName',
        }
        poll_interval => 10,
        loop => $loop,
    );

    $tc->register_polling_timer();

    my $future = $tc->run('hello_name', { name => 'TeamCity' })->then(
        sub {
            my ($build) = @_;
            print "Build succeeded\n";
            my $greeting = $tc->get_artifact_content($build, 'greeting.txt');
            print "Content of greeting.txt artifact: $greeting\n";
        },
        sub {
            print "Build failed\n";
            exit 1
        }
    );

    my $touch_future = $tc->touch('hello_name', { name => 'TeamCity' })->then(
        sub {
            my ($build) = @_;
            print "Touch build started\n";
            $loop->stop();
        },
        sub {
            print "Touch build failed to start\n";
            exit 1
        }
    );

    $loop->run();


=head1 DESCRIPTION

Teamcity::Executor is a module for executing Teamcity build configurations.
When you execute one, you'll receive a future of the build. Teamcity::Executor
polls TeamCity and when it finds the build has ended, it resolves the future.

=head1 LICENSE

Copyright (C) Avast Software

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Miroslav Tynovsky E<lt>tynovsky@avast.comE<gt>

=cut
