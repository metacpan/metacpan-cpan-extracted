package Net::Cisco::ObjectGroup;

use strict;
use warnings FATAL => qw(all);

our $VERSION = '1.01';
$VERSION = eval $VERSION; # numify for warning-free dev releases

use UNIVERSAL::require;
use Carp;

sub new {
    my $dummy_class = shift;
    my $arg_ref = shift;

    croak 'missing parameter "type"' if !defined $arg_ref->{type};
    croak "unrecognized object-group type: '$arg_ref->{type}'"
        if $arg_ref->{type} !~ m/^(?:icmp|network|protocol|service|port)$/i;

    croak 'missing parameter "name"' if !defined $arg_ref->{name};
    croak "bad object-group name: '$arg_ref->{name}'"
        if $arg_ref->{name} !~ m/^[a-zA-Z0-9_.-]{1,64}$/;

    croak 'bad description' if exists $arg_ref->{description}
        and length $arg_ref->{description} > 200;

    my $type = $arg_ref->{type} =~ m/icmp/i             ? 'ICMP'
             : $arg_ref->{type} =~ m/network/i          ? 'Network'
             : $arg_ref->{type} =~ m/protocol/i         ? 'Protocol'
             : $arg_ref->{type} =~ m/(?:service|port)/i ? 'Service'
             : croak 'please submit a bug report against this module';

    my $class = 'Net::Cisco::ObjectGroup::'. $type;
    $class->require or
        croak "couldn't load '$class' (maybe you forgot to install it?)";

    my $og = $class->new({
        type => lc $type,
        name => $arg_ref->{name},
        desc => $arg_ref->{description},
        objs => [],
    });

    $og->_init( $arg_ref ) if $og->can('_init');

    return $og;
}

1;

=head1 NAME

Net::Cisco::ObjectGroup - Generate Cisco ACL object groups

=head1 VERSION

This document refers to version 1.01 of Net::Cisco::ObjectGroup.

=head1 SYNOPSIS

 use Net::Cisco::ObjectGroup;
 my $og = Net::Cisco::ObjectGroup->new({
     type         => 'icmp'
     name         => 'friendly_icmp',
     description  => 'ICMP types we like', # optional
     pretty_print => 1,                    # optional
 });

 $g->push({icmp_type => 8}); # this is an echo request
 $g->push({group_object => $another_objectgroup_object});

 print $g->dump, "\n";
 # prints the object-group configuration commands to STDOUT, something like:
 
 object-group icmp friendly_icmp
   description ICMP types we like
   icmp-object echo
   group-object other_icmp_types

=head1 DESCRIPTION

Use this module to manage the presentation of Cisco PIX or FWSM Object Groups.
Group entries are pushed into the object in a simple parmaterized fashion, and
you can then dump the content in a format that is parsable by Cisco devices.

=head1 IMPORTANT NOTE

This module's error checking is only concerned with B<syntactic correctness>.
It makes no judgement of the I<semantic correctness> of your group entries.

For instance, newer FWSM systems use netmasks specified in terms of host
address network masks (e.g. C<255.255.255.0>), whereas older systems use
wildcard bits (e.g. C<0.0.0.255>). C<Net::Cisco::ObjectGroup> will not check
that you use the correct type of mask, or even that your mask isn't something
completely inappropriate (e.g. C<cabbages>).

=head1 METHODS

=head2 C<< Net::Cisco::ObjectGroup->new >>

Each object group that you manage must be created through this method, which
takes at least two parameters: the C<type> and the C<name> of the object
group. The parameters must be provided in a single hash reference argument,
like so:

 my $g = Net::Cisco::ObjectGroup->new({
     type        => 'network',
     name        => 'my_new_object_group',
     description => 'used for something useful', # optional
 });

Optionally you may also provide a description of the group. For details of
the types of object group available, and additional parameters to this method
that they accept, see L</"GROUP TYPES">, below.

C<Net::Cisco::ObjectGroup> is actually a factory class, and this method
returns an object of the type that you requested in the C<type> parameter. All
objects inherit from C<Net::Cisco::ObjectGroup::Base>, and on success this
method will return an instance of one of the following:

=over 4

=item *

Net::Cisco::ObjectGroup::ICMP

=item *

Net::Cisco::ObjectGroup::Network

=item *

Net::Cisco::ObjectGroup::Protocol

=item *

Net::Cisco::ObjectGroup::Service

=back

=head2 C<push>

Use this method to add an entry to the object group. Although according to
Cisco's documentation order of the content of an object group is not
significant, this module will preseve the order of pushed entries, with new
entries being added to the end of the list of items in the group.

Parameters are all passed within a single hash reference argument. Which keys
of that hash you populate will depend on the type of the object group on which
you are operating.  Logic within the module should check that you are
syntactically correct, but for brevity of this documentation you are referred
to the many Cisco manuals containing object group syntax usage guidelines.

See L</"GROUP TYPES">, below, for parameter specifics.

=head2 C<dump>

This method generates and returns the object group as it would look in a Cisco
configuration file.

The returned value is a scalar, with embedded newline characters and no
terminating newline, so you will need to append that as required. Note that
when submitting this to, for example, a L<Net::Appliance::Session> session via
C<cmd()>, a newline will be automatically appended by that method.

Fully compatible Cisco commands are produced on the fly from the data stored
in the C<Net::Cisco::ObjectGroup> object, so you can C<dump> and C<push>
repeatedly to your heart's content.

=head1 GROUP TYPES

Following Cisco configuration guidelines, there are four types of object group
available to you. Each of them implements a C<push()> object method to
populate the group, with custom parameters as described below.

=head2 ICMP

The C<new> method to C<Net::Cisco::ObjectGroup> will also accept a
C<pretty_print> parameter, which if set to a true value, enables the
substitution of some numeric ICMP types for their text aliases within the
output from C<dump>.

The C<push> method for ICMP object groups accepts the following parameters:

=over 4

=item C<icmp_type>

Fill this value in your parameter hash with an ICMP type. As mentioned above,
it is your responsibility to enter something that the Cisco device will parse
(e.g. a recognised ICMP type name or IANA assigned number).

=item C<group_object>

Use this parameter to refer to another ICMP object group in this group entry.

=back

=head2 Network

The C<push> method for Network object groups accepts the following parameters:

=over 4

=item C<net_addr>, C<netmask>

At a minimum, if configuring a network address, you must pass the C<net_addr>
parameter. If C<netmask> is omitted, then the C<net_addr> is assumed to be a
host address (32 bit netmask). Otherwise, specify a netmask in C<netmask>.

=item C<group_object>

Use this parameter to refer to another Network object group in this group
entry.

=back

=head2 Protocol

The C<new> method to C<Net::Cisco::ObjectGroup> will also accept a
C<pretty_print> parameter, which if set to a true value, enables the
substitution of some protocol numbers for their text aliases within the output
from C<dump>.

The C<push> method for Protocol object groups accepts the following
parameters:

=over 4

=item C<protocol>

Fill this value in your parameter hash with a protocol type. As mentioned
above, it is your responsibility to enter something that the Cisco device will
parse (e.g. a recognised protocol name or IANA assigned number).

=item C<group_object>

Use this parameter to refer to another Protocol object group in this group
entry.

=back

=head2 Service

The C<new> method to C<Net::Cisco::ObjectGroup> will also accept a
C<pretty_print> parameter, which if set to a true value, enables the
substitution of some port numbers for their corresponding service names within
the output from C<dump>.

The C<new> method for Service object groups I<requires> the following
additional parameter:

=over 4

=item C<protocol>

Service object groups must be specified with any of three possible IP protocol
groups, C<tcp>, C<udp> or C<tcp-udp> in this parameter.

=back

The C<push> method for Service object groups accepts the following parameters:

=over 4

=item C<svc_op>, C<svc>, C<svc_hi>

If specifying one or more services (rather than a group, as below), then at a
minimum the C<svc_op> and C<svc> parameters must be completed. C<svc_op> may
be either C<eq> or C<range>, and if the latter then C<scv_hi> must also
contain the corresponding service to make a range.

As mentioned above, it is your responsibility to enter values for C<svc> and
C<svc_hi> that the Cisco device will parse (e.g. a recognised service name or
IANA assigned number).

=item C<group_object>

Use this parameter to refer to another Service object group in this group
entry.

=back

You may encounter the following diagnostic messages from Protocol groups:

=over 4

=item C<missing parameter "protocol" when creating service group>

This is a required parameter to the C<new()> class method when specifying an
object group type of C<service> (or C<port>).

=item C<unrecognized protocol type:>...

You have used an unrecognized value for the C<protocol> parameter to C<new()>.

=item C<missing service operator>

The C<svc_op> parameter is missing in your call to C<push()>.

=item C<unrecognized service operator:>...

You have used an unrecognized value for the C<svc_op> parameter to C<push()>.

=back

=head1 DIAGNOSTICS

=over 4

=item C<must specify either group-object or>...

At a minimum please supply an object group or other required parameter.

=item C<cannot specify both group-object and>...

Likewise you should not specify I<both> an object group and type-specific
paramters.

=item C<bad group-object>

Referenced object groups must be of the same type as the group they are
referenced from.

=item C<missing parameter "type">

You forgot to specify the C<type> parameter to C<<
Net::Cisco::ObjectGroup->new >>.

=item C<unrecognized object-group type:>...

The group type must be one of C<icmp>, C<network>, C<protocol>, C<service> or
C<port>.

=item C<missing parameter "name">

You forgot to specify the C<name> parameter to C<<
Net::Cisco::ObjectGroup->new >>.

=item C<bad object-group name:>...

Object group names must be between one and 64 characters comprising only
upper and lowercase letters, digits, underscore, period and hyphen.

=item C<bad description>

The length of the description must not exceed 200 characters.

=back

=head1 DEPENDENCIES

Other than the contents of the standard Perl distribution, you will need the
following:

=over 4

=item *

UNIVERSAL::require

=item *

Class::Data::Inheritable

=item *

Class::Accessor >= 0.25

=back

=head1 BUGS

If you spot a bug or are experiencing difficulties that are not explained
within the documentation, please send an email to oliver@cpan.org or submit a
bug to the RT system (http://rt.cpan.org/). It would help greatly if you are
able to pinpoint problems or even supply a patch.

=head1 SEE ALSO

L<Net::Cisco::AccessList::Extended>, L<Net::Appliance::Session>

=head1 AUTHOR

Oliver Gorwits C<< <oliver.gorwits@oucs.ox.ac.uk> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) The University of Oxford 2008.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
