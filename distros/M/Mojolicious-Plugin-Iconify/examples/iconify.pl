#!/usr/bin/perl

use Mojolicious::Lite;

plugin 'Iconify';
plugin 'Iconify::API' => { collections => 'iconify-collections-json/json' };

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
<body class="container-fluid p-4">

    <h1 class="text-center mb-5">I "<%= icon('noto:red-heart') %>" Mojolicious!</h1>

    <div class="row">
    % foreach my $prefix (iconify_api_collections) {
        % my $info = iconify_api_collection_info($prefix);
        <div class="col-sm-3">
            <div class="card mb-4">
                <div class="card-header">
                    <div class="row">
                        <div class="col-sm-8">
                            <%= $info->{name} %>
                        </div>
                        <div class="col-sm-4 text-right">
                            <span class="badge badge-info"><%= $info->{category} %></span>
                        </div>
                    </div>
                </div>
                <div class="card-body">
                    <div class="text-center">
                        <ul class="list-inline m-0">
                        % foreach my $sample (@{$info->{samples}}) {
                            <li class="list-inline-item">
                                %= iconify_icon "$prefix:$sample", size => 32
                            </li>
                        % }
                        </ul>
                    </div>
                    <p class="card-text">
                        <dl>
                            <dt>Prefix</dt>
                            <dd><%= $prefix %></dd>
                            <dt>Total</dt>
                            <dd><%= $info->{total} %></dd>
                            <dt>License</dt>
                            <dd><%= $info->{license}->{title} %></dd>
                            <dt>Author</dt>
                            <dd><a href="<%= $info->{author}->{link} %>"><%= $info->{author}->{name} %></a></dd>
                        </dl>
                    </p>
                </div>
            </div>
        </div>
    % }
    <div>
</body>
</html>
