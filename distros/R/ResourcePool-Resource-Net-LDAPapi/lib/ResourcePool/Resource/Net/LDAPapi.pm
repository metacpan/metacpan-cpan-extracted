# Original ResourcePool::Resource::Net::LDAP:
#*********************************************************************
#*** ResourcePool::Resource::Net::LDAP
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*********************************************************************

=head1 NAME

ResourcePool::Resource::Net::LDAPapi - A L<ResourcePool|ResourcePool> wrapper for L<Net::LDAPapi|Net::LDAPapi>

=head1 SYNOPSIS
 
 use ResourcePool::Resource::Net::LDAPapi;
 
 my $resource = ResourcePool::Resource::Net::LDAPapi->new(
                   $factory,
                   [@NamedBindOptions],
                   [@NamedNewOptions]);

=head1 DESCRIPTION

This class is used by the L<ResourcePool|ResourcePool> internally to create L<Net::LDAPapi|Net::LDAPapi> connections. It's called by the corresponding L<ResourcePool::Factory::Net::LDAPapi|ResourcePool::Factory::Net::LDAPapi> object which passes the parameters needed to establish the L<Net::LDAPapi|Net::LDAPapi> connection.

The only thing which has to been known by an application developer about this class is the implementation of the L<precheck()|/precheck> and L<postcheck()|/postcheck> methods:

=head1 API

=over 4

=cut

package ResourcePool::Resource::Net::LDAPapi;

use vars qw($VERSION @ISA);
use strict;
use Net::LDAPapi qw(LDAP_SUCCESS);
use ResourcePool::Resource;

$VERSION = "1.00";
push @ISA, "ResourcePool::Resource";

sub new($$$@) {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new();

    $self->{Factory} = shift;
    $self->{BindOptions} = defined $_[0] ? shift: [];
    my $NewOptions = defined $_[0] ? shift: [];

    $self->{ldaph} = Net::LDAPapi->new(@{$NewOptions});
    if (! defined $self->{ldaph}) {
        swarn("ResourcePool::Resource::Net::LDAPapi: ".
              "Connect to '%s' failed: $@\n", 
              $self->{Factory}->info());
        return undef;
    }
    
    bless($self, $class);

    # bind returns $self on success
    return $self->bind($self->{BindOptions});
}

sub close($) {
    my ($self) = @_;
    #$self->{ldaph}->unbind();
}

sub fail_close($) {
    my ($self) = @_;
    swarn("ResourcePool::Resource::Net::LDAPapi: ".
          "closing failed connection to '%s'.\n",
          $self->{Factory}->info());
}

sub get_plain_resource($) {
    my ($self) = @_;
    return $self->{ldaph};
}

sub DESTROY($) {
    my ($self) = @_;
    $self->close();
}

=item S<$resource-E<gt>precheck>

Performs a bind(), either anonymous or with dn and password (depends on the arguments to L<ResourcePool::Factory::Net::LDAPapi|ResourcePool::Factory::Net::LDAPapi>).

Returns true on success and false if the bind failed (regardless of the reason)

=cut 

sub precheck($) {
    my ($self) = @_;
    return $self->bind($self->{BindOptions});
}

=item S<$resource-E<gt>postcheck>

Does not implement any postcheck().

Returns always true

=cut

sub bind($$) {
    my ($self, $bindopts) = @_;
    my @BindOptions = @{$bindopts};
    
    if ($self->{ldaph}->bind_s(@BindOptions) != LDAP_SUCCESS) {
        swarn("ResourcePool::Resource::Net::LDAPapi: ".
              "Bind to '%s' failed: %s\n", $self->{Factory}->info(), $self->{ldaph}->errstring);
        delete $self->{ldaph};
        return undef;
    }
    return $self;
}


sub swarn($@) {
    my $fmt = shift;
    warn sprintf($fmt, @_);
}

=back

=head1 SEE ALSO

L<Net::LDAPapi|Net::LDAPapi>,
L<ResourcePool|ResourcePool>,
L<ResourcePool::Resource|ResourcePool::Resource>,
L<ResourcePool::Factory::Net::LDAPapi|ResourcePool::Factory::Net::LDAPapi>

=head1 AUTHOR

=head2 ResourcePool::Resource::Net::LDAPapi

Copyright (C) 2015 by Phillip O'Donnell <podonnell@cpan.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head2 Portions based on L<ResourcePool::Resource::Net::LDAP|ResourcePool::Resource::Net::LDAP>

Copyright (C) 2001-2003 by Markus Winand <mws@fatalmind.com>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

		
1;
