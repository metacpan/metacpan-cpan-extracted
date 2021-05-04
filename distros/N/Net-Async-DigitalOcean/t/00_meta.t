use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Moose;

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

# $ENV{DIGITALOCEAN_API} //= 'http://0.0.0.0:8080/';

use Net::Async::DigitalOcean;

eval {
    Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
}; if ($@) {
    plan skip_all => 'no endpoint defined ( e.g. export DIGITALOCEAN_API=http://0.0.0.0:8080/ )';
    done_testing;
}

{ # initalize and reset server state
    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
    eval {
	$do->meta_reset->get;
    }; if ($@) {
	plan skip_all => 'no meta API supported';
	done_testing;
    }
}

if (DONE) { # initalize and reset server state
    my $AGENDA = qq{meta: };
    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef);

    my $f = $do->meta_ping;
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    my $ps1 = $f->get; $ps1 = $ps1->{pings};
#--
    $do->meta_ping->get for (1..3); 
    my $ps2 = $do->meta_ping->get; $ps2 = $ps2->{pings};
    ok( $ps1 + 4 == $ps2, $AGENDA.'pings');
#--
    $f = $do->meta_reset;
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    $f->get;
    ok( 1, $AGENDA.'reset returned' );
#--
    $ps2 = $do->meta_ping->get; $ps2 = $ps2->{pings};
    ok ($ps2 == 1, $AGENDA.'ping after reset');
# warn $ps2;
#--
    $f = $do->meta_statistics;
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    my $ss = $f->get; # $ss = $ss->{statistics};
    is( $ss->{active_droplets}, 0, $AGENDA.'statistics, droplets');
#warn Dumper $ss;
#--
    $f = $do->meta_capabilities;
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    my $ca = $f->get;
#warn Dumper $ca;
    is( $ca->{chapter_domains}->{support}, "complete", $AGENDA.'capabilities');
}

done_testing;

__END__
