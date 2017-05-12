#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;

BEGIN {
    my $debug_flag = $ENV{SMART_COMMENTS} || $ENV{SMART_COMMENT} || $ENV{SMART_DEBUG} || $ENV{SC};
    if ($debug_flag) {
        my @p = map { '#'x$_ } ($debug_flag =~ /([345])\s*/g);
        use UNIVERSAL::require;
        Smart::Comments->use(@p);
    }
}

use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Net::Scan::SSH::Server::SupportedAuth qw(:flag);
use Net::CIDR qw(:all);

MAIN: {
    my %opt;
    Getopt::Long::Configure("bundling");
    GetOptions(\%opt,
               'help|h|?') or pod2usage(-verbose=>1);
    pod2usage(-verbose=>1) if exists $opt{'help'};
    pod2usage("missing target host") unless @ARGV;

    ### %opt

    print "HOST                   : SSH2  SSH1 (K=publickey, P=password)\n";
    print "===================================\n";
    for my $target (map { expand_cidr($_) } @ARGV) {
        ### $target
        my ($host, $port) = $target =~ /^([^:]+)(?::(\d+))?$/;
        $port ||= 22;
        ### host, port: $host, $port

        my $scanner = Net::Scan::SSH::Server::SupportedAuth->new(
            host => $host,
            port => $port,
           );
        my $sa = $scanner->scan;

        printf("%-23s: 2=%s%s  1=%s%s\n",
               $port == 22 ? $host : "$host:$port",
               format_result($sa),
              );
    }
}

sub expand_cidr {
    my $addr = shift;
    my @addrs;

    if ($addr =~ m{^([0-9.]+/\d+)(?::(\d+))?}) {
        my($cidr, $port) = ($1, $2);
        $port ||= 22;
        my @ranges = Net::CIDR::cidr2range($cidr);

        for my $r (map { [split(/-/,$_)] } @ranges) {
            my $beg = unpack('N', pack('C4', split(/\./, $r->[0])));
            my $end = unpack('N', pack('C4', split(/\./, $r->[1])));
            my $cur = $beg;

            while ($cur <= $end) {
                my $ip = join('.', unpack('C4', pack('N', $cur)));
                push @addrs, "${ip}:${port}";
                $cur++;
            }
        }
    } else {
        push @addrs, $addr;
    }

    return @addrs;
}

sub format_result {
    my $sa = shift;

    return (
        ($sa->{2} & $AUTH_IF{publickey}) ? 'K' : '-',
        ($sa->{2} & $AUTH_IF{password} ) ? 'P' : '-',
        ($sa->{1} & $AUTH_IF{publickey}) ? 'K' : '-',
        ($sa->{1} & $AUTH_IF{password} ) ? 'P' : '- ',
       );
}

__END__

=head1 NAME

B<scan-sshauth.pl> - probe SSH supported authentication method

=head1 SYNOPSIS

B<scan-sshauth.pl> [ B<--help> ] HOSTNAME | IP_ADDRESS | CIDR ...

  $ scan-sshauth.pl abbasak booofy cagayan diu
  $ scan-sshauth.pl 192.168.1.1
  $ scan-sshauth.pl 192.168.1.1:10022
  $ scan-sshauth.pl 192.168.1.1:10022 192.168.1.2
  $ scan-sshauth.pl 192.168.1.0/24
  $ scan-sshauth.pl 192.168.1.0/24:10022

=head1 DESCRIPTION

probe supported SSH authentication method of specified hostname or IP address or CIDR block.

=head1 OPTIONS

=over 4

=item B<--help>

show help.

=item B<hostname>

=item B<hostname:port>

=item B<IP_address>

=item B<IP_address:port>

=item B<CIDR>

=item B<CIDR:port>


=back

=head1 SEE ALSO

L<Net::Scan::SSH::Server::SupportedAuth|Net::Scan::SSH::Server::SupportedAuth>

=head1 AUTHOR

HIROSE, Masaaki E<lt>hirose31@gmail.comE<gt>

=cut

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# coding: euc-jp
# End:

# vi: set ts=4 sw=4 sts=0 :
