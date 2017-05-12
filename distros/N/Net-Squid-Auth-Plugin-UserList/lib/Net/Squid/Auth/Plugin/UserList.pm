package Net::Squid::Auth::Plugin::UserList;

use warnings;
use strict;

=head1 NAME

Net::Squid::Auth::Plugin::UserList - A User List-Based Credentials Validation Plugin for L<Net::Squid::Auth::Engine>

=head1 VERSION

Version 0.02

=cut

our $VERSION = 0.02;

=head1 SYNOPSIS

If you're a system administrator trying to use L<Net::Squid::Auth::Engine> to
validate your user's credentials using a user:password list as credentials
repository, do as described here:

On C<$Config{InstallScript}/squid-auth-engine>'s configuration file:

    plugin = UserList
    <UserList>
      users = <<EOF
        joe_average:secret
        john_manager:terces
      EOF
    </UserList>

On your Squid HTTP Cache configuration:

    auth_param basic /usr/bin/squid-auth-engine /etc/squid-auth-engine.conf

And you're ready to use this module.

If you're a developer, you might be interested in reading through the source
code of this module, in order to learn about it's internals and how it works.
It may give you ideas about how to implement other plugin modules for
L<Net::Squid::Auth::Engine>. 

=head1 FUNCTIONS

=head2 new( $config_hash )

Constructor. Expects a hash reference with all the configuration under the
section I<< <UserList> >> in the C<$Config{InstallScript}/squid-auth-engine> as
parameter. Returns a plugin instance.

=cut

sub new {
    my ( $class, $config ) = @_;
    return unless UNIVERSAL::isa( $config, 'HASH' );
    return bless { _config => $config }, $class;
}

=head2 initialize()

Initialization function. Gets a user list from the 'users' parameter in the
configuration hash passed in to C<new()> and parses it using "\n" as user
record split and ":" as user / password separator inside of every record.
Returns nothing, as specified by the plugin interface.

=cut

sub initialize {
    my $self = shift;
    my @users = split "\n", $self->{_config}{users};
    foreach my $record (@users) {
        my ( $username, $password ) = split ':', $record;
        $self->{_usermap}{$username} = $password;
    }
    return;
}

=head2 is_valid( $username, $password )

This is the credential validation interface. It expects a username and password
as parameters and returns a boolean indicating if the credentials are valid
(i.e., are listed in the configuration file) or not.

=cut

sub is_valid {
    my ( $self, $username, $password ) = @_;
    return 0 unless exists $self->{_usermap}{$username};
    no warnings;
    return $self->{_usermap}{$username} eq $password;
}

=head1 OTHER IMPLEMENTATIONS

=head2 L<Net::Squid::Auth::Plugin::SimpleLDAP>

A simple LDAP-based credentials validation plugin for L<Net::Squid::Auth::Engine>.

=head1 AUTHOR

Luis Motta Campos, C<< <lmc at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-squid-auth-plugin-userlist at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Squid-Auth-Plugin-UserList>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Squid::Auth::Plugin::UserList


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Squid-Auth-Plugin-UserList>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Squid-Auth-Plugin-UserList>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Squid-Auth-Plugin-UserList>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Squid-Auth-Plugin-UserList>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008 Luis Motta Campos, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Net::Squid::Auth::Plugin::UserList
