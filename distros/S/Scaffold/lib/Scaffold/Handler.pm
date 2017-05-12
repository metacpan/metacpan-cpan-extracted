package Scaffold::Handler;

our $VERSION = '0.02';

use 5.8.8;
use Switch;
use Try::Tiny;
use Scaffold::Stash;

use Scaffold::Class
  version   => $VERSION,
  base      => 'Scaffold::Base',
  accessors => 'stash scaffold page_title',
  mutators  => 'is_declined',
  constants => 'TRUE FALSE :state :plugins',
  messages => {
      'declined'          => '%s',
      'redirect'          => "%s",
      'moved_permanently' => "%s",
      'render'            => "%s",
      'not_found'         => "%s",
      'bad_url'           => "%s",
  },
  constant => {
      DECLINED   => 'scaffold.handler.declined',
      REDIRECT   => 'scaffold.handler.redirect',
      MOVED_PERM => 'scaffold.handler.moved_permanently',
      RENDER     => 'scaffold.handler.render',
      NOTFOUND   => 'scaffold.handler.notfound',
      BADURL     => 'scaffold.handler.bad_url',
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub handler {
    my ($class, $module, @params) = @_;

    my $action;
    my $location;
    my $state = STATE_PRE_ACTION;
    my $p1 = ( shift(@params) || 'main' );
    my $root = $class->scaffold->config('configs')->{'app_rootp'};

    $p1 = 'main' if ($p1 eq '1');
    $action = 'do_' . $p1;

    $class->{stash} = Scaffold::Stash->new(
        request => $class->scaffold->request
    );

    $class->{page_title} = $location = $class->scaffold->request->uri->path;

    $class->scaffold->response->status('200');
    $class->scaffold->response->header('Content-Type' => 'text/html');

    try {

        LOOP: 
        while ($state) {

            switch ($state) {
                case STATE_PRE_ACTION {
                    $state = $class->_pre_action();
                }
                case STATE_ACTION {
                    $state = $class->_perform_action($action, $p1, @params);
                }
                case STATE_POST_ACTION {
                    $state = $class->_post_action();
                }
                case STATE_PRE_RENDER {
                    $state = $class->_pre_render();
                }
                case STATE_RENDER {
                    $state = $class->_process_render();
                }
                case STATE_POST_RENDER {
                    $state = $class->_post_render();
                }
                case STATE_FINI {
                    last LOOP;
                }
            };

        }

    } catch {

        my $ex = $_;

        $class->exceptions($ex, $action, $location, $module);

    };

    $class->_pre_exit();

    return $class->scaffold->response;

}

sub redirect {
    my ($self, $url) = @_;

    my $uri = $self->scaffold->request->uri;
    $url = substr($url, 1);
    $uri->path($url);

    $self->throw_msg(REDIRECT, 'redirect', $uri->canonical);

}

sub moved_permanently {
    my ($self, $url) = @_;

    my $uri = $self->scaffold->request->uri;
    $url = substr($url, 1);
    $uri->path($url);

    $self->throw_msg(MOVED_PERM, 'moved_permanently', $uri->canonical);

}

sub declined {
    my ($self) = @_;

    $self->throw_msg(DECLINED, 'declined', "");

}

sub not_found {
    my ($self, $file) = @_;

    $self->throw_msg(NOTFOUND, 'not_found', $file);

}

sub bad_url {
    my ($self, $url) = @_;

    $self->throw_msg(BADURL, 'bad_url', $url);
    
}

sub exceptions {
    my ($self, $ex, $action, $location, $module) = @_;

    my $page;
    my $ref = ref($ex);

    if ($ref && $ex->isa('Badger::Exception')) {

        my $type = $ex->type;
        my $info = $ex->info;

        switch ($type) {
            case MOVED_PERM {
                $self->scaffold->response->redirect($info, '301');
            }
            case REDIRECT {
                $self->scaffold->response->redirect($info, '302');
            }
            case RENDER {
                $page = $self->custom_error(
                    $self->scaffold,
                    $self->page_title,
                    $info,
                );
                $self->scaffold->response->status('500');
                $self->scaffold->response->body($page);
            }
            case DECLINED {
                my $text = qq(
                    Declined - undefined method<br />
                    <span style='font-size: .8em'>
                    Method: $action <br />
                    Location: $location <br />
                    Module: $module <br />
                    </span>
                );
                $page = $self->custom_error(
                    $self->scaffold,
                    $self->page_title,
                    $text,
                );
                $self->scaffold->response->status('404');
                $self->scaffold->response->body($page);
            }
            case NOTFOUND {
                my $text = qq(
                    File not found<br />
                    <span style='font-size: .8em'>
                    File: $info<br />
                    </span>
                );
                $page = $self->custom_error(
                    $self->scaffold,
                    $self->page_title,
                    $text,
                );
                $self->scaffold->response->status('404');
                $self->scaffold->response->body($page);
            }
            case BADURL {
                my $text = qq(
                    URL not handled<br />
                    <span style='font-size: .8em'>
                    URL: $info<br />
                    </span>
                );
                $page = $self->custom_error(
                    $self->scaffold,
                    $self->page_title,
                    $text,
                );
                $self->scaffold->response->status('404');
                $self->scaffold->response->body($page);
            }

        }

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->{config} = $config;
    $self->{scaffold} = $config->{scaffold};

    return $self;

}

sub _pre_action {
    my ($self) = @_;

    my $pstatus;
    my $status = STATE_ACTION;

    if (my $plugins = $self->scaffold->plugins) {

        foreach my $plugin (@$plugins) {

            $pstatus = $plugin->pre_action($self);
            last if ($pstatus != PLUGIN_NEXT);

        }

    }

    return $status;

}

sub _perform_action {
    my ($self, $action , $p1, @p) = @_;

    my $method = lc($action);

    if ($self->can($method)) {

        $self->$method(@p);

    } elsif ($self->can('do_default')) {

        $self->do_default($p1, @p);

    } else {

        $self->declined();

    }

    $self->declined() if ($self->is_declined);

    return STATE_POST_ACTION;

}

sub _post_action {
    my ($self) = @_;

    my $pstatus;
    my $status = STATE_PRE_RENDER;

    if (my $plugins = $self->scaffold->plugins) {

        foreach my $plugin (@$plugins) {

            $pstatus = $plugin->post_action($self);
            last if ($pstatus != PLUGIN_NEXT);

        }

    }

    return $status;

}

sub _pre_render {
    my ($self) = @_;

    my $pstatus;
    my $status = STATE_RENDER;

    if (my $plugins = $self->scaffold->plugins) {

        foreach my $plugin (@$plugins) {

            $pstatus = $plugin->pre_render($self);
            last if ($pstatus != PLUGIN_NEXT);

        }

    }

    return $status;

}

sub _process_render {
    my ($self) = @_;

    my $status = STATE_POST_RENDER;
    my $view   = $self->stash->view;
    my $cache  = $self->scaffold->cache;
    my $page   = $self->stash->view->data;

    # set the content type

    if (my $type = $view->content_type) {

        $self->scaffold->response->header('Content-Type' => $type);

    }

    # render the output

    if (! $view->template_disabled) {

        if ($view->cache) {

            if ($page = $cache->get($view->cache_key)) {

                $self->scaffold->response->body($page);

            } else {

                $self->_process_page($page);

            }

        } else {

            $self->_process_page($page);

        }

    } else {

        $self->scaffold->response->body($page);

    }

    return $status;

}

sub _process_page {
    my $self = shift;

    my $view  = $self->stash->view;
    my $cache = $self->scaffold->cache;
    my $page  = $self->stash->view->data;

    if (my $render = $self->scaffold->render) {

        if (! $view->template_disabled) {

            $page = $render->process($self);

        }

        # cache the output

        if ($view->cache) {

            $cache->set($view->cache_key, $page);

        }

    }

    $self->scaffold->response->body($page);

}

sub _post_render {
    my ($self) = @_;

    my $pstatus;
    my $status = STATE_FINI;

    if (my $plugins = $self->scaffold->plugins) {

        foreach my $plugin (@$plugins) {

            $pstatus = $plugin->post_render($self);
            last if ($pstatus != PLUGIN_NEXT);

        }

    }

    return $status;

}

sub _pre_exit {
    my ($self) = @_;

    my $pstatus;

    if (my $plugins = $self->scaffold->plugins) {

        foreach my $plugin (@$plugins) {

            $pstatus = $plugin->pre_exit($self);
            last if ($pstatus != PLUGIN_NEXT);

        }

    }

}

1;

__END__

=head1 NAME

Scaffold::Handler - The base class for Scaffold Handlers

=head1 SYNOPSIS

 use Scaffold::Server;

 my $server = Scaffold::Server->new(
    locations => [
        {
            route   => qr{^/$},
            handler => 'App::Main'
        },{
            route   => qr{^/something/(\w+)/(\d+)$},
            handler => 'App::Something'
        }
    ]
 );

 ...

 package App::Main;

 use Scaffold::Class
   version => '0.01',
   base    => 'Scaffold::Handler',
   filesystem => 'File',
 ;

 sub do_main
     my ($self) = @_;

    $self->view->template_disable(1);
    $self->view->data('<p>Hello World</p>');

 }

 1;

 package App::Something;

 use Scaffold::Class
   version => '0.01',
   base    => 'Scaffold::Handler',
   filesystem => 'File',
 ;

 sub do_main
     my ($self, $action, $id) = @_;

    my $text = sprintf("action = %s, id = %s\n", $action, $id);

    $self->view->template_disable(1);
    $self->view->data($text);

 }

 1;

=head1 DESCRIPTION

This is the base class for all handlers within Scaffold. Your application will
inherit and extend this class. Handlers are the basis of your application.  

=head2 The Request Lifecycle

When a request comes into Scaffold it is first processed by L<Scaffold::Server|Scaffold::Server>
which takes the incomming url and passes it to L<Scaffold::Routes|Scaffold::Routes>.
Scaffold::Routes parses the url depending on the regex from the "route" verbs 
in the "locations" stanzia of the configuration. If a match is found it returns
the "handler" associated with the route and any parameters extracted from
the url. The server then calls the handler's handler() method passing the
parameters in @_;

=head2 Plugins

Scaffold handlers have an internal state machine. At certain steps, plugins are
called. Scaffold loads three plugins at startup. They are 
L<Scaffold::Cache::Manager|Scaffold::Cache::Manager>,
L<Scaffold::Session::Manager|Scaffold::Session::Manager> and L<Scaffold::Stash::Manager|Scaffold::Stash::Manager>.
These plugins help maintain the Scaffold environment. Plugins are guranteed to
run in the order they are defined.

=head2 The State Machine

The following are the steps that the state machine performs. 

=over 4

=item pre_action

Plugins are called during this phase. For example Scaffold::Cache::Manager
and Scaffold::Session::Manager run in this phase.

=item action

Your main line code is called during this phase. Please see below to 
understand how it is called.

=item post_action

Plugins are called during this phase.

=item pre_render

Plugins are called during this phase.

=item render

Your defined render is called to process items in the view stash.

=item post_render

Plugins are called during this phase.

=item pre_exit

Plugins are called during this phase. For example Scaffold::Stash::Manager and
Scaffold::Session::Manager run during this phase. This is also the last phase 
before the response is returned back to Scaffold::Server.

=back

=head2 The Action Phase

The action phase is where your mainline application code is called. During 
this phase one of three options can happen. They are the following.

=over 4

=item Option 1

If any parameters where extracted from the url, the first one is assumed
to be the method that will be called in the handler. This paramenter is
then prepended with "do_" and is checked with can() to see if it is defined.
If the method is defined it is called with the remaining parameters passed 
in @_;

=item Option 2

If the above method is not defined then "do_main" is checked for with can().
If it is defined, it is called with all the parameters passed in @_.

=item Option 3 

If "do_main" is not defined then "do_default" is checked for with can(). If it
is defined, it is called with all the parameters passed in @_. If it doesn't
exist an exception is thrown and a nice error page is displayed.

=back

=head2 Extending and Overriding

Since Scaffold::Handler is inherited, you can override any of the methods
that the default handler defines. For example you can override the 
exceptions() method to handle your applications exceptions.

=head2 Where's the MVC

Scaffold handlers don't enforce the MVC pattern. You can certainly write your
code in that fashion. There is nothing stopping you. The handler can be 
considered the controller, the render phase could be considered the view, 
all you would have to do is create the model. Remember, Scaffold is 
about flexiablity, not comformity to predefined methodolgies.

=head1 METHODS

The following are the methods that you inherit from Scaffold::Handler.

=over 4

=item handler(sobj, ref(handler) params) 

The main entry point. This method contains the state machine that handles the
life cycle of a request. It runs the plugins sends the output thru a renderer
for format and returns the response back to the dispatcher.

=item redirect(url)

The method performs a 302 redirect with the specified URL. A fully qualified 
URL is returned in the response header.

 $self->redirect('/login');

Redirects are considered exceptions. When one is generated normal processing
stops and the redirect happens. Since 3xx level http codes are handled directly
by the browser, this method is a prime candiate to override in a single page
JavaScript application. In that case it may return a data structure that has
meaning to the JavaScript application.

=item moved_permanently(url)

The method performs a 301 redirect with the specified URL. A fully qualified 
URL is returned in the response header.

 $self->moved_permanently('/login');

This is considered an exception and normal processing stops.

=item declined()

This method performs a 404 response, along with an error page. The error page
shows the location and the handler that was supposed to run along with a dump
of various objects within Scaffold.

 $self->declined();

This is considered an exception and normal processing stops.

=item not_found(file)

This method performs a 404 response, along with an error page. The error page
shows the name of the file that was not found along with a dump of various
objects within Scaffold.

 $self->not_found($file);

This is considered an exception and normal processing stops.

=item exceptions()

This method performs exception handling. The methods redirect(), 
moved_permanently(), declined() and not_found() throw exceptions. They are 
handled here. If other exception types need to be handled, this method 
can be overridden.

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
