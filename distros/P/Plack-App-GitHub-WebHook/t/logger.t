use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use HTTP::Message::PSGI;
use Plack::App::GitHub::WebHook;

my %options = (
    access => 'all',
    hook   => sub {
        my ($payload, $event, $delivery, $logger) = @_;
        foreach my $level (qw(debug info warn error fatal)) {
            $logger->{$level}->($delivery);
            $logger->log( $level, "$delivery\n" );
        }
        $logger->fatal($payload->{answer});
    });

my $app = Plack::App::GitHub::WebHook->new(%options)->to_app;
my $logfile = [];
my $expect = [
    debug => '12345',
    debug => '12345',
    info  => '12345',
    info  => '12345',
    warn  => '12345',
    warn  => '12345',
    error => '12345',
    error => '12345',
    fatal => '12345',
    fatal => '12345',
    fatal => '42',
];


my $env = req_to_psgi( POST '/', Content => '{"answer":42}', 
    'X-GitHub-Event' => 'ping', 
    'X-Github-Delivery' => '12345'
);
my $res = $app->($env); 
is_deeply $logfile, [], "don't die without logger";


$logfile = [];
$env->{'psgix.logger'} = sub {
	push @$logfile, $_[0]->{level}, $_[0]->{message};
};

$res = $app->($env); 
is_deeply $logfile, $expect, 'log to psgix.logger';


if (eval { require File::Temp; require Log::Dispatch::Code; 1 } ) {
	$logfile = [];
    my $callback = sub {
		my %args = @_;
		push @$logfile, $args{level}, $args{message};
	}; 
	my $logger = Log::Dispatch->new(
    	outputs => [ [ 'Code', code => $callback, min_level => 'debug' ] ]
	);

	Plack::App::GitHub::WebHook->new( logger => $logger, %options )->to_app->($env);

	pop @$expect for 1..6; # fatal level not supported by Log::Dispatch
	is_deeply $logfile, $expect, 'log to psgix.logger';
} else {
    note "Log::Dispatch::File required to test its use";
}

done_testing;
