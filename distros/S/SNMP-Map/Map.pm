=head1 NAME

SNMP::Map - Tool for drawing network map

=head1 SYNOPSIS
 
 my $map = new SNMP::Map;
 $map->get_data(username=> 'user',
               password =>'pass',
               ipv3 => ['10.8.255.238','10.8.255.239','10.8.255.244','10.8.255.248'],
               vlan=>'vlan-224'
 );
 $map->get_output(file => 'map.jpg');

=head1 DESCRIPTION

The SNMP::Map module is used for drawing network map of hosts which support SNMP.
Spanning Tree root switch can be distinguished by its position and color. Module provides
switches and ports on the picture linked by each other.You can get various information 
about switch and its link. Image map file is also available. So, it can be used to create
javascript for popuping additional info.

=head1 METHODS

=head2 new

This is the constructor. It does not accept any attributes.

 my $map = new SNMP::Map;

=head2 get_data

C<get_data> method gets data from switches using SNMP protocol. It starts from the spanning tree root switch,
and makes recursive calls to all switches linked to root. By default, it uses SNMP v3, but for switches
listed in ipv2 array reference,it uses SNMP v2. If a failure occurs, method returns underfined value,
you can use 'error' method to get error. At least, one ip adress must be specified by B<ipv2> or B<ipv3> attribute.
It is recommended to get more info,  list all switches by B<ipv2> and B<ipv3> attributes. It was tested on
'WS-C2950','WS-C2960','WS-3750' platforms. 'WS-C2950' switches must be listed in B<ipv2>.


Attributes:

=over

=item username

username for SNMP v3.

=item password

password for SNMP v3.

=item community

community for SNMP v2.

=item timeout

timeout for SNMP.

=item ipv3

array reference consist of list of hosts which is supported SNMP v3.

=item ipv2

array reference consist of list of hosts which is supported SNMP v2.

=item debug

switch on/off debug.can be true or false. Debug information is printed to STDERR.

=item vlan

vlan to draw map.

=back


 $map->get_data(username=>'user',
                community=>'comm',
                password=>'pass',
                ipv3=>['10.8.255.115','10.8.255.118','10.8.255.119','10.8.255.111'],
                ipv2=>['10.8.255.145','10.8.255.133','10.8.255.151','10.8.255.149'],
                vlan => 'vlan-192');

=head2 get_output

This method is used for saving image into file. Also you can get an image map file.
A color value used in attributes of the method may be "h,s,v" (hue, saturation, brightness)
floating point numbers between 0 and 1, or an X11 color name such as 'white', 'black',
'red', 'green', 'blue', 'yellow', 'magenta', 'cyan', or 'burlywood'.

Attributes:

=over

=item root_color

sets the outline color for Spanning Tree root switch, and the default fill color if 
the 'style' is 'filled' and 'fillcolor' is not specified.

=item root_fillcolor

sets the fill color for Spanning Tree root switch when the style is 'filled'. If not 
specified, the 'fillcolor' when the 'style' is 'filled' defaults to be the same as the 
outline color.

=item root_fontcolor

sets the label text color for Spanning Tree root switch.

=item color

sets the outline color for hosts and the default fill color if the 'style' is 'filled' 
and 'fillcolor' is not specified.

=item fillcolor

sets the fill color for hosts when the style is 'filled'. If not specified, the 'fillcolor'
when the 'style' is 'filled' defaults to be the same as the outline color.

=item fontcolor

sets the label text color for hosts.

=item shapes

sets hash reference for the host`s shape, the key - regexp for the device platform, value - shape.
shape could be: 'record', 'plaintext', 'ellipse', 'circle', 'egg', 'triangle', 'box', 'diamond',
'trapezium', 'parallelogram', 'house', 'hexagon', 'octagon'. B<unknown> key is for hosts for which 
platform is unknown.

=item edges_colors

sets array reference for colors of the links between hosts. First element of array reference
is the color for the unknown state of link. Last element is the color for link in blocking state.
2-7 elements - colors for hosts depending of its cost. Formula to correspond link color and its
cost -  C<log(1/cost)*100> .

=item file

file to output image.

=item format

format of image file. Could be: 'ps','hpgl','pcl','mif','pic','gd','gd2','gif','jpg','png','wbmp',
'vrml','vtx,'mp','fig','svg','svgz','plain'.

=item layout

The B<layout> attribute determines which layout algorithm GraphViz.pm will use. Possible values are:
'dot','neato','twopi','circo','fdp'. 'dot' and 'circo' are recommended.

=item bgcolor

background color of image.

=item height, width

minimal height/width of image in inches.

=item fontsize

host`s label font size.

=item style

host`s style. Could be: 'filled', 'solid', 'dashed', 'dotted', 'bold', 'invis'.

=item edge_style

style of link. Could be: 'filled', 'solid', 'dashed', 'dotted', 'bold', 'invis'.

=item cmap,imap

file to output client-side/server-side image file. B<href> parameter in the html tags 
is the ip adress for hosts and number for links. You can change it to B<nohref> and use
'nodes_info' and 'edge_info' methods to create javascript pop up.

=back

 $map->get_output(file=>'../map.jpg',
                 root_fillcolor=>'blue',
                 root_fontcolor=>'cyan',
                 fontcolor=>'red',
                 color=>'green',
                 shapes => {unknown => 'record','IP Phone' =>'ellipse'},
                 edges_colors=>['blue','0,0,0.9','0,0,0.8','0,0,0.7','0,0.5,0.6','0,0,0.5','0,0,0.4','red'],
                 height=>5,
                 width=>9,
                 edge_style=>'dashed',
                 cmap=>'map'
);

=head2 error

return last error message.

=head2 nodes_info

returns hash reference with information about host.To use this method you must call 'get_data'
method first. Keys of the hash reference are the ip address of the hosts.The following 
information could be obtained:

 $info = $map->nodes_info();
 print $info->{10.8.255.101}{deviceID};
 print $info->{10.8.255.101}{priority};
 print $info->{10.8.255.101}{mac};
 print $info->{10.8.255.101}{platform};
 print $info->{10.8.255.101}{interfaces}{Gi0/1}{cost}; #cost for Gi0/1 port
 print $info->{10.8.255.101}{interfaces}{Gi0/1}{cost}; #state for Gi0/1 port

=head2 edge_info

take the number of the link as first parameter. To use this method you must call 'get_data'
method first.Number correspond to B<href> parameter of the image map file of link. The 
following information could be obtained:

 $info = $map->edge_info(5);
 print $info->{from_ip};
 print $info->{from_interface}; #name of the port
 print $info->{from_virtual}; #name of the virtual port
 print $info->{to_ip};
 print $info->{to_interface}; #name of the port
 print $info->{to_virtual}; #name of the virtual port


=head1 NOTES

Module was tested on 'WS-C2950','WS-C2960','WS-3750' platforms. B<ipv2> option in 'get_data' 
method is used for WS-C2950.

=head1 AUTHOR

Krol Alexander <kasha@bigmir.net>

=head1 LICENSE

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut


package SNMP::Map;
use strict;
use warnings;
use Net::SNMP;
use GraphViz;

our $VERSION = '1.01';

my $ID1='1.3.6.1.2.1.17.2.5.0'; #to get RootID(priority and Mac Adress)
my $ID2='1.3.6.1.2.1.2.2.1.6'; #to get STP Mac ID 2 IP
my $ID3='1.3.6.1.2.1.17.1.1.0'; #to get MAC for switch
my $ID4='1.3.6.1.2.1.17.2.2.0'; #to get priority for switch
my $ID5='1.3.6.1.2.1.17.2.15.1.3'; #port`s state
my $ID6='1.3.6.1.2.1.17.2.15.1.5'; #port`s cost
my $ID7='1.3.6.1.2.1.17.1.4.1.2'; #index correspondence
my $ID8='1.3.6.1.2.1.2.2.1.2'; #to get interfaces
my $ID9='1.3.6.1.2.1.2.2.1.1'; #to get port`s indexes
my $ID10='1.3.6.1.4.1.9.9.46.1.6.1.1.14'; #to get port`s status
my $ID11='1.3.6.1.4.1.9.9.23.1.2.1.1.6'; #to get DeviceID
my $ID12='1.3.6.1.4.1.9.9.23.1.2.1.1.7'; #to which port device is connected
my $ID13='1.3.6.1.4.1.9.9.23.1.2.1.1.4'; #to which ip device is connected
my $ID14='1.3.6.1.4.1.9.9.23.1.2.1.1.8'; #to get DevicePlatfrom
my $ID15='1.3.6.1.2.1.4.20.1.1'; #to get aliases
my $ID16='1.3.6.1.4.1.9.9.98.1.1.1.1.8'; #to get link between port index and virtual port index
my $ID17='1.3.6.1.4.1.9.9.98.1.1.1.1.1'; #to get phys link state
my $ID18='1.3.6.1.2.1.2.2.1.3'; #to get virtual link state


sub new
{
    my $invocant= shift;
    my $class = $invocant;
    my $data={};
    return bless $data,$class;
}

sub get_data
{
    my $self = shift;
    my (@sessions,$ip,$RootMac,%options);

    %options = (@_);
 
    $self->{result} = {};
    $self->{mac2ip} = {};
    $self->{aliases} = {};
    $self->{correspondence} = {};
    $self->{index} = {};
    $self->{labels} = {};
    $self->{draw2} = [];
    $self->{info_edge} = [];
    $self->{info_node} = {};
    $self->{virtual} = {};
    $self->{platforms} = {};
    $self->{checked} = [];
    $self->{shapes} = {};
    $self->{GOT} = 0;    

    $self->{USER} = $options{username};
    $self->{PASS} = $options{password};
    $self->{COMMUNITY} = $options{community};
    $self->{TIMEOUT} = $options{timeout} || 1;
    $self->{IP_CONF} = $options{ipv3} || [];
    $self->{IPV2_CONF} = $options{ipv2} || [];
    $self->{DEBUG} = $options{debug};
    $self->{VLAN} = $options{vlan} || die "Vlan must be specified\n";




    $self->getaliases();
    $RootMac = $self->getrootid();
    unless (defined($RootMac))
    {
	$self->{error} = 'Unable to determinate root mac for spanning tree';
	return undef;
    }
    map{push(@sessions,$self->getmac2ip($_))} (@{$self->{IP_CONF}},@{$self->{IPV2_CONF}}); 
    snmp_dispatcher();
    map{$_->close()}@sessions;


    $self->{root_ip} = $ip = $self->{mac2ip}{$RootMac};
    
    unless (defined($ip))
    {
	$self->{error} = 'Unable to determinate root ip for spanning tree';
	return undef;
    }
    my $version= grep($ip eq $_,@{$self->{IPV2_CONF}})? 'v2':'v3';
    $self->{result}{$ip} = {};
    $self->{checked}[0]=$ip;
    $self->getdata($self->{result}{$ip},$ip,$version);
    $self->getdeviceplatform($self->{result},$ip);
    $self->{GOT} = 1;
    return 1;
}
sub error
{
    my $self = shift;
    return $self->{error};
}
sub get_output
{
    my $self = shift;
    my $ip = $self->{root_ip};
    my %options = (@_);
    die "No data to output" unless($self->{GOT});

    $self->{root_color} = $options{root_color} || '0.85,0.58,0.8';
    $self->{color} = $options{color} || '0.54,0.34,0.67';
    $self->{root_fillcolor} = $options{root_fillcolor} || '0.70,0.70,0.90';
    $self->{fillcolor} = $options{fillcolor} || '0.72,0.96,0.17';
    $self->{root_fontcolor} = $options{root_fontcolor} || '0.85,0.58,0.8';
    $self->{fontcolor} = $options{fontcolor} || '0.54,0.34,0.67';


    $self->{shapes} = $options{shapes} || {unknown => 'ellipse','IP Phone' => 'diamond'};
    $self->{edges_colors} = $options{edges_colors} || ['0.4,0.3,0.8','0,0,0.9','0,0,0.8','0,0,0.6','0,0,0.4','0,0,0.2',
						       '0,0,0','1,1,1'];

    my $file = $options{file};
    my $format = $options{format} || 'jpg';

    $options{layout} ||= 'dot';
    $options{bgcolor} ||= 'white';
    $options{height} ||= 5;
    $options{width} ||= 5;
    $options{style} ||= 'filled';
    $options{fontsize} ||= 10;
    $options{edge_style} ||= 'filled';

    my $picture = GraphViz->new(directed=>0,layout=>$options{layout},rankdir=>$options{rankdir},
				bgcolor=>$options{bgcolor},height=>$options{height},width=>$options{width},
				overlap=>'false',name=>'map',node=>{style=>$options{style},fontsize=>$options{fontsize},
			        fontname=>$options{fontname}},edge=>{style=>$options{edge_style}});
    $self->output_nodes($self->{result},$picture,$ip);
    $self->output_edges($self->{result},$ip);
    $self->printedges($picture);


    
    if ($format eq 'ps'){$picture->as_ps($file);}
    elsif ($format eq 'hpgl') {$picture->as_hpgl($file);}
    elsif ($format eq 'pcl') {$picture->as_pcl($file);}
    elsif ($format eq 'mif') {$picture->as_mif($file);}
    elsif ($format eq 'pic') {$picture->as_pic($file);}
    elsif ($format eq 'gd') {$picture->as_gd($file);}
    elsif ($format eq 'gd2') {$picture->as_gd2($file);}
    elsif ($format eq 'gif') {$picture->as_gif($file);}
    elsif ($format eq 'jpg') {$picture->as_jpeg($file);}
    elsif ($format eq 'png') {$picture->as_png($file);}
    elsif ($format eq 'wbmp') {$picture->as_wbmp($file);}
    elsif ($format eq 'vrml') {$picture->as_vrml($file);}
    elsif ($format eq 'vtx') {$picture->as_vtx($file);}
    elsif ($format eq 'mp') {$picture->as_mp($file);}
    elsif ($format eq 'fig') {$picture->as_fig($file);}
    elsif ($format eq 'svg') {$picture->as_svg($file);}
    elsif ($format eq 'svgz') {$picture->as_svgz($file);}
    elsif ($format eq 'plain') {$picture->as_plain($file);}
    else {die "Unknown format - $format for get_output \n";}
    
    $picture->as_cmapx($options{cmap}) if (defined($options{cmap}));
    $picture->as_ismap($options{imap}) if (defined($options{imap}));
}

sub getdeviceplatform
{
    my ($self,$result,$root_ip)= @_;
    my $platforms = $self->{platforms};
    my ($ipt,$DevicePlatform);
    local $_;

  
  
    foreach (keys %{$result->{$root_ip}{devices}})
    {
	($ipt) = grep(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/,keys %{$result->{$root_ip}{devices}{$_}});
	$platforms->{$ipt} = $result->{$root_ip}{devices}{$_}{platform};
	next unless (keys %{$result->{$root_ip}{devices}{$_}{$ipt}{devices}});
	$self->getdeviceplatform($result->{$root_ip}{devices}{$_},$ipt);
    }
}

sub getdeviceid
{
    my ($self,$result,$root_ip,$ip)= @_;
    my ($ipt,$DeviceID);
    local $_;

  
  
    foreach (keys %{$result->{$root_ip}{devices}})
    {
	($ipt) = grep(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/,keys %{$result->{$root_ip}{devices}{$_}});
	return $result->{$root_ip}{devices}{$_}{DeviceID} if ($ip eq $ipt);
	next unless (keys %{$result->{$root_ip}{devices}{$_}{$ipt}{devices}});
	$DeviceID = $self->getdeviceid($result->{$root_ip}{devices}{$_},$ipt,$ip);
	return $DeviceID if (defined($DeviceID));
    }
    return undef;
}

sub getaliases
{
    my ($self) = shift;
    my ($aliases,$virtual) = ($self->{aliases},$self->{virtual});
    my ($session,$error,$ip,$status,@sessions);
    my $VirtState={};
    my @ips = (@{$self->{IP_CONF}},@{$self->{IPV2_CONF}});
    foreach $ip (@ips)
    {
	($session,$error)= Net::SNMP->session(    -hostname       => $ip,
						  -version        => 'snmpv3',
						  -timeout        => $self->{TIMEOUT},
						  -username       => $self->{USER},
						  -authpassword   => $self->{PASS},
						  -nonblocking    => 1,
						  -maxmsgsize     => 65535);

	die "Error while creating SNMP object:$error\n" if (!defined($session));
	
	$status = $session->get_table(-baseoid      => $ID15,
			              -callback     => [\&push2aliases,$self]);

	$self->debug("Error while sending a SNMP get-request $ID15:",$session->error()) if (!defined($status));

	$status = $session->get_table(-baseoid      => $ID16,
			              -callback     => [\&pushphyslink2virtlink,$self]);
	
	$self->debug("Error while sending a SNMP get-request $ID16:",$session->error()) if (!defined($status));
	
	$status = $session->get_table(-baseoid      => $ID17,
				      -callback     => [\&pushphyslinkstate,$self]);
	
	$self->debug("Error while sending a SNMP get-request $ID17:",$session->error()) if (!defined($status));

	$status = $session->get_table(-baseoid      => $ID18,
				      -callback     => [\&pushvirtlinkstate,$self,$VirtState]);
	
	$self->debug("Error while sending a SNMP get-request $ID18:",$session->error()) if (!defined($status));

	push(@sessions,$session);
    }
    snmp_dispatcher();
    map($_->close(),@sessions);

    foreach  $ip (@ips)
    {
	while (my ($key,$val) = each %{$virtual->{$ip}})
	{
	    delete $virtual->{$ip}{$key} if ($val == -1 or !defined($VirtState->{$ip}{$val}));
	}
    }

}
sub pushvirtlinkstate
{
    my ($session,$self,$VirtState) = @_;
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    local $_;

    
    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID18:\t ".$session->hostname.':'.$session->error());
	return;
    }
    
    while (my ($key,$val) = each %$lists)
    {
	$VirtState->{$ip}{substr($key,20)} = $val if ($val == 53);
    }
}
sub pushphyslinkstate
{
    my ($session,$self) = @_;
    my $virtual = $self->{virtual};
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    local $_;
    my $index;
    
    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID17:\t ".$session->hostname.':'.$session->error());
	return;
    }
    
    while (my ($key,$val) = each %$lists)
    {
	$index = substr($key,29);
	$virtual->{$ip}{$index} = -1 if ($val == 1);
    }
}
sub pushphyslink2virtlink
{
    my ($session,$self) = @_;
    my $virtual = $self->{virtual};
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    local $_;
    my $index;
    
    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID16:\t ".$session->hostname.':'.$session->error());
	return;
    }
    
    while (my ($key,$val) = each %$lists)
    {
	$index = substr($key,29);
	no warnings;
	$virtual->{$ip}{$index} = $val if ($index ne $val and $val and $virtual->{$ip}{$index} != -1);
	use warnings;
    }
    
}
sub push2aliases
{
    my ($session,$self) = @_;
    my $aliases = $self->{aliases};
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    local $_;

    
    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID15:\t ".$session->hostname.':'.$session->error());
	return;
    }
    
    foreach (values %$lists)
    {
	$aliases->{$_} = $ip if ($_ ne $ip);
    }
    
}
sub getrootid
{
    my ($self) = shift;
    my ($session,$error,$ip,$lists,%settings,$version,$vlan_v2);
    my @ips = (@{$self->{IP_CONF}},@{$self->{IPV2_CONF}});
    $vlan_v2 = $self->{VLAN};
    $vlan_v2 =~ s/vlan-(\d+)/$1/;
    
    
    
    foreach $ip (@ips)
    {
	$version = grep($_ eq $ip,@{$self->{IPV2_CONF2}})? 'v2':'v3';
	if ($version eq 'v3')
	{
	    %settings = (	-hostname       => $ip,
				-version        => 'snmpv3',
				-timeout        => $self->{TIMEOUT},
				-username       => $self->{USER},
				-authpassword   => $self->{PASS},
				-maxmsgsize     => 65535);
	}
	else
	{
	    %settings = (	-hostname       => $ip,
				-version        => 'snmpv2',
				-community      => $self->{COMMUNITY}.'@'.$vlan_v2,
				-timeout        => $self->{TIMEOUT},
				-maxmsgsize     => 65535);
	}
	
	($session,$error) = Net::SNMP->session(%settings);
	die "Error while creating SNMP object:$error\n" if (!defined($session));
	
	if ($version eq 'v3')
	{
	    $lists= $session->get_request(
		-varbindlist     => [$ID1],
		-contextname     => $self->{VLAN},
		);
	}
	else 
	{
	    $lists= $session->get_request(
		-varbindlist     => [$ID1],
		);
	}
	

	if (!defined($lists))
	{
	    $self->debug("Error while sending a SNMP get-request $ID1:",$session->error());
	    $session->close();
	    last;
	}

	if (substr($lists->{$ID1},0,14) ne 'noSuchInstance')
	{
	    use bigint;
	    no warnings;
	    my $RootMac = hex(substr($lists->{$ID1},6));
	    no bigint;
	    use warnings;
	    $session->close();
	    return $RootMac;
	}
	$session->close();
    }
    return undef;
	    
}


sub getmac2ip
{
    my ($self,$ip) = @_;

    my ($session,$error,$status);
    
    ($session,$error) = Net::SNMP->session(
	    -hostname       => $ip,
	    -version        => 'snmpv3',
	    -timeout        => $self->{TIMEOUT},
	    -username       => $self->{USER},
	    -authpassword   => $self->{PASS},
	    -nonblocking    => 1,
	    -maxmsgsize     => 65535,
	);

    
    die "Error while creating SNMP object:$error\n" if (!defined($session));
        
    
    $status= $session->get_table(
	-baseoid       => $ID2,
	-callback      => [\&push2mac2ip,$self],
	);
    $self->debug("Error while sending a SNMP get-request $ID2:",$session->error()) if (!defined($status));
    return $session;
}

sub push2mac2ip
{
       my ($session,$self) = @_;
       my $mac2ip = $self->{mac2ip};
       my ($min,@ar,$binmin);
       my $ip = $session->hostname;
       my $lists = $session->var_bind_list;
       local $_;
       

       if (!defined($lists))
       {
	   $self->debug( "Error while sending a SNMP get-request for $ID2:$ip ".$session->error());
	   return;
       }
       
       @ar= sort { $a cmp $b } values %$lists;

       foreach (@ar)
       {

	   if (length == 14)
	   {
	       $min = $_;
	       last;
	   }
	       
       }
       no warnings;
       use bigint;
       my $dec = hex($min);
       $dec = $dec % 2? $dec-1:$dec;
       $mac2ip->{$dec} = $ip;
       no bigint;
       use warnings;
}    


sub getdata
{
    my ($self,$result,$ip,$version) = @_;
    my ($aliases,$correspondence,$index,$vlan) = ($self->{aliases},$self->{correspondence},$self->{index},$self->{VLAN});
    my ($vlan_v2,%settings,$error,$session,$status,$session2,@ToCheck);
    local $_;




    $vlan_v2 = $vlan;
    $vlan_v2 =~ s/vlan-(\d+)/$1/;
    if ($version eq 'v3')
    {
	%settings = (	-hostname       => $ip,
			-version        => 'snmpv3',
			-timeout        => $self->{TIMEOUT},
			-username       => $self->{USER},
			-authpassword   => $self->{PASS},
			-nonblocking    => 1,
			-maxmsgsize     => 65535);
    }
    else
    {
	%settings = (	-hostname       => $ip,
			-version        => 'snmpv2',
			-community      => $self->{COMMUNITY}.'@'.$vlan_v2,
			-timeout        => $self->{TIMEOUT},
			-nonblocking    => 1,
			-maxmsgsize     => 65535);
    }
    ($session,$error) = Net::SNMP->session(%settings);

    die("Error while creating SNMP object:$error\n") if (!defined($session));

    
    $self->getsettings(\%settings,$ID3,\&pushbridgemac,$result,$version,'request');
    $status= $session->get_request(%settings);
    $self->debug("Error while sending a SNMP get-request $ID3:".$session->error()) if (!defined($status));
    
    
    
    $self->getsettings(\%settings,$ID4,\&pushbridgepri,$result,$version,'request');
    $status= $session->get_request(%settings);
    $self->debug("Error while sending a SNMP get-request $ID4:".$session->error()) if (!defined($status));
    
    
    $self->getsettings(\%settings,$ID5,\&pushstate,$result,$version,'table');
    $status= $session->get_table(%settings);
    $self->debug("Error while sending a SNMP get-request $ID5:".$session->error()) if (!defined($status));
    
    $self->getsettings(\%settings,$ID6,\&pushcost,$result,$version,'table');
    $status= $session->get_table(%settings);
    $self->debug("Error while sending a SNMP get-request $ID6:".$session->error()) if (!defined($status));

        
    $self->getsettings(\%settings,$ID7,\&pushcorrespondence,$correspondence,$version,'table');
    $status= $session->get_table(%settings);
    $self->debug("Error while sending a SNMP get-request $ID7:".$session->error()) if (!defined($status));
    
    ($session2,$error) = Net::SNMP->session(	-hostname       => $ip,
						-version        => 'snmpv3',
						-timeout        => $self->{TIMEOUT},
						-username       => $self->{USER},
						-authpassword   => $self->{PASS},
						-nonblocking    => 1,
						-maxmsgsize     => 65535);
    
    die("Error while creating SNMP object:$error\n") if (!defined($session2));

    $status= $session2->get_table(
	-baseoid       => $ID8,
	-callback      => [\&pushinterfaces,$self,$result],
	);
    $self->debug("Error while sending a SNMP get-request $ID8:".$session2->error()) if (!defined($status));

    $status= $session2->get_table(
	-baseoid       => $ID9,
	-callback      => [\&pushindexes,$self],
	);
    $self->debug("Error while sending a SNMP get-request $ID9:".$session2->error()) if (!defined($status));
    
    $status= $session2->get_table(
	-baseoid       => $ID10,
	-callback      => [\&pushstatus,$self],
	);
    $self->debug("Error while sending a SNMP get-request $ID10:".$session2->error()) if (!defined($status));
    
    $status= $session2->get_table(
	-baseoid       => $ID11,
	-callback      => [\&pushdeviceid,$self,$result],
	);
    $self->debug("Error while sending a SNMP get-request $ID11:".$session2->error()) if (!defined($status));

    $status= $session2->get_table(
	-baseoid       => $ID12,
	-callback      => [\&pushdeviceport,$self,$result],
	);
    $self->debug("Error while sending a SNMP get-request $ID12:".$session2->error()) if (!defined($status));

    $status= $session2->get_table(
	-baseoid       => $ID13,
	-callback      => [\&pushdeviceip,$self,$result,\@ToCheck],
	);
    $self->debug("Error while sending a SNMP get-request $ID13:".$session2->error()) if (!defined($status));
    
    
    $status= $session2->get_table(
	-baseoid       => $ID14,
	-callback      => [\&pushdeviceplatform,$self,$result],
	);
    $self->debug("Error while sending a SNMP get-request $ID14:".$session2->error()) if (!defined($status));

    snmp_dispatcher();
    $session->close();
    $session2->close();

    
    


    for (my $i = 0;$i <= $#ToCheck;$i++)
    {
	$ip = $ToCheck[$i][0];
	$version= grep($ip eq $_,@{$self->{IPV2_CONF}})? 'v2':'v3';
	$self->getdata($ToCheck[$i][1],$ip,$version);
    }
    
    @ToCheck = ();
}


sub getsettings
{
	my ($self,$settings,$ID,$func,$result,$version,$type) = @_;
	my $vlan = $self->{VLAN};

	if ($type eq 'table')
	{
	    if ($version eq 'v3')
	    {
		%$settings=(-baseoid      => $ID,
			    -contextname  => $vlan,
			    -callback     => [$func,$self,$result]);
	    }
	    elsif ($version eq 'v2')
	    {
		%$settings=(-baseoid      => $ID,
			    -callback     => [$func,$self,$result]);
	    }
	    else
	    {
		die "Unknown version - $version in func getsettings\n";
	    }
	}
	elsif ($type eq 'request')
	{
	    if ($version eq 'v3')
	    {
		%$settings=(-varbindlist  => [$ID],
			    -contextname  => $vlan,
			    -callback     => [$func,$self,$result]);
	    }
	    elsif ($version eq 'v2')
	    {
		%$settings=(-varbindlist  => [$ID],
			    -callback     => [$func,$self,$result]);
	    }
	    else
	    {
		die "Unknown version - $version in func getsettings \n";
	    }
	}
	else
	{
	    die "Unknown type operation - $type in func getSettings \n";
	}
}



sub pushbridgemac
{
    my ($session,$self,$result) = @_;
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;

    
    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID2:\t ".$session->hostname.':'.$session->error());
	return;
    }
    
    $result->{data}{mac} = substr($lists->{$ID3},2);

}


sub pushbridgepri
{
    my ($session,$self,$result) = @_;
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;


    
    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID3:\t ".$session->hostname.':'.$session->error());
	return;
    }

    
    $result->{data}{priority} = $lists->{$ID4};
}

sub pushstate
{
    my ($session,$self,$result) = @_;
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    my @state;
    @state[1..6]=('disabled','blocking','listening','learning','forwarding','broken');
    my ($key,$value);
    
    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID5:\t ".$session->hostname.':'.$session->error());
	return;
    }
    
    while (($key,$value) = each %$lists)
    {
	$result->{data}{state}{substr($key,24)} = $state[$value];
    }
}

sub pushcost
{
    my ($session,$self,$result) = @_;
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    my ($key,$value);
    
    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID6:\t ".$session->hostname.':'.$session->error());
	return;
    }
    
    while (($key,$value) = each %$lists)
    {
	$result->{data}{cost}{substr($key,24)} = $value;
    }
}


sub pushcorrespondence
{

    my ($session,$self,$correspondence) = @_;
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    my ($key,$value);

    
    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID7:\t ".$session->hostname.':'.$session->error());
	return;
    }
 
    while (($key,$value) = each %$lists)
    {
	$correspondence->{$ip}{substr($key,23)} = $value;
    }
    %{$correspondence->{$ip}} = reverse %{$correspondence->{$ip}};
}


sub debug
{
    my ($self,$str) = @_;

    print STDERR $str."\n" if ($self->{DEBUG});
}


sub pushinterfaces
{
    my ($session,$self,$result) = @_;
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    my ($key,$value);

    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID8:\t ".$session->hostname.':'.$session->error());
	return;
    }

    while (($key,$value) = each %$lists)
    {
	$value =~ s/^(.{2}).*?(\d.*)$/$1$2/;
	$result->{data}{interface}{substr($key,20)} = $value;
    }
}



sub pushindexes
{
    my ($session,$self) = @_;
    my $index = $self->{index};
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    my ($key,$value);


    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID9:$ip\t ".$session->hostname.':'.$session->error());
	return;
    }

    while (($key,$value) = each %$lists)
    {
	no warnings;
	$index->{$ip}{substr($key,20)}=$value  unless($index->{$ip}{substr($key,20)} == -1);
	use warnings;
    }


}

sub pushstatus
{
    my ($session,$self) = @_;
    my $index = $self->{index};
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    my ($key,$value);
    

    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID10:\t ".$session->hostname.':'.$session->error());
	return;
    }

    while (($key,$value) = each %$lists)
    {
	$index->{$ip}{substr($key,30)}=-1 if ($value == 2);
    }
    

}

sub pushdeviceid
{
    my ($session,$self,$result) = @_;
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    my ($key,$val,$id);
    

    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID11:\t ".$session->hostname.':'.$session->error());
	$result->{data}{shape}='ellipse';
	return;
    }
    
    while (($key,$val) = each %$lists)
    {
	($id) = $key =~ /\.(\d+)\.\d+$/;
	$result->{devices}{$id}{DeviceID}=$val;
    }

}


sub pushdeviceport
{
    my ($session,$self,$result) = @_;
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    my ($key,$val,$id);
    

    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID12:\t ".$session->hostname.':'.$session->error());
	return;
    }

    while (($key,$val) = each %$lists)
    {
	($id) = $key =~ /\.(\d+)\.\d+$/;
	$val =~ s/^(.{2}).*?(\d.*)$/$1$2/;
	$result->{devices}{$id}{interface}=$val;
    }

}

sub pushdeviceip
{
    my ($session,$self,$result,$ToCheck) = @_;
    my ($checked,$aliases) = ($self->{checked},$self->{aliases});
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    my ($key,$val,$id);
    

    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID13:\t ".$session->hostname.':'.$session->error());
	return;
    }

    while (($key,$val) = each %$lists)
    {
	($id) = $key =~ /\.(\d+)\.\d+$/;

	$val =~ s/0x([0-f]{2})([0-f]{2})([0-f]{2})([0-f]{2})/sprintf("%d.%d.%d.%d",hex($1),hex($2),hex($3),hex($4))/e;
	$val = $aliases->{$val} if (defined($aliases->{$val}));

	$result->{devices}{$id}{$val}{data} = undef;
	unless (grep($_ eq $val,@$checked))
	{
	    push(@$ToCheck,[$val,$result->{devices}{$id}{$val}]);
	    push(@$checked,$val);
	}
    }

}


sub pushdeviceplatform
{
    my ($session,$self,$result) = @_;
    my $ip = $session->hostname;
    my $lists = $session->var_bind_list;
    my ($key,$val,$id);
    

    if (!defined($lists))
    {
	$self->debug("Error while sending a SNMP get-request for $ID14:\t ".$session->hostname.':'.$session->error());
	return;
    }

    while (($key,$val) = each %$lists)
    {
	($id) = $key =~ /\.(\d+)\.\d+$/;
	$result->{devices}{$id}{platform}=$val;
    }

}

sub output_nodes
{
    my ($self,$result,$picture,$root_ip) = @_;
    my ($correspondence,$index,$labels,$platforms,$shapes) = ($self->{correspondence},$self->{index},
                                                                                $self->{labels},
	                                                                        $self->{platforms},$self->{shapes}); 
    my ($val,$ip,$color,$shape,$label,$fillcolor,$fontcolor);


    ($ip) = grep(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/,keys %$result);
    $color = $root_ip eq $ip? $self->{root_color}:$self->{color};
    $fillcolor = $root_ip eq $ip?$self->{root_fillcolor}:$self->{fillcolor};
    $fontcolor = $root_ip eq $ip?$self->{root_fontcolor}:$self->{fontcolor};


    $labels->{$ip}[0] = $ip;

    foreach $val (keys %{$result->{$ip}{devices}})
    {
	push(@{$labels->{$ip}},$result->{$ip}{data}{interface}{$val});
	$self->output_nodes($result->{$ip}{devices}{$val},$picture,$root_ip);
    }

    if (defined($platforms->{$ip}))
    {
	while (my ($key,$val) = each %$shapes)
	{
	    if ($platforms->{$ip} =~ /$key/)
	    {
		$shape = $val;
		last;
	    }
	}
	$shape ||= 'box';
    }
    else
    {
	$shape = $shapes->{unknown};
    }
    $label = $#{$labels->{$ip}} == 0? $labels->{$ip}[0]:$labels->{$ip};
    $picture->add_node($ip,shape=>$shape,label=>$label,fontcolor=>$fontcolor,color=>$color,fillcolor=>$fillcolor,URL=>$ip);
}
sub nodes_info
{
    my $self = shift;
    
    die "No data for info" unless ($self->{GOT});
    $self->nodes_info_($self->{result});
    return %{$self->{info_node}};
}
sub nodes_info_
{
    my ($self,$result) = @_;
    my ($info_node,$platforms,$index,$correspondence) = ($self->{info_node},$self->{platforms},$self->{index},
							 $self->{correspondence});
    my $ip;

    ($ip) = grep(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/,keys %$result);
    $info_node->{$ip}{deviceID} =  $result->{DeviceID} if (defined($result->{DeviceID}));
    $info_node->{$ip}{priority}= $result->{$ip}{data}{priority} if (defined($result->{$ip}{data}{priority}));
    $info_node->{$ip}{mac} = $result->{$ip}{data}{mac} if (defined($result->{$ip}{data}{mac}));
    $info_node->{$ip}{platform} = $platforms->{$ip} if (defined($platforms->{$ip}));
    if (defined($correspondence->{$ip}))
    {
	$info_node->{$ip}{interfaces} = {};
	
	foreach my $value (values %{$index->{$ip}})
	{
	    my $key = $correspondence->{$ip}{$value};
	    next if ($value == -1 or !defined($key));
	    next unless (defined($result->{$ip}{data}{interface}{$value}));
	    my $inf_key = $result->{$ip}{data}{interface}{$value};
	    $info_node->{$ip}{interfaces}{$inf_key}{state} = $result->{$ip}{data}{state}{$key} 
	      if (defined($result->{$ip}{data}{state}{$key}));
	    $info_node->{$ip}{interfaces}{$inf_key}{cost} = $result->{$ip}{data}{cost}{$key} 
	      if (defined($result->{$ip}{data}{cost}{$key}));
	}
		
    }
    foreach my $val (keys %{$result->{$ip}{devices}})
    {
	$self->nodes_info_($result->{$ip}{devices}{$val});
    }
}

sub output_edges
{
    my ($self,$result,$root_ip) = @_;
    my ($correspondence,$virtual,$info_edge,$draw2) = ($self->{correspondence},$self->{virtual},
						       $self->{info_edge},$self->{draw2});
    my ($interface_from,$from_port,$interface_to,$to_port,$ip,$ip2,$val,$color,$ifvirtualfrom,$ifvirtualto);
    my @edges_colors=@{$self->{edges_colors}};


    $ifvirtualto=$ifvirtualfrom = 0;

    ($ip) = grep(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/,keys %$result);
    
    foreach $val (keys %{$result->{$ip}{devices}})
    {
	($ip2) = grep(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/,keys %{$result->{$ip}{devices}{$val}});
	$interface_from = $result->{$ip}{data}{interface}{$val};
	$from_port = $self->getport($ip,$interface_from);
	$interface_to = $result->{$ip}{devices}{$val}{interface};
	$to_port = $self->getport($ip2,$interface_to);
	if (defined($correspondence->{$ip}{$val}))
	{
	    my $ind = $correspondence->{$ip}{$val};
	    if (defined($result->{$ip}{data}{cost}{$ind}))
	    {
		    my $cost = $result->{$ip}{data}{cost}{$ind};
		    my $value  = sprintf("%1.0f",log((1/$cost)*100));
		    $color = $edges_colors[$value];
	    }
	    else
	    {
		$color=$edges_colors[0];
	    }
	    $color = $edges_colors[$#edges_colors] if ($result->{$ip}{data}{state}{$ind} eq 'blocking');
	}
	else
	{
	    $color = $edges_colors[0];
	}
	
	if (defined($virtual->{$ip}{$val}))
	{
	    my $val_virt = $virtual->{$ip}{$val};
	    $ifvirtualfrom = $result->{$ip}{data}{interface}{$val_virt};
	    $ifvirtualto = $self->getvirtualto($self->{result},$root_ip,$interface_to,$ip2);
	    my $ind_virt = $correspondence->{$ip}{$val_virt};
	    $color = $edges_colors[$#edges_colors] if ($result->{$ip}{data}{state}{$ind_virt} eq 'blocking');
	}
	
	my $n = $#$info_edge+1;
	
	$info_edge->[$n] = {};
	$info_edge->[$n]{from_ip} = $ip;
	$info_edge->[$n]{from_interface} = $interface_from;
	$info_edge->[$n]{from_virtual} = $ifvirtualfrom;
	$info_edge->[$n]{to_ip} = $ip2;
	$info_edge->[$n]{to_interface} = $interface_to;
	$info_edge->[$n]{to_virtual} = $ifvirtualto;
	
	
	push(@$draw2,"$ip $ip2 $from_port $to_port $color $#$info_edge");
	    
	
	
	$self->output_edges($result->{$ip}{devices}{$val},$root_ip);
	
    }
}
sub edge_info
{
    my ($self,$n) = @_;
    die "No data for info" unless ($self->{GOT});
    return %{$self->{info_edge}[$n]};
}
sub getvirtualto
{
    my ($self,$result,$root_ip,$interface_to,$ip) = @_;
    my $virtual = $self->{virtual};
    my ($ipt,$val2,$val2_virt,$VirtualTo);
    local $_;
    
    foreach (keys %{$result->{$root_ip}{devices}})
    {
	($ipt) = grep(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/,keys %{$result->{$root_ip}{devices}{$_}});
	if ($ip eq $ipt and keys %{$result->{$root_ip}{devices}{$_}{$ipt}{devices}})
	{
	    foreach my $ind (%{$result->{$root_ip}{devices}{$_}{$ipt}{data}{interface}})
	    {		
		no warnings;
		if ($result->{$root_ip}{devices}{$_}{$ipt}{data}{interface}{$ind} eq $interface_to)
		{
		    $val2_virt= $virtual->{$ip}{$ind};
		    return $result->{$root_ip}{devices}{$_}{$ipt}{data}{interface}{$val2_virt};
		}
		use warnings;
	    }
	    return undef;
	}
	$VirtualTo = $self->getvirtualto($result->{$root_ip}{devices}{$_},$ipt,$interface_to,$ip);
	return $VirtualTo if (defined($VirtualTo));
    }
    return undef;
}
sub printedges
{
    my ($self,$picture) = @_;
    my $draw2 = $self->{draw2};
    my @edges_colors = @{$self->{edges_colors}};
    my $labels = $self->{labels};
    local $_;
    my ($ip,$ip2,$port,$port2,$color,$number,$_ip,$_ip2,$_port,$_port2,$_color,$_number,$colorf);

    my $j = 0;

NEXT:while ($j <= $#$draw2)
    {
	unless (defined($draw2->[$j]))
	{
	    $j++;
	    next;
	}
	($ip,$ip2,$port,$port2,$color,$number) = split / /,$draw2->[$j];
	for (my $i = $j+1;$i <= $#$draw2;$i++)
	{
	    next unless (defined($draw2->[$i]));
	    ($_ip,$_ip2,$_port,$_port2,$_color,$_number) = split / /,$draw2->[$i];
	    if (($ip eq $_ip2) and ($ip2 eq $_ip) and ($port eq $_port2) and ($port2 eq $_port))
	    {
		$colorf = $color ge $_color? $color:$_color;
		$colorf = $color if ($_color eq $edges_colors[0]);
		$colorf = $_color if ($color eq $edges_colors[0]);
		my %ports;
		$ports{from_port} = $port if ($#{$labels->{$ip}} > 0);
		$ports{to_port} = $port2 if ($#{$labels->{$ip2}} > 0);
		$picture->add_edge($ip => $ip2,%ports,color=>$colorf,URL=>$number);
		delete $draw2->[$i];
		delete $draw2->[$j];
		$j++;
		next NEXT;
	    }
	}
	my %ports;
	$ports{from_port} = $port if ($#{$labels->{$ip}} > 0);
	$ports{to_port} = $port2 if ($#{$labels->{$ip2}} > 0);
	$picture->add_edge($ip => $ip2,%ports,color=>$color,URL=>$number);
	delete $draw2->[$j];
	$j++;
    }
}
sub getport
{
    my ($self,$ip,$interface) = @_;
    my $labels = $self->{labels};
    for (my $i = 0; $i <= $#{$labels->{$ip}}; $i++)
    {	   
	return $i if ($labels->{$ip}[$i] eq $interface);
    }
    return 0;
}
1;
