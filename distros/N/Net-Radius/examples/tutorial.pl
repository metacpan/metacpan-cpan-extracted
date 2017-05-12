##
## This file shows the very basics of using these modules by commenting
## on common tasks required within a server or a client. It assumes you're
## familiar with the RADIUS protocol. If you're not, check the included RFCs
## and your equipment's manual.
##
## Luis E. Muñoz <luismunoz@cpan.org>
##
## THIS FILE IS CURRENTLY UNDER REVIEW. PLEASE REFER TO example-*.pl FOR
## SPECIFIC USAGE EXAMPLES INVOLVING UP TO DATE METHODS.
##
###################################
###################################

use Net::Radius::Packet;
use Net::Radius::Dictionary;

# The first thing you need, is a dictionary file. We will assume that 
# this pathname is correct. The dictionary contains the specifications
# for the attributes that this module understands, and must contain
# information for the attributes that your vendor provides. Normally,
# vendors support a set of standard attributes, and might also have
# proprietary attributes that you can add to this file.

my $dict = new Net::Radius::Dictionary "../dictionary"
    or die "Cannot read or parse the dictionary: $!\n";

# As you see, there's no point in going on if you do not have a
# dictionary object to work with.

# Our first task, is to fill a packet. Let's create a packet that
# looks like the one sent from a NAS or access device...

my $packet = new Net::Radius::Packet $dict;

# The packet object needs to know which dictionary to use to encode and
# decode the attributes you will use.

# One of the common packets we'll receive from devices are going to be
# 'Access-Request' packets. Let's do it.

$packet->set_code('Access-Request');

# Now let's add an identifier, which is like a counter that the NAS uses
# to keep track of which reply belongs to which request.

$packet->set_identifier(1);

# At this point, we have set some information in the packet. However, we
# should add some useful attributes to it. First, we add some attributes
# that are standard and should be in the dictionary. Otherwise, the generated
# packet won't contain the intended data.

$packet->set_attr('User-Name',		'you');
$packet->set_attr('NAS-IP-Address',	'127.0.0.1');
$packet->set_attr('NAS-Port', 		1);

# Some equipment also can use a 'Vendor-Specific Attribute' to control
# some part of its behavior. These attributes are there so that each
# vendor can extend the protocol in a somewhat standard way. Let's
# add a vendor attribute for a Cisco piece of equipment. Note that 
# Cisco is vendor 9.

$packet->set_vsattr(9, 'cisco-avpair', 'This is my VSA 1');

# You can add multiple instances of the attribute/value to the packetr
# just like below.

$packet->set_vsattr(9, 'cisco-avpair', 'This is my VSA 2');

# At this point, you have a nice example packet. In order to use this
# packet, we must first "sign" it as the NAS would. This is done in
# this particular kind of packet with the help of the user-supplied
# password, as seen below.

$packet->set_attr('User-Password',	'My-Password');

# However the password must be protected by snooping. We do so using
# a 'shared-secret'. This is a secret password that is known only to
# this module and the NAS (as well as your network guys).

$packet->set_attr('User-Password',	$packet->password('My-Shared-Secret'));

# Before the actual signing takes place, we must convert the object to
# an actual packet that can be sent through the network, like in this
# example.

my $p = $packet->pack;

# The final step in signing the packet is done below. $data will
# contain the definitive data that must be sent to the server. Note
# that the shared secret MUST be the same used to protect the password
# for authentication to occur.

my $data = auth_resp($p, 'My-Shared-Secret');

# After this, we can take a look at how our finished packed looks...

my $np = new Net::Radius::Packet $dict, $data;

$np->dump;

# The accompaining examples in this directory explain what to do at the
# server...
