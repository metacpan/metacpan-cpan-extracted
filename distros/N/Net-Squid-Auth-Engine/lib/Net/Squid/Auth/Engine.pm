package Net::Squid::Auth::Engine;

use warnings;
use strict;
use Config::General qw(ParseConfig);

=head1 NAME

Net::Squid::Auth::Engine - External Credentials Authentication for Squid HTTP Cache

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Squid authentication using an external credentials repository, now implemented
in Perl. If you're a sysadmin trying to use this engine to authenticate your
Squid users, please read the documentation provided with the script
$Config{InstallScript}/squid-auth-engine, shipped with this module.

    #!/usr/bin/perl
    use warnings;
    use strict;
    use Net::Squid::Auth::Engine;
    use IO::Handle;
    BEGIN { STDOUT->autoflush(1); }
    my $engine = Net::Squid::Auth::Engine->new( $ARGV[0] );
    $engine->run;

=head1 CONFIGURATION FILE SPECIFICATION

The configuration file currently supports two keywords, at the moment. Only one
of them is useful and required:

=head2 C<plugin>

The C<plugin> keyword indicates which module name should be loaded as
authentication back-end to this interface. The string
I<Net::Squid::Auth::Plugin::> will be automatically appended to the module name
pointed here before it's loaded.

=head2 C<include>

The C<include> keyword can be used to import and process another configuration
file (a part of one) if required. The configuration file name should be passed
as argument to the keyword.

=head2 Configuration File Example

  plugin 'UserList'

=head1 WRITING PLUGINS

A plugin for L<Net::Squid::Auth::Engine> is a module under
L<Net::Squid::Auth::Plugin> that implements a well-stablished interface.

It is expected to keep it's own internal state and initialize only once (and
not at every request, this is not a stateless protocol!).

It is also expected to implement the following methods:

=over 4

=item B<C<new( $config_hash )>>

New is a constructor. It receives a hash reference containing all the keywords
and values passed in the main configuration file which section is the "last"
plugin module name (e.g.: for Net::Squid::Auth::Plugin::UserList, the section
is named "UserList". That's case sensitive, pay attention!).

The constructor must return a blessed reference for the plugin module, that is
able to keep it's internal state and implements the following methods.

=item B<C<initialize()>>

Initialization method called upon instantiation. This provides an opportunity
for the plugin initialize itself, stablish database connections and ensure it
have all the necessary resources to verify the credentials presented. It
receives no parameters and expect no return values.

=item B<C<is_valid( $username, $password )>>

Credential verification method. This method does the real work for the
credentials verification, and must return a boolean value without raising any
exceptions. A true value means that the pair (username, password) is a valid
credentials, and a false value means that the credentials aren't valid.
Undefined values will be passed as-is to the method, which means that it's free
to validate any credentials the way it sees fit.

=back

=head1 EXAMPLE PLUGIN

As a plugin implementation example, this module depends on the
L<Net::Squid::Auth::Plugin::UserList>, the most basic plugin possible: it loads
a username and password list from the configuration file and uses it to
authenticate users against it. For more information, please read the
L<Net::Squid::Auth::Plugin::UserList> documentation.

=head1 OTHER IMPLEMENTATIONS

=head2 L<Net::Squid::Auth::Plugin::SimpleLDAP>

A simple LDAP-based credentials validation plugin for L<Net::Squid::Auth::Engine>.

=head1 FUNCTIONS

=head2 new

Constructor. Receives a configuration file name, opens and reads it,
initializes the module and returns the authentication engine instance.

=cut

sub new {
    my ( $class, $config ) = @_;
    my $self = bless {}, $class;
		die "Net::Squid::Auth::Engine requires a config file" unless $config;
    $self->_read_config_file( $config );
    $self->_initialize;
    return $self;
}


=head2 run

Runs the engine, that is: load and parse the configuration file; identifies the
authentication module to be loaded; load and instantiate the authentication
module to be used; give the authentication module a chance to initialize itself
(stablishing database connections, etc.); waits for a Squid-standard
credentials line in the standard input, reads it, feeds it to the
authentication module instance, collects the answer and prints "OK" or "ERR" in
the stdout file handle, as the Squid external authentication protocol commands.
Then, waits for the next credential line to show up... you got the idea, right?

=cut

sub run {
    my $self = shift;
    while (1) {
        my ( $username, $password ) = $self->_read_credentials;
        print STDOUT $self->{_plugin}->is_valid( $username, $password )
            ? "OK\n"
            : "ERR\n";
    }
}

=head2 _read_config_file

Reads a configuration file, parses it, and makes it available. The underling
configuration parser is L<Config::General>.

=cut

sub _read_config_file {
    my $self = shift;
		$self->{_CONF}{filename} = shift;
    die q{Can't read the configuration file "}
        . $self->{_CONF}{filename} . q{".}
        unless -r $self->{_CONF}{filename};
    my %conf = ParseConfig(
        -ConfigFile           => $self->{_CONF}{filename},
        -AllowMultiOptions    => 'no',
        -UseApacheInclude     => 1,
        -MergeDuplicateBlocks => 1,
        -AutoTrue             => 1,
        -CComments            => 0,
    );
    $self->{_CONFIG} = \%conf;

    # Mandatory Config File Options Verification
    die q{Missing mandatory 'plugin' keyword in the configuration file.}
        unless $self->{_CONFIG}{plugin};
    my $section = $self->{_CONFIG}{plugin};
    die "Missing mandatory section '$section' in the config file."
        unless UNIVERSAL::isa( $self->{_CONFIG}{$section}, 'HASH' );
}

=head2 _initialize

Internal engine initialization. Happens once, mainly instanciates the plugin
and tries to initialize it properly. Die for errors, as usual.

=cut

sub _initialize {
    my $self   = shift;
    my $tag    = $self->{_CONFIG}{plugin};
    my $module = 'Net::Squid::Auth::Plugin::' . $self->{_CONFIG}{plugin};
    eval "use $module";
    die qq{Can't load "$module": $@.} if $@;
    $self->{_plugin} = eval { $module->new( $self->{_CONFIG}{$tag} ); };
    die qq{Can't instantiate $module: $@.} if $@;
    eval { $self->{_plugin}->initialize; };
    die qq{$module\:\:initialize() triggered an error: $@.} if $@;
}

=head2 _read_credentials

This method tryies, waits for, and reads a line from STDIN, splits it at the
first whitespace found from left to right, and returns the username (to the
left of the splitting whitespace) and the password (to the right of the
splitting whitespace), as described by the Squid HTTP Cache documentation.

=cut

sub _read_credentials {
    my $self        = shift;
    my $credentials = <STDIN>;
    # TODO: is this the right thing to do? Check it
    die q{Got a EOF from Squid?!?} unless $credentials;
    my ( $username, $password ) = $credentials =~ m{^(\S+)(?:\s+(.+))?$};
    return ( $username, $password );
}

=head1 AUTHOR

Luis Motta Campos, C<< <lmc at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-squid-auth-engine at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Squid-Auth-Engine>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=over 4

=item * There are no working tests for this module (yet);

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Squid::Auth::Engine


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Squid-Auth-Engine>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Squid-Auth-Engine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Squid-Auth-Engine>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Squid-Auth-Engine>

=back

=head1 ACKNOWLEDGEMENTS

To William A. Knob, for the initial idea;

To Otavio Fernandes, for the documentation links;

To Lucas Mateus, for the inner loop implementation, all comments and improvements;

To Fernando Oliveira, for comments and questioning the prototype;

To Alexei Znamensky, Gabriel Viera, and Mike Tesliuk, for pointing me a design
bug and helping me re-design the responsibility chain.

To Alexei Znamensky, for trying to use the module, reporting bugs, submiting
patches and implementing L<Net::Squid::Auth::Plugin::SimpleLDAP>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Luis Motta Campos, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Net::Squid::Auth::Engine
