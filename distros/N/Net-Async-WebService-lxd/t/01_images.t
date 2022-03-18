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
	    },
		"description" => "Net::Async::WebService::lxd test suite",
		"name" => $PROJECT[1],
	})->get;
};

if (DONE) {
    my $AGENDA = q{images: };

    my $f = $lxd->create_image(
	@PROJECT,
	body => {
	    aliases => [ {"name" => "xxx$$", } ],
#            public => 'true',
#            auto_update => 0,
	    source => {
		type     => "image",
                mode     => "pull",
		server   => 'https://images.linuxcontainers.org',
		protocol => 'simplestreams',
		alias    => 'openwrt/snapshot',
            },
        }
	);
    isa_ok($f, 'Future', $AGENDA.'image creation initiated');

    my $r = $f->get;
#warn Dumper $r;
    is( $r, 'success', $AGENDA.'image creation finished');
#--
    my @is = @{ $lxd->images( @PROJECT )->get };
    ok((scalar @is) == 1, $AGENDA.'list 1 image');
#warn Dumper \@is;
    my ($fi) = @is;
    $fi =~ s{/1.0/images/}{};
    $f = $lxd->image( @PROJECT, fingerprint => $fi );
    isa_ok($f, 'Future', $AGENDA.'image retrieval initiated');
    my $i = $f->get;
#warn "image info ".Dumper $i;
    is( $i->{fingerprint}, $fi, $AGENDA.'retrieved image fingerprint');
    is( $i->{update_source}->{server}, 'https://images.linuxcontainers.org', $AGENDA.'retrieved image update source' );
    is( $i->{properties}->{os}, 'Openwrt', $AGENDA.'retrieved image os');
#--
    $r = $lxd->images_aliases(@PROJECT)->get;
    ok( (grep { $_ =~ /xxx$$/ } @$r), $AGENDA.'alias found');
#--
    $r = $lxd->image_alias( @PROJECT, name => "xxx$$" )->get;
    is ($r->{target}, $fi, $AGENDA.'alias info retrieved');
#--
    $r = $lxd->modify_images_alias( @PROJECT, name => "xxx$$", body => { description => 'new description' })->get;
    $r = $lxd->image_alias( @PROJECT, name => "xxx$$" )->get;
    is ($r->{target},      $fi, $AGENDA.'modified alias info retrieved');
    is ($r->{description}, 'new description', $AGENDA.'modified alias info retrieved');
#--
    $r = $lxd->rename_images_alias( @PROJECT, name => "xxx$$", body => { name => "rumsti$$" })->get;
    is($r, 'success', $AGENDA.'image alias modify finished');

    throws_ok {
	$lxd->image_alias( @PROJECT, name => "xxx$$" )->get;
    } qr/not found/i, $AGENDA.'modified alias';
    $r = $lxd->image_alias( @PROJECT, name => "rumsti$$" )->get;
    is ($r->{target},      $fi, $AGENDA.'modified alias info retrieved');
    is ($r->{description}, 'new description', $AGENDA.'modified alias info retrieved');
#--
    $r = $lxd->add_images_alias( @PROJECT, body => {
	"description" => "newer description",
        "name" =>  "ramsti$$",
        "target" => $fi,
        "type"   => "container" })->get;
    is($r, 'success', $AGENDA.'image alias add finished');
#--
    $r = $lxd->delete_image_alias( @PROJECT, name => "rumsti$$")->get;
    is_deeply ($r, {}, $AGENDA.'image alias delete finished');

    $r = $lxd->image_alias( @PROJECT, name => "ramsti$$" )->get;
    is ($r->{target},      $fi, $AGENDA.'added alias info retrieved');
    is ($r->{description}, 'newer description', $AGENDA.'added alias info retrieved');

#warn Dumper $r;exit;
#--
    $r = $lxd->modify_image( @PROJECT, fingerprint => $fi, body => {
	properties => {
	    os => 'Rumsti',
	}
			     })->get;
    is_deeply ($r, {}, $AGENDA.'patching image information');
#warn "modify response ".Dumper $r;
    $i = $lxd->image( @PROJECT, fingerprint => $fi )->get;
    is( $i->{properties}->{os}, 'Rumsti', $AGENDA.'modified image os');

#warn "after modify ".Dumper $i;
#--
    $r = $lxd->update_images_refresh( @PROJECT, fingerprint => $fi )->get;
    is( $r, 'success', $AGENDA.'image refresh finished');
#--
    if (0) { # TO BE DONE
	$f = $lxd->image_export( @PROJECT, fingerprint => $fi );
	$r = $f->get;
warn Dumper $r;
    }
#--
    $f = $lxd->delete_image( @PROJECT, fingerprint => $fi );
    isa_ok($f, 'Future', $AGENDA.'image deletion initiated');
    $r = $f->get;
#warn Dumper $r;
    is( $r, 'success', $AGENDA.'image deletion finished');
}

$lxd->delete_project( name => $PROJECT[1] )->get;

done_testing;

__END__


#-- simple life cycle
    my $f = $lxd->create_instance(
	@PROJECT,
	body => {
	    architecture => 'x86_64',
	    profiles     => [ 'default'  ],
	    name         => 'test1',
	    source       => { 'type' => 'image', fingerprint => '6dc6aa7c8c00' },
	    config       => {},
	} );

    is( $f->get, 'success', $AGENDA.'created inside project');
    throws_ok {
	$lxd->create_instance(
	    @PROJECT,
	    body => {
		architecture => 'x86_64',
		profiles     => [ 'default'  ],
		name         => 'test1',
		source       => { 'type' => 'image', fingerprint => '6dc6aa7c8c00' },
		config       => {},
	    } )->get;
    } qr/already/, $AGENDA.'container exists';
#-- instances
    $f = $lxd->instances( @PROJECT );
    isa_ok( $f, 'Future' );
    like( $f->get->[0],  qr{/1.0/instances/test1}, $AGENDA.'one instance found');
    isa_ok ( $lxd->instances( )->get, 'ARRAY', $AGENDA.'default project');

    ok( eq_set( $lxd->instances( project => 'testxxx' )->get, [] ), $AGENDA.'wrong project');
#    ok( eq_set( $lxd->instances( 'all-projects' => 'true' )->get, [ '/1.0/instances/test'] ), $AGENDA.'all projects');
#--
    my $i = $lxd->instance( name => 'test1', @PROJECT )->get;
#warn Dumper $i;
    cmp_deeply( $i, superhashof({
	name         => 'test1',
	description  => ignore(),
	architecture => ignore(),
	status       => ignore(),
				}), $AGENDA.'instance data');

#-- instances recursive
    my $is = $lxd->instances_recursion1( @PROJECT )->get;
#warn Dumper $is; exit;
    cmp_deeply( $is->[0], superhashof({
	name         => 'test1',
	description  => ignore(),
	config       => ignore(),
	expanded_config => ignore(),
	status       => ignore(),
				}), $AGENDA.'instances recursion 1');
    $is = $lxd->instances_recursion2( @PROJECT )->get;
#warn Dumper $is; exit;
    cmp_deeply( $is->[0], superhashof({
	name         => 'test1',
	backups      => ignore(),
	description  => ignore(),
	config       => ignore(),
	expanded_config => ignore(),
	status       => ignore(),
				}), $AGENDA.'instances recursion 2');
#--
    throws_ok {
	$lxd->instance( @PROJECT, name => 'xxx' )->get;
    } qr/not found/i, $AGENDA.'non-existing instance bombed';
#--
    $i = $lxd->instance_recursion1( @PROJECT, name => 'test1' )->get;
    cmp_deeply( $i, superhashof({
	name         => 'test1',
	description  => ignore(),
	architecture => ignore(),
	backups      => ignore(),
	description  => ignore(),
	config       => ignore(),
	expanded_config => ignore(),
	status       => ignore(),
				}), $AGENDA.'instance recursive data');
#--
    my $s = $lxd->instance_state( @PROJECT, name => 'test1' )->get;
    cmp_deeply( $s, superhashof({
	status         => 'Stopped',
	processes      => 0,
	memory         => ignore(),
	disk           => ignore(),
	network        => ignore(),
				}), $AGENDA.'instance state');
#- PUT state
    $s = $lxd->instance_state( @PROJECT, name => 'test1',
			       body => {
				   action   => "start",
				   force    => JSON::false,
				   stateful => JSON::false,
				   timeout  => 30,
			       } )->get;
#warn Dumper $s;
#--
    throws_ok {
	$lxd->delete_instance(@PROJECT, name => 'test1')->get;
    } qr/running/i, $AGENDA.'failed to delete running container';
#--
    $lxd->instance_state( @PROJECT, name => 'test1',
			  body => {
			      action   => "stop",
			      force    => JSON::false,
			      stateful => JSON::false,
			      timeout  => 30,
			  } )->get;
    is( $lxd->delete_instance(@PROJECT, name => 'test1')->get, 'success', $AGENDA.'deleted container');
}

