#!/usr/bin/env perl

use Mojolicious::Lite;
use lib '../lib', '../t/lib';
use Local::Schema;

my $schema = Local::Schema->connect(
    'dbi:SQLite:data.db',
);
plugin DBIC => {
    schema => $schema,
};

get '/notes' => {
    controller => 'DBIC',
    action => 'list',
    resultset => 'Notes',
    template => 'notes.list',
} => 'notes.list';

get '/notes/:id' => {
    controller => 'DBIC',
    action => 'get',
    resultset => 'Notes',
    template => 'notes.get',
} => 'notes.get';

get '/events' => {
    controller => 'DBIC',
    action => 'list',
    resultset => 'Events',
    template => 'events.list',
} => 'events.list';

app->start;
__DATA__
@@ notes.list.html.ep
<ul>
    % for my $row ( $resultset->all ) {
        <li><%=
            link_to $row->title,
                'notes.get', { id => $row->id }
        %></li>
    % }
</ul>

@@ notes.get.html.ep
% title $row->title;
<h1><%= $row->title %></h1>
%== $row->description

@@ events.list.html.ep
<ul>
    % for my $row ( $resultset->all ) {
        <li><%= $row->title %></li>
    % }
</ul>

