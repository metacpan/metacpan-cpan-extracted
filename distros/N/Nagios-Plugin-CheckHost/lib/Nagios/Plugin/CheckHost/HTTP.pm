package Nagios::Plugin::CheckHost::HTTP;

use strict;
use warnings;

use base 'Nagios::Plugin::CheckHost';

sub _initialize {
    my $self = shift;

    $self->{check} = 'http';

    my $np = $self->_initialize_nagios(shortname => 'CHECKHOST-HTTP');

    $np->add_arg(
        spec     => 'host|H=s',
        help     => 'host to check',
        required => 1,
    );

    $np->add_arg(
        spec     => 'max_nodes|n=i',
        help     => 'max amount of nodes used for the check (default %s)',
        default  => 3,
        required => 1,
    );

    $np->add_arg(
        spec => 'warning|w=i',
        help => 'maximum number of nodes that failed '
          . 'threshold check with any code, '
          . 'outside of which a warning will be generated. '
          . 'Default %s.',
        default => 0,
    );

    $np->add_arg(
        spec => 'critical|c=i',
        help => 'maximum number of nodes that failed '
          . 'threshold check with a critical code, '
          . 'outside of which a critical will be generated. '
          . 'Default %s.',
        default => 1,
    );

    $self;
}

sub process_check_result {
    my ($self, $result) = @_;

    my $np   = $self->{nagios};
    my $opts = $np->opts;

    my @failed_nodes = ();

    foreach my $node ($result->nodes) {
        push @failed_nodes, $node unless $result->request_ok($node);

        my $response_time = $result->request_time($node);
        $np->add_perfdata(
            label => "time-" . $node->shortname,
            value => $response_time,
            uom   => 's',
        );
    }

    my $code = $np->check_threshold(
        check => scalar(@failed_nodes),
        warning  => $opts->get('warning'),
        critical => $opts->get('critical'),
    );
    
    $np->nagios_exit($code, 'report ' . $self->report_url);
}

1;
