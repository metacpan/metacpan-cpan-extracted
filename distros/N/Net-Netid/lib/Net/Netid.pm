#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Net::Netid;

use strict;
use 5.001;
use warnings;
use warnings::register;

use attributes qw(reftype);
use File::Spec;
use IO::Socket;

use Proc::Command;
use Data::Str2Num qw(str2int);

#####
# Connect up with the event log.
#
use vars qw( $VERSION $DATE $FILE);
$VERSION = '0.02';
$DATE = '2003/07/27';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA=('Exporter');
@EXPORT_OK = qw(&netid &ipid &net2dot &dot2net &net2num &ip2dot &dot2dec &clean_ip_str
                &clean_netid &clean_ipid &clean_ip2dot);

use SelfLoader;

1

__DATA__

sub netid
{

    unless( $_[0] ) {
       warn( "No input str supplied\n" );
       return undef;
    }
    shift @_ if $_[0] eq 'Net::Netid' || ref($_[0]);  # drop self on object call 

    #########
    # Parse the input arguments into variables
    #
    my ($str, @options) = @_;

    ######
    # Validate the input
    #
    unless( $str ) {
       warn( "No input str supplied\n" );
       return undef;
    }

    #######
    # Pickup any options
    #
    my $options_p;
    if (ref($options[0]) eq 'HASH') {
       $options_p = $options[0];
    }
    else {
       my %options = @options;
       $options_p = \%options;
    }

    my $hash_p = $options_p->{'results'};
    unless( $hash_p && attributes::reftype($hash_p) eq 'HASH' ) {
        my %hash = ();
        $hash_p = \%hash;
    }



    ########
    # Initialize the variables
    #
    my @variables = qw(domain 
                       host        ip_addr_dot 
                       ns_domain   ns_ip_addr_dot
                       mx_domain   mx_ip_addr_dot);

    my $variable;
    foreach $variable (@variables) {
        $hash_p->{$variable} = '';
    }

    #####
    # If the input is a IP dot notation, instead of a
    # domain name, then set the domain name to *
    #
    # Otherswise, use the network name servers to lookup
    # the IP address for that domain.
    #
    my @result = ipid( $str, $options_p->{network} );
    unless( @result ) {
       warn( "No addresses or other ids for $str. Check connection.\n" );
       return undef;
    }
    ($hash_p->{domain}, $hash_p->{host}, $hash_p->{ip_addr_dot}, $hash_p->{ip_addr_network}) = @result;


    ######
    # Find the primary name server and
    # its IP address for a valid domain.
    #
    my ($i, @rec, $rec, $command);
    my $domain_soa = ($hash_p->{domain}) ? $hash_p->{domain} : $hash_p->{host};
    my ($soa_rec, $mx_rec) = ('','');
    if($domain_soa) {

        #######
        # Redirect stderr to the null device
        #
        my $devnull = File::Spec->devnull();
        no warnings;
        open SAVE_ERR, ">&STDERR";
        use warnings;
        open STDERR, ">$devnull";

        my @rec = Proc::Command->command( "nslookup -q=soa $domain_soa", 5);
        if( @rec ) {
            $soa_rec = join '',@rec;
            if( $soa_rec  =~ /.*primary name server = (\S+).*/ ) {
                $hash_p->{ns_domain} = $1; 
                my $ns_ip_network = gethostbyname($hash_p->{ns_domain});
                $hash_p->{ns_ip_addr_dot} = net2dot($ns_ip_network) if ($ns_ip_network);
            }
        }

        @rec = Proc::Command->command( "nslookup -q=mx $domain_soa", 5);
        close STDERR;
        open STDERR, ">&SAVE_ERR";

        if( @rec ) {
            $mx_rec = join '',@rec;
            my (@mx) = $mx_rec =~ /mail exchanger\s*\=\s*(\S+)\s+/ig;
            if( @mx ) {
                $hash_p->{mx_domain} = $mx[0];
                my $mx_ip_network = gethostbyname($hash_p->{mx_domain});
                $hash_p->{mx_ip_addr_dot} = net2dot($mx_ip_network) if $mx_ip_network;

            }
        }
    }


    if( $options_p->{report} ) {

        my ($domain, $host, $ip_addr_dot, $ns_domain, $ns_ip_addr_dot, $mx_domain, $mx_ip_addr_dot);
        foreach $variable (@variables) {
            eval "\$$variable = \$hash_p->{$variable} ? \$hash_p->{$variable} : '*'";
        }

        my $report  = <<"EOF";
\tDomain     : $domain
\tHost       : $host [$ip_addr_dot]
\tName Server: $ns_domain [$ns_ip_addr_dot]
\tMx         : $mx_domain [$mx_ip_addr_dot]
EOF

        if( $options_p->{dns_records} ) {
            $report .= "\n\nName Server Start of Authority Record  for $domain:\n\n$soa_rec"
                if $soa_rec;

            $report .=  "\n\nName Server MX Record for $mx_domain:\n\n$mx_rec" 
                if $mx_rec;
        }
        $hash_p->{netid_report} = $report;
    }

    return $hash_p;
}




######
# Convert a string to the domain and ip address.
#
# This is a high level abstraction of most of the other functions in this package
#
sub ipid
{
    return undef unless(defined($_[0]));
    shift @_ if $_[0] eq 'Net::Netid' || ref($_[0]);  # drop self on object call 
    my ($str, $network) = @_;

    #####
    # If no $str, return empty.
    #
    return undef unless $str;

    ########
    # Establish return variables
    #
    my ($domain, $host, $ip_addr_dot, $ip_addr_network) = ('','','','');

    ########
    # Case where string is a 4 byte big endian 
    # network address.
    #
    if( length($str) == 4 && $network) {
        $ip_addr_network = $str;
        $ip_addr_dot = net2dot($ip_addr_network);
    }
    else {

        ########
        # Case where $str is ip dot notation.
        #
        my $ip_addr_dot_test = ip2dot( $str );
        if( defined($ip_addr_dot_test) ) {
            $ip_addr_dot=$ip_addr_dot_test;
            $ip_addr_network = dot2net($ip_addr_dot);
        }

        else {

            ########
            # Case where $str is a domain name.
            #
            $domain = lc($str);  #lowercase
            my $ip_addr_network_test = gethostbyname($domain);
            if( defined($ip_addr_network_test) && length($ip_addr_network_test) == 4) {
                $ip_addr_network = $ip_addr_network_test;  
                $ip_addr_dot = net2dot($ip_addr_network);
            }
            else {
                return undef;
            }
        }

    }
    ($host) = gethostbyaddr($ip_addr_network, AF_INET) if( $ip_addr_network);
    $host = '' unless $host;
    return ($domain, $host, $ip_addr_dot, $ip_addr_network);

}


######
# Convert an ip string to dot notation
#
sub ip2dot
{

    return undef unless(defined($_[0]));
    shift @_ if $_[0] eq 'Net::Netid' || ref($_[0]);  # drop self on object call 
    my ($ip_addr_str, $network) = @_;
    return undef unless(defined($ip_addr_str));

    my ($a, $b, $c, $d, @num, $i);

    #####
    # If ip_addr is a number,
    # change to the dot notation.
    #
    my $num = str2int( $ip_addr_str );
    if( defined($num) ) {
        return net2dot($num) if($network && (length($num) == 4));
        while($num) {
            unshift @num, $num % 256;
            last if $num < 256;
            $num = $num / 256;
        }
        return undef if 4 < @num;
        while( @num < 4 ) {
            unshift @num,0;
        } 
    }

    elsif($ip_addr_str =~  /^\s*(\w+)\.\s*(\w+)\.\s*(\w+)\.\s*(\w+)$/) {
        @num =  ($1,$2,$3,$4);
        foreach $num (@num) {
            $num = str2int( $num );
            return undef unless(defined $num); 
            return undef if( $num<0 || 255<$num); 
        }
    }

    else {
        return undef;
    }
    return "$num[0].$num[1].$num[2].$num[3]";

}


######
# Convert dot notation to decimal
#
sub dot2dec
{
    return undef unless(defined($_[0]));
    shift @_ if $_[0] eq 'Net::Netid' || ref($_[0]);  # drop self on object call 
    my ($ip) = @_;
    return undef unless defined $ip;

    my @dec = split( /\./, $ip );
    if( 4 < @dec ) {
        warn( "$ip is not a valid IP address\n");
        return undef;
    }

    $ip = 0;
    foreach my $dec (@dec) {
       $ip = (256 * $ip) + $dec;
    }

    ####
    # Some only give the significant bits
    # assuming that the least significant 
    # are zero
    #
    for( my $i=0; $i < (4-@dec); $i++) { 
       $ip = (256 * $ip);
    }
    $ip;

}

#####
# Convert a net packed number to dot notation.
#
sub net2dot
{
    return undef unless $_[0];
    shift @_ if $_[0] eq 'Net::Netid' || ref($_[0]);  # drop self on object call 
    return undef unless $_[0];
    my ($a, $b, $c, $d) = unpack('C4',$_[0]);
    "$a.$b.$c.$d";
}


#####
# Convert dot notation to a net packed number.
#
sub dot2net
{
    return undef unless(defined($_[0]));
    shift @_ if $_[0] eq 'Net::Netid' || ref($_[0]);  # drop self on object call 
    my ($ip_addr_dot) = @_;
    return undef unless(defined($ip_addr_dot)); 
    my ($a, $b, $c, $d) = split(/\./, $ip_addr_dot);
    pack("C4", $a, $b, $c, $d);
}


######
# Converts a long Network Internet Address integer or various variations into
# the dot notation for an Internet Address
#
# This function is particularly obtuse in that spammers take
# particular delight in making any ip address hard to decode.
#
#
sub clean_ip_str
{
    return undef unless(defined($_[0]));
    shift @_ if $_[0] eq 'Net::Netid' || ref($_[0]);  # drop self on object call 
    my ($ip_addr_str) = @_;
    return () unless(defined($ip_addr_str));

    ######
    # Remove any spaces
    #
    $ip_addr_str =~ s/ //g;

    #####
    # Remove beginning and trailing white space.
    #
    ($ip_addr_str) = ($ip_addr_str =~ /^\s*(\S+)\s*$/);

    return undef unless(defined($ip_addr_str));

    ####
    # Convert any %xx web hex escape characters to their
    # ASCII equivalent code. This is popular with spammer's
    # in the belief that it will hide their true identity.
    # 
    $ip_addr_str =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
   
    #######
    # Interesting way to hide IP address is to
    # any characters@domain
    # any characters@IP
    #
    $ip_addr_str = $1 if( $ip_addr_str =~ /^\S+\s*@\s*(\S+)$/ ); 

    #####
    # Parse out any bracket IP dot notation
    #
    $ip_addr_str = $1 if( $ip_addr_str =~ /^\[(\S+)]$/ );
    $ip_addr_str = $1 if ($ip_addr_str =~ /<\s*(\S+)\s*>/);
    return undef unless(defined($ip_addr_str));

    ######
    # Parse any ports.
    #
    my $port = '';
    ($ip_addr_str,$port) = ($1,$2) if( $ip_addr_str =~/(\S+)\s*:\s*(.*?)/ );
    $port = '' unless $port;

    ($ip_addr_str,$port);

}


sub clean_netid 
{  
    shift @_ if $_[0] eq 'Net::Netid' || ref($_[0]);  # drop self on object call 

    #########
    # Parse the input arguments into variables
    #
    my ($str, @options) = @_;
  
    ($str, my $port) = clean_ip_str($str);
    netid( $str, @options);

}


######
# Clean the ip string and convert the string to the domain and ip address.
#
# This is a high level abstraction of most of the other functions in this package
#
sub clean_ipid
{
    shift @_ if $_[0] eq 'Net::Netid' || ref($_[0]);  # drop self on object call 
    my ($str, $network) = @_;

    ($str, my $port) = clean_ip_str($str);
    ipid( $str, $network);

}


######
# Convert an ip string to dot notation
#
sub clean_ip2dot
{

    shift @_ if $_[0] eq 'Net::Netid' || ref($_[0]);  # drop self on object call 
    my ($str, $network) = @_;
    
    ($str, my $port) = clean_ip_str($str);
    ip2dot( clean_ip_str($str, $network) );

}


1;


__END__


=head1 NAME

Net::Netid - obtain basic IP host identfications from Domain Name Servers

=head1 SYNOPSIS

 use Net::Netid qw(netid ipid net2dot dot2net net2num ip2dot clean_ip_str
                   clean_netid clean_ipid clean_ip2dot);

 \%results = Net::Netid->netid($str, \%options)
 \%results = Net::Netid->netid($str,  @options)
 \%results = Net::Netid->netid($str)

 ($domain, $host, $ip_addr_dot, $ip_addr_network) = Net::Netid->ipid($str)
 ($domain, $host, $ip_addr_dot, $ip_addr_network) = Net::Netid->ipid($str, $network)

 $ip_addr_dot = Net::Netid->ip2dot($ip_addr_str)
 $ip_addr_dot = Net::Netid->ip2dot($ip_addr_str, $network)

 $ip_addr_dot = Net::Netid->net2dot($ip_addr_integer)
 $ip_addr_integer = Net::Netid->dot2net($ip_addr_dot)

 ($ip_addr_dot,$port) = Net::Netid->clean_ip_str($ip_addr_str)

 \%results = Net::Netid->clean_netid($str, \%options)
 \%results = Net::Netid->clean_netid($str,  @options)
 \%results = Net::Netid->clean_netid($str)

 ($domain, $host, $ip_addr_dot, $ip_addr_network) = Net::Netid->clean_ipid($str)
 ($domain, $host, $ip_addr_dot, $ip_addr_network) = Net::Netid->clean_ipid($str, $network)

 $ip_addr_dot = Net::Netid->clean_ip2dot($ip_addr_str, $network)

 \%results = netid($str, \%options)
 \%results = netid($str,  @options)
 \%results = netid($str)

 ($domain, $host, $ip_addr_dot, $ip_addr_network) = ipid($str)
 ($domain, $host, $ip_addr_dot, $ip_addr_network) = ipid($str, $network)

 $ip_addr_dot = ip2dot($ip_addr_str)
 $ip_addr_dot = ip2dot($ip_addr_str, $network)

 $ip_addr_dot = net2dot($ip_addr_integer)
 $ip_addr_integer = dot2net($ip_addr_dot)

 ($ip_addr_dot,$port) = clean_ip_str($ip_addr_str)

 \%results = clean_netid($str, \%options)
 \%results = clean_netid($str,  @options)
 \%results = clean_netid($str)

 ($domain, $host, $ip_addr_dot, $ip_addr_network) = clean_ipid($str)
 ($domain, $host, $ip_addr_dot, $ip_addr_network) = clean_ipid($str, $network)

 $ip_addr_dot = clean_ip2dot($ip_addr_str, $network)

=head1 DESCRIPTION

The "Net::Netid" module contains various methods used lookup 
the basic information, domaind name, IP address, name server,
mail box exchanger avaiable for a Internet
host from Internet Domain Name Servers (DNS).

The following may be used either as methods of the "Net::Netid" module or
as stand-alone subroutines imported into the using module:

=head2 netid description

 \%results = netid($str, \%options)
 \%results = netid($str,  @options)
 \%results = netid($str)

The C<netid> method lookups the basic information avaiable for the Internet
host identified by C<$str> on the Internet Domain Name Servers (DNS).

The C<netid> method C<$str> input may be either an Internet address string 
(dot or number notation), domain string or a packed four byte integer.
The intenet address may be either an integer, integer string or a dot notation string.
The C<@options> input may have the following keys: C<qw(report results network)>.

The C<netid> method will use the L<C<ipid>|/ipid description> method to find the 
C<$domain, $host, $ip_addr_dot for $str and $options{network}>.
If $options{network} is present, $str should be a four byte integer.
The C<netid> method will then use the system C<nslookup> and C<$ip_addr_dot>
to find the name server and mail exchanger domain and ip addresses:
C<qw(ns_domain ns_ip_addr_dot mx_domain mx_ip_addr_dot)>

The C<netid> will place these results in the following C<%results> hash keys:

 C<qw(domain host ip_addr_dot ns_domain ns_ip_addr_dot mx_domain  mx_ip_addr_dot)>

The C<\%result> hash reference is either the supplied C<result => \%result> option
or if this option is not present the reference to a hash created by C<netid>.

If the C<report => 1> option is present, the C<netid> method will also format the results
in a report and add it to the %result hash under the key netid_report.

=head2 ipid description

 ($domain, $host, $ip_addr_dot, $ip_addr_network) = ipid($str)
 ($domain, $host, $ip_addr_dot, $ip_addr_network) = ipid($str, $network)

The C<ipid> method lookups a host Internet address and domain name
identified by C<$str> on the Internet Domain Name Servers (DNS).

The C<ipid> method C<$str> input may be either an Internet address string 
(dot or number notation), domain string or a packed four byte integer.
If C<$str> is a packed four byte integer, the second argument, C<$network>,
should be supplied.

The C<netid> method will set either C<$domain $ip_addr_dot or $ip_addr_network>
to C<$str> based on C<netid> determination of C<$str>.
The C<netid> method will then use the Domain Name Servers to fill in the
missing information.

=head2 ip2dot description

 $ip_addr_dot = ip2dot($ip_addr_str)
 $ip_addr_dot = ip2dot($ip_addr_str, $network)

The C<ip2dot> method converts a Internet Address string, C<$ip_addr_str>,
to a Internet Address string in the decimal dot notation.
If the conversion, fails, the C<ip2dot> returns an undef.

The C<ipid> method C<$ip_addr_str> input may be either an Internet address string 
(dot or number notation), or a packed four byte integer.
If C<$ip_addr_str> is a packed four byte integer, the second argument, C<$network>,
should be supplied.

=head2 net2dot description

 $ip_addr_dot = net2dot($ip_addr_integer)

The C<net2dot> method converts a packed four byte network Internet Address
integer, $ip_addr_integer, to a dot notation string, $ip_addr_dot.

=head2 dot2net description

 $ip_addr_integer = dot2net($ip_addr_dot)

The C<dot2net> method converts a dot notation string, $ip_addr_dot
integer, $ip_addr_integer, to a packed four byte network Internet Address.

=head2 clean_ip_str description

 ($ip_addr_dot,$port) = clean_ip_str($str)

The C<clean_ip_str> cleans up string, C<$str>, that identifies
an Internet host.
The method will extract the string from common punctuation such
as surrounding brackets. 
The method will unescape any web C<%XX> hexadecimal escapes
and separate out any port number.

=head2 clean_netid description

 \%results = clean_netid($str, \@options)
 \%results = clean_netid($str,  @options)
 \%results = clean_netid($str)

The C<clean_netid> method will use the L<C<clean_ip_str>|/clean_ip_str description>
on the host identification string, C<$str>, and use the cleaned string to call
L<C<netid>|/netid description>.

=head2 clean_ipid description

 ($domain, $host, $ip_addr_dot, $ip_addr_network) = clean_ipid($str, $network)

The C<clean_netid> method will use the L<C<clean_ip_str>|/clean_ip_str description>
on the host identification string, C<$str>, and use the cleaned string to call
L<C<ipid>|/ipid description>.

=head2 clean_ip2dot description

 $ip_addr_dot = clean_ip2dot($ip_addr_str, $network)

The C<clean_netid> method will use the L<C<clean_ip_str>|/clean_ip_str description>
on the host address string, C<$ip_addr_str>, and use the cleaned string to call
L<C<ip2dot>|/ip2dot description>.

=head1 REQUIREMENTS

Coming soon.

=head1 DEMONSTRATION

 ~~~~~~ Demonstration overview ~~~~~

Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

 =>     use File::Package;
 =>     my $fp = 'File::Package';

 =>     my $nid = 'Net::Netid';
 =>     my $loaded;
 => my $errors = $fp->load_package( $nid)
 => $errors
 ''

 => my $net = Net::Netid->dot2net('240.192.31.14')
 'ðÀ'

 => Net::Netid->net2dot($net)
 '240.192.31.14'

 => Net::Netid->ip2dot('google.com')
 undef

 => Net::Netid->ip2dot('002.010.0344.0266')
 '2.8.228.182'

 => my @result=  Net::Netid->ipid('google.com')
 => $result[1]
 'www.google.com'

 => @result =  Net::Netid->ipid($result[2])
 => $result[1]
 'www.google.com'

 =>     my $hash_p =  Net::Netid->netid('google.com');
 =>     $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;
 => [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]
 [
           'www.google.com',
           'ns1.google.com',
           'smtp.google.com'
         ]

 =>     $hash_p =  Net::Netid->netid($hash_p->{ip_addr_dot});
 =>     $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;
 => [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]
 [
           'www.google.com',
           'ns1.google.com',
           'smtp.google.com'
         ]

 => [my ($ip,$post) = Net::Netid->clean_ip_str(' <234.077.0xff.0b1010>')]
 [
           '234.077.0xff.0b1010',
           ''
         ]

 => [($ip,$post) = Net::Netid->clean_ip_str(' [%32%33%34.077.0xff.0b1010]')]
 [
           '234.077.0xff.0b1010',
           ''
         ]

 => @result=  Net::Netid->clean_ipid('google.com')
 => $result[1]
 'www.google.com'

 => @result =  Net::Netid->clean_ipid($result[2])
 => $result[1]
 'www.google.com'

 =>     $hash_p =  Net::Netid->clean_netid('google.com');
 =>     $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;
 => [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]
 [
           'www.google.com',
           'ns1.google.com',
           ''
         ]

 =>     $hash_p =  Net::Netid->clean_netid($hash_p->{ip_addr_dot});
 =>     $hash_p->{mx_domain} = 'smtp.google.com' if $hash_p->{mx_domain} =~ /smtp\d\.google.com/;
 => [$hash_p->{host},$hash_p->{ns_domain},$hash_p->{mx_domain}]
 [
           'www.google.com',
           'ns1.google.com',
           'smtp.google.com'
         ]

 => Net::Netid->clean_ip2dot('google.com')
 undef

 => Net::Netid->clean_ip2dot('002.010.0344.0266')
 '2.8.228.182'


=head1 QUALITY ASSURANCE

The module "t::Net::Netid" is the Software
Test Description(STD) module for the "Net::Netid".
module. 

To generate all the test output files, 
run the generated test script,
run the demonstration script and include it results in the "Net::Netid" POD,
execute the following in any directory:

 tmake -test_verbose -replace -run  -pm=t::Net::Netid

Note that F<tmake.pl> must be in the execution path C<$ENV{PATH}>
and the "t" directory containing  "t::Net::Netid" on the same level as the "lib" 
directory that contains the "Net::Netid" module.

=head1 NOTES

=head2 AUTHOR

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 BINDING REQUIREMENTS NOTICE

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, 490A (L<STD490A/3.2.3.6>).
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 LICENSE

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http::www.softwarediamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE. 

=head2 SEE_ALSO:

L<Net::Netid|Net::Netid>

=for html
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="COPYRIGHT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut
### end of script  ######