package Mojolicious::Plugin::ErrorsAndWarnings;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';

has config_key => 'codes';
has stash_key  => 'plugin.errors';

sub register {
  my ($plugin, $app, $conf) = @_;

  for my $type (qw/errors warnings/) {
    my $singular = ($type =~ m,^(.*)s$,,)[0];

    # Create helpers to add values to relevant stash
    $app->helper("add_$singular" => sub { $plugin->_add_to_stash($type, @_) });

    # Create accessors for errors and warnings
    $app->helper($type => sub { shift->stash->{$plugin->stash_key}->{$type} });
  }
}

sub _add_to_stash {
  my ($plugin, $type, $app, $name, %attrs) = @_;

  my $data = {};
  if (my $conf = $app->config($plugin->config_key)) {
    $data = $conf->{$name} // $conf->{default} // {};
  }

  # Add the code name and attrs. Added in this order because %attrs can
  # override the code.
  $data = {%{$data}, code => $name, %attrs};
  push @{$app->stash->{$plugin->stash_key}->{$type}}, $data;

  return $data;
}

1;

=head1 NAME

Mojolicious::Plugin::ErrorsAndWarnings - Store errors & warnings during a request

=head1 SYNOPSIS

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

=head1 DESCRIPTION

L<Mojolicious::Plugin::ErrorsAndWarnings> is a basic plugin for L<Mojolicious>
which provides helpers to store and retrieve user-defined errors and warnings.
This is particularly useful to help collect errors and warnings from within
multiple method calls during a request cycle. At the end of the request, the
error and warning objects provide additional information about any problems
encountered while performing an operation.

Adding errors or warnings will store them under the L<Mojolicious
stash|Mojolicious::Controller/stash> key C<plugin.errors> by default. Don't
access this stash value directly. Use the C<$c-E<gt>errors> and
C<$c-E<gt>warnings> accessors instead.

  # add errors and warnings using the imported helpers
  $c->add_error('first_error');
  $c->add_warning('first_warning');

  # {"errors":[{"code":"first_error"}], "warnings":[{"code":"first_warning"}]}
  $c->render(json => {errors => $c->errors, warnings => $c->warnings});

The first argument to L</add_error> or L</add_warning> is referred to as the
C<code>. This an application-specific error or warning code, expressed as a
string value.

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

Additional members can be added to provide more specific information about the
problem. See also L<http://jsonapi.org/format/#errors> for examples of other
members you might want to use.

=head1 ATTRIBUTES

L<Mojolicious::Plugin::ErrorsAndWarnings> implements the following attributes.

=head2 config_key

The name of the config key to inspect for user-defined error and warning codes.
Defaults to C<codes>.

The plugin will merge default values from an app's config if a matching key is
found. See the example below.

  # Mojolicious::Lite example merging config values
  use Mojolicious::Lite;

  plugin 'ErrorsAndWarnings';

  app->config({
    # config_key attribute is `codes' by default
    codes => {
      # Default key/values merged for unmatched code names
      'default'            => {status => 400},

      # Global codes
      'forbidden'          => {status => 403, title => 'Permission denied to resource.'},
      'not_found'          => {status => 404, title => 'Not found.'},
      'method_not_allowed' => {status => 405, title => 'Method not allowed.'},
    },
  });

  get '/' => sub {
    my $c = shift;

    $c->add_error('not_found');
    $c->add_error('user_defined_err', foo => 'bar bar' );

    # {
    #    "errors": [
    #        {
    #            "code": "not_found",
    #            "status": 404,
    #            "title": "Not found."
    #        },
    #        {
    #            "code": "user_defined_err",
    #            "status": 400,
    #            "foo": "bar bar"
    #        }
    #    ]
    # }
    $c->render(json => { errors => $c->errors });
  };

=head2 stash_key

Name of the L<Mojolicious stash|Mojolicious::Controller/stash> key to store the
errors and warnings. Defaults to C<plugin.errors>.

Don't access this stash value directly. Use the C<$c-E<gt>errors> and
C<$c-E<gt>warnings> accessors instead.

=head1 HELPERS

L<Mojolicious::Plugin::ErrorsAndWarnings> implements the following helpers.

=head2 add_error

  $self->add_error('user_not_found');
  $self->add_error('user_not_found', additional => 'Error Attr');
  $self->add_error('user_not_found', code => 'rename_error_code');

Pushes to the errors stash.

=head2 add_warning

  $self->add_warning('field_ignored');
  $self->add_warning('field_ignored', path => 'username');
  $self->add_warning('field_ignored', code => 'rename_warning_code');

Pushes to the warnings stash.

=head2 errors

Returns an C<ARRAYREF> of errors.

=head2 warnings

Returns an C<ARRAYREF> of warnings.

=head1 METHODS

L<Mojolicious::Plugin::Config> inherits all methods from L<Mojolicious::Plugin>
and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, Paul Williams.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Paul Williams <kwakwa@cpan.org>

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
