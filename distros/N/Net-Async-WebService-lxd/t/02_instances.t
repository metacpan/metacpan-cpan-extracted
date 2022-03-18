use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Deep;

use Data::Dumper;
$Data::Dumper::Indent = 1;
use JSON;

my $warn = shift @ARGV;
unless ($warn) {
    close STDERR;
    open (STDERR, ">/dev/null");
    select (STDERR); $| = 1;
}

use constant DONE => 1;

# $ENV{LXD_ENDPOINT} = 'https://192.168.3.50:8443';
unless ( $ENV{LXD_ENDPOINT} ) {
    plan skip_all => 'no LXD_ENDPOINT defined in ENV';
    done_testing; exit;
}

use Net::Async::WebService::lxd;

no  warnings 'once';
use Log::Log4perl::Level;
$Net::Async::WebService::lxd::log->level($warn ? $DEBUG : $ERROR); # one of DEBUG, INFO, WARN, ERROR, FATAL

sub _setup_dir {
    use File::Temp;
    my $tmpdir = File::Temp->newdir();
    return $tmpdir->dirname;
}

my %SSL = map  { $_ => $ENV{$_} }
          grep { $_ =~ /^SSL_/ }
          keys %ENV;

%SSL = (
    SSL_cert_file   => "t/client.crt",
    SSL_key_file    => "t/client.key",
    SSL_fingerprint => 'sha1$92:DD:63:F8:99:C4:5F:82:59:52:82:A9:09:C8:57:F0:67:56:B0:1B',
) unless %SSL;

#== tests ========================================================

use IO::Async::Loop;
my $loop = IO::Async::Loop->new;

my @PROJECT = (	project => 'test' );


my $lxd = Net::Async::WebService::lxd->new( loop      => $loop,
					    endpoint  => $ENV{LXD_ENDPOINT},
					    %SSL,
					    @PROJECT,
                                           );
eval {
    $lxd->create_project(
	body => {
	    "config" => {
		"features.images"   => "true",
		"features.profiles" => "false",
	    },
		"description" => "Net::Async::WebService::lxd test suite",
		"name" => $PROJECT[1],
	})->get;
};





if (DONE) {
    my $AGENDA = q{instances: };

#-- simple life cycle
    my $f = $lxd->create_instance(
	@PROJECT,
	body => {
	    name => "ccc$$",
	    source => {
		type => 'image',
		mode => 'pull',
		server => 'https://images.linuxcontainers.org',
		protocol => 'simplestreams',
		alias => 'alpine/edge',
	    },
	    profile => [ 'default' ],
	    architecture => 'x86_64',
	    config       => {},
	} );
    isa_ok( $f, 'Future', $AGENDA.'future creation' );
    is( $f->get, 'success', $AGENDA.'created');
#--
    my @is = @{ $lxd->images( @PROJECT )->get };
    ok((scalar @is) == 1, $AGENDA.'list 1 image');
    my ($fi) = @is;
    $fi =~ s{/1.0/images/}{};
#warn "original image $fi";

    if (1) { # execute
	$lxd->instance_state( @PROJECT, name => "ccc$$",
			      body => {
				  action   => "start",
				  force    => JSON::false,
				  stateful => JSON::false,
				  timeout  => 30,
			      } )->get;
	my $r = $lxd->execute_in_instance(
	    @PROJECT,
	    name => "ccc$$",
	    body => {
		"command" => [ '/usr/bin/cal' ],
#		"command" => [ "ash", "-c", 'echo "xxxx" > xxxx' ],
		"wait-for-websocket" => JSON::false,
		"interactive" => JSON::false,
		"environment" => {
		    "TERM" => "screen",
		    "HOME" => "/root",
		},
		"width"  => 0,
		"height" => 0,
		"record-output" => JSON::true,
		"user"   => 0,
		"group"  => 0,
		"cwd"    => "/tmp"
	    }
	    )->get;
	like($r->{stdout}, qr/Su Mo Tu/, $AGENDA.'execute stdout');
	is( $r->{stderr}, '', $AGENDA.'execute stderr');
	$lxd->instance_state( @PROJECT, name => "ccc$$",
			      body => {
				  action   => "stop",
				  force    => JSON::false,
				  stateful => JSON::false,
				  timeout  => 30,
			      } )->get;
    }

    if (1) {
	my $r = $lxd->instance_files(
	    @PROJECT,
	    name => "ccc$$",
	    path => "/",
	    )->get;
	is( scalar (grep { $_ eq 'usr' or $_ eq 'etc' } @$r), 2, $AGENDA.'root files');

	($r, my $h) = $lxd->instance_files(
	    wantheaders => 1,
	    @PROJECT,
	    name => "ccc$$",
	    path => "/etc/network/interfaces",
	    )->get;
#	is( scalar (grep { $_ eq 'usr' or $_ eq 'etc' } @$r), 2, $AGENDA.'lxd socket');
#warn Dumper $r, $h;
	like ($r, qr/dhcp/, $AGENDA.'file content' );
	is( $h->header( 'x-lxd-type' ), 'file', $AGENDA.'file get' );
	is( $h->header( 'x-lxd-uid' ),   0,     $AGENDA.'file get' );
	is( $h->header( 'x-lxd-gid' ),   0,     $AGENDA.'file get' );
	is( $h->header( 'x-lxd-mode' ), '0644', $AGENDA.'file get' );
#--
	my $text = "file contents";
	$r = $lxd->create_instance_file(
	    @PROJECT,
	    name => "ccc$$",
	    path => "/home/test",
	    headers => {
		'X-Lxd-Type' => 'file',
		'X-Lxd-Uid' => 405,
		'X-Lxd-Gid' => 100,
		'X-Lxd-Mode' => , '0644',
		'X-Lxd-Write' => , 'overwrite',
		'Content-Type' => 'application/octet-stream',
		'Content-Length' => length($text),
	    },
	    body => $text,
	    )->get;
	is_deeply( $r, {}, $AGENDA.'file written' );
#--
	throws_ok {
	    $lxd->delete_instance_files(
		@PROJECT,
		name => "ccc$$",
		path => "/home/testx",
		)->get;
	} qr/not found/i, $AGENDA.'deleted non-existing file';
	$r = $lxd->delete_instance_files(
	    @PROJECT,
	    name => "ccc$$",
	    path => "/home/test",
	    )->get;
	is_deeply( $r, {}, $AGENDA.'file deleted' );
	throws_ok {
	    $lxd->instance_files(
		@PROJECT,
		name => "ccc$$",
		path => "/home/test",
		)->get;
	} qr/not found/i, $AGENDA.'fetched non-existing file';
    }


    if (1) { # publish image from container
	$lxd->create_image(
	    @PROJECT,
	    body => {
		aliases => [ {"name" => "cccc$$", } ],
		source => {
		    type     => "instance",
		    name     => "ccc$$",
		},
	    }
	    )->get;
	@is = @{ $lxd->images( @PROJECT )->get };
#warn "current images".Dumper \@is;
	is( (scalar @is), 2, $AGENDA.'published container image' );
	my ($fi2) = grep { $_ !~ $fi} @is;
#warn "published image is $fi2 (and not $fi)";
	$fi2 =~ s{/1.0/images/}{};
	$f = $lxd->delete_image( @PROJECT, fingerprint => $fi2 );
	is( $f->get, 'success', $AGENDA.'published image deleted');
    }


    # $lxd->add_images_alias( @PROJECT, body => {
    # 	"description" => "newer description",
    #     "name" =>  "ramsti$$",
    #     "target" => $fi,
    #     "type"   => "container" })->get;
    
    throws_ok {
	$lxd->create_instance(
	    @PROJECT,
	    body => {
		architecture => 'x86_64',
		profiles     => [ 'default'  ],
		name         => "ccc$$",
		source       => { 'type' => 'image', fingerprint => $fi },
		config       => {},
	    } )->get;
    } qr/already/, $AGENDA.'container exists';
#-- instances
    $f = $lxd->instances( @PROJECT );
    isa_ok( $f, 'Future' );
    ok( (grep { $_ =~ qr{/1.0/instances/ccc$$} } @{ $f->get }), $AGENDA.'our instance found');
    isa_ok ( $lxd->instances( )->get, 'ARRAY', $AGENDA.'default project');

    ok( eq_set( $lxd->instances( project => 'testxxx' )->get, [] ), $AGENDA.'wrong project');
#    ok( eq_set( $lxd->instances( 'all-projects' => 'true' )->get, [ '/1.0/instances/test'] ), $AGENDA.'all projects');

#--
    if (1) {
	my $i = $lxd->instance( name => "ccc$$", @PROJECT )->get;
#warn Dumper $i; exit;
	cmp_deeply( $i, superhashof({
	    name         => "ccc$$",
	    description  => ignore(),
	    architecture => ignore(),
	    status       => ignore(),
				    }), $AGENDA.'instance data');

#-- instances recursive
	my $is = $lxd->instances_recursion1( @PROJECT )->get;
	($i) = grep { $_->{name} eq "ccc$$" } @$is;
#warn Dumper $is; exit;
	cmp_deeply( $i, superhashof({
	    name         => "ccc$$",
	    description  => ignore(),
	    config       => ignore(),
	    expanded_config => ignore(),
	    status       => ignore(),
				    }), $AGENDA.'instances recursion 1');
	$is = $lxd->instances_recursion2( @PROJECT )->get;
	($i) = grep { $_->{name} eq "ccc$$" } @$is;
#warn Dumper $is; exit;
	cmp_deeply( $i, superhashof({
	    name         => "ccc$$",
	    backups      => ignore(),
	    description  => ignore(),
	    config       => ignore(),
	    expanded_config => ignore(),
	    status       => ignore(),
				    }), $AGENDA.'instances recursion 2');
#--
	throws_ok {
	    $lxd->instance( @PROJECT, name => "xxx$$" )->get;
        } qr/not found/i, $AGENDA.'non-existing instance bombed';
#--
	$i = $lxd->instance_recursion1( @PROJECT, name => "ccc$$" )->get;
	cmp_deeply( $i, superhashof({
	    name         => "ccc$$",
	    description  => ignore(),
	    architecture => ignore(),
	    backups      => ignore(),
	    description  => ignore(),
	    config       => ignore(),
	    expanded_config => ignore(),
	    status       => ignore(),
				    }), $AGENDA.'instance recursive data');
#--
	my $s = $lxd->instance_state( @PROJECT, name => "ccc$$" )->get;
	cmp_deeply( $s, superhashof({
	    status         => 'Stopped',
	    processes      => 0,
	    memory         => ignore(),
	    disk           => ignore(),
	    network        => ignore(),
				}), $AGENDA.'instance state');
#- PUT state
	$s = $lxd->instance_state( @PROJECT, name => "ccc$$",
				   body => {
				       action   => "start",
				       force    => JSON::false,
				       stateful => JSON::false,
				       timeout  => 30,
				   } )->get;
    }
#warn Dumper $s;
#--
    throws_ok {
	$lxd->delete_instance(@PROJECT, name => "ccc$$")->get;
    } qr/running/i, $AGENDA.'failed to delete running container';
#--
    $lxd->instance_state( @PROJECT, name => "ccc$$",
			  body => {
			      action   => "stop",
			      force    => JSON::false,
			      stateful => JSON::false,
			      timeout  => 30,
			  } )->get;
#--
    my $r = $lxd->create_instance_snapshot(@PROJECT,
					   name => "ccc$$",
					   body => {
					       "expires_at" => "2023-03-23T17:38:37.753398689-04:00",
					       "name"       => "snap0",
					       "stateful"   => JSON::false,
					},
	)->get;
    is( $r, 'success', $AGENDA.'created snapshot');
    $f = $lxd->instance_snapshots( @PROJECT, name => "ccc$$");
    ok( (grep { $_ =~ qr{/1.0/instances/ccc$$} } @{ $f->get }), $AGENDA.'our snapshot found');

    $f = $lxd->instance_snapshot( @PROJECT, name => "ccc$$", snapshot => 'snap0');
    my $sn = $f->get;
    cmp_deeply( $sn, superhashof({
	name         => 'snap0',
	config         => ignore(),
				}), $AGENDA.'snapshot created');
#warn Dumper $sn;
#--
    $f = $lxd->create_instance(
	@PROJECT,
	body => {
	    name => "ddd$$",
	    source => {
		type =>  "copy",
		"base-image" =>  $fi,
		source =>  "ccc$$/snap0",
		allow_inconsistent =>  JSON::false,
	    },
	    profile => [ 'default' ],
	    architecture => 'x86_64',
	    config       => {},
	} );
    is( $f->get, 'success', $AGENDA.'created from snapshot');
    diag("TODO: restore from snapshot");

#--
    $f = $lxd->create_instance_backup( @PROJECT,
				       name => "ddd$$",
				       body => {
	compression_algorithm => "gzip",
	container_only => JSON::false,
	expires_at => "2023-03-23T17:38:37.753398689-04:00",
	instance_only => JSON::false,
	name => "backup0",
	optimized_storage => JSON::true
				       });
    isa_ok( $f, 'Future', $AGENDA.'started backup' );
    $r = $f->get;
    is( $r, 'success', $AGENDA.'created backup');

    if (1) {
	use File::Temp qw(tempdir);
	my $tmpdir = tempdir( CLEANUP => 1 );
#warn "temp $tmpdir";
	$r = $lxd->instance_backup_export( @PROJECT,
					   name => "ddd$$",
					   backup => "backup0" )->get;
	ok( length($r) > 100000, $AGENDA.'backup received' );
	use File::Slurp;
	write_file($tmpdir.'/backup.tar.gz', $r);
#warn "==================".Dumper $r;
	$r = $lxd->delete_instance_backup( @PROJECT,
					   name => "ddd$$",
					   backup => "backup0" )->get;
	is( $r, 'success', $AGENDA.'deleted backup');

	my $b = read_file($tmpdir.'/backup.tar.gz');
	$f = $lxd->create_instance(
	    @PROJECT,
	    headers => {
		'X-Lxd-Name' => "eee$$",
		'Accept-Encoding' => 'gzip',
		'Content-Type' => 'application/octet-stream',
#		'Transfer-Encoding' => 'chunked',
		'Content-Length' => length($b),
	    },
	    body => $b,
	    );
        isa_ok( $f, 'Future', $AGENDA.'future creation' );
        is( $f->get, 'success', $AGENDA.'created');
	#-- can I start/stop it?
	$lxd->instance_state( @PROJECT, name => "eee$$",
			      body => {
				  action   => "start",
				  force    => JSON::false,
				  stateful => JSON::false,
				  timeout  => 30,
			      } )->get;
	$lxd->instance_state( @PROJECT, name => "eee$$",
			      body => {
				  action   => "stop",
				  force    => JSON::false,
				  stateful => JSON::false,
				  timeout  => 30,
			      } )->get;
	is( $lxd->delete_instance(@PROJECT, name => "eee$$")->get, 'success', $AGENDA.'deleted container');
    }

#--
    is( $lxd->delete_instance(@PROJECT, name => "ccc$$")->get, 'success', $AGENDA.'deleted container');
    is( $lxd->delete_instance(@PROJECT, name => "ddd$$")->get, 'success', $AGENDA.'deleted container');
#--
#warn "to be deleted $fi";
    $lxd->delete_image( @PROJECT, fingerprint => $fi )->get;
}

if (DONE) {
    my $AGENDA = q{pseudo objects: };

    $lxd->create_instance(
	@PROJECT,
	body => {
	    name => "eee$$",
	    source => {
		type => 'image',
		mode => 'pull',
		server => 'https://images.linuxcontainers.org',
		protocol => 'simplestreams',
		alias => 'alpine/edge',
	    },
	    profile => [ 'default' ],
	    architecture => 'x86_64',
	    config       => {},
	} )->get;
    my $r = $lxd->instance( name => "eee$$", @PROJECT )->get;
    my $i = bless $r, 'lxd::instance';

    $i->start( $lxd );
    is( $i->state( $lxd )->{status}, 'Running', $AGENDA.'started' );
    $i->freeze( $lxd );
    is( $i->state( $lxd )->{status}, 'Frozen', $AGENDA.'frozen' );
    $i->stop( $lxd );
    is( $i->state( $lxd )->{status}, 'Stopped', $AGENDA.'stopped' );

    $lxd->delete_instance(@PROJECT, name => "eee$$")->get;

    my @is = @{ $lxd->images( @PROJECT )->get };
    ok((scalar @is) == 1, $AGENDA.'list 1 image');
    my ($fi) = @is;
    $fi =~ s{/1.0/images/}{};
    $lxd->delete_image( @PROJECT, fingerprint => $fi )->get;
}


eval {
    $lxd->delete_project( name => $PROJECT[1] )->get;
};

done_testing;

__END__


