#!/usr/bin/perl

=head1 NAME

snmp_effective_example.pl

=cut

sub say { print @_, "\n" } # use feature qw/say/;
BEGIN { $ENV{'SNMP_EFFECTIVE_DEBUG'} = 1 } # for debugging

use warnings;
use strict;
use lib qw(lib ../lib);
use SNMP::Effective;

say 'Setting up SNMP::Effective...';
my $effective = SNMP::Effective->new(
                    master_timeout => 5,
                    dest_host      => "127.0.0.1",
                    get            => "1.3.6.1.2.1.1.1.0", # sysDescr.0
                    getnext        => "sysName",
                    walk           => "sysUpTime",
                    callback       => \&my_callback,
                    arg            => {
                        Version   => "2c",
                        Community => "public",
                    },
                );

say 'SNMP::Effective->execute...';
$effective->execute;

sub my_callback {
    my $host = shift;
    my $error = shift;
    my $heap = $host->heap;
    my $data;

    if($error) {
        say "Error: Could not get data from $host: $error";
        return;
    }

    $data = $host->data;

    for my $oid (keys %$data) {
        say "-" x 78;
        say "$host returned oid($oid) with data:";
        say join "\n", map { "\t$_ => $data->{$oid}{$_}" } keys %{ $data->{$oid} };
        say "";
    } 

    return; # snmp-effective doesn't care about the return value
}
