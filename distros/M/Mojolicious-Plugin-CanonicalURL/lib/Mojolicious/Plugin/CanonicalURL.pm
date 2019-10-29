package Mojolicious::Plugin::CanonicalURL;
use Mojo::Base 'Mojolicious::Plugin';
use Carp         ();
use Exporter     'import';
use Mojo::Util   ();
use Scalar::Util ();
use Sub::Quote   ();

our $VERSION = '0.05';

our @EXPORT_OK = qw(remove_trailing_slashes);

sub register {
    my (undef, $app, $config) = @_;

    my (
        $should_canonicalize_request_config,
        $should_not_canonicalize_request_config,
        $inline_code,
        $end_with_slash,
        $canonicalize_before_render,
        %captures
    ) = _parse_and_validate_config($config);

    my $sub_string = '';
    my ($path_declared, $path_with_no_slashes_at_the_end_declared);
    if (defined $should_canonicalize_request_config) {
        ($path_declared, $path_with_no_slashes_at_the_end_declared, $sub_string) = _create_should_canonicalize_request_sub_string(
            config => $should_canonicalize_request_config,
            captures => \%captures,
            sub_string => $sub_string,
            should_canonicalize_request => 1,
            path_declared => $path_declared,
            path_with_no_slashes_at_the_end_declared => $path_with_no_slashes_at_the_end_declared,
        );
    }
    if (defined $should_not_canonicalize_request_config) {
        ($path_declared, $path_with_no_slashes_at_the_end_declared, $sub_string) = _create_should_canonicalize_request_sub_string(
            config => $should_not_canonicalize_request_config,
            captures => \%captures,
            sub_string => $sub_string,
            should_canonicalize_request => undef,
            path_declared => $path_declared,
            path_with_no_slashes_at_the_end_declared => $path_with_no_slashes_at_the_end_declared,
        );
    }
    $sub_string .= $inline_code if $inline_code;

    $sub_string .= 'my $_mpcu_path = $c->req->url->path->to_string;' unless $path_declared;
    if ($end_with_slash) {
        $sub_string .= q{
            my $_mpcu_path_length = length($_mpcu_path);
            return $next->() if $_mpcu_path_length != 0 and rindex($_mpcu_path, '/') == $_mpcu_path_length - 1 and ($_mpcu_path_length < 2 or rindex($_mpcu_path, '//') != $_mpcu_path_length - 2);

            while (rindex($_mpcu_path, '/') == length($_mpcu_path) - 1) {
                substr $_mpcu_path, -1, 1, '';
            }

            my $url = $c->req->url->clone;
            $url->path($_mpcu_path)->path->trailing_slash(1);

            $c->res->code(301);
            $c->redirect_to($url);
        };
    } else {
        $sub_string .= q{
            return $next->() if $_mpcu_path eq '/' or rindex($_mpcu_path, '/') != length($_mpcu_path) - 1 or $_mpcu_path eq '';

            while (rindex($_mpcu_path, '/') == length($_mpcu_path) - 1) {
                substr $_mpcu_path, -1, 1, '';
            }

            $c->res->code(301);
            $c->redirect_to($c->req->url->clone->path($_mpcu_path));
        };
    }

    # Potentially flaky for a minor speed improvment. Could just assign $next and $c above to @_.
    # Or could use Mojo::Template, but that would be awkward writing perl code.
    $sub_string =~ s/\$next\b/\$_[0]/g;
    $sub_string =~ s/\$c\b/\$_[1]/g;

    $app->hook(around_action => _quote_sub($sub_string, \%captures));

    if ($canonicalize_before_render) {
        # replace return $next->() with return
        $sub_string =~ s/return\s+\$_\[0\]->\(\)/return/g;

        # replace $_[1] with $_[0] since $c is now the first argument
        $sub_string =~ s/\$_\[1\]/\$_[0]/gm;

        # we could set a stash variable if we failed to canonicalize in
        # around_action, but the performance hit isn't big
        $sub_string = "return if \$_[0]->res->is_redirect;$sub_string";
        $app->hook(before_render => _quote_sub($sub_string, \%captures));
    }
}

sub _quote_sub {
    my ($sub_string, $captures) = @_;
    return Sub::Quote::quote_sub $sub_string, $captures, {no_install => 1, no_defer => 1};
}

sub _parse_and_validate_config {
    my ($config) = @_;

    my (
        $should_canonicalize_request,
        $should_not_canonicalize_request,
        $inline_code,
        $end_with_slash,
        $canonicalize_before_render
    );
    my %captures;
    if (defined $config) {
        Carp::confess 'config must be a hash reference, but was ' . Scalar::Util::reftype $config
          if not defined Scalar::Util::reftype $config
          or Scalar::Util::reftype $config ne 'HASH';

        if (%$config) {
            my $captures_allowed;
            if (exists $config->{should_canonicalize_request}) {
                ($should_canonicalize_request, $captures_allowed) =
                  _validate_should_canonicalize_request_config(delete $config->{should_canonicalize_request}, 1);
            }
            if (exists $config->{should_not_canonicalize_request}) {
                ($should_not_canonicalize_request, $captures_allowed) = _validate_should_canonicalize_request_config(
                    delete $config->{should_not_canonicalize_request},
                    undef,
                );
            }

            if (exists $config->{inline_code}) {
                $inline_code = delete $config->{inline_code};
                Carp::confess 'inline_code must be a true scalar value'
                  unless not defined Scalar::Util::reftype $inline_code and $inline_code;
                $captures_allowed = 1;
            }

            if (exists $config->{canonicalize_before_render}) {
                Carp::confess 'canonicalize_before_render must be a scalar value'
                  if defined Scalar::Util::reftype $config->{canonicalize_before_render};
                $canonicalize_before_render = delete $config->{canonicalize_before_render};
            }

            if ($captures_allowed and exists $config->{captures}) {
                %captures = %{delete $config->{captures}};
                Carp::confess 'captures cannot be empty' unless %captures;
            }

            Carp::confess
              'captures only applies when inline_code is set or a scalar reference is passed to should_canonicalize_request or should_not_canonicalize_request'
              if exists $config->{captures};

            if (exists $config->{end_with_slash}) {
                $end_with_slash = delete $config->{end_with_slash};
                Carp::confess 'end_with_slash must be a scalar value' if defined Scalar::Util::reftype $end_with_slash;
            }

            Carp::confess 'unknown keys passed in config: ' . Mojo::Util::dumper $config if keys %$config;
        }
    }

    return (
        $should_canonicalize_request,
        $should_not_canonicalize_request,
        $inline_code,
        $end_with_slash,
        $canonicalize_before_render,
        %captures
    );
}

sub _validate_should_canonicalize_request_config {
    my ($config, $should_canonicalize_request) = @_;

    my $captures_allowed;
    my $config_name    = _get_should_canonicalize_request_config_name($should_canonicalize_request);
    my $config_reftype = Scalar::Util::reftype $config || '';
    Carp::confess
      "$config_name must be a scalar that evaluates to true and starts with a '/', a REGEXP, a SCALAR, a subroutine, an array reference, or a hash reference"
      unless $config
      and ((not $config_reftype and index($config, '/') == 0)
        or grep { $config_reftype eq $_ } qw/ARRAY HASH REGEXP SCALAR CODE/);

    if (defined $config_reftype and $config_reftype eq 'SCALAR') {
        $captures_allowed = 1;
    } elsif (defined $config_reftype and $config_reftype eq 'ARRAY') {
        Carp::confess "array passed to $config_name must not be empty" unless @$config;

        for (@$config) {
            Carp::confess "elements of $config_name must be a true value" unless $_;

            my $reftype = Scalar::Util::reftype $_;
            Carp::confess
                "elements of $config_name must have a reftype of undef (scalar), CODE, HASH, REGEXP, or SCALAR but was '$reftype'"
                    unless not defined $reftype
                        or $reftype eq 'CODE'
                        or $reftype eq 'HASH'
                        or $reftype eq 'REGEXP'
                        or $reftype eq 'SCALAR';
            Carp::confess "elements of $config_name must begin with a '/' when they are scalar"
              if not defined $reftype and index($_, '/') != 0;

            if (defined $reftype and $reftype eq 'SCALAR') {
                $captures_allowed = 1;
            }

            if (defined $reftype and $reftype eq 'HASH') {
                _validate_starts_with_hash($config_name, $_);
            }
        }
    } elsif (defined $config_reftype and $config_reftype eq 'HASH') {
        _validate_starts_with_hash($config_name, $config);
    }

    return ($config, $captures_allowed);
}

sub _validate_starts_with_hash {
    my ($config_name, $hash) = @_;
    my %copy = %$hash;
    Carp::confess "must provide key 'starts_with' to hash in $config_name" unless exists $copy{starts_with};
    Carp::confess 'value for starts_with must not be undef' unless defined $copy{starts_with};
    Carp::confess 'value for starts_with must be a scalar'
        unless not defined Scalar::Util::reftype $copy{starts_with};
    Carp::confess q{value for starts_with must begin with a '/'}
        unless index(delete $copy{starts_with}, '/') == 0;
    Carp::confess "unknown keys/values passed in hash inside of $config_name: " . Mojo::Util::dumper \%copy
        if %copy
}

sub _create_should_canonicalize_request_sub_string {
    my %args = @_;
    my ($config, $captures, $sub_string, $should_canonicalize_request, $path_declared, $path_with_no_slashes_at_the_end_declared) =
    @{{@_}}{qw/config captures sub_string should_canonicalize_request path_declared path_with_no_slashes_at_the_end_declared/};
    my $path_with_no_slashes_at_the_end_declared_code = q{
        my $_mpcu_path_with_no_slashes_at_the_end = $_mpcu_path;
        while (rindex($_mpcu_path_with_no_slashes_at_the_end, '/') == length($_mpcu_path_with_no_slashes_at_the_end) - 1) {
            substr $_mpcu_path_with_no_slashes_at_the_end, -1, 1, '';
        }
    };

    my $config_name          = _get_should_canonicalize_request_config_name($should_canonicalize_request);
    my $config_variable_name = "\$$config_name";
    my $if_or_unless         = $should_canonicalize_request ? 'unless' : 'if';
    my $reftype              = Scalar::Util::reftype $config;
    if (not defined $reftype) {
        $config =~ s#/+\z##m;
        $captures->{$config_variable_name} = \$config;

        unless ($path_with_no_slashes_at_the_end_declared) {
            unless ($path_declared) {
                $sub_string .= 'my $_mpcu_path = $c->req->url->path->to_string;';
                $path_declared = 1;
            }

            $sub_string .= $path_with_no_slashes_at_the_end_declared_code;
            $path_with_no_slashes_at_the_end_declared = 1;
        }
        $sub_string .= "return \$next->() $if_or_unless \$_mpcu_path_with_no_slashes_at_the_end eq $config_variable_name;";
    } elsif ($reftype eq 'REGEXP') {
        unless ($path_declared) {
            $sub_string .= 'my $_mpcu_path = $c->req->url->path->to_string;';
            $path_declared = 1;
        }

        $captures->{$config_variable_name} = \$config;
        $sub_string .= "return \$next->() $if_or_unless \$_mpcu_path =~ $config_variable_name;";
    } elsif ($reftype eq 'SCALAR') {
        my $code = $$config;
        $code = "return \$next->() $if_or_unless $code" if $code !~ /\A\s*return/;
        $code .= ';' unless $code =~ /;\s*\z/;

        Carp::confess 'code must contain return $next->()' unless $code =~ /return\s+\$next->\(\)/;

        $sub_string .= $code;
    } elsif ($reftype eq 'CODE') {
        $captures->{$config_variable_name} = \$config;
        $sub_string .= qq{
            local \$_ = \$c;
            return \$next->() $if_or_unless $config_variable_name->();
        };
    } elsif ($reftype eq 'HASH') {
        unless ($path_declared) {
            $sub_string .= 'my $_mpcu_path = $c->req->url->path->to_string;';
            $path_declared = 1;
        }

        my $starts_with = $config->{starts_with};
        $captures->{$config_variable_name} = \$starts_with;
        $sub_string .= qq{return \$next->() $if_or_unless index(\$_mpcu_path, $config_variable_name) == 0;}
    } else {
        if (grep { not defined Scalar::Util::reftype $_ } @$config and not $path_with_no_slashes_at_the_end_declared) {
            unless ($path_declared) {
                $sub_string .= 'my $_mpcu_path = $c->req->url->path->to_string;';
                $path_declared = 1;
            }

            $sub_string .= $path_with_no_slashes_at_the_end_declared_code;
            $path_with_no_slashes_at_the_end_declared = 1;
        }

        unless ($path_declared) {
            for my $config_item (@$config) {
                my $reftype = Scalar::Util::reftype $config_item;
                if ($reftype eq 'REGEXP' or $reftype eq 'HASH') {
                    $sub_string .= 'my $_mpcu_path = $c->req->url->path->to_string;';
                    $path_declared = 1;
                    last;
                }
            }
        }

        $sub_string .= 'return $next->() unless' if $should_canonicalize_request;
        for my $index (0 .. $#$config) {
            my $reftype_of_item = Scalar::Util::reftype $config->[$index];
            my $condition;

            if (not defined $reftype_of_item) {
                $config->[$index] =~ s#/+\z##;
                my $var_name = '$_mpcu_' . $config_name . "_eq_$index";
                my $value = $config->[$index];
                $captures->{$var_name} = \$value;

                $condition = "\$_mpcu_path_with_no_slashes_at_the_end eq $var_name";
            } elsif ($reftype_of_item eq 'CODE') {
                my $var_name = '$_mpcu_' . $config_name . "_code_$index";
                my $value = $config->[$index];
                $captures->{$var_name} = \$value;
                $condition .= "do { local \$_ = \$c; $var_name->(); }";
            } elsif ($reftype_of_item eq 'HASH') {
                my $var_name = '$_mpcu_' . $config_name . "_starts_with_$index";
                my $value = $config->[$index]{starts_with};
                $captures->{$var_name} = \$value;
                $condition = "index(\$_mpcu_path, $var_name) == 0";
            } elsif ($reftype_of_item eq 'REGEXP') {
                my $var_name = '$_mpcu_' . $config_name . "_regexp_$index";
                my $value = $config->[$index];
                $captures->{$var_name} = \$value;
                $condition = "\$_mpcu_path =~ $var_name";
            } else {
                $condition = ${$config->[$index]};
            }

            if ($should_canonicalize_request) {
                $sub_string .= " ||" if $index != 0;
                $sub_string .= " $condition";
            } else {
                $sub_string .= "return \$next->() if $condition;";
            }
        }

        $sub_string .= ';' if $should_canonicalize_request;
    }

    return ($path_declared, $path_with_no_slashes_at_the_end_declared, $sub_string);
}

sub _get_should_canonicalize_request_config_name {
    return shift() ? 'should_canonicalize_request' : 'should_not_canonicalize_request';
}

sub remove_trailing_slashes {
    my ($path) = "$_[0]"; # turn possible Mojo::Path into string.

    while (rindex($path, '/') == length($path) - 1) {
        substr $path, -1, 1, '';
    }

    return $path;
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::CanonicalURL - Ensures canonical URLs via redirection

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojolicious-Plugin-CanonicalURL"><img src="https://travis-ci.org/srchulo/Mojolicious-Plugin-CanonicalURL.svg?branch=master"></a>

=head1 SYNOPSIS

  # Redirects all URLs that have a slash to their no-slash equivalent with a 301 status code.
  $app->plugin('CanonicalURL');

  # Redirects all requests whose paths have no slash to their slash equivalent with a 301 status code.
  $app->plugin('CanonicalURL', { end_with_slash => 1 });

  # Canonicalize any requests whose paths match the regex qr/foo/.
  $app->plugin('CanonicalURL', { should_canonicalize_request => qr/foo/ });

  # Canonicalize only requests with path /foo EXACTLY.
  $app->plugin('CanonicalURL', { should_canonicalize_request => '/foo' });

  # Same as above, but using a subroutine. $_ contains the Mojolicious::Controller for the request.
  use Mojolicious::Plugin::CanonicalURL 'remove_trailing_slashes';
  $app->plugin('CanonicalURL', { should_canonicalize_request => sub { remove_trailing_slashes($_->req->url->path) eq '/foo' } });

  # Same as above, but faster. Code is inlined into the subroutine. This is equally as fast as "should_canonicalize_request => '/foo'" above
  # 'return $next->() unless ' added to the beginning of the string, and ';' added to the end automatically.
  $app->plugin('CanonicalURL', { should_canonicalize_request => \q{remove_trailing_slashes($c->req->url->path) eq '/foo'} } });

  # Same as above, with explicit 'return $next->() unless' at the beginning and ';' at the end.
  $app->plugin('CanonicalURL', { should_canonicalize_request => \q{return $next->() unless remove_trailing_slashes($c->req->url->path) eq '/foo';} } });

  # for multiline code to be inlined, inline_code is recommended instead
  # of should_canonicalize_request
  $app->plugin('CanonicalURL', {
    inline_code => q{
      my $path_no_slashes = remove_trailing_slashes($c->req->url->path);
      return $next->() if $path_no_slashes eq $path1;
      return $next->() if $path_no_slashes eq $path2;
      return $next->() if $path_no_slashes eq $path3;
    },
    # you may pass your own variables for use in inline_code
    captures => {
      '$path1' => \$path1,
      '$path2' => \$path2,
      '$path3' => \$path3,
    },
  });

  # canoncalize all requests that start with /foo
  $app->plugin('CanonicalURL', { should_canonicalize_request => qr{^/foo} });

  # Same as above, but faster because it uses index()
  $app->plugin('CanonicalURL', { should_canonicalize_request => {starts_with => '/foo'} });

  # canoncalize all requests that start with /foo or /bar
  $app->plugin('CanonicalURL', { should_canonicalize_request => [qr{^/foo}, qr{^/bar}] });

  # Same as above, but faster than qr{^/foo} or qr{^/bar} because it uses index()
  $app->plugin('CanonicalURL', { should_canonicalize_request => [{starts_with => '/foo'}, {starts_with => '/bar'}] });

  # Canonicalize all requests except the one with the path /foo
  $app->plugin('CanonicalURL', { should_not_canonicalize_request => '/foo' });

  # All options available to should_canonicalize_request are available to should_not_canonicalize_request.
  # Canonicalize all requests except the one with the path /foo, any request matching qr/bar/, any request
  # starting with /baz, any request with the path /qux/, or any request with the host example.com
  $app->plugin('CanonicalURL', { should_not_canonicalize_request => [
      '/foo',
      qr/bar/,
      {starts_with => '/baz'}
      sub { $_->req->url->path eq '/qux/' },
      \q{$c->req->url->to_abs->host eq 'example.com'},
    ],
  });

  # should_canonicalize_request and should_not_canonicalize_request can be used together
  # All request must start with /foo and must NOT match qr/bar/ to be canonicalized
  # /foo/baz matches
  # /foo/bar does not match
  $app->plugin('CanonicalURL', {
      should_canonicalize_request => {starts_with => '/foo'},
      should_not_canonicalize_request => qr/bar/,
  });

=head1 DESCRIPTION

L<Mojolicious::Plugin::CanonicalURL> is a flexible and fast
L<Mojlicious::Plugin> to give you control over canonicalizing your URLs.
L<Mojolicious::Plugin::CanonicalURL> uses L<Sub::Quote> to build the subroutine
used as an L<Mojolicious/around_action> hook based on the L</OPTIONS> you pass
in to make it as fast as possible. L<Mojolicious::Plugin::CanonicalURL> by
default redirects URLs ending with a slash in their path to their non-slash
equivalent. All redirected URLs will have a status code of
L<301|https://en.wikipedia.org/wiki/HTTP_301>.

L</end_with_slash> can be set to C<1> to instead require that canonicalized
URLs end with a slash.

L</should_canonicalize_request> and/or L</should_not_canonicalize_request> can be set to
override the default that all URLs will be canonicalized.

When redirecting to the canonicalized path, all other attributes of the
L<Mojo::URL> for the request will remain the same (such as query parameters);
only L<Mojo::URL/path> will change to the canonicalized form.

L<Mojolicious::Plugin::CanonicalURL> will remove multiple trailing slashes and
replace them with one slash if L</end_with_slash> is a C<true> value, or no slashes if
L</end_with_slash> is a C<false> value.

By default, L<Mojolicious::Plugin::CanonicalURL> only works for dynamic actions that have
methods that are called. This means that, by default, this plugin will not work for L<Mojolicious::Lite> routes like this:

  get '/' => {text => 'I ♥ Mojolicious!'};

Or routes in a full app like this:

  sub startup {
    my ($self) = @_;

    my $routes = $self->routes;
    $routes->get('/' => {text => 'I ♥ Mojolicious!'});
  }

See L</canonicalize_before_render> to canonicalize non-dynamic actions.

=head1 OPTIONS

=head2 end_with_slash

  # Require all canonicalized URLs do not end with a slash. This is the default.
  $app->plugin('CanonicalURL', { end_with_slash => undef });

  # Require all canonicalized URLs end with a slash.
  $app->plugin('CanonicalURL', { end_with_slash => 1 });

Sets whether canonicalized URLs should end with a slash or not. Default is
C<undef> (canonicalzed URLs will not end with a slash). This matches up with
how L<Mojolicious> generates L<Mojolicious::Guides::Routing/Named-routes>,
which have no slash at the end. Make sure that if you set L<end_with_slash> to
C<1> and you used named routes that you keep this in mind so that you do not
redirect anytime a named route URL is used. A role using
L<Class::Method::Modifiers/after-methods> may be the correct way to add
trailing slashes by setting the L<Mojo::Path/trailing_slash> to C<1> on the
L<Mojo::URL>.

If L</end_with_slash> is C<false>, an exception is made for the root path, C</>,
according to L<RFC
2616|https://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html>:

  Note that the absolute path cannot be empty; if none is present in the original URI, it MUST be given as "/" (the server root).

L<Mojolicious::Plugin::CanonicalURL> will replace multiple trailing slashes
with one if L</end_with_slash> is C<true>, or zero if L</end_with_slash> is
C<false>.

=head2 should_canonicalize_request

L</should_canonicalize_request> is responsible for determining if a given
request should be canonicalized or not. L</should_canonicalize_request> can be
several different types of values.

L</should_canonicalize_request> may be combined with L</should_not_canonicalize_request>
to specify conditions that must be met and conditions that must not be met for a request
to be canonicalized.

=head3 SCALAR

If L<should_canonicalize_request> is passed a scalar value, it will only canonicalize a reqeust
if its path (L<Mojo::URL/path>) matches the provided path. Note that all paths are compared without any trailing
slashes, regardless of the value of L</end_with_slash>. All scalar values should be valid requests paths that start with a C</>.

  # will only canonicalize paths where $c->req->url->path eq '/foo'
  $app->plugin('CanonicalURL', { should_canonicalize_request => '/foo' });

=head3 REGEXP

If L</should_canonicalize_request> is passed regex, the regex will be compared
to the path of the request. If the regex does not match against the path, the
request will not be canonicalized.

  # $c->req->url->path =~ qr/foo/ must be true for a request to be canonicalized
  $app->plugin('CanonicalURL', { should_canonicalize_request => qr/foo/ });

=head3 CODE

If L</should_canonicalize_request> is passed a subroutine, C<$_> will contain
the L<Mojolicious::Controller> for the current request, and the truth value
returned by the subroutine will determine if the request is canonicalized. If a C<true> value
is returned, the request will be canonicalized. If a C<false> value is returned, the request
will not be canonicalized.

  # will only canonicalize request if path eq '/foo'
  $app->plugin('CanonicalURL', {
    should_canonicalize_request => sub {
      return remove_trailing_slashes($_->req->url->path) ne '/foo';
    },
  });

=head3 SCALAR REFERENCE

L</"SCALAR REFERENCE"> is similar to L</CODE>, except that the code will be
inlined into the generated method, avoiding the extra subroutine call.

  # 'return $next->() unless ' is added if there is no return at the beginning, and ';' added at the end if it does not exist
  $app->plugin('CanonicalURL', {
    should_canonicalize_request => \q{remove_trailing_slashes($c->req->url->path) eq '/foo'},
  });

C<$next> and C<$c> from L<Mojolicious/around_action> are available.
"return $next->() unless " is added if the string does not begin with
C<return>, and C<;> is added to the end if it does not exist. If manually
returning without performing canonicalization, make sure to return
"$next->()".

  return $next->();

You also can have your own variables through L</captures>:

  my $my_path = '/foo';
  $app->plugin('CanonicalURL', {
    captures => { '$my_path' => \$my_path },
    should_canonicalize_request => \q{remove_trailing_slashes($c->req->url->path) eq $my_path},
  });

But be careful not to use any L</"RESERVED VARIABLE NAMES">.

This is really meant for small one-liners that evaluate to a true/false value. For longer, more custom code, see L</inline_code>.

When comparing paths manually, be sure to handle the case where a path may or may not have a slash at the end.
L<Mojolicious::Plugin::CanonicalURL> provides L</remove_trailing_slashes>, which can be used in inlined code or
exported.

=head3 HASH

L</should_canonicalize_request> may be provided a hash reference to specify what path a request must start with
to be canonicalized. The key must be C<starts_with>, and the value should be a valid path starting with a slash.

  # all reqeusts must start with '/foo' to be canonicalized
  $app->plugin('CanonicalURL', { should_canonicalize_request => { starts_with => '/foo' } });

In the future, this may allow other keys, like C<contains>, which could be a faster form of something like C<qr/bar/>.

=head3 ARRAY

L</should_canonicalize_request> can be passed an array reference with any number of elements as defined
by L</SCALAR>, L</REGEXP>, L</CODE>, L</"SCALAR REFERENCE"> and L</HASH>, and these conditions will be or'ed together, so that a request
will be canonicalized if any of the conditions is true. Note that a L<SCALAR REFERENCE|"SCALAR REFERENCE1"> should just be a condition, without
a C<return> or trailing C<;>.

L</captures> may be used if a scalar reference is provided in the array.

  # Canonicalize any request whose path equals '/foo', any request whose path matches qr/bar/, any request
  # whose path starts with '/baz', any request with the path '/qux/', or any request that has the host example.com
  $app->plugin('CanonicalURL', { should_canonicalize_request => [
      '/foo',
      qr/bar/,
      {starts_with => '/baz'},
      sub { $_->req->url->path eq '/qux/' },
      \q{$c->req->url->to_abs->host eq 'example.com'},
    ],
  });

=head2 should_not_canonicalize_request

L</should_not_canonicalize_request> is responsible for determining if a given
request should be canonicalized or not. L</should_not_canonicalize_request> accepts
the same types of values as L</should_canonicalize_request>, but handles them oppositely.

L</should_not_canonicalize_request> may be combined with L</should_canonicalize_request>
to specify conditions that must not be met and conditions that must be met for a request
to be canonicalized.

=head3 SCALAR

If L<should_not_canonicalize_request> is passed a scalar value, it will only canonicalize a reqeust
if its path (L<Mojo::URL/path>) does not match the provided path. Note that all paths are compared without any trailing
slashes, regardless of the value of L</end_with_slash>. All scalar values should be valid requests paths that start with a C</>.

  # will only canonicalize paths where $c->req->url->path ne '/foo'
  $app->plugin('CanonicalURL', { should_not_canonicalize_request => '/foo' });

=head3 REGEXP

If L</should_not_canonicalize_request> is passed regex, the regex will be compared
to the path of the request. If the regex matches against the path, the
request will not be canonicalized.

  # $c->req->url->path !~ qr/foo/ must be true for a request to be canonicalized
  $app->plugin('CanonicalURL', { should_not_canonicalize_request => qr/foo/ });

=head3 CODE

If L</should_not_canonicalize_request> is passed a subroutine, C<$_> will contain
the L<Mojolicious::Controller> for the current request, and the truth value
returned by the subroutine will determine if the request is canonicalized. If a C<true> value
is returned, the request will not be canonicalized. If a C<false> value is returned, the request
will be canonicalized.

  # will not canonicalize request if path eq '/foo'
  $app->plugin('CanonicalURL', {
    should_not_canonicalize_request => sub {
      return remove_trailing_slashes($_->req->url->path) eq '/foo';
    },
  });

=head3 SCALAR REFERENCE

L<SCALAR REFERECE|"SCALAR REFERENCE1"> is similar to L<CODE|"CODE1">, except that the code will be
inlined into the generated method, avoiding the extra subroutine call.

  # 'return $next->() if ' is added if there is no return at the beginning, and ';' added at the end if it does not exist
  $app->plugin('CanonicalURL', {
    should_not_canonicalize_request => \q{remove_trailing_slashes($c->req->url->path) eq '/foo'},
  });

C<$next> and C<$c> from L<Mojolicious/around_action> are available.
"return $next->() if " is added if the string does not begin with
C<return>, and C<;> is added to the end if it does not exist. If manually
returning without performing canonicalization, make sure to return
"$next->()".

  return $next->();

You also can have your own variables through L</captures>:

  my $my_path = '/foo';
  $app->plugin('CanonicalURL', {
    captures => { '$my_path' => \$my_path },
    should_not_canonicalize_request => \q{remove_trailing_slashes($c->req->url->path) eq $my_path},
  });

But be careful not to use any L</"RESERVED VARIABLE NAMES">.

This is really meant for small one-liners that evaluate to a true/false value. For longer, more custom code, see L</inline_code>.

When comparing paths manually, be sure to handle the case where a path may or may not have a slash at the end.
L<Mojolicious::Plugin::CanonicalURL> provides L</remove_trailing_slashes>, which can be used in inlined code or
exported.

=head3 HASH

L</should_not_canonicalize_request> may be provided a hash reference to specify what paths a request must start with
to not be canonicalized. The key must be C<starts_with>, and the value should be a valid path starting with a slash.

  # all reqeusts must not start with '/foo' to be canonicalized
  $app->plugin('CanonicalURL', { should_not_canonicalize_request => { starts_with => '/foo' } });

In the future, this may allow other keys, like C<contains>, which could be a faster form of something like C<qr/bar/>.

=head3 ARRAY

L</should_not_canonicalize_request> can be passed an array reference with any number of elements as defined
by L<SCALAR|"SCALAR2">, L<REGEXP|"REGEXP1">, L<CODE|"CODE1">, L<SCALAR REFERENCE|"SCALAR REFERENCE1"> and L<HASH|"HASH1">, and these conditions will be or'ed together, so that a request
will not be canonicalized if any of the conditions is true. Note that a L<SCALAR REFERENCE|"SCALAR REFERENCE1"> should just be a condition, without
a C<return> or trailing C<;>.

L</captures> may be used if a scalar reference is provided in the array.

  # Do not canonicalize any request whose path equals '/foo', any request whose path matches qr/bar/, any request
  # whose path starts with '/baz', any request with the path '/qux/', or any request that has the host example.com
  $app->plugin('CanonicalURL', { should_not_canonicalize_request => [
      '/foo',
      qr/bar/,
      {starts_with => '/baz'},
      sub { $_->req->url->path eq '/qux/' },
      \q{$c->req->url->to_abs->host eq 'example.com'},
    ],
  });

=head2 inline_code

L</inline_code> allows you to pass in code that will be run right before the code
to canonicalize a request runs, but after any code generated by L</should_canonicalize_request> or L</should_not_canonicalize_request>.
This is meant for larger, more custom code than the scalar inline code
allowed for L</should_canonicalize_request> and L</should_not_canonicalize_request>.

  $app->plugin('CanonicalURL', {
    inline_code => q{
      # custom code
      if (...) {
        $c->app->log("Path is " . $c->req->url->path);
        return $next->() if remove_trailing_slashes($c->req->url->path) eq '/foo';
      }
    },
  });

If L</inline_code> is set, L</captures> may be used to access your variables inside of the code:

  $app->plugin('CanonicalURL', {
    captures => { '$my_var' => \$my_var },
    inline_code => q{
      if (...) {
        # custom code
        $c->app->log("My var is $my_var");
        return $next->() if $c->req->url->path eq $my_var;
      }
    },
  });

When comparing paths manually, be sure to handle the case where a path may or may not have a slash at the end.
L<Mojolicious::Plugin::CanonicalURL> provides L</remove_trailing_slashes>, which can be used in inlined code or
exported.

=head2 captures

  my $skip = {
    '/path_one' => 1,
    '/path_two' => 1,
  };

  $app->plugin('CanonicalURL', {
    captures => { '$skip' => \$skip },
    should_canonicalize_request => \'exists $skip->{remove_trailing_slashes($c->req->url->path)}',
  });

  # same as above using inline_code
  $app->plugin('CanonicalURL', {
    captures => { '$skip' => \$skip },
    inline_code => q{
      if (exists $skip->{$c->req->url->path}) {
        return $next->();
      }
    },
  });

L</captures> corresponds to captures in L<Sub::Quote>:

  \%captures is a hashref of variables that will be made available to the code.
  The keys should be the full name of the variable to be made available, including the sigil.
  The values should be references to the values. The variables will contain copies of the values.

L</captures> can only be used when L</should_canonicalize_request> or L</should_not_canonicalize_request> use L</"SCALAR REFERENCE"> or L<SCALAR REFERENCE|"SCALAR REFERENCE1">,
or when a scalar reference is provided in L</ARRAY> or L<ARRAY|/"ARRAY1"> for L</should_canonicalize_request> or L</should_not_canonicalize_request>,
or when L</inline_code> is set.

See L<Sub::Quote/SYNOPSIS>'s C<Silly::dragon> for an example using captures.

=head2 canonicalize_before_render

  # Now the before_render hook will be used to canonicalize requests in addition to the around_action hook.
  $app->plugin('CanonicalURL', {
    canonicalize_before_render => 1,
  });

  # useful for actions defined like this in Mojolicious::Lite which will not trigger the around_action hook
  get '/' => {text => 'I ♥ Mojolicious!'};

  # or actions like this in the full app
  sub startup {
    my ($self) = @_;

    my $routes = $self->routes;
    $routes->get('/' => {text => 'I ♥ Mojolicious!'});
  }

For text routes as shown above, no action is actually called, because the text is stored with the route and
rendered from the string without being wrapped in a subroutine. This means that
requests for these routes cannot be canonicalized using the
L<Mojolicious/around_action> hook. When using routes of
this format, L</canonicalize_before_render> must be set to C<1> so that the
L<Mojolicious/before_render> hook will be used instead to canonicalize these
requests. If a request was already successfully canonicalized (or redirected by other means) in the
L<Mojolicious/around_action> hook, then the L<Mojolicious/before_render> hook
will return early. However, both the L<Mojolicious/around_action> and
L<Mojolicious/before_render> hooks will be called when a request does not need
to be canonicalized, performing the same work twice (the performance of this
shouldn't be a problem, especially for lite apps).

By default, L</canonicalize_before_render> is C<undef>, meaning that the
L<Mojolicious/before_render> hook is not used to canonicalize requests, only
the L<Mojolicious/around_action> hook is used.

=head1 EXPORTED

=head2 remove_trailing_slashes

Removes all trailing slashes from a path. Accepts a string or a blessed reference that overloads C<"">, such as L<Mojo::Path>. This is useful for examining paths.

  # export to use in your code
  use Mojolicious::Plugin::CanonicalURL 'remove_trailing_slashes';
  $app->plugin('CanonicalURL', { should_canonicalize_request => sub { remove_trailing_slashes($_->req->url->path) eq '/foo' } });

  # or use in code that is inlined
  $app->plugin('CanonicalURL', { should_canonicalize_request => \q{remove_trailing_slashes($_->req->url->path) eq '/foo'} });

L</remove_trailing_slashes> can be exported or used by inlined code, such as when L</should_canonicalize_request> or L</should_not_canonicalize_request> use L</"SCALAR REFERENCE"> or L<SCALAR REFERENCE|"SCALAR REFERENCE1">,
or when L</inline_code> is set.

=head1 RESERVED VARIABLE NAMES

These are the variable names that L<Mojolicious::Plugin::CanonicalURL> uses and you should avoid using when declaring your own
variables via L</inline_code>, L</"SCALAR REFERENCE">, L<SCALAR REFERENCE|"SCALAR REFERENCE1">, or L</captures>:

=over

=item

C<$c>

=item

C<$next>

=item

C<$_mpcu_path>

=item

C<$_mpcu_path_length>

=item

C<$_mpcu_path_with_no_slashes_at_the_end>

=item

C<$_mpcu_*>

=back

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Adam Hopkins

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

=over

=item

L<Mojolicious>

=item

L<Mojolicious::Plugin>

=back

=cut
