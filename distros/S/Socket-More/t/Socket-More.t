use strict;
use warnings;

use Test::More;
use Data::Cmp qw<cmp_data>;

use Socket qw<:all>;
use feature "say";



BEGIN { use_ok('Socket::More') };
use Socket::More ":all";

{
	#Test socket wrapper
	my $sock_addr=pack_sockaddr_in(1234, inet_pton(AF_INET, "127.0.0.1"));
	socket my $normal,AF_INET, SOCK_STREAM, 0;
	ok $normal, "Normal socket created";

	CORE::socket my $core, AF_INET, SOCK_STREAM,0;
	ok $core, "Core socket created";
	socket my $wrapper, $sock_addr, SOCK_STREAM,0;
	ok $wrapper, "Wrapper socket created";
	
	my $interface={family=>AF_INET,type=>SOCK_STREAM, protocol=>0};
	socket(my $hash, $interface);
	
	ok getsockname($normal) eq getsockname($core), "Sockets ok";
	ok getsockname($wrapper) eq getsockname($core), "Sockets ok";
	ok getsockname($hash) eq getsockname($core), "Socket ok";
	
}

{
	#Do we get any interfaces at all?
	my @interfaces=Socket::More::getifaddrs;
	ok @interfaces>=1, "interfaces returned";
}

{
	#No port or no path should give 0 results
	my @results=Socket::More::sockaddr_passive( { });
	ok @results==0, "No port, no result";

	@results=Socket::More::sockaddr_passive( {
			port=>[]
		});
	ok @results==0, "No port, no result";
	
	@results=Socket::More::sockaddr_passive( {
			path=>[]
		});

	ok @results==0, "No path, no result";
}
	
{
	#Test default specifications perform the same as explicit options
	#This gives all interfaces, AF_INET AF_INET6 and AF_UNIX
	my @results=Socket::More::sockaddr_passive( {
			path=>["asdf", "path2"],
			port=>[0,10,12]
		});
	#Should give same results
	my @results_family=Socket::More::sockaddr_passive( {
			family=>[AF_INET, AF_INET6, AF_UNIX],
			path=>["asdf", "path2"],
			port=>[0,10,12]
		});


	#Should give same results
	my @results_family_interface=Socket::More::sockaddr_passive( {
			interface=>".*",
			family=>[AF_INET, AF_INET6, AF_UNIX],
			path=>["asdf", "path2"],
			port=>[0,10,12]
		});

	#Should give same results. Not the partial name for family types
	my @results_family_string=Socket::More::sockaddr_passive( {
			family=>[qw(AF_INET INET6 UNIX)],
			path=>["asdf", "path2"],
			port=>[0,10,12]
		});

	#ok cmp_deeply(\@results, \@results_family),"Family ok";
	ok cmp_data(\@results, \@results_family)==0,"Family ok";
	#ok cmp_deeply(\@results, \@results_family_interface),"Family  and interface ok";
	ok cmp_data(\@results, \@results_family_interface)==0,"Family  and interface ok";
	ok cmp_data(\@results, \@results_family_string)==0,"Family ok";

}

{
	#say STDERR "BIND testing";
	#Attempt to bind our listeners
	my $unix_sock_name="test_sock";

	my $u_name=$unix_sock_name."_S";
	unlink $u_name if( -S $u_name);

	$u_name=$unix_sock_name."_D";
	unlink $u_name if( -S $u_name);


	my @results=Socket::More::sockaddr_passive( {
			path=>[$unix_sock_name],
			port=>[0,0,0]
	});

	for(@results){
		#say STDERR "ADDRESS/path: ".$_->{address};
		#unlink $_->{address};
		die "Could not make socket $!" unless socket my $socket, $_->{family}, SOCK_STREAM, 0;
		die "Could not bind $!" unless bind $socket, $_->{addr};

		my $name=getsockname($socket);
		if($_->{family}==AF_UNIX){
			my $path=unpack_sockaddr_un($name);
			#ok $path eq $unix_sock_name;
			close $socket;
			$u_name=$unix_sock_name."_S";
			unlink $u_name if( -S $u_name);

			$u_name=$unix_sock_name."_D";
			unlink $u_name if( -S $u_name);
		}
		elsif($_->{family} ==AF_INET or  $_->{family}== AF_INET6){
			#Check whe got a non zero port
			my($err, $ip, $port)=getnameinfo($name, NI_NUMERICHOST|NI_NUMERICSERV);
			ok $port != 0, "Non zero port";
			close $socket;

		}
		else{
			
		}
		
	}
	
}
{
	#say STDERR "Interger to string tests";
	#Test the af 2 name and name 2 af 
	#Each system is different by we assume that AF_INET and AF_INET6 are always available
	
	ok cmp_data([AF_INET],[string_to_family("AF_INET\$")])==0, "Name lookup ok";
	ok cmp_data([AF_INET6],[string_to_family("AF_INET6")])==0, "Name lookup ok";
	ok cmp_data([AF_INET, AF_INET6],[string_to_family("AF_INET")])==0, "Name lookup ok";

	ok "AF_INET" eq family_to_string(AF_INET), "String convert ok";
	ok "AF_INET6" eq family_to_string(AF_INET6), "String convert ok";
	
	ok cmp_data([SOCK_STREAM], [string_to_sock("SOCK_STREAM")])==0, "Name lookup ok";
	ok cmp_data([SOCK_DGRAM], [string_to_sock("SOCK_DGRAM")])==0, "Name lookup ok";

	ok "SOCK_STREAM" eq sock_to_string(SOCK_STREAM), "String convert ok";
	ok "SOCK_DGRAM" eq sock_to_string(SOCK_DGRAM), "String convert ok";
}
{
	#Command line argument string parsing
	my @spec=parse_passive_spec("interface=eth0, family=INET\$,type=STREAM");
	ok @spec==1, "Parsed ok";
	ok cmp_data($spec[0]{family},[AF_INET])==0, "Family match ok";
	ok cmp_data($spec[0]{type},[SOCK_STREAM])==0, "Type match ok";

}
{
	#Command line argument string parsing
	my @spec=parse_passive_spec("192.168.0.1:8080,type=stream");
	ok @spec==1, "Parsed ok";

	ok cmp_data($spec[0]{family}, [AF_INET])==0, "Family match ok";
	ok cmp_data($spec[0]{type}, [SOCK_STREAM])==0, "Type match ok";

	@spec=parse_passive_spec("path_goes_here,type=STREAM");
	ok @spec==1, "Parsed ok";

	ok cmp_data($spec[0]{family},[AF_UNIX])==0, "Family match ok";
	ok cmp_data($spec[0]{type},[SOCK_STREAM])==0, "Type match ok";


	@spec=parse_passive_spec(":8084");
	ok @spec==1, "Parsed ok";
	ok !exists($spec[0]{family}), "Omitted family from spec";

	@spec=parse_passive_spec(":8084,family=INET6,type=stream");

	ok cmp_data($spec[0]{family},[AF_INET6])==0, "Family match ok";
	ok cmp_data($spec[0]{type},[SOCK_STREAM])==0, "Type match ok";

}
{
	#Loopback
	my @results=Socket::More::sockaddr_passive( {address=>"localhost", port=>0, family=>AF_INET, type=>SOCK_DGRAM});
	ok @results==1,"localhost";

	ok $results[0]{address} eq "127.0.0.1", "localhost";


  SKIP:{
		skip "No IPv6 Interfaces", 2 unless (has_IPv6_interface);
		#Only test this if we know the system has at least one ipv6 address.
		@results=Socket::More::sockaddr_passive( {address=>"localhost", port=>0, family=>AF_INET6, type=>SOCK_DGRAM});
		ok @results==1,"localhost";

		ok $results[0]{address} eq "::1", "localhost";
	}
}
{
	#any/unspecified
	#Loopback
	my @results=Socket::More::sockaddr_passive( {address=>"0.0.0.0", port=>0, family=>AF_INET, type=>SOCK_DGRAM});
	ok @results==1, "ipv4 wildcard";
	ok $results[0]{address} eq "0.0.0.0", "ipv4 wildcard";

	@results=Socket::More::sockaddr_passive( {address=>"::", port=>0, family=>AF_INET6, type=>SOCK_DGRAM});
	ok @results==1, "unspecified address";
	ok $results[0]{address} eq "::", "unspecified address";
}

{
  #Test obtaining an unused port
	my @results=Socket::More::reify_ports Socket::More::sockaddr_passive( {address=>"0.0.0.0", port=>0, family=>AF_INET, type=>SOCK_DGRAM});
  
  #test the ports are non zero and all the same
  my $prev;
  for my $r (@results){
    ok ((defined($r->{port}) and $r->{port}!=0), "port reified");
    if(defined($prev)){
        ok $prev==$r->{port}, "Ports are the same";     
        $prev=$r->{port};
    }

    #Test that we can rebind to port immediately
    #
    ok defined (socket my $sock, $r->{family}, $r->{type}, 0), "Could not create port refied socket";
    ok defined (bind $sock, $r->{addr}), "Could not rebind reified port";
    close $sock;
  }
}
{
  #Test obtaining an unused port
	my @results=Socket::More::reify_ports_unshared Socket::More::sockaddr_passive( {address=>"0.0.0.0", port=>0, family=>AF_INET, type=>SOCK_DGRAM});
  
  #test the ports are non zero
  my $prev;
  for my $r (@results){
    ok ((defined($r->{port}) and $r->{port}!=0), "port reified");
    if(defined($prev)){

        #NOTE: This is likely to work.. but no guarentee that port numbers will be different accross interfaces
        ok $prev!=$r->{port}, "Ports different";     
        $prev=$r->{port};
    }

    #Test that we can rebind to port immediately
    #
    ok defined (socket my $sock, $r->{family}, $r->{type}, 0), "Could not create port refied socket";
    ok defined (bind $sock, $r->{addr}), "Could not rebind reified port";
    close $sock;
  }
}
##########################################################################
# {                                                                      #
#         #IF name and index mapping                                     #
#         my @name=map {$_->{name}} getifaddrs;                          #
#         my @index= map { Socket::More::if_nametoindex($_) } @name;     #
#         my @tname= map { Socket::More::if_indextoname($_)} @index;     #
#         for (0..$#index){                                              #
#                 ok $name[$_] eq $tname[$_], "Name->index->name match"; #
#         }                                                              #
#         my @nameindex=Socket::More::if_nameindex;                      #
#                                                                        #
#         ok @nameindex, "nameindex count ok";                           #
#                                                                        #
# }                                                                      #
##########################################################################

done_testing;
