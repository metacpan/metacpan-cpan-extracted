#!/usr/bin/perl

use lib 'lib';

=head1	NAME

 Version: 	$Id: graphscan.pl,v 1.5 2004/08/31 13:42:55 mmanno Exp $
 Date:		1.2004
 Author:	mm

 v0.1	base, copied from Nmap::Scanner example/event_scan.pl

=head1 SYNOPSIS

    use GD to draw png charts from nmap xml 
    Currently draws:
            Port State
            Port Numbers
            OS Names
            Port Service Type
            Port Service Product Name

=head1 REQUIREMENTS

    Modules:
    
    GD::Graph must be installed
    Nmap::Scanner of course
    
    The following directories need to exist:
    html/       images and html output will be saved here
    results/    nmaps xml logs will be saved here
    xml/        some stylesheets this script needs

    

=cut

use File::Basename;
use GD::Graph;
use GD::Graph::pie;
use GD::Graph::bars;
use GD::Graph::hbars;
use vars qw($opt_h $opt_v $opt_u $opt_p $opt_r $opt_R $opt_l $opt_H $opt_x $opt_y $opt_o $opt_i $opt_f $opt_c);
use Getopt::Std;
use Nmap::Scanner;

use Data::Dumper;
use strict;

# config
my $portrange="21,22,23,25,53,80,110,119,143,161,389,443,3128,3306,8080"; # to scan
my $refresh=7; # of html page with -c
my $xmldir="xml"; # of xsl stylesheets for -H

# command line options
getopts('hvupCHf:o:i:x:y:r:R:l:');
usage() if $opt_h;
# FIXME both 'html' ??
my $imagedir  = $opt_i ? $opt_i : 'html';
my $resultdir = $opt_o ? $opt_o : 'results';
my $bxs = $opt_x ? $opt_x : 640; # base size x
my $bys = $opt_y ? $opt_y : 480; # base size y
my $file = basename $opt_f if $opt_f;
die "$!: $imagedir" unless (-d $imagedir);
die "$!: $resultdir" unless (-d $resultdir);
unless ($opt_H) {
        unless ( -e "$xmldir/bannerscan.xsl" and -e "$xmldir/empty.xsl" and -e "$xmldir/identity.xsl" ) {
                print "WARN: xsl stylesheets missing in $xmldir\n";
                print "WARN: no html results page will be build\n";
                print "WARN: down hosts will not be excluded\n";
        }
}


# global hashes for statistic data
my (%stat_hosts, %stat_ports, %stat_port_states, %stat_os_match, 
        %stat_os_class, %stat_services, %stat_products);


# setup scanner callback
my $scanner = new Nmap::Scanner;
#FIXME# $scanner->register_scan_started_event(\&scan_started);
#$scanner->register_port_found_event(\&port_found);
$scanner->register_scan_complete_event(\&scan_complete);

print "..::Start::..\n";
my $results;
# run nmap or load
if ($opt_r) {
        $file = mk_filename() unless $opt_f;
        save_html($refresh) unless ($opt_H and $opt_C);
        #$results = $scanner->scan(" -p 1,21 $opt_r");
        $results = $scanner->scan("-T Aggressive -sS -sV -O --randomize_hosts -p $portrange $opt_r");
} elsif ($opt_R) {
        $file = mk_filename() unless $opt_f;
        save_html($refresh) unless ($opt_H and $opt_C);
        $results = $scanner->scan("-T Aggressive -sS -sV -O -p $portrange -iR $opt_R");
} elsif ($opt_l) {
        $file = basename $opt_l unless $opt_f;
        save_html($refresh) unless ($opt_H and $opt_C);
        $results = $scanner->scan_from_file("$opt_l");
} else {
        usage();
}

save_scan($file,$results) if ($opt_r or $opt_R);

print "..::Images::..\n";
save_graph ( "Hosts", $file, 'pie', \%stat_hosts ) if %stat_hosts;
save_graph ( "Ports", $file, 'pie', \%stat_ports ) if %stat_ports;
save_graph ( "States", $file, 'bars', \%stat_port_states ) if %stat_port_states;
save_graph ( "Services", $file, 'pie', \%stat_services ) if %stat_services;
save_graph ( "OSMatch", $file, 'hbars', \%stat_os_match ) if %stat_os_match;
save_graph ( "OSClass", $file, 'hbars', \%stat_os_class ) if %stat_os_class;
save_graph ( "Products", $file, 'hbars', \%stat_products ) if %stat_products;
print "\n";
print "..::HTML::..\n" unless $opt_H;
save_html() unless $opt_H;

=head1 Subs

=head2 usage

    graphscan.pl [-v] [-u] [-p] [-c] [-H] [-x x] [-y y] [-f file] [-o dir] [-i dir] (-r opt|-R n|-l file)

    i.e.: graphscan.pl -v -c -H -i /home/your/public_html -R 1001

=cut
sub usage {
	print "usage: ". basename($0) ." [-v] [-u] [-p] [-c] [-H] [-x x] [-y y] [-f file] [-o dir] [-i dir] (-r opt|-R n|-l file)\n";
    print "    -r nmapopt   : run nmap\n";
    print "    -R number    : run nmap random ip scan on n ips\n";
    print "    -l file.xml  : load nmap xml\n\n";
    print "    -v           : verbose\n";
    print "    -u           : use unknown (product/os), default: drop it\n";
    print "    -p           : add version to product names\n";
    print "    -C           : don\'t continously generate images (ports/states) during scan\n";
    print "    -H           : don\'t generate HTML page in image dir\n";
    print "    -x y         : base width       (640)\n";
    print "    -y x         : base height      (480)\n";
    print "    -f file.xml  : base filename    (timestamp)\n";
    print "    -o dir       : xml output dir   (results)\n";
    print "    -i dir       : image output dir (html)\n";
	print "    -h           : help\n";
	print "    i.e.         :  ".basename($0)." -r 10.0.0.0/24\n";
	print "    i.e.         :  ".basename($0)." -v -c -H -i /home/your/public_html -R 1001\n";
	print "    i.e.         :  ".basename($0)." -H -l scan.xml\n";
	exit 1;
}

=head2 save graph png

        save_graph (Title, Savefile, ChartType, Data);

=cut
sub save_graph {
        my $title = shift;
        my $file = shift;
        my $type = shift;
        my $dat = shift;
        $file =~ s/\.xml//;
        
        # resize if element number is high
        my $xs=$bxs;
        my $ys=$bys;
        my @t=keys %$dat;
        my $size = $#t+1;
        if ($size < 28) { $xs/=2; $ys/=2; }
        elsif ($size > 200) {$xs*=3.5; $ys*=3.0; }
        elsif ($size > 150) {$xs*=3.0; $ys*=2.5; }
        elsif ($size > 100) {$xs*=2.5; $ys*=2.0; }
        elsif ($size > 60) { $xs*=2; $ys*=2; }
        if ($type eq 'pie' and $size>13 and $size<30) { $xs=$bxs/1.5; $ys=$bys/1.5; }
        $xs = int($xs);
        $ys = int($ys);

        my $graph;
        if ($type eq 'pie') {
                $graph = GD::Graph::pie->new($xs, $ys);
        } elsif ($type eq 'hbars') {
                $graph = GD::Graph::hbars->new($xs, $ys);
        } elsif ($type eq 'bars') {
                $graph = GD::Graph::bars->new($xs, $ys);
        } else {
                $graph = GD::Graph::bars->new($xs, $ys);
        }

        # sort data
        #my @data = ([keys %$dat], [values %$dat]);
        my @keys = sort (keys %$dat);
        my (@k,@v);
        my $n=0;
        foreach my $key (@keys) {
                my $value = $dat->{$key};
                push @k, $key;
                push @v, $value;
                $n+=$value;
        }
        my @data = ([@k],[@v]);

        #print "$title: k=$size, n=$n ;" if $opt_v;
        $graph->set ( title => $title." (n=".$n.")" );

        # generate image
        my $img = $graph->plot( \@data );
        my $png_data = $img->png;

        # write to file
        open (F, ">$imagedir/$file-$title.png") or die "$!: $imagedir/$file-$title.png";
        print F $png_data;
        close (F);
        #open (DISPLAY,"| display -") || die; binmode DISPLAY; print DISPLAY $png_data; close DISPLAY;
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

=head2 save_html

        generate html index page in imagedir

=cut
sub save_html {
        my $refresh = shift;
        my $name = $file;
        $name =~ s/\.xml//;
        print "Saving html to $name.html\n" if $opt_v;
        open F,">$imagedir/$name.html" or return;
        print F <<EOF;
<html>        
<head>
        <link rel="stylesheet" type="text/css" media="all" href="bannerscan.css" />
EOF
        if ($refresh) {
                print F "<title>graphscan running - $file</title>\n";
                print F '<meta http-equiv="refresh" content="'.$refresh.'; URL='.$name.'.html">'."\n";
        } else {
                # build finish page
                print F "<title>graphscan finish - $file</title>\n";
                # FIXME 
                # backup
                if ($opt_l) {
                        `cp $file $imagedir/$file.old`;
                } else {
                        `cp $resultdir/$file $imagedir/$file.old`;
                }
                
                # apply ident transform to clean imagedir/file from down hosts
                my $cmd = 'perl -ne \'print unless /^(\w*)$/\'';
                `xalan -XSL $xmldir/empty.xsl -IN $imagedir/$file.old | $cmd > $imagedir/$file`;
                `rm $imagedir/$file.old` unless ($imagedir eq $resultdir); # don't delete if no backup

                # add xsl stylesheet to result.xml file
                $cmd = 'perl -pi -e \'s!\?>!\?>\n<\?xml-stylesheet type="text/xsl" href="bannerscan.xsl" \?>!\'';
                `$cmd $imagedir/$file`;

                # generate result.html for opera users..
                `xalan -XSL $xmldir/bannerscan.xsl -IN $imagedir/$file > $imagedir/$name.results.html`;
                
                # imagedir needs bannerscan.css bannerscan.xsl (fix names to be more generic)
                print "WARN: no bannerscan.css stylesheet in $imagedir\n" unless (-e "$imagedir/bannerscan.css");
                print "WARN: no bannerscan.xsl stylesheet in $imagedir (only important for $name.xml)\n" unless (-e "$imagedir/bannerscan.xsl");
                
                # add thumbnail and link to .xml/.html files to index.html?
        }
        print F <<EOF;
</head>
<body>
EOF
        print F '<img src="'.$name.'-Hosts.png" border="0">'."\n" if (%stat_hosts or $refresh);
        print F '<img src="'.$name.'-States.png" border="0">'."\n" if (%stat_port_states or $refresh);
        print F '<img src="'.$name.'-Ports.png" border="0">'."\n" if (%stat_ports or $refresh);
        print F '<img src="'.$name.'-Services.png" border="0">'."\n" if (%stat_services or $refresh);
        print F '<img src="'.$name.'-Products.png" border="0">'."\n" if (%stat_products or $refresh);
        print F '<img src="'.$name.'-OSMatch.png" border="0"><br>'."\n" if (%stat_os_match or $refresh);
        print F '<img src="'.$name.'-OSClass.png" border="0"><br>'."\n" if (%stat_os_class or $refresh);
        print F '<a href="javascript:back()">back</a>&nbsp;';
        print F '<a href="'.$name.'.results.html">html results</a>&nbsp;' unless $refresh;
        print F '<a href="'.$file.'">xml results</a><br>' unless $refresh;
        print F <<EOF;
</body>
</html>        
EOF
close (F);
}

=head2 scan_complete

        Store values
        Generate images, if -c

=cut
sub scan_complete {
    my $self      = shift;
    my $host      = shift;

    # verbose
    my $addresses = join(',', map {$_->addr()} $host->addresses());

    $stat_hosts{$host->status()}+=1;

    if ( lc($host->status()) eq 'up' ) {
        if ( $host->hostname() ) {
            print "Finished scanning ", $host->hostname(),"\n" if $opt_v;
        } else {
            print "Finished scanning ", $addresses,"\n" if $opt_v;
        }
        
        # OS Detect
        my $last=0;
        if ($host->os()) {
                # match
                my $name;
                my @oss = $host->os()->osmatches();
                foreach my $os (@oss) {
                        if ( $last<$os->accuracy() ) {
                                $name = $os->name();
                                $last=$os->accuracy();
                        } 
                }
                if ($opt_u) { $name = 'unknown' unless $name; }
                $name = substr($name,0,50);
                $stat_os_match{$name}+=1 if $name;

                # class
                $last=0;
                $name=undef;
                @oss = $host->os()->osclasses();
                foreach my $os (@oss) {
                        if ( $last<$os->accuracy() ) {
                                $name = $os->osfamily();
                                #+osgen?
                                #osfamily/vendor
                                $last=$os->accuracy();
                        } 
                }
                if ($opt_u) { $name = 'unknown' unless $name; }
                $name = substr($name,0,50);
                $stat_os_class{$name}+=1 if $name;
        }
        
        # Foreach Port
        my $ports = $host->get_port_list();
        while (my $port = $ports->get_next()) {
                
                # Port States
                $stat_port_states{$port->state()}+=1;

                # Only Open Port Now
                next unless lc($port->state()) eq 'open';

                print "Port found: ".$port->portid()."/".$port->protocol()." = ".
                    $port->state()."\n" if $opt_v;


                if ($port->service()) {
                    # Port Product Name
                    if ($port->service()->product()) {
                            my $prod = $port->service()->product();
                            $prod .= " ".$port->service()->version() if ($port->service()->version()                                                                                 and $opt_p);
                            $prod = substr($prod,0,50);
                            $stat_products{$prod}+=1;
                    } else {
                            $stat_products{'unknown'}+=1 if $opt_u;
                    }
                
                    # Port Service
                    $stat_services{$port->service()->name()}+=1;
                }

                # Port Numbers
                $stat_ports{$port->portid()."/".$port->protocol()}+=1;
                
        } 
        
        if (not $opt_C) {
                print "=== Image Update $addresses ===\n" if $opt_v;
                save_graph ( "Hosts", $file, 'pie', \%stat_hosts ) if %stat_hosts;
                save_graph ( "Ports", $file, 'pie', \%stat_ports ) if %stat_ports;
                save_graph ( "States", $file, 'bars', \%stat_port_states ) if %stat_port_states;
                save_graph ( "Services", $file, 'pie', \%stat_services ) if %stat_services;
                save_graph ( "OSMatch", $file, 'hbars', \%stat_os_match ) if %stat_os_match;
                save_graph ( "OSClass", $file, 'hbars', \%stat_os_class ) if %stat_os_class;
                save_graph ( "Products", $file, 'hbars', \%stat_products ) if %stat_products;
                #print "\n";
        }

        #print "ip:ports:os\n"
        
    } #endif host up


}
=head2 port_found

        Port Found Callback
        unused

=cut 
sub port_found {
    my $self     = shift;
    my $host     = shift;
    my $port     = shift;
    # FIXME: are ports detected in hordes? then better move this to scan_complete
    # function only called if $opt_r.. if addport missing in xml
    return unless lc($port->state()) eq 'open';
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

    print "$hostname ($addresses) is $status\n";
    print Dumper $host;
}

