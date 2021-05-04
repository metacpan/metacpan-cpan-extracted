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

sub _maybe_better_wait {
    my ($do, $wait, $reason) = @_;
    return unless $do->endpoint eq Net::Async::DigitalOcean->DIGITALOCEAN_API;
    diag( $reason // "wait for creation" );    $loop->delay_future( after => $wait )->get;
}

# $ENV{DIGITALOCEAN_API} //= 'http://0.0.0.0:8080/';

use Net::Async::DigitalOcean;

use Log::Log4perl::Level;
$Net::Async::DigitalOcean::log->level('DEBUG') if $warn;


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
	diag "meta interface missing => no reset";
    }
}

if (DONE) {
    my $AGENDA = q{domains: };

    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );

    my $f;
#--
    $f = $do->create_domain( {name => "example1.devc.at"} ); # ,  ip_address => "1.2.3.4" } );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    my $dd = $f->get; $dd = $dd->{domain};
#warn Dumper $dd;
    is ($dd->{name}, 'example1.devc.at', $AGENDA.'created');
#    is ($dd->{ttl}, 1800, $AGENDA.'ttl');
    ok( exists $dd->{ttl}, $AGENDA.'ttl exists');
    ok( exists $dd->{zone_file}, $AGENDA.'zone');

    _maybe_better_wait( $do, 10 );
#--
    $f = $do->domain( "example1.devc.at" );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    $dd = $f->get; $dd = $dd->{domain};
    is ($dd->{name}, 'example1.devc.at', $AGENDA.'created');
    is ($dd->{ttl}, 1800, $AGENDA.'ttl');
    ok (exists $dd->{zone_file}, $AGENDA.'zone');
#--
    throws_ok {
	$do->domain( "rumsti" )->get;
    } qr/not found/i, $AGENDA.'domain not found by name';
#--
    $dd = $do->create_domain( {name => "example2.devc.at" })->get; # ,  ip_address => "1.2.3.4" } );
    _maybe_better_wait( $do, 10 );

    $f = $do->domains;
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    $dd = $f->get; $dd = $dd->{domains};
    is( (scalar @$dd), 2, $AGENDA.'nr of domains');
    map {is( $_->{ttl}, 1800, $AGENDA.'domains ttl')} @$dd;
    ok( eq_set( [ qw(example1.devc.at example2.devc.at) ], [ map{ $_->{name} } @$dd ] ), $AGENDA.'names');
    map { like( $_->{zone_file}, qr/hostmaster/, $AGENDA.'domains zone_file') } @$dd;
#--
    $do->create_domain( { name => "example3.devc.at",  ip_address => "1.2.3.4" } )->get;
    _maybe_better_wait( $do, 10 );

    $dd = $do->domains->get; $dd = $dd->{domains};
    map { like( $_->{zone_file}, qr/1.2.3.4/, $AGENDA.'zone_file reflects domain IP') }
    grep { $_->{name} =~ /example3/ } @$dd;
#--
    throws_ok {
	$do->create_domain( { name => "example3.devc.at" } )->get;
    } qr/exists/i, $AGENDA.'create domain already existing';

#--
    $f = $do->delete_domain( "example2.devc.at" );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    $f->get;
    ok(1, $AGENDA.'deleted');

    _maybe_better_wait( $do, 10 );

    throws_ok {
	$do->domain( "example2.devc.at" )->get;
    } qr/not found/i, $AGENDA.'domain not found by name';
#--
    throws_ok {
	$do->delete_domain( "example4.com" )->get;
    } qr/not.+found/i, $AGENDA.'delete domain not found by name';
#--
    $dd = $do->domains->get; $dd = $dd->{domains};
#warn Dumper $dd;
    foreach (@$dd) {
	$do->delete_domain( $_->{name} )->get;
    }
}

if (DONE) {
    my $AGENDA = q{domain records: };

    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );

    eval {
	$do->create_domain( {name => "example.devc.at" })->get;
	$do->create_domain( {name => "example2.devc.at", ip_address => "162.10.66.0" })->get;
	_maybe_better_wait( $do, 10 );
    };

    my $f;
#-- list, simple
    $f = $do->domain_records( "example.devc.at" );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    my $rs = $f->get; $rs = $rs->{domain_records};
    is( (scalar @$rs), 4, $AGENDA.'default');
    ok( eq_set( [ map { $_->{type} } @$rs ], [ qw(NS NS NS SOA ) ]), $AGENDA.'default types');
    map { like( $_->{data}, qr/ns\d\.digitalocean/, $AGENDA.'NS digitalocean') } grep { $_->{type} eq 'NS' } @$rs;
#-- create
    $f = $do->create_record( "example.devc.at",
			     {
				 type =>  "A",
				 name =>  "www",
				 data => "162.10.66.0",
				 priority => undef,
				 port => undef,
				 ttl => 1800,
				 weight => undef,
				 flags => undef,
				 tag => undef,
			     });
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    $f->get;
    ok(1, $AGENDA.'added');

    $rs = $do->domain_records( "example.devc.at" )->get; $rs = $rs->{domain_records};
#warn Dumper $rs;
    is( (scalar @$rs), 5, $AGENDA.'one added');
    map { is($_->{data}, "162.10.66.0", $AGENDA.'ip added')} grep { $_->{name} eq 'www' } @$rs;
    map { ok( defined $_->{id}, $AGENDA.'id added')} @$rs;
#warn Dumper $rs;
#--
    $f = $do->domain_record( "example.devc.at", $rs->[-1]->{id} );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    my $r = $f->get; $r = $r->{domain_record};
    is_deeply($rs->[-1], $r, $AGENDA.'record fetched');
#--
    $r->{data} = "162.10.66.10";
    $f = $do->update_record( "example.devc.at", $rs->[-1]->{id}, $r );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');

    my $r2 = $do->domain_record( "example.devc.at", $rs->[-1]->{id} )->get; $r2 = $r2->{domain_record};
    is_deeply( $r, $r2, $AGENDA.'updated');
#warn Dumper $r2;
#--
    $f = $do->delete_record( "example.devc.at", $rs->[-1]->{id} );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    lives_ok {
	$f->get;
    } $AGENDA.'deleted record';
    throws_ok {
	$do->domain_record( "example.devc.at", $rs->[-1]->{id} )->get;
    } qr/not found/i, $AGENDA.'delete confirmed';

#==
    $rs = $do->domain_records( "example2.devc.at" )->get; $rs = $rs->{domain_records};
    is( (scalar @$rs), 5, $AGENDA.'default');

    is( (scalar grep { $_->{type} eq 'NS'} @$rs), 3, $AGENDA.'NS with ip');
    ($r) = grep { $_->{type} eq 'A' } @$rs;
    is( $r->{data}, "162.10.66.0", $AGENDA.'create domain with ip record');
#--
    $rs = $do->domain_records( "example2.devc.at", type => 'NS' )->get; $rs = $rs->{domain_records};
    is( (scalar grep { $_->{type} eq 'NS'} @$rs), 3, $AGENDA.'NS via list typed');

    $rs = $do->domain_records( "example2.devc.at", type => 'A' )->get; $rs = $rs->{domain_records};
    is( (scalar grep { $_->{type} eq 'A'} @$rs), 1, $AGENDA.'A via list typed');

    $rs = $do->domain_records( "example2.devc.at", name => '@' )->get; $rs = $rs->{domain_records};
    is( (scalar @$rs), 5, $AGENDA.'@ via list named'); # A + NS + SOA

    $rs = $do->domain_records( "example2.devc.at", name => '@', type => 'A' )->get; $rs = $rs->{domain_records};
#warn Dumper $rs;
    is( (scalar @$rs), 1, $AGENDA.'A via list named+typed');

    throws_ok {
	$do->domain_records( "example2.devc.at", name => '@', type => 'XX' )->get;
    } qr/invalid|unprocess/i, $AGENDA.'nothing via list named+typed';

# warn Dumper $rs;
#-- cleanup
    $do->delete_domain( "example.devc.at" )->get;
    $do->delete_domain( "example2.devc.at" )->get;
}

done_testing;

