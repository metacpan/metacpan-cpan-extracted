package Sys::Simple::CPU::Linux;

use strict;
use warnings;

use IO::Handle;
use Time::HiRes qw/usleep/;


# cpu usage: Get cpu usage on perl, 
# based on this post on stackoverflow
#
# Sleep to give the /proc time to update 
#
# https://stackoverflow.com/questions/23367857/accurate-calculation-of-cpu-usage-given-in-percentage-in-linux/23376195#23376195
#

my @fields = qw/tag user nice system idle iowait irq softirq steal guest guest_nice/;

sub cpu_usage {
    my $factor = $_[0] || 1;
    my $wait = 10_000 * $factor;

    my %previous;
    my %actual;

    # I like to ident after the open when doing "block" operation
    # over the contents of a file handle

    open my $fh, "<", "/proc/stat";
        $fh->autoflush( 1 );
        @previous{ @fields } = split ( /\s+/, <$fh> );

        usleep $wait;
        seek $fh, 0, 0;

        $fh->autoflush( 1 );
        @actual{ @fields } = split ( /\s+/, <$fh> );
    close $fh;
    
    my $previdle = $previous{ idle } + $previous{ iowait };
    my $idle = $actual{ idle } + $actual{ iowait };
    
    my $prevnonidle =   $previous{ user } + $previous{ nice } 
                      + $previous{ system } + $previous{ irq } 
                      + $previous{ softirq } + $previous{ steal };
    
    my $nonidle =   $actual{ user } + $actual{ nice } 
                  + $actual{ system } + $actual{ irq }
                  + $actual{ softirq } + $actual{ steal };
    
    my $prevtotal = $previdle + $prevnonidle;
    my $total = $idle + $nonidle;
    
    my $totald = $total - $prevtotal;
    my $idled = $idle - $previdle;
    
    my $cpu_percentage = ( $totald - $idled ) / ( $totald || 1 );
    
    return $cpu_percentage;
    
}

1;
