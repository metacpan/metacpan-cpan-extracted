use strict;
use Test::More;
use lib qw(t);
use Data::Dumper;
use Errno qw(EAGAIN);
use POE qw(Component::IKC::ClientLite);

use POEIKC::Daemon;
use POEIKC::Daemon::P2P;
use POEIKC::Client;

eval q{ use Class::Inspector };
plan skip_all => "Class::Inspector is not installed." if $@;


eval q{ use Demo::P2P };
plan skip_all => "." if $@;


######################

$| = 1;

my @options = (
  "./bin/poeikcd start --alias=POEIKCd_t -n=ServerA -p=49225 -I=t:lib -M=Demo::P2P -s ",
  "./bin/poeikcd start --alias=POEIKCd_t -n=ServerB -p=49226 -I=t:lib -M=Demo::P2P -s ",
);

my @pid;
######################
foreach my $options (@options){
	 `$options`;
}
######################

	sleep 1;

	my @client_opt;
	for ( 49225, 49226 ){
		my ($name) = $0 =~ /(\w+)\.\w+/;
		$name .= $$ . sprintf "%02d",$_;
		my %cicopt = (
			ip => '127.0.0.1',
			port => $_,
			name => $name,
			timeout=>5,
			connect_timeout=>5,
		);
		push @client_opt, \%cicopt;
	}
	my @ikc;
	for (@client_opt){
		my $ikc = create_ikc_client(%{$_});
		$ikc or plan skip_all => POE::Component::IKC::ClientLite::error();
		push @ikc, $ikc;
	}


	my $sa;
	my $sb;

	$sa = $ikc[0]->post_respond( 'POEIKCd_t/something_respond' => ['ServerA_alias','server_connect','ServerB','49226'] );

sleep 1;

#		print Dumper $ikc[0];
#		print Dumper $ikc[1];

	$sa = $ikc[0]->post_respond( 'POEIKCd_t/something_respond' => ['ServerA_alias','go','ServerB'] );
	$sb = $ikc[1]->post_respond( 'POEIKCd_t/something_respond' => ['ServerB_alias','go','ServerA'] );

	$sa = $ikc[0]->post_respond( 'POEIKCd_t/something_respond' => ['ServerA_alias','get'] );
	$sb = $ikc[1]->post_respond( 'POEIKCd_t/something_respond' => ['ServerB_alias','get'] );
#print "\nsa=> $sa\n", Dumper $sa;
#print "\nsb=> $sb\n", Dumper $sb;
ref $sa ne 'HASH' and plan skip_all => __LINE__ . POE::Component::IKC::ClientLite::error();
ref $sb ne 'HASH' and plan skip_all => __LINE__ . POE::Component::IKC::ClientLite::error();

plan tests => 2;
is($sa->{this_pid} , $sb->{catch}->{PID}, "PID");
is($sb->{this_pid} , $sa->{catch}->{PID}, "PID");

######################
# shutdown
	for my $ikc ( @ikc ) {
		$ikc->post_respond('POEIKCd_t/method_respond',
			['POEIKC::Daemon::Utility','shutdown']
		);
		$ikc->error and die($ikc->error);
	}

# ` pkill -f poeikcd`;

1;

__END__

 poeikcd start -f --alias=POEIKCd_t -n=ServerA -p=49225 -I=eg/lib:lib:t -M=Demo::P2P
 poeikcd start -f --alias=POEIKCd_t -n=ServerB -p=49226 -I=eg/lib:lib:t -M=Demo::P2P

#  poikc -p=49225 -D "Demo::P2P->spawn"
#  poikc -p=49226 -D "Demo::P2P->spawn"

  poikc -p=49225 -D ServerA_alias server_connect ServerB 49226

  poikc -p=49225 -D ServerA_alias go ServerB
  poikc -p=49226 -D ServerB_alias go ServerA


#	$   poikc -p=49225 -D "Demo::P2P->spawn"
#	# $ikc_client->post_respond( 'POEIKCd_t/something_respond' => ['Demo::P2P->spawn'] );
#
#	$   poikc -p=49226 -D "Demo::P2P->spawn"
#	# $ikc_client->post_respond( 'POEIKCd_t/something_respond' => ['Demo::P2P->spawn'] );

$   poikc -p=49225 -D ServerA_alias server_connect ServerB 49226
# $ikc_client->post_respond( 'POEIKCd_t/something_respond' => ['ServerA_alias','server_connect','ServerB','49226'] );

$   poikc -p=49225 -D ServerA_alias go ServerB
# $ikc_client->post_respond( 'POEIKCd_t/something_respond' => ['ServerA_alias','go','ServerB'] );

$   poikc -p=49226 -D ServerB_alias go ServerA
# $ikc_client->post_respond( 'POEIKCd_t/something_respond' => ['ServerB_alias','go','ServerA'] );

