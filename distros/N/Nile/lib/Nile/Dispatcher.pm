#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Dispatcher;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Dispatcher - Application action dispatcher.

=head1 SYNOPSIS
        
    # dispatch the default route or detect route from request
    $app->dispatcher->dispatch;

    # dispatch specific route and request method
    $app->dispatcher->dispatch($route, $request_method);
    $app->dispatcher->dispatch('/accounts/register/create');
    $app->dispatcher->dispatch('/accounts/register/save', 'POST');

=head1 DESCRIPTION

Nile::Dispatcher - Application action dispatcher.

=cut

use Nile::Base;
use Capture::Tiny ();
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 dispatch()
    
    # dispatch the default route or detect route from request
    $app->dispatcher->dispatch;

    # dispatch specific route and request method
    $app->dispatcher->dispatch($route, $request_method);

Process the action and send output to client.

=cut

sub dispatch {

    my $self = shift;
    
    my $content = $self->dispatch_action(@_);

    return $content;

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 dispatch_action()
    
    # dispatch the default route or detect route from request
    $content = $app->dispatcher->dispatch_action;

    # dispatch specific route and request method
    $content = $app->dispatcher->dispatch_action($route, $request_method);

Process the action and return output.

=cut

sub dispatch_action {

    my ($self, $route, $request_method) = @_;
    
    my $app = $self->app;

    $request_method ||= $app->request->request_method;
    $request_method ||= "ajax" if ($app->request->is_ajax);
    $request_method ||= "*";

    $route = $self->route($route);
    $route ||= "";

    # beginning slash. forum/topic => /forum/topic
    $route = "/$route" if ($route !~ /^\//);

    #$match->{action}, $match->{args}, $match->{query}, $match->{uri}, $match->{code}, $match->{route}
    my $match = $app->router->match($route, $request_method);
    #$app->dump($match);
    
    if ($match->{action}) {
        $route =  $match->{action};
        while (my($k, $v) = each %{$match->{args}}) {
            $app->request->add_param($k, $v);
        }
    }
    #------------------------------------------------------
    my ($content, @result);
    undef $@;
    #------------------------------------------------------
    # inline actions. $app->action("get", "/home", sub {...});
    # inline actions. $app->capture("get", "/home", sub {...});
    if (ref($route) eq "CODE") {
        if (defined $match->{route}->{attributes} && $match->{route}->{attributes} =~ /capture/i) {
            # run the action and capture output of print statements
            ($content, @result) = Capture::Tiny::capture_merged {eval {$route->($self->app)}};
        }
        if (defined $match->{route}->{attributes} && $match->{route}->{attributes} =~ /command/i) {
            # run the action and capture output of print statements
            ($content, @result) = Capture::Tiny::capture_merged {eval {$route->($self->app)}};
			$content .= join "", @result;
        }
        else {
            # run the action and get the returned content
            $content = eval {$route->($self->app)};
        }

        if ($@) {
            $app->abort("Dispatcher error. Inline action dispatcher error for route '$route'.\n\n$@");
        }

        return $content;
    }
    #------------------------------------------------------
    # if route is '/' then use the default route
    if (!$route || $route eq "/") {
        $route = $app->var->get("default_route");
    }

    $route ||= $app->abort("Dispatcher error. No route defined.");
    
    my ($module, $controller, $action) = $self->action($route);

    my $class = "Nile::Module::${module}::${controller}";
    
    undef $@;
    eval "use $class;";

    if ($@) {
        $app->abort("Dispatcher error. Module error for route '$route' class '$class'.\n\n$@");
    }
    
    my $object = $class->new();

    if (!$object->can($action)) {
        # try /Accounts => Accounts/Accounts/Accounts
        if (($module eq $controller) && ($action eq "index")) {
            # try /Accounts => Accounts/Accounts/Accounts
            if ($object->can($module)) {
                $action = $module;
            }
            # try /Accounts => Accounts/Accounts/accounts
            elsif ($object->can(lc($module))) {
                $action = lc($module);
            }
        }
        else {
            $app->abort("Dispatcher error. Module '$class' action '$action' does not exist.");
        }
    }
    
    my $meta = $object->meta;
    
    my $attrs = $meta->get_method($action)->attributes;
    #$app->dump($attrs);
    
    # sub home: Action Capture Public {...}
    if (!grep(/^(action|capture|command|public)$/i, @$attrs)) {
        $app->abort("Dispatcher error. Module '$class' method '$action' is not marked as 'Action' or 'Capture'.");
    }

    #Methods: HEAD, POST, GET, PUT, DELETE, PATCH, [ajax]

    if ($request_method ne "*" && !grep(/^$request_method$/i, @$attrs)) {
        $app->abort("Dispatcher error. Module '$class' action '$action' request method '$request_method' is not allowed.");
    }
    
    # add method "me" or one of its alt
    $app->add_object_context($object, $meta);
    
    undef $@;

    if (grep(/^(capture)$/i, @$attrs)) {
        # run the action and capture output of print statements. sub home: Capture {...}
        ($content, @result) = Capture::Tiny::capture_merged {eval {$object->$action($self->app)}};
    }
    elsif (grep(/^(command)$/i, @$attrs)) {
        # run the action and capture output of print statements and return value. sub home: Command {...}
        ($content, @result) = Capture::Tiny::capture_merged {eval {$object->$action($self->app)}};
		$content .= join "", @result;
    }
    else {
        # run the action and get the returned content sub home: Action {...}
        $content = eval {$object->$action($self->app)};
    }

    if ($@) {
        $content = "Module error: Module '$class' method '$action'. $@\n$content\n";
    }

    return $content;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 action()
    
    my ($module, $controller, $action) = $app->dispatcher->action($route);
    #route /module/controller/action returns (Module, Controller, action)
    #route /module/action returns (Module, Module, action)
    #route /module returns (Module, Module, index)

Find the action module, controller and method name from the provided route.

=cut

sub action {

    my ($self, $route) = @_;

    $route || return;
    my ($module, $controller, $action);
    
    $route =~ s/^\/+//;
    
    my @parts = split(/\//, $route);

    if (scalar @parts == 3) {
        ($module, $controller, $action) = @parts;
    }
    elsif (scalar @parts == 2) {
        $module = $parts[0];
        $controller = $parts[0];
        $action = $parts[1];
    }
    elsif (scalar @parts == 1) {
        $module = $parts[0];
        $controller = $parts[0];
        $action = "index";
    }
    
    $module ||= "";
    $controller ||= "";
    
    return (ucfirst($module), ucfirst($controller), $action);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 route()
    
    my $route = $app->dispatcher->route($route);
    
Detects the current request path if not provided from the request params named as
'action', 'route', or 'cmd' in the post or get methods:
    
    # uri route
    /blog/?action=register
    
    # form route
    <input type="hidden" name="action" value="register" />

If not found, it will try to detect the route from the request uri after the path part
    
    # assuming application path is /blog, so /register will be the route
    /blog/register

=cut

sub route {
    my ($self, $route) = @_;
    
    my $app = $self->app;

    # if no route, try to find route from the request param named by action_name
    if (!$route) {
        # allow multiple names separated with commas, i.e. 'action', 'action,route,cmd'.
        my @action_name = split(/\,/, $app->var->get("action_name"));
        foreach (@action_name) {
            last if ($route = $app->request->param($_));
        }
    }
    
    # if no route, get the route from the query string in the REQUEST_URI
    $route ||= $app->request->url_path;
    
    if ($route) {
        $route =~ s!^/!!g;
        $route =~ s!/$!!g;
    }

    return $route;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
