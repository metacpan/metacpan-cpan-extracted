package QBit::WebInterface::Routing;
$QBit::WebInterface::Routing::VERSION = '0.033';
use qbit;

use base qw(QBit::Class);

use Exception::Routing;

use URI::Escape qw(uri_escape_utf8 uri_unescape);

my %METHODS = (
    GET     => 1,
    HEAD    => 2,
    POST    => 4,
    PUT     => 8,
    PATCH   => 16,
    DELETE  => 32,
    OPTIONS => 64,
);
$METHODS{'ANY'} = _get_methods_bit([keys(%METHODS)]);

sub init {$_[0]->{'strictly'} //= 1;}

sub get {shift->_generate_route(GET => @_)}

sub head {shift->_generate_route(HEAD => @_)}

sub post {shift->_generate_route(POST => @_)}

sub put {shift->_generate_route(PUT => @_)}

sub patch {shift->_generate_route(PATCH => @_)}

sub delete {shift->_generate_route(DELETE => @_)}

sub options {shift->_generate_route(OPTIONS => @_)}

sub any {
    my ($self, @args) = @_;

    if (@args == 1) {
        shift->_generate_route(ANY => @args);
    } elsif (@args == 2) {
        shift->_generate_route(@args);
    } else {
        throw Exception::Routing gettext('Expected one or two arguments');
    }
}

sub under {
    my ($self, @args) = @_;

    throw Exception::Routing gettext('Route must begin with "/"') unless $args[0] =~ m/\A\//;

    $args[0] =~ s/\/\z//;

    my $under_route = $self->new(strictly => $self->{'strictly'});

    $under_route->{'__UNDER__'} = {route => $args[0]};

    $under_route->{'__LAST__'} = \$under_route->{'__UNDER__'};

    $under_route->{'__ROUTES__'} = $self->{'__ROUTES__'};

    return $under_route;
}

sub _generate_route {
    my ($self, $methods, $url) = @_;

    throw Exception::Routing gettext('Route must begin with "/"') unless $url =~ m/\A\//;

    if (exists($self->{'__UNDER__'})) {
        $url =~ s/\A\/// if $self->{'__UNDER__'}{'route'} =~ m/\/\z/;

        $url = $self->{'__UNDER__'}{'route'} . $url;
    }

    my $methods_bits = _get_methods_bit($methods);

    my $route = {
        methods => $methods_bits,
        %{$self->_get_settings($url)}
    };

    if (exists($self->{'__UNDER__'})) {
        $route->{'route_path'} = $self->{'__UNDER__'}{'route_path'}
          if exists($self->{'__UNDER__'}{'route_path'});

        $route->{'conditions'} = $self->{'__UNDER__'}{'conditions'}
          if exists($self->{'__UNDER__'}{'conditions'});
    }

    foreach my $r (@{$self->{'__ROUTES__'} // []}) {
        if ($route->{'route_name'} eq $r->{'route_name'} && $route->{'methods'} & $r->{'methods'}) {
            throw Exception::Routing gettext('Route "%s" already exists', $url);
        }
    }

    push(@{$self->{'__ROUTES__'}}, $route);

    $self->{'__LAST__'} = \$route;

    return $self;
}

sub _get_settings {
    my ($self, $route_name) = @_;

    my @route_levels = split('/', $route_name);

    my @params        = ();
    my @format_levels = ();
    foreach my $route_level (@route_levels) {
        my $regexp_and_format = $self->_get_regexp_and_format_for_level($route_level, \@params);
        $route_level = $regexp_and_format->{'regexp'};
        push(@format_levels, $regexp_and_format->{'format'});
    }

    throw Exception::Routing gettext('Placeholders names can not intersect')
      if @params > 1 && @{arrays_intersection(@params)};

    my $pattern = @route_levels  ? join('\/', @route_levels)  : '\/';
    my $format  = @format_levels ? join('/',  @format_levels) : '/';

    if (!$self->{'strictly'}) {
        $pattern .= '\/' if $pattern !~ m/\/\z/;
        $format  .= '/'  if $format !~ m/\/\z/;
    } elsif ($route_name =~ m/\/\z/) {
        $pattern .= '\/' if $pattern !~ m/\/\z/;
        $format  .= '/'  if $format !~ m/\/\z/;
    }

    return {
        pattern    => '\A' . $pattern . '\z',
        format     => $format,
        params     => \@params,
        levels     => scalar(grep {length($_)} @route_levels),
        route_name => $route_name,
    };
}

sub _get_regexp_and_format_for_level {
    my ($self, $level, $params) = @_;

    my $regexp = '';
    my $format = '';
    my $param  = '';
    my $spec_symbol;
    my $new_spec_symbol;
    my $is_end = FALSE;

    foreach my $symbol (split('', $level)) {
        if (defined($new_spec_symbol)) {
            if ($symbol eq $new_spec_symbol) {
                if (defined($spec_symbol)) {
                    $param .= $symbol;
                } else {
                    $regexp .= quotemeta($symbol);
                    $format .= $symbol;
                }

                undef($new_spec_symbol);

                next;
            } else {
                throw Exception::Routing gettext('You must use "%s" for symbol "%s"', $new_spec_symbol x 2,
                    $new_spec_symbol);
            }
        }

        if ($symbol =~ /[!\:\*]/) {
            if (defined($spec_symbol)) {
                if ($symbol eq $spec_symbol) {
                    if ($is_end) {
                        $is_end = FALSE;

                        $param .= $symbol;
                    } elsif (length($param)) {
                        $is_end = TRUE;
                    } else {
                        undef($spec_symbol);

                        $regexp .= quotemeta($symbol);
                        $format .= $symbol;
                    }
                } elsif ($is_end) {
                    push(@$params, $param);
                    $param = '';

                    $regexp .= $self->_get_regexp_by_symbol($spec_symbol);
                    $format .= '%s';

                    $is_end = FALSE;

                    $spec_symbol = $symbol;
                } else {
                    $new_spec_symbol = $symbol;
                }
            } else {
                $spec_symbol = $symbol;
            }
        } else {
            if ($is_end) {
                push(@$params, $param);
                $param = '';

                $regexp .= $self->_get_regexp_by_symbol($spec_symbol);
                $format .= '%s';

                $is_end = FALSE;

                undef($spec_symbol);

                $regexp .= quotemeta($symbol);
                $format .= $symbol;
            } elsif (defined($spec_symbol)) {
                $param .= $symbol;
            } else {
                $regexp .= quotemeta($symbol);
                $format .= $symbol;
            }
        }
    }

    throw Exception::Routing gettext('You must use "%s" for symbol "%s"', $new_spec_symbol x 2, $new_spec_symbol)
      if $new_spec_symbol;

    if ($is_end) {
        push(@$params, $param);
        $param = '';

        $regexp .= $self->_get_regexp_by_symbol($spec_symbol);
        $format .= '%s';

        undef($spec_symbol);
    }

    throw Exception::Routing gettext('You must use "%s" for symbol "%s"', $spec_symbol x 2, $spec_symbol)
      if $spec_symbol;

    return {regexp => $regexp, format => $format};
}

sub _get_regexp_by_symbol {
    my ($self, $symbol) = @_;

    my $regexp = '';

    if ($symbol eq '!') {
        # /user/!id!
        $regexp = '([^\/.]+)';
    } elsif ($symbol eq ':') {
        # /user/:name:
        $regexp = '([^\/]+)';
    } elsif ($symbol eq '*') {
        # /user/*name*
        $regexp = '(.+)';
    }

    return $regexp;
}

sub _get_methods_bit {
    my ($methods) = @_;

    $methods = [$methods] unless ref($methods) eq 'ARRAY';

    my $methods_bit = $METHODS{shift(@$methods)};
    foreach my $method (@$methods) {
        $methods_bit |= $METHODS{$method};
    }

    return $methods_bit;
}

my $HANDLER_ROUTES_COUNT;

sub to {
    my ($self, @args) = @_;

    my $route_path;
    if (@args == 2 && $args[0] eq 'controller' && ref($args[1]) eq 'CODE') {
        #to(controller => \&func)

        $route_path = {path => '', cmd => '', controller => $args[1]};
    } elsif (@args % 2 == 0) {
        #to(path => <PATH>, cmd => <CMD>)

        $route_path = {hash_transform({@args}, ['path', 'cmd'])};
    } elsif (@args == 1) {
        if (ref($args[0]) eq 'CODE') {
            #to(\&func)

            $HANDLER_ROUTES_COUNT++;
            $route_path = {
                path    => "__HANDLER_PATH_${HANDLER_ROUTES_COUNT}__",
                cmd     => "__HANDLER_CMD_${HANDLER_ROUTES_COUNT}__",
                handler => $args[0]
            };
        } else {
            #to('path#cmd')

            my ($path, $cmd) = ($args[0] =~ m/\A([a-zA-Z_0-9]+)?#([a-zA-Z_][a-zA-Z_0-9]+)?\z/);

            $route_path = {path => $path // '', cmd => $cmd // ''};
        }
    } else {
        throw Exception::Routing gettext('Unknown format arguments');
    }

    if (exists($route_path->{'handler'})) {
        ${$self->{'__LAST__'}}->{'route_path'} = $route_path;
    } else {
        if (exists(${$self->{'__LAST__'}}->{'route_path'})) {
            my $under_route_path = ${$self->{'__LAST__'}}->{'route_path'};

            ${$self->{'__LAST__'}}->{'route_path'} = {
                path       => '',
                cmd        => '',
                controller => sub {
                    my ($web_interface, $params) = @_;

                    if (exists($under_route_path->{'controller'})) {
                        my ($path, $cmd) = $under_route_path->{'controller'}($web_interface, $params);

                        $under_route_path->{'path'} = $path // '';
                        $under_route_path->{'cmd'}  = $cmd // '';
                    }

                    if (exists($route_path->{'controller'})) {
                        my ($path, $cmd) = $route_path->{'controller'}($web_interface, $params);

                        $route_path->{'path'} = $path // '';
                        $route_path->{'cmd'}  = $cmd // '';
                    }

                    $route_path->{'path'} = $under_route_path->{'path'} // '' if $route_path->{'path'} eq '';
                    $route_path->{'cmd'}  = $under_route_path->{'cmd'} // ''  if $route_path->{'cmd'} eq '';

                    return ($route_path->{'path'}, $route_path->{'cmd'});
                }
            };
        } else {
            ${$self->{'__LAST__'}}->{'route_path'} = $route_path;
        }
    }

    return $self;
}

sub name {
    my ($self, $name) = @_;

    my @routes_with_this_name =
      grep {$name eq ($_->{'name'} // '')} @{$self->{'__ROUTES__'}};

    throw Exception::Routing gettext('Name "%s" for route already exists', $name) if @routes_with_this_name;

    ${$self->{'__LAST__'}}->{'name'} = $name;

    return $self;
}

sub attrs {
    my ($self, @attrs) = @_;

    foreach my $attr (@attrs) {
        push(@{${$self->{'__LAST__'}}->{'attrs'}}, $attr);

        if ($attr eq 'CMD') {
            $self->type('CMD');
        } elsif ($attr eq 'FORMCMD') {
            $self->type('FORM');
            $self->process_method('_process_form');
        }
    }

    return $self;
}

sub type {
    my ($self, $type) = @_;

    throw Exception::Routing gettext('Type for this route "%s" already exists', ${$self->{'__LAST__'}}->{'route_name'})
      if defined(${$self->{'__LAST__'}}->{'type'});

    ${$self->{'__LAST__'}}->{'type'} = $type;

    return $self;
}

sub process_method {
    my ($self, $process_method) = @_;

    throw Exception::Routing gettext('Process method for this route "%s" already exists',
        ${$self->{'__LAST__'}}->{'route_name'})
      if defined(${$self->{'__LAST__'}}->{'process_method'});

    ${$self->{'__LAST__'}}->{'process_method'} = $process_method;

    return $self;
}

sub get_current_route {
    my ($self, $wi) = @_;

    my $method = $wi->request->method;
    my $uri    = $wi->request->uri;

    $uri =~ s/[?#][^\/]*\z//;
    $uri .= '/' if !$self->{'strictly'} && $uri !~ m/\/\z/;

    $uri = fix_utf(uri_unescape($uri));

    my @routes = $self->_get_routes_by_methods($method);

    @routes = sort {$self->_sort_routes($a, $b)} @routes;

    foreach my $route (@routes) {
        my $pattern = $route->{'pattern'};

        if (my @values = ($uri =~ m/$pattern/i)) {
            delete(@$route{qw(path cmd args)});

            my %url_params = ();

            if (@{$route->{'params'}}) {
                throw Exception::Routing gettext('Different number of parameters')
                  unless @{$route->{'params'}} == @values;

                @url_params{@{$route->{'params'}}} = @values;
            }

            if (exists($route->{'conditions'})) {
                my $ok = TRUE;

                foreach my $condition_name (keys(%{$route->{'conditions'}})) {
                    my $check_value;
                    if (exists($url_params{$condition_name})) {
                        $check_value = $url_params{$condition_name};
                    } elsif ($wi->request->can($condition_name)) {
                        $check_value = $wi->request->$condition_name();
                    } else {
                        $check_value = $wi->request->http_header($condition_name);
                    }

                    my $condition = $route->{'conditions'}{$condition_name};

                    if (ref($condition) eq 'ARRAY') {
                        $ok = in_array($check_value, $condition);
                    } elsif (ref($condition) eq 'Regexp') {
                        $ok = $check_value =~ $condition;
                    } elsif (ref($condition) eq 'CODE') {
                        $ok = $condition->($wi, $check_value, \%url_params);
                    } else {
                        throw Exception::Routing gettext('Unknown condition type "%s"', ref($condition));
                    }

                    last unless $ok;
                }

                next unless $ok;
            }

            if (exists($route->{'route_path'}{'controller'})) {
                ($route->{'path'}, $route->{'cmd'}) =
                  $route->{'route_path'}{'controller'}($wi, \%url_params);
            } else {
                $route->{'path'} = $route->{'route_path'}{'path'};
                $route->{'cmd'}  = $route->{'route_path'}{'cmd'};
            }

            $route->{'args'} = \%url_params;

            return $route;
        }
    }

    return {};
}

sub _get_routes_by_methods {
    my ($self, $method) = @_;

    my @routes = ();

    foreach my $route (@{$self->{'__ROUTES__'}}) {
        push(@routes, $route) if $METHODS{$method} & $route->{'methods'};
    }

    return @routes;
}

sub _sort_routes {
    my ($self, $f, $s) = @_;

    my $result = $s->{'levels'} <=> $f->{'levels'};

    if ($result == 0) {
        if (@{$f->{'params'}} && @{$s->{'params'}}) {
            $result = @{$f->{'params'}} <=> @{$s->{'params'}};
        } elsif (@{$f->{'params'}} && !@{$s->{'params'}}) {
            $result = 1;
        } elsif (!@{$f->{'params'}} && @{$s->{'params'}}) {
            $result = -1;
        }
    }

    if ($result == 0) {
        if (exists($f->{'conditions'}) && !exists($s->{'conditions'})) {
            $result = -1;
        } elsif (!exists($f->{'conditions'}) && exists($s->{'conditions'})) {
            $result = 1;
        } else {
            my $f_pattern = $f->{'pattern'};
            my $s_pattern = $s->{'pattern'};

            l(
                gettext(
                    'Warning: Routes "%s" and "%s" differences only in conditions', $f->{'route_name'},
                    $s->{'route_name'}
                )
             )
              if $f->{'route_name'} =~ /$s_pattern/i && $s->{'route_name'} =~ /$f_pattern/i;
        }
    }

    return $result;
}

sub conditions {
    my ($self, %conditions) = @_;

    if (exists(${$self->{'__LAST__'}}->{'conditions'})) {
        ${$self->{'__LAST__'}}->{'conditions'} = {%{${$self->{'__LAST__'}}->{'conditions'}}, %conditions};
    } else {
        ${$self->{'__LAST__'}}->{'conditions'} = \%conditions;
    }

    return $self;
}

sub url_for {
    my ($self, $name, $params, %vars) = @_;

    my $route;
    foreach my $r (@{$self->{'__ROUTES__'}}) {
        if (($r->{'name'} // '') eq $name) {
            $route = $r;

            last;
        }
    }

    throw Exception::Routing gettext('Route with name "%s" not found', $name) unless $route;

    my $url;
    if (@{$route->{'params'}}) {
        $url = sprintf(
            $route->{'format'},
            map {uri_escape_utf8($params->{$_}) // throw Exception::Routing gettext('Expected param "%s"', $_)}
              @{$route->{'params'}}
        );
    } else {
        $url = $route->{'format'};
    }

    return $url
      . (
        %vars
        ? '?' . join('&', map {uri_escape_utf8($_) . '=' . uri_escape_utf8($vars{$_})} sort keys(%vars))
        : ''
      );
}

sub create_handler_cmds {
    my ($self, $package, $cmds) = @_;

    foreach my $route (@{$self->{'__ROUTES__'}}) {
        my $route_path = $route->{'route_path'};
        if (defined($route_path->{'handler'})) {
            $cmds->{$route_path->{'path'}}{$route_path->{'cmd'}} = {
                package    => $package,
                sub_name   => $route_path->{'cmd'},
                sub        => $route_path->{'handler'},
                attributes => {map {$_ => TRUE} @{$route->{'attrs'}}},
                (exists($route->{'process_method'}) ? (process_method => $route->{'process_method'}) : ()),
            };
        }
    }
}

TRUE;
