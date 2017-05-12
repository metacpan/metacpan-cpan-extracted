package RT::Authen::ExternalAuth::DBI::Cookie;

use CGI::Cookie;

use strict;

=head1 NAME

RT::Authen::ExternalAuth::DBI::Cookie - Database-backed, cookie SSO source for RT authentication

=head1 DESCRIPTION

Provides the Cookie implementation for L<RT::Authen::ExternalAuth>.

=head1 SYNOPSIS

    Set($ExternalSettings, {
        # An example SSO cookie service
        'My_SSO_Cookie'  => {
            'type'            =>  'cookie',
            'name'            =>  'loginCookieValue',
            'u_table'         =>  'users',
            'u_field'         =>  'username',
            'u_match_key'     =>  'userID',
            'c_table'         =>  'login_cookie',
            'c_field'         =>  'loginCookieValue',
            'c_match_key'     =>  'loginCookieUserID',
            'db_service_name' =>  'My_MySQL'
        },
        'My_MySQL' => {
            ...
        },
    } );

=head1 CONFIGURATION

Cookie-specific options are described here. Shared options
are described in the F<etc/RT_SiteConfig.pm> file included
in this distribution.

The example in the L</SYNOPSIS> lists all available options
and they are described below.

=over 4

=item name

The name of the cookie to be used.

=item u_table

The users table.

=item u_field

The username field in the users table.

=item u_match_key

The field in the users table that uniquely identifies a user
and also exists in the cookies table. See c_match_key below.

=item c_table

The cookies table.

=item c_field

The field that stores cookie values.

=item c_match_key

The field in the cookies table that uniquely identifies a user
and also exists in the users table. See u_match_key above.

=item db_service_name

The DB service in this configuration to use to lookup the cookie
information. See L<RT::Authen::ExternalAuth::DBI>.

=back

=cut

# {{{ sub GetCookieVal
sub GetCookieVal {

    # The name of the cookie
    my $cookie_name = shift;
    my $cookie_value;

    # Pull in all cookies from browser within our cookie domain
    my %cookies = CGI::Cookie->fetch();

    # If the cookie is set, get the value, if it's not set, get out now!
    if (defined $cookies{$cookie_name}) {
      $cookie_value = $cookies{$cookie_name}->value;
      $RT::Logger->debug(  "Cookie Found",
                           ":: $cookie_name");
    } else {
        $RT::Logger->debug( "Cookie Not Found");
    }

    return $cookie_value;
}

# }}}

1;
