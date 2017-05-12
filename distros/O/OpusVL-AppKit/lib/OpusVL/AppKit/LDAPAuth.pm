package OpusVL::AppKit::LDAPAuth;

use Moose;
with 'OpusVL::AppKit::RolesFor::Auth';

use Net::LDAP;
use Net::LDAP::Util qw/escape_dn_value/;
use experimental 'smartmatch';

has ldap_server          => (is => 'rw', isa => 'Str', default => 'ldap');

# NOTE: we assume that the dn parts we're given are already correctly escaped if
# necessary.
has user_base_dn    => (is => 'ro', isa => 'Str', default => 'ou=People,dc=opusvl');
has user_field      => (is => 'ro', isa => 'Str', default => 'uid');

sub server
{
    my $self = shift;
    return Net::LDAP->new($self->ldap_server) || die $@;
}


sub check_password
{
    my ($self, $username, $password) = @_;

    my $query = sprintf("(%s=%s)", $self->user_field, escape_dn_value($username));
    my $mesg  = $self->server->search(base => $self->user_base_dn, filter => $query);
    
    foreach my $entry ($mesg->entries) {
        my $login = $self->server->bind($entry->dn, password => $password);
        return 1 unless $login->is_error;
    }
    
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::LDAPAuth

=head1 VERSION

version 2.29

=head1 SYNOPSIS

    my $test = OpusVL::AppKit::LDAPAuth->new({
        ldap_server => 'ldap',
        user_base_dn => 'ou=People,dc=opusvl',
        user_field => 'uid',
    });
    ok $test->check_password($user, $password);

=head1 DESCRIPTION

This class implements the OpusVL::AppKit::RolesFor::Auth to provide a mechanism to 
check a users password via LDAP.

=head2 check_password

Check password is correct for user.

=head1 NAME

OpusVL::AppKit::LDAPAuth

=head1 METHODS

=head2 check_password

This method checks the password for the user using the user_base_dn and user_field
along with the username to construct the dn.  The username will be escaped for you
but the configuration parameters you supply to the object are assumed to already be
escaped.  i.e. a username of "user.name" should just work.

=head1 SEE ALSO

To integrate this with Catalyst you need to add the trait 
L<OpusVL::AppKit::RolesFor::Model::LDAPAuth> to your model and apply the role
L<OpusVL::AppKit::RolesFor::Schema::LDAPAuth> to your schema class.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
