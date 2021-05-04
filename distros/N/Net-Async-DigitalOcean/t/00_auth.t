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

use Net::Async::DigitalOcean;

eval {
    Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
}; if ($@) {
    plan skip_all => 'no endpoint defined ( e.g. export DIGITALOCEAN_API=http://0.0.0.0:8080/ )';
    done_testing;
}

if (DONE) {
    my $AGENDA = qq{authentication: };

    my $do;
    my $bearer = delete $ENV{DIGITALOCEAN_BEARER};

    eval {
	$do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
    }; if ($@ =~ /token missing/) { # problems here => we work against digitalocean itself
	$do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef, bearer => $bearer );

	lives_ok {
	    $do->account->get;
	} "authorization worked with '$bearer'";
	#--
	$ENV{DIGITALOCEAN_BEARER} .= "xxx";
	$do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
	
	throws_ok {
	    $do->account->get;
	} qr/invalid|unauthor/i, "authorization failed with '$ENV{DIGITALOCEAN_BEARER}'";
	
    } else { # no problem without a bearer
	eval {
	    $do->account->get;
	}; if ($@ =~ /token missing/i) {
	    diag "$@ => do testing";

	    $ENV{DIGITALOCEAN_BEARER} = $bearer || "a" x 64; # $bearer;
	    $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
	    
	    lives_ok {
		$do->account->get;
	    } "authorization worked with '$ENV{DIGITALOCEAN_BEARER}'";
	    #--
	    $ENV{DIGITALOCEAN_BEARER} .= "xxx";
	    $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
	    
	    throws_ok {
		$do->account->get;
	    } qr/invalid|unauthoriz/i, "authorization failed with '$ENV{DIGITALOCEAN_BEARER}'";
	} else {
	    plan skip_all => 'server does not support authentication';
	}
    }
}

done_testing;



__END__


# $ENV{DIGITALOCEAN_API} //= 'http://0.0.0.0:8080/';

if (DONE) { # initalize and reset server state
#    my $AGENDA = qq{account: };
    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
    $do->meta_reset->get;
}

if (DONE) {
    my $AGENDA = qq{account: };
    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef);

    my $f = $do->account;
    isa_ok($f, 'IO::Async::Future', $AGENDA.'first future');
    my $ac = $f->get; $ac = $ac->{account};
    ok( exists $ac->{email}, $AGENDA.'email' );
    is( $ac->{droplet_limit}, 25, $AGENDA.'limit default' );
#--
    $do->meta_account({ droplet_limit => 40 })->get;
    $ac = $do->account->get; $ac = $ac->{account};
    is( $ac->{droplet_limit}, 40, $AGENDA.'limit changed' );
#warn Dumper $ac;


}
done_testing;

__END__


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
