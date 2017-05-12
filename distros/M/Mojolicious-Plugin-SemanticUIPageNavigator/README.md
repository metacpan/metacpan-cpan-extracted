# NAME

Mojolicious::Plugin::SemanticUIPageNavigator - Mojolicious::Plugin::SemanticUIPageNavigator

# VERSION

version 0.0.3

# SYNOPSIS

    # Mojolicious::Lite
    plugin 'SemanticUIPageNavigator';

    # Mojolicious
    $self->plugin( 'SemanticUIPageNavigator');

# DESCRIPTION

[Mojolicious::Plugin::SemanticUIPageNavigator](https://metacpan.org/pod/Mojolicious::Plugin::SemanticUIPageNavigator) generates a page navigation bar based on
SemanticUI framework, just like
首页 上一页 1 2 ... 11 12 13 14 15 ... 85 86 下一页 末页

# NAME

Mojolicious::Plugin::SemanticUIPageNavigator - Page Navigator plugin for Mojolicious,
which is dependent on SemanticUI front-end framework. This module is derived from
[Mojolicious::Plugin::PageNavigator](https://metacpan.org/pod/Mojolicious::Plugin::PageNavigator) and [Mojolicious::Plugin::BootstrapPagination](https://metacpan.org/pod/Mojolicious::Plugin::BootstrapPagination)

# HELPERS

## page\_navigator

    %=  page_navigator( $current_page, $total_pages, $opts );

### Options

Options is a optional ref hash.

    %= page_navigator( $current_page, $total_pages,{
        round => 2,
        outer => 2,
        param => 'page',
      });

- round

    Number of pages around the current page. Default: 3.

- outer

    Number of outer window pages (first and last pages). Default: 2.

- param

    Name of param for query url. Default: 'p'

# SEE ALSO

[Mojolicious::Plugin::BootstrapPagination](https://metacpan.org/pod/Mojolicious::Plugin::BootstrapPagination) ande [Mojolicious::Plugin::PageNavigator](https://metacpan.org/pod/Mojolicious::Plugin::PageNavigator)

# Repository

# COPYRIGHT

Copyright (C) Yan Xueqing

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

yanxq <yanxueqing621@163.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by BerryGenomics.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
