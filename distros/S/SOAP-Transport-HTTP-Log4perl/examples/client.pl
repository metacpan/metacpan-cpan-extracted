#!/usr/bin/perl

use strict;
use warnings;

use Log::Log4perl;
use SOAP::Transport::HTTP::Log4Perl logger => 'test';
#use SOAP::Transport::HTTP::MockReplay;

use SOAP::Lite 
	uri   => 'http://www.soaplite.com/Server',
	proxy => 'http://localhost:8080/',
;

my $LOG = init_logger();

$LOG->info("Start");
my $value = SOAP::Lite->new->test(1)->result;
$LOG->info("Got $value");


sub init_logger {
	my $conf = q{
		log4perl.rootLogger = ALL, OUT

		log4perl.appender.OUT                          = Log::Log4perl::Appender::ScreenColoredLevels
		log4perl.appender.OUT.layout                   = PatternLayout
		log4perl.appender.OUT.layout.ConversionPattern = %4R %p %C %c %m%n
	};

	Log::Log4perl->init(\$conf);
	return Log::Log4perl->get_logger("Client");
}
