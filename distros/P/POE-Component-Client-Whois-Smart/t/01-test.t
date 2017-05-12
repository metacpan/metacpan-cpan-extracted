#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use POE;
use Data::Dumper;

# data for tests
my @domains = qw(     
    freshmeat.net
    freebsd.org
    reg.ru
    ns1.nameself.com.NS
    perl.com
);

my @domains_directi = map { "directi:$_" } qw(     
    freshmeat.net
    freebsd.org
    perl.com
    testazxcvawer.com
);


my @domains_not_reg = qw(
    thereisnosuchdomain123.com
    thereisnosuchdomain453.ru
    suxx.vn
);

my @domains_incorrect = qw/
    href=www.asdfzxcb.html>
/;

my @ips = qw(
    202.75.38.179
    207.173.0.0
    87.242.73.95
);

my @registrars = ('REGRU-REG-RIPN');
my $server  = 'whois.ripn.net',

my $directi_requests_send;

# start test
plan tests => @domains + 2*@domains_directi + @domains_not_reg + @ips + @registrars + @domains_incorrect + 1 + 2;

use_ok('POE::Component::Client::Whois::Smart');
print "The following tests requires internet connection...\n";

POE::Session->create(
    package_states => [
        'main' => [
                    qw(
                        _start
                        _response
                        _response_no_referral
                        _response_referral
                        _response_directi
                        _response_not_reg
                        _response_ip
                        _response_registrar
			_response_domains_incorrect
                    )
        ],
    ],
);

$poe_kernel->run();

sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP]; 

    POE::Component::Client::Whois::Smart->whois(
        query => \@domains,
        event => '_response',
	referral => 2,
	cache_dir => '/tmp/whois-gateway-d'
    );

    POE::Component::Client::Whois::Smart->whois(
        query => [ qw/moskva.com/ ],
        event => '_response_no_referral',
	referral => 0,
	cache_dir => '/tmp/whois-gateway'
    );

    POE::Component::Client::Whois::Smart->whois(
        query => [ qw/moskva.com/ ],
        event => '_response_referral',
        referral => 1,
	cache_dir => '/tmp/whois-gateway'
    );

    POE::Component::Client::Whois::Smart->whois(
        query  => \@registrars,
        server => $server, 
        event  => '_response_registrar',
    );

    POE::Component::Client::Whois::Smart->whois(
        query  => \@domains_not_reg,
        event  => '_response_not_reg',
    );
    
    POE::Component::Client::Whois::Smart->whois(
        query  => \@ips,
        event  => '_response_ip',
    );

    POE::Component::Client::Whois::Smart->whois(
        query  => \@domains_incorrect,
        event  => '_response_domains_incorrect',
    );

    POE::Component::Client::Whois::Smart->whois(
        query  => \@domains_directi,
        event  => '_response_directi',
	directi_params => {
	    service_username => 'boldin.pavel@gmail.com',
	    service_password => 'dazachem',
	    service_langpref => 'en',
	    service_role     => 'reseller',
	    service_parentid => '999999998',
	    url		     => 'https://api.onlyfordemo.net/anacreon/servlet/APIv3',
	},
    );
}

sub _response {
    my $full_result = $_[ARG0];
    foreach my $result ( @{$full_result} ) {
        my $query = $result->{query} if $result;
        $query =~ s/.NS$//i;

        ok( $result && !$result->{error} && $result->{whois} =~ /$query/i,
            "whois for domain ".$result->{query}." from ".$result->{server} );
    }                            

}

sub _response_no_referral {
    my $result = $_[ARG0]->[0];

    my $query = $result->{query} if $result;

#warn Dumper $result;

    ok( $result && !$result->{error} && $result->{whois} =~ /Whois Server:/,
	"non-referral whois for domain ".$result->{query}." from ".$result->{server} );
}

sub _response_referral {
    my $result = $_[ARG0]->[0];

    my $query = $result->{query} if $result;

#warn Dumper $result;

    ok(	    $result && !$result->{error} 
	&&  $result->{whois} !~ /Whois Server:/i
	&&  $result->{whois} =~ /Registrant Contact:/i,
	"referral whois for domain ".$result->{query}." from ".$result->{server} );
}

sub _response_directi {
    my $full_result = $_[ARG0];

    #warn Dumper \@_;

    foreach my $result ( @{$full_result} ) {
        my $query = $result->{query} if $result;
	my $ok;

	#use Data::Dumper;
	#warn Dumper $result;
	
	if ( $result->{whois} ) {
	  $ok  = $result->{whois} =~ m/^(available|regthrough)/;
	}
	else {
	    $ok = $result->{query} =~ m/\.(?:ru|ns)$/ && $result->{error};
	}
	$ok ||= $result->{error} eq 'Not found' && $query =~ m/^test/;

        ok( $ok, "whois for domain ".$result->{query}." from DirectI" );
    }                            

    if ( ! $directi_requests_send++ ) {
	POE::Component::Client::Whois::Smart->whois(
	    query  => \@domains_directi,
	    event  => '_response_directi',
	    directi_params => {
		service_username => 'boldin.pavel@gmail.com',
		service_password => 'dazachem',
		service_langpref => 'en',
		service_role     => 'reseller',
		service_parentid => '999999998',
		url		     => 'https://api.onlyfordemo.net/anacreon/servlet/APIv3',
	    },
	);
    }
}

sub _response_registrar {
    my $full_result = $_[ARG0];
    foreach my $result ( @{$full_result} ) {
        my $query = $result->{query} if $result;
	#print Dumper($result);


        ok( $result && !$result->{error} && $result->{whois} =~ /$query/i,
            "whois for registrar  ".$result->{query}." from ".$result->{server} );
    }                            
}

sub _response_not_reg {
    my $full_result = $_[ARG0];
    foreach my $result ( @{$full_result} ) {

	#warn Dumper $result;

        ok( $result && $result->{error},
            "whois for domain (not reged) ".$result->{query} );
    }                            
}

sub _response_ip {
    my $full_result = $_[ARG0];
    foreach my $result ( @{$full_result} ) {
        ok( $result && !$result->{error} && $result->{whois},
            "whois for IP ".$result->{query}." from ".$result->{server} );
    }                            
}

sub _response_domains_incorrect {
    my $full_result = $_[ARG0];
#    warn Dumper $full_result;

    foreach my $result ( @{$full_result} ) {
        ok(	$result && $result->{error}
	    &&	$result->{error} =~ m/^host resolve.*failed/,
            "host resolve for ".$result->{query}." from ".$result->{server} );
    }                            
}

1;
