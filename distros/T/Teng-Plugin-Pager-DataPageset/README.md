# NAME

Teng::Plugin::Pager::DataPageset - Pager using DataPageset

# SYNOPSIS

    package MyApp::DB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('Pager::DataPageset');

    package main;
    my $db = MyApp::DB->new(dbh => $dbh);
    my $page = $c->req->param('page');

    my ($rows, $pager) = $db->search_with_data_pageset(user => {
        type => 3
    },{
        page  => $page,
        rows  => 5,
        total_entries => 10000,
        pages_per_set => 5,
    });

# DESCRIPTION

This is a helper for pagination using Data::Pageset.

# METHODS

## search\_with\_data\_pageset($table\_name, \\%where, \\%opts)

This method returns ArrayRef\[Teng::Row\] and instance of [Data::Pageset](http://search.cpan.org/perldoc?Data::Pageset).

- $opts->{page}

    Current page number.

- $opts->{rows}

    The number of entries per page.

- $opts->{total\_entries}

    See [Data::Pageset](http://search.cpan.org/perldoc?Data::Pageset).

- $opts->{paegs\_per\_set}

    See [Data::Pageset](http://search.cpan.org/perldoc?Data::Pageset).

- $opts->{mode}

    See [Data::Pageset](http://search.cpan.org/perldoc?Data::Pageset).

# LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokubass <tokubass {at} cpan.org>
