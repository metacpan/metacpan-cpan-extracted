package Scaffold::Stash::View;

our $VERSION = '0.01';

use 5.8.8;
use Scaffold::Class
  version   => $VERSION,
  base      => 'Scaffold::Base',
  constants => 'FALSE',
  mutators  => 'title template data template_disabled template_wrapper 
                template_default content_type cache cache_key',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub reinit {
    my ($self) = @_;

    $self->title('');
    $self->data('');
    $self->cache(FALSE);
    $self->template('');
    $self->cache_key('');
    $self->content_type('');
    $self->template_default('');
    $self->template_wrapper('');
    $self->template_disabled(FALSE);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Stash::View - The internal view of an output page.

=head1 DESCRIPTION

This is the interface between the handlers and the templating system.

=head1 MUTATORS

=over 4

=item title 

The title for the page.

=item template 

The template to use for the page.

=item data 

The data that the template will process for the page.

=item template_disabled 

Temporary disable the templating system. .i.e. to send raw data to the
browser.

=item template_wrapper

The wrapper to use for the template.

=item content_type 

The content type for the page. The default is 'text/html'.

=item cache 

Boolean switch as to wither to cache this page.

=item cache_key

The key to use to return the page from cache.

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

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
