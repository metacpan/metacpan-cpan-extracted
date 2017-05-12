#!/usr/bin/perl

use lib 'lib';

=head1	NAME

 Version: 	$Id: bannerscan.pl,v 1.5 2004/08/31 13:42:55 mmanno Exp $
 Date:		1.2004
 Author:	mm

 v0.2   getopt added
 v0.1	base, copied from Nmap::Scanner example/event_scan.pl

=head1 SYNOPSIS

    parse live nmap output and do probes

    BUGS: need to handle multiple addresses per host?

=head1 REQUIREMENTS

  XML::Simple
  threads
  Nmap::Scanner of course

  The following directories need to exist:
  out/          probe output goes here
  probes/       probe scripts here
  results/      nmaps xml logs will be saved here

=cut

use vars qw($opt_h $opt_v $opt_c $opt_r $opt_l $opt_R $opt_f $opt_o $opt_O);
use File::Basename;
use Getopt::Std;
use Nmap::Scanner;
use XML::Simple;
use threads;
use strict;

use Data::Dumper;
#$|=0;

# config
my $portrange="21,22,23,25,53,80,110,119,143,161,389,443,3128,3306,8080";

# command line options
getopts('hvGc:r:R:l:f:o:O:');
usage() if $opt_h;
my $probeoutdir = $opt_O ? $opt_O : "out";
my $resultdir = $opt_o ? $opt_o : "results";
my $configfile = $opt_c ? $opt_c : "probes.xml";
my $file = basename $opt_f if $opt_f;
die "$!: $configfile" unless (-e $configfile);
die "$!: $probeoutdir" unless (-d $probeoutdir);
die "$!: $resultdir" unless (-d $resultdir);

# load probe config
my $conf = XMLin("$configfile", keeproot => 0,suppressempty =>0,noattr => 1) or die "cannot load config: $!";

# global hash for thread data
my $spool;

# setup scanner callback
my $scanner = new Nmap::Scanner;
#FIXME# $scanner->register_scan_started_event(\&scan_started);
$scanner->register_port_found_event(\&port_found);
$scanner->register_no_ports_open_event(\&no_ports);
$scanner->register_scan_complete_event(\&scan_complete);

print "..::Start::..\n";
my $results;
# run nmap or load
if ($opt_r) {
        $file = mk_filename() unless $opt_f;
        #$results = $scanner->scan(" -p 1,21 $opt_r");
        $results = $scanner->scan("-T Aggressive -sS -sV -O --randomize_hosts -p $portrange $opt_r");
} elsif ($opt_R) {
        $file = mk_filename() unless $opt_f;
        $results = $scanner->scan("-T Aggressive -sS -sV -O -p $portrange -iR $opt_R");
} elsif ($opt_l) {
        $file = basename $opt_l unless $opt_f;
        $results = $scanner->scan_from_file("$opt_l");
} else {
        usage();
}

# dump results to xml file
print "..::Save::..\n" if ($opt_r or $opt_R);
save_scan($file,$results) if ($opt_r or $opt_R);

# collect threads
print "..::finishing::..\n";
foreach my $thr (threads->list) {
# Don't join the main thread or ourselves
        if ($thr->tid && !threads::equal($thr, threads->self)) {
                $thr->join;
        }
}

=head1 Subs

=head2 usage

=cut
sub usage {
	print "usage: ". basename($0) ." [-v] [-h] [-f file] [-c file] [-o dir] [-O dir] (-r opt|-R n|-l file)\n";
    print "    -r nmapopt   : run nmap\n";
    print "    -R number    : run nmap random scan number times\n";
    print "    -l file.xml  : load nmap xml\n\n";
    print "    -G           : don\'t start global probe\n"
    print "    -f file.xml  : output filename  (timestamp.xml)\n";
    print "    -c config.xml: config file      (config.xml)\n";
    print "    -o dir       : xml output dir   (results)\n";
    print "    -O dir       : probe output dir (out)\n";
	print "    -v           : verbose\n";
	print "    -h           : help\n";
	print "    i.e.         :  ".basename($0)." -r 10.0.0.0/24\n";
	print "    i.e.         :  ".basename($0)." -R 2342\n";
	print "    i.e.         :  ".basename($0)." -l scan.xml\n";
	exit 1;
}

=head2 mk_filename
        
        generate a timestamp for filenames
=cut
sub mk_filename {
        my ($sec,$min,$h,$mday,$mon,$y,$wday,$yday,$isdst)=localtime;
        $mon++;$y+=1900; my $i = 1;
        while (-e  "$resultdir/".sprintf("%04d%02d%02d-nmap-%02d.xml",$y,$mon,$mday,$i) ) {
                $i++;
        }
        my $file = sprintf("%04d%02d%02d-nmap-%02d.xml",$y,$mon,$mday,$i);
        return $file;
}

=head2 save scan

        save scan xml to file
        save_scan ( Nmap::Result );

=cut
sub  save_scan {
        my $file = shift;
        my $results = shift;
        # dump results to xml file
        open (F,">$resultdir/$file") or die "$!: $resultdir/$file\n\n".$results->as_xml();
        print F $results->as_xml();
        close (F);
        return $file;
}

=head2 do_node

    Probe deployer 
    for every entry in config do argl


    decide if i am to call function on array of hashes
    or on a single hash 
    (cause xml::simple output differs if only one node is found)

=cut
sub do_node {
    my $func = shift; #function to call
    my $data = shift; #on every node in this struct
    my $opt = shift;  #optional arg to func
     
    my @node;
    if ( ref ($data) eq 'ARRAY' ) { 
        @node = @$data;
    } else { push @node,$data }

    foreach my $n ( @node ) {
        &$func ($n,$opt);
    }
}

=head2 log_run

dump probe output to file: ip.probetyp.lst

=cut
sub log_run {
    my $cmd=shift;
    my $spool=shift;
    my $out=`$cmd 2>&1`;
    my $name=lc($spool->{addr}.".".$spool->portid().".".$spool->{probetyp});
    open (F,">$probeoutdir/$name.lst") or warn "..::file ERROR::.. $probeoutdir/$name.lst writeable? ";
    print F $out;
    close F;
}

=head2 check_port

        run a probe if trigger matches

=cut
sub check_port {
    my $target = shift;
    # exec the command for this trigger
    my $test = $spool->service()->name()." ".
               $spool->service()->product()." ".
               $spool->service()->version()." ".
               $spool->service()->extrainfo();
    if ($test=~ /$target->{trigger}/i) {
        my $cmd = $target->{cmd};
        $cmd =~ s/\$IP/$spool->{addr}/g;
        $cmd =~ s/\$PORT/$spool->portid()/eg;
        print "..::HIT::.. $spool->{addr}:".$spool->portid()." --- $cmd\n" if $opt_v;

        $spool->{probetyp}=$target->{typ};
        threads->new(\&log_run,$cmd,$spool);
        #nonthread#log_run($cmd,$spool);
        
    } else {
        print "..::Unknown::.. $spool->{addr}:".$spool->portid()." \n" if $opt_v;
    }

}

=head2 scan_complete

        Call the banner scanner

=head3 HOST Struct (complete)

    {
        'PORTS' => { tcp' => {
                                '25' => bless( {
                                                'STATE' => 'open',
                                                'SERVICE' => bless( {
                                                                'PRODUCT' => 'OpenSSH',
                                                                'SERVICE' => undef,
                                                                'EXTRAINFO' => 'protocol 2.0',
                                                                'HIGHVER' => undef,
                                                                'NAME' => 'smtp',
                                                                'RPCNUM' => undef,
                                                                'CONF' => '10',
                                                                'METHOD' => 'probed',
                                                                'LOWVER' => undef,
                                                                'PROTO' => undef
                                                                }, 'Nmap::Scanner::Service' ),
                                                'NUMBER' => '25',
                                                'PROTO' => 'tcp'
                                        }, 'Nmap::Scanner::Port' ),
                              },
                   }
        'NAME' => ',ford.rainbow',
        'OS'   => bless {}, 'Nmap::Scanner::OS'
        'STATUS' => 'up',
        'ADDRESSES' => [
                        bless( {
                                'TYPE' => 'ipv4',
                                'ADDRESS' => '10.1.1.5'
                                }, 'Nmap::Scanner::Address' )
                       ],
        EXTRA_PORTS => bless( {
                                           'STATE' => 'unknown',
                                           'COUNT' => '0'
                              }, 'Nmap::Scanner::ExtraPorts' ),
    }, 'Nmap::Scanner::Host' 

=cut
sub scan_complete {
    my $self      = shift;
    my $host      = shift;

    return if ( lc($host->status()) ne 'up' );
    my $addresses = join(',', map {$_->addr()} $host->addresses());
    
    if ( $host->hostname() ) {
        print "..::Finished scanning::.. ", $host->hostname(),"\n" if $opt_v;
    } else {
        print "..::Finished scanning::.. ", $addresses,"\n" if $opt_v;
    }

    # foreach port
    my $ports = $host->get_port_list();
    while (my $port = $ports->get_next()) {
            next unless lc($port->state()) eq 'open';
            next unless ($port->service());
            #print Dumper $port;
            $spool=$port; # remember me!!!
            map {
                    $spool->{addr}=$_->addr; # remember me!!!
                    &do_node(\&check_port,$conf->{probe});# FIXME not needed?# if $port->state() eq "open";
            } $host->addresses();
    }

    # Launch global probe
    #`probes/all.sh $addresses` unless $opt_G;

    
}

=head2 scan_started

        Scan started Callback
        unused

=cut
sub scan_started {
    my $self     = shift;
    my $host     = shift;

    my $hostname = $host->hostname();
    my $addresses = join(',', map {$_->addr()} $host->addresses());
    my $status = $host->status();

    print "$hostname ($addresses) is $status\n" if $opt_v;
    #print Dumper $host if $opt_v;
}

=head2 no_ports

        No Ports Callback
        unused

=cut
sub no_ports {
    my $self       = shift;
    my $host       = shift;
    my $extraports = shift;

    my $name = $host->hostname();
    my $addresses = join(',', map {$_->addr()} $host->addresses());
    my $state = $extraports->state();

    print "All ports on host $name ($addresses) are in state $state\n" if $opt_v;
    #print Dumper $host,$extraports if $opt_v;
}

=head2 port_found

        Port Found Callback
        unused

=head3 HOST Struct    

=head3 PORT Struct

    {
        'STATE' => 'open',
        'SERVICE' => undef,
        'NUMBER' => '21',
        'OWNER' => '',
        'PROTO' => 'tcp'
    }, 'Nmap::Scanner::Port'

=cut 
sub port_found {
    my $self     = shift;
    my $host     = shift;
    my $port     = shift;

    my $name = $host->hostname();
    my $addresses = join(',', map {$_->addr()} $host->addresses());

    print "..::FOUND::.. on host $name ($addresses), ",
          $port->state()," port ",
          join('/',$port->protocol(),$port->portid()),"\n" if $opt_v;

}
