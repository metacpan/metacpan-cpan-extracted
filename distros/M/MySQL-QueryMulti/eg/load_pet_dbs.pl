#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use MySQL::QueryMulti;
use Data::Compare;

use vars qw();

#####################

my ( $sth, $cnt, $comp, $cmd, $pass, $qm, $sql );

read_conf();

$cmd = get_mysql_cmd() . " < t/sql";
system($cmd);
die if $?;

#####################

sub get_mysql_cmd {
    my $cmd = "mysql -u $ENV{DBI_USER} -h $ENV{MYSQL_HOST} ";
    $cmd .= '-p$Pass ' if defined( $ENV{MYSQL_PASS} );

    return $cmd;
}

sub read_conf {
    open( IN, 'CONF' ) or die "failed to open CONF: $!";

    while (<IN>) {
        next if /^\s*$/;
        next if !/=/;
        chomp;
        m/(.*?)\s*=\s*(.*)/;
        $ENV{$1} = $2;
    }

    close(IN);
}