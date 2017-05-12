#!/usr/bin/env perl
use strict;
use warnings;
use Net::Proxy;
use Getopt::Long;
use Benchmark qw( :hireswallclock timediff );
use Pod::Usage;

my %conf = (
    proxy       => 10000,
    server      => 10001,
    connections => 1,
);
GetOptions( \%conf, 'help', 'manual', 'verbose+', map {"$_=s"} keys %conf )
    or pod2usage(2);
pod2usage(1) if $conf{help};
pod2usage( -verbose => 2 ) if $conf{manual};

# mark the beginning of the benchmark/profiling
my $t0;

for my $item (qw( proxy server )) {
    $conf{$item} = ":$conf{$item}" if $conf{$item} !~ /:/;
    $conf{$item} = [ split /:/, $conf{$item} ];
}

# setup the proxy
my $proxy = Net::Proxy->new(
    {   in => {
            type    => 'tcp',
            host    => $conf{proxy}[0] || 'localhost',
            port    => $conf{proxy}[1],
            timeout => 1,
            hook    => sub {
                $t0 ||= Benchmark->new;
                Net::Proxy->set_callback( $_[1] );    # remove ourselves now
                }
        },
        out => {
            type => 'tcp',
            host => $conf{server}[0] || 'localhost',
            port => $conf{server}[1],
        },
    }
);
$proxy->register();

Net::Proxy->set_verbosity( $conf{verbose} || 0 );
Net::Proxy->mainloop( $conf{connections} );

# end of benchmark/profiling
my $t1 = timediff( Benchmark->new, $t0 );
print "\nforwarder.pl report: @$t1\n";

__END__

=head1 NAME

forwarder.pl - An example TCP port forwarder

=head1 SYNOPSIS

forwarder.pl [ options ]

=head1 OPTIONS

    --help                    Display this help
    --manual                  Longer manpage
    --verbose                 Increase verbosity (may be used several times)
    --proxy  [<host>:]<port>  Local port to be forwarded (default: 10000)
    --server [<host>:]<port>  Destination server         (default: 10001)
    --connections <n>         Maximum number of connection to accept
                              (0 means never stop, default is 1)

=head1 DESCRIPTION

This script is an example port forwarder written with C<Net::Proxy>.

If run for a limited number of connections, it prints a small
wallclock/CPU time report at the end.

It is used to profile C<Net::Proxy> itself, by using C<Devel::DProf>
and the B<bench.pl> script (also distributed in the F<eg/> directory
of the C<Net-Proxy> distribution.

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1

=head1 COPYRIGHT

Copyright 2008 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

