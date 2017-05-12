package Pinwheel::Mapper;

use strict;
use warnings;


sub new
{
    my $class = shift;
    my $self = bless({}, $class);
    $self->reset();
    return $self;
}


sub reset
{
    my $self = shift;
    $self->{routes} = [];
    $self->{named} = {};
}


sub connect
{
    my $self = shift;
    my $name = (scalar(@_) & 1) ? undef : shift;
    my $route = _tidy_path(shift);
    my %options = @_;
    my $defaults = delete $options{'defaults'} || {};
    my $requirements = delete $options{'requirements'} || {};
    my $conditions = delete $options{'conditions'} || {};
    my @matchkeys = ();
    my %target = ();
    my $regexp;

    $options{'_static'} = 1 if ($route =~ /^\w+:\/\//);

    while (my ($key, $value) = each(%options)) {
        $defaults->{$key} = $value unless $key =~ /^_/;
    }

    my $subfn = sub {
        my ($prefix, $type, $name) = @_;
        my $pattern;

        push @matchkeys, $name;
        if ($name eq 'controller' || $name eq 'action') {
            $target{$name} = '*';
        } elsif ($name eq 'id') {
            $defaults->{id} ||= undef;
        }
        $prefix = '\.' if ($prefix eq '.');
        if ($type eq '*') {
            $pattern = $prefix . '(.*)';
        } elsif (exists($requirements->{$name})) {
            $pattern = $prefix . '(' . $requirements->{$name} . ')';
        } elsif ($prefix eq '\.') {
            $pattern = $prefix . '([^/.][^/]*)';
        } else {
            $pattern = $prefix . '([^/.]+)';
        }
        $pattern = "(?:$pattern)?" if exists($defaults->{$name});
        return $pattern;
    };

    $regexp = $route;
    $regexp =~ s!([/.]?)([:*])\(?([a-z][a-z0-9_]*)\)?!&$subfn($1, $2, $3)!ge;
    $defaults->{'controller'} ||= 'content';
    $defaults->{'action'} ||= 'index';
    if (!$target{'controller'}) {
        $target{'controller'} = $defaults->{'controller'};
    }
    if (!$target{'action'}) {
        $target{'action'} = $defaults->{'action'};
    }

    foreach (keys %$requirements) {
        $requirements->{$_} = qr/^$requirements->{$_}$/;
    }
    if ($conditions->{method} && $conditions->{method} eq 'any') {
        $conditions->{method} = undef;
    }

    my $r = {
        name => $name,
        route => $route,
        regexp => qr/^${regexp}$/,
        matchkeys => \@matchkeys,
        defaults => $defaults,
        requirements => $requirements,
        conditions => $conditions,
        target => \%target,
        options => \%options
    };
    push @{$self->{routes}}, $r unless $options{'_static'};
    $self->{named}{$name} = $r if defined($name);
}


sub match
{
    my ($self, $path, $method) = @_;
    my ($k, $v, %params, @matches, $route);

    $path = _tidy_path($path);
    $method = undef if $method && $method eq 'any';

    foreach $route (@{$self->{routes}}) {
        @matches = ($path =~ /$route->{regexp}/);
        next if scalar(@matches) == 0;
        if (defined($method) && defined($route->{conditions}{method})) {
            next if $method ne $route->{conditions}{method};
        }
        foreach $k (@{$route->{matchkeys}}) {
            $v = shift @matches;
            $v =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/ge if $v;
            $params{$k} = $v;
        }
        while (($k, $v) = each(%{$route->{defaults}})) {
            $params{$k} = $v unless defined($params{$k});
        }
        return \%params;
    }
    return undef;
}


sub generate
{
    my $self = shift;
    my $name = (scalar(@_) & 1) ? shift : undef;
    my %params = @_;
    my ($base, $k, $v, $route, $url);

    # If the controller and action are the same as the base set of parameters,
    # inherit any missing keys
    $base = delete $params{_base};
    if (!$name && _compare_targets($base, \%params)) {
        while (($k, $v) = each(%$base)) {
            $params{$k} = $v unless exists($params{$k});
        }
    }

    # A controller and action are always required
    $params{controller} ||= 'content';
    $params{action} ||= 'index';

    # Expand any objects supplied as route parameters
    foreach (keys(%params)) {
        next unless ref($v = $params{$_});
        $v = $v->route_param;
        if (ref $v) {
            delete $params{$_};
            %params = (%params, %$v);
        } else {
            $params{$_} = $v;
        }
    }

    # Find the appropriate route
    if ($name) {
        # Quick: find the named route
        $route = $self->{named}{$name};
    } else {
        # Slower: scan routes for the first valid parameter match
        foreach my $r (@{$self->{routes}}) {
            next unless _compare_targets($r->{target}, \%params);
            next unless _validate_route_params($r, \%params);
            $route = $r;
            last;
        }
    }
    return undef unless $route;

    # Fill in missing parameters with the defaults from the matched route
    while (($k, $v) = each(%{$route->{defaults}})) {
        $params{$k} = $v unless exists($params{$k});
    }

    return _insert_route_params($route, \%params);
}


sub names
{
    return [sort keys %{$_[0]->{named}}];
}


sub _tidy_path
{
    my ($path) = @_;
    # 1. Remove trailing slashes
    $path =~ s/\/+$//;
    # 2. Remove leading slashes before a /
    $path =~ s/(?<!:)\/+(?=\/)//g;
    # 3. Ensure leading '/' unless it's a full URL
    $path = '/' . $path if ($path !~ /^\// && $path !~ /^\w+:\/\//);
    return $path;
}

# Does this route match these params?
# The route matches if the controller and the action match.
# controller/action are matched as follows: it matches if it's specified in
# the route, and the corresponding param is either missing, or the same as
# that on the route, or "*".

sub _compare_targets
{
    my ($base, $params) = @_;
    my ($key, $b, $p);

    foreach $key ('controller', 'action') {
        $b = $base->{$key};
        return 0 unless defined($b);
        $p = $params->{$key};
        return 0 if ($p && $p ne $b && $b ne '*');
    }
    return 1;
}

# Is this set of params OK for this route?
# Tests defaults and requirements (regexp).

sub _validate_route_params
{
    my ($route, $params) = @_;
    my ($key, $value, $regexp);
    my $requirements = $route->{requirements};
    my $defaults = $route->{defaults};

    foreach $key (@{$route->{matchkeys}}) {
        $value = $params->{$key};
        return 0 unless (defined($value) || exists($defaults->{$key}));
        $regexp = $requirements->{$key};
        return 0 if (defined($value) && $regexp && $value !~ /${regexp}/);
    }
    return 1;
}

sub _insert_route_params
{
    my ($route, $params) = @_;
    my ($filter, $fn, $url);

    # Run any requested filters on the parameters before inserting them
    $filter = $route->{options}{_filter} || [];
    $filter = [$filter] if (ref($filter) eq 'CODE');
    &$_($params) foreach (@$filter);

    return unless _validate_route_params($route, $params);

    # Insert the parameters into the URL
    $url = $route->{route};
    $url =~ s!([/.]?)\*\(?([a-z][a-z0-9_]*)\)?!_param($1, $params->{$2}, 1)!ge;
    $url =~ s!([/.]?):\(?([a-z][a-z0-9_]*)\)?!_param($1, $params->{$2}, 0)!ge;

    return $url;
}

sub _param
{
    my ($prefix, $s, $keep_slash) = @_;
    return '' if !defined($s);
    $s =~ s/([^A-Za-z0-9\/_.-])/sprintf('%%%02X', ord($1))/ge;
    $s =~ s/\//%2F/g unless $keep_slash;
    return $prefix . $s;
}


1;

__DATA__

=head1 NAME

Pinwheel::Mapper

=head1 SYNOPSIS

    use Pinwheel::Mapper;
    my $mapper = Pinwheel::Mapper->new();

    # TODO, add a meaningful synopsis

=head1 DESCRIPTION

Handles the routing functionality.

=head1 ROUTINES

=over 4

=item Mapper->new()

Constructor method.  Creates an empty mapper.

=item $mapper->reset()

Empties the mapper.

=item $mapper->connect([NAME,] PATH, OPTIONS)

TODO, document me.

The PATH is tidied.

'defaults' is removed from OPTIONS and kept (default: {})

'requirements' is removed from OPTIONS and kept (default: {})

If PATH is absolute (^\w+://) then the '_static=1' is added to OPTIONS.

target = {}

defaults are merged in from OPTIONS except for keys that begin with "_".
(Special keys seem to be: _static _base _filter).

Big scary regex parser replacement thing:

  find
        optional "/" or "." ("prefix")
        ":" or "*" (type)
        optional "("
        [a-z][a-z0-9_]* ("name")
        optional ")"

  push name onto matchkeys
  if name = "controller" or "action", set the appropriate 'target' to '*'
  if name "id", defaults{id}||=undef
  quotemeta prefix

  if type = "*":
        pattern = prefix."(.*)"
  elsif there is a "requirements" for name, use it (it's a regex):
        pattern = prefix."($requirement)"
  elsif prefix was "."
        pattern = prefix.'([^/.][^/]*)' # i.e. .repr is allowed to contain "."
  else
        pattern = prefix.'([^/.]+)' # i.e. /:foo is not allowed to contain "."
 
  make optional if a default exists for this name:
   (?:pattern)?



defaults{controller}||=content
defaults{action}||=index

target{controller} ||= defaults{controller}
target{action} ||= defaults{action}

Each value of 'requirements' is compiled into a regex: ^value$

Route hash is built.

Pushed to 'routes', unless _static
  (namely: absolute route, or _static=1 specifically passed in)

Stored in 'named', if a name was given.

=item $params = $mapper->match(PATH)

Finds the first route matching PATH.  Routes are tried in the order they were
added using C<$mapper-E<gt>connect>.

If a matching route is found, returns the parameters required.  If no matching
route is found, returns C<undef>.

TODO, document how matching works.

TODO, document what "the parameters required" means.

=item $url = $mapper->generate([NAME, ]PARAMS)

Create a url for a mapped controller.

TODO, what does that even mean?

NAME is TODO.  PARAMS is a list of name/value options.

_base
controller
action

requirements/defaults/regex

=item @names = @{ $mapper->names }

Returns the names of all named routes, sorted, as an array ref.

=back

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut

