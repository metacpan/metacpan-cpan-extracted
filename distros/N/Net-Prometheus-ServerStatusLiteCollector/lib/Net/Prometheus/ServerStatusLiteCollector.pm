package Net::Prometheus::ServerStatusLiteCollector;

# ABSTRACT: A Net::Prometheus Collector that works in tandem with Plack::Middleware::ServerStatus::Lite

use 5.008001;
use strict;
use warnings;

use DateTime;
use DateTime::Format::ISO8601::Format;
use JSON;
use Net::Prometheus::Types qw(MetricSamples Sample);
use Parallel::Scoreboard;

our $VERSION = "0.02";

my $JSON = JSON->new->utf8(0);
my $dt_formatter = DateTime::Format::ISO8601::Format->new(second_precision => 3);

# Basic get/set attribute methods
my @attrs = qw(
    counter_file
    scoreboard
    labels
);
foreach my $attr (@attrs) {
    no strict 'refs';
    *$attr = sub {
        my $self = shift;
        if (defined $_[0]) {
            return $self->{$attr} = $_[0];
        } else {
            return $self->{$attr};
        }
    };
}

sub log {
    my $self = shift;
    my ($level, $msg) = @_;

    my $timestamp = DateTime->now(
        formatter => $dt_formatter,
        time_zone => 'America/Los_Angeles',
    )->stringify;

    print STDERR $JSON->encode({
        category   => 'Plack',
        middleware => __PACKAGE__,
        level      => $level,
        pid        => $$,
        timestamp  => $timestamp,
        message    => $msg,
    });
}

sub warn {
    my $self = shift;
    my ($msg) = @_;

    $self->log('WARN', $msg);
}

sub error {
    my $self = shift;
    my ($msg) = @_;

    $self->log('ERROR', $msg)
}

# Simple class initialization, pass in a hashref of arguments or directly
sub new {
    my $class = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my $self = bless {}, $class;

    # Copy keys from %args, but ignore invalid attributes
    for my $k (@attrs) {
        $self->$k($args{$k}) if defined $args{$k};
    }

    return $self
}

sub collect {
    my $self = shift;

    # Ripped from https://metacpan.org/source/KAZEBURO/Plack-Middleware-ServerStatus-Lite-0.36/bin/server-status

    my $stats = {};
    # Must use an already open instance of Parallel::Scoreboard since
    # initializing new will clear out scoreboard directory
    if ($self->scoreboard && ref $self->scoreboard eq 'Parallel::Scoreboard') {
        $stats = $self->scoreboard->read_all();
    }
    if (! scalar %$stats) {
        $self->warn("There is no status file in scoreboard directory. Maybe all processes are idle state and do not serve any request yet.");
        return ();
    }

    # Check counter file
    my $counter_fh;
    if ($self->counter_file) {
        unless (open($counter_fh, '<:unix', $self->counter_file)) {
            $self->error("Could not open counter file: $!");
            return ();
        }
    }

    # Check scoreboard stats is valid
    my @all_workers = keys %$stats;
    my $pstatus = eval {
        $JSON->decode($stats->{$all_workers[0]} || '{}');
    };
    if (!$pstatus->{ppid} || !$pstatus->{uptime} || !$pstatus->{ppid}) {
        $self->error("Status file does not have some necessary variables");
        return ();
    }
    my $parent_pid = $pstatus->{ppid};

    # Begin compiling stats
    my @samples = ();
    push @samples,
        MetricSamples('plack_uptime', gauge => 'Uptime of Plack server',
            [Sample('plack_uptime', $self->labels, (time - $pstatus->{uptime}))]);

    # Compile request counter stats
    if ($counter_fh) {
        seek $counter_fh, 10, 0;
        sysread $counter_fh, my $counter, 20;
        sysread $counter_fh, my $total_bytes, 20;
        no warnings;
        $counter += 0;
        $total_bytes += 0;
        my $total_kbytes = int($total_bytes / 1_000);
        push @samples,
            MetricSamples('plack_number_served_requests', gauge => 'Number of requests served by Plack process',
                [Sample('plack_number_served_requests', $self->labels, $counter)]);
        push @samples,
            MetricSamples('plack_total_kbytes_served', gauge => 'Total Kilobytes served by Plack process',
                [Sample('plack_total_kbytes_served', $self->labels, $total_kbytes)]);
    }

    # Obtain all worker process IDs
    @all_workers = ();
    my $psopt = $^O =~ m/bsd$/ ? '-ax' : '-e';
    my $ps = `LC_ALL=C command ps $psopt -o ppid,pid`;
    $ps =~ s/^\s+//mg;
    for my $line (split /\n/, $ps) {
        next if $line =~ m/^\D/;
        my ($ppid, $pid) = split /\s+/, $line, 2;
        push @all_workers, $pid if $ppid == $parent_pid;
    }

    # Count busy and idle workers
    my $idle = 0;
    my $busy = 0;
    my @process_status;
    for my $pid (@all_workers) {
        my $json = $stats->{$pid};
        $pstatus = eval {
            $JSON->decode($json || '{}');
        };
        $pstatus ||= {};
        if ($pstatus->{status} && $pstatus->{status} eq 'A') {
            $busy++;
        }
        else {
            $idle++;
        }

        if (defined $pstatus->{time}) {
            $pstatus->{ss} = time - $pstatus->{time};
        }
        $pstatus->{pid} ||= $pid;
        delete $pstatus->{time};
        delete $pstatus->{ppid};
        delete $pstatus->{uptime};
        push @process_status, $pstatus;
    }
    push @samples,
        MetricSamples('plack_busy_workers', gauge => 'Number of busy Plack workers',
            [Sample('plack_busy_workers', $self->labels, $busy)]);
    push @samples,
        MetricSamples('plack_idle_workers', gauge => 'Number of idle Plack workers',
            [Sample('plack_idle_workers', $self->labels, $idle)]);

    $stats = {};
    foreach my $pstatus (@process_status) {
        foreach my $stat (qw(method uri remote_addr protocol)) {
            $stats->{$stat}{$pstatus->{$stat}}++ if $pstatus->{$stat};
        }
    }
    foreach my $stat (qw(method uri remote_addr protocol)) {
        my $stat_counts = $stats->{$stat};
        push @samples,
            MetricSamples("plack_sample_$stat", gauge => "Count of $stat for sample of requests",
                [
                    map {
                        Sample(
                            "plack_sample_$stat",
                            [@{$self->labels}, $stat => $_],
                            $stat_counts->{$_}
                        )
                    }
                    (keys %$stat_counts)
                ]
            );
    }

    return @samples;
}

1;
__END__

=encoding utf-8

=head1 SYNOPSIS

    use Net::Prometheus::ServerStatusLiteCollector;

=head1 DESCRIPTION

Net::Prometheus::ServerStatusLiteCollector is ...

=head1 AUTHOR

Steven Leung E<lt>stvleung@gmail.comE<gt>

=cut
