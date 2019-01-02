package Mojolicious::Plugin::BasicAuthPlus;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream;
use Authen::Simple::Password;
use Authen::Simple::Passwd;
use Net::LDAP;

our $VERSION = '0.11.3';

sub register {
    my ($plugin, $app) = @_;

    $app->renderer->add_helper(
        basic_auth => sub {
            my $self = shift;

            # Sent credentials
            my $auth = $self->req->url->to_abs->userinfo || '';

            my ($hash_ref, $status) = $plugin->_check_auth($self, $auth, @_);
            if ($status) {
                return ($hash_ref, $status);
            }
            else {
                # Not verified
                my $realm = $hash_ref->{realm};
                return $plugin->_password_prompt($self, $realm);
            }
        }
    );
}

sub _check_auth {
    my ($plugin, $c, $auth, @params) = @_;

    # Required credentials
    my ($realm, $password, $username) = $plugin->_expected_auth(@params);
    my $callback = $password if ref $password eq 'CODE';
    my $params   = $password if ref $password eq 'HASH';

    # No credentials entered
    return {realm => $realm} if !$auth and !$callback and !$params;

    my ($auth_username, $auth_password) = _split_auth($auth);

    # Hash for return data
    my %data;
    $data{username} = $auth_username if $auth_username;

    # Verification within callback
    return (\%data, 1) if $callback and $callback->(_split_auth($auth));

    # Verified with realm => username => password syntax
    return (\%data, 1) if $auth eq ($username || '') . ":$password";

    # Verified via simple, passwd file, LDAP, or Active Directory.
    if ($auth) {
        if ($params->{'username'} and $params->{'password'}) {
            return (\%data, 1) if $plugin->_check_simple($c, $auth, $params);
        }
        elsif ($params->{'path'}) {
            return (\%data, 1) if $plugin->_check_passwd($c, $auth, $params);
        }
        elsif ($params->{'host'}) {
            my ($ok, $ldap) = $plugin->_check_ldap($c, $auth, $params);
            if ($ldap) {
                $data{ldap} = $ldap;
            }
            return (\%data, 1) if $ok;
        }
    }

    # Not verified
    return {realm => $realm};
}

sub _expected_auth {
    my $self  = shift;
    my $realm = shift;

    return @$realm{qw/ realm password username /} if ref $realm eq "HASH";

    # realm, pass, user || realm, pass, undef || realm, callback
    return $realm, reverse @_;
}

sub _password_prompt {
    my ($self, $c, $realm) = @_;

    $c->res->headers->www_authenticate("Basic realm=\"$realm\"");
    $c->res->code(401);
    $c->rendered;

    return;
}

sub _split_auth {
    # Split $auth into username and password (which may contain ":")
    my ($username, $password) = split ':', $_[0], 2;

    $username = '' unless defined $username;
    $password = '' unless defined $password;

    return ($username, $password);
}

sub _check_simple {
    my ($self, $c, $auth, $params) = @_;
    my ($username, $password) = _split_auth($auth);

    return 1
        if $username eq $params->{'username'}
        and Authen::Simple::Password->check($password, $params->{'password'});
}

sub _check_ldap {
    my ($self, $c, $auth, $params) = @_;
    my ($username, $password) = _split_auth($auth);
    my $logging = $params->{logging} // 0;

    return 0 unless defined $password;

    my $ldap = Net::LDAP->new(
        $params->{host},
        port    => $params->{port} // 389,
        scheme  => $params->{scheme} // 'ldap',
        debug   => $params->{debug} // 0,
        timeout => $params->{timeout} // 120,
        version => $params->{version} // 3,
    );
    unless ($ldap) {
        $c->app->log->warn("Connection to $params->{host} failed: $@")
            if $logging;
        return 0;
    }

    my $socket_type = ref $ldap->{net_ldap_socket};
    $c->app->log->warn("LDAP socket type: $socket_type") if $logging;

    unless (
        # SSL connection already established
        ($socket_type eq 'IO::Socket::SSL')

        # Or user doesn't want TLS
        || (defined($params->{start_tls}) && $params->{start_tls} == 0)
        )
    {
        my $dse     = $ldap->root_dse();
        my $has_tls = $dse->supported_extension('1.3.6.1.4.1.1466.20037');

        if ($has_tls) {
            my $mesg = $ldap->start_tls(
                verify => $params->{tls_verify} // 'optional',
                cafile => $params->{cafile} // '',
            );
            if ($mesg->is_error) {
                my $text = "start_tls() failed for $params->{host}. "
                    . "[$mesg->code] $mesg->error_name: $mesg->error_text";
                $c->app->log->warn($text) if $logging;
                $ldap->unbind;
                return 0;
            }
        }

        $socket_type = ref $ldap->{net_ldap_socket};
        $c->app->log->warn("LDAP socket type after start_tls(): $socket_type")
            if $logging;
    }

    my @credentials
        = $params->{binddn}
        ? ($params->{binddn}, password => $params->{bindpw})
        : ();

    my $mesg = $ldap->bind(@credentials);
    if ($mesg->is_error) {
        $c->app->log->warn("LDAP bind failed"
                . ($params->{binddn} ? " for $params->{binddn}: " : ": ")
                . $mesg->error)
            if $logging;
        $ldap->unbind;
        return 0;
    }

    my $count = () = $params->{filter} =~ /%s/g;
    my $filter = sprintf($params->{filter}, ($username) x $count);
    my $scope  = $params->{scope} // 'sub';
    my $search = $ldap->search(
        base   => $params->{basedn},
        scope  => $scope,
        filter => $filter,
        attrs  => ['1.1']
    );

    if ($search->is_error) {
        $c->app->log->warn("LDAP search failed: " . $search->error)
            if $logging;
        $ldap->unbind;
        return 0;
    }

    if ($search->count == 0) {
        $c->app->log->warn(
            qq{User '$username' not found with filter '$filter' and scope '$scope'}
        ) if $logging;
        $ldap->unbind;
        return 0;
    }

    if ($search->count > 1) {
        $c->app->log->warn("Found "
                . $search->count
                . qq{ matching entries for $username with filter '$filter'})
            if $logging;
    }

    my $entry = $search->entry(0);
    my $dn    = $entry->dn;
    $mesg = $ldap->bind($dn, password => $password);

    if ($mesg->is_error) {
        $c->app->log->warn(
            qq{LDAP failed to authenticate user '$username' with dn '$dn': }
                . $mesg->error)
            if $logging;
        $ldap->unbind;
        return 0;
    }
    else {
        $c->app->log->info(
            qq{LDAP successfully authenticated user '$username' with dn '$dn'}
        ) if $logging;
        if ($params->{return_ldap_handle}) {
            return (1, $ldap);
        }
        else {
            $ldap->unbind;
            return 1;
        }
    }

    return 0;
}

sub _check_passwd {
    my ($self, $c, $auth, $params) = @_;
    my ($username, $password) = _split_auth($auth);

    my $passwd = Authen::Simple::Passwd->new(%$params);

    return 1 if $passwd->authenticate($username, $password);
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::BasicAuthPlus - Basic HTTP Auth Helper Plus

=head1 VERSION

Version 0.11.3

=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'basic_auth_plus';
  
  get '/' => sub {
      my $self = shift;
  
      $self->render(text => 'ok')
        if $self->basic_auth(
          "Realm Name" => {
              username => 'username',
              password => 'password'
          }
      );
  };
  
  # Mojolicious
  $self->plugin('BasicAuthPlus');
  
  sub index {
      my $self = shift;
  
      $self->render(text => 'ok')
          if $self->basic_auth(
              "My Realm" => {
                  path => '/path/to/some/passwd/file.txt'
              }
          );
  }

=head1 DESCRIPTION

L<Mojolicious::Plugin::BasicAuthPlus> is a helper for basic HTTP
authentication that supports multiple authentication schemes, including
a callback, explicit username and password (plaintext or encrypted) without
a callback, a passwd file, LDAP, and Active Directory.

=head1 METHODS

L<Mojolicious::Plugin::BasicAuthPlus> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

Register condition in L<Mojolicious> application.

=head2 C<basic_auth>

Configure specific auth method (see CONFIGURATION).  Returns a two-element
list, where the first element is a hash reference and the second is an
integer (1 for success, 0 for failure).

The hash reference contains one key/value pair for the username used to
authenticate, and when LDAP is used it may also contain the 'ldap' key
whose value is the active LDAP connection handle if requested by setting
the return_ldap_handle option (see options below).

Generally, you can ignore this; thus, for example, both of the following
are valid:

  my ($hash_ref, $auth_ok)
      = $self->basic_auth(
          "My Realm" => {
              username => 'zapp',
              password => 'brannigan'
          }
      );
  if ($auth_ok) {
      $self->app->log->info("Auth success for $hash_ref->{username}");
      render(text => 'ok');
  }

  $self->render(text => 'ok')
      if $self->basic_auth(
          "My Realm" => {
              username => 'zapp',
              password => 'brannigan'
          }
      );

=head1 CONFIGURATION

The basic_auth method takes an HTTP Basic Auth realm name that is either a
code ref for a subroutine that will do the authentication check, or a hash,
where the realm is the hash name.  When the realm represents a named hash,
the key/value pairs specify the source of user credentials and determine the
method used for authentication (e.g., passwd file, LDAP, Active Directory).

Realm names may contain whitespace.

If a username and password are defined, then other options pertaining to a
passwd file or LDAP/ActiveDirectory authentication will be ignored, because it
it assumed you intend to compare the defined username and password against
those supplied by the user.

The following options may be set in the hash:

=head2 username

Specify the username to match.

=head2 password

Specify the password to match.  The string may be plaintext or use any of the
formats noted in L<Authen::Simple::Password>.

=head2 path

The location of a password file holding user credentials.  Per
L<Authen::Simple::Passwd>, "Any standard passwd file that has records seperated
with newline and fields seperated by ":" is supported.  First field is expected
to be username and second field, plain or encrypted password.  Required."

=head2 host

The hostname or IP address of an LDAP or Active Directory server.

=head2 basedn

The base DN to use with LDAP or Active Directory.

=head2 binddn

The bind DN to use when doing an authenticated bind against LDAP or Active
Directory.

=head2 bindpw

The password to use when doing an authenticated bind to LDAP or Active
Directory.

=head2 scope

The search scope for LDAP or Active Directory.  Choices are
'base' | 'one' | 'sub' | 'subtree' | 'children', but the default is 'sub'.
See Net::LDAP for further discussion.

=head2 filter

The LDAP/ActiveDirectory filter to use when searching a directory.

=head2 port

The TCP port to use for an LDAP/ActiveDirectory connection.  The default is 389.

=head2 debug

Set the LDAP debug level. See the debug method in Net::LDAP for details.
The default value is 0, debugging off.

=head2 timeout

Timeout in seconds passed to IO::Socket when connecting to a remote
LDAP server.  The default is 120.

=head2 version

Set the LDAP protocol version being used (default is LDAPv3). To talk
to an older server, for example one using LDAPv2, set this to 2.  With
modern LDAP implementations, you shouldn't need to bother setting this.

=head2 start_tls

Enable TLS support for LDAP.  This is the default.  If you do not want TLS,
set this to zero, but it's recommended to take the default.

=head2 tls_verify

For SSL certificate validation, set tls_verify to 'none' | 'optional' | 'require'.
The default is 'optional'.  See Net::LDAP for more information.

=head2 cafile

The path to your CA or CA chain certificate file.  Required in TLS mode for
LDAP if tls_verify is true.

=head2 return_ldap_handle

When authenticating against LDAP, the plugin will do an unbind operation to
close the connection with the LDAP server after an authentication success or
failure.  In some cases, it may be useful to return the active LDAP connection
handle to your calling code so that further LDAP operations can be performed
after authentication succeeds.  To enable this, set return_ldap_handle.

Note that the last bind operation on the connection will be that of the end
user you're trying to authenticate, so once you get the handle back any LDAP
operation you attempt to execute will have only the LDAP privileges granted to
the end user who just authenticated.  If you need the LDAP privileges of your
administrative bind DN or other user, you'll need to do a fresh bind using the
same handle.  Rebinding will probably work with many modern LDAP
implementations, but it is not guaranteed.

The default behavior for the plugin is to close the LDAP connection and not
return a connection handle.

=head2 logging

If set, this enables some logging of successes and failures for
authentication, LDAP binding, etc.  The default is no logging.

=head1 EXAMPLES

  # With callback
  get '/' => sub {
      my $self = shift;
  
      return $self->render(text => 'ok')
          if $self->basic_auth(
              realm => sub { return 1 if "@_" eq 'username password' }
          );
  };
  
  # With callback and getting username from return hash ref.
  get '/' => sub {
      my $self = shift;
  
      my ($href, $auth_ok) = $self->basic_auth(
          realm => sub { return 1 if "@_" eq 'username password' }
      );

      if ($auth_ok) {
          return $self->render(
              status => 200,
              text   => 'ok',
              msg    => "Welcome $href->{username}"
          );
      }
      else {
          return $self->render(
              status => 401,
              text   => 'unauthorized',
              msg    => "Sorry $href->{username}"
          );
      }
  };
  
  # With encrypted password
  get '/' => sub {
      my $self = shift;
  
      $self->render(text => 'ok')
        if $self->basic_auth(
          "Realm Name" => {
              username => 'username',
              password => 'MlQ8OC3xHPIi.'
          }
      );
  };
  
  # Passwd file authentication
  get '/' => sub {
      my $self = shift;
  
      $self->render(text => 'ok')
        if $self->basic_auth(
          "Realm Name" => {
              path => '/path/to/passwd/file.txt'
          }
      );
  };
  
  # LDAP authentication (with anonymous bind)
  get '/' => sub {
      my $self = shift;
  
      $self->render(text => 'ok')
        if $self->basic_auth(
          "Realm Name" => {
              host   => 'ldap.company.com',
              basedn => 'ou=People,dc=company,dc=com'
          }
      );
  };
  
  # LDAP authentication over TLS/SSL (with authenticated bind)
  get '/' => sub {
      my $self = shift;
      my ($hash_ref, $auth_ok)
          = $self->basic_auth(
              "Realm Name" => {
                  host       => 'ldap.company.com',
                  basedn     => 'ou=People,dc=domain,dc=com',
                  binddn     => 'cn=bender,ou=People,dc=domain,dc=com',
                  bindpw     => 'secret',
                  filter     => '(&(objectClass=person)(cn=%s))',
                  cafile     => '/some/path/to/ca.cert',
                  tls_verify => 'require'
              }
          );
      $self->render(text => 'ok') if $auth_ok;
  };

  # LDAP authentication over TLS/SSL (with authentciated bind),
  # returning the active LDAP handle and using it to do an additional
  # search.  Logging is also enabled.
  get '/' => sub {
      my $self = shift;
      my ($hash_ref, $auth_ok)
          = $self->basic_auth(
              "Realm Name" => {
                  host       => 'ldap.company.com',
                  basedn     => 'ou=People,dc=domain,dc=com',
                  binddn     => 'cn=bender,ou=People,dc=domain,dc=com',
                  bindpw     => 'secret',
                  filter     => '(&(objectClass=person)(cn=%s))',
                  cafile     => '/some/path/to/ca.cert',
                  tls_verify => 'require',
                  logging    => 1,
                  return_ldap_handle => 1
              }
          );

      if ($hash_ref->{ldap}) {
          my $ldap     = $hash_ref->{ldap};
          my $username = $hash_ref->{username};
          my @fields   = qw(cn sn mail);
          my $filter   = join '', map { "($_=*$username*)" } @fields;
          $filter      = '(|' . $filter . ')';

          my $mesg = $ldap->search(
              base   => 'dc=domain,dc=com',
              scope  => 'sub',
              filter => $filter,
              attrs  => [ 'cn', 'sn', 'mail' ]
          );
          croak $mesg->error if $mesg->code;

          my @entries = $mesg->entries;

          for my $entry (@entries) {
              my $email = $entry->get_value('mail');
              $self->app->log->info("Email address for $username is $email.");
          }
          $ldap->unbind;
      }

      $self->render(text => 'ok') if $auth_ok;
  };

  # Active Directory authentication (with authenticated bind)
  get '/' => sub {
      my $self = shift;
  
      $self->render(text => 'ok')
        if $self->basic_auth(
          "Realm Name" => {
              host   => 'ldap.company.com',
              basedn => 'dc=company,dc=com',
              binddn => 'ou=People,dc=company,dc=com',
              bindpw => 'secret',
              filter =>
              '(&(objectClass=organizationalPerson)(userPrincipalName=%s))'
          }
      );
  };

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mojolicious-plugin-basicauthplus at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-BasicAuthPlus>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 DEVELOPMENT

L<http://github.com/stregone/mojolicious-plugin-basicauthplus>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::BasicAuthPlus

You can also look for information at:

=over 4 

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-BasicAuthPlus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-BasicAuthPlus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-BasicAuthPlus>

item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-BasicAuthPlus/>

=back

=head1 ACKNOWLEDGEMENTS

Based on Mojolicious::Plugin::BasicAuth, by Glen Hinkle <tempire@cpan.org>.

=head1 AUTHOR

Brad Robertson <blr@cpan.org>

=head1 CONTRIBUTORS

=over 2

Nicolas Georges

Jay Mortensen

Mark Muldoon

G.Y. Park

Jan Paul Schmidt

=back

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>,
L<Authen::Simple::Password>, L<Authen::Simple::Passwd>, L<Net::LDAP>

=head1 COPYRIGHT

Copyright (c) 2013-2018 by Brad Robertson.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

