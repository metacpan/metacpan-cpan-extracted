use strict;
use warnings;

use List::Util qw /sum/;
use Regexp::Common qw /number/;

my @servers;
my @clients;
my $interval = <>;
my ($start_time, $end_time, $duration);
if ($interval =~ /^($RE{num}{real})\.\.($RE{num}{real})$/) {
    $start_time = $1;
    $end_time = $2;
    $duration = $end_time - $start_time;
} else {
    die "syntax error: no interval found.\n";
}
#warn "$start_time .. $end_time ($duration)";
my $prev_time = 0;
while (<>) {
    if (/^\@($RE{num}{real}) <Server (\d+)> (<==|==>) Client (\d+)/) {
        my ($time, $server_id, $direction, $client_id) = ($1, $2, $3, $4);
        my $server = $servers[$server_id] ||= {
            q_len => [[0 => 0]],
        };
        my $client = $clients[$client_id] ||= {
            enter => undef,
            start_service => undef,
            leave => undef,
        };
        my $prev_len = $server->{q_len}->[-1]->[-1];
        if ($direction eq '<==') {
            push @{ $server->{q_len} }, [ $time => ++$prev_len ];
            $client->{enter} = $time;
            $client->{q_len} = $prev_len;
        } else {
            push @{ $server->{q_len} }, [ $time => --$prev_len ];
            $client->{leave} = $time;
        }
    }
    elsif (/^@($RE{num}{real}) <Server (\d+)> serves Client (\d+)/) {
        my ($time, $server_id, $client_id) = ($1, $2, $3);
        $clients[$client_id]->{start_service} = $time;
    }
    else {
        die "syntax error: line $.: $_\n";
    }
}

my (@ave_len, @ave_len2);
for (0..$#servers) {
    my $server = $servers[$_];
    next if !defined $server;
    print "<Server $_>\n";
    my ($accum, $accum2, $prev_time, $prev_len) = (0, 0, 0, 0);
    for my $item (@{ $server->{q_len} }) {
        my ($time, $len) = @$item;
        #warn "len = $len\n";
        $accum += ($time - $prev_time) * $prev_len;
        if ($prev_len > 1) {
            $accum2 += ($time - $prev_time) * ($prev_len - 1);
        }
        $prev_len  = $len;
        $prev_time = $time;
    }
    $accum += $prev_len * ($end_time - $prev_time);
    if ($prev_len > 1) {
       $accum2 += ($end_time - $prev_time) * ($prev_len - 1);
   }
    my $ave_len = $accum / $duration;
    print "  Customers in system: $ave_len\n";
    my $ave_len2 = $accum2 / $duration;
    print "  Customers in queue: $ave_len2\n";
    push @ave_len, $ave_len;
    push @ave_len2, $ave_len2;
}

print "Total\n";

print "  Customers in system: ", sum(@ave_len) / scalar(@ave_len), "\n";
print "  Customers in queue: ", sum(@ave_len2) / scalar(@ave_len2), "\n";

my ($count, $accum) = (0, 0);
for (0..$#clients) {
    my $client = $clients[$_];
    next if !defined $client;
    if (defined $client->{enter} and defined $client->{leave}) {
        $accum += $client->{leave} - $client->{enter};
        $count++;
    }
}
print "  Time in system: ", $accum / $count, "\n";

($count, $accum) = (0, 0);
for (0..$#clients) {
    my $client = $clients[$_];
    next if !defined $client;
    if (defined $client->{enter} and defined $client->{start_service}) {
        $accum += $client->{start_service} - $client->{enter};
        $count++;
    }
}
print "  Time in queue: ", $accum / $count, "\n";

($count, $accum) = (0, 0);
for (0..$#clients) {
    my $client = $clients[$_];
    next if !defined $client;
    if (defined $client->{start_service} and defined $client->{leave}) {
        $accum += $client->{leave} - $client->{start_service};
        $count++;
    }
}
print "  Service time: ", $accum / $count, "\n";
