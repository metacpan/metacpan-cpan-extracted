#!/usr/bin/env perl

use 5.10.1;
use strict;
use utf8;
use warnings;
use Mojolicious::Lite;

get '/' => sub {
    shift->render('index');
};

app->start('fastcgi');

__DATA__

@@ index.html.ep
<table>
    <tr>
        <td>
            Perl
        </td>
        <td>
            %== $^V
        </td>
    </tr>
    <tr>
        <td>
            Mojolicious
        </td>
        <td>
            %== Mojolicious->VERSION
        </td>
    </tr>
    <tr>
        <td>
            Mojo::Server::FastCGI
        </td>
        <td>
            %== Mojo::Server::FastCGI->VERSION
        </td>
    </tr>
</table>
