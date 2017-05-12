#===============================================================================
#      PODNAME:  Net::IP::Identifier_Role
#     ABSTRACT:  The role that Net::IP::Identifier plugins must satisfy
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Mon Oct  6 12:25:04 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier_Role;

use Role::Tiny;
use Net::IP;
use Net::IP::Identifier::Net;

our $VERSION = '0.111'; # VERSION

requires qw( new name );

use overload '""' => sub { shift->name };

sub ips {
    my ($self, @new) = @_;

    if (@_ > 1) {
        for (my $ii = 0; $ii < @new; $ii++) {
            my $cidr = $new[$ii];
            my $ip;
            if (ref $cidr) {    # already a Net::IP or Net::IP::Identifier::Net
                $ip = $cidr;
                if (ref $ip eq 'Net::IP') {
                    # convert Net::IP to Net::IP::Identifier::Net
                    $ip = Net::IP::Identifier::Net->new($ip);
                }
            }
            else {
                if (defined $new[$ii + 1] and
                    not ref $new[$ii + 1] and
                    $new[$ii + 1] eq '-' and
                    defined $new[$ii + 2]) {
                    $cidr = "$cidr - $new[$ii + 2]";
                    $ii += 2;
                }
                $ip = Net::IP::Identifier::Net->new($cidr)
            }
            $self->{ips}{"$ip"} = $ip if ($ip); # stringify $ip for key
        }
    }

    return wantarray
    ? values %{$self->{ips}}
    : $self->{ips};
}

sub cidrs {
    my ($self, @new) = @_;

    return wantarray
    ? keys %{$self->{ips}}
    : $self->{ips};
}

sub identify {
    my ($self, $ip, $replacement) = @_;

    $ip = Net::IP::Identifier::Net->new($ip) if (not ref $ip);
    for my $net (values %{$self->ips}) {
        # if different versions, can't be overlap (unless entity gets
        # some ::ffff:N:N:N:N/N blocks which seems unlikly)
        next if ($net->version ne $ip->version);
        my $overlap = $ip->overlaps($net);
        if ($overlap == $IP_IDENTICAL or
            $overlap == $IP_A_IN_B_OVERLAP) {
            return $net if ($self->cidr_id);
            return $replacement || $self;
        }
    }
    return; # undef, doesn't belong to entity
}

sub cidr_id {
    my ($self, @new) = @_;

    if (@_ > 1) {
        $self->{cidr_id} = $new[0];
    }
    return $self->{cidr_id};
}

sub refresh {
    # stub, may be overridden by entities to refresh the ips array
}

sub children {
    # stub, entities with children should return an array of the names here
    # (and the child netblocks should not be listed in the parent)
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier_Role - The role that Net::IP::Identifier plugins must satisfy

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 package Net::IP::Identifier::Plugin::My_Entity;

 use Role::Tiny::With;
 with Net::IP::Identifier_Role; # each Entity must satisfy this role

 use Net::IP::Identifier::Net;

 sub new {  # constructor
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    $self->ips( ... );  # set the array of Net::IP::Identifier::Net objects for this entity
    return $self;
 }

 sub name {
    return 'My_Entity';
 }

 1;

=head1 DESCRIPTION

Each entity included as a Net::IP::Identifier::Plugin module must satisfy
the Net::IP::Identifier_Role, as per the SYNOPSYS above.  The module must
provide a method named B<ips> which returns an array (or ref to an array in
scalar context) of the Net::IP::Identifier::Net objects representing the IPs and network
blocks that make up the entity.

Net::IP::Identifier_Role adds the B<identify> method used to check whether
an IP belongs to an entity, and an B<ips> method for creating the array of
IPs and netowrk blocks representing the entity, converting strings to
Net::IP::Identifier::Net objects (and vice versa) as necessary.

=head2 Required Methods

This role requires two methods: a B<new> constructor and a B<name>.
Typically, an entity consuming this role will set its collection of
B<ips> in its B<new> constructor.

=over

=item new( [ options ] );

Net::IP::Identifier will not pass any options, but they might be useful for
stand-alone construction.

=item name

Must return a string representing the name of the entity.  It's probably a
good idea to keep this short, with no spaces.

=back

=head2 Provided Methods

=over

=item ips ( [ @new ] )

This method is provided by the Net::IP::Identifier_Role, but you may
override it if you need different functionality.  It must return an array
of Net::IP::Identifier::Net objects that represent the entity.

The IPs are actually stored as a hash, where the key is the string
representation and the values are the Net::IP::Identifier::Net objects.  When called in
scalar context, B<ips> returns the reference to the hash.

If B<@new> is defined, each element must be either a Net::IP or
Net::IP::Identifier::Net object, or a form acceptable to
Net::IP::Identifier::Net(or Net::IP)->new.  The current hash of IPs is
replaced by the B<@new> list.

=item identify($ip, [ $replacement ] )

Match B<$ip> against all of the Net::IP::Identifier::Net objects in the entity.
B<$ip> must be in the same form as described above in B<ips>.

If no match is found, returns undef.

If a match is found, the entity object (which stringifies to the entity's
B<name>) is returned, unless B<$replacement> is defined, it which case it is
returned.

=item cidrs

A convenience method to return just the keys of the B<ips> hash.  In scalar
context, returns the reference to the hash (same as B<ips>).

=item cidr_id

This accessor/method sets or clears a flag that modifies the return value
of the B<identify> method.  When clear, the return value of B<identify> is
the entity object (which stringifies to the entities B<name> method).  When
set, the returned object is instead the Net::IP::Identifier::Net object
(which stringifies to the B<print> method).

=item refresh

A stub.

If there is a programatic method to fetch a new list of IPs and netblocks,
and entity can override the B<refresh> method.

This method should be called judiciously as it may be fairly network
intensive.  Also, many entities may not provide such a method.  See
Net::IP::Identifier::Google for an example.

=back

=head1 SEE ALSO

=over

=item Net::IP::Identifier

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
