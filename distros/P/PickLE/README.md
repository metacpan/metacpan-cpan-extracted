[![MetaCPAN Release](https://badge.fury.io/pl/PickLE.svg)](https://metacpan.org/release/PickLE)
# NAME

PickLE - An electronic component pick list application and file parser library.

# SUMMARY

An application and a parsing library to create an electronic component pick list
file format designed to be human-readable and completely usable in its own
plain-text form.

# SYNOPSIS

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

For the command-line application you can just run `pickle` and you'll be
presented with the up-to-date usage of the tool.

This bundle also comes with a web server that can be used as a microservice to
parse PickLE documents. In order to use this you just run `picklews` which is a
[Mojolicious](https://metacpan.org/pod/Mojolicious) web application and accepts the common command-line arguments
described in [Mojolicious::Commands](https://metacpan.org/pod/Mojolicious%3A%3ACommands).

# REQUIREMENTS

You must have installed all of the third-party libraries listed in `cpanfile`.

# LICENSE

This library is free software; you may redistribute and/or modify it under the
same terms as Perl itself.

# AUTHOR

Nathan Campos <nathan@innoveworkshop.com>

# COPYRIGHT

Copyright (c) 2022- Nathan Campos.
