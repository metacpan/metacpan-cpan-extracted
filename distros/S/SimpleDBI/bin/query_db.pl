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
    'query|e=s', 
    'file|f=s', 
    'sep|s=s', 
    'charset|c=s', 
    'write_head|H=i', 
);

my $dbi = SimpleDBI->new(%h);
$dbi->query_db($h{query}, %$dbi, result_type => 'file');
