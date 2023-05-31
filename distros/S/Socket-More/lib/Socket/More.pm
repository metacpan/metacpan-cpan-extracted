package Socket::More;

use 5.036000;
use strict;
use warnings;
use Carp;

use Socket ":all";

use List::Util qw<uniq>;
use Exporter "import";

use AutoLoader;

use Net::IP::Lite qw<ip2bin>;
use Data::Cmp qw<cmp_data>;

use Sort::Key::Multi qw<siikeysort>;

#use Scalar::Util qw<looks_like_number>;
use Data::Combination;


##DIRECT COPY FROM Net::IP
##########################
my $ERROR;
my $ERRNO;
# Definition of the Ranges for IPv4 IPs
my %IPv4ranges = (
    '00000000'                         => 'PRIVATE',     # 0/8
    '00001010'                         => 'PRIVATE',     # 10/8
    '0110010001'                       => 'SHARED',      # 100.64/10
    '01111111'                         => 'LOOPBACK',    # 127.0/8
    '1010100111111110'                 => 'LINK-LOCAL',  # 169.254/16
    '101011000001'                     => 'PRIVATE',     # 172.16/12
    '110000000000000000000000'         => 'RESERVED',    # 192.0.0/24
    '110000000000000000000010'         => 'TEST-NET',    # 192.0.2/24
    '110000000101100001100011'         => '6TO4-RELAY',  # 192.88.99.0/24 
    '1100000010101000'                 => 'PRIVATE',     # 192.168/16
    '110001100001001'                  => 'RESERVED',    # 198.18/15
    '110001100011001101100100'         => 'TEST-NET',    # 198.51.100/24
    '110010110000000001110001'         => 'TEST-NET',    # 203.0.113/24
    '1110'                             => 'MULTICAST',   # 224/4
    '1111'                             => 'RESERVED',    # 240/4
    '11111111111111111111111111111111' => 'BROADCAST',   # 255.255.255.255/32
);
 
# Definition of the Ranges for Ipv6 IPs
my %IPv6ranges = (
    '00000000'                                      => 'RESERVED',                  # ::/8
    ('0' x 128)                                     => 'UNSPECIFIED',               # ::/128
    ('0' x 127) . '1'                               => 'LOOPBACK',                  # ::1/128
    ('0' x  80) . ('1' x 16)                        => 'IPV4MAP',                   # ::FFFF:0:0/96
    '00000001'                                      => 'RESERVED',                  # 0100::/8
    '0000000100000000' . ('0' x 48)                 => 'DISCARD',                   # 0100::/64
    '0000001'                                       => 'RESERVED',                  # 0200::/7
    '000001'                                        => 'RESERVED',                  # 0400::/6
    '00001'                                         => 'RESERVED',                  # 0800::/5
    '0001'                                          => 'RESERVED',                  # 1000::/4
    '001'                                           => 'GLOBAL-UNICAST',            # 2000::/3
    '0010000000000001' . ('0' x 16)                 => 'TEREDO',                    # 2001::/32
    '00100000000000010000000000000010' . ('0' x 16) => 'BMWG',                      # 2001:0002::/48            
    '00100000000000010000110110111000'              => 'DOCUMENTATION',             # 2001:DB8::/32
    '0010000000000001000000000001'                  => 'ORCHID',                    # 2001:10::/28
    '0010000000000010'                              => '6TO4',                      # 2002::/16
    '010'                                           => 'RESERVED',                  # 4000::/3
    '011'                                           => 'RESERVED',                  # 6000::/3
    '100'                                           => 'RESERVED',                  # 8000::/3
    '101'                                           => 'RESERVED',                  # A000::/3
    '110'                                           => 'RESERVED',                  # C000::/3
    '1110'                                          => 'RESERVED',                  # E000::/4
    '11110'                                         => 'RESERVED',                  # F000::/5
    '111110'                                        => 'RESERVED',                  # F800::/6
    '1111110'                                       => 'UNIQUE-LOCAL-UNICAST',      # FC00::/7
    '111111100'                                     => 'RESERVED',                  # FE00::/9
    '1111111010'                                    => 'LINK-LOCAL-UNICAST',        # FE80::/10
    '1111111011'                                    => 'RESERVED',                  # FEC0::/10
    '11111111'                                      => 'MULTICAST',                 # FF00::/8
);

#------------------------------------------------------------------------------
# Subroutine ip_iptypev4
# Purpose           : Return the type of an IP (Public, Private, Reserved)
# Params            : IP to test, IP version
# Returns           : type or undef (invalid)
sub ip_iptypev4 {
    my ($ip) = @_;
    no warnings "uninitialized";
 
    # check ip
    if ($ip !~ m/^[01]{1,32}$/) {
        $ERROR = "$ip is not a binary IPv4 address $ip";
        $ERRNO = 180;
        return;
    }
     
    # see if IP is listed
    foreach (sort { length($b) <=> length($a) } keys %IPv4ranges) {
        return ($IPv4ranges{$_}) if ($ip =~ m/^$_/);
    }
 
    # not listed means IP is public
    return 'PUBLIC';
}
 
#------------------------------------------------------------------------------
# Subroutine ip_iptypev6
# Purpose           : Return the type of an IP (Public, Private, Reserved)
# Params            : IP to test, IP version
# Returns           : type or undef (invalid)
sub ip_iptypev6 {
    my ($ip) = @_;
    no warnings "uninitialized";

    # check ip
    if ($ip !~ m/^[01]{1,128}$/) {
        $ERROR = "$ip is not a binary IPv6 address";
        $ERRNO = 180;
        return;
    }
     
    foreach (sort { length($b) <=> length($a) } keys %IPv6ranges) {
        return ($IPv6ranges{$_}) if ($ip =~ m/^$_/);
    }
 
    # How did we get here? All IPv6 addresses should match 
    $ERROR = "Cannot determine type for $ip";
    $ERRNO = 180;
    return;
}

#######
#END COPY FROM Net::IP

my @af_2_name;
my %name_2_af;
my @sock_2_name;
my %name_2_sock;
my $IPV4_ANY="0.0.0.0";
my $IPV6_ANY="::";

BEGIN{
	#build a list of address family names from socket
	my @names=grep /^AF_/, keys %Socket::;
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


	@names=grep /^SOCK_/, keys %Socket::;

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



our %EXPORT_TAGS = ( 'all' => [ qw(
	getifaddrs
	sockaddr_passive
	socket
	family_to_string
	string_to_family
	sock_to_string
	string_to_sock
	parse_passive_spec
	unpack_sockaddr
	if_nametoindex
	if_indextoname
	if_nameindex
	has_IPv4_interface
	has_IPv6_interface
  reify_ports
  reify_ports_unshared

) ] );

our @EXPORT_OK = ( @{$EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

	
);

our $VERSION = 'v0.4.2';

sub getifaddrs;
sub string_to_family;
sub string_to_sock;
sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Socket::More::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Socket::More', $VERSION);

#Socket stuff

#Basic wrapper around CORE::socket.
#If it looks like an number: Use core perl
#Otherwise, extract socket family from assumed sockaddr and then call core

sub socket {

	require Scalar::Util;
	#qw<looks_like_number>;
	return &CORE::socket if Scalar::Util::looks_like_number $_[1];

	if(ref($_[1]) eq "HASH"){
		#assume a 'interface object no need for remaining args
		return CORE::socket $_[0], $_[1]{family}, $_[1]{type}, $_[1]{protocol};
	}
	else {
		#Assume a packed string
		my $domain=sockaddr_family($_[1]);
		return CORE::socket $_[0], $domain, $_[2], $_[3];
	}
}

#Network interface stuff
#=======================
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


#main routine to return passive address structures
sub sockaddr_passive{
	require Scalar::Util;
	my ($spec)=@_;
	my $r={};
	#my $sort_order=$spec->{sort}//$_default_sort_order;
	#If no interface provided assume all
	$r->{interface}=$spec->{interface}//".*";
	
        ##############################################
        # if(ref($r->{interface}) ne "ARRAY"){       #
        #         $r->{interface}=[$r->{interface}]; #
        # }                                          #
        ##############################################

	$r->{type}=$spec->{type}//[SOCK_STREAM, SOCK_DGRAM];
	$r->{protocol}=$spec->{protocol}//0;

	#If no family provided assume all
	$r->{family}=$spec->{family}//[AF_INET, AF_INET6, AF_UNIX];	
	
	#Configure port and path
	$r->{port}=$spec->{port}//[];
	$r->{path}=$spec->{path}//[];
	
  ######
  #v0.4.0 adds string support for type and family
  
  # Convert to arrays for unified interface 
  for($r->{type}, $r->{family}){
    unless(ref eq "ARRAY"){
      $_=[$_];
    }
  }

  for($r->{type}->@*){
    unless(Scalar::Util::looks_like_number $_){
      ($_)=string_to_sock $_;
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
		$r->{port}=[undef, $r->{port}];#AF_INET, AF_INET6, AF_UNIX];
	}


	if(ref($r->{path}) eq "ARRAY"){
		unshift $r->{path}->@*, undef;
	}
	else {
		$r->{path}=[undef, $r->{path}];#AF_INET, AF_INET6, AF_UNIX];
	}

	carp "No port number specified, no address information will be returned" if ($r->{port}->@*==0) or ($r->{path}->@*==0);

	#Delete from combination specification... no need to make more combos
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
	my @new_spec_int;
	my @new_fam;

	if(grep /$IPV4_ANY/, @$address){
		#$r->{interface}=[$IPV4_ANY];
		push @new_spec_int, $IPV4_ANY;
		#@$address=($IPV4_ANY);
		push @new_address, $IPV4_ANY;
		push @new_fam, AF_INET;
		push @new_interfaces, ({name=>$IPV4_ANY,addr=>pack_sockaddr_in 0, inet_pton AF_INET, $IPV4_ANY});
	}

	if(grep /$IPV6_ANY/, @$address){
		#$r->{interface}=[$IPV6_ANY];
		push @new_spec_int, $IPV6_ANY;
		#@$address=($IPV6_ANY);
		push @new_address, $IPV6_ANY;
		push @new_fam, AF_INET6;
		push @new_interfaces, ({name=>$IPV6_ANY, addr=>pack_sockaddr_in6 0, inet_pton AF_INET6, $IPV6_ANY});
	}

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
			my ($err,$res, $service);


			#Port or path needs to be set
			if($fam == AF_INET){
				my (undef, $ip)=unpack_sockaddr_in($interface->{addr});
				$clone->{addr}=pack_sockaddr_in($_->{port},$ip);
				$clone->{address}=inet_ntop($fam, $ip);
				#$interface->{port}=$_->{port};
				$clone->{interface}=$interface->{name};
				#$clone->{group}=Net::IP::XS::ip_iptypev4(Net::IP::XS->new($clone->{address})->binip);
				$clone->{group}=ip_iptypev4 ip2bin($clone->{address});
				#$clone->{group}=Net::IP->new($clone->{address})->iptype;
			}
			elsif($fam == AF_INET6){
				my(undef, $ip, $scope, $flow_info)=unpack_sockaddr_in6($interface->{addr});
				$clone->{addr}=pack_sockaddr_in6($_->{port},$ip, $scope,$flow_info);
				$clone->{address}=inet_ntop($fam, $ip);
				$clone->{interface}=$interface->{name};
				#$clone->{group}=Net::IP::XS::ip_iptypev6(Net::IP::XS->new($clone->{address})->binip);
				
				$clone->{group}=ip_iptypev6 ip2bin($clone->{address});

				#$clone->{group}=Net::IP->new($clone->{address})->iptype;
			}
			elsif($fam == AF_UNIX){
				my $suffix=$_->{type}==SOCK_STREAM?"_S":"_D";

				$clone->{addr}=pack_sockaddr_un $_->{path}.$suffix;
				my $path=unpack_sockaddr_un($clone->{addr});			
				$clone->{address}=$path;
				$clone->{path}=$path;
				$clone->{interface}=$interface->{name};
				$clone->{group}="UNIX";
			}
			else {
				die "Unsupported family type";
				last;
			}
			#$clone->{interface}=$interface->{name};

			#Final filtering of address and group
			next unless grep {$clone->{address}=~ /$_/i } @$address;
			
			next  unless grep {$clone->{group}=~ /$_/i } @$group;

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
		#my $found=List::Util::first {eq_deeply $_, $out} @list;
                my $found=List::Util::first {cmp_data($_, $out)==0} @list;
                push @list, $out unless $found;
        }

	
	@output=@list;
	@output=siikeysort {$_->{interface}, $_->{family}, $_->{type}} @output;
}

#Parser for CLI  -l options
sub parse_passive_spec {
	#splits a string by : and tests each set
	my @output;
	my @full=qw<interface type protocol family port path address group data>;
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
							$spec{address}=[$IPV6_ANY, $IPV4_ANY];

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
			elsif($key eq "type"){
				#Convert string to integer
				@val=string_to_sock($value);
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

sub sock_to_string { $sock_2_name[$_[0]]; }


sub string_to_sock { 
	my ($string)=@_;
	my @found=grep { /$string/i} sort keys %name_2_sock;
	@name_2_sock{@found};
}

sub has_IPv4_interface {
	my $spec={
		family=>AF_INET,
		type=>SOCK_STREAM,
		port=>0
	};
	my @results=sockaddr_passive $spec;
	
	@results>=1;

}

sub has_IPv6_interface{
	my $spec={
		family=>AF_INET6,
		type=>SOCK_STREAM,
		port=>0
	};
	my @results=sockaddr_passive $spec;
	
	@results>=1;

}

sub _reify_ports {

    my $shared=shift;
    #if any specs contain a 0 for the port number, then perform a bind to get one from the OS.
    #Then close the socket, an hope that no one takes it :)
    
    my $port;
    map {
      if(defined($_->{port}) and $_->{port}==0){
        if($shared and defined $port){
          $_->{port}=$port;
        }
        else{
          #attempt a bind 
          die "Could not create socket to reify port" unless CORE::socket(my $sock, $_->{family}, $_->{type}, 0);
          die "Could not set reuse address flag" unless setsockopt $sock, SOL_SOCKET,SO_REUSEADDR,1;
          die "Could not bind socket to reify port" unless bind($sock, $_->{addr});
          my $name=getsockname $sock;

          my ($err, $a, $port)=getnameinfo($name, NI_NUMERICHOST);

          unless($err){
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

sub sockaddr_valid {
	#Determin if the sock address is still a valid passive address
}

sub monitor {

}

1;
__END__

