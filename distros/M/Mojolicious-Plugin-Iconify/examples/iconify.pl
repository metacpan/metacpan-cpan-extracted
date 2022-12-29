#!/usr/bin/perl

use Mojolicious::Lite;

plugin 'Iconify';
plugin 'Iconify::API' => { collections => '/path-of-iconify-collections-json/json' };

get '/' => 'index';

app->start;
__DATA__

@@ index.html.ep
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@latest/dist/css/bootstrap.min.css">

    <title>Mojolicious::Plugin::Iconify</title>

    %= iconify_js
    %= iconify_api_js
</head>
<body class="container p-4">

    <h1 class="text-center mb-5">I "<%= iconify_icon('noto:red-heart') %>" Mojolicious!</h1>

    <table class="table table-striped">
        <thead>
            <tr>
                <th>Name</th>
                <th>Samples</th>
                <th>Category</th>
                <th>Prefix</th>
                <th>Total</th>
                <th>License</th>
                <th>Author</th>
            </tr>
        </thead>
        <tbody>
        % foreach my $prefix (iconify_api_collections) {
            % my $info = iconify_api_collection_info($prefix);
            <tr>
                <td><%= $info->{name} %></td>
                <td>
                    % foreach my $sample (@{$info->{samples}}) {
                        %= iconify_icon "$prefix:$sample", size => 24
                    % }
                </td>
                <td><%= $info->{category} %></td>
                <td><%= $prefix %></td>
                <td><%= $info->{total} %></td>
                <td><%= $info->{license}->{title} %></td>
                <td><a href="<%= $info->{author}->{link} %>"><%= $info->{author}->{name} %></a></td>
            </tr>
        % }
        </tbody>
    <table>
</body>
</html>
