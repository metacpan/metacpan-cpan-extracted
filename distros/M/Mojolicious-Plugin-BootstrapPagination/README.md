# NAME

Mojolicious::Plugin::BootstrapPagination - Page Navigator plugin for Mojolicious
This module has derived from [Mojolicious::Plugin::PageNavigator](http://search.cpan.org/perldoc?Mojolicious::Plugin::PageNavigator)

# SYNOPSIS

    # Mojolicious::Lite
    plugin 'bootstrap_pagination'

    # Mojolicious
    $self->plugin( 'bootstrap_pagination' );

# DESCRIPTION

[Mojolicious::Plugin::BootstrapPagination](http://search.cpan.org/perldoc?Mojolicious::Plugin::BootstrapPagination) generates standard page navigation bar, like 
  

<<  1  2 ... 11 12 13 14 15 ... 85 86 >>

# HELPERS

## bootstrap\_pagination

    %= bootstrap_pagination( $current_page, $total_pages, $opts );

### Options

Options is a optional ref hash.

    %= bootstrap_pagination( $current_page, $total_pages, {
        round => 4,
        outer => 2,
        query => "&id=$id",
        start => 1,
        class => 'pagination-lg',
        param => 'page' } );

- round

    Number of pages around the current page. Default: 4.

- outer

    Number of outer window pages (first and last pages). Default 2.

- param

    Name of param for query url. Default: 'page'

- query

    Additional query string to url. Optional.

- start

    Start number for query string. Default: 1. Optional.

# INTERNATIONALIZATION

If you want to use internationalization (I18N), you can pass a code reference via _localize_.

    plugin 'bootstrap_pagination' => {
      localize => \&localize,
    };
    

    sub localize {
      my ($number) = @_;
    

      my %trans = (
        1 => 'one',
        2 => 'two',
        6 => 'six',
        7 => 'seven',
        8 => 'eight',
        9 => 'nine',
       10 => 'ten',
       11 => 'eleven',
       12 => 'twelve',
       13 => 'thirteen',
       14 => 'fourteen',
       15 => 'fifteen',
      );
    

      return $trans{$number};
    }

This will print the words instead of the numbers.

# SEE ALSO

[Mojolicious](http://search.cpan.org/perldoc?Mojolicious), [Mojolicious::Guides](http://search.cpan.org/perldoc?Mojolicious::Guides), [http://mojolicio.us](http://mojolicio.us),[Mojolicious::Plugin::PageNavigator](http://search.cpan.org/perldoc?Mojolicious::Plugin::PageNavigator).

# Repository

https://github.com/dokechin/Mojolicious-Plugin-BootstrapPagination

# LICENSE

Copyright (C) dokechin.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

dokechin <>

# CONTRIBUTORS

Andrey Chips Kuzmin <chipsoid@cpan.org>
