package Socket::More;

use 5.036000;

use Import::These qw<Socket::More:: Constants Interface>;
use Socket::More::Lookup ();

use Data::Cmp qw<cmp_data>;
use Data::Combination;



my @af_2_name;
my %name_2_af;
my @sock_2_name;
my %name_2_sock;

use constant::more  IPV4_ANY=>"0.0.0.0",
                    IPV6_ANY=>"::";

BEGIN{
	#build a list of address family names from socket
	my @names=grep /^AF_/, keys %Socket::More::Constants::;
	no strict;
	for my $name (@names){
		my $val;
		eval {
			$val=&{$name};
		};
		unless($@){
			$name_2_af{$name}=$val;
			$af_2_name[$val]=$name;
		}
	}


	@names=grep /^SOCK_/, keys %Socket::More::Constants::;

	#filter out the following bit masks on BSD, to prevent a huge array:
	#define	SOCK_CLOEXEC	0x10000000
	#define	SOCK_NONBLOCK	0x20000000
	
	for my $ignore(qw<SOCK_CLOEXEC SOCK_NONBLOCK>){
		@names=grep $_ ne $ignore, @names;
	}
	for my $name (@names){
		my $val;
		eval {
			$val=&{$name};
		};
		unless($@){
			$name_2_sock{$name}=$val;
			$sock_2_name[$val]=$name;
		}
	}
}



use Export::These qw<
	sockaddr_passive
	parse_passive_spec

	socket

	family_to_string
	string_to_family

	socktype_to_string
  sock_to_string

	string_to_socktype
  string_to_sock

	unpack_sockaddr


	has_IPv4_interface
	has_IPv6_interface

  reify_ports
  reify_ports_unshared

  sockaddr_family


  pack_sockaddr_un
  unpack_sockaddr_un

  pack_sockaddr_in
  unpack_sockaddr_in

  unpack_sockaddr_in6
  pack_sockaddr_in6


>;

sub _reexport {
  Socket::More::Constants->import;
  Socket::More::Lookup->import;
  Socket::More::Interface->import;
}

our $VERSION = 'v0.5.1';

sub string_to_family;
sub string_to_socktype;

# NOTE: These constants allow for perl to optimise away the false condition
# tests per platform
use constant::more IS_DARWIN=> !!($^O =~ /darwin/i),
                    IS_LINUX=> !!($^O =~ /linux/i),
                    IS_BSD=>   !!($^O =~ /bsd/i);


#Network interface stuff
#=======================
#
                    #
sub sockaddr_family {
  if(IS_LINUX){
    return unpack "S", $_[0];
  }
  if(IS_DARWIN){
    return unpack "xC", $_[0];
  }
  if(IS_BSD){
    return unpack "xC", $_[0];
  }
}



sub socket {

	if(ref($_[1]) eq "HASH"){
		#assume a 'interface object no need for remaining args
    
    #v 0.5.0 rename type to socktype
    $_[1]{socktype}=delete $_[1]{type} if exists $_[1]{type};
		return CORE::socket $_[0], $_[1]{family}, $_[1]{socktype}, $_[1]{protocol};
	}
  else{
    return &CORE::socket;
  }
}




sub unpack_sockaddr_un {
  my ($size, $fam, $name);
  if(IS_LINUX){
    ($fam,$name)=unpack "SZ[108]", $_[0];
  }
  if(IS_DARWIN){

    ($size,$fam,$name)=unpack "CCZ[104]", $_[0];
  }
  if(IS_BSD){
    ($size,$fam,$name)=unpack "CCZ[104]", $_[0];
  }

  
  $name;
}

sub pack_sockaddr_un {
  #pack PACK_SOCKADDR_UN, 106, AF_UNIX, $_[0];
  #PLATFORM eq pack PACK_SOCKADDR_UN, AF_UNIX, $_[0];
  if(IS_LINUX){
    return pack "SZ[108]", AF_UNIX, $_[0];
  }
  if(IS_DARWIN){
    return pack "CCZ[104]", 106, AF_UNIX, $_[0];
  }
  if(IS_BSD){
    return pack "CCZ[104]", 106, AF_UNIX, $_[0];
  }
}



sub pack_sockaddr_in {
  #pack PACK_SOCKADDR_IN, AF_INET, $_[0], $_[1];
  if(IS_LINUX){
    return pack "Sna4x8", AF_INET, $_[0], $_[1];
  }
  if(IS_DARWIN){
    return pack "xCna4x8", AF_INET, $_[0], $_[1];
  }
  if(IS_BSD){
    return pack "xCna4x8", AF_INET, $_[0], $_[1];
  }
}

sub unpack_sockaddr_in {
  #my ($port, $addr)=
  unpack "na4", substr($_[0], 2);
  #($port,$addr);
}



sub pack_sockaddr_in6 {
  #pack PACK_SOCKADDR_IN6,  AF_INET6, $_[0], $_[3]//0, $_[1], $_[2]//0;
  if(IS_LINUX){
    return pack  "snNa16N",  AF_INET6, $_[0], $_[3]//0, $_[1], $_[2]//0;
  }
  if(IS_DARWIN){
    return pack  "xCnNa16N",  AF_INET6, $_[0], $_[3]//0, $_[1], $_[2]//0;
  }
  if(IS_BSD){
    return pack  "xCnNa16N",  AF_INET6, $_[0], $_[3]//0, $_[1], $_[2]//0;
  }
}

sub unpack_sockaddr_in6{
  my($port,$flow,$ip,$scope)=unpack "nNa16N", substr($_[0], 2);
  ($port,$ip, $scope, $flow);
}

#Return a socket configured for the address

sub unpack_sockaddr{
	my ($addr)=@_;
	my $family=sockaddr_family $addr;
	if($family==AF_INET){
		return unpack_sockaddr_in $addr;
	}
	elsif($family==AF_INET6){
		return unpack_sockaddr_in6 $addr;
	}
  elsif($family == AF_UNIX){
		return unpack_sockaddr_un $addr;
  }
	else {
		die "upack_sockaddr: unsported family type";
	}
}


#Used as pseudo interface for filtering to work
sub make_unix_interface {

	{
		name=>"unix",
		addr=>pack_sockaddr_un("/thii")
	}
}


# Main routine to return passive address structures for binding or adding to
# multicast group
#
sub sockaddr_passive{
	require Scalar::Util;
	my ($spec)=@_;

  # v0.5.0 renamed type to socktype
  $spec->{socktype}=delete $spec->{type} if exists $spec->{type};

	my $r={};

	#If no interface provided assume all
	$r->{interface}=$spec->{interface}//".*";
	
        ##############################################
        # if(ref($r->{interface}) ne "ARRAY"){       #
        #         $r->{interface}=[$r->{interface}]; #
        # }                                          #
        ##############################################

	$r->{socktype}=$spec->{socktype}//[SOCK_STREAM, SOCK_DGRAM];
	$r->{protocol}=$spec->{protocol}//0;

	#If no family provided assume all
	$r->{family}=$spec->{family}//[AF_INET, AF_INET6, AF_UNIX];	
	
	#Configure port and path
	$r->{port}=$spec->{port}//[];
	$r->{path}=$spec->{path}//[];
	
  ######
  #v0.4.0 adds string support for type and family
  
  # Convert to arrays for unified interface 
  for($r->{socktype}, $r->{family}){
    unless(ref eq "ARRAY"){
      $_=[$_];
    }
  }

  for($r->{socktype}->@*){
    unless(Scalar::Util::looks_like_number $_){
      ($_)=string_to_socktype $_;
    }
  }

  for($r->{family}->@*){
    unless(Scalar::Util::looks_like_number $_){
      ($_)=string_to_family $_;
    }
  }
  # End
  #####


	#NOTE: Need to add an undef value to port and path arrays. Port and path are
	#mutually exclusive
	if(ref($r->{port}) eq "ARRAY"){
		unshift $r->{port}->@*, undef;
	}
	else {
		$r->{port}=[undef, $r->{port}];
	}


	if(ref($r->{path}) eq "ARRAY"){
		unshift $r->{path}->@*, undef;
	}
	else {
		$r->{path}=[undef, $r->{path}];
	}

	die "No port number specified, no address information will be returned" if ($r->{port}->@*==0) or ($r->{path}->@*==0);

	#Delete from combination specification... no need to make more combos
  #
  my $enable_group=exists $spec->{group};

	my $address=delete $spec->{address};
	my $group=delete $spec->{group};
	my $data=delete $spec->{data};

	$address//=".*";
	$group//=".*";

	#Ensure we have an array for later on
	if(ref($address) ne "ARRAY"){
		$address=[$address];
	}

	if(ref($group) ne "ARRAY"){
		$group=[$group];
	}

	my @interfaces=(make_unix_interface, Socket::More::getifaddrs);

	#Check for special cases here and adjust accordingly
	my @new_address;
	my @new_interfaces;
	##my @new_spec_int;
	my @new_fam;

  # IF IPV4_ANY or IPV6_ANY is specified,  nuke any other address provided
  #
	if(grep /${\IPV4_ANY()}/, @$address){
		#push @new_spec_int, IPV4_ANY;
		push @new_address, IPV4_ANY;
		push @new_fam, AF_INET;
    my @results;
    Socket::More::Lookup::getaddrinfo(
      IPV4_ANY,
      "0",
      {flags=>NI_NUMERICHOST|NI_NUMERICSERV, family=>AF_INET},
      @results
    );


		push @new_interfaces, ({name=>IPV4_ANY,addr=>$results[0]{addr}});
	}

	if(grep /${\IPV6_ANY()}/, @$address){
		#push @new_spec_int, IPV6_ANY;
		push @new_address, IPV6_ANY;
    push @new_fam, AF_INET6;
    my @results;
    Socket::More::Lookup::getaddrinfo(
      IPV6_ANY,
      "0",
      {flags=>NI_NUMERICHOST|NI_NUMERICSERV, family=>AF_INET6},
      @results
    );
    push @new_interfaces, ({name=>IPV6_ANY, addr=>$results[0]{addr}});
	}


  # TODO: Also add special case for multicast interfaces? for datagrams?

	if(@new_address){
		@$address=@new_address;
		@interfaces=@new_interfaces;
		$r->{interface}=[".*"];
	}

	#$r->{family}=[@new_fam];

	#Handle localhost
	if(grep /localhost/, @$address){
		@$address=('^127.0.0.1$','^::1$');
		$r->{interface}=[".*"];
	}

  

  $r->{address}=$address;

	#Generate combinations
	my $result=Data::Combination::combinations $r;
	

	#Retrieve the interfaces from the os
	#@interfaces=(make_unix_interface, Socket::More::getifaddrs);


	#Poor man dereferencing
	my @results=$result->@*;
	
	#Force preselection of matching interfaces
	@interfaces=grep {
		my $interface=$_;
		scalar grep {$interface->{name} =~ $_->{interface}} @results
	} @interfaces;

	#Validate Family and fill out port and path
  no warnings "uninitialized";
	my @output;
	for my $interface (@interfaces){
		my $fam= sockaddr_family($interface->{addr});
		for(@results){
			next if $fam != $_->{family};

			#Filter out any families which are not what we asked for straight up

			goto CLONE if ($fam == AF_UNIX) 
				&& ($interface->{name} eq "unix")
				#&& ("unix"=~ $_->{interface})
				&& (defined($_->{path}))
				&& (!defined($_->{port}));


			goto CLONE if
				($fam == AF_INET or $fam ==AF_INET6)
				&& defined($_->{port})
				&& !defined($_->{path})
				&& ($_->{interface} ne "unix");

			next;
	CLONE:
		
			my %clone=$_->%*;			
			my $clone=\%clone;
			$clone{data}=$spec->{data};

			#A this point we have a valid family  and port/path combo
			#
			my ($err, $res, $service);


			#Port or path needs to be set
			if($fam == AF_INET){
        if(!exists $_->{address} or $_->{address} eq ".*"){
          my (undef, $ip)=unpack_sockaddr_in($interface->{addr});

          # Get the hostname/ip address as human readable string aka inet_ntop($fam, $ip);
          Socket::More::Lookup::getnameinfo($interface->{addr}, my $host="", my $port="", NI_NUMERICHOST|NI_NUMERICSERV);

          # Pack with desired port
          $clone->{address}=$host;
          $clone->{addr}=pack_sockaddr_in($_->{port}, $ip);
        }
        else {
          my @results;
          Socket::More::Lookup::getaddrinfo($_->{address},$_->{port},{flags=>NI_NUMERICHOST|NI_NUMERICSERV, family=>AF_INET,socktype=>$_->{socktype},protocol=>$_->{protocol}}, @results);
          $clone->{addr}=$results[0]{addr};
        }
				$clone->{interface}=$interface->{name};
        $clone->{if}=$interface;  # From v0.5.0

        if($enable_group){
          require Socket::More::IPRanges;
          $clone->{group}=Socket::More::IPRanges::ipv4_group($clone->{address});
        }
			}
			elsif($fam == AF_INET6){
        if(!exists $_->{address} or $_->{address} eq ".*"){
          my(undef, $ip, $scope, $flow_info)=unpack_sockaddr_in6($interface->{addr});
          Socket::More::Lookup::getnameinfo($interface->{addr}, my $host="", my $port="", NI_NUMERICHOST|NI_NUMERICSERV);
          $clone->{address}=$host;
          $clone->{addr}=pack_sockaddr_in6($_->{port},$ip, $scope, $flow_info);
        }
        else {
          my @results;
          Socket::More::Lookup::getaddrinfo($_->{address},$_->{port},{flags=>NI_NUMERICHOST|NI_NUMERICSERV, family=>AF_INET6,socktype=>$_->{socktype},protocol=>$_->{protocol}}, @results);
          $clone->{addr}=$results[0]{addr};
        }

				$clone->{interface}=$interface->{name};
        if($enable_group){
          require Socket::More::IPRanges;
          $clone->{group}=Socket::More::IPRanges::ipv6_group($clone->{address});
        }
			}
			elsif($fam == AF_UNIX){
				my $suffix=$_->{socktype}==SOCK_STREAM?"_S":"_D";

				$clone->{addr}=pack_sockaddr_un $_->{path}.$suffix;
				my $path=unpack_sockaddr_un($clone->{addr});			
				$clone->{address}=$path;
				$clone->{path}=$path;
				$clone->{interface}=$interface->{name};
				$clone->{group}="UNIX" if $enable_group;
			}
			else {
				die "Unsupported family type";
				last;
			}
			#$clone->{interface}=$interface->{name};

			#Final filtering of address and group
			next unless grep {$clone->{address}=~ /$_/i } @$address;
			
      if($enable_group){
        next  unless grep {$clone->{group}=~ /$_/i } @$group;
      }
      next unless defined $clone->{addr};

			#copy data to clone
			$clone->{data}=$data;
			push @output, $clone;		
		}
	}

	my @list;

	#Ensure items in list are unique
  push @list, $output[0] if @output;
  for(my $i=1; $i<@output; $i++){
          my $out=$output[$i];
          my $found=grep {!cmp_data($_, $out)} @list; 
          push @list, $out unless $found;
  }


	
        #@output=@list;
  #@output=siikeysort {$_->{interface}, $_->{family}, $_->{type}} @output;
  @output=sort {
    $a->{interface} cmp $b->{interface} || $a->{family} cmp $b->{family}|| $a->{socktype} cmp $b->{socktype}
  } 
    #v0.5.0 renamed type to socktype, alias back for compatibility
    map {$_->{type}=$_->{socktype};$_} @list;
  
}

#Parser for CLI  -l options
sub parse_passive_spec {
	#splits a string by : and tests each set
	my @output;
	my @full=qw<interface type socktype protocol family port path address group data>;
	for my $input(@_){
		my %spec;

		#split fields by comma, each field is a key value pair,
		#An exception is made for address::port

		my @field=split ",", $input;

		#Add information to the spec
		for my $field (@field){
			if($field!~/=/){
				for($field){
					if(/(.*):(.*)$/){
						#TCP and ipv4 only
						$spec{address}=[$1];
						$spec{port}=length($2)?[$2]:[];

						if($spec{address}[0] =~ /localhost/){
							#do not set family
							#$spec{address}=['^127.0.0.1$','^::1$'];
						}
						elsif($spec{address}[0] eq ""){
							$spec{address}=[IPV6_ANY, IPV4_ANY];

							#$spec{family}=[AF_INET, AF_INET6];
						}
						else{
							if($spec{address}[0]=~s|^\[|| and
								$spec{address}[0]=~s|\]$||){
								$spec{family}=[AF_INET6];
							}
							else{
								#assume an ipv4 address
								$spec{family}=[AF_INET];
							}
						}

						#$spec{type}=[SOCK_STREAM];

					}
					else {
						#Unix path
						$spec{path}=[$field];
						#$spec{type}=[SOCK_STREAM];
						$spec{family}=[AF_UNIX];
						$spec{interface}=['unix'];
					}
				}
				#goto PUSH;
				next;
			}
			my ($key, $value)=split "=", $field,2;
			$key=~s/ //g;
			$value=~s/ //g;
			my @val;
			#Ensure only 0 or 1 keys match
			die "Ambiguous field name: $key" if 2<=grep /^$key/i, @full;
			($key)=grep /^$key/i, @full;

      # The string to in constant lookup is also done in sockadd_passive in
      # v0.4.0 onwards. The conversion below is to keep compatible with
      # previous version. Also parsing to an actual value is useful outside of
      # use of this module
      # 
			if($key eq "family"){
				#Convert string to integer
				@val=string_to_family($value);
			}
			elsif($key eq "socktype"){
				#Convert string to integer
				@val=string_to_socktype($value);
			}
			elsif($key eq "type"){
				#Convert string to integer
        $key="socktype";      #v0.5.0 type was renamed to socktype.
				@val=string_to_socktype($value);
			}
			else{
				@val=($value);

			}
			
      defined($spec{$key})
              ?  (push $spec{$key}->@*, @val)
              : ($spec{$key}=[@val]);
		}
		PUSH:
		push @output, \%spec;
	}
	@output;
}


sub family_to_string { $af_2_name[$_[0]]; }

sub string_to_family { 
	my ($string)=@_;
	my @found=grep { /$string/i} sort keys %name_2_af;
	@name_2_af{@found}; 
}

sub socktype_to_string { $sock_2_name[$_[0]]; }
# v0.5.0 renamed. Alias to old name
*sock_to_string=\*socktype_to_string;


sub string_to_socktype { 
	my ($string)=@_;
	my @found=grep { /$string/i} sort keys %name_2_sock;
	@name_2_sock{@found};
}
# v0.5.0 renamed. Alias to old name
*string_to_sock=\*string_to_socktype;


sub has_IPv4_interface {
	my $spec={
		family=>AF_INET,
		socktype=>SOCK_STREAM,
		port=>0
	};
	my @results=sockaddr_passive $spec;
	
	@results>=1;

}

sub has_IPv6_interface{
	my $spec={
		family=>AF_INET6,
		socktype=>SOCK_STREAM,
		port=>0
	};
	my @results=sockaddr_passive $spec;
	
	@results>=1;

}

sub _reify_ports {

    my $shared=shift;
    #if any specs contain a 0 for the port number, then perform a bind to get one from the OS.
    #Then close the socket, and hope that no one takes it :)
    
    my $port;
    map {
      if(defined($_->{port}) and $_->{port}==0){
        if($shared and defined $port){
          $_->{port}=$port;
        }
        else{
          #attempt a bind 
          die "Could not create socket to reify port $!" unless CORE::socket(my $sock, $_->{family}, $_->{socktype}, 0);
          die "Could not set reuse address flag $!" unless setsockopt $sock, SOL_SOCKET,SO_REUSEADDR,1;
          die "Could not bind socket to reify port $!" unless bind($sock, $_->{addr});
          my $name=getsockname $sock;

          #my ($err, $a, $port)=getnameinfo($name, NI_NUMERICHOST);
          #my ($err, $a, $port)=
          my $ok=Socket::More::Lookup::getnameinfo($name, my $host="", my $port="", NI_NUMERICHOST);

          if($ok){
            $_->{port}=$port;
          }
          close $sock;
        }
      }
      $_;
    }
    sockaddr_passive @_;
}

sub reify_ports {
    _reify_ports 1, @_;
}

sub reify_ports_unshared {
    _reify_ports 0, @_;
}


1;
__END__

