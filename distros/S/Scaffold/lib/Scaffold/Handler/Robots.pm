package Scaffold::Handler::Robots;

our $VERSION = '0.01';

use 5.8.8;
use Scaffold::Class
  version    => $VERSION,
  base       => 'Scaffold::Handler',
  filesystem => 'File',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub do_default {
    my ($self) = @_;

    my $d;
    my $cache = $self->scaffold->cache;
    my $doc_rootp = $self->scaffold->config('configs')->{doc_rootp};
    my $file = File($doc_rootp, 'robots.txt');

    if (! ($d = $cache->get($file))) {

        if ($file->exists) {

            $d = $file->read();
            $cache->set($file, $d);

        } else {

            $self->not_found($file);

        }

    }

    $self->stash->view->data($d);
    $self->stash->view->template_disabled(1);
    $self->stash->view->content_type('text/plain');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Handler::Robots - A handler to handle "robots.txt" files

=head1 SYNOPSIS

 use Scaffold::Server;

 my $server = Scaffold::Server->new(
    configs => {
        doc_rootp => 'html',
    },
    locations => [
        {
            route   => qr{^/$},
            handler => 'App::Main'
        },{ 
            route   => qr{^/robots.txt$},
            handler => 'Scaffold::Handler::Robots',
        },{
            route   => qr{^/favicon.ico$},
            handler => 'Scaffold::Handler::Favicon',
        },{
            route   => qr{^/static/(.*)$},
            handler => 'Scaffold::Handler::Static',
        }
    ] 
 );

=head1 DESCRIPTION

This handler will return a "robots.txt" file back to the browser. Where it is 
located is controlled by the configs option "doc_rootp". Once a "robots.txt"
file has been requested, subsequent requests will load the image from cache 
instead of disk.

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
