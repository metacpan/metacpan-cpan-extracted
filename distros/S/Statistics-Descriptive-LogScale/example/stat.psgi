#!/usr/bin/perl -w

use strict;
use AnyEvent;
use Time::HiRes qw(time);
use URI::Escape qw(uri_unescape);

use Statistics::Descriptive::LogScale;

my %STAT;
foreach (qw(time concurrency)) {
	$STAT{$_} = Statistics::Descriptive::LogScale->new;
};

my $CONC;

sub request {
	my ($writer, $param, $time) = @_;
	my $delay = $param->{delay} || 0.1;

	$CONC++;
	# warn "in request";
	my $timer;

	$timer = AE::timer $delay, undef, sub {
		# warn "in timer";
		undef $timer;
		my $t = time - $time;
		$writer->write("WAIT=$t\n");
		$writer->close;
		$STAT{time}->add_data(time - $time);
		$STAT{concurrency}->add_data($CONC);
		$CONC--;
	};
};

sub stat_summary {
	my ($writer, $param) = @_;

	my $type = $param->{type} || "time";
	if (!$STAT{$type}) {
		$writer->write ("No statistics avaliable for type=$type\n");
		$writer->close;
		return;
	};

	$writer->write("Statistical summary for $type\n");
	foreach my $method (qw(count mean std_dev)) {
		$writer->write("$method: ".$STAT{$type}->$method."\n");
	};

	foreach (0.5, 1, 5, 10, 25, 50, 75, 90, 95, 99, 99.5) {
		my $x = $STAT{$type}->percentile($_) // "-inf";
		$writer->write("$_%: $x\n");
	};
	$writer->close;
};

my %HANDLER = (
	stat => \&stat_summary,
	req => \&request,
);

my $RE = join "|", reverse sort map { quotemeta "/$_" } keys %HANDLER;
$RE = qr/^($RE).*?(?:\?(.*))?$/;

my @HEADER = (
	'Content-Type' => 'text/plain',
);

my $app = sub {
	my $env = shift;
	my $time = time;

	if ($env->{REQUEST_URI} !~ $RE) {
		return [ 404, \@HEADER, ["No such address here"] ]
	};
	my $uri = $1;
	my $query = $2 // '';
	my %hash = ( map { uri_unescape($_) } split /[&=]/, $query );
	$uri =~ s,^/,,;
	
	return sub {
		my $responder = shift;
		my $writer = $responder->([ 200, \@HEADER ]);

		# warn "in psgi cb, uri=$uri, sub=$HANDLER{$uri}";

		eval {
		$HANDLER{$uri}->($writer, \%hash, $time);
		};
		if ($@) {
			warn "dead: ".$@;
		};
	};
};

