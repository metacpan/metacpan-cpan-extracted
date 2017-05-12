package Net::LDAP::SimpleServer;

use strict;
use warnings;

# ABSTRACT: Minimal-configuration, read-only LDAP server

our $VERSION = '0.0.17';    # VERSION

use 5.008;
use Carp;

our $personality = undef;

sub import {
    my $pkg = shift;
    $personality = shift || 'Fork';

    eval "use base qw{Net::Server::$personality}";    ## no critic
    croak $@ if $@;

    push @Net::LDAP::SimpleServer::ISA, qw(Net::Server);

    #use Data::Dumper;
    #print STDERR Data::Dumper->Dump( [ \@Net::LDAP::SimpleServer::ISA ],
    #    ['ISA'] );
    return;
}

use File::Basename;
use File::HomeDir;
use File::Spec;
use File::Path 2.08 qw{make_path};
use Scalar::Util qw{reftype};
use Net::LDAP::SimpleServer::LDIFStore;
use Net::LDAP::SimpleServer::ProtocolHandler;

my $BASEDIR             = File::Spec->catfile( home(),   '.ldapsimple' );
my $DEFAULT_CONFIG_FILE = File::Spec->catfile( $BASEDIR, 'server.conf' );
my $DEFAULT_DATA_FILE   = File::Spec->catfile( $BASEDIR, 'server.ldif' );
my $DEFAULT_LOG_FILE    = File::Spec->catfile( $BASEDIR, 'server.log' );

my @LDAP_PRIVATE_OPTIONS = ( 'store', 'input', 'output' );
my @LDAP_PUBLIC_OPTIONS = ( 'data_file', 'root_dn', 'root_pw', 'allow_anon' );

make_path($BASEDIR);

sub options {
    my ( $self, $template ) = @_;
    my $prop = $self->{server};

    ### setup options in the parent classes
    $self->SUPER::options($template);

    ### add a single value option
    for (@LDAP_PUBLIC_OPTIONS) {
        $prop->{$_} = undef unless exists $prop->{$_};
        $template->{$_} = \$prop->{$_};
    }

    #use Data::Dumper;
    #print STDERR Data::Dumper->Dump( [$self->{server}], ['server'] );
    return;
}

sub default_values {
    my $self = @_;

    my $v = {};
    $v->{port}      = 389;
    $v->{log_file}  = $DEFAULT_LOG_FILE;
    $v->{conf_file} = $DEFAULT_CONFIG_FILE if -r $DEFAULT_CONFIG_FILE;
    $v->{syslog_ident} =
      'Net::LDAP::SimpleServer [' . $Net::LDAP::SimpleServer::VERSION . ']';

    $v->{allow_anon} = 1;
    $v->{root_dn}    = 'cn=root';
    $v->{data_file}  = $DEFAULT_DATA_FILE if -r $DEFAULT_DATA_FILE;

    #use Data::Dumper; print STDERR Dumper($v);
    return $v;
}

sub post_configure_hook {
    my $self = shift;
    my $prop = $self->{server};

    # create server directory in home dir
    make_path($BASEDIR);

    #use Data::Dumper; print STDERR '# ' . Dumper( $prop );
    croak q{Configuration has no "data_file" file!}
      unless $prop->{data_file};
    croak qq{Cannot read data_file file (} . $prop->{data_file} . q{)}
      unless -r $prop->{data_file};

    # data_file is not a "public" option in the server, it is created here
    $prop->{store} =
         Net::LDAP::SimpleServer::LDIFStore->new( $prop->{data_file} )
      || croak q{Cannot create data store!};

    return;
}

sub process_request {
    my $self = shift;
    my $prop = $self->{server};

    my $params = { map { ( $_ => $prop->{$_} ) } @LDAP_PUBLIC_OPTIONS };
    for (@LDAP_PRIVATE_OPTIONS) {
        $params->{$_} = $prop->{$_} if $prop->{$_};
    }
    $params->{input}  = *STDIN{IO};
    $params->{output} = *STDOUT{IO};
    my $handler = Net::LDAP::SimpleServer::ProtocolHandler->new($params);

    until ( $handler->handle ) {

        # intentionally empty loop
    }
    return;
}

1;    # Magic true value required at end of module



=pod

=encoding utf-8

=head1 NAME

Net::LDAP::SimpleServer - Minimal-configuration, read-only LDAP server

=head1 VERSION

version 0.0.17

=head1 SYNOPSIS

    use Net::LDAP::SimpleServer;

    # Or, specifying a Net::Server personality
    use Net::LDAP::SimpleServer 'PreFork';

    # using default configuration file
    my $server = Net::LDAP::SimpleServer->new();

    # passing a specific configuration file
    my $server = Net::LDAP::SimpleServer->new({
        conf_file => '/etc/ldapconfig.conf'
    });

    # passing configurations in a hash
    my $server = Net::LDAP::SimpleServer->new({
        port => 5000,
        data_file => '/path/to/data.ldif',
    });

    # make it spin
    $server->run();

    # make it spin with options
    $server->run({ allow_anon => 0 });

=head1 DESCRIPTION

As the name suggests, this module aims to implement a simple LDAP server,
using many components already available in CPAN. It can be used for
prototyping and/or development purposes. This is B<NOT> intended to be a
production-grade server, altough some brave souls in small offices might
use it as such.

As of April 2010, the server will load a LDIF file and serve its
contents through the LDAP protocol. Many operations are B<NOT> available yet,
notably writing into the directory tree.

The constructors will follow the rules defined by L<Net::Server>, but the most
useful are the two forms described below.

C<Net::LDAP::SimpleServer> will use the directory C<< ${HOME}/.ldapsimple >>
as a C<BASEDIR> for server files. If there exists a file:

    BASEDIR/server.conf

it will be used as the default confguration file. Similarly, if there exists
a file:

    BASEDIR/server.ldif

it will be used as the default data file for this server.

=head1 METHODS

=head2 new()

Instantiates a server object. If the default configuration file is available,
the options in it will be used.

=head2 new( HASHREF )

Instantiates a server object using the options specified in a hash
reference.

=head2 options()

As specified in L<Net::Server>, this method creates new options for the,
server, namely:

=over 4

=item *

data_file - the LDIF data file used by LDIFStore

=item *

root_dn - the administrator DN of the repository

=item *

root_pw - the password for root_dn

=item *

allow_anon - whether to allow for anonymous binds

=back

=head2 default_values()

As specified in L<Net::Server>, this method provides default values for a
number of options.

Notice that we do set a default password for the C<< cn=root >> DN. This
allows for out-of-the-box testing, but make sure you change the password
when putting this to production use.

=head2 post_configure_hook()

Method specified by L<Net::Server> to validate the parameters used in the
server instance.

=head2 process_request()

Method specified by L<Net::Server> to actually handle one connection. In this
module it basically delegates the processing to
L<Net::LDAP::SimpleServer::ProtocolHandler>.

=head1 CONFIGURATION AND ENVIRONMENT

Net::LDAP::SimpleServer may use a configuration file to specify the
server settings. If no file is specified and options are not passed
in a hash, this module will look for a default configuration file named
C<< BASEDIR/server.conf >>.

    data_file /path/to/a/ldif/file.ldif
    #port 389
    #root_dn cn=root
    #root_pw somepassword

=head1 TODO

We plan to implement more options in Net::LDAP::SimpleServer. Some ideas are:

    #objectclass_req (true|false)
    #user_tree dc=some,dc=subtree,dc=com
    #user_id_attr uid
    #user_pw_attr password

Keeping in mind we do NOT want to implement a full blown LDAP server.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Net::LDAP::SimpleServer

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Net-LDAP-SimpleServer>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Net-LDAP-SimpleServer>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Net-LDAP-SimpleServer>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Net-LDAP-SimpleServer>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Net-LDAP-SimpleServer>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/N/Net-LDAP-SimpleServer>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Net-LDAP-SimpleServer>

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

Please report any bugs or feature requests by email to C<bug-net-ldap-simpleserver at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-SimpleServer>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/russoz/Net-LDAP-SimpleServer>

  git clone https://github.com/russoz/Net-LDAP-SimpleServer.git

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



