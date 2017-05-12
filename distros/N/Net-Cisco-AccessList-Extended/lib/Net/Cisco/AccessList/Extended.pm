package Net::Cisco::AccessList::Extended;
use base qw(Class::Accessor::Fast);

# generates Cisco extended access-lists

use strict;
use warnings FATAL => 'all';

our $VERSION = '1.01';
$VERSION = eval $VERSION; # numify for warning-free dev releases

use List::MoreUtils qw(any);
use Carp;

__PACKAGE__->mk_ro_accessors(qw(_name _acls));
# okay, this is a little sly... _acls is read-only but because it's an array
# reference we can push items onto the array without writing to the accessor

# ===========================================================================

# initialize the ACL rules list and private attr
sub new {
    my ($class, $name) = @_;

    croak 'missing parameter for list name' if !defined $name;

    my $self = $class->SUPER::new({
        _name => $name,
        _acls => [],
    });
    bless ($self, $class);  # reconsecrate into __PACKAGE__

    return $self;
}

# Add a new rule to our ACL rule list, specified by parameters in hash.
sub push {
    my ($self, $arg_ref) = @_;

    croak 'missing parameter "access"' if !defined $arg_ref->{access};
    croak 'missing parameter "proto" or "proto_og"'
        if !defined $arg_ref->{proto} and !defined $arg_ref->{proto_og};

    croak 'cannot specify both protocol and protocol group'
        if defined $arg_ref->{proto} and defined $arg_ref->{proto_og};

    croak 'missing source network address'
        if defined $arg_ref->{src_mask} and !defined $arg_ref->{src_ip};
    croak 'missing destination network address'
        if defined $arg_ref->{dst_mask} and !defined $arg_ref->{dst_ip};

    croak 'cannot specify both source network and network group'
        if defined $arg_ref->{src_ip} and defined $arg_ref->{src_og};
    croak 'cannot specify both destination network and network group'
        if defined $arg_ref->{dst_ip} and defined $arg_ref->{dst_og};

    croak 'missing low service for source service range'
        if defined $arg_ref->{src_svc_hi} and !defined $arg_ref->{src_svc};
    croak 'missing source service operator'
        if defined $arg_ref->{src_svc} and !defined $arg_ref->{src_svc_op};
    croak 'cannot specify both source service and service group'
        if defined $arg_ref->{src_svc_op} and defined $arg_ref->{src_svc_og};

    croak 'missing low service for destination service range'
        if defined $arg_ref->{dst_svc_hi} and !defined $arg_ref->{dst_svc};
    croak 'missing destination service operator'
        if defined $arg_ref->{dst_svc} and !defined $arg_ref->{dst_svc_op};
    croak 'cannot specify both destination service and service group'
        if defined $arg_ref->{dst_svc_op} and defined $arg_ref->{dst_svc_og};

    croak 'cannot specify both icmp type and icmp group'
        if defined $arg_ref->{icmp} and defined $arg_ref->{icmp_og};
    croak 'cannot use icmp with services'
        if (defined $arg_ref->{icmp} or defined $arg_ref->{icmp_og})
        and (defined $arg_ref->{src_svc_op}
             or defined $arg_ref->{src_svc_og}
             or defined $arg_ref->{dst_svc_op}
             or defined $arg_ref->{dst_svc_og});


    my ($proto, $src, $dst, $ssvc, $dsvc, $icmp, $line);
    $ssvc = $dsvc = $icmp = ''; # optionals

    my $name = $self->_name;
    my $acls = $self->_acls;

    $arg_ref->{access} =
        $arg_ref->{access} =~ m/^(?:[Pp]ermit|1)$/ ? 'permit' : 'deny';

    $proto = defined $arg_ref->{proto} ? $arg_ref->{proto}
                                       : "object-group $arg_ref->{proto_og}";

    $src = defined $arg_ref->{src_og}   ? "object-group $arg_ref->{src_og}"
         : defined $arg_ref->{src_mask} ? "$arg_ref->{src_ip} $arg_ref->{src_mask}"
         : defined $arg_ref->{src_ip}   ? "host $arg_ref->{src_ip}"
         :                                "any"
         ;

    $dst = defined $arg_ref->{dst_og}   ? "object-group $arg_ref->{dst_og}"
         : defined $arg_ref->{dst_mask} ? "$arg_ref->{dst_ip} $arg_ref->{dst_mask}"
         : defined $arg_ref->{dst_ip}   ? "host $arg_ref->{dst_ip}"
         :                                "any"
         ;

    $ssvc = " object-group $arg_ref->{src_svc_og}"
        if defined $arg_ref->{src_svc_og};
    $ssvc = " $arg_ref->{src_svc_op} $arg_ref->{src_svc}"
        if defined $arg_ref->{src_svc_op};
    $ssvc .= " $arg_ref->{src_svc_hi}" if defined $arg_ref->{src_svc_hi};

    $dsvc = " object-group $arg_ref->{dst_svc_og}"
        if defined $arg_ref->{dst_svc_og};
    $dsvc = " $arg_ref->{dst_svc_op} $arg_ref->{dst_svc}"
        if defined $arg_ref->{dst_svc_op};
    $dsvc .= " $arg_ref->{dst_svc_hi}" if defined $arg_ref->{dst_svc_hi};

    $icmp = " object-group $arg_ref->{icmp_og}"
        if defined $arg_ref->{icmp_og};
    $icmp = " $arg_ref->{icmp}" if defined $arg_ref->{icmp};

    $line = sprintf "access-list $name extended %s %s %s%s %s%s%s",
        $arg_ref->{access}, $proto, $src, $ssvc, $dst, $dsvc, $icmp;

    push @$acls, $line;
    # see, we don't need to store $acls back into _acls here

    return $self;
}

# return our current ACL rule list.
sub dump {
    my $self = shift;

    return join "\n", @{$self->_acls};
}

1;

=head1 NAME

Net::Cisco::AccessList::Extended - Generate Cisco extended access-lists

=head1 VERSION

This document refers to version 1.01 of Net::Cisco::AccessList::Extended.

=head1 SYNOPSIS

 use Net::Cisco::AccessList::Extended;
 my $l = Net::Cisco::AccessList::Extended->new('INCOMING_LIST');
 
 $l->push({
     access  => 'permit',
     proto   => 'ip',
     src_og  => 'friendly_net',
     dst_og  => 'local_net',
 });
 
 print $l->dump, "\n";
 # prints the access-list commands to STDOUT, something like:
 
 access-list INCOMING_LIST extended permit ip object-group friendly_net object-group local_net

=head1 DESCRIPTION

Use this module to manage the presentation of Cisco Extended Access Lists.
List entries are pushed into the object in a simple parmaterized fashion, and
you can then dump the list in a format that is parsable by Cisco devices.

Support is included for list entries that reference Object Groups (as used by
more recent PIX OS and FWSM software versions).

=head1 IMPORTANT NOTE

This module's error checking is only concerned with B<syntactic correctness>.
It makes no judgement of the I<semantic correctness> of your list entries.

For instance, newer FWSM systems use netmasks specified in terms of host
address network masks (e.g. C<255.255.255.0>), whereas older systems use
wildcard bits (e.g. C<0.0.0.255>). C<Net::Cisco::AccessList::Extended> will
not check that you use the correct type of mask, or even that your mask isn't
something completely inappropriate (e.g. C<cabbages>).

=head1 METHODS

=head2 C<< Net::Cisco::AccessList::Extended->new >>

Each access list that you manage must be created through this method, which
takes one parameter, the name of the access list.

On success this method returns a newly instatiated
C<Net::Cisco::AccessList::Extended> object. Lucky you.

=head2 C<push>

Use this method to add an access list entry (sometimes called an Access
Control Entry by Cisco documentation) to the end of an access list. In case it
is not obvious, access lists are ordered, so I<pushing> an entry means it is
added to the I<end> of the list.

Parameters are all passed within a single hash reference argument. Which keys
of that hash you populate will depend on the Access Control Entry (hereafter,
ACE) that you are appending to the access list. Logic within the module should
check that you are syntactically correct, but for brevity of this
documentation you are referred to the many Cisco manuals containing ACE syntax
usage guidelines.

Possible keys and values are as follows:

=over 4

=item C<access>

This parameter is required and dictates whether the ACE will be a I<permit> or
I<deny> rule, with the following values being interpreted as meaning
C<permit>:

 Permit | permit | 1

Any other value in this slot is taken to be a request for a C<deny> statement.

=item C<proto> or C<proto_og>

Network protocol. As mentioned above, it is your responsibility to enter
something that the Cisco device will parse (e.g. a recognised protocol name or
IANA assigned number, or protocol object group). This parameter is required.

=item C<src_ip>, C<src_mask> or C<src_og>

Source network. Various combinations of these three keys are permitted.
Omitting them all results in the keyword C<any> being used. Only providing the
C<src_ip> is allowed, as well as providing both the C<src_ip> and C<src_mask>.
I<Alterntively> you may specify an object group in the C<src_og> slot.

=item C<src_svc_op>, C<src_svc>, C<src_svc_hi> or C<src_svc_og>

Source port(s). Again, various combinations of these keys are permitted. A
service (aka I<port>) object group is used by I<only> filling the
C<src_svc_og> slot.  Otherwise, C<src_svc_op> is required and is the service
operator (e.g. C<gt>, C<eq>, etc). C<src_svc> is the service name or IANA
assigned port number, and if the operator is C<range> then the upper port
boundary must be provided in the C<src_svc_hi> slot.

=item C<dst_ip>, C<dst_mask> or C<dst_og>

These keys function identically to their C<src_> counterparts, but of course
control the production of destination network address fields.

=item C<dst_svc_op>, C<dst_svc>, C<dst_svc_hi> or C<dst_svc_og>

These keys function identically to their C<src_> counterparts, but of course
control the production of destination service fields.

=item C<icmp> or C<icmp_og>

Any value in this slot will be appended to the ACE, so that you can limit the
match to a particular ICMP message type if the rule's protocol is C<icmp>. Use
C<icmp_og> if your value is the name of an icmp object group.

=back
 
On success this method returns its own object. On failure this module will
C<die>.

=head2 C<dump>

This method generates and returns the access list as it would look in a Cisco
configuration file.

The returned value is a scalar, with embedded newline characters and no
terminating newline, so you will need to append that as required. Note that
when submitting this to, for example, a L<Net::Appliance::Session> session via
C<cmd()>, a newline will be automatically appended by that method.

Fully compatible Cisco commands are produced on the fly from the data stored
in the C<Net::Cisco::AccessList::Extended> object, so you can C<dump> and
C<push> repeatedly to your heart's content.

=head1 DIAGNOSTICS

=over 4

=item C<missing parameter for list name>

You have not provided the required parameter to C<new()>, see L</"METHODS">.

=item Various other C<missing...> or C<cannot...> messages

These are generated by the internal syntax checking routine, which will alert
you to conflicting parameters passed to the C<push> object method.

=back

=head1 DEPENDENCIES

Other than the contents of the standard Perl distribution, you will need the
following:

=over 4

=item *

Class::Accessor::Fast (bundled with Class::Accessor)

=item *

List::MoreUtils

=back

=head1 SEE ALSO

L<Net::Cisco::ObjectGroup>, L<Net::Appliance::Session>

=head1 AUTHOR

Oliver Gorwits C<< <oliver.gorwits@oucs.ox.ac.uk> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) The University of Oxford 2008.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

