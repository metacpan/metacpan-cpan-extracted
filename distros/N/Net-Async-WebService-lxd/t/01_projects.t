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
#    SSL_fingerprint => 'sha1$92:DD:63:F8:99:C4:5F:82:59:52:82:A9:09:C8:57:F0:67:56:B0:1B',
    SSL_fingerprint => 'sha256$7c263bae0e60802337233c7ff8edf3140ab5bdad968b71bff879322adee03e80',
) unless %SSL;

#== tests ========================================================


use IO::Async::Loop;
my $loop = IO::Async::Loop->new;

my @PROJECT = (); # (	project => 'test' );

my $lxd = Net::Async::WebService::lxd->new( loop        => $loop,
					    endpoint    => $ENV{LXD_ENDPOINT},
					    %SSL,
					    @PROJECT,
                                           );


if (DONE) {
    my $AGENDA = q{project life cycle: };

    my $f = $lxd->create_project(
	body => {
	    "config" => {
		"features.images"   => "false",
		"features.profiles" => "false"
	    },
	    "description" => "test project",
	    "name" => "test1"
	});
    isa_ok( $f, 'Future', $AGENDA.'future');
    like( $f->get, qr/success/i, $AGENDA.'created project');
#--
    my $p = $lxd->project( name => 'test1' )->get;
    is( $p->{description}, "test project", $AGENDA.'fetch info');
    ok( exists $p->{config}, $AGENDA.'fetch info');
#--
    $p = $lxd->project_state( name => 'test1' )->get;
    map { is( $_->{Usage}, 0, $AGENDA.'no usage' ) } values %{ $p->{resources} };
#--
    $lxd->rename_project( name => 'test1', body => { name => 'testx' } )->get;
    $p = $lxd->project( name => 'testx' )->get;
    is( $p->{description}, "test project", $AGENDA.'fetch info, renamed');

    $lxd->rename_project( name => 'testx', body => { name => 'test1' } )->get;
    $p = $lxd->project( name => 'test1' )->get;
    is( $p->{description}, "test project", $AGENDA.'fetch info, rerenamed');
#--
    $lxd->modify_project( name => 'test1', body => { description => "XXX" } )->get;
    $p = $lxd->project( name => 'test1' )->get;
    is( $p->{description}, "XXX", $AGENDA.'modified description');
#warn Dumper $p;
#--
    throws_ok {
	$lxd->create_project(
	    body => {
		"config" => {
		    "features.images"   => "false",
			"features.profiles" => "false"
		},
		    "description" => "test project",
		    "name" => "test1"
	    })->get;
    } qr/already/, $AGENDA.'duplicate project';
#--
    $lxd->create_project(
	    body => {
		"config" => {
		    "features.images"   => "false",
			"features.profiles" => "false"
		},
		    "description" => "test project",
		    "name" => "test2"
	    })->get;
    my $ps = $lxd->projects->get;
    is( (scalar grep { /test/ }  @$ps), 2, $AGENDA.'all projects');
#--
    foreach my $p ( map { /(test.+)/ ? $1 : () } @$ps ) {
	$lxd->delete_project( name => $p )->get;
    }
    $ps = $lxd->projects->get;
    is( (scalar grep { /test/ }  @$ps), 0, $AGENDA.'no projects');
}

done_testing;

__END__
