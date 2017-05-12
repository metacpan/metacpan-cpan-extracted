#!/usr/bin/perl -w
#
# Command line interface to RRD::Editor module
#
# Compatible with RRDTOOL, with the following exceptions:
# - currently restore and xport are not implemented
# - currently times must be specified as unix timestamps (i.e. -1d, -1w etc don't work, and there is no @ option in rrdupdate)
# Added features
# - extra editing options available to "rrdtool tune" (add-DS, del-DS, add-RRA, del-RRA).
# - "rrdtool convert" to change between file formats (native-double, portable-double, portable-single)
# - "rrdtool resize SIZE" option added (just supply the size wanted, no need to GROW, SHRINK relative to current size)
#
# (c) D.J.Leith 2011
#
####################################################

use strict;
use Getopt::Long qw(GetOptions);
use Carp qw(croak carp cluck);
use RRD::Editor;

if (@ARGV<1) {die("Need to supply at least one argument\n");}
my $cmd=shift @ARGV;
my $file=shift @ARGV;

my $rrd = RRD::Editor->new();
if ($cmd eq "create") {
    $rrd->create(join(" ",@ARGV));
    $rrd->save($file);
    
} elsif ($cmd eq "convert") {
    # new option - convert file between native and portable formats  
    my $encoding;
    GetOptions("format|f=s"  => \$encoding);
    if ($encoding !~ m/(native-double|portable-double|portable-single)/) {croak("unknown file format ".$encoding."\n");} 
    $rrd->open($file);
    $rrd->save($file,$encoding);
        
} elsif ($cmd eq "dump") {
    $rrd->open($file);
    print $rrd->dump(join(" ",@ARGV));
    
} elsif ($cmd eq "fetch") {
    $rrd->open($file);
    print $rrd->fetch(join(" ",@ARGV));
    
} elsif ($cmd eq "first") {
    $rrd->open($file);
    my $i=0;
    if (defined($ARGV[1])) {$i=$ARGV[1];}
    print $rrd->last()-$rrd->RRA_numrows($i)*$rrd->RRA_step($i),"\n";
    
} elsif ($cmd eq "info") {
    $rrd->open($file);
    print $rrd->info(join(" ",@ARGV));
    
} elsif ($cmd eq "last") {
    $rrd->open($file);
    print $rrd->last(),"\n";
    
} elsif ($cmd eq "lastupdate") {
    $rrd->open($file);
    my @names=$rrd->DS_names();
    printf "%12s"," ";
    for (my $i=0; $i<@names; $i++) {printf "%-17s",$names[$i];}
    printf "\n%10u: ",$rrd->last();
    my @vals=$rrd->lastupdate();
    for (my $i=0; $i<@vals; $i++) {printf "%-16.10e ",$vals[$i];}
    print "\n";
    
} elsif ($cmd eq "resize") {
    $rrd->open($file);
    my $size=$rrd->RRA_numrows($ARGV[0]);
    if ($ARGV[1] eq "GROW") {
        $size += $ARGV[2];
    } elsif ($ARGV[1] eq "SHRINK") {
        $size -= $ARGV[2];
    } elsif ($ARGV[1] eq "SIZE") { # new option, just directly state the desired number of rows in the RRA
        $size = $ARGV[2];
    } else {
        die("Unknown option ".$ARGV[1],"\n");
    }
    $rrd->resize_RRA($ARGV[0],$size);
    $rrd->save("resize.rrd");
    
} elsif ($cmd eq "restore") {
    print STDERR "Not implemented.\n";
    
} elsif ($cmd eq "tune") {
    # New options: add_DS, del_DS, add_RRA, del_RRA
    my @heartbeat; my @min; my @max; my @rename; my @type;
    my @add_DS; my @del_DS; my @add_RRA; my @del_RRA; my @xff;
    GetOptions(
    "heartbeat|h:s" => \@heartbeat,
    "minimum|i:s" => \@min,
    "maximum|a:s" => \@max,
    "type|d:s" => \@type,
    "data-source-rename|r:s" => \@rename,
    "add-DS:s" => \@add_DS,
    "del-DS:s" => \@del_DS,
    "add-RRA:s" => \@add_RRA,
    "del-RRA:s" => \@del_RRA
    );
    $rrd->open($file);
    my $i;
    for ($i=0; $i<@heartbeat; $i++) {
        my @bits=split(":",$heartbeat[$i]);
        $rrd->set_DS_heartbeat($bits[0],$bits[1]);
    };
    for ($i=0; $i<@min; $i++) {
        my @bits=split(":",$min[$i]);
        $rrd->set_DS_min($bits[0],$bits[1]);
    };
    for ($i=0; $i<@max; $i++) {
        my @bits=split(":",$max[$i]);
        $rrd->set_DS_max($bits[0],$bits[1]);
    };
    for ($i=0; $i<@type; $i++) {
        my @bits=split(":",$type[$i]);
        $rrd->set_DS_type($bits[0],$bits[1]);
    };
    for ($i=0; $i<@rename; $i++) {
        my @bits=split(":",$rename[$i]);
        $rrd->rename_DS($bits[0],$bits[1]);
    };
    for ($i=0; $i<@add_DS; $i++) {
        $rrd->add_DS($add_DS[$i]);
    };    
    for ($i=0; $i<@del_DS; $i++) {
        $rrd->delete_DS($del_DS[$i]);
    };    
    for ($i=0; $i<@del_RRA; $i++) {
        $rrd->delete_RRA($del_RRA[$i]);
    };    
    for ($i=0; $i<@add_RRA; $i++) {
        $rrd->add_RRA($add_RRA[$i]);
    };    
    $rrd->save();
    
} elsif ($cmd eq "update") {
    $rrd->open($file);
    $rrd->update(join(" ",@ARGV));
    
} elsif ($cmd eq "xport") {
    print STDERR "Not implemented.\n";
    
} else {
   print STDERR "Unknown command $cmd\n";
}
