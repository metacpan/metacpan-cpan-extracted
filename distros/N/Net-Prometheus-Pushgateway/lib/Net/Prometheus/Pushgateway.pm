package Net::Prometheus::Pushgateway;

use 5.14.2;
use strict;
use warnings;
use utf8;
use Carp qw/croak carp/;
use LWP::UserAgent;

our $VERSION    = '0.01';

my %METRIC_VALID_TYPES = (
    'untyped'       => 1,
    'counter'       => 1,
    'gauge'         => 1,
    'histogram'     => 1,
    'summary'       => 1,
);

sub new {
    my ($class, %opt) = @_;
    my $self = {};
    $self->{'host'}         = $opt{'-host'}     // croak "You must specify '-host' param";
    $self->{'port'}         = $opt{'-port'}     // croak "You must specify '-port' param";
    my $path                = $opt{'-path'};
    $self->{'ua'}           = LWP::UserAgent->new();
    $self->{'url'} = 'http://' . $self->{host} . ':' . $self->{'port'} . $path;

    return bless $self, $class;
}

sub increment {
    my $self = shift;
    $self->add(
        @_,
        '-value'    => 1,
        '-type'     => 'counter',
    );
}

sub summary {
    my $self = shift;
    $self->add(
        @_,
        '-type'     => 'summary',
    );
}

sub add {
    my ($self, %opt) = @_;
    my $metric_name         = $opt{'-metric_name'}          // croak "You must specify '-metric_name' param";
    my $label               = $opt{'-label'}                // {};
    my $value               = $opt{'-value'}                // croak "You must specify '-value' param";
    my $type                = lc($opt{'-type'})             // 'untyped';

    croak "Label must be hashref" if ref($label) ne 'HASH';
    croak "Unvalid metric type: '$type'. Valid types: " . join(', ', keys %METRIC_VALID_TYPES) if not $METRIC_VALID_TYPES{$type};

    my $raw_str = "# TYPE $metric_name $type\n";
    $raw_str .= $metric_name;
    if ($label) {
        $raw_str .= '{' . join (', ', map {$_ . '="' . $label->{$_} . '"'} keys %$label) . '}';
    }
    $raw_str .= " $value\n";
    return $self->_send_to_prometheus($raw_str);
}

sub _send_to_prometheus {
    my ($self, $str) = @_;

    my $request = HTTP::Request->new('POST', $self->{'url'});
    $request->content($str);
    my $response = $self->{'ua'}->request($request);
    return 1 if ($response->is_success);

    croak "Can't send POST request to '$self->{'url'}'. MSG: " . $response->decoded_content . " Code: " . $response->code;
}

1;

=pod

=encoding UTF-8

=head1 NAME

B<Net::Prometheus::Pushgateway> - client module for pushing metrics to prometheus exporter (pushgateway, prometheus aggregation gateway)

=head1 SYNOPSYS

    use Net::Prometheus::Pushgateway;

    # Create Net::Prometheus::Pushgateway object for pushgateway exporter
    my $metric = Net::Prometheus::Pushgateway->new(
        '-host'         => '127.0.0.1',
        '-port'         => 9091,
        '-path'         => '/metrics/job/<job_name>/instance/<instance_name>',
    );
    # OR
    # Create Net::Prometheus::Pushgateway object for prometheus aggregation gateway
    my $metric = Net::Prometheus::Pushgateway->new(
        '-host'         => '127.0.0.1',
        '-port'         => 9091,
        '-path'         => '/api/ui/metrics',
    );

    # Send increment metric
    $metric->increment(-metric_name => 'perl_metric_increment', -label => {'perl_label' => 5});

    # Send summary metric
    $metric->summary(-metric_name => 'perl_metric_summary', -label => {'perl_label' => 5}, value => 15);



=head1 METHODS

=head2 new(%opt)

Create Net::Prometheus::Pushgateway object

    Options:
        -host                   => Prometheus exporter host
        -port                   => Prometheus exporter port number
        -path                   => Path to prometheus exporter host (/api/ui/metrics - prometheus aggregation gateway, /metrics/job/<job_name>/instance/<instance_name> - prometeus

=head1 PUSH METRICS

=head1 add(%opt)

Push custom metrics

    Options:
        -metric_name            => Name of pushed metrics
        -label                  => HashRef to metric labels
        -value                  => Metric value
        -type                   => Metric type (default: untyped. Valid metric types in %Net::Prometheus::Pushgateway::METRIC_VALID_TYPE)S

=head2 increment(%opt)

Push increment metrics

    Options:
        -metric_name            => Name of pushed metrics
        -label                  => HashRef to metric labels

=head2 summary(%opt)

Push summary metrics

    Options:
        -metric_name            => Name of pushed metrics
        -value                  => Metric value

=head1 DEPENDENCE

L<LWP::UserAgent>

=head1 AUTHORS

=over 4

=item *

Pavel Andryushin <vrag867@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Pavel Andryushin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
