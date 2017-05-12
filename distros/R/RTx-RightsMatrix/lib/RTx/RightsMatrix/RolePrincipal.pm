package RTx::RightsMatrix::RolePrincipal;

use strict;

use RT::Groups;

=head1 NAME

RTx::RightsMatrix::RolePrincipal - A fake RT Principal for querying role rights

=head1 SYNOPSIS

Point, click, drool

=head2 Documentation

Patches are wellcome.

=head2 Todo

=head2 Repository

You can find repository of this project at
L<svn://svn.chaka.net/RTx-RightsMatrix>

=head1 AUTHOR

        Todd Chapman <todd@chaka.net>

=cut

sub new {
    my $self = {};
    bless $self, shift;
    $self->{Role} = shift;
    return $self;
}

sub IsUser { 0; }

sub IsGroup { 1; }

sub Object { shift; }

sub Name { my $self = shift; $self->{Role} . ' Role'; }

sub Id { my $self = shift; $self->{Role} . '-Role'; }

sub id { my $self = shift; $self->{Role} . '-Role'; }

sub HasRight {
    my $self = shift;

    my %args = @_;
    # role accounts don't have permission on custom fields
    if (ref($args{Object}) eq 'RT::CustomField') {
        return 0;
    }
    #get the real principal and ask it
    my $principal = $self->_RealPrincipal(@_);

    if ($principal) {
#$RT::Logger->debug("Role: " . $self->{Role} . " Object: " . $args{Object}->id . " Group: " . $principal->id);
        return $principal->HasRight(@_);
    }
    return 0;
}

sub _HasDirectRight {
    my $self = shift;

    my %args = @_;
    # role accounts don't have permission on custom fields
    if (ref($args{Object}) eq 'RT::CustomField') {
        return 0;
    }
    #get the real principal and ask it
    my $principal = $self->_RealPrincipal(@_);

    if ($principal) {
#$RT::Logger->debug("Role: " . $self->{Role} . " Object: " . $args{Object}->id . " Group: " . $principal->id);
        return $principal->_HasDirectRight(@_);
    }
    return 0;

}

sub GrantRight {
    my $self = shift;

    my $principal = $self->_RealPrincipal(@_);
    return $principal->GrantRight(@_);
}

sub RevokeRight {
    my $self = shift;

    my $principal = $self->_RealPrincipal(@_);
    return $principal->RevokeRight(@_);
}

sub _RealPrincipal {
    my $self = shift;

    my %args = @_;
    #get the real principal
    my $groups = RT::Groups->new($RT::SystemUser);
    $groups->Limit(FIELD => 'Domain',   VALUE => ref($args{Object}) . '-Role' );
    $groups->Limit(FIELD => 'Instance', VALUE => (ref($args{Object}) =~ /::System$/) ? 0 : $args{Object}->id );
    $groups->Limit(FIELD => 'Type',     VALUE => $self->{Role} );

    if ($groups->Count) {
        return $groups->First->PrincipalObj;
    }
    else {
        $RT::Logger->debug("No group found for Domain: " . ref($args{Object}) . '-Role Instance: ' . $args{Object}->id . ' Type: ' . $self->{Role});
    }
    return;
}

1;
