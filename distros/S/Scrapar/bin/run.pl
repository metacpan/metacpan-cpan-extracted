#!/usr/bin/perl

use lib qw(lib), glob('customer/*/lib');
use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use File::Find::Rule;
use List::Util;
use Scrapar::Var;
use DBI;
use YAML;
use FindBin;
use List::Util qw(shuffle);
use Scrapar::Util;
require UNIVERSAL::require;

my %opts;

sub get_backends {
    my @candidate_inc;
    my @inc = map { $_ if $_ . '/Scrapar/Backend' } @INC;

    my %h;
    return (sort
	    grep { !$h{$_}++ }
	    map { s[/][::]g; $_ }
	    map { s[.+/Scrapar/Backend/(.+)\.pm][]; $1 }
	    grep { !$h{$_}++ && m[/Scrapar/Backend/] && !m[/_.+.pm] } 
	    File::Find::Rule->file()->name('*.pm')->in(grep { !m[^/] } @INC));
}

sub list_backends {
    print "\nAvailable backends:\n\n", map { "  $_\n" } get_backends;
    print "\n";
}

sub write_pid {
    my $pid_file = "$FindBin::Bin/../run/run.pid";
    mkdir "$FindBin::Bin/../run";
    
    die "run.pl is already running. Exiting...\n" if -e $pid_file;
    open my $fh, '>', $pid_file or die $!;
    print { $fh } $$, $/;
    close $fh;

    END {
	unlink "$FindBin::Bin/../run/run.pid"
    }
}

sub load_config {
    my $config_file = shift;
    return YAML::LoadFile($config_file);
}

my %backend_cache_hit_rate;
sub sort_backends {
    my @backends = @_;

    my $grep_result = `grep 'Cache hit rate' log/*.log`;
    for my $line (split /\n/, $grep_result) {
	$line =~ m/.+\[(.+)] Cache hit rate: (.+)/;
	$backend_cache_hit_rate{$1} = [ 1, 0, 0 ];
	$backend_cache_hit_rate{$1}->[0]++;
	$backend_cache_hit_rate{$1}->[1] += $2;
    }
    for my $key (keys %backend_cache_hit_rate) {
	$backend_cache_hit_rate{$key}->[2] = $backend_cache_hit_rate{$key}->[1] 
	    / $backend_cache_hit_rate{$key}->[0];
    }	   

    $backend_cache_hit_rate{$_} ||= [ 1, 0, 0 ] for @backends;
    
#    use Data::Dumper;
#    print Dumper \%backend_cache_hit_rate;
    return(sort { $backend_cache_hit_rate{$a}->[2]
		      <=> $backend_cache_hit_rate{$b}->[2] }
	   @backends);
}

sub main {
    getopts('c:lhk', \%opts);

    if ($opts{h}) {
	exec('perldoc', '-t', $0);
	exit;
    }

    if ($opts{l}) {
	list_backends();
	exit;
    }

    if ($opts{k}) {
	`cat $FindBin::Bin/../run/* | xargs kill`;
	unlink glob("$FindBin::Bin/../run/*");
	exit(0);
    }

    die "Please specify a config file" unless $opts{c};
    my $config = load_config($opts{c});

    write_pid;
    while (1) {
	Scrapar::Util::recycle_log_files("$FindBin::Bin/../log");

	for my $backend (sort_backends get_backends) {
	    print "Running backend $backend ...\n\n";
	    system(join q/ /, 
		   "perl $FindBin::Bin/scrape.pl -C -b $backend",
		   ($config->{max_links}{$backend} ?
		     "-L $config->{max_links}{$backend}" : ""),
		   ($config->{cache_expires_in} ? "-e $config->{cache_expires_in}" : ""),
		   ($config->{dsn} ? "-c -D $config->{dsn}" : ""),
		   ($config->{username} ? "-u $config->{username}" : ""),
		   ($config->{password} ? "-p $config->{password}" : ""),
		   ($config->{proxy} ? "-P $config->{proxy}" : ""));
	    my $sleep_sec = 5;
	    print "Stopping backend " . $backend
		. " and sleep for $sleep_sec seconds \n\n";
	    sleep $sleep_sec;
	}
    }
}

main;

__END__

=pod

=head1 NAME

  run.pl - An all-in-one scraper command

=head1 USAGE

    -c config file     # load config file

    -l                 # list all available backends

    -h                 # show help message

=head1 COPYRIGHT

Copyright 2009-2010 by Yung-chung Lin

All right reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
