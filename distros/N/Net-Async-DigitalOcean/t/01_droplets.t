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
    my $AGENDA = q{droplets: };

    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
    $do->start_actionables( 5 );

    my $f = $do->create_droplet({
	"name"       => "example.com",
	"region"     => "nyc3",
	"size"       => "s-1vcpu-1gb",
	"image"      => "openfaas-18-04",
	"ssh_keys"   => [],
	"backups"    => 'true',
	"ipv6"       => 'true',
	"monitoring" => 'true',
	"tags"       => [	    "env:prod",	    "web"	    ],
	"user_data"  => "#cloud-config\nruncmd:\n  - touch /test.txt\n",
#	"vpc_uuid"   => "760e09ef-dc84-11e8-981e-3cfdfeaae000"
				  });
    isa_ok($f, 'IO::Async::Future', $AGENDA.'first future');
    my $dro = $f->get;  # $dro = $dro->{droplet}; # $vol->{tags} //= [];
    is_deeply ($dro->{tags}, [ "env:prod", "web" ], $AGENDA.'tags');
 #   is( $dro->{vpc_uuid}, "760e09ef-dc84-11e8-981e-3cfdfeaae000", $AGENDA.'vpc');
    is( $dro->{name}, 'example.com', $AGENDA.'name');
    isa_ok( $dro->{image},  'HASH', $AGENDA.'image');
    isa_ok( $dro->{region}, 'HASH', $AGENDA.'region');
    isa_ok( $dro->{size},   'HASH', $AGENDA.'size');
    is_deeply ($dro->{features}, [ 'backups', 'monitoring' ], $AGENDA.'features');
    ok( exists $dro->{networks}->{v6}, $AGENDA.'ipv6' );
#    warn Dumper $dro;
#--
    $f = $do->droplet( id => $dro->{id} );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'same, future');
    my $dro2 = $f->get; $dro2 = $dro2->{droplet};
    $dro->{status}   = $dro2->{status};    # they seem to differ, sometimes
    $dro->{features} = $dro2->{features};  # they seem to differ
    $dro->{vpc_uuid} = $dro2->{vpc_uuid};  # they seem to differ
    $dro->{networks} = $dro2->{networks};  # they seem to differ
    $dro->{next_backup_window} = $dro2->{next_backup_window};  # they seem to differ
    is_deeply($dro, $dro2, $AGENDA.'found by id');
#--
    $f = $do->droplet( id => $dro->{id}.'xxx' );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    throws_ok {
	$f->get;
    } qr/not found/i, $AGENDA.'not found by id';
#-- create one more
    $dro2 = $do->create_droplet({
	"name"       => "example.com2",
	"region"     => "nyc3",
	"size"       => "s-1vcpu-1gb",
	"image"      => "openfaas-18-04",
	"ssh_keys"   => [],
	"backups"    => 'true',
	"ipv6"       => 'true',
	"monitoring" => 'true',
	"tags"       => [	    "env:prod",	    "web2"	    ],
	"user_data"  => "#cloud-config\nruncmd:\n  - touch /test.txt\n",
#	"vpc_uuid"   => "760e09ef-dc84-11e8-981e-3cfdfeaae000"
				  })->get;
#warn Dumper $dro2;
    is ($dro2->{name}, 'example.com2', $AGENDA.'2nd droplet, name');
    is_deeply ($dro2->{features}, [ 'backups', 'monitoring' ], $AGENDA.'2nd droplet, features');
    ok( exists $dro->{networks}->{v6}, $AGENDA.'ipv6' );
#--
    my $d = $do->droplets; # no tags
    isa_ok($d, 'IO::Async::Future', $AGENDA.'first future');

    my $page_size = 6;
    my $page = 0;
    do {
	(my $l, $d) = $d->get;
	isa_ok($d, 'IO::Async::Future', $AGENDA.'followup future') if defined $d;
#warn "list ", Dumper $l;
	if ($page == 0) {
	    ok (! defined $l->{links}->{first}, $AGENDA.'no first link');
	} else {
	    like ($l->{links}->{first}, qr/page=0/, $AGENDA.'first link');
	}
	$page++;
	like ($l->{links}->{next}, qr/$page/, $AGENDA.'next link') if $l->{links}->{next};
	my $s = $l->{meta}->{total}; my $last = int (($s-1) / $page_size);
	like ($l->{links}->{last}, qr/$last/, $AGENDA.'last link') if $l->{links}->{last};
    } while (defined $d);
#--
    $d = $do->droplets_all;
    isa_ok($d, 'IO::Async::Future', $AGENDA.'first future');
    my $l = $d->get;
    ok (scalar @{ $l->{droplets} } >= 2,                 $AGENDA.'full droplets, length');
    is (scalar @{ $l->{droplets} }, $l->{meta}->{total}, $AGENDA.'full droplets, consistency');
#warn Dumper $l->{droplets};
#TODO; all by tags

#-- delete by tag
    $f = $do->delete_droplet( tag => 'web' );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'delete by tag future');
    $f->get;
    diag( "delete done" );
#-- try again
    throws_ok {
	$do->delete_droplet( id => $dro->{id} )->get;
    } qr/not.+found/i, $AGENDA.'not found by id';
#-- delete by id
    $f = $do->delete_droplet( id => $dro2->{id} );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'delete by id future');
    $f->get;
    diag( "delete done" );
}

if (DONE) {
    my $AGENDA = q{multiple droplets: };

    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
    $do->start_actionables( 5 );

    my $f = $do->create_droplet({
	"names"      => [ "example1.com", "example2.com" ],
	"region"     => "nyc3",
	"size"       => "s-1vcpu-1gb",
	"image"      => "openfaas-18-04",
	"ssh_keys"   => [],
	"backups"    => 'true',
	"ipv6"       => 'true',
	"monitoring" => 'true',
	"tags"       => [	    "env:prod",	    "web"	    ],
	"user_data"  => "#cloud-config\nruncmd:\n  - touch /test.txt\n",
#	"vpc_uuid"   => "760e09ef-dc84-11e8-981e-3cfdfeaae000"
				  });
    isa_ok($f, 'IO::Async::Future', $AGENDA.'first future');
    my $dros = $f->get;  # $dro = $dro->{droplet}; # $vol->{tags} //= [];
#warn Dumper $dros;

    ok( eq_set([qw(example1.com example2.com)], [ map { $_->{name} } @$dros ]), $AGENDA.'name');

    map { is_deeply ($_->{tags}, [ "env:prod", "web" ], $AGENDA.'tags') } @$dros;
#   map { is( $_->{vpc_uuid}, "760e09ef-dc84-11e8-981e-3cfdfeaae000", $AGENDA.'vpc') } @$dros;
    map { isa_ok( $_->{image},  'HASH', $AGENDA.'image') } @$dros;
    map { isa_ok( $_->{region}, 'HASH', $AGENDA.'region') } @$dros;
    map { isa_ok( $_->{size},   'HASH', $AGENDA.'size') } @$dros;
#   map { is_deeply ($_->{features}, [ 'backups', 'ipv6', 'monitoring' ], $AGENDA.'features') } @$dros;
#--
    $do->delete_droplet( id => $_->{id} )->get for @$dros;
#--
    throws_ok {
	$do->create_droplet({
	    "names"      => [ map { "example$_.com"} 1..20 ],
	    "region"     => "nyc3",
	    "size"       => "s-1vcpu-1gb",
	    "image"      => "openfaas-18-04",
	    "ssh_keys"   => [],
	    "backups"    => 'true',
	    "ipv6"       => 'true',
	    "monitoring" => 'true',
	    "tags"       => [	    "env:prod",	    "web"	    ],
	    "user_data"  => "#cloud-config\nruncmd:\n  - touch /test.txt\n",
#	    "vpc_uuid"   => "760e09ef-dc84-11e8-981e-3cfdfeaae000"
			    })->get;
    } qr/cannot.+more.+droplets/, $AGENDA.'too many droplets to be created';
#--
    eval {
	$do->meta_account({ droplet_limit => 5 })->get;
	throws_ok {
	    $do->create_droplet({
	    "names"      => [ map { "example$_.com"} 1..6 ],
	    "region"     => "nyc3",
	    "size"       => "s-1vcpu-1gb",
	    "image"      => "openfaas-18-04",
	    "ssh_keys"   => [],
	    "backups"    => 'true',
	    "ipv6"       => 'true',
	    "monitoring" => 'true',
	    "tags"       => [	    "env:prod",	    "web"	    ],
	    "user_data"  => "#cloud-config\nruncmd:\n  - touch /test.txt\n",
	    "vpc_uuid"   => "760e09ef-dc84-11e8-981e-3cfdfeaae000"
			    })->get;
	} qr/droplet limit/, $AGENDA.'droplet limit';
    }; if ($@) {
	diag "meta interface not working";
    }
}

if (DONE) {
    my $AGENDA = q{droplet snapshots: };

    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
    $do->start_actionables( 5 );

    my $dro = $do->create_droplet({
	"name"       => "example.com",
	"region"     => "nyc3",
	"size"       => "s-1vcpu-1gb",
	"image"      => "openfaas-18-04",
	"ssh_keys"   => [],
	"backups"    => 'true',
	"ipv6"       => 'true',
	"monitoring" => 'true',
	"tags"       => [	    "env:prod",	    "web"	    ],
	"user_data"  => "#cloud-config\nruncmd:\n  - touch /test.txt\n",
#	"vpc_uuid"   => "760e09ef-dc84-11e8-981e-3cfdfeaae000"
				  })->get;
#warn Dumper $dro;
    is_deeply( $dro->{snapshot_ids}, [], $AGENDA.'no snapshots yet' );
    if (1) {
	$do->create_droplet_snapshot( id => $dro->{id} )->get;
	my $dro3 = $do->droplet( id => $dro->{id} )->get; $dro3 = $dro3->{droplet};
	is( (scalar @{ $dro3->{snapshot_ids} }), 1, $AGENDA.'1 snapshot' );
    }
#--
    my $dro2;
    if (1) {
	$do->create_droplet_snapshot( id => $dro->{id} )->get;
	$dro2 = $do->droplet( id => $dro->{id} )->get; $dro2 = $dro2->{droplet};
#warn Dumper $dro2;
	is( (scalar @{ $dro2->{snapshot_ids} }), 2, $AGENDA.'2 snapshots' );
    }
#--
    if (1) {
	my $f = $do->snapshots ( droplet => $dro->{id} );
	isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
	my $sns = $f->get; $sns = $sns->{snapshots};
	ok( eq_set([ map { $_->{id} } @$sns ], $dro2->{snapshot_ids}), $AGENDA.'all snapshots retrieved'  );
	map { is_deeply( [ $dro->{region}->{slug} ], $_->{regions}, $AGENDA.'snapshot regions') } @$sns;
#warn Dumper $sns;
    }
#-- cleanup
    $do->delete_snapshot( $_ ) for @{ $dro2->{snapshot_ids} };
    $do->delete_droplet( id => $dro->{id} )->get;
}

if (DONE) {
    my $AGENDA = q{droplet action: };

    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef, ); #tracing => 1 );
    $do->start_actionables( 5 );

    my $f;

    my $fdro1 = $do->create_droplet({
	"name"       => "example1.com",
	"region"     => "nyc3",
	"size"       => "s-1vcpu-1gb",
	"image"      => "openfaas-18-04",
	"ssh_keys"   => [],
	"backups"    => 'false',
	"ipv6"       => 'false',
	"monitoring" => 'true',
	"tags"       => [	    "env:prod",	    "web1"	    ],
#	"vpc_uuid"   => "760e09ef-dc84-11e8-981e-3cfdfeaae000"
				  });
    my $fdro2 = $do->create_droplet({
	"name"       => "example2.com",
	"region"     => "nyc3",
	"size"       => "s-1vcpu-1gb",
	"image"      => "openfaas-18-04",
	"ssh_keys"   => [],
	"backups"    => 'true',
	"ipv6"       => 'true',
	"monitoring" => 'true',
	"tags"       => [	    "env:prod",	    "web2"	    ],
#	"vpc_uuid"   => "760e09ef-dc84-11e8-981e-3cfdfeaae000"
				  });
    Future->wait_all( $fdro1, $fdro2 )->await;
    my $dros = $do->droplets->get;
#warn Dumper $dros;
    my ($dro1, $dro2) = @{ $dros->{droplets} };
#--
    if (1) {
	$f = $do->droplet_actions( id => $dro1->{id} );
	isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
	my $acs = $f->get; $acs = $acs->{actions};
#warn Dumper $acs;
	is( (scalar @$acs), 1,                     $AGENDA.'create actions');
	is( $acs->[0]->{resource_id}, $dro1->{id}, $AGENDA.'action droplet id');
	is( $acs->[0]->{type}, 'create',           $AGENDA.'action droplet type');
#--
	throws_ok {
	    $do->droplet_actions( id => $dro1->{id}.'xxx' )->get;
	} qr/not.+found/i, $AGENDA.'not found by id';
    }
#--
    if (1) {
	$f = $do->reboot( tag => 'env:prod' );
	isa_ok($f, 'IO::Async::Future', $AGENDA.'tagged actions');
	$f->get;
	ok( 1, $AGENDA."tagged reboot done" );
	my $acs = $do->droplet_actions( id => $dro1->{id} )->get; $acs = $acs->{actions};
#warn Dumper $acs;
	ok( eq_set( [ map { $_->{type} }   @$acs ], [ 'reboot', 'create' ] ), $AGENDA.'actions retrieved, type');
	ok( eq_set( [ map { $_->{status} } @$acs ], [ ('completed')x2 ] ),    $AGENDA.'actions retrieved, status');
	map { ok( $_->{completed_at},                                         $AGENDA.'actions retrieved, completed' ) } @$acs;
	$acs = $do->droplet_actions( id => $dro2->{id} )->get; $acs = $acs->{actions};
#warn Dumper $acs;
	ok( eq_set( [ map { $_->{type} }   @$acs ], [ 'reboot', 'create' ] ), $AGENDA.'actions retrieved, type');
	ok( eq_set( [ map { $_->{status} } @$acs ], [ ('completed')x2 ] ),    $AGENDA.'actions retrieved, status');
	map { ok( $_->{completed_at},                                         $AGENDA.'actions retrieved, completed' ) } @$acs;
    }
#--
    if (1) {
# does not complete:
#	             	 shutdown
	foreach my $type (qw(reboot
	             	 power_cycle

	             	 power_off
	             	 power_on  	 )) {
	    $f = $do->$type( id => $dro1->{id} );
	    isa_ok($f, 'IO::Async::Future', $AGENDA.'future '.$type);
	    $f->get;
	    ok( 1, $AGENDA."$type done" );
# TODO test return action
	}
    }
#--
    if (1) { # en/disable ipv6
	my $dro3 = $do->droplet( id => $dro1->{id} )->get; $dro3 = $dro3->{droplet};
	ok( (! grep { $_ eq 'ipv6' } @{ $dro3->{features} }), $AGENDA.'no ipv6');
	ok( ! (scalar @{ $dro3->{networks}->{v6} }), $AGENDA.'no ipv6');
	$f = $do->enable_ipv6( id => $dro1->{id} );
	isa_ok($f, 'IO::Async::Future', $AGENDA.'enable_ipv6');
	$f->get;
	ok( 1, $AGENDA."enable_ipv6 done" );

	diag "rebooting droplet...";
	$do->reboot( id => $dro3->{id} )->get;

	$dro3 = $do->droplet( id => $dro1->{id} )->get; $dro3 = $dro3->{droplet};
#warn Dumper $dro3;
	ok( (scalar @{ $dro3->{networks}->{v6} }), $AGENDA.'enabled ipv6');
#	ok( (grep { $_ eq 'ipv6' } @{ $dro3->{features} }), $AGENDA.'enabled ipv6');
#--
# 	if (0 && 0) { # this does NOT work with DO
# 	    $do->perform_droplet_actions( id => $dro1->{id}, 'disable_ipv6' )->get;
# 	    ok( 1, $AGENDA."disable_ipv6 done" );

# 	    diag "rebooting droplet...";
# 	    $do->perform_droplet_actions( id => $dro3->{id}, 'reboot' )->get;

# 	    $dro3 = $do->droplet( id => $dro1->{id} )->get; $dro3 = $dro3->{droplet};
# #warn Dumper $dro3;
# 	    ok( ! (scalar @{ $dro3->{networks}->{v6} }), $AGENDA.'no ipv6');
# #	ok( (! grep { $_ eq 'ipv6' } @{ $dro3->{features} }), $AGENDA.'no ipv6');
# 	}
#-- TODO

	# $dro3 = $do->droplet( id => $dro2->{id} )->get; $dro3 = $dro3->{droplet};
	# ok( (grep { $_ eq 'backups' } @{ $dro3->{features} }), $AGENDA.'backups enabled');
	# $do->perform_droplet_actions( id => $dro2->{id}, 'disable_backups' )->get;
	# $dro3 = $do->droplet( id => $dro2->{id} )->get; $dro3 = $dro3->{droplet};
	# ok( (! grep { $_ eq 'backups' } @{ $dro3->{features} }), $AGENDA.'backups disabled');
    }
#--
    if (1) { # renaming
	$f = $do->rename( id => $dro2->{id}, 'rumsti' );
	isa_ok($f, 'IO::Async::Future', $AGENDA.'rename');
	$f->get;
	ok( 1, $AGENDA.'renaming complete');
	_maybe_better_wait( $do, 10 );
	my $dro3 = $do->droplet( id => $dro2->{id} )->get; $dro3 = $dro3->{droplet};
	is($dro3->{name}, 'rumsti', $AGENDA.'rename');
    }
#--
    if (1) { # rebuild
	$f = $do->rebuild( id => $dro2->{id}, 'dokku-18-04' );
	isa_ok($f, 'IO::Async::Future', $AGENDA.'rebuild');
	$f->get;
	ok( 1, $AGENDA.'rebuilding complete');
	_maybe_better_wait( $do, 10 );
	my $dro3 = $do->droplet( id => $dro2->{id} )->get; $dro3 = $dro3->{droplet};
# warn Dumper $dro3;
	is($dro3->{image}->{slug}, 'dokku-18-04', $AGENDA.'rebuild');
    }
#--
    if (1) { # resize
	$f = $do->resize( id => $dro2->{id}, 's-1vcpu-2gb', 'true' );
	isa_ok($f, 'IO::Async::Future', $AGENDA.'resize');
	$f->get;
	ok( 1, $AGENDA.'resizing complete');
	_maybe_better_wait( $do, 10 );
	my $dro3 = $do->droplet( id => $dro2->{id} )->get; $dro3 = $dro3->{droplet};
#warn Dumper $dro3;
	is($dro3->{size}->{slug}, 's-1vcpu-2gb', $AGENDA.'resize');
	is($dro3->{size_slug},    's-1vcpu-2gb', $AGENDA.'resize');
    }
#-- cleanup
    $do->delete_droplet( id => $_->{id} )->get for @{ $dros->{droplets} }
}

done_testing;

__END__

if (0&&DONE) {
    my $AGENDA = q{droplets/backups: };

    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
    $do->start_actionables( 5 );

    my $dro = $do->create_droplet({
	"name"       => "example.com",
	"region"     => "nyc3",
	"size"       => "s-1vcpu-1gb",
	"image"      => "openfaas-18-04",
	"ssh_keys"   => [],
	"backups"    => 'true',
	"ipv6"       => 'true',
	"monitoring" => 'true',
	"tags"       => [	    "env:prod",	    "web"	    ],
	"user_data"  => "#cloud-config\nruncmd:\n  - touch /test.txt\n",
#	"vpc_uuid"   => "760e09ef-dc84-11e8-981e-3cfdfeaae000"
				  })->get;

    $do->_perform_droplet_backup( id => $dro->{id} )->get;
    my $dro1 = $do->droplet( id => $dro->{id} )->get; $dro1 = $dro1->{droplet};
#--
    my $f = $do->backups( $dro->{id} );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    my $bups = $f->get; $bups = $bups->{backups};
    is( (scalar @$bups), 1, $AGENDA.'1 backup' );
    is( $bups->[0]->{type}, 'backup', $AGENDA.'type');
warn Dumper $bups;
#--
    $do->_perform_droplet_backup( id => $dro->{id} )->get;
    $bups = $do->backups( $dro->{id} )->get; $bups = $bups->{backups};
    is( (scalar @$bups), 2, $AGENDA.'2 backups' );
    map { is( $_->{type}, 'backup', $AGENDA.'type') } @$bups;
#warn Dumper $bups;

#--
my $dro2; die "rework!!!";
    if (0) { # backup/restore
	$f = $do->_perform_droplet_backup( id => $dro2->{id} );
	isa_ok($f, 'IO::Async::Future', $AGENDA.'backup');
	$f->get;
	ok( 1, $AGENDA.'backup complete');
	my $dro3 = $do->droplet( id => $dro2->{id} )->get; $dro3 = $dro3->{droplet};
	is ((scalar @{ $dro3->{backup_ids} }), 1, $AGENDA.'1 backup');
#-
	$do->_perform_droplet_backup( id => $dro2->{id} )->get;
	$dro3 = $do->droplet( id => $dro2->{id} )->get; $dro3 = $dro3->{droplet};
	is ((scalar @{ $dro3->{backup_ids} }), 2, $AGENDA.'2 backups');
#warn Dumper $dro3;
#-
	$f = $do->perform_droplet_restore ( id => $dro2->{id}, $dro3->{backup_ids}->[0] );
	isa_ok($f, 'IO::Async::Future', $AGENDA.'restore');
	$f->get;
	ok( 1, $AGENDA.'restore complete');
#- backid not ok
	throws_ok {
	    $do->perform_droplet_restore ( id => $dro2->{id}, $dro3->{backup_ids}->[0].'xxx' )->get;
	} qr/not found/i, $AGENDA.'invalid backup';
#- any changes to test?
    }


}

