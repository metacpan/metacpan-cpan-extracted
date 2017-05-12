package OpusVL::AppKit::Controller::AppKit::User;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config
(
    appkit_myclass              => 'OpusVL::AppKit',
);


sub change_password
    : Path('changepword')
    : Args(0)
    : AppKitForm("appkit/user/change_password.yml")
    : AppKitFeature('Password Change')
{
    my ($self, $c ) = @_;

    if ( $c->stash->{form}->submitted_and_valid )
    {
        my $password = $c->req->params->{'password'};

        $c->user->update( { password => $password } );
        $c->stash->{hide_form} = 1;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Controller::AppKit::User

=head1 VERSION

version 2.29

=head2 change_password

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
