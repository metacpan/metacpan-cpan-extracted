# Mojolicious::Plugin::ErrorsAndWarnings [![Build Status](https://travis-ci.org/kwakwaversal/mojolicious-plugin-errorsandwarnings.svg?branch=master)](https://travis-ci.org/kwakwaversal/mojolicious-plugin-errorsandwarnings)

Store errors & warnings during a request for the
[Mojolicious](http://mojolicio.us) web framework

```perl
  # Mojolicious example
  package MyApp;
  use Mojo::Base 'Mojolicious';

  sub startup {
    my $self = shift;

    $self->plugin('ErrorsAndWarnings');

    # Router
    my $r = $self->routes;
    $r->get('/')->to(cb => sub {
      my $c = shift;
      $c->add_error('first_error');
      $c->add_error('second_error', more => 'detail');

      # {"errors":[{"code":"first_error"},{"code":"second_error","more":"detail"}]}
      $c->render(json => { errors => $c->errors });
    });
  }

  1;
```

[Mojolicious::Plugin::ErrorsAndWarnings](https://metacpan.org/release/Mojolicious-Plugin-ErrorsAndWarnings)
is a basic plugin for [Mojolicious](https://metacpan.org/release/Mojolicious)
which provides helpers to store and retrieve user-defined errors and warnings.
This is particularly useful to help collect errors and warnings from within
multiple method calls during a request cycle. At the end of the request, the
error and warning objects provide additional information about any problems
encountered while performing an operation.

Adding errors or warnings will store them under the Mojolicious stash key
`plugin.errors` by default. Don't access this stash value directly. Use the
`$c->errors` and `$c->warnings` accessors instead.

```perl
  # add errors and warnings using the imported helpers
  $c->add_error('first_error');
  $c->add_warning('first_warning');

  # {"errors":[{"code":"first_error"}], "warnings":[{"code":"first_warning"}]}
  $c->render(json => {errors => $c->errors, warnings => $c->warnings});
```

The first argument to `add_error` or `add_warning` is referred to as the `code`.
This an application-specific error or warning code, expressed as a string value.

```perl
  $c->add_error('sql', status => 400, title => 'Your SQL is malformed.');
  $c->add_warning('search', title => 'Invalid search column.', path => 'pw');

  # {
  #    "errors": [
  #        {
  #            "code": "sql",
  #            "status": 400,
  #            "title": "Your SQL is malformed."
  #        }
  #    ],
  #    "warnings": [
  #        {
  #            "code": "search",
  #            "path": "password",
  #            "title": "Invalid search column."
  #        }
  #    ]
  # }
  $c->render(json => {errors => $c->errors, warnings => $c->warnings});
```

Additional members can be added to provide more specific information about the
problem. See also <http://jsonapi.org/format/#errors> for examples of other
members you might want to use.
