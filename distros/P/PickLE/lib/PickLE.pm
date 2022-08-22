#!/usr/bin/env perl

package PickLE;

use strict;
use warnings;
use 5.010;
use version;

our $VERSION = version->declare('v0.1.0');

1;

__END__

=encoding utf8

=head1 NAME

PickLE - An electronic component pick list application and file parser library.

=head1 SUMMARY

An application and a parsing library to create an electronic component pick list
file format designed to be human-readable and completely usable in its own
plain-text form.

=head1 SYNOPSIS

If you're going to use this bundle only as a library to parse PickLE documents
it's super simple:

  use PickLE::Document;

  # Start from scratch.
  my $doc = PickLE::Document->new;
  $doc->add_category($category);
  $doc->save("example.pkl");

  # Load from file.
  $doc = PickLE::Document->load("example.pkl");

  # List all document properties.
  $doc->foreach_property(sub {
    my $property = shift;
    say $property->name . ': ' . $property->value;
  });

  # List all components in each category.
  $doc->foreach_category(sub {
    my $category = shift;
    $category->foreach_component(sub {
      my ($component) = @_;
      say $component->name;
    });
  });

For the command-line application you can just run C<pickle> and you'll be
presented with the up-to-date usage of the tool.

This bundle also comes with a web server that can be used as a microservice to
parse PickLE documents. In order to use this you just run C<picklews> which is a
L<Mojolicious> web application and accepts the common command-line arguments
described in L<Mojolicious::Commands>.

=head1 REQUIREMENTS

You must have installed all of the third-party libraries listed in C<cpanfile>.

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under the
same terms as Perl itself.

=head1 AUTHOR

Nathan Campos <nathan@innoveworkshop.com>

=head1 COPYRIGHT

Copyright (c) 2022- Nathan Campos.

=cut