[![Build Status](https://api.travis-ci.org/augensalat/mojolicious-plugin-methodoverride.svg?branch=master)](https://travis-ci.org/augensalat/mojolicious-plugin-methodoverride)

# NAME

Mojolicious::Plugin::MethodOverride - Simulate HTTP Verbs 

# SYNOPSIS

```perl
package My::App;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  $self->plugin('MethodOverride');

  ...
}

1;
```

# DESCRIPTION

This plugin can simulate any HTTP verb (a.k.a. HTTP method) in
environments where HTTP verbs other than GET and POST are not available.
It uses the same approach as in many other restful web frameworks, where
it replaces the "HTTP POST" method with a method given by an "HTTP"
header. It is also possible to define a query parameter for the same
purpose.

Any token built of US-ASCII letters is accepted as a valid value for the
HTTP verb.

# CONFIGURATION

The default HTTP header to override the "HTTP POST" method is
"X-HTTP-Method-Override". Overriding through a query parameter is off by
default.

These settings can be changed in the plugin method call as demonstrated
in the examples below:

```perl
# Mojolicious
$self->plugin(
  MethodOverride => {
    header => 'X-Tunneled-Method',
    param  => 'x-tunneled-method',
  }
);

# Mojolicious::Lite
plugin 'MethodOverride',
  header => 'X-HTTP-Method',
  param  => 'http_method';
```

HTTP header can be disabled by setting to "undef":

```perl
# A Mojolicious app, that enables method overriding
# by query parameter only:
$self->plugin(
  MethodOverride => {
    header => undef,
    param  => 'x-tunneled-method',
  }
);
```

# AUTHOR

Bernhard Graf `<graf at cpan.org>`

# BUGS

Please report any bugs or feature requests to 
"bug-mojolicious-plugin-methodoverride at rt.cpan.org", or through the
web interface at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-MethodOverride.
I will be notified, and then you'll automatically be notified of progress
 on your bug as I make changes.

# SEE ALSO

Plack::Middleware::MethodOverride,
Catalyst::TraitFor::Request::REST::ForBrowsers,
HTTP::Engine::Middleware::MethodOverride,
http://code.google.com/apis/gdata/docs/2.0/basics.html

# LICENSE AND COPYRIGHT

Copyright (C) 2012 - 2015 Bernhard Graf.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.

