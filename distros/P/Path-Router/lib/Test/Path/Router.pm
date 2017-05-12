package Test::Path::Router;
our $AUTHORITY = 'cpan:STEVAN';
# ABSTRACT: A testing module for testing routes
$Test::Path::Router::VERSION = '0.15';
use strict;
use warnings;

use Test::Builder 1.001013 ();
use Test::Deep    0.113    ();
use Data::Dumper  2.154    ();
use Sub::Exporter 0.981;

my @exports = qw/
    routes_ok
    path_ok
    path_not_ok
    path_is
    mapping_ok
    mapping_not_ok
    mapping_is
/;

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { default => \@exports }
});

our $Test = Test::Builder->new;

sub routes_ok {
    my ($router, $routes, $message) = @_;
    my ($passed, $reason);
    foreach my $path (keys %$routes) {
        my $mapping = $routes->{$path};

        my $generated_path = $router->uri_for(%{$mapping});

        $generated_path = '' unless defined $generated_path;

        # the path generated from the hash
        # is the same as the path supplied
        if ($path ne $generated_path) {
            $Test->ok(0, $message);
            $Test->diag("... paths do not match\n" .
                        "   got:      '" . $generated_path . "'\n" .
                        "   expected: '" . $path . "'");
            return;
        }

        my $match = $router->match($path);
        my $generated_mapping = $match && $match->mapping;

        $Test->ok( $match->path eq $path, "matched path (" . $match->path . ") and requested paths ($path) match" );

        # the path supplied produces the
        # same match as the hash supplied

        unless (Test::Deep::eq_deeply($generated_mapping, $mapping)) {
            $Test->ok(0, $message);
            $Test->diag("... mappings do not match for '$path'\n" .
                        "   got:      " . _dump_mapping_info($generated_mapping) . "\n" .
                        "   expected: " . _dump_mapping_info($mapping));
            return;
        }
    }
    $Test->ok(1, $message);
}

sub path_ok {
    my ($router, $path, $message) = @_;
    if ($router->match($path)) {
        $Test->ok(1, $message);
    }
    else {
        $Test->ok(0, $message);
    }
}

sub path_not_ok {
    my ($router, $path, $message) = @_;
    unless ($router->match($path)) {
        $Test->ok(1, $message);
    }
    else {
        $Test->ok(0, $message);
    }
}

sub path_is {
    my ($router, $path, $expected, $message) = @_;

    my $generated_mapping = $router->match($path)->mapping;

    # the path supplied produces the
    # same match as the hash supplied

    unless (Test::Deep::eq_deeply($generated_mapping, $expected)) {
        $Test->ok(0, $message);
        $Test->diag("... mappings do not match for '$path'\n" .
                    "   got:      '" . _dump_mapping_info($generated_mapping) . "'\n" .
                    "   expected: '" . _dump_mapping_info($expected) . "'");
    }
    else {
        $Test->ok(1, $message);
    }
}

sub mapping_ok {
    my ($router, $mapping, $message) = @_;
    if (defined $router->uri_for(%{$mapping})) {
        $Test->ok(1, $message);
    }
    else {
        $Test->ok(0, $message);
    }
}

sub mapping_not_ok {
    my ($router, $mapping, $message) = @_;
    unless (defined $router->uri_for(%{$mapping})) {
        $Test->ok(1, $message);
    }
    else {
        $Test->ok(0, $message);
    }
}

sub mapping_is {
    my ($router, $mapping, $expected, $message) = @_;

    my $generated_path = $router->uri_for(%{$mapping});

    # the path generated from the hash
    # is the same as the path supplied
    if (
        (defined $generated_path and not defined $expected) or
        (defined $expected and not defined $generated_path) or
        (defined $generated_path and defined $expected
            and $generated_path ne $expected)
        ) {
        $_ = defined $_ ? qq{'$_'} : qq{undef}
            for $generated_path, $expected;
        $Test->ok(0, $message);
        $Test->diag("... paths do not match\n" .
                    "   got:      $generated_path\n" .
                    "   expected: $expected");
    }
    else {
        $Test->ok(1, $message);
    }
}

## helper function

sub _dump_mapping_info {
    my ($mapping) = @_;
    local $Data::Dumper::Indent = 0;
    my $out = Data::Dumper::Dumper($mapping);
    $out =~ s/\$VAR\d\s*=\s*//;
    return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Path::Router - A testing module for testing routes

=head1 VERSION

version 0.15

=head1 SYNOPSIS

  use Test::More plan => 1;
  use Test::Path::Router;

  my $router = Path::Router->new;

  # ... define some routes

  path_ok($router, 'admin/remove_user/56', '... this is a valid path');

  path_is($router,
      'admin/edit_user/5',
      {
          controller => 'admin',
          action     => 'edit_user',
          id         => 5,
      },
  '... the path and mapping match');

  mapping_ok($router, {
      controller => 'admin',
      action     => 'edit_user',
      id         => 5,
  }, '... this maps to a valid path');

  mapping_is($router,
      {
          controller => 'admin',
          action     => 'edit_user',
          id         => 5,
      },
      'admin/edit_user/5',
  '... the mapping and path match');

  routes_ok($router, {
      'admin' => {
          controller => 'admin',
          action     => 'index',
      },
      'admin/add_user' => {
          controller => 'admin',
          action     => 'add_user',
      },
      'admin/edit_user/5' => {
          controller => 'admin',
          action     => 'edit_user',
          id         => 5,
      }
  },
  "... our routes are valid");

=head1 DESCRIPTION

This module helps in testing out your path routes, to make sure
they are valid.

=head1 EXPORTED FUNCTIONS

=over 4

=item B<path_ok ($router, $path, ?$message)>

=item B<path_not_ok ($router, $path, ?$message)>

=item B<path_is ($router, $path, $mapping, ?$message)>

=item B<mapping_ok ($router, $mapping, ?$message)>

=item B<mapping_not_ok ($router, $mapping, ?$message)>

=item B<mapping_is ($router, $mapping, $path, ?$message)>

=item B<routes_ok ($router, \%test_routes, ?$message)>

This test function will accept a set of C<%test_routes> which
will get checked against your C<$router> instance. This will
check to be sure that all paths in C<%test_routes> procude
the expected mappings, and that all mappings also produce the
expected paths. It basically assures you that your paths
are roundtrippable, so that you can be confident in them.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
