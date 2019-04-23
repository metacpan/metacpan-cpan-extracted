#!/usr/bin/env perl

package Test::OpenStack::MetaAPI;

use strict;
use warnings;

use Test::More;    # for note & co
use Test::MockModule;
use HTTP::Response;
use JSON ();

my $json_object;
my $mock_lwp;

our $UA_DISPLAY_OUTPUT;

use Exporter 'import';
our @EXPORT_OK = qw(
  mock_lwp_useragent
  mock_get_request
  mock_post_request
  mock_put_request
  mock_delete_request

  application_json
  txt_plain

  last_http_request
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# add the json header
sub application_json {
    my ($content) = @_;

    return {
        content => $content,
        headers => [
            ['Content-Type' => 'application/json'],
        ],
    };
}

sub txt_plain {
    my ($content) = @_;

    return {
        content => $content,
        headers => [
            ['Content-Type' => 'text/plain'],
        ],
    };
}

our $LAST_REQUEST;

sub last_http_request {
    return $LAST_REQUEST;
}

sub mock_lwp_useragent {
    $mock_lwp = Test::MockModule->new('LWP::UserAgent');

    $mock_lwp->redefine(
        request => sub {
            my ($self, @args) = @_;

            $json_object //=
              JSON->new->pretty->indent->relaxed->allow_blessed(0)
              ->convert_blessed(0);

            my $req = $args[0];

            my $method = uc $req->method;
            my $uri    = $req->uri;

            $LAST_REQUEST = $method . " " . $uri;

            note "LWP: ", $LAST_REQUEST;

            if (ref $req eq 'HTTP::Request') {
                if (my $fake = request_is_mocked($req)) {
                    return $fake;
                }

                my $content = $req->content // '';
                if (length $content) {
                    $content =~
                      s{"password"\s*:\s*"[^"]+"}{"password":"********"}g;

                    my $as_json = eval {
                        $json_object->encode($json_object->decode($content));
                    };
                    note "CONTENT: ", $as_json // $content;
                }

            }

            my $output = $mock_lwp->original('request')->($self, @args);

            # display output answer
            if ($UA_DISPLAY_OUTPUT && ref $output eq 'HTTP::Response') {

                note $output->is_success()? "Success: ": "Error: ",
                  $output->code;

                my $content = $output->content // '';
                my $as_json =
                  eval { $json_object->encode($json_object->decode($content)) };

                note "CONTENT: ", $as_json // $content;
            }

            return $output;
        });

    return;
}

my %MOCKED_REQUEST;

sub request_is_mocked {
    my ($req) = @_;

    my $method = uc $req->method;
    my $uri    = _sanitize_uri($req->uri);

    if ($MOCKED_REQUEST{$method} && $MOCKED_REQUEST{$method}->{$uri}) {
        note "mocked request: $method $uri";

        my $mocked = $MOCKED_REQUEST{$method}->{$uri};

        ### maybe just for the content??
        $mocked = $mocked->{content}->($req)
          if ref $mocked->{content} eq 'CODE';

        ## convert it as one HTTP::Response object
        my $response = HTTP::Response->new($mocked->{code}, $mocked->{msg});

        ## add headers...
        if (ref $mocked->{headers}) {
            foreach my $header (@{$mocked->{headers}}) {
                next unless ref $header;
                $response->header($header->[0], $header->[1]);
            }
        }
        if (defined $mocked->{content}) {
            $response->content($mocked->{content});
            $response->{body} = $mocked->{content};
        }

        #bless $response, 'OpenStack::Client::Response';
        $response->request($req);

        return $response;
    }

    return;
}

sub mock_get_request {
    my ($uri, $content, $code) = @_;

    return mock_method_request(get => $uri, $content, $code);
}

sub mock_post_request {
    my ($uri, $content, $code) = @_;

    return mock_method_request(post => $uri, $content, $code);
}

sub mock_put_request {
    my ($uri, $content, $code) = @_;

    return mock_method_request(put => $uri, $content, $code);
}

sub mock_delete_request {
    my ($uri, $content, $code) = @_;

    return mock_method_request(delete => $uri, $content, $code);
}

sub mock_method_request {
    my ($method, $uri, $content, $code) = @_;

    $method = uc $method;

    $uri = _sanitize_uri($uri);

    note "mocking request: $method $uri";

    $MOCKED_REQUEST{$method} //= {};
    my $mocked = {
        code => $code // 201,
        msg  => "Mocked Request",
    };

    if (ref $content eq 'HASH') {
        $mocked = {%$mocked, %$content};
    } else {

        # dynamic or static content: can hold a string or a code ref
        $mocked->{content} = $content;
    }

    $MOCKED_REQUEST{$method}->{$uri} = $mocked;

    return 1;
}

sub _sanitize_uri {
    my ($uri) = @_;

    #$uri = lc($uri);
    if ($uri =~ m{^(https?://)(.+)$}i) {
        my ($prot, $root) = ($1, $2);
        $root =~ s{/+}{/}g;
        $uri = $prot . $root;
    }

    return $uri;
}

1;
