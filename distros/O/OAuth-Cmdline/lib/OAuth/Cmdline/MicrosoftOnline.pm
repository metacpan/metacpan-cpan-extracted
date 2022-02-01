###########################################
package OAuth::Cmdline::MicrosoftOnline;
###########################################
use strict;
use warnings;
use MIME::Base64;
use base qw( OAuth::Cmdline );
use Moo;

our $VERSION = '0.07'; # VERSION
# ABSTRACT: Microsoft Online-specific settings for OAuth::Cmdline

has resource => (
  is => "rw",
  required => 1,
);

###########################################
sub site {
###########################################
    return "microsoft-online";
}

1;

###########################################
sub tokens_get_additional_params {
###########################################
    my( $self, $params ) = @_;

    push(@$params, resource => $self->resource);

    return $params;
}

###########################################
sub update_refresh_token {
###########################################
    my( $self, $cache, $data ) = @_;

    # MS Online returns a new refresh token with every access token.
    # We need to use this new token each time otherwise in 14 days
    # we have to re-authorise. By updating the refresh token, we
    # get 90 days
    $cache->{ refresh_token } = $data->{ refresh_token };

    return ($cache, $data);
}

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuth::Cmdline::MicrosoftOnline - Microsoft Online-specific settings for OAuth::Cmdline

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    my $oauth = OAuth::Cmdline::MicrosoftOnline->new(
        resource => "https://graph.microsoft.com",
        # ...
    );
    $oauth->access_token();

=head1 DESCRIPTION

This class overrides methods of C<OAuth::Cmdline> if Microsoft Online's Web API
requires it.

The parameter 'resource' is mandatory, and is poorly described at L<https://msdn.microsoft.com/en-us/library/azure/dn645542.aspx>. It tells the OAuth API what protected resource you are trying to access. For example, to access Azure Graph (to manage user accounts in Azure AD etc.), the correct resource URI is C<https://graph.microsoft.com>. A URI does not have to be a URL, but Microsoft choose to use URLs for their URIs, so if you are trying to access a different endpoint protected by the Microsoft Online OAuth system, then it will probably look like a URL.

To use this module with Azure AD:

=over

=item *
Make a copy of I<eg/microsoft-online-token-init> somewhere else. You will modify this file in the following steps.

=item *
Sign up for a free Azure account as though you were going to deploy some infrastructure. This creates a free Azure Active Directory in your Azure tenant.

=item *
In the Azure portal, go to B<Default Directory > App registrations>

=item *
Click B<New registration>. Set the B<Name> to whatever you like, and select B<Accounts in this organizational directory only (Default Directory only - Single tenant)>. Set the B<Redirect URI> to I<http://localhost:8082/callback>. Then click B<Register> at the bottom.

=item *
A new page showing the new application is shown. On the B<Overview> page that is showing, under B<Essentials>, you should see the B<Application (client) ID> (a UUID). Copy it and then paste it into microsoft-online-token-init in I<client_id>.

=item *
Still on the same page, click the B<Endpoints> button at the top. Copy the B<OAuth 2.0 authorization endpoint (v1)> into microsoft-online-token-init as I<login_uri>. Copy the B<OAuth 2.0 token endpoint (v1)> into microsoft-online-token-init as I<token_uri>.

=item *
Click B<Certificates & secrets> on the left, then B<New client secret>.

=item *
After naming and saving your secret, take the B<Value> and put it in microsoft-online-token-init as I<client_secret>.

=item *
Click B<API permissions> on the left, then B<Add a permission>. Click the B<Microsoft Graph> tile, then B<Delegated permissions>. Check the box B<Directory > Directory.Read.All> then B<Add permission> at the bottom.

=item *
The new permission is added to the list, but now you have to click B<Grant admin consent for Default Directory> and B<Yes>. Anyone who gets hold of this client secret can now read data in the directory. These are the permissions you need to run the example code in I<eg/microsoft-online-users>. You can revoke them later after testing.

=item *
Run microsoft-online-token-init in a terminal and then go to http://localhost:8082 in a local browser.

=item *
Follow the link. Sign into Microsoft with the same account used with Azure portal, and Accept the Permissions requested.

=back

Your web service will retrieve the tokens and store them. You can then use

    $oauth->access_token()

to get an access token to carry out calls against the Azure Graph API as shown in eg/microsoft-online-users.

Example code is in the eg folder

=head1 AUTHOR

Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Mike Schilli.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
