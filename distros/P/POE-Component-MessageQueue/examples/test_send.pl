
use Net::Stomp;
use Getopt::Long;
use Data::Random qw/rand_image/;
use MIME::Base64;
use strict;

my $MAX_THREADS  = 100;
my $MONKEY_COUNT = 10000;
my $USERNAME     = 'system';
my $PASSWORD     = 'manager';

sub throw_a_monkey
{
	my ($stomp, $headers) = @_;
	my $data  = "monkey";

	$stomp->send({
		destination => "/queue/monkey_bin",
		body        => $data,
		persistent  => 'true',
		%$headers
	});
}

sub throw_an_image
{
	my ($stomp, $headers) = @_;
	my $data  = rand_image(width => 640, height => 480);

	$stomp->send({
		destination => "/queue/monkey_bin",
		body        => encode_base64( $data ),
		persistent  => 'true',
		%$headers
	});
}

sub main
{
	my $port     = 61613;
	my $hostname = "localhost";

	my $count = 1;
	my $image = 0;
	my $fork  = 0;
	my $disconnect = 0;
	my $delay      = 0;
	my $deliver_after;

	GetOptions(
		"port|p=i"     => \$port,
		"hostname|h=s" => \$hostname,

		"count|c=i"    => \$count,
		"fork|f=i"     => \$fork,
		"image|i"      => \$image,
		"disconnect"   => \$disconnect,
		"delay|d=i"    => \$delay,

		"deliver-after|a=i" => \$deliver_after,
	);

	my $headers = {};

	if ( $deliver_after )
	{
		$headers->{'deliver-after'} = $deliver_after;
	}

	while ( $fork-- > 1 )
	{
		# for child and drop out of loop
		fork() or last;
	}

	my $_setup = sub ()
	{
		my $stomp = Net::Stomp->new({
			hostname => $hostname,
			port     => $port
		});
		$stomp->connect({ login => $USERNAME, passcode => $PASSWORD });
		return $stomp;
	};
	my $stomp = $_setup->();

	for (my $i = 0; $i < $count; $i++)
	{
		if ( $image )
		{
			throw_an_image($stomp, $headers);
		}
		else
		{
			throw_a_monkey($stomp, $headers);
		}

		if ( $disconnect )
		{
			$stomp->disconnect();
			$stomp = $_setup->();
		}

		if ( $delay )
		{
			sleep($delay);
		}
	}
	$stomp->disconnect();
}
main;

