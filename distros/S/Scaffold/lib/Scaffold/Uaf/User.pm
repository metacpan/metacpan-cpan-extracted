package Scaffold::Uaf::User;

our $VERSION = '0.01';

use 5.8.8;
use Scaffold::Class
  version   => $VERSION,
  base      => 'Scaffold::Base',
  accessors => 'username',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub attribute {
    my ($self, $key, $value) = @_;

    $self->{attributes}->{$key} = $value if (defined($value));
    return $self->{attributes}->{$key};

}
    
# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->{config} = $config;
    $self->{username} = $config->{username};

    return $self;

}

1;

__END__

=head1 NAME

Scaffold::Uaf::User - A module that defines a basic user object.

=head1 SYNOPSIS

=over 4

 use Scaffold::Uaf::User;

 my $username = 'joe blow';
 my $user = Scaffold::Uaf::User->new(username => $username);
 $user->attribute('birthday', '01-Jan-2008');
 
=back

=head1 DESCRIPTION

Scaffold::Uaf::User is a base module that can be used to create an
user object. The object is extremely flexiable and is not tied to any one 
data source. 

=head1 METHODS

=over 4

=item new()

This method initializes the user object. It takes one parameter, the username.

Example:

=over 4

 my $username = 'joeblow';
 my $user = Scaffold::Uaf::User->new(username => $username);

=back

=back

=head1 MUTATORS

=over 4

=item attribute()

Set/Returns a user object attribute.

Example:

 my $birthday = $user->attribute('birthday');
 $user->attribute('birthday', $birthday);

=back

=head1 SEE ALSO

 Scaffold
 Scaffold::Base
 Scaffold::Cache
 Scaffold::Cache::FastMmap
 Scaffold::Cache::Manager
 Scaffold::Cache::Memcached
 Scaffold::Class
 Scaffold::Constants
 Scaffold::Engine
 Scaffold::Handler
 Scaffold::Handler::Default
 Scaffold::Handler::Favicon
 Scaffold::Handler::Robots
 Scaffold::Handler::Static
 Scaffold::Lockmgr
 Scaffold::Lockmgr::KeyedMutex
 Scaffold::Lockmgr::UnixMutex
 Scaffold::Plugins
 Scaffold::Render
 Scaffold::Render::Default
 Scaffold::Render::TT
 Scaffold::Routes
 Scaffold::Server
 Scaffold::Session::Manager
 Scaffold::Stash
 Scaffold::Stash::Controller
 Scaffold::Stash::Cookie
 Scaffold::Stash::Manager
 Scaffold::Stash::View
 Scaffold::Uaf::Authenticate
 Scaffold::Uaf::AuthorizeFactory
 Scaffold::Uaf::Authorize
 Scaffold::Uaf::GrantAllRule
 Scaffold::Uaf::Login
 Scaffold::Uaf::Logout
 Scaffold::Uaf::Manager
 Scaffold::Uaf::Rule
 Scaffold::Uaf::User
 Scaffold::Utils

=head1 AUTHOR

Kevin L. Esteb E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
