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
    my $AGENDA = q{droplets/volumes: };

    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef, ); # tracing => 1 );
    $do->start_actionables( 5 );

    my $dro = $do->create_droplet({
	"name"       => "example.com",
	"region"     => "nyc1",
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

    my $vol1 = $do->create_volume({
	"size_gigabytes"   => 10,
	"name"             => "example",
	"description"      => "Block store for examples",
	"region"           => "nyc1",
	"filesystem_type"  => "ext4",
	"filesystem_label" => "example",
	'tags'             => [],
			       })->get; $vol1 = $vol1->{volume};
#warn Dumper $vol1; 
    my $f = $do->volume_attach( $vol1->{id}, { type       => 'attach',
					       droplet_id => $dro->{id},
					       region     => 'nyc1'
				             } );
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    $f->get;
    ok(1 , $AGENDA.'attach done');
#--
    my $dro2 = $do->droplet( id => $dro->{id} )->get; $dro2 = $dro2->{droplet};
    is_deeply($dro2->{volume_ids}, [ $vol1->{id} ], $AGENDA.'attached volumes');
#--
    my $vol2 = $do->create_volume({
	"size_gigabytes"   => 10,
	"name"             => "example2",
	"description"      => "Block store for examples",
	"region"           => "nyc1",
	"filesystem_type"  => "ext4",
	"filesystem_label" => "example",
	'tags'             => [],
			       })->get; $vol2 = $vol2->{volume};
    $do->volume_attach( $vol2->{id}, { type       => 'attach',
				       droplet_id => $dro->{id},
				       volume_name => "volume2",
#				       region     => 'nyc1'
			             } )->get;
    $dro2 = $do->droplet( id => $dro->{id} )->get; $dro2 = $dro2->{droplet};
    ok(eq_set( $dro2->{volume_ids}, [ $vol1->{id}, $vol2->{id} ] ), $AGENDA.'attached volumes 2');
#--
    my $vol3 = $do->create_volume({
	"size_gigabytes"   => 10,
	"name"             => "example3",
	"description"      => "Block store for examples",
	"region"           => "nyc3",   # <-----
	"filesystem_type"  => "ext4",
	"filesystem_label" => "example",
	'tags'             => [],
			       })->get; $vol3 = $vol3->{volume};
    throws_ok {
	$do->volume_attach( $vol3->{id}, { type       => 'attach',
					   droplet_id => $dro->{id},
					   volume_name => "volume3",
			                 } )->get;
    } qr/allocation/, $AGENDA.'region mismatch';

#--
    $do->volume_attach( $vol1->{id}, { type       => 'detach',
				       droplet_id => $dro->{id},
				       region     => 'nyc1'
			             } )->get;
    $dro2 = $do->droplet( id => $dro->{id} )->get; $dro2 = $dro2->{droplet};
    is_deeply($dro2->{volume_ids}, [ $vol2->{id} ], $AGENDA.'attached volumes 3');
#--
    $do->volume_attach( $vol2->{id}, { type       => 'detach',
				       droplet_id => $dro->{id},
				       region     => 'nyc1' 
			             } )->get;
    $dro2 = $do->droplet( id => $dro->{id} )->get; $dro2 = $dro2->{droplet};
    is_deeply($dro2->{volume_ids}, [ ], $AGENDA.'attached volumes 4');
# warn Dumper $dro2;

#-- TODO use wrong region at attach/detach

#-- cleanup
    $do->delete_volume( id => $_->{id} )->get        for ($vol1, $vol2, $vol3);
    $do->delete_droplet( id => $dro->{id} )->get;
}

done_testing;

__END__
