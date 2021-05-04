use strict;
use warnings;

use Test::More;
use Test::Exception;

use Data::Dumper;
$Data::Dumper::Indent = 1;

my $warn = shift @ARGV;
unless ($warn) {
    close STDERR;
    open (STDERR, ">/dev/null");
    select (STDERR); $| = 1;
}

use constant DONE => 1;

use JSON;
use HTTP::Status qw(:constants);

use IO::Async::Loop;
my $loop = IO::Async::Loop->new;

use Net::Async::DigitalOcean;

use Log::Log4perl::Level;
$Net::Async::DigitalOcean::log->level('DEBUG') if $warn;


delete $ENV{DIGITALOCEAN_BEARER};
delete $ENV{DIGITALOCEAN_API};

if (DONE) {
    my $AGENDA = q{broken initialization: };

    throws_ok {
	Net::Async::DigitalOcean->new( );
    } qr/loop missing/i, $AGENDA.'no loop';
}

if (DONE) {
    my $AGENDA = q{smoke test env: };

    throws_ok {
	Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
    } qr/no.+endpoint/i, $AGENDA.'endpoint problem';
}

if (DONE) {
    my $AGENDA = q{local test against own server: };

    { # explicit
	my $do = Net::Async::DigitalOcean->new( loop => $loop,
						endpoint => 'http://0.0.0.0:8080/');
	is( $do->endpoint, 'http://0.0.0.0:8080/', $AGENDA.'explicit endpoint ok');
	ok( ! defined $do->bearer, $AGENDA.'no token');
	is( $do->rate_limit_frequency, 2, $AGENDA.'rate limit default');
    }

    { # implicit
	$ENV{DIGITALOCEAN_API} = 'http://0.0.0.0:8080/';
#--
	my $do = Net::Async::DigitalOcean->new( loop => $loop,
						endpoint => undef );
	is( $do->endpoint, 'http://0.0.0.0:8080/', $AGENDA.'implicit endpoint ok');
	ok( ! defined $do->bearer, $AGENDA.'no token');

	$ENV{DIGITALOCEAN_BEARER} = 'xxxx';
	$do = Net::Async::DigitalOcean->new( loop => $loop,
					     endpoint => undef );
	is( $do->endpoint, 'http://0.0.0.0:8080/', $AGENDA.'implicit endpoint ok');
	is( $do->bearer, 'xxxx', $AGENDA.'token');
	is( $do->rate_limit_frequency, 2, $AGENDA.'rate limit default');
	

#--
	$do = Net::Async::DigitalOcean->new( loop => $loop,
					     bearer => 'yyyy',
					     endpoint => undef,
					     rate_limit_frequency => 3,	    );
	is( $do->endpoint, 'http://0.0.0.0:8080/', $AGENDA.'implicit endpoint ok');
	is( $do->bearer, 'yyyy', $AGENDA.'token');
	is( $do->rate_limit_frequency, 3, $AGENDA.'rate limit explicit');
	
	delete $ENV{DIGITALOCEAN_BEARER};
	delete $ENV{DIGITALOCEAN_API};
    }

}

if (DONE) {
    my $AGENDA = q{real usage: };

    throws_ok {
	Net::Async::DigitalOcean->new( loop => $loop );
    } qr/bearer/, $AGENDA.'bearer token missing';

    $ENV{DIGITALOCEAN_BEARER} = 'xxxx';

    my $do = Net::Async::DigitalOcean->new( loop => $loop );
    is( $do->endpoint, Net::Async::DigitalOcean->DIGITALOCEAN_API, $AGENDA.'digitalocean endpoint ok');
    is( $do->rate_limit_frequency, 2, $AGENDA.'rate limited');
    is( $do->bearer, 'xxxx', $AGENDA.'token');

    delete $ENV{DIGITALOCEAN_BEARER};

# TODO: test headers
# TODO: integrate actionables into $do object?

}

done_testing;

__END__
