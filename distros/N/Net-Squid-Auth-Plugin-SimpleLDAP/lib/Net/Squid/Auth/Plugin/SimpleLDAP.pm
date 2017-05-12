package Net::Squid::Auth::Plugin::SimpleLDAP;

use warnings;
use strict;

# ABSTRACT: A simple LDAP-based credentials validation plugin for Net::Squid::Auth::Engine

our $VERSION = '0.1.84';    # VERSION

use Carp;
use Net::LDAP 0.4001;
use Scalar::Util qw/reftype/;

sub new {
    my ( $class, $config ) = @_;

    my $reftype = reftype($config) || '';
    croak 'Must pass a config hash' unless $reftype eq 'HASH';

    # some reasonable defaults
    $config->{userattr} = 'cn' unless $config->{userattr};
    $config->{passattr} = 'userPassword'
      unless $config->{passattr};
    $config->{objclass} = 'person' unless $config->{objclass};

    # required information
    foreach my $required qw(binddn bindpw basedn server) {
        croak qq{Missing config parameter '$required'}
          unless $config->{$required};
    }

    return bless { _cfg => $config }, $class;
}

sub initialize {
    my $self = shift;

    # connect
    $self->{ldap} =
         Net::LDAP->new( $self->config('server'), $self->config('NetLDAP') )
      || croak "Cannot connect to LDAP server: " . $self->config()->{server};

    # bind
    my $mesg =
      $self->{ldap}
      ->bind( $self->config('binddn'), password => $self->config('bindpw') );
    $mesg->code && croak "Error binding to LDAP server: " . $mesg->error;

    return;
}

sub _search {
    my ( $self, $search ) = @_;

    # search
    my $mesg = $self->{ldap}->search(
        base   => $self->config('basedn'),
        scope  => 'sub',
        filter => '(&(objectClass='
          . $self->config('objclass') . ')('
          . $self->config('userattr') . '='
          . "$search" . '))',
        attrs => [ $self->config('userattr'), $self->config('passattr') ],
    );

    # if errors
    if ( $mesg->code ) {
        $mesg = $self->{ldap}->unbind;
        $mesg->code && croak "Error searching LDAP server: " . $mesg->error;
    }

    # get results
    my @entries = $mesg->entries();
    my $result  = {};

    my $entry = shift @entries;
    return $result unless $entry;

    my $user;
    if ( $self->config('userattr') =~ m/dn/i ) {
        $user = $entry->dn();
    }
    else {
        $user = $entry->get_value( $self->config('userattr') );
    }
    my $pw = $entry->get_value( $self->config('passattr') );

    $result->{$user} = $pw;

    carp "Found more than 1 entry for user ($user)" if shift @entries;

    return $result;
}

sub is_valid {
    my ( $self, $username, $password ) = @_;
    my $result = $self->_search("$username");
    return 0 unless exists $result->{$username};

    return $result->{$username} eq $password;
}

sub config {
    my ( $self, $key ) = @_;

    return $self->{_cfg}->{$key};
}

1;    # End of Net::Squid::Auth::Plugin::SimpleLDAP



=pod

=encoding utf-8

=head1 NAME

Net::Squid::Auth::Plugin::SimpleLDAP - A simple LDAP-based credentials validation plugin for Net::Squid::Auth::Engine

=head1 VERSION

version 0.1.84

=head1 SYNOPSIS

If you're a system administrator trying to use Net::Squid::Auth::Engine to
validate your user's credentials using a LDAP server as a credentials
repository, do as described here:

On C<$Config{InstallScript}/squid-auth-engine>'s configuration file:

  plugin = SimpleLDAP
  <SimpleLDAP>
    # LDAP server
    server = myldap.server.somewhere       # mandatory

    # connection options
    <NetLDAP>                              # optional section with
      port = N                             #   Net::LDAP's
      scheme = 'ldap' | 'ldaps' | 'ldapi'  #     constructor
      ...                                  #     options
    </NetLDAP>

    # bind options
    binddn = cn=joedoe                     # mandatory
    bindpw = secretpassword                # mandatory

    # search options
    basedn = ou=mydept,o=mycompany.com     # mandatory
    objclass = inetOrgPerson               # opt, default "person"
    userattr = uid                         # opt, default "cn"
    passattr = password                    # opt, default "userPassword"
  </SimpleLDAP>

Unless configured otherwise, this module will assume the users in your LDAP
directory belong to the object class C<person>, as defined in section 3.12 of
RFC 4519, and the B<user> and B<password> information will be looked for in the
C<cn> and C<userPassword> attributes, respectively. Although you can choose
to use any other pair of attributes, the C<userattr> can be set to C<DN>,
while the C<passattr> can not.

On your Squid HTTP Cache configuration:

    auth_param basic /usr/bin/squid-auth-engine /etc/squid-auth-engine.conf

And you're ready to use this module.

If you're a developer, you might be interested in reading through the source
code of this module, in order to learn about it's internals and how it works.
It may give you ideas about how to implement other plugin modules for
L<Net::Squid::Auth::Engine>.

=head1 METHODS

=head2 new( $config_hash )

Constructor. Expects a hash reference with all the configuration under the
section I<< <SimpleLDAP> >> in the C<$Config{InstallScript}/squid-auth-engine>
as parameter. Returns a plugin instance.

=head2 initialize()

Initialization method called upon instantiation. This provides an opportunity
for the plugin initialize itself, stablish database connections and ensure it
have all the necessary resources to verify the credentials presented. It
receives no parameters and expect no return values.

=head2 _search()

Searches the LDAP server. It expects one parameter with a search string for
the username. The search string must conform with the format used in LDAP
queries, as defined in section 3 of RFC 4515.

=head2 is_valid( $username, $password )

This is the credential validation interface. It expects a username and password
as parameters and returns a boolean indicating if the credentials are valid
(i.e., are listed in the configuration file) or not.

=head2 config( $key )

Accessor for a configuration setting given by key.

=head1 ACKNOWLEDGEMENTS

Luis "Fields" Motta Campos C<< <lmc at cpan.org> >>, who could now say:

"The circle is now complete. When I left you, I was but the learner; now *I* am the master."

To what I'd reply:

"Only a master of Perl, Fields"

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Net::Squid::Auth::Plugin::SimpleLDAP

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Net-Squid-Auth-Plugin-SimpleLDAP>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Net-Squid-Auth-Plugin-SimpleLDAP>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Net-Squid-Auth-Plugin-SimpleLDAP>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Net-Squid-Auth-Plugin-SimpleLDAP>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Net-Squid-Auth-Plugin-SimpleLDAP>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/N/Net-Squid-Auth-Plugin-SimpleLDAP>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Net-Squid-Auth-Plugin-SimpleLDAP>

=back

=head2 Email

You can email the author of this module at C<RUSSOZ at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #sao-paulo.pm then talk to this person for help: russoz.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-net-squid-auth-plugin-simpleldap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Squid-Auth-Plugin-SimpleLDAP>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/russoz/Net-Squid-Auth-Plugin-SimpleLDAP>

  git clone https://github.com/russoz/Net-Squid-Auth-Plugin-SimpleLDAP.git

=head1 AUTHOR

Alexei Znamensky <russoz@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alexei Znamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__

