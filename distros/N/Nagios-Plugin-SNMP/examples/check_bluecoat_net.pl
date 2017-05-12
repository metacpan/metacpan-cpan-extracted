#!/usr/local/bin/perl

# nagios: +epn

=pod

=head1 NAME

check_bluecoat_net.pl - Check Bluecoat network pressure 

=head1 DESCRIPTION

This script checks network pressure on a Bluecoat Proxy device.  It will
return memory pressure % utilization as perfdata for each interface on
the Bluecoat proxy being checked.  Network pressure thresholds are set on
the device by the Bluecoat proxy administrator so we do not need to ask
the user to provide warning nor critical thresholds to the script.

=cut

sub check_bluecoat_net {

    use strict;

    use FindBin;
    use lib "$FindBin::Bin/lib";
    use Nagios::Plugin::SNMP;

    my $LABEL = 'BLUECOAT-NET';

    my $plugin = Nagios::Plugin::SNMP->new(
        'shortname' => $LABEL,
        'usage' => 'USAGE: %s'
    );

    $plugin->getopts;

    my $DEBUG = $plugin->opts->get('snmp-debug');

    #  Return from current state will be one of these:
    my @states = qw(ok low-warning warning high-warning
                    low-critical critical high-critical);

    #  These are all tables, one entry in each per interface
    my %oids = qw(
        .1.3.6.1.4.1.3417.2.8.3.1.1.2 netName
        .1.3.6.1.4.1.3417.2.8.3.1.1.3 netUtilizationValue
        .1.3.6.1.4.1.3417.2.8.3.1.1.4 netWarningThreshold
        .1.3.6.1.4.1.3417.2.8.3.1.1.6 netCriticalThreshold
        .1.3.6.1.4.1.3417.2.8.3.1.1.9 netCurrentState
    );

    my %net;

    for my $oid (keys %oids) {

        debug("Walking table $oid");

        my $results = $plugin->walk($oid);

        for my $result (keys %$results) {

            my $table = $results->{$result};

            for my $item (keys %$table) {

                my ($base, $idx) = ($item =~ m/^(.+)\.(\d+)$/);
                my $key = $oids{$base};

                debug("$idx: $key = $table->{$item}");

                $net{$idx} = {} if ! exists $net{$idx};
                $net{$idx}->{$key} = $table->{$item};

            }

        }

    }

    #  Close and destroy session
    $plugin->close();

    my @perf_data;

    my @ok;
    my @warn;
    my @crit;

    my $level = OK;

    for my $idx (sort keys %net) {

        my %net = %{$net{$idx}};
        my $name = $net{'netName'};

        if ($net{'netCurrentState'} == 0) {

            push(@ok, "$name $net{'netUtilizationValue'}%");

        } elsif (($net{'netCurrentState'} > 0) && 
                 ($net{'netCurrentState'} < 6)) {

            push(@warn, "$name $net{'netUtilizationValue'}% " .
                        ">= $net{'netWarningThreshold'}");
            $level = WARNING unless $level == CRITICAL;

        } else {
            push(@crit, "$name $net{'netUtilizationValue'}% " .
                        ">= $net{'netCriticalThreshold'}");
            $level = CRITICAL;
        }

        $name =~ s/ utilization//gi;
        $name =~ s/ /_/g;
        $name =~ s/:/-/g;

        push(@perf_data, "'${name}'=$net{'netUtilizationValue'};" .
                         "$net{'netWarningThreshold'};" .
                         "$net{'netCriticalThreshold'};" .
                         "0;0");
                 
    }

    my $output = "$LABEL ";

    if (scalar(@crit) > 0) {
        $output .= 'CRITICAL ' . join(', ', @crit) . ' ';
    }

    if (scalar(@warn) > 0) {
        $output .= 'WARNING ' . join(', ', @warn) . ' ';
    }

    if (scalar(@ok) > 0) {
        $output .= 'OK ' . join(', ', @ok);
    }

    print "$output | " . join(' ', @perf_data) . "\n";

    return $level;

    sub debug {

        return unless $DEBUG == 1;

        my $msg = shift;

        print STDERR scalar(localtime()) . ": $msg\n";

    }
}

exit check_bluecoat_net();
