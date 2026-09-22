#!/usr/bin/env perl
use strict;
use warnings;
use v5.20;

use Getopt::Long qw(GetOptions);
use File::Temp qw(tempfile);
use IO::Async::Loop;
use Net::Async::Kubernetes;

my %opt = (
    kubeconfig => $ENV{KUBECONFIG} // "$ENV{HOME}/.kube/config",
    namespace  => 'default',
    pod        => undef,
    container  => undef,
    tail_lines => 20,
    port       => 80,
);

GetOptions(
    'kubeconfig=s' => \$opt{kubeconfig},
    'namespace=s'  => \$opt{namespace},
    'pod=s'        => \$opt{pod},
    'container=s'  => \$opt{container},
    'tail-lines=i' => \$opt{tail_lines},
    'port=i'       => \$opt{port},
) or die "invalid options\n";

my $loop = IO::Async::Loop->new;
my $kube = Net::Async::Kubernetes->new(kubeconfig => $opt{kubeconfig});
$loop->add($kube);

sub run_step {
    my ($title, $code) = @_;
    say "\n== $title ==";
    my $ok = eval { $code->(); 1 };
    if ($ok) {
        say "OK";
        return 1;
    }
    my $err = $@ || 'unknown error';
    $err =~ s/\s+\z//;
    say "FAILED: $err";
    return 0;
}

say "kubeconfig: $opt{kubeconfig}";
say "namespace:  $opt{namespace}";

my $selected_pod;
run_step('Discover pod', sub {
    my $pods = $kube->list('Pod', namespace => $opt{namespace})->get;
    my @items = @{$pods->items || []};
    die "no pods in namespace $opt{namespace}" unless @items;

    if ($opt{pod}) {
        ($selected_pod) = grep { $_->metadata->name eq $opt{pod} } @items;
        die "pod '$opt{pod}' not found in namespace $opt{namespace}" unless $selected_pod;
    } else {
        ($selected_pod) = grep { (($_->status->phase // '') eq 'Running') } @items;
        $selected_pod ||= $items[0];
    }

    say "selected pod: " . $selected_pod->metadata->name;
    say "phase: " . ($selected_pod->status->phase // 'unknown');
});

exit 1 unless $selected_pod;
my $pod_name = $selected_pod->metadata->name;

run_step('One-shot log()', sub {
    my $text = $kube->log('Pod', $pod_name,
        namespace => $opt{namespace},
        tailLines => $opt{tail_lines},
        (defined($opt{container}) ? (container => $opt{container}) : ()),
    )->get;

    my @lines = split /\n/, $text;
    my $show = @lines > 3 ? 3 : scalar @lines;
    for my $i (0 .. $show - 1) {
        say "log[$i]: $lines[$i]";
    }
});

run_step('exec()', sub {
    my $stdout = '';
    my $stderr = '';
    my $status = '';
    my $done = $loop->new_future;

    $kube->exec('Pod', $pod_name,
        namespace => $opt{namespace},
        (defined($opt{container}) ? (container => $opt{container}) : ()),
        command   => ['sh', '-c', 'echo net-async-kubernetes-exec-ok'],
        stdin     => 0,
        stdout    => 1,
        stderr    => 1,
        tty       => 0,
        on_frame  => sub {
            my ($ch, $payload) = @_;
            $stdout .= $payload if $ch == 1;
            $stderr .= $payload if $ch == 2;
            $status .= $payload if $ch == 3;
        },
        on_close  => sub { $done->done unless $done->is_ready; },
        on_error  => sub {
            my ($err) = @_;
            $done->fail($err) unless $done->is_ready;
        },
    )->get;

    $done->get;
    say "exec stdout: $stdout" if length $stdout;
    say "exec stderr: $stderr" if length $stderr;
    say "exec status: $status" if length $status;
});

run_step('attach()', sub {
    my $done = $loop->new_future;
    my $opened = 0;

    $kube->attach('Pod', $pod_name,
        namespace => $opt{namespace},
        (defined($opt{container}) ? (container => $opt{container}) : ()),
        stdin     => 0,
        stdout    => 1,
        stderr    => 1,
        tty       => 0,
        on_open   => sub {
            my ($session) = @_;
            $opened = 1;
            $session->close(code => 1000);
        },
        on_close  => sub { $done->done unless $done->is_ready; },
        on_error  => sub {
            my ($err) = @_;
            $done->fail($err) unless $done->is_ready;
        },
    )->get;

    $done->get;
    die "attach did not open" unless $opened;
});

run_step('port_forward()', sub {
    my $done = $loop->new_future;
    my $opened = 0;
    my $status = '';

    $kube->port_forward('Pod', $pod_name,
        namespace => $opt{namespace},
        ports     => [$opt{port}],
        on_open   => sub {
            my ($session) = @_;
            $opened = 1;
            $session->close(code => 1000);
        },
        on_frame  => sub {
            my ($ch, $payload) = @_;
            $status .= $payload if $ch == 3;
        },
        on_close  => sub { $done->done unless $done->is_ready; },
        on_error  => sub {
            my ($err) = @_;
            $done->fail($err) unless $done->is_ready;
        },
    )->get;

    $done->get;
    die "port_forward did not open" unless $opened;
    say "port_forward status: $status" if length $status;
});

run_step('cp_to_pod()/cp_from_pod()', sub {
    my ($in_fh, $local_in) = tempfile('nak8s-cp-in-XXXX', TMPDIR => 1, UNLINK => 1);
    my ($out_fh, $local_out) = tempfile('nak8s-cp-out-XXXX', TMPDIR => 1, UNLINK => 1);
    close $out_fh;

    my $payload = "net-async-kubernetes-cp-ok\n";
    print {$in_fh} $payload;
    close $in_fh;

    my $remote = "/tmp/nak8s-cp-$$.txt";

    $kube->cp_to_pod('Pod', $pod_name,
        namespace => $opt{namespace},
        (defined($opt{container}) ? (container => $opt{container}) : ()),
        local  => $local_in,
        remote => $remote,
    )->get;

    $kube->cp_from_pod('Pod', $pod_name,
        namespace => $opt{namespace},
        (defined($opt{container}) ? (container => $opt{container}) : ()),
        remote => $remote,
        local  => $local_out,
    )->get;

    open my $fh, '<:raw', $local_out or die "cannot read $local_out: $!";
    local $/ = undef;
    my $got = <$fh>;
    close $fh;

    die "cp roundtrip mismatch" unless defined($got) && $got eq $payload;
    say "cp roundtrip bytes: " . length($got);
});

say "\nDemo completed.";
