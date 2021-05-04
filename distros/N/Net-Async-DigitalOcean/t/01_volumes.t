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

#$ENV{DIGITALOCEAN_API} //= 'http://0.0.0.0:8080/';
#$ENV{DIGITALOCEAN_API} //= 'https://api.digitalocean.com/v2/';

use Net::Async::DigitalOcean;

eval { # figure out whether we should test at all
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
    my $AGENDA = q{creating/deleting volume endpoint: };

    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );

    my $f = $do->create_volume({
	"size_gigabytes"   => 10,
	"name"             => "example",
	"description"      => "Block store for examples",
	"region"           => "nyc1",
	"filesystem_type"  => "ext4",
	"filesystem_label" => "example",
	'tags'             => [],
			       });
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    my $vol = $f->get;  $vol = $vol->{volume}; # $vol->{tags} //= [];
#warn Dumper $vol;
    $vol->{tags} //= [];
    is ($vol->{name}, 'example', $AGENDA.'name');
    is (scalar( @{ $vol->{droplet_ids} }), 0, $AGENDA.'droplets');
    is ($vol->{region}->{slug}, 'nyc1', $AGENDA.'region');

#--
    $f = $do->volume( id => $vol->{id} );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    my $vol2 = $f->get;    $vol2 = $vol2->{volume};
#warn Dumper $vol, $vol2;
    is_deeply( $vol, $vol2, $AGENDA.'volume found again');
#--
#    $f = $do->volume( name => $vol->{name}, 'nyc1' );
#    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
#    $vol2 = $f->get;    $vol2 = $vol2->{volume};
#warn Dumper $vol, $vol2;
#    is_deeply( $vol, $vol2, $AGENDA.'volume found again by name and region');
#--
#    $f = $do->volume( name => $vol->{name}, 'xxx' );
#    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
#    throws_ok {
#	$f->get;
#    } qr/not found/i, $AGENDA.'not found by name and region';
#--
    $f = $do->volume( id => $vol->{id}.'xxx' );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    throws_ok {
	$f->get;
    } qr/not found/i, $AGENDA.'not found by id';
#--
    $f = $do->volumes;
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    my $vols = $f->get;    $vols = $vols->{volumes};
#warn Dumper $vols;
    ok ((grep { $_->{id} eq $vol->{id} } @$vols), $AGENDA.'this one volume found');
#--
    $do->create_volume({
	"size_gigabytes"   => 10,
	"name"             => "example",
	"description"      => "Block store for examples",
	"region"           => "fra1",
	"filesystem_type"  => "ext4",
	"filesystem_label" => "example2",
			       })->get;
#--
    $f = $do->volumes( name => $vol->{name} );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    my $vols2 = $f->get;    $vols2 = $vols2->{volumes};
#warn Dumper $vols2;
    ok ((scalar @$vols2) >= 2, $AGENDA.'volume found again by name, at least 2 volumes');
#--
    throws_ok {
	$do->create_volume({
	    "size_gigabytes"   => 10,
	    "name"             => "example",
	    "description"      => "Block store for examples",
	    "region"           => "fra111", # does not exist
	    "filesystem_type"  => "ext4",
	    "filesystem_label" => "example2",
			   })->get;
    } qr/region/, $AGENDA.'creation fail';

    if (1) {
#-- snapshots
	$f = $do->create_snapshot( $vol->{id}, { "name" => "big-data-snapshot1475261774" } );
	isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
	my $snap = $f->get; $snap = $snap->{snapshot};
	is ($snap->{resource_type}, 'volume', $AGENDA.'snapshot type');
	is ($snap->{name},          'big-data-snapshot1475261774', $AGENDA.'snapshot name');
	is ($snap->{resource_id},   $vol->{id}, $AGENDA.'snap volume id');
	ok( ! defined $snap->{tags} or (scalar @{$snap->{tags}}), $AGENDA.'snap empty tags');

#	is_deeply ($snap->{tags}, [], $AGENDA.'snap empty tags');
#	is_deeply ($snap->{regions}, [ qw(nyc1) ], $AGENDA.'snapshot region');
#--
	$snap = $do->create_snapshot( $vol->{id},
				      { "name" => "big-data-snapshot1475261774-2",
					"tags" => [ qw(some tags here) ],
				      } )->get; $snap = $snap->{snapshot};
	is ($snap->{name},          'big-data-snapshot1475261774-2', $AGENDA.'snapshot name 2');
#	is_deeply ($snap->{tags}, [ qw(some tags here) ], $AGENDA.'snap tags');
#--
	$f = $do->snapshots ( volume => $vol->{id} );
	isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
	my $snaps = $f->get; $snaps = $snaps->{snapshots};

	ok ((scalar @$snaps) == 2, $AGENDA.'exactly 2 snapshots');
	map { is($_->{resource_id}, $vol->{id}, $AGENDA.'snapshots resource id') }   @$snaps;
	map { is_deeply($_->{regions}, [ qw(nyc1) ], $AGENDA.'snapshots regions') }  @$snaps;

	ok( eq_set( [ map { @{ $_->{tags} } } @$snaps ],
		    [ qw(some tags here) ] ), $AGENDA.'snap all tags');
#warn Dumper $snaps;
#-- create for non-ex volume
	throws_ok {
	    $do->create_snapshot( $vol->{id}.'xxxx',
				  { "name" => "big-data-snapshot1475261774-2",
				    "tags" => [ qw(more tags here) ],
				  } )->get;
	} qr/not.+found/i, $AGENDA.'volume for snapshot not found';

	#-- delete snapshot
	$f = $do->delete_snapshot ($snaps->[0]->{id});
	isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
	lives_ok {
	    $f->get;
	} $AGENDA.'snapshot deleted';
	#--
	throws_ok {
	    $do->delete_snapshot ($snaps->[0]->{id})->get;
	} qr/not.+found/i, $AGENDA.'snapshot not found not deleted';
	lives_ok {
	    $do->delete_snapshot ($snaps->[1]->{id})->get;
	} $AGENDA.'snapshot 2 deleted';
    }
#======
#--
    $f = $do->delete_volume( id => $vol->{id}.'xxx' );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    throws_ok {
	$f->get;
    } qr/not.+found/i, $AGENDA.'not found not deleted';
#-- delete volume
    $f = $do->delete_volume( id => $vol->{id} );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    lives_ok {
	$f->get;
    } $AGENDA.'deleted';
#--
    $f = $do->delete_volume( name => $vol->{name}.'xxxx', 'sfo1' );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    throws_ok {
	$f->get;
    } qr/invalid region/i, $AGENDA.'not deleted by wrong name';
#--
    $f = $do->delete_volume( name => $vol->{name}, 'fra1' );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    lives_ok {
	$f->get;
    } $AGENDA.'deleted by name/region';
#-- clean up volumes
    map {
	diag "leftovers ".$_->{id};
#	$do->delete_volume( id => $_->{id} )->get;
    } @{ $do->volumes->get->{volumes} };

    use Future::Utils qw( fmap_void );
    my $clearer = fmap_void {
	$do->delete_volume( id => $_->{id} );
    } foreach => $do->volumes->get->{volumes};

    $loop->await( $clearer );

    diag "leftovers: ".Dumper [ map { $_->{id} } @{ $do->volumes->get->{volumes} } ];
    diag "volumes cleared";
}

if (DONE) {
    my $AGENDA = q{resizing volume: };

    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
    $do->start_actionables( 2 );

    my $vol = $do->create_volume({
	"size_gigabytes"   => 10,
	"name"             => "example",
	"description"      => "Block store for examples",
	"region"           => "nyc1",
	"filesystem_type"  => "ext4",
	"filesystem_label" => "example",
	'tags'             => [],
			       })->get; $vol = $vol->{volume};
#--
    my $f = $do->volume_resize( $vol->{id}, {
	                                      type           => 'resize',
					      size_gigabytes => 100,
					      region         => 'nyc1', });
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    $f->get;
    ok(1 , $AGENDA.'resize done');
#-- cleanup
    $do->delete_volume( name => $vol->{name}, 'nyc1' )->get;
}

done_testing;

__END__
