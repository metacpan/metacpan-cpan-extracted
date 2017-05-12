#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Router;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Router - URL route manager.

=head1 SYNOPSIS
    
    # get router object
    $router = $app->router;

    # load routes file from the path/route folder. default file extension is xml.
    $router->load("route");
    
    # find route action and its information, result is hash ref
    my $match = $router->match($route, $request_method);
    say $match->{action},
        $match->{args},
        $match->{query},
        $match->{uri},
        $match->{code},
        $match->{route};

    my $match = $router->match("/news/world/egypt/politics/2014/07/24/1579279", "get");
    my $match = $router->match("/blog/computer/software/article_name");
    my $match = $router->match($route, $request_method);

    # add new route information to the router object
    $router->add_route(
        name  => "blogview",
        path  => "blog/view/{id:\d+}",
        target  => "/Blog/Blog/view", # can be a code ref like sub{...}
        method  => "*", # get, post, put, patch, delete, options, head, ajax, *
        defaults  => {
                id => 1
            },
        attributes => "capture", # undef or "capture" for inline actions capture
    );

=head1 DESCRIPTION

Nile::Router - URL route manager.

=head2 ROUTES FILES

Routes are stored in a special xml files in the application folder named B<route>. Below is a sample C<route.xml> file.

    <?xml version="1.0" encoding="UTF-8" ?>

    <register route="/register" action="Accounts/Register/create" method="get" defaults="year=1900|month=1|day=23" />
    <post route="/blog/post/{cid:\d+}/{id:\d+}" action="Blog/Article/post" method="post" />
    <browse route="/blog/{id:\d+}" action="Blog/Article/browse" method="get" />
    <view route="/blog/view/{id:\d+}" action="Blog/Article/view" method="get" />
    <edit route="/blog/edit/{id:\d+}" action="Blog/Article/edit" method="get" />

Each route entry in the routes file has the following format:

    <name route="/blog" action="Plugin/Controller/Action" method="get" defaults="k1=v1|k2=v2..." />

The following are the components of the route tag:
The route 'name', this must be unique name for the route.
The url 'route' or path that should match.
The 'action' or target which should be executed if route matched the path.
The 'method' is optional and if provided will only match the route if request method matched it. Empty or '*' will match all.
The 'defaults' is optional and can be used to provide a default values for the route params if not exist. These params if exist will be added to the request params in the request object.

Routes are loaded and matched in the same order they exist in the file, the sort order is kept the same.

=cut

use Nile::Base;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub BUILD {
    my ($self, $args) = @_;

    $self->{cache} = +{};
    $self->{cache_route} = +{};
    $self->{routes} = [];
    $self->{patterns} = +{};
    $self->{names} = +{};
    $self->{paths_methods} = +{};
    
    $self->{route_counter} = 0;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 load()
    
    # load routes file. default file extension is xml. load route.xml file.
    $router->load("route");
    
    # add another routes file. load and add the file blog.xml file.
    $router->load("blog");

Loads and adds routes files. Routes files are XML files with specific tags. Everytime you load a route file
it will be added to the routes and does not clear the previously loaded files unless you call the clear method.
This method can be chained.

=cut

sub load {

    my ($self, $file) = @_;

    $file .= ".xml" unless ($file =~ /\.xml$/i);
    my $filename = $self->app->file->catfile($self->app->var->get("route_dir"), $file);
    
    # keep routes sorted
    $self->app->xml->keep_order(1);

    my $xml = $self->app->xml->get_file($filename);
    
    my ($regexp, $capture, $uri_template, $k, $v, $defaults, $key, $val);

    while (($k, $v) = each %{$xml}) {
        # <register route="register" action="Accounts/Register/register" method="get" defaults="year=1900|month=1|day=23" />
        
        $v->{-defaults} ||= "";
        $defaults = +{};
        foreach (split (/\|/, $v->{-defaults})) {
            ($key, $val) = split (/\=/, $_);
            $defaults->{$key} = $val;
        }

        $self->add_route(
                    name  => $k,
                    path  => $v->{-route},
                    target  => $v->{-action},
                    method  => $v->{-method} || '*',
                    defaults  => $defaults,
                    attributes => undef,
                );
    }

    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 match()
    
    # find route action and its information, result is hash ref
    my $match = $router->match($route, $request_method);
    say $match->{action},
        $match->{args},
        $match->{query},
        $match->{uri},
        $match->{code},
        $match->{route};

Match routes from the loaded routes files. If route matched returns route target or action, default arguments if provided,
and uri and query information.

=cut

sub match {

    my ($self, $route, $method) = @_;
    
    $route || return;

    my $uri = $self->_match($route, $method);
    
    $uri || return;
    
    # get the full matched route object
    my $matched_route = $self->cash_route($route, $method);
    
    #my $route = $router->route_for($uri, $method);

    # inline actions. $app->action("get", "/home", sub {}); $app->capture("get", "/home", sub {});
    if (ref($uri) eq "CODE") {
        #return wantarray? ($uri,  $route_obj->{attributes}, $route_obj): {action=>$uri, route=>$route_obj->{attributes}};
        # ($action, $args, $uri, $query, $code, $matched_route)
        #return wantarray? ($uri, undef, undef, undef, 1, $matched_route): {action=>$uri, code=>1, route=>$matched_route};
        return {action=>$uri, args=>undef, query=>undef, uri=>undef, code=>1, route=>$matched_route};
    }
    
    #$uri = /blog/view/?lang=en&locale=us&Article=Home
    my ($action, $query) = split (/\?/, $uri);
    
    my ($args, $k, $v);
    
    $query ||= "";

    foreach (split(/&/, $query)) {
        ($k, $v) = split (/=/, $_);
        $args->{$k} = $self->url_decode($v);
    }

    #return wantarray? ($action, $args, $uri, $query, 0, $matched_route) : {action=>$action, args=>$args, query=>$query, uri=>$uri, code=>0, route=>$matched_route};
    return {action=>$action, args=>$args, query=>$query, uri=>$uri, code=>0, route=>$matched_route};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _match {

    my ($self, $full_uri, $method) = @_;

    $method ||= '*';
    $method = uc($method);

    my ($uri, $querystring) = split /\?/, $full_uri;
  
    if (exists( $self->{cache}->{"$method $full_uri"})) {

        if (ref($self->{cache}->{"$method $full_uri"})) {
            return wantarray ? @{ $self->{cache}->{"$method $full_uri"} } : $self->{cache}->{"$method $full_uri"};
        }
        else {
            return unless defined $self->{cache}->{"$method $full_uri"};
            return $self->{cache}->{"$method $full_uri"};
        }

    }
  
    foreach my $route (grep { $method eq '*' || $_->{method} eq $method || $_->{method} eq '*' } @{$self->{routes}}) {
        if (my @captured = ($uri =~ $route->{regexp})) {
            
            # cash the full matched route
            $self->{cache_route}->{"$method $full_uri"} = $route;

            if (ref($route->{target}) eq 'ARRAY') {
                $self->{cache}->{"$method $full_uri"} = [
                     map {
                        $self->_prepare_target( $route, $_, $querystring, @captured)
                     } @{ $route->{target} }
                ];
                return wantarray ? @{ $self->{cache}->{"$method $full_uri"} } : $self->{cache}->{"$method $uri"};
            }
            else {
                #return $s->{cache}->{"$method $full_uri"} = $s->_prepare_target($route, "$route->{target}", $querystring, @captured);
                return $self->{cache}->{"$method $full_uri"} = $self->_prepare_target($route, $route->{target}, $querystring, @captured);
            }# end if()
        }# end if()
    }# end foreach()
  
    $self->{cache}->{"$method $uri"} = undef;
    return;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub cash_route {
    my ($self, $uri, $method) = @_;
    return $self->{cache_route}->{"$method $uri"};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _prepare_target {

    my ($self, $route, $target, $querystring, @captured) = @_;

    $querystring = '' unless defined($querystring);

    no warnings 'uninitialized';
    my $values = {map { my ($k,$v) = split /\=/, $_; ($k => $v) } split /&/, $querystring};

    my %defaults = %{ $route->{defaults} };

    map {
        my $value = @captured ? shift(@captured) : $defaults{$_};
        $value =~ s/\/$//;
        $value = $defaults{$_} unless length($value);
        $values->{$_} = $value;
        delete($defaults{$_}) if exists $defaults{$_};
    } @{$route->{captures}};
  
    map { $target =~ s/\[\:\Q$_\E\:\]/$values->{$_}/g } keys %$values;

    my %skip = ( );

    my $form_params = join '&', grep { $_ } map {
        $skip{$_}++;
        url_encode($_) . '=' . url_encode($values->{$_}) if defined($values->{$_});
    } grep { defined($values->{$_}) } sort {lc($a) cmp lc($b)} keys %$values;

    my $default_params = join '&', map {
        url_encode($_) . '=' . url_encode($defaults{$_}) if defined($defaults{$_});
    } grep { defined($defaults{$_}) && ! $skip{$_} } sort {lc($a) cmp lc($b)} keys %defaults;

    my $params = join '&', (grep { $_ } $form_params, $default_params);

    if ($target =~ m/\?/) {
        return $target . ($params ? "&$params" : "" );
    }
    else {
        #return $target . ($params ? "?$params" : "" );
        if ($params) { $target .= "?$params"; };
        return $target;
    }# end if()

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 uri_for()

    my $route = $router->uri_for($route_name, \%params);

Returns the uri for a given route with the provided params.
=cut

sub uri_for {

    my ($self, $name, $args) = @_;

    confess "Unknown route '$name'." unless my $route = $self->{names}->{$name};

    my $template = $route->{uri_template};

    map {
        $args->{$_} = $route->{defaults}->{$_} unless defined($args->{$_})
    } keys %{$route->{defaults}};

    my %used = ( );

    map {
        $template =~ s!
        \[\:$_\:\](\/?)
        !
        if (defined($args->{$_}) && length($args->{$_})) {
            $used{$_}++;
            "$args->{$_}$1"
        }
        else {
            "";
        }# end if()
        !egx
    } @{$route->{captures}};
  
    my $params = join '&', map { url_encode($_) . '=' . url_encode($args->{$_}) }
        grep { defined($args->{$_}) && length($args->{$_}) && ! $used{$_} } keys %$args;

    if (length($params)) {
        $template .= $template =~ m/\?/ ? "&$params" : "?$params";
    }
  
    return $template;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 route_for()
    
    my $route = $router->route_for($path, [$method]);

Returns the route matching the path and method.

=cut

sub route_for {

    my ($self, $uri, $method) = @_;

    $method ||= '*';
    $method = uc($method);

    ($uri) = split /\?/, $uri or return;
  
    foreach my $route (grep {$method eq '*' || $_->{method} eq $method || $_->{method} eq '*'} @{$self->{routes}}) {
        if (my @captured = ($uri =~ $route->{regexp})) {
            return $route;
        }
    }
  
    return;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 add_route()
    
    # add new route information to the router object
    $router->add_route(
        name  => "blogview",
        path  => "blog/view/{id:\d+}",
        target  => "/Blog/Blog/view", # can be a code ref like sub{...}
        method  => "*", # get, post, put, patch, delete, options, head, ajax, *
        defaults  => {
                id => 1
            },
        attributes => "capture", # undef or "capture" for inline actions capture
    );

This method adds a new route information to the routing table. Routes must be unique, so you can't have two routes that both look like /blog/:id for example. 
An exception will be thrown if an attempt is made to add a route that already exists.
If route name is empty, a custom route name in the form C<__ROUTE__[number]> will be used.

=cut

sub add_route {

    my ($self, %args) = @_;

    $args{name} ||= "__ROUTE__" . ++$self->{route_counter};
    
    # Set the method:
    $args{method} ||= '*';
    $args{method} = uc($args{method});

    my $uid = "$args{method} $args{path}";
    my $starUID = "* $args{path}";
  
    confess "Required param 'path' was not provided." unless defined($args{path}) && length($args{path});

    confess "Required param 'target' was not provided." unless defined($args{target}) && length($args{target});

    confess "Required param 'name' was not provided." unless defined($args{name}) && length($args{name});

    if (exists($self->{names}->{$args{name}})) {
        confess "name '$args{name}' is already in use by '$self->{names}->{$args{name}}->{path}'.";
    }
  
    if (exists($self->{paths_methods}->{$uid})) {
        confess "path '$args{method} $args{path}' conflicts with pre-existing path '$self->{paths_methods}->{$uid}->{method} $self->{paths_methods}->{$uid}->{path}'."
    }

    if (exists($self->{paths_methods}->{$starUID})) {
        confess "name '* $args{name}' is already in use by '$self->{paths_methods}->{$starUID}->{method} $self->{paths_methods}->{$starUID}->{path}'."
    }
        
    $args{defaults} ||= {};
  
    ($args{regexp}, $args{captures}, $args{uri_template}) = $self->_patternize( $args{path} );
  
    my $regUID = "$args{method} " . $args{regexp};

    if (my $exists = $self->{patterns}->{$regUID}) {
        confess "path '$args{path}' conflicts with pre-existing path '$exists'.";
    }
  
    push @{$self->{routes}}, \%args;

    $self->{patterns}->{$regUID} = $args{path};
    $self->{names}->{$args{name}} = $self->{routes}->[-1];
    $self->{paths_methods}->{$uid} = $self->{routes}->[-1];

    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _patternize {
  
    my ($self, $path) = @_;

    my @captures = ();
  
    my $regexp = do {
        (my $copy = $path) =~ s!
        \{(\w+\:(?:\{[0-9,]+\}|[^{}]+)+)\} | # /foo/{Page:\d+}
        :([^/\{\}\:\-]+)                   | # /foo/:title
        \{([^\}]+)\}                       | # /foo/{Bar} and /foo/{*WhateverElse}
        ([^/\{\}\:\-]+)                      # /foo/literal/
        !
        if ($1) {
            my ($name, $pattern) = split /:/, $1;
            push @captures, $name;
            $pattern ? "($pattern)" : "([^/]*?)";
        }
        elsif ($2) {
            push @captures, $2;
            "([^/]*?)";
        }
        elsif ($3) {
            my $part = $3;
            if ($part =~ m/^\*/) {
                $part =~ s/^\*//;
                push @captures, $part;
                "(.*?)";
            }
            else {
            push @captures, $part;
            "([^/]*?)";
            }# end if()
        }
        elsif ($4) {
            quotemeta($4);
        }# end if()
    !sgxe;
    
    # Make the trailing '/' optional:
    unless($copy =~ m{\/[^/]+\.[^/]+$}) {
        $copy .= '/' unless $copy =~ m/\/$/;
        $copy =~ s{\/$}{\/?};
    }

    qr{^$copy$};

    };
  
    # This tokenized string becomes a template for the 'uri_for(...)' method:
    my $uri_template = do {
        (my $copy = $path) =~ s!
        \{(\w+\:(?:\{[0-9,]+\}|[^{}]+)+)\} | # /foo/{Page:\d+}
        :([^/\{\}\:\-]+)                   | # /foo/:title
        \{([^\}]+)\}                       | # /foo/{Bar} and /foo/{*WhateverElse}
        ([^/\{\}\:\-]+)                      # /foo/literal/
        !
        if ($1) {
            my ($name, $pattern) = split /:/, $1;
            "[:$name:]";
        }
        elsif ($2) {
            "[:$2:]";
        }
        elsif ($3) {
            my $part = $3;
            if ($part =~ m/^\*/) {
                $part =~ s/^\*//;
                "[:$part:]"
            }
            else {
            "[:$part:]"
            }# end if()
        }
        elsif ($4) {
            $4;
        }# end if()
    !sgxe;
    
    unless ($copy =~ m{\/[^/]+\.[^/]+$}) {
        $copy .= '/' unless $copy =~ m/\/$/;
        $copy =~ s{\/$}{\/?};
        $copy =~ s/\?$//;
    }

    $copy;
  };
  
    return ($regexp, \@captures, $uri_template);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub replace_route {
    my ($self, %args) = @_;
    $self->add_route(%args) unless eval { $self->uri_for($args{name}) };
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 url_decode()
    
    my $decode_url = $router->url_decode($url);

=cut

sub url_decode {
    my ( $self, $decode ) = @_;
    return () unless defined $decode;
    $decode =~ tr/+/ /;
    $decode =~ s/%([a-fA-F0-9]{2})/ pack "C", hex $1 /eg;
    return $decode;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 url_encode()
    
    my $encoded_url = $router->url_encode($url);

=cut

  sub url_encode {
    my ( $self, $encode ) = @_;
    return () unless defined $encode;
    $encode =~ s/([^A-Za-z0-9\-_.!~*'() ])/ uc sprintf "%%%02x",ord $1 /eg;
    $encode =~ tr/ /+/;
    return $encode;
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
