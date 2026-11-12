package Praxo::Adapters::Harmovela;

use strict;
use warnings;
use HTTP::Tiny ();
use Time::HiRes ();
use Praxo::Errors qw(praxo_error);
use Praxo::Json ();

my $MAX_BODY = 1024;

sub new {
    my ($class, %args) = @_;
    my $base_url = $args{base_url} // '';
    $base_url =~ s{/+$}{};
    return bless {
        base_url => $base_url,
        source => $args{source} // 'praxo-core',
        spec_version => $args{spec_version} // '0.2',
        transport => $args{transport},
        clock => $args{clock},
        timeout => $args{timeout} // 10,
    }, $class;
}

sub emit {
    my ($self, $event) = @_;
    praxo_error('HARMOVELA_URL', 'harmovela: base URL is required')
        if $self->{base_url} eq '';
    my ($seconds, $nanos) = $self->_now;
    my $payload = ref($event->{data}) eq 'HASH' ? { %{ $event->{data} } } : {};
    my $session_id = $event->{sessionId};
    $payload->{session_id} = $session_id
        if defined $session_id && $session_id ne '';
    my $run_id = $event->{runId};
    $payload->{run_id} = $run_id if defined $run_id && $run_id ne '';
    my $envelope = {
        spec_version => $self->{spec_version},
        id => _event_id($event, $seconds, $nanos),
        type => $event->{type},
        source => $self->{source},
        created_at => _rfc3339_nano($seconds, $nanos),
        payload => $payload,
    };
    my $body = Praxo::Json::stringify($envelope);
    my $headers = { 'content-type' => 'application/json' };
    my $response = $self->{transport}
        ? $self->{transport}->('/events', $body, $headers)
        : $self->_post('/events', $body, $headers);
    my $status = $response->{status} // 0;
    return if $status >= 200 && $status < 300;
    my $text = $response->{body} // '';
    $text = substr($text, 0, $MAX_BODY) if length($text) > $MAX_BODY;
    praxo_error('HARMOVELA_HTTP', "harmovela: HTTP $status: $text");
}

sub _now {
    my ($self) = @_;
    return $self->{clock}->() if $self->{clock};
    my ($seconds, $microseconds) = Time::HiRes::gettimeofday();
    return ($seconds, $microseconds * 1000);
}

sub _event_id {
    my ($event, $seconds, $nanos) = @_;
    my $prefix = $event->{runId};
    $prefix = $event->{sessionId}
        if !defined($prefix) || $prefix eq '';
    $prefix = 'event' if !defined($prefix) || $prefix eq '';
    return $prefix . '-' . ($seconds * 1_000_000_000 + $nanos);
}

sub _rfc3339_nano {
    my ($seconds, $nanos) = @_;
    my @parts = gmtime($seconds);
    return sprintf(
        '%04d-%02d-%02dT%02d:%02d:%02d.%09dZ',
        $parts[5] + 1900, $parts[4] + 1, $parts[3],
        $parts[2], $parts[1], $parts[0], $nanos
    );
}

sub _post {
    my ($self, $path, $body, $headers) = @_;
    my $http = HTTP::Tiny->new(timeout => $self->{timeout});
    my $response = $http->post(
        $self->{base_url} . $path,
        { headers => $headers, content => $body },
    );
    return {
        status => $response->{status} // 0,
        body => $response->{content} // '',
    };
}

1;
