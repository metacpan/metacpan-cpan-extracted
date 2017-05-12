package OpusVL::AppKit::FormFu::Constraint::AppKitUsername;

use strict;
use base 'HTML::FormFu::Constraint';

sub user_stashkey { my $self = shift; my ( $key ) = @_; $self->{user_stashkey} = $key; }

sub constrain_value
{
    my $self                = shift;
    my ( $value, $params)   = @_;
    my $c                   = $self->form->stash->{context};
    my $stashkey            = $self->{user_stashkey} || 'user';
    my $existing            = $c->stash->{$stashkey}->id if ( exists $c->stash->{$stashkey} );
    my $matched             = $c->model('AppKitAuthDB::User')->search( { username => $value, ( $existing ? ( id => { '!=' => $existing } ) : () ) } )->count;
    $self->{message} = "Username already in use";
    return ( $matched > 0 ) ? 0 : 1;
}

##
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::FormFu::Constraint::AppKitUsername

=head1 VERSION

version 2.29

=head1 SYNOPSIS

    - type: Text
      name: username
      constraints:
        - type: '+OpusVL::AppKit::FormFu::Constraint::AppKitUsername'
          user_stashkey: user_for_update

=head1 DESCRIPTION

Ensures that duplicate user names aren't created.

To find existing user (the one we might be updating, therefore the username WILL exist) we check the 
context stash (Catalyst context) and look for stash key identified by 'user_stashkey'.

If the 'user' is in the stash, it will asume it to be a dbix object, pull its id and 
ignore that id when checking for existing usernames.

=head2 Adding a user.

Nothing required except and AppKitAuthDB model, which should be in every AppKit app.

=head2 Updating a user.

In the Catalyst stash there must be:
    'user'        - dbix object for the User.

=head1 NAME

OpusVL::AppKit::FormFu::Constraint::AppKitUsername - Username contraint for the AppKitAuthDB model.

=head1 METHODS

=head2 user_stashkey

Sets the key used to find an existing user in the context stash.

=head2 constrain_value

This method is used by formfu to hook into this constraints, constraining code.

Returns:
    boolean     - 0 = did not validate, 1 = validated

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
