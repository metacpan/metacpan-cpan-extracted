package OpusVL::AppKit::TraitFor::Controller::Login::NewSessionIdOnLogin;

use MooseX::MethodAttributes::Role;
use namespace::autoclean;

requires qw/
    login
    login_form_stash_key
/;

after 'login' => sub {
    my ( $self, $ctx ) = @_;

    $ctx->change_session_id;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::TraitFor::Controller::Login::NewSessionIdOnLogin

=head1 VERSION

version 2.29

=head1 DESCRIPTION

Simple controller role to generate a new session id when the user
logs in.  Actually it's a little blunter than that, it forces a new
one to be generated every time the login page is visited.  That's
not a problem, even if it is a little pointless.  It's just this
is the simplest place to hook in the functionality.

=head1 NAME

OpusVL::AppKit::TraitFor::Controller::Login::NewSessionIdOnLogin

=head1 METHODS

=head2 after 'login'

    $ctx->change_session_id;

=head1 SEE ALSO

=over

=item L<CatalystX::SimpleLogin::ControllerRole::Login>

=back

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
