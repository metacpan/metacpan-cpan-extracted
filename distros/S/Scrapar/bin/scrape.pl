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
use Scrapar::Logger;
use Date::Format;
require UNIVERSAL::require;

my %opts;
my $pid_file;

sub write_pid {
    my $backend = shift;
    mkdir "$FindBin::Bin/../run";
    $pid_file = "$FindBin::Bin/../run/$backend.pid";
    
    open my $fh, '>', $pid_file or die $!;
    print { $fh } $$, $/;
    close $fh;
}

sub init_logger {
    my $backend = shift;
    my $logger = $ENV{SCRAPER_LOGGER} = Scrapar::Logger->new();
    $logger->backend($backend);

    mkdir "$FindBin::Bin/../log";
    $logger->add(file => {
	filename => "$FindBin::Bin/../log/scrape-"
			  . (time2str("%Y-%m-%d", int(time / 86400) * 86400 + 86400)) . ".log",
	maxlevel => "debug",
	minlevel => "warning",
	mode => 'append',
	newline => 1,
    });
    $logger->info("Scrapar started");
}

$SIG{QUIT} = $SIG{INT} = sub {
    $ENV{SCRAPER_LOGGER}->info("Scrapar interrupted");

    exit(-1);
};

END {
    $ENV{SCRAPER_LOGGER}->info("Scrapar stopped");

    $ENV{SCRAPER_REQUESTS} ||= 1;
    $ENV{SCRAPER_CACHE_HITS} ||= 0;
    $ENV{SCRAPER_LOGGER}->info("Cache hit rate: " 
			       . ($ENV{SCRAPER_CACHE_HITS} / $ENV{SCRAPER_REQUESTS}));

    unlink $pid_file if $pid_file && -e $pid_file;
}

sub list_backends {
    my @candidate_inc;
    my @inc = map { $_ if $_ . '/Scrapar/Backend' } @INC;

    my %h;
    my @files = (sort
		 grep { !$h{$_}++ }
		 map { s[/][::]g; $_ }
		 map { s[.+/Scrapar/Backend/(.+)\.pm][]; $1 }
		 grep { !$h{$_}++ && m[/Scrapar/Backend/] && !m[/_.+.pm] }
		 File::Find::Rule->file()
		 ->name('*.pm')->in(grep { !m[^/] } @INC));

    print "\nAvailable backends:\n\n", map { "  $_\n" } @files;
    print "\n";
}

sub main {
    getopts('Chlb:d:D:u:p:ciL:T:g:P:', \%opts);

    if ($opts{C}) {
	$ENV{SCRAPER_CACHE} = 1;
    }

    # data handler must be processed by $opts{b}
    # because running backend is dependent on default data handler
    if ($opts{d}) {
	if ($opts{d} =~ m[^D::.+]) {
	    $ENV{DEFAULT_DATAHANDLER} = $opts{d};
	}
	else {
	    die "Please specify a valid data handler";
	}
    }

    # DSN
    if ($opts{D}) {
	$ENV{SCRAPER_DBH} = DBI->connect($opts{D}, $opts{u}, $opts{p});
    }

    # commit to database if specified
    if ($opts{c}) {
	die "Please connect to a connection to database first" if !$ENV{SCRAPER_DBH};
	$ENV{SCRAPER_COMMIT} = 1;
    }

    if ($opts{i}) {
	$ENV{SCRAPER_TIME_INTERVAL} = $opts{i};
    }

    if ($opts{L}) {
	$opts{L} =~ m[(\d+)];
	$ENV{SCRAPER_MAX_LINKS} = $1 || 0;
    }

    if ($opts{T}) {
	$opts{T} =~ m[(\d+)];
	$ENV{SCRAPER_MAX_TIME} = $1 || 0;
    }

    if ($opts{P}) {
	$ENV{SCRRAPER_PROXY} = $opts{P};
    }

    if ($opts{l}) {
	list_backends();
    }
    elsif ($opts{b}) {
	my $run_backend = sub {
	    my $backend_module = 'Scrapar::Backend::' . $opts{b};
	    $ENV{SCRAPER_BACKEND} = $opts{b};
	    $backend_module->require or die $@;
	    
	    init_logger($opts{b});
	    write_pid($opts{b});
	    my $backend = $backend_module->new({
		cache_expires_in => $opts{e},
	    });
	    $backend->run();
	};

	$run_backend->();
    }
    else {
	exec('perldoc', '-t', $0);
    }
}

main;

__END__

=pod

=head1 NAME

  scrape.pl - Command-line data scraper

=head1 USAGE

    -l                 # list all available backends

    -b Backend engine  # scrape with a backend engine

    -d data handler    # specify the default data handler

    -D DSN             # the data source name, 
                       # e.g. 'DBI:mysql:database=db;host=localhost;port=3306'

    -u user name       # the user name to database

    -p password        # the password to database

    -c                 # commit to database? (-D must be specified)

    -C                 # cache fetched web pages

    -i                 # use random time intervals between any two web requests

    -L                 # max number of links to be fetched in one run

    -T                 # max time for one run

    -P                 # proxy server

    -e                 # cache validation period

    -h                 # show help message

=head1 COPYRIGHT

Copyright 2009-2010 by Yung-chung Lin

All right reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
