package Praxo::Adapters::Otel;

use strict;
use warnings;
use HTTP::Tiny ();
use Time::HiRes ();
use Praxo::Errors qw(praxo_error);
use Praxo::Json ();

my $MAX_BODY = 512;

sub new {
    my ($class, %args) = @_;
    return bless {
        endpoint => $args{endpoint} // '',
        service_name => $args{service_name} // 'praxo-core',
        allowed_data_keys => $args{allowed_data_keys} // [],
        transport => $args{transport},
        clock => $args{clock},
        timeout => $args{timeout} // 10,
    }, $class;
}

sub emit {
    my ($self, $event) = @_;
    praxo_error('OTEL_URL', 'otel: endpoint is required')
        if $self->{endpoint} eq '';
    my $nanos = $self->{clock}
        ? $self->{clock}->()
        : int(Time::HiRes::gettimeofday() * 1_000_000_000);
    my $body = Praxo::Json::stringify($self->_payload($event, $nanos));
    my $headers = { 'content-type' => 'application/json' };
    my $response = $self->{transport}
        ? $self->{transport}->($self->{endpoint}, $body, $headers)
        : $self->_post($body, $headers);
    my $status = $response->{status} // 0;
    return if $status >= 200 && $status < 300;
    my $text = $response->{body} // '';
    $text = substr($text, 0, $MAX_BODY) if length($text) > $MAX_BODY;
    praxo_error('OTEL_HTTP', "otel: HTTP $status: $text");
}

sub _payload {
    my ($self, $event, $nanos) = @_;
    my $stamp = "$nanos";
    my $data = ref($event->{data}) eq 'HASH' ? $event->{data} : {};
    my $key = join('|',
        $event->{sessionId} // '',
        $event->{runId} // '',
        $event->{type} // '',
        $stamp,
        Praxo::Json::stringify($data),
    );
    my $trace_id = _stable_id("trace-a:$key") . _stable_id("trace-b:$key")
        . _stable_id("trace-c:$key") . _stable_id("trace-d:$key");
    my $span_id = _stable_id("span-a:$key") . _stable_id("span-b:$key");
    my @attributes = (
        _attribute('praxo.event.type', $event->{type} // ''),
    );
    push @attributes, _attribute('praxo.session.id', $event->{sessionId})
        if ($event->{sessionId} // '') ne '';
    push @attributes, _attribute('praxo.run.id', $event->{runId})
        if ($event->{runId} // '') ne '';
    push @attributes, _attribute('praxo.event.at', $stamp);
    for my $name (@{ $self->{allowed_data_keys} }) {
        next unless exists $data->{$name};
        push @attributes,
            _attribute("praxo.event.data.$name", _text($data->{$name}));
    }
    my $service = $self->{service_name} eq ''
        ? 'praxo-core'
        : $self->{service_name};
    return {
        resourceSpans => [
            {
                resource => {
                    attributes => [
                        _attribute('service.name', $service),
                    ],
                },
                scopeSpans => [
                    {
                        scope => { name => 'praxo-core' },
                        spans => [
                            {
                                traceId => $trace_id,
                                spanId => $span_id,
                                name => 'praxo.' . ($event->{type} // ''),
                                kind => 1,
                                startTimeUnixNano => $stamp,
                                endTimeUnixNano => $stamp,
                                attributes => \@attributes,
                            },
                        ],
                    },
                ],
            },
        ],
    };
}

sub _attribute {
    my ($key, $value) = @_;
    return {
        key => $key,
        value => { stringValue => defined $value ? "$value" : '' },
    };
}

sub _text {
    my ($value) = @_;
    return $value if defined $value && !ref $value;
    return Praxo::Json::stringify($value);
}

sub _stable_id {
    my ($text) = @_;
    my $hash = 0x811c9dc5;
    for my $byte (unpack 'C*', $text) {
        $hash ^= $byte;
        $hash = ($hash * 0x01000193) & 0xFFFFFFFF;
    }
    return sprintf('%08x', $hash);
}

sub _post {
    my ($self, $body, $headers) = @_;
    my $http = HTTP::Tiny->new(timeout => $self->{timeout});
    my $response = $http->post(
        $self->{endpoint},
        { headers => $headers, content => $body },
    );
    return {
        status => $response->{status} // 0,
        body => $response->{content} // '',
    };
}

1;
