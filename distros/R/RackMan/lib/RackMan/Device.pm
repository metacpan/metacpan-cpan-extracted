package RackMan::Device;

use Carp;
use Module::Runtime;
use Moose;
use Moose::Util::TypeConstraints;
use RackMan;
use RackMan::Types;
use RackMan::Utils;
use Socket;
use namespace::autoclean;



#
# constants
#
use constant {
    DEFAULT_VIRT_IFACES     => "/(carp|lagg|vlan)\\d+/",
    DEFAULT_MGMT_IFACES     => "/(areca|ilo|ipmi)/",
};


#
# global vars
#
my %ImplementedType = map { $_ => 1 } RackMan::Types->implemented;


#
# custom types
#
enum RackObjectType => [ RackMan::Types->enum ];


#
# object attributes
#
has rackman => (
    is => "ro",
    isa => "RackMan",
);

has racktables => (
    is => "ro",
    isa => "RackTables::Schema",
    required => 1,
);

has rackobject => (
    is => "ro",
    isa => "RackTables::Schema::Result::RackObject",
    handles => {
        object_id           => "id",
        object_name         => "name",
        object_asset_no     => "asset_no",
        object_has_problem  => "has_problems",
        object_comment      => "comment",
    },
);

has object_type => (
    is => "ro",
    isa => "RackObjectType",
    lazy => 1,
    builder => "_get_type",
);

has attributes => (
    is => "ro",
    isa => "HashRef",
    lazy => 1,
    builder => "_get_attributes",
);

has explicit_tags => (
    is => "ro",
    isa => "ArrayRef",
    lazy => 1,
    builder => "_get_explicit_tags",
);

has implicit_tags => (
    is => "ro",
    isa => "ArrayRef",
    lazy => 1,
    builder => "_get_implicit_tags",
);

has tag_tree => (
    is => "ro",
    isa => "HashRef",
    lazy => 1,
    builder => "_get_tag_tree",
);

has ports => (
    is => "ro",
    isa => "ArrayRef[HashRef]",
    lazy => 1,
    builder => "_get_ports",
);

has ipv4addrs => (
    is => "ro",
    isa => "ArrayRef[HashRef]",
    lazy => 1,
    traits => ["Array"],
    builder => "_get_ipv4addrs",
    handles => {
        has_ipv4addrs   => "count",
    },
);

has ipv6addrs => (
    is => "ro",
    isa => "ArrayRef[HashRef]",
    lazy => 1,
    traits => ["Array"],
    builder => "_get_ipv6addrs",
    handles => {
        has_ipv6addrs   => "count",
    },
);

has default_ipv4_gateway => (
    is => "ro",
    isa => "HashRef",
    lazy => 1,
    builder => "_get_default_ipv4_gateway",
);

has parents => (
    is => "ro",
    isa => "ArrayRef",
    lazy => 1,
    builder => "_get_parents",
);

has rack => (
    is => "ro",
    isa => "HashRef",
    lazy => 1,
    builder => "_get_rack",
);


#
# BUILDARGS()
# ---------
sub BUILDARGS {
    my $class = shift;
    my %param;
    my $rack_obj;

    if (@_ % 2 == 0) {
        %param = @_;
    }
    elsif (ref $_[0] eq "HASH") {
        %param = %{$_[0]};
    }
    else {
        croak "invalid argument: ", lc ref $_[0], "ref instead of hashref";
    }

    # check parameters
    croak "error: one of 'id' or 'name' must be specified"
        if not exists $param{id} and not exists $param{name};

    croak "error: parameter 'racktables' isn't a RackTables::Schema object"
        unless eval { $param{racktables}->isa("RackTables::Schema") };

    # try to find the RackObject
    for my $src (qw< name id >) {
        next unless exists $param{$src};

        # try to fetch a RackObject using the given source
        $rack_obj = $param{racktables}->resultset("RackObject")->search(
            { "me.$src" => $param{$src} },
            { prefetch => { attribute_values => { attr => "attr" } } },
        )->first;

        # if none returned, it means it doesn't exist
        RackMan->error("no RackObject with $src '$param{$src}'")
            unless defined $rack_obj;

        last if $rack_obj;
    }

    # construct the object attributes
    my %attrs = ( rackobject => $rack_obj, racktables => $param{racktables} );
    $attrs{rackman} = $param{rackman} if defined $param{rackman};

    return \%attrs
}


#
# BUILD()
# -----
sub BUILD {
    my ($self, $args) = @_;

    if ($ImplementedType{$self->object_type}) {
        # determine the type of device and apply the corresponding 
        # role to the object
        my $type_role = __PACKAGE__."::".$self->object_type;
        eval { Module::Runtime::require_module($type_role) }
            or RackMan->error("can't load $type_role: $@");
        $type_role->meta->apply($self);

        # "specialise" the object (apply a specialised role) to the object
        # so it knows how to speak with the actual hardware, if needed
        $self->specialise;
    }
}


#
# _get_type()
# ---------
sub _get_type {
    my $self = shift;

    # fetch the hardware type of the RackObject
    my $type = $self->racktables->resultset("Dictionary")->search(
        { chapter_id => 1, dict_key => $self->rackobject->objtype_id },
    )->first->dict_value;

    $type = RackMan::Types->from_racktables($type);

    return $type
}


#
# _get_attributes()
# ---------------
sub _get_attributes {
    my $self = shift;

    my %attr;
    my $dictionary = $self->racktables->resultset("Dictionary");

    # fetch object attributes
    for my $attv ($self->rackobject->attribute_values) {
                                    # $attv is an AttributeValue resultset
        my $attm = $attv->attr;     # $attm is an AttributeMap resultset
        my $attr = $attm->attr;     # $attr is an Attribute resultset
        my $name = $attr->name;
        my $type = $attr->type;

        if ($type eq "string") {
            $attr{$name} = $attv->string_value;
        }
        elsif ($type eq "uint") {
            $attr{$name} = int $attv->uint_value;
        }
        elsif ($type eq "float") {
            $attr{$name} = .0+ $attv->float_value;
        }
        elsif ($type eq "dict") {
            my $dict_rs = $dictionary->search(
                { "chapter.id" => $attm->chapter_id, dict_key => $attv->uint_value },
                { join => "chapter" },
            );

            while (my $item = $dict_rs->next) {
                $attr{$name} = $item->dict_value;
            }
        }
    }

    # interpret "GMarker" (that's a RackTables thing. don't ask.)
    s/^.+%GSKIP%//, s/%GPASS%/ / for values %attr;

    # extract wiki-links and store them in additional attributes
    for (keys %attr) {
        ($attr{$_}, $attr{"$_ link"})
            = $attr{$_} =~ /^\[\[([^|]+)\s*\|\s*(.+)\]\]$/
            if $attr{$_} =~ /^\[\[/;
        $attr{$_} =~ s/ +$//;
    }

    return \%attr
}


#
# _get_explicit_tags()
# ------------------
sub _get_explicit_tags {
    my $self = shift;

    # fetch object tags
    my $tags_rs = $self->racktables->resultset("TagTree")->search(
        { entity_realm => "object", entity_id => $self->object_id },
        { join => "tag_storages" },
    );
    my @explicit_tags = map { eval { $_->tag } } $tags_rs->all;

    return \@explicit_tags
}


#
# _get_implicit_tags()
# ------------------
sub _get_implicit_tags {
    my $self = shift;

    # fetch object tags
    my $tags_rs = $self->racktables->resultset("TagTree")->search(
        { entity_realm => "object", entity_id => $self->object_id },
        { join => "tag_storages" },
    );

    # for each tag, find all its parent tags
    my @implicit_tags;
    for my $tag ($tags_rs->all) {
        while ($tag = $tag->parent) {
            push @implicit_tags, $tag->tag;
        }
    }

    return \@implicit_tags
}


#
# _get_tag_tree()
# -------------
sub _get_tag_tree {
    my $self = shift;

    # fetch object tags
    my $tags_rs = $self->racktables->resultset("TagTree")->search(
        { entity_realm => "object", entity_id => $self->object_id },
        { join => "tag_storages" },
    );

    # reconstruct the tag tree as a hash of hashes
    my %tag_tree;
    for my $tag ($tags_rs->all) {
        my $node = $tag_tree{$tag->tag} ||= {};

        while ($tag = $tag->parent) {
            $node = $node->{$tag->tag} ||= {};
        }
    }

    return \%tag_tree
}


#
# _get_ports()
# ----------
sub _get_ports {
    my $self = shift;

    # find associated ports
    my $ports = $self->racktables->resultset("viewAssociatedPorts")->search(
        {}, { bind => [ $self->object_id ] },
    );

    my @ports = map +{
        name                => $_->name,
        l2address           => $_->l2address,
        l2address_text      => eval {
            my $s = $_->l2address || ""; $s =~ s/(\w\w)/$1:/g; $s =~ s/:$//; $s
        },
        iif_id              => $_->iif_id,
        iif_name            => $_->iif_name,
        oif_id              => $_->oif_id,
        oif_name            => $_->oif_name,
        peer_port_id        => $_->peer_port_id,
        peer_port_name      => $_->peer_port_name,
        peer_object_id      => $_->peer_object_id,
        peer_object_name    => $_->peer_object_name,
    }, $ports->all;

    return \@ports
}


#
# regular_mac_addrs()
# -----------------
sub regular_mac_addrs {
    my $self = shift;

    my ($re, $err) = parse_regexp($self->rackman->config->val(
        "general", "management_interfaces", DEFAULT_MGMT_IFACES));

    return
        grep { $_->{name} !~ /$re/ }
        grep { defined $_->{l2address} and length $_->{l2address} }
        @{ $self->ports }
}


#
# _get_ipv4addrs()
# --------------
sub _get_ipv4addrs {
    my $self = shift;

    # find IPv4 addresses
    my $ipv4_rs = $self->racktables->resultset("IPv4Allocation")->search(
        { object_id => $self->object_id },
    );

    my @addrs = sort { $a->{iface} cmp $b->{iface} } map +{
        version => 4,  type => $_->type,  iface => $_->name,
        addr => inet_ntoa(pack "N", $_->ip),
    }, grep defined $_->ip, $ipv4_rs->all;

    return \@addrs
}


#
# _get_ipv6addrs()
# --------------
sub _get_ipv6addrs {
    my $self = shift;

    # Socket.pm only has IPv6 support since Perl 5.12; for older Perl,
    # we need to use Socket6
    if ($] < 5.012) {
        require Socket6;
        import Socket6;
    }
    else {
        *inet_ntop = \&Socket::inet_ntop;
    }

    # find IPv6 addresses
    my $ipv6_rs = $self->racktables->resultset("IPv6Allocation")->search(
        { object_id => $self->object_id },
    );

    my @addrs = sort { $a->{iface} cmp $b->{iface} } map +{
        version => 6,  type => $_->type,  iface => $_->name,
        addr => inet_ntop(AF_INET6(), $_->ip),
    }, grep defined $_->ip, $ipv6_rs->all;

    return \@addrs
}


#
# regular_ipv4addrs()
# -----------------
sub regular_ipv4addrs {
    my $self = shift;

    my ($re, $err) = parse_regexp($self->rackman->config->val(
        "general", "management_interfaces", DEFAULT_MGMT_IFACES));

    return
        grep { $_->{iface} !~ /$re/ }
        grep { $_->{type} eq "regular" }
        @{ $self->ipv4addrs }
}


#
# regular_ipv6addrs()
# -----------------
sub regular_ipv6addrs {
    my $self = shift;

    my ($re, $err) = parse_regexp($self->rackman->config->val(
        "general", "management_interfaces", DEFAULT_MGMT_IFACES));

    return
        grep { $_->{iface} !~ /$re/ }
        grep { $_->{type} eq "regular" }
        @{ $self->ipv6addrs }
}


#
# physical_interfaces()
# -------------------
sub physical_interfaces {
    my $self = shift;

    my ($re, $err) = parse_regexp($self->rackman->config->val(
        "general", "virtual_interfaces", DEFAULT_VIRT_IFACES));

    return
        grep { $_->{iface} !~ /$re/ }
        grep { $_->{type} eq "regular" }
        @{ $self->ipv4addrs }, @{ $self->ipv6addrs }
}


#
# _get_default_ipv4_gateway()
# -------------------------
sub _get_default_ipv4_gateway {
    my ($self, $addr) = @_;

    if (not defined $addr) {
        # if no IP address is given, use the first regular one
        my @addrs = $self->regular_ipv4addrs;
        $addr = $addrs[0]{addr};
    }

    # find the network of the given IPv4 address
    my $networks = $self->racktables
        ->resultset("viewIPv4AddressNetwork")->search(
        {}, { bind => [ $addr ] },
    );

    # determine the lower (network address) and upper (broadcast
    # address) bounds of the range
    my $network = $networks->first;
    return {} unless $network;
    my $lower   = $network->ip;
    my $upper   = $lower | (0xffffffff >> $network->mask);

    my $range = $self->racktables
        ->resultset("viewIPv4AddressRange")->search(
        {}, { bind => [ $lower, $upper ] },
    );

    # filter to only keep the routers, and keep only the first one
    my ($gateway) = grep { $_->type eq "router" } $range->all;

    # construct the result
    my @fields = qw< iface type addr object_id >;
    my %result;
    @result{@fields} = ();

    if (defined $gateway) {
        $result{$_} = $gateway->$_ for @fields;
        $result{masklen} = $network->mask;
        $result{network} = $network->addr;
        $result{netname} = $network->name;
    }

    return \%result
}


#
# get_network()
# -----------
sub get_network {
    my ($self, $addr) = @_;

    my @fields = qw< id addr mask name comment >;
    return { map { $_ => "" } @fields } unless defined $addr;

    $addr = { version => 4,  addr => $addr } unless ref $addr;

    # find the network of the given address
    my $view = $addr->{version} eq "6" ? "viewIPv6AddressNetwork"
                                       : "viewIPv4AddressNetwork";
    my $networks = $self->racktables->resultset($view)->search(
        {}, { bind => [ $addr->{addr} ] },
    );

    my $network = $networks->first;
    return defined $network
        ? { map { $_ => $network->$_ } @fields }
        : { map { $_ => "" } @fields }
}


#
# _get_parents()
# ------------
sub _get_parents {
    my ($self) = @_;

    my $parents = $self->racktables->resultset("EntityLink")->search(
        { child_entity_type => "object", child_entity_id => $self->object_id }
    );

    my @parents = map $_->parent_entity_id, $parents->all;

    return \@parents
}


#
# _get_rack()
# ---------
sub _get_rack {
    my $self = shift;

    my $object_id = $self->object_id;

    # check if this is a VM or a blade. in that case, we must find
    # the ID of the parent
    if (my @parents = @{ $self->parents }) {
        ($object_id) = @parents;
    }

    # find associated rack
    my $rack = $self->racktables->resultset("viewRack")->search(
        {}, { bind => [ $object_id ] },
    )->first;

    my %rack = (
        id        => $rack->id,
        name      => $rack->name,
        comment   => $rack->comment,
        row_id    => $rack->row_id,
        row_name  => $rack->row_name,
    );

    $_ = join " ", map ucfirst lc, split / /
        for $rack{name}, $rack{row_name};

    return \%rack
}


__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

RackMan::Device - Class for representing a RackObject

=head1 SYNOPSIS

    use RackMan::Device;

    my $obj = RackMan::Device->new({ name => $name, racktables => $rtschema });


=head1 DESCRIPTION

This module is a Moose-based class for representing a RackObject.


=head1 METHODS

=head2 new

Create and return a new object.

B<Arguments>

Arguments are expected as a hashref with the following keys:

=over

=item *

C<id> - ID of the object to retrieve from the database

=item *

C<name> - name of the object to retrieve from the database

=item *

C<racktables> - I<(mandatory)> a C<RackTables::Schema> instance

=item *

C<rackman> - an optional parent RackMan object

=back

One of C<name> of C<id> must be specified.


=head2 get_network

Find and return network information about the given IP address.
Result is given as a hashref.

B<Arguments>

=over

=item 1. IP address, as given by C<ipv4addrs> or C<ipv6addrs>

=back

B<Result>

=over

=item *

C<id> - integer, network id (in IPv4Network)

=item *

C<addr> - string, IP address

=item *

C<mask> - integer, network mask length

=item *

C<name> - string, network name

=item *

C<comment> - string, comment or description, if any

=back


=head1 ATTRIBUTES

=head2 attributes

Hashref, contains the attributes for this RackObject

=head2 default_ipv4_gateway

Hashref, contains information about the default IPv4 gateway:

=over

=item *

C<addr> - string, IPv4 address in dot-quad form

=item *

C<iface> - string, interface name

=item *

C<masklen> - integer, network mask length

=item *

C<network> - string, network address

=item *

C<netname> - string, network name

=item *

C<object_id> - integer, ID of the peer RackObject

=item *

C<type> - string, type of the address (C<regular>, C<shared>,
C<virtual>, C<router>)

=back

=head2 explicit_tags

Arrayref, contains the list of explicit tags for this RackObject

=head2 implicit_tags

Arrayref, contains the list of implicit tags for this RackObject

=head2 ipv4addrs

Arrayref, contains the list of IPv4 addresses for this RackObject,
each address being a hashref with the following keys:

=over

=item *

C<type> - string, type of the address (C<regular>, C<shared>, C<virtual>, C<router>)

=item *

C<iface> - string, interface name

=item *

C<addr> - string, IP address

=back

=head2 ipv6addrs

Arrayref, contains the list of IPv6 addresses for this
RackObject, each address being a hashref with the following keys:

=over

=item *

C<type> - string, type of the address (C<regular>, C<shared>, C<virtual>, C<router>)

=item *

C<iface> - string, interface name

=item *

C<addr> - string, IP address

=back

=head2 object_id

Integer, RackObject's ID

=head2 object_name

String, RackObject's name

=head2 object_asset_no

String, RackObject's asset tag

=head2 object_has_problem

Boolean

=head2 object_comment

String, RackObject's comment

=head2 object_type

String, RackObject's type

=head2 ports

Arrayref, contains the list of ports associated to this RackObject,
each port being a hashref with the following keys:

=over

=item *

C<name> - string, port name

=item *

C<l2address> - string, port L2 address

=item *

C<l2address_text> - string, port L2 address in colon-separated format

=item *

C<iif_id> - integer, inner interface ID

=item *

C<iif_name> - string, inner interface name

=item *

C<oif_id> - integer, outter interface ID

=item *

C<oif_name> - string, outter interface name

=item *

C<peer_port_id> - integer, peer port ID

=item *

C<peer_port_name> - string, peer port name

=item *

C<peer_object_id> - integer, peer object ID

=item *

C<peer_object_name> - string, peer object name

=back


=head2 parents

Arrayref, contains the object ID of the parents


=head2 physical_interfaces

List of the IPv4 addresses of the device which are not associated
with a virtual interface, as given by the [general]/virtual_interfaces 
config parameter. See L<rack/"CONFIGURATION"> for more details.


=head2 rack

Hashref, information about the rack containing the device

=over

=item *

C<id> - integer, rack ID

=item *

C<name> - string, rack name

=item *

C<comment> - text, rack comment

=item *

C<row_id> - integer, rack row ID

=item *

C<row_name> - string, rack row name

=back


=head2 rackman

An optional parent RackMan object, as given when this
object was created

=head2 rackobject

The underlying RackObject corresponding to the device

=head2 regular_mac_addrs

List of the regular MAC addresses of the device

=head2 regular_ipv4addrs

List of the regular IPv4 addresses of the device

=head2 regular_ipv6addrs

List of the regular IPv6 addresses of the device


=head2 tag_tree

Hashref, contains the tree of tags, with the explicit tags at first level


=head1 SEE ALSO

L<RackTables::Schema>


=head1 AUTHOR

Sebastien Aperghis-Tramoni (sebastien@aperghis.net)

=cut

