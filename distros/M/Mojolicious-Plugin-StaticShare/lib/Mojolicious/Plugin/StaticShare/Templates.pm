package Mojolicious::Plugin::StaticShare::Templates;
use utf8;

=pod

=encoding utf8

Доброго всем

=head1 Mojolicious::Plugin::StaticShare::Templates

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::StaticShare::Templates - internal defaults templates.

=head1 TEMPLATES

=head2 layouts/Mojolicious-Plugin-StaticShare/main.html.ep

One main layout.

=head2 Mojolicious-Plugin-StaticShare/header.html.ep

One included header for templates.

=head2 Mojolicious-Plugin-StaticShare/dir.html.ep

Template for render dir content: subdirs, files, markdown index file.

=head2 Mojolicious-Plugin-StaticShare/markdown.html.ep

Template for render parsed content of markdown files.

=head2 Mojolicious-Plugin-StaticShare/pod.html.ep

Template for render parsed content of Perl pod files(.pod, .pl, .pm).

=head2 Mojolicious-Plugin-StaticShare/not_found.html.ep

Template for render 404.

=head2 Mojolicious-Plugin-StaticShare/exception.html.ep

Template for render 500.

=head2 Mojolicious-Plugin-StaticShare/svg.html.ep

All SVG icons as one svg tag.

=cut
1;
__DATA__

@@ layouts/Mojolicious-Plugin-StaticShare/main.html.ep
<!DOCTYPE html>
<html>
<head>
<title><%= stash('title')  %></title>


%# http://realfavicongenerator.net
<link rel="apple-touch-icon" sizes="152x152" href="/apple-touch-icon.png">
<link rel="icon" type="image/png" href="/favicon-32x32.png" sizes="32x32">
<link rel="icon" type="image/png" href="/favicon-16x16.png" sizes="16x16">
<link rel="manifest" href="/manifest.json">
<link rel="mask-icon" href="/safari-pinned-tab.svg" color="#5bbad5">
<meta name="theme-color" content="#ffffff">

<link href="/css/main.css" rel="stylesheet">

% if (stash('pod')) {
<style>

pre {
  background-color: #fafafa;
  border: 1px solid #c1c1c1;
  border-radius: 3px;
  font: 100% Consolas, Menlo, Monaco, Courier, monospace;
  padding: 1em;
}

:not(pre) > code {
  background-color: rgba(0, 0, 0, 0.04);
  border-radius: 3px;
  font: 0.9em Consolas, Menlo, Monaco, Courier, monospace;
  padding: 0.3em;
}

</style>
% }


<meta name="app:name" content="<%= stash('app:name') // 'Mojolicious::Plugin::StaticShare' %>">
%#<meta name="app:version" content="<%= stash('app:version') // 0.01 %>">
<meta name="url:version" content="<%= stash('app:version') // 0.01 %>">

</head>
<body class="white">

%= include 'Mojolicious-Plugin-StaticShare/svg';

%= include 'Mojolicious-Plugin-StaticShare/header';

<main><div class="container clearfix"><%= stash('content') || content %></div></main>

<script src="/mojo/jquery/jquery.js"></script>
%#<script src="/js/dmuploader.min.js"></script>
<script src="/js/jquery.ui.widget.js"></script>
<script src="/js/jquery.fileupload.js"></script>
<script src="/js/velocity.min.js"></script>
<script src="/js/modal.js"></script>
<script src="/js/plugin-static-share.js"></script>

%= javascript begin
  ///console.log('Доброго всем!! ALL GLORY TO GLORIA');
% end

</body>
</html>

@@ Mojolicious-Plugin-StaticShare/dir.html.ep
% layout 'Mojolicious-Plugin-StaticShare/main';

<div class="row">
<div class="dirs-col col s6">

% if ($c->admin) {
<div class="right btn-panel" style="padding:1.2rem 0;">
  <a href="javascript:" class="hide renames"><svg class="icon icon15 black-fill"><use xlink:href="#svg:rename" /></svg></a>
  <a href="javascript:" class="hide del-dirs"><svg class="icon icon15 red-fill fill-lighten-1"><use xlink:href="#svg:dir-delete" /></svg></a>
  <a id="add-dir" href="javascript:" class="btn-flat00" style="display:inline !important;">
    <svg class="icon icon15 lime-fill fill-darken-4"><use xlink:href="#svg:add-dir" /></svg>
    <!--span class="lime-text text-darken-4"><%= i18n 'Add dir' %></span-->
  </a>
</div>

% }

<h2 class="lime-text text-darken-4">
%#  <svg class="icon icon15 lime-fill fill-darken-4"><use xlink:href="#svg:folder"></svg>
%# <%= i18n 'Dirs' %>
  <svg class="icon icon15 lime-fill fill-darken-4"><use xlink:href="#svg:down-right-round" />
  <span class=""><%= i18n 'Down' %></span>
  <span class="chip lime lighten-5" style=""><%= scalar @$dirs %></span>
</h2>

<div class="progress progress-dir white" style="margin:0; padding:0;">
    <div class="determinate lime" style="width: 0%"></div>
</div>

<ul class="collection dirs" style="margin-top:0;">
  <li class="collection-item dir lime darken-4 hide" style="position:relative;"><!-- template new folder -->
    <div class="input-field" style="padding-left:2rem; padding-right:4rem; position:relative;">
      <svg class="icon icon15 lime-fill fill-lighten-5" style="position:absolute; left:0; top:0.3rem;"><use xlink:href="#svg:folder"></svg>
      <input type="text" name="dir-name" class="" style="width:100%;" placeholder="<%= i18n 'new dir name'%>" >
      <a href="javascript:" _href="<%= $url_path->to_route %>" class="save-dir" style="position:absolute; right:2rem; top:0.3rem;">
        <svg class="icon icon15 lime-fill fill-lighten-5"><use xlink:href="#svg:upload"></svg>
      </a>
    </div>
    <a class="lime-text text-darken-4 dir hide" style="display:block;">
      <svg class="icon icon15 lime-fill fill-darken-4"><use xlink:href="#svg:folder"></svg>
      <span></span>
    </a>
    <div class="red-text error"></div>
    <input type="checkbox" name="dir-check"  class="" style="position:absolute; right:0.8rem; top:1rem;">
  </li>
  % for my $dir (sort  @$dirs) {
  % my $url = $url_path->clone->merge($dir)->trailing_slash(1)->to_route;
    <li class="collection-item dir lime lighten-5" style="position:relative;">
      <div class="input-field hide" style="padding-left:2rem; padding-right:4rem; position:relative;">
        <svg class="icon icon15 lime-fill fill-darken-4" style="position:absolute; left:0; top:0.3rem;"><use xlink:href="#svg:folder"></svg>
        <input type="text" name="dir-name" class="" style="width:100%;" placeholder="<%= i18n 'new dir name'%>" value="<%== $dir %>">
        <a href="javascript:" _href="<%= $url %>" class="save-dir" style="position:absolute; right:2rem; top:0.3rem;">
          <svg class="icon icon15 lime-fill fill-darken-4"><use xlink:href="#svg:upload"></svg>
        </a>
      </div>
       <a href="<%= $url %>" class="lime-text text-darken-4 dir" style="display:block;">
          <svg class="icon icon15 lime-fill fill-darken-4"><use xlink:href="#svg:folder"></svg>
          <span><%== $dir %></span>
        </a>
      <div class="red-text error"></div>
% if ($c->admin) { # delete dir
        <input type="checkbox" name="dir-=check" style="position:absolute; right:0.8rem; top:1rem;">
% }
    </li>
  % }
</ul>

</div>

<div class="files-col col s6">

% if ($c->admin || $c->public_uploads) {
<div class="right btn-panel" style="padding:1.2rem 0;">
  <a href="javascript:" class="hide renames"><svg class="icon icon15 black-fill"><use xlink:href="#svg:rename" /></svg></a>
  <a href="javascript:" class="hide del-files"><svg class="icon icon15 red-fill fill-lighten-1"><use xlink:href="#svg:file-delete" /></svg></a>
  <label for="fileupload" class="btn-flat000">
    <svg class="icon icon15 light-blue-fill fill-darken-1"><use xlink:href="#svg:add-item" /></svg>
    <!--span class="blue-text"><%= i18n 'Add uploads'%></span-->
  </label>
  <input id="fileupload" style="display:none;" type="file" name="file" data-url="<%= $url_path->clone->trailing_slash(0) %>" multiple>
  
</div>

% }

<h2 class="light-blue-text text-darken-2">
  <%= i18n 'Files'%>
  <span class="chip light-blue lighten-5" style=""><%= scalar @$files %></span>
</h2>

<div class="progress progress-file white" style="margin:0; padding:0;">
    <div class="determinate blue" style="width: 0%"></div>
</div>

<table class="striped files light-blue lighten-5" style="border: 1px solid #e0e0e0;">
%#<thead>
%#  <tr>
%#    <th class="name"><%= i18n 'Name'%></th>
%#    <th class="action" style="width:1%;"></th>
%#    <th class="size center"><%= i18n 'Size'%></th>
%#    <!--th class="type">Type</th-->
%#    <th class="mtime center"><%= i18n 'Last Modified'%></th>
%#  </tr>
%#</thead>
<thead class="hide">
  <tr class="light-blue"><!--- new upload file template -->
    <td class="chb">
      <input type="checkbox" name="file-check" class="" style="vertical-align: text-top;">
    </td>
    <td class="name">
      <a class="file-view hide"></a>
      <input type="text" name="file-name" value="" class="" style="width:100%;">
      <div class="red-text error"></div>
    </td>
    <td class="action">
      <a href="" class="file-download hide" style="padding:0.1rem;"><svg class="icon icon15 light-blue-fill fill-darken-1"><use xlink:href="#svg:download" /></a>
      <a href="javascript:" _href="" class="file-rename hide" style="padding:0.1rem;"><svg class="icon icon15"><use xlink:href="#svg:upload" /></a>
      <a href="javascript:" class="file-upload"><svg class="icon icon15 white-fill"><use xlink:href="#svg:upload" /></a>
    </td>
    <td class="size right-align fs8" ></td>
    <!--td class="type"></td-->
    <td class="mtime right-align fs8"></td>
  </tr>
</thead>
<tbody>
  % for my $file (sort { $a->{name} cmp $b->{name} } @$files) {
  % my $href = $url_path->clone->merge($file->{name})->to_route;
  <tr class="">
    <td class="chb">
% if ($c->admin) {
      <input type="checkbox" name="file-check"  class="" style="vertical-align: text-top;">
% }
    </td>

    <td class="name">
      <a href="<%= $href %>" class="file-view"><%== $file->{name} %></a>
      <input type="text" name="file-name" value="<%== $file->{name} %>" class="hide" style="width:100%;">
      <div class="red-text error hide"></div>
    </td>
    <td class="action">
      <a href="<%= $href %>?attachment=1" class="file-download" style="padding:0.1rem;"><svg class="icon icon15 light-blue-fill fill-darken-1"><use xlink:href="#svg:download" /></a>
      <a href="javascript:" _href="<%= $href %>" class="file-rename hide" style="padding:0.1rem;"><svg class="icon icon15"><use xlink:href="#svg:upload" /></a>

    </td>
    <td class="size right-align fs8" ><%= $file->{size} %></td>
    <!--td class="type"><%= $file->{type} %></td-->
    <td class="mtime right-align fs8"><%= $file->{mtime} %></td>
  </tr>
  % }
</tbody>
</table>

</div><!-- col 2 -->
</div><!-- row -->

% if (stash 'index') {
  <div class="right-align grey-text"><%= stash 'index' %></div>
% }
<div class="index"><%== stash('markdown') || stash('pod') || '' %></div>

%= include 'Mojolicious-Plugin-StaticShare/confirm-modal';

@@ Mojolicious-Plugin-StaticShare/header.html.ep

<header class="container clearfix">
<h1><%= i18n 'Index of'%>
% unless (@{$url_path->parts}) {
  <a href="<%= $url_path %>" class="chip grey-text grey lighten-4"><%= i18n 'root' %></a>
% }
% my $con;
% for my $part (@{$url_path->parts}) {
%   $con .="/$part";
  <a href="<%= $con %>" class="chip maroon-text maroon lighten-5"><%= $part %></a>
% }

% if ($c->plugin->root_url->to_route ne $url_path->to_route) {
  <a href="<%= $url_path->clone->trailing_slash(0)->to_dir %>" class="btn-flat000 ">
    <svg class="icon icon15 maroon-fill"><use xlink:href="#svg:up-left-round" />
    <span class="maroon-text"><%= i18n 'Up'%></span>
  </a>
% }

</h1>
<hr />
</header>


@@ Mojolicious-Plugin-StaticShare/markdown.html.ep
% layout 'Mojolicious-Plugin-StaticShare/main' unless layout;
<%== stash('markdown') || stash('content') || 'none content' %>

@@ Mojolicious-Plugin-StaticShare/pod.html.ep
% layout 'Mojolicious-Plugin-StaticShare/main' unless layout;
<%== stash('pod') || stash('content') || 'none content' %>

@@ Mojolicious-Plugin-StaticShare/not_found.html.ep
% layout 'Mojolicious-Plugin-StaticShare/main';
<h2 class="red-text">404 <%= i18n 'Not found'%></h2>

@@ Mojolicious-Plugin-StaticShare/exception.html.ep
% layout 'Mojolicious-Plugin-StaticShare/main';
% title i18n 'Error';

<h2 class="red-text">500 <%= i18n 'Error'%></h2>

% if(my $msg = $exception && $exception->message) {
%   utf8::decode($msg);
    <h3 id="error" style="white-space:pre;" class="red-text"><%= $msg %></h3>
% }



@@ Mojolicious-Plugin-StaticShare/svg.html.ep

<svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
  
  <symbol id="svg:up-left-round" viewBox="0 0 50 50">
    <path d="M 43.652344 50.003906 C 40.652344 50.003906 14.632813 49.210938 14.011719 22 L 3.59375 22 L 20 0.34375 L 36.410156 22 L 26.011719 22 C 26.472656 46.441406 43.894531 47.988281 44.074219 48.003906 L 44.035156 50 C 44.035156 50 43.902344 50.003906 43.652344 50.003906 Z "></path>
  </symbol>
  
  <symbol id="svg:down-right-round" viewBox="0 0 50 50">
    <path d="M 28 46.410156 L 28 35.988281 C 19.636719 35.796875 12.960938 33.171875 8.136719 28.179688 C -0.359375 19.386719 -0.0195313 6.507813 0 5.964844 L 1.996094 5.925781 C 2.054688 6.652344 3.628906 23.542969 28 23.992188 L 28 13.589844 L 49.65625 30 Z "></path>
  </symbol>
  
  <symbol id="svg:add-item" viewBox="0 0 26 26">
    <path style=" " d="M 4 0 C 1.796875 0 0 1.796875 0 4 L 0 21 C 0 23.203125 1.796875 25 4 25 L 14 25 C 13.5 24.402344 13.085938 23.730469 12.78125 23 L 4 23 C 2.894531 23 2 22.105469 2 21 L 2 4 C 2 2.894531 2.894531 2 4 2 L 10.28125 2 C 11.003906 2.183594 11 3.050781 11 3.9375 L 11 7 C 11 7.550781 11.449219 8 12 8 L 15 8 C 15.996094 8 17 8.003906 17 9 L 17 12.78125 C 17.628906 12.519531 18.300781 12.339844 19 12.25 L 19 8 C 19 6.9375 18.027344 5.929688 16.28125 4.21875 C 16.039063 3.980469 15.777344 3.714844 15.53125 3.46875 C 15.285156 3.222656 15.019531 2.992188 14.78125 2.75 C 13.070313 1.003906 12.0625 0 11 0 Z M 20 14.1875 C 16.789063 14.1875 14.1875 16.789063 14.1875 20 C 14.1875 23.210938 16.789063 25.8125 20 25.8125 C 23.210938 25.8125 25.8125 23.210938 25.8125 20 C 25.8125 16.789063 23.210938 14.1875 20 14.1875 Z M 19 17 L 21 17 L 21 19 L 23 19 L 23 21 L 21 21 L 21 23 L 19 23 L 19 21 L 17 21 L 17 19 L 19 19 Z "></path>
  </symbol>
  
  <symbol id="svg:add-dir" viewBox="0 0 50 50">
    <path d="M 5 4 C 3.346 4 2 5.346 2 7 L 2 13 L 3 13 L 47 13 L 48 13 L 48 11 C 48 9.346 46.654 8 45 8 L 18.044922 8.0058594 C 17.765922 7.9048594 17.188906 6.9861875 16.878906 6.4921875 C 16.111906 5.2681875 15.317 4 14 4 L 5 4 z M 3 15 C 2.449 15 2 15.448 2 16 L 2 43 C 2 44.654 3.346 46 5 46 L 32.027344 46 C 33.856756 48.421534 36.749111 50 40 50 C 45.5 50 50 45.5 50 40 C 50 37.767371 49.248916 35.706061 48 34.037109 L 48 16 C 48 15.448 47.551 15 47 15 L 3 15 z M 40 32 C 44.4 32 48 35.6 48 40 C 48 44.4 44.4 48 40 48 C 35.6 48 32 44.4 32 40 C 32 35.6 35.6 32 40 32 z M 40 34.099609 C 39.4 34.099609 39 34.499609 39 35.099609 L 39 39 L 35.099609 39 C 34.499609 39 34.099609 39.4 34.099609 40 C 34.099609 40.6 34.499609 41 35.099609 41 L 39 41 L 39 44.900391 C 39 45.500391 39.4 45.900391 40 45.900391 C 40.6 45.900391 41 45.500391 41 44.900391 L 41 41 L 44.900391 41 C 45.500391 41 45.900391 40.6 45.900391 40 C 45.900391 39.4 45.500391 39 44.900391 39 L 41 39 L 41 35.099609 C 41 34.499609 40.6 34.099609 40 34.099609 z"></path>
  </symbol>
  
  <symbol id="svg:file-delete" viewBox="0 0 26 26">
    <path style=" " d="M 4 0 C 1.800781 0 0 1.800781 0 4 L 0 21 C 0 23.199219 1.800781 25 4 25 L 14.3125 25 C 14.113281 24.699219 14.09375 24.304688 14.09375 23.90625 C 14.09375 23.605469 14.210938 23.300781 14.3125 23 L 4 23 C 2.898438 23 2 22.101563 2 21 L 2 4 C 2 2.898438 2.898438 2 4 2 L 10.3125 2 C 11.011719 2.199219 11 3.101563 11 4 L 11 7 C 11 7.601563 11.398438 8 12 8 L 15 8 C 16 8 17 8 17 9 L 17 14.3125 C 17.601563 14.011719 18.398438 14.011719 19 14.3125 L 19 8 C 19 6.898438 18.011719 5.886719 16.3125 4.1875 C 16.011719 3.988281 15.800781 3.699219 15.5 3.5 C 15.300781 3.199219 15.011719 2.988281 14.8125 2.6875 C 13.113281 0.988281 12.101563 0 11 0 Z M 18.0625 16.0625 C 17.886719 16.0625 17.695313 16.085938 17.59375 16.1875 L 16.1875 17.59375 C 15.988281 17.792969 15.988281 18.300781 16.1875 18.5 L 18.6875 21 L 16.1875 23.5 C 15.988281 23.699219 15.988281 24.207031 16.1875 24.40625 L 17.59375 25.8125 C 17.792969 26.011719 18.300781 26.011719 18.5 25.8125 L 21 23.3125 L 23.5 25.8125 C 23.699219 26.011719 24.207031 26.011719 24.40625 25.8125 L 25.8125 24.40625 C 26.011719 24.207031 26.011719 23.699219 25.8125 23.5 L 23.3125 21 L 25.8125 18.5 C 26.011719 18.300781 26.011719 17.792969 25.8125 17.59375 L 24.40625 16.1875 C 24.207031 15.988281 23.699219 15.988281 23.5 16.1875 L 21 18.6875 L 18.5 16.1875 C 18.398438 16.085938 18.238281 16.0625 18.0625 16.0625 Z "></path>
  </symbol>
  
  <symbol id="svg:download" viewBox="0 0 26 26">
    <path style=" " d="M 11 0 C 9.34375 0 8 1.34375 8 3 L 8 11 L 4.75 11 C 3.339844 11 3.042969 11.226563 4.25 12.4375 L 10.84375 19.03125 C 13.042969 21.230469 13.015625 21.238281 15.21875 19.03125 L 21.78125 12.4375 C 22.988281 11.226563 22.585938 11 21.3125 11 L 18 11 L 18 3 C 18 1.34375 16.65625 0 15 0 Z M 0 19 L 0 23 C 0 24.65625 1.34375 26 3 26 L 23 26 C 24.65625 26 26 24.65625 26 23 L 26 19 L 24 19 L 24 23 C 24 23.550781 23.550781 24 23 24 L 3 24 C 2.449219 24 2 23.550781 2 23 L 2 19 Z "></path>
  </symbol>
  
  <symbol id="svg:upload" viewBox="0 0 26 26">
    <path style=" " d="M 12.96875 0.3125 C 12.425781 0.3125 11.882813 0.867188 10.78125 1.96875 L 4.21875 8.5625 C 3.011719 9.773438 3.414063 10 4.6875 10 L 8 10 L 8 18 C 8 19.65625 9.34375 21 11 21 L 15 21 C 16.65625 21 18 19.65625 18 18 L 18 10 L 21.25 10 C 22.660156 10 22.957031 9.773438 21.75 8.5625 L 15.15625 1.96875 C 14.054688 0.867188 13.511719 0.3125 12.96875 0.3125 Z M 0 19 L 0 23 C 0 24.65625 1.34375 26 3 26 L 23 26 C 24.65625 26 26 24.65625 26 23 L 26 19 L 24 19 L 24 23 C 24 23.550781 23.550781 24 23 24 L 3 24 C 2.449219 24 2 23.550781 2 23 L 2 19 Z "></path>
  </symbol>
  
  <symbol id="svg:folder" viewBox="0 0 30 30">
    <path d="M 4 3 C 2.895 3 2 3.895 2 5 L 2 8 L 13 8 L 28 8 L 28 7 C 28 5.895 27.105 5 26 5 L 11.199219 5 L 10.582031 3.9707031 C 10.221031 3.3687031 9.5701875 3 8.8671875 3 L 4 3 z M 3 10 C 2.448 10 2 10.448 2 11 L 2 23 C 2 24.105 2.895 25 4 25 L 26 25 C 27.105 25 28 24.105 28 23 L 28 11 C 28 10.448 27.552 10 27 10 L 3 10 z"></path>
  </symbol>
  
  <symbol id="svg:dir-delete" viewBox="0 0 50 50">
    <path d="M 5 3 C 3.346 3 2 4.346 2 6 L 2 12 L 3 12 L 47 12 L 48 12 L 48 10 C 48 8.346 46.654 7 45 7 L 18.044922 7.0058594 C 17.765922 6.9048594 17.188906 5.9861875 16.878906 5.4921875 C 16.111906 4.2681875 15.317 3 14 3 L 5 3 z M 3 14 C 2.449 14 2 14.448 2 15 L 2 42 C 2 43.654 3.346 45 5 45 L 31.359375 45 C 33.095702 47.980427 36.320244 50 40 50 C 45.5 50 50 45.5 50 40 C 50 37.767371 49.248916 35.706061 48 34.037109 L 48 15 C 48 14.448 47.551 14 47 14 L 3 14 z M 40 32 C 44.4 32 48 35.6 48 40 C 48 44.4 44.4 48 40 48 C 35.6 48 32 44.4 32 40 C 32 35.6 35.6 32 40 32 z M 36.5 35.5 C 36.25 35.5 36.000781 35.600781 35.800781 35.800781 C 35.400781 36.200781 35.400781 36.799219 35.800781 37.199219 L 38.599609 40 L 35.800781 42.800781 C 35.400781 43.200781 35.400781 43.799219 35.800781 44.199219 C 36.000781 44.399219 36.3 44.5 36.5 44.5 C 36.7 44.5 36.999219 44.399219 37.199219 44.199219 L 40 41.400391 L 42.800781 44.199219 C 43.000781 44.399219 43.3 44.5 43.5 44.5 C 43.7 44.5 43.999219 44.399219 44.199219 44.199219 C 44.599219 43.799219 44.599219 43.200781 44.199219 42.800781 L 41.400391 40 L 44.199219 37.199219 C 44.599219 36.799219 44.599219 36.200781 44.199219 35.800781 C 43.799219 35.400781 43.200781 35.400781 42.800781 35.800781 L 40 38.599609 L 37.199219 35.800781 C 36.999219 35.600781 36.75 35.5 36.5 35.5 z"></path>
  </symbol>
  
  <symbol id="svg:rename" viewBox="0 0 26 26">
    <g><g><path d="M12.06264,19l-2.36342,0l-1.30078,4.10156c-0.09766,0.39844 -0.29687,0.59766 -0.39844,0.69922c-0.19922,0.09766 -0.39844,0.19922 -0.69922,0.19922l-3.69922,0c-0.20312,0 -0.40234,0 -0.5,-0.10156c-0.10156,-0.09766 -0.10156,-0.29687 0,-0.69922l6.39844,-20.19922c0.10156,-0.30078 0.19922,-0.5 0.39844,-0.69922c0.20313,-0.19922 0.5,-0.30078 0.90234,-0.30078l4.19922,0c0.5,0 0.80078,0.10156 0.89844,0.30078c0.10156,0.19922 0.30078,0.39844 0.40234,0.69922l2.95108,9.03495c-1.71786,0.16122 -3.28237,0.87163 -4.51487,1.95258l-1.73699,-6.68674l-0.19922,0l-2.10156,7.69922l3.06733,0c-0.90603,1.12601 -1.51473,2.50008 -1.70391,4z"></path></g><g><path d="M23.48616,15.3l-1.2,1.1l-2.8,-2.8l1.2,-1.1c0.4,-0.4 1.1,-0.4 1.5,0l1.4,1.4c0.3,0.5 0.3,1.1 -0.1,1.4z M18.38616,14.6l3.1,3.1l-5.5,5.4c-0.1,0.1 -0.1,0.1 -0.2,0.1l-3.5,1l-0.1,0c-0.1,0 -0.2,0 -0.3,-0.1c-0.1,-0.1 -0.2,-0.3 -0.1,-0.4l1.1,-3.4c0,-0.1 0.1,-0.2 0.2,-0.3z M15.38616,22.5l-0.3,-1.5l-1.5,-0.3l-0.6,1.9l0.4,0.4z"></path></g></g>
  </symbol>
  
</svg>

@@ Mojolicious-Plugin-StaticShare/confirm-modal.html.ep
<!-- Modal Structure -->
<div id="confirm-modal" class="modal bottom-sheet modal-fixed-footer">
  <div class="modal-header hide">
    <h2 class="red-text del-files"><span><%= i18n 'Confirm to delete these files' %></span><span class="chip red lighten-4"></span></h2>
    <h2 class="red-text del-dirs"><span><%= i18n 'Confirm to delete these dirs' %></span><span class="chip red lighten-4"></span></h2>
    <h2 class="red-text foo">Foo header</h2>
  </div>
  <div class="modal-content"></div>
  <div class="modal-footer green lighten-5">
    <a href="javascript:" class="modal-action modal-close green-text waves-effect waves-green btn-flat"><%= i18n 'I AM SURE' %></a>
  </div>
</div>
