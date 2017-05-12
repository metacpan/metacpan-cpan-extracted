# Original ResourcePool::Factory::Net::LDAP:
#*********************************************************************
#*** ResourcePool::Resource::Net::LDAP
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*********************************************************************

=head1 NAME

ResourcePool::Factory::Net::LDAPapi - A L<Net::LDAPapi|Net::LDAPapi> Factory for L<ResourcePool|ResourcePool>

=head1 SYNOPSIS

 use ResourcePool::Factory::Net::LDAPapi;
 
 my $factory = ResourcePool::Factory::Net::LDAPapi->new([NewOptions]);

=head1 DESCRIPTION

This class is a factory class for L<Net::LDAPapi|Net::LDAPapi> resources to be used with the L<ResourcePool|ResourcePool>.

Please have a look at the L<ResourcePool::Factory|ResourcePool::Factory> documentation to learn about the purpose of such a factory.

=head1 API

=over 4

=cut

package ResourcePool::Factory::Net::LDAPapi;

use strict;
use vars qw($VERSION @ISA);

use ResourcePool::Factory;
use ResourcePool::Resource::Net::LDAPapi;
use Data::Dumper;

push @ISA, "ResourcePool::Factory";
$VERSION = "1.00";

=item S<ResourcePool::Factory::Net::LDAPapi-E<gt>new($hostname)>

=item S<ResourcePool::Factory::Net::LDAPapi-E<gt>new($hostname, $port)>

=item S<ResourcePool::Factory::Net::LDAPapi-E<gt>new(-host =E<gt> $hostname, -port =E<gt> $port)>

=item S<ResourcePool::Factory::Net::LDAPapi-E<gt>new(-url =E<gt> $url)>

All parameters passed to C<new()> are passed to C<Net::LDAPapi-E<gt>new()>. See L<Net::LDAPapi|Net::LDAPapi> for full list.

=cut

####
# Some notes about the singleton behavior of this class.
# 1. the constructor does not return a singleton reference!
# 2. there is a seperate function called singelton() which will return a
#    singleton reference
# this change was introduces with ResourcePool 0.9909 to allow more flexible
# factories (e.g. factories which do not require all parameters to their 
# constructor) an example of such an factory is the Net::LDAP factory.

sub new($@) {
    my ($proto) = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new();
    
    if (! exists($self->{host})) {
        if (defined $_[0] && ref($_[0]) ne "ARRAY") {
            $self->{BindOptions} = [];
            $self->{NewOptions}  = [@_];
        }
    }
    
    bless($self, $class);

    return $self->bind($self->{BindOptions});
}

=item S<$factory-E<gt>bind("dn", "password")>

=item S<$factory-E<gt>bind(-dn =E<gt> "dn", -password =E<gt> "password")>

All parameters passed to C<bind()> are passed to C<Net::LDAPapi-E<gt>bind_s()>. See L<Net::LDAPapi|Net::LDAPapi> for full list.

Please note that this module will always do a bind to the LDAP server, if you do not specify any bind arguments the bind will be anonymously. The C<bind()> call is used to check the vitality of the LDAP connection, if it fails L<ResourcePool|ResourcePool> will throw it away..

=cut

sub bind($@) {
    my $self = shift;
    $self->{BindOptions} = [@_];
    return $self;
}

sub mk_singleton_key($) {
    my $d = Data::Dumper->new([$_[0]]);
    $d->Indent(0);
    $d->Terse(1);
    return $d->Dump();
}


sub create_resource($) {
    my ($self) = @_;
    return ResourcePool::Resource::Net::LDAPapi->new($self     
            , $self->{BindOptions}
            , $self->{NewOptions}
    );
}

sub info($) {
    my ($self) = @_;
    my $dn;

    if (scalar(@{$self->{BindOptions}}) % 2 == 0) {
        # even numer -> old Net::LDAP->bind syntax
        my %h = @{$self->{BindOptions}};
        $dn = $h{dn};
    } else {
        # odd numer -> new Net::LDAP->bind syntax
        $dn = $self->{BindOptions}->[0];    
    }
    # if dn is still undef -> anonymous bind
    eturn (defined $dn? $dn . "@" : "" ) . $self->{host};
}

=back

=head1 EXAMPLES
 
 use ResourcePool;
 use ResourcePool::Factory::Net::LDAPapi;
 
 my $factory = ResourcePool::Factory::Net::LDAPapi->new(-host => "ldaphost");
 $factory->bind(-dn => 'cn=admin,dc=example,dc=com', -password => 'secret');

=head1 SEE ALSO

L<Net::LDAPapi|Net::LDAPapi>,
L<ResourcePool|ResourcePool>,
L<ResourcePool::Factory|ResourcePool::Factory>,
L<ResourcePool::Resource::Net::LDAPapi|ResourcePool::Resource::Net::LDAPapi>

=head1 AUTHOR

=head2 ResourcePool::Factory::Net::LDAPapi

Copyright (C) 2015 by Phillip O'Donnell <podonnell@cpan.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head2 Portions based on L<ResourcePool::Factory::Net::LDAP|ResourcePool::Factory::Net::LDAP>

Copyright (C) 2001-2003 by Markus Winand <mws@fatalmind.com>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
