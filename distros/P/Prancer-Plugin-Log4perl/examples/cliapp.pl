#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use File::Basename ();
use Log::Log4perl;

use Prancer::Core qw(config);
use Prancer::Plugin::Log4perl qw(logger);

sub main {
    # figure out where exist to make finding config files possible
    my (undef, $root, undef) = File::Basename::fileparse($0);

    # this just returns a prancer object so we can get access to configuration
    # options and other awesome things like plugins.
    my $app = Prancer::Core->new("${root}/foobar.yml");

    # in here we get to initialize things!
    Prancer::Plugin::Log4perl->load();

    # custom log4perl config but there is a default one
    Log::Log4perl->init(\qq|
        log4perl.rootLogger = TRACE, stdout
        log4perl.appender.stdout = Log::Dispatch::Screen
        log4perl.appender.stdout.stderr = 0
        log4perl.appender.stdout.layout = Log::Log4perl::Layout::PatternLayout
        log4perl.appender.stdout.layout.ConversionPattern = %d{yyyy-MM-dd HH:mm:ss,SSS} %5p [%c{1}:%M:%L] - %m%n
    |);

    logger->trace("this is a trace message");
    logger->info("information");

    return;
}

main(@ARGV) unless caller;

1;
