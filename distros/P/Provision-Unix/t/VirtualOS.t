
use strict;
use warnings;

use Data::Dumper qw( Dumper );
use English qw( -no_match_vars );
use Test::More;

use lib "lib";
use Provision::Unix;
use Provision::Unix::User;
use Provision::Unix::VirtualOS;

my $prov = Provision::Unix->new( debug => 0 );
my $vos;

eval { $vos = Provision::Unix::VirtualOS->new( prov => $prov, fatal => 0, debug => 0 ) };
if ( $EVAL_ERROR ) {
    my $message = $EVAL_ERROR; chop $message;
    plan skip_all => $message;
} 
else {
    plan 'no_plan';
};

ok( defined $vos, 'get Provision::Unix::VirtualOS object' );
ok( $vos->isa('Provision::Unix::VirtualOS'), 'check object class' );


my $virt_class = ref $vos->{vtype};
my @parts = split /::/, $virt_class;
my $virt_type = lc( $parts[-1] );
ok( $virt_type, "virtualization type: $virt_type");

my $template_dir;
my $template_that_exists = undef;
if ( $virt_type =~ /virtuozzo|ovz|openvz|xen/ ) {

# get_template_dir
    $template_dir = $vos->get_template_dir( v_type => $virt_type );
    ok( $template_dir, "get_template_dir, $template_dir");

# get_template_list
    my $templates = $vos->get_template_list( v_type => $virt_type );
    ok( $templates && scalar @$templates, 'get_template_list' ) or do {
        warn "no templates installed!";
        exit;
    };
#warn Dumper($templates);

# select a template for testing
    my @preferred;
    @preferred = grep { $_->{name} =~ /debian/} @$templates or
    @preferred = grep { $_->{name} =~ /cpanel/} @$templates or
    @preferred = grep { $_->{name} =~ /ubuntu/} @$templates or
    @preferred = grep { $_->{name} =~ /centos/} @$templates or
        $template_that_exists = @$templates[0]->{name};
#warn Dumper(@preferred);

    if ( ! $template_that_exists ) {
        my @list = grep { $_->{name} =~ /default/} sort { $b cmp $a } @preferred;
        if ( scalar @list > 0 ) {
            no warnings;
            my @sorted = sort { ( $b =~ /(\d\.\d)/)[0] <=> ($a =~ /(\d\.\d)/)[0] } @list;
            use warnings;
            $template_that_exists = $sorted[0]->{name} if scalar @sorted > 0;
        };
        $template_that_exists ||= $preferred[0]->{name};
    };
};

my $ve_id_or_name
    = $virt_type eq 'openvz'    ? 72000
    : $virt_type eq 'ovz'       ? 72000
    : $virt_type eq 'virtuozzo' ? 72000
    : $virt_type eq 'xen'       ? 'test1'
    : $virt_type eq 'ezjail'    ? 'test1'
    : $virt_type eq 'jail'      ? 'test1'
    :                             undef;

my %common = (
    name  => $ve_id_or_name,
    debug => 0,
    fatal => 0,
);
my $required_bin
    = $virt_type eq 'openvz'    ? 'vzlist'
    : $virt_type eq 'ovz'       ? 'vzlist'
    : $virt_type eq 'virtuozzo' ? 'vzlist'
    : $virt_type eq 'xen'       ? 'xm'
    :                             undef;

my %requires_template = map { $_ => 1 } qw/ xen ovz openvz virtuozzo /;
my $util = $prov->get_util;

if ( defined $required_bin ) {
    my $found_bin
        = $util->find_bin( $required_bin, fatal => 0, debug => 0 );
    if ( !$found_bin || !-x $found_bin ) {
        print
            "Skipped tests b/c virtual type $virt_type chosen but $required_bin not found.\n";
        exit;
    }
}

ok( !$vos->is_valid_ip('1.1.1'),           'is_valid_ip -' );
ok( !$vos->is_valid_ip('1.1.1.1.1'),       'is_valid_ip -' );
ok(  $vos->is_valid_ip('1.1.1.1'),         'is_valid_ip +' );
ok( !$vos->is_valid_ip('0.0.0.0'),         'is_valid_ip -' );
ok( !$vos->is_valid_ip('255.255.255.255'), 'is_valid_ip -' );
ok( !$vos->is_valid_ip('0.1.1.1'),         'is_valid_ip -' );
ok(  $vos->is_valid_ip('2.1.1.1'),         'is_valid_ip +' );

#ok( $vos->_check_template( 'non-existing' ), '_check_default' );
#ok( $vos->_check_template( $template_that_exists), '_check_default' );

my $fs_root = $vos->get_fs_root( $ve_id_or_name );

# these are expensive tests.
SKIP: {
    skip "you are not root", 13 if $EFFECTIVE_USER_ID != 0;
    skip "could not determine a valid name", 12 if ! $ve_id_or_name;

my $r;

    if ( -d "$fs_root/etc" ) {
        print "\n$fs_root/etc/resolv.conf\n";
        $r = $vos->set_nameservers( 
            %common,
            nameservers  => '67.223.251.133 64.79.200.113',  # nyc
            #nameservers  => '64.79.200.111 64.79.200.113',  # tuk
            #searchdomain => 'example.com',
            test_mode    => 1,
        );
        ok( $r, "set_nameservers" );
    };

    if ( $vos->is_present( name => $ve_id_or_name ) ) {
        $r = $vos->get_status( name => $ve_id_or_name );
        ok( $r, 'get_status' );
    };

    if ( $virt_type eq 'xen' ) {
        # $r = $vos->install_config_file();
        # ok( $vos->is_running( name => $ve_id_or_name ), 'is_running');
    }

    my %request = ( %common );

    if ( $vos->is_present( %common ) ) {

        if ( $vos->is_running( %common ) ) {
            ok( $vos->stop( %common), 'stop');
        };

        $request{test_mode} = 0;
        ok( $vos->destroy( %common ), 'destroy');
        sleep 1;
    }

#$prov->error( 'dump' );

    $request{test_mode} = 1;
    $request{ip}        = '10.0.1.68';
    $request{ram}       = 512;
    $request{disk_size} = 4000;

    $r = $vos->create( %request );

    if ( $requires_template{$virt_type} ) {
        ok( !$r, 'create, no template' );
    }
    else {
        ok( $r, 'create, no template' );
    }

    $request{ip} = '10.0.1.';
    ok( !$vos->create( %request ), 'create, no valid IPs');

    $request{ip} = '10.0.1.70';
    $request{template} = 'non-existing';
    ok( !$vos->create( %request ), 'create, invalid template');

    if ( $requires_template{$virt_type} ) {
        $request{template} = $template_that_exists;
    }
    else {
        delete $request{template};
    };

    $request{ip}       = '10.0.1.73 10.0.1.74 10.0.1.75';
    $request{password} = 'p_u_t3stlng';
    $request{ssh_key}  = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAv6f4BW89Afnsx51BkxGvPbLeqDK+o6RXp+82KSIhoiWzCJp/dwhB7xNBR0W7Lt/n7KJUGYdlP7h5YlmgvpdJayzMkbsoBW2Hj9/7MkFraUlWYIU9QtAUCOARBPQWC3JIkslVvInGBxMxH5vcCO0/3TM/FFZylPTXjyqmsVDgnY4C1zFW3SdGDh7+1NCDh4Jsved+UVE5KwN/ZGyWKpWXLqMlEFTTxJ1aRk563p8wW3F7cPQ59tLP+a3iHdH9sE09ynbI/I/tnAHcbZncwmdLy0vMA6Jp3rWwjXoxHJQLOfrLJzit8wzG867+RYDfm6SZWg7iYZYUlps1LSXSnUxuTQ== matt@SpryBook-Pro.local';
    ok( $vos->create( %request ),
        "create, valid template ($template_that_exists), test mode"
    );

    $request{hostname} = 'test1.example.com';
    $request{nameservers} = '64.79.200.111 64.79.200.113';
    $request{test_mode} = 0;
    ok( $vos->create( %request ), 'create, valid request')
        or do {
            $request{debug} = 1;
            warn Dumper(\%request);
            diag $vos->create( %request );
        };

    ok( $vos->start( %common), 'start');

#exit;
#$prov->error( 'dump' );

    ok( $vos->restart( %common), 'restart');

    ok( $vos->set_password(
            %common,
            user     => 'root',
            password => 'letm3iwchlnny',
            ssh_key  => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAv6f4BW89Afnsx51BkxGvPbLeqDK+o6RXp+82KSIhoiWzCJp/dwhB7xNBR0W7Lt/n7KJUGYdlP7h5YlmgvpdJayzMkbsoBW2Hj9/7MkFraUlWYIU9QtAUCOARBPQWC3JIkslVvInGBxMxH5vcCO0/3TM/FFZylPTXjyqmsVDgnY4C1zFW3SdGDh7+1NCDh4Jsved+UVE5KwN/ZGyWKpWXLqMlEFTTxJ1aRk563p8wW3F7cPQ59tLP+a3iHdH9sE09ynbI/I/tnAHcbZncwmdLy0vMA6Jp3rWwjXoxHJQLOfrLJzit8wzG867+RYDfm6SZWg7iYZYUlps1LSXSnUxuTQ== matt@SpryBook-Pro.local',
        ),
        'set_password'
    );

    ok( $vos->disable( %common ), 'disable');
    ok( $vos->enable( %common ), 'enable');
    ok( $vos->stop( %common ), 'stop');

#exit;

    ok( $vos->destroy( %common, test_mode => 0), 'destroy');
};

#$prov->error( 'dump' );

