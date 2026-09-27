use strict;
use warnings;

package Test::NFA;

# Test helpers for Net::Flickr::API: an API object whose clock is fake and
# whose Flickr client replays canned responses. -- claude, 2026-09-26

use Exporter 'import';
our @EXPORT_OK = qw(new_api response);

use Config::Simple;
use HTTP::Response;
use Log::Dispatch::Code;

sub response {
        my $code    = shift;
        my @headers = @_;

        my $body = $code == 200 ? '<rsp stat="ok"><ok/></rsp>'
                 :                "status $code";

        return HTTP::Response->new($code, "status $code", \@headers, $body);
}

# new_api(responses => \@responses, %config)
#
# Any other arguments are flickr.* config params.  If responses run out, the
# last one is replayed.  If latency is given, each request advances the fake
# clock by that much.
sub new_api {
        my %arg = @_;

        my $responses = delete $arg{responses} || [ response(200) ];
        my $latency   = delete $arg{latency}   || 0;

        my $cfg = Config::Simple->new(syntax => 'ini');
        $cfg->param('flickr.api_handler', 'LibXML');
        $cfg->param("flickr.$_", $arg{$_}) for keys %arg;

        my $api = Test::NFA::API->new($cfg);
        $api->{api} = Test::NFA::Client->new($api, $responses, $latency);

        # Errors are logged to STDERR; collect them for inspection instead.
        $api->log->remove('__error');
        $api->log->add(Log::Dispatch::Code->new(
                name      => '__test',
                min_level => 'error',
                code      => sub {
                        my %msg = @_;
                        push @{ $api->{'__logged'} }, $msg{message};
                },
        ));

        return $api;
}

package Test::NFA::API;

use parent -norequire, 'Net::Flickr::API';
BEGIN { require Net::Flickr::API }

sub _now {
        my $self = shift;
        return $self->{'__fake_now'} ||= 1_800_000_000;
}

sub _sleep {
        my $self    = shift;
        my $seconds = shift;

        push @{ $self->{'__sleeps'} }, $seconds;
        $self->{'__fake_now'} = $self->_now + $seconds;
}

sub sleeps {
        my $self = shift;
        return $self->{'__sleeps'} || [];
}

sub logged_errors {
        my $self = shift;
        return $self->{'__logged'} || [];
}

sub advance {
        my $self    = shift;
        my $seconds = shift;

        $self->{'__fake_now'} = $self->_now + $seconds;
}

package Test::NFA::Client;

sub new {
        my ($class, $api, $responses, $latency) = @_;

        return bless {
                api       => $api,
                responses => [ @$responses ],
                latency   => $latency,
                sent_at   => [],
        }, $class;
}

sub execute_request {
        my $self = shift;

        push @{ $self->{sent_at} }, $self->{api}->_now;
        $self->{api}->advance($self->{latency});

        my $responses = $self->{responses};
        return @$responses > 1 ? shift @$responses : $responses->[0];
}

sub calls {
        my $self = shift;
        return scalar @{ $self->{sent_at} };
}

sub sent_at {
        my $self = shift;
        return $self->{sent_at};
}

1;
