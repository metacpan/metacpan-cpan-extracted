package Teamcity::Executor;
use 5.020;
use strict;
use warnings;

our $VERSION = "0.1.1";

use Moose;
use autobox::Core;
use HTTP::Tiny;
use Cpanel::JSON::XS;
use IO::Async::Timer::Periodic;

use feature 'say';
use feature 'signatures';
no warnings 'experimental::signatures';

has credentials      => (is => 'ro', isa => 'HashRef');

has build_id_mapping => (is => 'ro', isa => 'HashRef');

has http => (
    is => 'ro', isa => 'HTTP::Tiny',
    default => sub { HTTP::Tiny->new(timeout => 10)   }
);

has loop => (
    is => 'ro', isa => 'IO::Async::Loop',
);

has teamcity_builds => (
    is => 'ro', isa => 'HashRef', default => sub { {} },
);

has poll_interval => (
    is => 'ro', isa => 'Int', default => 10,
);

has teamcity_auth_url => (
    is => 'ro', isa => 'Str', lazy => 1, default => sub ($self) {
        my $url  = $self->credentials->{url};
        my $user = $self->credentials->{user};
        my $pass = $self->credentials->{pass};

        my ($protocol, $address) = $url =~ m{(http[s]://)(.*)};

        return $protocol . $user . ':' . $pass . '@' . $address;
    }
);


sub http_request($self, $method, $url, $headers = {}, $content = '') {

    my $desecretized_url = $url =~ s{(http[s]://)[^/]+:[^@]+@}{$1}r;
    # say STDERR "# $method\t$desecretized_url";

    my $response;

    my $retry = 0;
    while (1) {
        $response = $self->http->request($method, $url, {
            headers => $headers,
            content => $content,
        });

        last if $response->{status} != 599;
        print ' [TeamCity request retry: ' if !$retry;
        print '.';
        sleep 1;
        $retry = 1;
    }
    print "] " if $retry;

    # say STDERR 'done';

    if (! $response->{success} ) {
        use Data::Dumper;
        print Dumper $response;
        die "HTTP $method request to $url failed: " .
            "$response->{status}: $response->{reason}"
    }

    return $response
}


sub run_teamcity_build {
    my ($self, $build_type_id, $properties, $build_name) = @_;

    $build_name //= 'unnamed-build';

    my $build_queue_url =
        $self->teamcity_auth_url . '/httpAuth/app/rest/buildQueue';

    my $xml_properties = '';

    for my $key ($properties->keys) {
        my $value = $properties->{$key};
        $xml_properties .= qq{<property name="$key" value="$value" />\n};
    }

    my $request_body =
        qq{<build>
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
            'Accept' => 'application/json',
        },
        $request_body,
    );

    my $json = decode_json $response->{content};

    my $build_id = $json->{id};
    my $build_href = $json->{href};
    my $f = $self->loop->new_future();

    $self->teamcity_builds->{$build_id} = {
        id     => $build_id,
        href   => $build_href,
        name   => $build_name,
        future => $f,
    };

    return $f, $build_id, $json->{webUrl}
}

sub get_artifact_list($self, $build_result) {

    # get build result
    my $result_url = $self->teamcity_auth_url . $build_result->{href};
    my $response = $self->http_request(
        'GET',
        $result_url,
        { 'Accept' => 'application/json' },
    );
    my $json = decode_json $response->{content};

    # get artifacts summary
    my $artifacts_href = $json->{artifacts}{href};
    my $artifacts_url = $self->teamcity_auth_url . $artifacts_href;
    $response = $self->http_request(
        'GET',
        $artifacts_url,
        { 'Accept' => 'application/json' },
    );

    $json = decode_json $response->{content};

    my %artifacts;
    # get individual artifacts URLs
    for my $node ($json->{file}->elements) {
        my $content_href = $node->{content}{href};
        my $metadata_href = $node->{content}{href};
        my $name = $node->{name};
        $artifacts{$name} = {
            name          => $name,
            content_href  => $content_href,
            metadata_href => $metadata_href,
        };
    }

    return \%artifacts
}

sub get_artifact_content($self, $build_result, $artifact_name) {
    my $artifact_list = $self->get_artifact_list($build_result);

    my $content_url = $self->teamcity_auth_url .
                        $artifact_list->{$artifact_name}{content_href};
    my $response = $self->http_request('GET', $content_url);

    return $response->{content}
}


sub run($self, $build_name, $properties = {}) {
    print "RUN\t$build_name(";
    print join(', ', map { "$_: '$properties->{$_}'" } $properties->keys);
    print ")";

    my ($f, $id, $url) = $self->run_teamcity_build(
        $self->build_id_mapping->{$build_name},
        $properties,
        $build_name,
    );

    say " [$id]\n\t$url";

    return $f;
}

sub poll_teamcity_results($self) {
    say 'TICK';
    for my $build ($self->teamcity_builds->values) {
        my $url = $self->teamcity_auth_url . $build->{href};
        my $response = $self->http_request(
            'GET',
            $url,
            { 'Accept' => 'application/json' },
        );

        my $json = decode_json $response->{content};

        my $state  = $json->{state};
        my $status = $json->{status};

        next if $state ne 'finished';

        say "RESULT\t$build->{name} [$build->{id}]: $status";

        if ($status eq 'SUCCESS') {
            my $href = $json->{href};
            $build->{future}->done({ id => $build->{id}, href => $href });
        }
        elsif ($status eq 'FAILURE') {
            $build->{future}->fail($json->{statusText});
        }

        delete $self->teamcity_builds->{$build->{id}};
    }
}

sub register_polling_timer($self) {
    my $timer = IO::Async::Timer::Periodic->new(
        interval => $self->poll_interval,
        on_tick => sub {
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
    )

    $tc->register_polling_timer();

    $tc->run('hello_name', { name => 'TeamCity' })->then(
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

