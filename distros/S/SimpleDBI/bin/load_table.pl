#!/usr/bin/perl
use Getopt::Long qw(:config no_ignore_case);
use SimpleDBI;
GetOptions (\%h, 
    'type|t=s', 
    'host|h=s', 
    'usr|u=s', 
    'passwd|p=s', 
    'port|P=s', 
    'db|d=s', 

    'table|T=s', 
    'file|f=s', 
    'field|F=s', 
    'replace|R=i', 
    'skip_head|H=i', 

    'sep|s=s', 
    'charset|c=s', 
);

$h{field} = [ split ',', $h{field} ] if($h{field});
my $dbi = SimpleDBI->new(%h);
$dbi->load_table($h{file}, %$dbi);
