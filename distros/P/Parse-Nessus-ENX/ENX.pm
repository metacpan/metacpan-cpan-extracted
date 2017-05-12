
package Parse::Nessus::ENX;

use strict;
use vars qw/ $VERSION @ISA @EXPORT_OK %EXPORT_TAGS /;

require Exporter;

@ISA       = qw/ Exporter /;
@EXPORT_OK =
  qw/ ebanners eports eplugin ewebdirs enfs eos esnmp estatos estatservices estatvulns /;
%EXPORT_TAGS = (all => [qw/ ebanners eports eplugin ewebdirs enfs eos esnmp estatos estatservices estatvulns /] );
$VERSION = '1.1';

use constant WEBDIR => 11032;  # nessus plugin id for web directories discovered
use constant NFS    => 10437;  # nessus plugin id for nfs shares discovered
use constant NMAP1  => 10336;  # nessus plugin id for Nmap OS guess
use constant NMAP2  => 11268;  # nessus plugin id for Nmap OS guess
use constant QUESO  => 10337;  # nessus plugin id for QueSO OS guess

sub ebanners {
    my (@ndata) = @_;
    my (@banners);
    foreach my $nbanner (@ndata) {
        if ( $nbanner =~ /emote(.*)server (banner|type)/ ) {
            my @result = split ( /\|/, $nbanner );
            $result[4] =~ s/^(.*?) \:\;|Solution (.*)$|r\;|\;|This is(.*)$//g;
            push @banners, join "|", $result[0], $result[4];
        }
    }
    return @banners;
}

sub eports {
    my (@ndata) = @_;
    my (@ports);
    my $nport = pop (@ndata);
    foreach my $ndata (@ndata) {
        my @result = split ( /\|/, $ndata );
        if ( $result[3] || $ndata =~ /\[NessusWX|\$DATA/ ) {
            next;
        }
        elsif ( $result[1] =~ /\($nport\// ) {
            push @ports, join "|", $result[0], $result[1];
        }
    }
    return @ports;
}

sub eplugin {
    my (@ndata) = @_;
    my (@plugins);
    my $eplugin = pop (@ndata);
    foreach my $ndata (@ndata) {
        my @result = split ( /\|/, $ndata );
        if ( !$result[4] ) {
            next;
        }
        elsif ( $result[2] =~ /$eplugin/ ) {
            push @plugins, join "|", $result[0], $result[1], $result[4];
        }
    }
    return @plugins;
}

sub ewebdirs {
    my (@ndata) = @_;
    my (@webdirs);
    my $webdirplugin = WEBDIR;
    foreach my $ndata (@ndata) {
        my @result = split ( /\|/, $ndata );
        if ( !$result[4] ) {
            next;
        }
        elsif ( $result[2] =~ /$webdirplugin/ ) {
            $result[4] =~ s/(^(.*)discovered\:\;|\;|\,)//g;
            $result[4] =~ s/The following(.*)authentication:/\|/;
            push @webdirs, join "|", $result[0], $result[1], $result[4];
        }
    }
    return @webdirs;
}

sub enfs {
    my (@ndata) = @_;
    my (@nfs);
    my $nfsplugin = NFS;
    foreach my $ndata (@ndata) {
        my @result = split ( /\|/, $ndata );
        if ( !$result[4] ) {
            next;
        }
        elsif ( $result[2] =~ /$nfsplugin/ ) {
            $result[4] =~ s/(^(.*?) \: \;|\;\;CVE(.*)$)//g;
            $result[4] =~ s/\;/,/g;
            push @nfs, join "|", $result[0], $result[1], $result[4];
        }
    }
    return @nfs;
}

sub eos {
    my (@ndata) = @_;
    my (@os);
    foreach my $ndata (@ndata) {
        if ( $ndata =~
            m/10336\|(INFO|NOTE)|11268\|(INFO|NOTE)|10337\|(INFO|NOTE)/ )
        {
            my @result = split ( /\|/, $ndata );
            if ( $result[2] eq NMAP1 ) {
                $result[4] =~ s/(Nmap(.*)running |\;)//g;
                push @os, join "|", $result[0], $result[4];
            }
            elsif ( $result[2] eq NMAP2 ) {
                $result[4] =~ s/(Remote OS guess : |\;\;(.*)$)//g;
                push @os, join "|", $result[0], $result[4];
            }
            elsif ( $result[2] eq QUESO ) {
                $result[4] =~
                  s/(QueSO has(.*) \;\* |\;\;\;CVE (.*)$| \(by (.*)$)//g;
                push @os, join "|", $result[0], $result[4];
            }
        }
    }
    return @os;
}

sub esnmp {
    my (@ndata) = @_;
    my (@snmp);
    foreach my $ndata (@ndata) {
        if ( $ndata =~ m/10264\|REPORT\|/ ) {
            my @result = split ( /\|/, $ndata );
            $result[4] =~ s/\;SNMP Agent(.*?)community name: //;
            $result[4] =~ s/(\;SNMP Agent (.*?)community name: |\;CVE(.*)$)/ /g;
            push @snmp, join "|", $result[0], $result[4];
        }
    }
    return @snmp;
}

sub estatos {
    my (@ndata) = @_;
    my (@allos);
    foreach my $ndata (@ndata) {
        if ( $ndata =~
            m/10336\|(INFO|NOTE)|11268\|(INFO|NOTE)|10337\|(INFO|NOTE)/ )
        {
            my @result = split ( /\|/, $ndata );
            chomp $result[4];
            if ( $result[2] eq NMAP1 ) {
                $result[4] =~ s/(Nmap(.*)running |\;)//g;
                push @allos, $result[4];
            }
            elsif ( $result[2] eq NMAP2 ) {
                $result[4] =~ s/(Remote OS guess : |\;\;(.*)$)//g;
                push @allos, $result[4];
            }
            elsif ( $result[2] eq QUESO ) {
                $result[4] =~
                  s/(QueSO has(.*) \;\* |\;\;\;CVE (.*)$| \(by (.*)$)//g;
                push @allos, $result[4];
            }
        }
    }
    my %count;
    map { $count{$_}++ } @allos;
    my @rearranged = sort { $count{$b} <=> $count{$a} } keys %count;
    my @graphos;
    foreach (@rearranged) {
        push @graphos, join "|", $_, "$count{$_}\n";
    }
    return @graphos;
}

sub estatservices {
    my (@ndata) = @_;
    my (@allports);
    foreach my $ndata (@ndata) {
        my @result = split ( /\|/, $ndata );
        if ( $result[3] || $ndata =~ /\[NessusWX|\$DATA/ ) {
            next;
        }
        else {
            chomp $result[1];
            push @allports, $result[1];
        }
    }
    my %count;
    map { $count{$_}++ } @allports;
    my @rearranged = sort { $count{$b} <=> $count{$a} } keys %count;
    my @graphservices;
    foreach (@rearranged) {
        push @graphservices, join "|", $_, "$count{$_}\n";
    }
    return @graphservices;
}

sub estatvulns {
    my (@edata) = @_;
    my (@allvuln);
    my $esevval = pop (@edata);
    my $eseverity;
    if ($esevval == 1) {
	    $eseverity = "REPORT";
    }
    elsif ($esevval == 2) {
	    $eseverity = "INFO";
    }
    elsif ($esevval == 3) {
	    $eseverity = "NOTE";
    }
    foreach my $edata (@edata) {
            my @result = split ( /\|/, $edata );
	    if (! $result[3]) {
		    next;
	    }
            elsif ( $result[3] =~ /$eseverity/ ) {
                push @allvuln, $result[2];
            }
    }
    my %count;
    map { $count{$_}++ } @allvuln;
    my @rearranged = sort { $count{$b} <=> $count{$a} } keys %count;
    my @graphvuln;
    foreach (@rearranged) {
        push @graphvuln, join "|", $_, "$count{$_}\n";
    }
    return @graphvuln;
}

1;

__END__

=pod

=head1 NAME

Parse::Nessus::ENX - extract specific data from Extended NSR (ENX) files

=head1 SYNOPSIS

	use Parse::Nessus::ENX;

	function(@nessusdata);
	
	function(@nessusdata,$query);	

=head1 DESCRIPTION

This module is designed to extract information from Extended NSR (ENX) 
files. Functions have been designed to return certain sets of data, 
such as service banners and OS versions. Other functions have been 
provided that will return more specific information, such as all IPs 
listening on a given port or all IPs associated with a specified plugin id.

=head1 EXAMPLES

To obtain a list of banners

	my @banners =  ebanners(@nessusdata);
	print @banners;
	
	# returns
	IP|service banner

	# example
	192.168.0.5|CompaqHTTPServer/2.1
	192.168.0.11|Apache/1.3.26 (Unix) mod_perl/1.24
	192.168.0.30|Microsoft-IIS/5.0
	192.168.0.31|220 cpan01 FTP server (SunOS 5.8) ready.
	192.168.0.51|NetWare HTTP Stack
	192.168.0.99|220 Service ready for new user.
	...

To query by port

	my $port = 22;
	my @ports = eports(@nessusdata,$port);		
	print @ports;
	
	# returns
	IP|specified port
	
	# example
	192.168.0.5|ssh (22/tcp)
	192.168.0.6|ssh (22/tcp)
	192.168.0.8|ssh (22/tcp)
	192.168.0.23|ssh (22/tcp)
	192.168.0.89|ssh (22/tcp)
	...

To obtain a list of web directories

	my @webdirs = ewebdirs(@nessusdata);		
	print @webdirs;
	
	# returns 
	IP|web port|web dir(s)|web dir(s) requiring authentication

	# example
	192.168.0.21|http (80/tcp)|/css /design /downloads /images /js
	192.168.0.43|http (80/tcp)|/images /public|/console
	192.168.0.47|https (443/tcp)|/files /html /images /js /jsp
	192.168.0.101|https (443/tcp)|/application /common /images /report|/printers
	192.168.0.110|http (80/tcp)|/admin
	...

To obtain a list of nfs shares

	my @nfs = enfs(@nessusdata);				
	print @nfs;
	
	# returns 
	IP|nfs port|nfs share(s)
	
	# example
	192.168.0.11|nfs (2049/tcp)|/apps (mountable by everyone)
	192.168.0.31|nfs (2049/tcp)|/cdrom (mountable by everyone)
	192.168.0.28|nfs (2049/tcp)|/data (mountable by everyone)
	192.168.0.45|nfs (2049/tcp)|You are running a superfluous NFS daemon...
	192.168.0.108|nfs (2049/tcp)|You are running a superfluous NFS daemon...
	...

To obtain a OS listing

	my @os = eos(@nessusdata);				
	print @os;
	
	# returns 
	IP|OS version

	# example
	192.168.0.1|IOS 12.1.5-12.2(6a), Cisco IOS 12.1(5)-12.2(7a)
	192.168.0.154|Linux 2.1.19 - 2.2.20
	192.168.0.111|HP Advancestack Etherswitch 224T or 210
	192.168.0.92|AIX 4.2-4.3.3
	192.168.0.10|NT Server 4.0 SP4-SP5 running Checkpoint Firewall-1
	...

To obtain a listing of SNMP community strings

	my @snmp = esnmp(@nessusdata);				
	print @snmp;

	# returns 
	IP|SNMP community string(s)

	# example
	192.168.0.1|private public
	192.168.0.111|public
	192.168.0.121|private public
	192.168.0.128|private public
	192.168.0.145|public
	...

To query by plugin id

	my $plugin = 10667;
	my @plugin = eplugin(@nessusdata,$plugin); 	
	print @plugin;

	# returns
	IP|port|plugin data

	# example
	192.168.0.202|https (443/tcp)|...OpenSSL which is;older than 0.9.6e...
	192.168.0.222|https (443/tcp)|...OpenSSL which is;older than 0.9.6e...
	192.168.0.235|https (443/tcp)|...OpenSSL which is;older than 0.9.6e...
	192.168.0.236|https (443/tcp)|...OpenSSL which is;older than 0.9.6e...
	192.168.0.237|https (443/tcp)|...OpenSSL which is;older than 0.9.6e...
	...

To obtain a OS count, useful for graphing

	my @countos = estatos(@nessusdata);
	print @countos;

	# returns
	OS version|count

	# example
	Windows NT4 or 95/98/98SE|17
	Windows 2000 Advanced Server SP3|14
	TOPS-20 Monitor 7(21733),KL-10 (DEC 2065)|11
	Cisco router running IOS 12.1.5-12.2.13a|11
	PS2 Linux 1.0|9
	Linux 2.4.17 on HP 9000 s700|7
	Cisco 2620 running IOS 12.1(6)|6
	Windows 2000 Server SP3|5
	Windows NT4 Workstation SP6a|4
	Nortel/Alteon ACE Director 3 Version 6.0.42-B|4

To obtain a service count, useful for graphing

	my @countservices = estatservices(@nessusdata);
	print @countservices;

	# returns
	service port|count

	#example
	http (80/tcp)|69
	telnet (23/tcp)|48
	netbios-ssn (139/tcp)|48
	https (443/tcp)|46
	loc-srv (135/tcp)|42
	ftp (21/tcp)|39
	smtp (25/tcp)|34
	pcanywheredata (5631/tcp)|30
	ssh (22/tcp)|25
	sun-answerbook (8888/tcp)|22

To obtain a vulnerability count, useful for graphing

	# note: options are as follows:
	# 1 returns high severity vulnerabilties
	# 2 returns medium severity vulnerabilities
	# 3 returns low level security notes
	
	my @countvulns = estatvulns(@nessusdata,1);
	print @countvulns;

	#returns
	plugin id|count

	#example
	11875|40
	11412|17
	10116|12
	11856|11	
	10932|10
	10937|7
	11793|6
	
=head1 AUTHOR

David J Kyger <dave@norootsquash.net>

=head1 Thanks

Gwendolynn ferch Elydyr <gwen@reptiles.org>

=head1 COPYRIGHT

Copyright 2003 David J Kyger. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

