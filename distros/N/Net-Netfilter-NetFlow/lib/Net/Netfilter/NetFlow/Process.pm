package Net::Netfilter::NetFlow::Process;
{
  $Net::Netfilter::NetFlow::Process::VERSION = '1.113260';
}

use strict;
use warnings FATAL => 'all';

use base 'Exporter';
our @EXPORT = qw(
    conntrack_init
    ct2ft
    ptee
);

use POSIX; # core
use Time::HiRes 'gettimeofday'; # core
use IPC::Run 'run';
use Log::Dispatch::Config;
use Log::Dispatch::Configurator::Any;
use Net::Netfilter::NetFlow::Utils;
use Net::Netfilter::NetFlow::ConntrackFormat;

# poke conntrack kernel hooks into waking up (bug?)
sub conntrack_init {
    my $config = shift;
    my $conntrack = can_run($config->{conntrack}->{progname})
        or die "Failed to find a local copy of conntrack in the path\n";

    run [$conntrack, format_args($config->{conntrack}, 'init_')],
        '>', '/dev/null', '2>&1';
}

# convert the conntrack output to flow-tools CSV input format
sub ct2ft {
    my $config = shift;
    my $got_alrm = 0;
    my $tracker = {};

    # respond to SIGALRM (thanks go to perlipc man page)
    my $alrm_handler = sub { ++$got_alrm };
    # POSIX unmasks the sigprocmask properly
    my $action = POSIX::SigAction->new($alrm_handler);
    POSIX::sigaction(&POSIX::SIGALRM, $action);

    my $ttl = $config->{ct2ft}->{ttl} || 60 * 60 * 24 * 7; # seven days;
    alarm $ttl;

    # XXX alarm will not fire until we have input to process
    while (<>) {

        # pruge tracked connections older than TTL seconds
        if ($got_alrm) {
            alarm 0;
            foreach my $p (keys %{$tracker}) {
                foreach my $k (keys %{$tracker->{$p}}) {
                    delete $tracker->{$p}->{$k}
                        if $tracker->{$p}->{$k} < ($^T - $ttl);
                }
            }
            $got_alrm = 0;
            alarm $ttl;
        }

        chomp;
        s/[^\s\d.A-Z]//g;
        next if m/^\s+$/;
        my $line = $_; 
        my @fields = split /\s+/, $line;
        next unless scalar @fields > 12; 

        next unless $fields[1] =~ m/^(NEW|DESTROY)$/;
        my $mode = $1; 
        next unless $fields[2] =~ m/^(1|6|17)$/;
        my $proto = $1; 

        next if $proto == 1 and 
            (($fields[5] ne '8') and ($fields[6] ne '8')); # only interested in ECHO

        if ($mode eq 'NEW') {
            my $key = join ',', @fields[ @{$ct_new_key{$proto}} ];
            $tracker->{$proto}->{$key} = $fields[0];
            next;
        }   

        my $key = join ',', @fields[ @{$ct_destroy_key{$proto}} ];
        next unless exists $tracker->{$proto}->{$key};

        my ($start_secs, $start_micsecs) = split /\./, $tracker->{$proto}->{$key};
        my ($end_secs,   $end_micsecs)   = split /\./, $fields[0];

        # secs and nanosecs (^9) since 1970
        my ($unix_secs, $micsecs) = gettimeofday;
        my $unix_nsecs = $micsecs * 1_000;

        # millisecs (^3) since "boot"
        my $sysuptime = (($unix_secs - $^T) * 1_000) + int ($micsecs / 1_000);

        # flow start/end in millisecs since "boot"
        my $first = (($start_secs - $^T) * 1_000) + int ($start_micsecs / 1_000);
        my $last  = (($end_secs   - $^T) * 1_000) + int ($end_micsecs   / 1_000);

        for my $dir (qw( private_src public_src dst )) {
            my ($dpkts, $doctets, $srcaddr, $dstaddr, $srcport, $dstport)
                = @fields[ @{$ct_mask_fields{$proto}{$dir}} ];

            print join ',',
                $unix_secs,
                $unix_nsecs,
                $sysuptime,
                $config->{flow_send}->{args}->[0] || '127.0.0.1',
                $dpkts,
                $doctets,
                $first,
                $last,
                $srcaddr,
                $dstaddr,
                '0.0.0.0', # NEXTHOP
                0, # INPUT (SNMP idx)
                0, # OUTPUT (SNMP idx)
                $srcport || 0, # might be ICMP
                $dstport || 0, # might be ICMP
                $proto,
                0, # TOS
                0; # TCP_FLAGS
            print "\n";
        }   
    } # while (<>)
}

# set up output tee to local syslog, and next process in pipe
sub ptee {
    my $config = shift;
    Log::Dispatch::Config->configure_and_watch(
        Log::Dispatch::Configurator::Any->new($config->{ptee}->{conf}) );
    my $dispatcher = Log::Dispatch::Config->instance;

    while (<>) {
        $dispatcher->notice($_);
    }
}

__END__

=head1 AUTHOR

Oliver Gorwits C<< <oliver@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) The University of Oxford 2009.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

