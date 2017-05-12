# Sys::HostAddr.pm
# $Id: HostAddr.pm,v 0.993 2014/09/06 00:53:19 jkister Exp $
# Copyright (c) 2010-2014 Jeremy Kister.
# Released under Perl's Artistic License.

package Sys::HostAddr;

use strict;
use warnings;
use IO::Socket::INET;
use Sys::Hostname;

our ($VERSION) = q$Revision: 0.993 $ =~ /(\d+\.\d+)/;
my $ipv;


$ENV{PATH} = ($^O eq 'MSWin32') ?
               'C:\Windows\system32;C:\Windows;C:\strawberry\c\bin;C:\strawberry\perl\bin;' . $ENV{PATH} :
               "/usr/sbin:/sbin:/usr/etc:$ENV{PATH}"; # silly centos not having ifconfig in path of non-root

sub new {
    my $class = shift;
    my %args;
    if(@_ % 2){
        my $interface = shift;
        %args = @_;
        $args{interface} = $interface;
    }else{
        %args = @_;
    }

    my $self = bless(\%args, $class);
 
    $self->{class} = $class;   
    $self->{ipv}   = 4 unless( $self->{ipv} );

    $ipv = $self->_mkipv();

    return($self);
}

sub public {
    my $self = shift;

    unless( $self->{ipv} == 4 ){
        warn "public method not supported on IPv $self->{ipv}\n";
        return;
    }

    my $sock = IO::Socket::INET->new(Proto => 'tcp',
                                     PeerAddr => 'www.dnsbyweb.com',
                                     PeerPort => 80, 
                                     Timeout => 3);       
     
    my $platform = ucfirst($^O);
    my $public;
    eval {
        local $SIG{ALRM} = sub { die "timeout during GET\n" };
        alarm(3);
        print $sock "GET /mip.mpl HTTP/1.1\r\n",                     
                    "Host: www.dnsbyweb.com\r\n",
                    "User-Agent: Sys::HostAddr/$VERSION (compatible; ${platform}; Perl $])\r\n",  
                    "Accept: text/html; q=0.5, text/plain\r\n",
                    "Connection: close\r\n",
                    "\r\n";

        my $dh; # done header
        while(<$sock>){
            if( /^\r\n$/ ){
                $dh=1;
                next;
            }
            next unless $dh;

            if(/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/){
                $public = $1;
                last;
            }
        }
        close $sock;
        alarm(0);
    };
    alarm(0);
    warn $@ if $@;

    return( $public );
}

sub interfaces {
    my $self = shift;

    my $cfg_aref = $self->ifconfig();
    my @interfaces;
    for (@{$cfg_aref}){
        if(/^\s+Description[\s\.]+:\s+([^\r\n]+)/){
            push @interfaces, $1;
        }elsif(/^([a-z0-9]+(?::[0-9]+)?):?\s+/ && $^O ne 'MSWin32' && $^O ne 'cygwin'){
            push @interfaces, $1;
        }
    }
    return( \@interfaces );
}

sub addresses {
    my $self = shift;
    my $getint = shift || $self->{interface};

    my $cfg_aref = $self->ifconfig( $getint );
    my @addrs;
    for (@{$cfg_aref}){
        if(/^\s+${ipv}\s+(?:addr:)?(\S+)\s/){
            push @addrs, $1; # unix
        }elsif(/^\s+${ipv}[\s\.]+:\s+([a-f0-9:\.]{3,40})/){
            push @addrs, $1; # win7
        }elsif(/^\s+IP Address[\s\.]+:\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/){
            push @addrs, $1 if($self->{ipv} eq '4'); # winxp ipv4
        }elsif(/^\s+IP Address[\s\.]+:\s+([a-f0-9:\.]{3,40})/){
            push @addrs, $1 if($self->{ipv} eq '6'); # winxp ipv6
        }
    }
    return( \@addrs );
}

sub ip {
    my $self = shift;
    my $getint = shift || $self->{interface};

    my $cfg_aref = $self->ifconfig( $getint );
    my %data;
    my ($interface,$addr,$netmask);
    for my $line (@{$cfg_aref}){
        if($line =~ /^([a-z0-9]+(?::[0-9]+)?):?\s+/ && $^O ne 'MSWin32' && $^O ne 'cygwin'){
            $interface = $1;
        }elsif($line =~ /^\s+${ipv}\s+(?:addr:)?(\S+)\s/){
            my $addr = $1;
            if($line =~ /netmask\s+(?:0x)?([a-f0-9]{8})\s/){
                my $hexed = $1;
                my @hnm = $hexed =~ /^(..)(..)(..)(..)$/;
                $netmask = join('.', map { hex $_ } @hnm);
            }elsif($line =~ /netmask\s+(\S+)/){
                $netmask = $1;
            }elsif($line =~ /Mask:(\S+)/){
                $netmask = $1;
            }elsif($self->{ipv} eq '6' && $line =~ m#(/\d{1,3})$#){
                $netmask = $1;
            }else{
                die "unknown netmask for $addr on $interface\n";
            }
            push @{$data{$interface}}, { address => $addr, netmask => $netmask };
        }elsif($line =~ /^\s+Description[\s\.]+:\s([^\r\n]+)/){
            $interface = $1;
        }elsif($line =~ /^\s+${ipv}[\s\.]+:\s+([a-f0-9:\.]{3,40})/){
            $addr = $1; # win7
        }elsif($line =~ /^\s+IP Address[\s\.]+:\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/){
            $addr = $1 if($self->{ipv} eq '4'); # winXP IPv4
        }elsif($line =~ /^\s+IP Address[\s\.]+:\s+([a-f0-9:\.]{3,40})/){
            $addr = $1 if($self->{ipv} eq '6'); # winXP IPv6
        }elsif($line =~ /^\s+Subnet Mask[\s\.]+:\s+(\S+)/){
            $netmask = $1;
            #this handles multiple ip addrs on same interface (tested on XP, anyway)
            push @{$data{$interface}}, { address => $addr, netmask => $netmask };
        }
    }
    return \%data;
}

sub first_ip {
    my $self = shift;
    my $getint = shift || $self->{interface};

    my $cfg_aref = $self->ifconfig( $getint );

    for (@{$cfg_aref}){
        my $addr;
        if(/^\s+${ipv}\s+(?:addr:)?(\S+)\s/){
            $addr = $1; # unix
        }elsif(/^\s+${ipv}[\s\.]+:\s+([a-f0-9:\.]{3,40})/){
            $addr = $1; # windows 7 win32
        }elsif(/^\s+IP Address[\s\.]+:\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/){
            $addr = $1 if($self->{ipv} eq '4'); # winxp ipv4
        }elsif(/^\s+IP Address[\s\.]+:\s+([a-f0-9:\.]{3,40})/){
            $addr = $1 if($self->{ipv} eq '6'); # winxp ipv6
        }
        if($addr){
            next if($addr =~ /^(?:127\.|::1)/); # never say ln is first
            return( $addr );
        }
    }

    die "couldnt find first $ipv IP Address\n";
}

sub ifconfig {
    my $self = shift;
    my $getint = shift || $self->{interface};

    my ($cmd,$param);
    if($^O eq 'MSWin32' || $^O eq 'cygwin'){
        $cmd = 'ipconfig';
        $param = '/all';
    }else{
        $cmd = 'ifconfig';
        $param = $getint || '-a';
        $param .= ' inet6' if($self->{ipv} eq '6' && $^O eq 'solaris');
    }
    my @config = $self->_get_stdout($cmd, $param);
    
    return( \@config );
}

sub main_ip {
    my $self = shift;
    my $method = shift || 'auto';

    if( $method eq 'preferred' && ($^O ne 'MSWin32' && $^O ne 'cygwin') ){ 
        die "'preferred' method to main_ip available on MSWin32/cygwin only.\n";
    }
    unless($method =~ /^(?:dns|route|preferred|auto)$/){
        die "invalid method given to main_ip\n";
    }
 
    if($method eq 'dns' || $method eq 'auto'){  
        my $addr;
        my $hostname = hostname();
        $self->_debug( "attempting hostname lookup in main_ip: $hostname" );
        eval {
            local $SIG{ALRM} = sub { die "timeout on $hostname\n" };
            alarm(3);
            my @x = ( gethostbyname($hostname) )[4];
            alarm(0);
    
            verbose( "multiple ip addrs found for $hostname" ) if(@x > 1);
            $addr = join( '.', unpack('C4', $x[0]) );
        };
        alarm(0);
        if($@){
            $self->_warn($@);
        }    
        if( $addr ){
            return $addr unless($addr =~ /^(?:127\.|::1)/); # never say lo is main
        }
        $self->_debug( "DNS lookup did not yield an IP addr." );
    }

    if($method eq 'route' || $method eq 'auto'){
        # if dns method failed us, check for default route, find local ip
        # addr(s) in same subnet -"first" one listed will be called "main"
        
        my ($cmd,$param);
        if($^O eq 'solaris'){
            $cmd = 'route';
            $param = 'get 0.0.0.0';
        }else{
            $cmd = 'netstat'; # works with MSWin32, too
            $param = '-nr';
        }
    
        my @data = $self->_get_stdout($cmd, $param);
        for my $line (@data){
            chomp $line;
            if($line =~ /^\s+0\.0\.0\.0\s+0\.0\.0\.0\s+\S+\s+(\S+)\s+/){
                return( $1 ); # mswin32
            }elsif($line =~ /^(?:0\.0\.0\.0|default)\s.*\s(\S+)$/){
                # 0.0.0.0 = debian linux, default = freebsd
                return( $self->first_ip($1) );
            }elsif($line =~ /^\s+interface:\s+(\S+)$/){
                return( $self->first_ip($1) ); # solaris
            }
        }
    }

    if($^O eq 'MSWin32' || $^O eq 'cygwin'){
        if($method eq 'preferred' || $method eq 'auto'){
            my $cfg_aref = $self->ifconfig();
            foreach (@{$cfg_aref}){
                if(/^\s+${ipv}[\s\.]+:\s+(\S+)\(Preferred\)/){
                    return($1);
                }
            }
        }
    }
 
    die "could not determine main ip address\n"; # we dont pick one at random
}

sub _mkipv {
    my $self = shift;

    return ( ($^O eq 'MSWin32' || $^O eq 'cygwin') && $self->{ipv} eq '6' ) ? 'IPv6 Address' :
             ($^O eq 'MSWin32' || $^O eq 'cygwin')  ? 'IPv4 Address' :
             ($self->{ipv} eq '6') ? 'inet6' :
                                     'inet';
}

sub _get_stdout {
    my $self = shift;
    my $cmd = shift || die "get_stdout syntax error1\n";
    my $params = join(' ', @_);

    $self->_debug( "running cmd: [$cmd] params: [$params]" );

    open(my $fh, "$cmd $params |") || die "cannot fork $cmd: $!\n"; # -| is 5.8+
    my @data = <$fh>;
    close $fh;

    return( @data );
}

sub _warn {
    my $self = shift;
    my $msg = join('', @_);

    warn "$self->{class}: $msg\n";
}

sub _debug {
    my $self = shift;

    $self->_warn(@_) if($self->{debug});
}


1;

__END__

=pod

=head1 NAME

Sys::HostAddr - Get IP address information about this host

=head1 SYNOPSIS

use Sys::HostAddr;

my $sysaddr = Sys::HostAddr->new();

my $string = $sysaddr->public();

my $aref = $sysaddr->interfaces();

my $aref = $sysaddr->addresses();

my $href = $sysaddr->ip();

my $ip = $sysaddr->first_ip();

my $main = $sysaddr->main_ip();


=head1 DESCRIPTION

C<Sys::HostAddr> provides methods for determining IP address
information about a local host.

=head1 CONSTRUCTOR

    my $sysaddr = Sys::HostAddr->new( debug     => [0|1],
                                      ipv       => [4|6],
                                      interface => 'ethX',
                                    );

=over 4

=item debug

C<debug> will control ancillary/informational messages being printed.

=item ipv

C<ipv> will limit response data to either IPv4 or IPv6 addresses.
Default: IPv4

=item interface

C<interface> limits response data to a particular interface, where
applicable.  This value is overriden if a method is given an
interface argument directly.

=back

=head1 USAGE

=over 4

=item public()

C<public> will attempt to find the public ip address of your machine.  
usefull if you're behind some NAT.  Sends an automation request to the
www.dnsbyweb.com service.  Works on IPv4 only.


=item main_ip( [$method] )

C<main_ip> will attempt to find the "main" or "primary" IP address of
the machine.  method can be: B<auto> (I<default>), B<preferred> (MSWin32/cygwin only),
B<route>, or B<dns>.
    

=item first_ip( [$interface] )

C<first_ip> will return the first ip address on a given interface (if provided),
or the first ip address returned by ifconfig (that is not localhost).

=item ip( [$interface] )

C<ip> will return a hash reference containing ipaddress/netmask information 
keyed by interface.  if $interface is provded, will be limited to that
interface, otherwise will include all interfaces

=item addresses( [$interface] )

C<addresses> will return an array reference of all ip addresses found.  if
$interface is provided, will be limited to that interface.

=item interfaces()

C<interfaces> will return an array reference of all interfaces found.  

=back

=head1 EXAMPLES


    use Sys::HostAddr;
    
    my $sysaddr = Sys::HostAddr->new();
    
    my $int_aref = $sysaddr->interfaces();
    foreach my $interface ( @{$int_aref} ){
        print "found $interface\n";
    }
    
    my $addr_aref = $sysaddr->addresses();
    foreach my $address ( @{$addr_aref} ){
        print "found $address\n";
    }
    
    my $href = $sysaddr->ip();
    foreach my $interface ( keys %{$href} ){
        print "$interface has: ";
        foreach my $aref ( @{$href->{$interface}} ){
             print " $aref->{addr} $aref->{netmask}\n";
        }
    }
    
    my $ip = $sysaddr->first_ip();
    print "$ip found as the first ip address\n";
    
    my $main = $sysaddr->main_ip();
    print "$main appears to be the main ip address of this machine\n";

    my $pub = $sysaddr->public();
    print "public addr appears to be $pub\n";

=head1 CAVEATS

=over 4

=item Win32 lightly tested with L<Strawberry Perl|http://strawberryperl.com/> 5.10.1 on Windows7

=item Win32 lacks some options, like per interface specification

=item Win32 lacks some features, like timeouts during lookups

=item Cygwin not tested at all, should work as well as MSWin32

=item IPv6 support not well tested.

=head1 RESTRICTIONS

=over 4

=item IPv6 support not well tested.

=item Win32 support not complete.

=back

=head1 AUTHOR

L<Jeremy Kister|http://jeremy.kister.net./>

=cut

