package Scaffold::Uaf::Logout;

our $VERSION = '0.01';

use 5.8.8;
use Scaffold::Class
  version => $VERSION,
  base    => 'Scaffold::Handler',
  mixin   => 'Scaffold::Uaf::Authenticate',
;

# -----------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------

sub do_main {
    my ($self) = @_;

    $self->uaf_init();

    my $title = $self->uaf_logout_title;
    my $wrapper = $self->uaf_logout_wrapper;
    my $template = $self->uaf_logout_template;
    my $logout_rootp = $self->uaf_logout_rootp;
    my $lock = $self->scaffold->session->session_id;

    $self->stash->view->title($title);
    $self->stash->view->template($template);
    $self->stash->view->template_wrapper($wrapper);

    if ($self->scaffold->lockmgr->lock($lock)) {

        $self->uaf_invalidate();
        $self->scaffold->lockmgr->unlock($lock);
        $self->scaffold->lockmgr->deallocate($lock);

    } else {

        $self->redirect($logout_rootp);

    }

}


# -----------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------

1;

=head1 NAME

Events::Uaf::Logout - A handler for /logout url

=head1 DESCRIPTION

This handler handles the url "/logout" and any actions on that url. By default
this method display a simple logout page which contains a logout form. This 
form can be used to verify that "logging out" is what they want to do. 

=head1 METHODS

=over 4

=item do_main

Displays a logout page based on these config parameters:

 uaf_logout_title
 uaf_logout_wrapper
 uaf_logout_template

It also invalidates the session.

=back

=head1 DEPENDENCIES

 Scaffold::Uaf::Authenticate

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

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
