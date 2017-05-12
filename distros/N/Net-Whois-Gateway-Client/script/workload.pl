#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  workload.pl
#
#        USAGE:  ./workload.pl 
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  05.05.2009 16:54:44 MSD
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;


use Net::Whois::Gateway::Client;
use Data::Dumper;

use Getopt::Long;

my @domains;

my $host = 'localhost';
my $mean_queue_size = 20;
my $total_request   = 10000;

my $requests_made = 0;

my $test_directi_frac = 0.5;
my $test_rusu_frac    = 0.5;
my $test_gtld_frac    = 0.5;

my $sum = 0;
$sum  +=  $_   foreach ($test_directi_frac, $test_rusu_frac, $test_gtld_frac);
$_    /=  $sum foreach ($test_directi_frac, $test_rusu_frac, $test_gtld_frac);


@domains = <>;
chomp( @domains );

my %domains_by_class;

if ( @domains < $mean_queue_size ) {
    die "Too less domains\n";
}

foreach my $domain ( @domains ) {
    my $class = $domain =~ m{\.(?:ru|su)$} ? 'rusu' : 'gtld';
    #warn $class;
    push @{ $domains_by_class{ $class } }, $domain;
    if ( $class eq 'gtld' && $domain !~ m/.me$/ ) {
	push @{ $domains_by_class{ directi } }, $domain;
    }
}

while ( $requests_made < $total_request ) {
    my $requests_size = norm_rand(
	$mean_queue_size, int sqrt( $mean_queue_size )
    );

    my @queue;
    my %param_gw;

#    $requests_made += $requests_size;

    foreach (1..$requests_size*$test_rusu_frac) {
	push @queue, get_random_element( $domains_by_class{ rusu } );
    }

    foreach (1..$requests_size*$test_gtld_frac) {
	push @queue, get_random_element( $domains_by_class{ gtld } );
    }

    foreach (1..$requests_size*$test_directi_frac) {
	push @queue,
		    'directi:'.get_random_element( $domains_by_class{ directi } );
    }

    $requests_made += scalar @queue;
    
    if ( grep { /^directi:/ } @queue ) {
	$param_gw{directi_params} = {
	    service_username => 'boldin.pavel@gmail.com',
	    service_password => 'dazachem',
	    service_langpref => 'en',
	    service_role     => 'reseller',
	    service_parentid => '999999998',
	    url              => 'http://api.onlyfordemo.net/anacreon/servlet/APIv3',
	};
    }

    fisher_yates_shuffle( \@queue );

    $param_gw{referral} = int rand(3);

    my @answer = Net::Whois::Gateway::Client::whois(
	query => \@queue,
	%param_gw,
    );
}

sub get_random_element {
    my $array = shift;

    return $array->[ int rand( @$array ) ];
}

sub norm_rand {
    return shift() + shift()*gaussian_rand();
}

sub gaussian_rand {
    my ($u1, $u2);  # uniformly distributed random numbers
    my $w;          # variance, then a weight
    my ($g1, $g2);  # gaussian-distributed numbers

    do {
	$u1 = 2 * rand() - 1;
	$u2 = 2 * rand() - 1;
	$w = $u1*$u1 + $u2*$u2;
    } while ( $w >= 1 );

    $w = sqrt( (-2 * log($w))  / $w );
    $g2 = $u1 * $w;
    $g1 = $u2 * $w;
    # return both if wanted, else just one
    return wantarray ? ($g1, $g2) : $g1;
}

sub fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
	my $j = int rand ($i+1);
	next if $i == $j;
	@$array[$i,$j] = @$array[$j,$i];
    }
}

