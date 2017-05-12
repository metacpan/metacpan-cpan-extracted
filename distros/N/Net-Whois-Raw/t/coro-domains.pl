#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;

BEGIN {
        use Socket;
        
        eval "
                use Coro;
                use Coro::AnyEvent;
                use Coro::Socket;
                use Coro::LWP;
        ";
        
        $::require_coro = $@ if $@;

    use_ok('Net::Whois::Raw',qw( whois ));

    $Net::Whois::Raw::CHECK_FAIL = 1;
    $Net::Whois::Raw::OMIT_MSG = 1;
    $Net::Whois::Raw::CHECK_EXCEED = 1;
};

my @domains = qw(
    yahoo.com
    freebsd.org
    reg.ru
    ns1.nameself.com.NS
    belizenic.bz
);

my $dns_cache = {};

SKIP: {
    print "The following tests requires internet connection. Checking...\n";
    skip "Looks like no internet connection", 5 unless get_connected();
    
    print "The following tests requires Coro. Checking...\n";
    skip "Looks like no Coro installed", 5 unless require_coro ();
    
    my @coros = ();
    
    # domains
    foreach my $domain ( @domains ) {
        push @coros, Coro->new (sub {
            my $txt = whois( $domain );
            $domain =~ s/.NS$//i;
            ok($txt && $txt =~ /$domain/i, "domain '$domain' resolved");
        });
    }
    
    $_->ready foreach @coros;
    
    $_->join foreach @coros;
    
};

sub get_connected {
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new( timeout => 10 );
    my $res = $ua->get( 'http://www.google.com' );
    
    return $res->is_success;
}

sub require_coro {
        
        no warnings 'once';
        
        *Net::Whois::Raw::whois_socket_fixup = sub {
                my $class = shift;
                my $sock  = shift;
                
                return Coro::Socket->new_from_fh ($sock, partial => 1);
        };
        
        *Net::Whois::Raw::whois_query_sockparams = sub {
                my $class  = shift;
                my $domain = shift;
                my $name   = shift;
                
                if (! $dns_cache->{$name}) {
                        my $ip = inet_ntoa (inet_aton ($name));
                        $dns_cache->{$name} = $ip;
                }
                
                return (
                        PeerAddr => $dns_cache->{$name},
                        PeerPort => 43,
                        # LocalHost => ,
                        # LocalPort => 
                );
        };
        
        return ! $::require_coro; 
}
