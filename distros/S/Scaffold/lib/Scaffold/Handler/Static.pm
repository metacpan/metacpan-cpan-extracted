package Scaffold::Handler::Static;

our $VERSION = '0.01';

use 5.8.8;
use MIME::Types 'by_suffix';

use Scaffold::Class
  version    => $VERSION,
  base       => 'Scaffold::Handler',
  constants  => 'TRUE FALSE',
  filesystem => 'File'
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub do_default {
    my ($self, @params) = @_;

    my $found = FALSE;
    my $cache = $self->scaffold->cache;
    my $static_search = $self->scaffold->config('configs')->{static_search};
    my $static_cached = $self->scaffold->config('configs')->{static_cached};
    my @paths = split(':', $static_search);

    foreach my $path (@paths) {

        my $file = File($path, @params);

        if ($file->exists) {

            my $d;
            my ($mediatype, $encoding) = by_suffix($file);
            $found = TRUE;

            if (! ($d = $cache->get($file))) {

                $d = $file->read();

                if ($static_cached) {

                    $self->stash->view->cache(1);
                    $self->stash->view->cache_key($file);

                }

            }

            $self->stash->view->data($d);
            $self->stash->view->template_disabled(1);
            $self->stash->view->content_type(($mediatype || 'text/plain'));

        }

    }

    $self->not_found(File(@params)) if (! $found);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Handler::Static - A handler for static files

=head1 SYNOPSIS

 use Scaffold::Server;

 my $server = Scaffold::Server->new(
    configs => {
         static_search => 'html:html/static',
         static_cached => FALSE,
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

This handler will return "static" files back to the browser. Where they are 
located is controlled by the configs option "static_search". This is a colon 
seperated search list of directories to search. Think of the PATH 
environment variable. The first matching file is sent. By default 
"static" files will be cached. This can be turned off with
the configs options "static_cached", which has a TRUE/FALSE value. This is a
global setting.

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
