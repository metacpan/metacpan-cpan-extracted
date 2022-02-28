# NAME

Mojolicious::Plugin::Pager - Pagination plugin for Mojolicious

# SYNOPSIS

## Example lite app

    use Mojolicious::Lite;

    plugin "pager";

    get "/" => sub {
      my $c = shift;
      $c->stash(total_items => 1431, items_per_page => 20);
    };

## Example template

    <ul class="pager">
      % for my $page (pages_for $total_items / $items_per_page) {
        <li><%= pager_link $page %></li>
      % }
    </ul>

## Custom template

    <ul class="pager">
      % for my $page (pages_for $total_items / $items_per_page) {
        % my $url = url_with; $url->query->param(x => $page->{n});
        <li><%= link_to "hey!", $url %></li>
      % }
    </ul>

# DESCRIPTION

[Mojolicious::Plugin::Pager](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3APager) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin for creating paged
navigation, without getting in the way. There are other plugins which ship with
complete markup, but this is often not the markup that _you_ want.

# HELPERS

## pager\_link

    $bytestream = $c->pager_link(\%page, @args);
    $bytestream = $c->pager_link(\%page, @args, sub { int(rand 100) });

Takes a `%page` hash and creates an anchor using
["link\_to" in Mojolicious::Controller](https://metacpan.org/pod/Mojolicious%3A%3AController#link_to). `@args` is passed on, without
modification, to `link_to()`. The anchor generated has some classes added.

See ["pages\_for"](#pages_for) for detail about `%page`.

Examples output:

    <a href="?page=2" class="prev" rel="prev">12</a>
    <a href="?page=1" class="first">1</a>
    <a href="?page=2" class="page">2</a>
    <a href="?page=3" class="active">3</a>
    <a href="?page=4" class="page">4</a>
    <a href="?page=5" class="page">5</a>
    <a href="?page=6" class="last">6</a>
    <a href="?page=3" class="next" rel="next">3</a>

## pages\_for

    @pages = $self->pages_for($total_pages);
    @pages = $self->pages_for(\%args)
    @pages = $self->pages_for;

Returns a list of `%page` hash-refs, that can be passed on to ["pager\_link"](#pager_link).

Example `%page`:

    {
      n       => 2,    # page number
      current => 1,    # if page number matches "page" query parameter
      first   => 1,    # if this is the first page
      last    => 1,    # if this is the last page
      next    => 1,    # if this is last, that brings you to the next page
      prev    => 1,    # if this is first, that brings you to the previous page
    }

`%args` can contain:

- current

    Default to the "page" query param or "1".

- items\_per\_page

    Only useful unless `total` is specified. Default to 20.

- size

    The max number of pages to show in the pagination. Default to 8 + "Previous"
    and "Next" links.

- total

    The total number of pages. Default to "1" or...

        $total = $args->{total_items} / $args->{items_per_page}
        $total = $c->stash('total_items') / $c->stash('items_per_page')

# METHODS

## register

    $app->plugin(pager => \%config);

Used to register this plugin and the ["HELPERS"](#helpers) above. `%config` can be:

- classes

    Used to set default class names, used by ["pager\_link"](#pager_link).

    Default:

        {
          current => "active",
          first   => "first",
          last    => "last",
          next    => "next",
          prev    => "prev",
          normal  => "page",
        }

- param\_name

    The query parameter that will be looked up to figure out which page you are on.
    Can also be set in ["stash" in Mojolicious::Controller](https://metacpan.org/pod/Mojolicious%3A%3AController#stash) on each request under the
    name "page\_param\_name".

    Default: "page"

# AUTHOR

Jan Henning Thorsen

# COPYRIGHT AND LICENSE

Copyright (C) 2017, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
