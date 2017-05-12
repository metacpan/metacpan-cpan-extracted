use strict;
use Test::More;
use Net::DNS;
use NetworkInfo::Discovery::Rendezvous;

my $obj = undef;
my $domain = 'zeroconf.org';
my $domain_addr = '';
my @hosts = ();

# First, try to check whether we are connected to the Internet.
eval q{
    my $resolver = Net::DNS::Resolver->new;
    my $query = $resolver->search($domain);

    if ($query) {
        for my $rr ($query->answer) {
            next unless $rr->type eq 'A';
            $domain_addr = $rr->address and last;
        }
    } else {
        plan skip_all => "Can't resolve '$domain'. Can't execute the tests.";
    }
};
plan 'no_plan';

# zeroconf.org provides dummy DNS-SD records for testing purposes. 
# Currently, 7 services are listed via services enumeration, but 
# only 4 have instances. 
# 
# The defined services are: 
#  - afpovertcp/tcp (AFP over TCP, Apple Filing Protocol)
#  - ftp/tcp (FTP)
#  - http/tcp (HTTP)
#  - ipp/tcp (IPP, Internet Printing Protocol, used by CUPS)
#  - pdl-datastream/tcp (alias for IPP)
#  - printer/tcp (generic name for IPP)
#  - ssh/tcp (SSH)
# 
# The defined instances are: 
#  - Sales, Marketing and Engineering, which are 3 virtual hosts 
#    on the same network printer
#  - Rose, which is the SSH access of the printer server

# checking by making request on zeroconf.org
$obj = new NetworkInfo::Discovery::Rendezvous domain => $domain;
ok( defined $obj                                        );  #01
eval { $obj->do_it };
is( $@, ''                                              );  #02
eval { @hosts = $obj->get_interfaces };
is( $@, ''                                              );  #03
ok( scalar @hosts                                       );  #04

for my $host (@hosts) {
    next unless $host->{ip};
    
    if($host->{nodename} eq 'Sales') {
        is( $host->{ip}, $domain_addr );
        
        if($host->{services}[0]{name} eq 'ipp') {
            is( $host->{services}[0]{port}, '49152' );
            is( $host->{services}[0]{protocol}, 'tcp' );
            is( $host->{services}[0]{fqdn}, 'Sales._ipp._tcp.zeroconf.org' );
        
        } elsif($host->{services}[0]{name} eq 'pdl-datastream') {
            is( $host->{services}[0]{port}, '49152' );
            is( $host->{services}[0]{protocol}, 'tcp' );
            is( $host->{services}[0]{fqdn}, 'Sales._pdl-datastream._tcp.zeroconf.org' );
        
        } elsif($host->{services}[0]{name} eq 'printer') {
            is( $host->{services}[0]{port}, '49152' );
            is( $host->{services}[0]{protocol}, 'tcp' );
            is( $host->{services}[0]{fqdn}, 'Sales._printer._tcp.zeroconf.org' );
        }
    }
    if($host->{nodename} eq 'Marketing') {
        is( $host->{ip}, $domain_addr );
        
        if($host->{services}[0]{name} eq 'ipp') {
            is( $host->{services}[0]{port}, '49153' );
            is( $host->{services}[0]{protocol}, 'tcp' );
            is( $host->{services}[0]{fqdn}, 'Marketing._ipp._tcp.zeroconf.org' );
        
        } elsif($host->{services}[0]{name} eq 'pdl-datastream') {
            is( $host->{services}[0]{port}, '49153' );
            is( $host->{services}[0]{protocol}, 'tcp' );
            is( $host->{services}[0]{fqdn}, 'Marketing._pdl-datastream._tcp.zeroconf.org' );
        
        } elsif($host->{services}[0]{name} eq 'printer') {
            is( $host->{services}[0]{port}, '49153' );
            is( $host->{services}[0]{protocol}, 'tcp' );
            is( $host->{services}[0]{fqdn}, 'Marketing._printer._tcp.zeroconf.org' );
        }
    }
    if($host->{nodename} eq 'Engineering') {
        is( $host->{ip}, $domain_addr );
        
        if($host->{services}[0]{name} eq 'ipp') {
            is( $host->{services}[0]{port}, '49156' );
            is( $host->{services}[0]{protocol}, 'tcp' );
            is( $host->{services}[0]{fqdn}, 'Engineering._ipp._tcp.zeroconf.org' );
        
        } elsif($host->{services}[0]{name} eq 'pdl-datastream') {
            is( $host->{services}[0]{port}, '49156' );
            is( $host->{services}[0]{protocol}, 'tcp' );
            is( $host->{services}[0]{fqdn}, 'Engineering._pdl-datastream._tcp.zeroconf.org' );
        
        } elsif($host->{services}[0]{name} eq 'printer') {
            is( $host->{services}[0]{port}, '49156' );
            is( $host->{services}[0]{protocol}, 'tcp' );
            is( $host->{services}[0]{fqdn}, 'Engineering._printer._tcp.zeroconf.org' );
        }
    }
    if($host->{nodename} eq 'Rose') {
        is( $host->{ip}, $domain_addr );
        
        if($host->{services}[0]{name} eq 'ssh') {
            is( $host->{services}[0]{port}, '22' );
            is( $host->{services}[0]{protocol}, 'tcp' );
            is( $host->{services}[0]{fqdn}, 'Engineering._ssh._tcp.zeroconf.org' );
        }
    }
}
