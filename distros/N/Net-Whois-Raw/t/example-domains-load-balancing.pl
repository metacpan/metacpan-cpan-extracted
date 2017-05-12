#!/usr/bin/perl -w

use strict;

use Test::More (tests => 6, skip_all => 'tmp');

exit;

sub ip_to_dword {
        my $ip = shift; # assume ipv4
        return unpack('B32', pack('C4C4C4C4', split(/\./, $ip)));
}

sub dword_to_ip {
        my $dword = shift;
        return join '.', unpack('C4C4C4C4', pack('B32', $dword));
}

BEGIN {
        use Socket;
        
        eval "
                use Coro;
                use Coro::AnyEvent;
                use Coro::Socket;
                use Coro::LWP;
                use Coro::Timer;
                use DBI:SQLite;
        ";
        
        $::require_coro = $@ if $@;
        
        unlink "db.sqlite";
        
        $ENV{DBI_DSN}  ||= 'DBI:SQLite:dbname=db.sqlite';
        $ENV{DBI_USER} ||= '';
        $ENV{DBI_PASS} ||= '';
        
        use DBI;
        
        $::dbh = DBI->connect;
        $::dbh->do ('create table whois_quota (
                name varchar(200), 
                ip varchar(15),
                ip_expire integer,
                quota integer
        );');

        $::dbh->do ('create table whois_connection (
                local_ip integer,
                remote_ip integer,
                created integer,
                domain varchar(300)
        );');

        $::dbh->do ('create table whois_ip (
                local_ip varchar(15)
        );');

        # TODO: FILL IP LIST into whois_ip
        $::dbh->do ('insert into whois_ip values (?);', {}, ip_to_dword ('192.168.2.2'));
        $::dbh->do ('insert into whois_ip values (?);', {}, ip_to_dword ('10.0.2.6'));
        
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
            $::dbh->do ('delete from whois_connection where domain = ?', {}, $domain);
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
                
                # TODO: YOU MUST PLACE QUOTA CHECK HERE
                # my $sth = $::dbh->prepare ('select * from ');
                
                my $ip;
                
                if (! $dns_cache->{$name}) {
                        $ip = inet_ntoa (inet_aton ($name)); # TODO: use coro::util for resolve
                        $dns_cache->{$name} = $ip;
                } else {
                        $ip = $dns_cache->{$name};
                }
                
                my $ip_num = ip_to_dword ($ip);
                
                my $sth = $::dbh->prepare (
                        'select local_ip from whois_ip where local_ip not in (select local_ip from whois_connection where remote_ip = ? group by local_ip) limit 1;'
                );
                my $rows_affected = $sth->execute ($ip_num);
                my $result = $sth->fetchall_arrayref ({});
                
                $sth->finish;
                
                if (@$result == 0) {
                        # no free ips, try to use minimally loaded
                        $sth = $::dbh->prepare ('select local_ip, count(local_ip) as local_ip_c from whois_connection where remote_ip = ? and created > ? group by local_ip order by count(local_ip) asc limit 1;');
                        
                        $rows_affected = $sth->execute ($ip_num);
                        $result = $sth->fetchall_arrayref ({});
                        
                }
                
                $::dbh->do (
                        'insert into whois_connection values (?, ?, ?, ?);',
                        {},
                        $result->[0]->{local_ip}, $ip_num, time, $domain
                );
                
                return (
                        PeerAddr => $dns_cache->{$name},
                        PeerPort => 43,
                        LocalHost => dword_to_ip ($result->[0]->{local_ip}),
                        # LocalPort => 
                );
        };
        
        return ! $::require_coro; 
}
