package Net::Hadoop::DFSAdmin::ReportParser;

use strict;
use warnings;

our $VERSION = "0.3";

sub parse {
    my ($this, @lines) = @_;
    chomp @lines;
    my @summary = ();
    while (@lines) {
        last if $lines[0] =~ m!^-+$!;
        push @summary, (shift @lines);
    }
    return +{
        namenode(@summary),
        datanodes(@lines),
    };
}

sub namenode {
    my @summary = @_;
    my %values = ();
    foreach my $line (@summary) {
        if ($line =~ m!^Configured Capacity: *(\d+)!i) {
            $values{capacity_configured} = $1;
        }
        elsif ($line =~ m!^Present Capacity: *(\d+)!i) {
            $values{capacity_present} = $1;
            $values{capacity} = $1;
        }
        elsif ($line =~ m!^DFS Remaining: *(\d+)!i) {
            $values{remaining} = $1;
        }
        elsif ($line =~ m!^DFS Used: *(\d+)!i) {
            $values{used} = $1;
        }
        elsif ($line =~ m!^DFS Used%: *([.0-9]+)!i) {
            $values{used_percent} = $1;
        }
        elsif ($line =~ m!^Under replicated blocks: *(\d+)!i) {
            $values{blocks_under_replicated} = $1;
        }
        elsif ($line =~ m!^Blocks with corrupt replicas: *(\d+)!i) {
            $values{blocks_with_corrupt_replicas} = $1;
        }
        elsif ($line =~ m!^Missing blocks: *(\d+)!i) {
            $values{blocks_missing} = $1;
        }
    }
    $values{remaining_percent} = undef;
    if (defined $values{remaining} and defined $values{capacity_configured}) {
        $values{remaining_percent} = sprintf("%.2f", $values{remaining} * 100 / $values{capacity_configured});
    }
    return %values;
}

sub datanodes {
    my @lines = @_;
    my %datanode_summary = ();
    my @datanodes = ();
    my @chunk = ();

    foreach my $line (@lines) {
        if ($line =~ m!^\s*$!) {
            push @datanodes, datanode(@chunk) if scalar(@chunk) > 0;
            @chunk = ();
            next;
        }

        next if $line =~ m!^-+$!;

        if ($line =~ m!^Datanodes available: (\d+) \((\d+) total, (\d+) dead\)!i) {
            %datanode_summary = (
                datanodes_num => $2,
                datanodes_available => $1,
                datanodes_dead => $3,
            );
            next;
        }

        push @chunk, $line;
    }
    if (scalar(@chunk) > 0) {
        push @datanodes, datanode(@chunk);
    }
    my $capacity_total = 0;
    my %aggr = (
        used_non_dfs_total => 0,
        used_non_dfs_total_percent => 0,
        datanode_remaining_min => undef,
        datanode_remaining_max => undef,
    );

    foreach my $node (@datanodes) {
        $capacity_total += $node->{capacity_configured};
        $aggr{used_non_dfs_total} += $node->{used_non_dfs};
        if (not defined $aggr{datanode_remaining_min} or $aggr{datanode_remaining_min} > $node->{remaining}) {
            $aggr{datanode_remaining_min} = $node->{remaining};
        }
        if (not defined $aggr{datanode_remaining_max} or $aggr{datanode_remaining_max} < $node->{remaining}) {
            $aggr{datanode_remaining_max} = $node->{remaining};
        }
    }
    $aggr{used_non_dfs_total_percent} = sprintf("%.2f", $aggr{used_non_dfs_total} * 100 / $capacity_total);

    return (
        %datanode_summary,
        %aggr,
        datanodes => \@datanodes,
    );
}

sub datanode {
    my @lines = @_;
    my %node = ();
    foreach my $line (@lines){
        if ($line =~ m!^Name: *([-.:0-9a-zA-Z]+)!i) {
            $node{name} = $1;
        }
        elsif ($line =~ m!^Decommission Status *: *([a-zA-Z0-9]+)!i) {
            $node{status} = lc($1);
        }
        elsif ($line =~ m!^Configured Capacity: *(\d+)!i) {
            $node{capacity_configured} = $1;
        }
        elsif ($line =~ m!^DFS Used: *(\d+)!i) {
            $node{used_dfs} = $1;
        }
        elsif ($line =~ m!^Non DFS Used: *(\d+)!i) {
            $node{used_non_dfs} = $1;
        }
        elsif ($line =~ m!^DFS Remaining: *(\d+)!i) {
            $node{remaining} = $1;
        }
        elsif ($line =~ m!^DFS Used%: ([.0-9]+)!i) {
            $node{used_percent} = $1;
        }
        elsif ($line =~ m!^DFS Remaining%: ([.0-9]+)!i) {
            $node{remaining_percent} = $1;
        }
        elsif ($line =~ m!^Last contact: (.*)!i) {
            $node{last_connect} = $1;
        }
    }
    return \%node;
}

1;


__END__

=head1 NAME

Net::Hadoop::DFSAdmin::ReportParser - Parser module for 'hadoop dfsadmin -report'

=head1 SYNOPSIS

  use Net::Hadoop::DFSAdmin::ReportParser;
  open($fh, '-|', 'hadoop', 'dfsadmin', '-report')
      or die "failed to execute 'hadoop dfsadmin -report'";
  my @lines = <$fh>;
  close($fh);

  my $r = Net::Hadoop::DFSAdmin::ReportParser->parse(@lines);

=head1 AUTHOR

TAGOMORI Satoshi E<lt>tagomoris {at} gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
