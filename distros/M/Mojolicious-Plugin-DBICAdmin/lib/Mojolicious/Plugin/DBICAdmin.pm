# ABSTRACT: Web interface for DBIx::Class Schema/ResultSource/ResultSet
use v5.14;
use utf8;
use strict;
use warnings;
package Mojolicious::Plugin::DBICAdmin;
{
  $Mojolicious::Plugin::DBICAdmin::VERSION = '0.0006';
}

use Mojo::Base 'Mojolicious::Plugin';
use Web::Util::DBIC::Paging;

my $config = { page_size => 25, };


sub register {
    my ( $self, $app, $conf ) = @_;

    # our base route
    my $r = $app->routes->route('/admin/dbic');
    if ( my $cond = $conf->{condition} ) {
        $r->over($cond);
    }
    else {
        # only localhost can view by default
        $app->routes->add_condition(
            localhost => sub {
                my ( $route, $c, $captures, $pattern ) = @_;
                $c->tx->remote_address eq '127.0.0.1';
            }
        );
        $r->over('localhost');
    }
    $config->{page_size} = $conf->{page_size} if $conf->{page_size} // 0 > 0;
    $config = +{ %$conf, %$config };

    # setup route and template
    push @{ $app->renderer->classes }, __PACKAGE__;
    $r->any( '/'     => \&_dbic_list )->name('dbic-admin-index');
    $r->any( '/list' => \&_dbic_list )->name('dbic-admin-list');
    $r->any( '/info' => \&_dbic_select_source )
      ->name('dbic-admin-info-select-source');
    $r->any( '/info/:source' => \&_dbic_info )->name('dbic-admin-info');
    $r->any( '/search'       => \&_dbic_select_source )
      ->name('dbic-admin-search-select-source');
    $r->any( '/search/:source' => \&_dbic_search )->name('dbic-admin-search');
    $r->any( '/delete/:source' => \&_dbic_delete )->name('dbic-admin-delete');
    return 1;
}

sub _dbic_list {
    my $c = shift;
    my @sources = sort grep !/::/, $c->app->schema->sources;
    $c->render( sources => \@sources, config => $config, );
}

sub _dbic_delete {
    my $c      = shift;
    my $source = $c->stash('source');
    $c->render( text => "search" );
}

sub _dbic_info {
    my $c       = shift;
    my $source  = $c->stash('source');
    my $src_obj = $c->app->schema->source($source);
    $c->render( src_obj => $src_obj, config => $config );
}

sub _dbic_search {
    my $c      = shift;
    my $source = $c->stash('source');
    my $rs     = $c->app->schema->resultset($source)
      || return $c->render_exception("ResultSource unexist !");
    my $param = $c->req->params->to_hash;
    $rs = search( 'raw', $param, $rs, $config );
    my $count = $rs->count;
    my $start = $param->{start} // 0;
    my $next  = $count < $config->{page_size} ? undef : $start + $count;
    my $prev =
        $start <= 0                   ? -1
      : $start > $config->{page_size} ? $start - $config->{page_size}
      :                                 0;
    $c->render(
        rs     => $rs,
        next   => $next,
        prev   => $prev,
        config => $config,
    );
}

sub _dbic_select_source {
    my $c = shift;
    $c->render( config => $config, template => 'dbic-admin-select-source' );
}

sub _dbic_index {
    my $c = shift;
    $c->render( config => $config );
}

1;

=pod

=head1 NAME

Mojolicious::Plugin::DBICAdmin - Web interface for DBIx::Class Schema/ResultSource/ResultSet

=head1 VERSION

version 0.0006

=head1 SYNOPSIS

This Plugin just for Web master view/search their data in DB

=head2 Configure

In Mojolicious App's C<startup> method:

  $self->plugin('DBICAdmin' =>   {
              condition => 'login', # optional
              stylesheet => '/dbic-admin-pure.css', #optional
              # ... other configurations
  });

=head2 Use

  #start app and view the URI :
  http://yourapp.domain/admin/dbic/

=head1 DESCRIPTION

You will see it, when you open URI : L</admin/dbic/>

=head2 routes

the Plugin set following routes :

=over

=item C</admin/dbic/>

Index of the module's function

=item C</admin/dbic/search> and C</admin/dbic/search/:source>

Search DBIx::Class drivered database

=item C</admin/dbic/info> and C</admin/dbic/info/:source>

List Result Source Class's columns info

=item C</admin/dbic/list>

List Result source loaded by DBIx::Class

=back

=head2 display style

Plugin use L<purecss|http://purecss.io/>

you can use customed theme of purecss by pass config directive : C<stylesheet="/dbic-admin-pure.css">

customlized theme of purecss must use name : C<.pure-skin-dbic>

where to coustom the theme ?

L<Here|http://yui.github.io/skinbuilder/?mode=pure>

=head2 config

=over

=item page_size

rows displayed per page

=item stylesheet

theme of the web page, should be the url of css file create by L<YUI Skin Builder|http://yui.github.io/skinbuilder/?mode=pure>

=item condition

array or scalar if single of Mojolicious route condition used for access control

=back

=encoding utf8

=head1 NAME

DBICAdmin -  Web interface for DBIx::Class Schema/ResultSource/ResultSet

=head1 AUTHOR

ChinaXing(陈云星) <chen.yack@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by ChinaXing(陈云星).

This is free software, licensed under:

  The (three-clause) BSD License

=cut

__DATA__

@@ dbic-admin-index.html.ep
% layout 'dbic-admin';
<div class="pure-u-1">
    <h1>Welcome !</h1>
    <p>
    The DBIx::Class based Database view/search/delete console !
    </p>
</div>

@@ dbic-admin-select-source.html.ep
% layout 'dbic-admin';
% my @sources = sort grep !/::/, app->schema->sources;
<div class="pure-u-1">
    <h2>Select Result source</h2>
    <hr>
    <div class="pure-menu pure-menu-open pure-menu-horizontal">
    <ul>
      <% for my $s (@sources) { %>
    <li>
       %= link_to  $s => url_for() . '/' . $s
    </li>
<% } %>
    <ul>
    </div>
</div>

@@ dbic-admin-list.html.ep
% layout 'dbic-admin';
<div class="pure-u-1">
<h2>All result source</h2>
<hr>
<ol>
<% for my $s (@$sources) { %>
    <li>
       %= link_to  $s => url_for( 'dbic-admin-search', source => $s)->to_abs
    </li>
<% } %>
</ol>
</div>

@@ dbic-admin-search.html.ep
% layout 'dbic-admin';
% my @columns = $rs->result_source->columns;
% my $source_name = $rs->result_source->source_name;
<div class='pure-u-1'>
  <h2>Detail of
    %= t b => $source_name
  </h2>
</div>
<div class="pure-g-r">
<div class="pure-u-2-3">
    %== form_for url_for() => (id => 'search-form' ) => ( onsubmit => 'modify_form_data()' ) => ( class => "pure-form" ) => begin
      %= select_field col => [@columns]
      %= search_field 'val'
      %= submit_button 'Search', name => 'search', class => 'pure-button'
      %= javascript begin
         function modify_form_data() {
             var form = document.forms['search-form'];
             var input = document.createElement('input');
             input.name = form.elements['col'].value;
             input.value = form.elements['val'].value;
             form.removeChild(form.elements['col']);
             form.removeChild(form.elements['val']);
             form.removeChild(form.elements['search']);
             form.appendChild(input);
             form.submit();
             return false;
         }
      % end
    % end
</div>
<div class="pure-u-1-4"  style="text-align:right">
% if ($next) {
        %= link_to Next => url_for->query(start=> $next), class => 'pure-button'
% }else {
        %= link_to Next => '#', class => 'pure-button-disabled pure-button'
% }
% if ($prev >=0 ) {
        %= link_to Prev => url_for->query(start=> $prev), class => 'pure-button'
% }else{
        %= link_to Prev => '#', class => 'pure-button-disabled pure-button'
% }
</div>
</div>
<div class="pure-u-1">
<table class='pure-table pure-table-horizontal' style="width:100%">
  <thead>
   <tr>
       % for (@columns) {
          %= t th => $_
       % }
   </tr>
  </thead>
   % my $i = 1;
   % while( my $r = $rs->next ) {
   <tr
       <% if (($i *= -1) > 0) { %>
           class='pure-table-odd'
       <% } %>
   >
       % for (@columns) {
         %= t td => $r->get_column($_)
       % }
   </tr>
   % }
</table>
</content>
</div>

@@ dbic-admin-info.html.ep
% layout 'dbic-admin';
<div class="pure-u-1">
<h2>Meta Data of
%= t b => $source
</h2>
<hr>
</div>
<div class="pure-u-1">
    <table class="pure-table pure-table-horizontal" style="width:100%">
    <thead>
    <tr>
        <th>Col</th><th>Accessor</th><th>type</th><th>size</th><th>nullable</th>
    </tr>
    </thead>
    % for ($src_obj->columns){
        % my $c_info = $src_obj->column_info($_);
        <tr>
            %= t td => $_
            %= t td => $c_info->{accessor} // $_
            %= t td => $c_info->{data_type}
            %= t td => $c_info->{size}
            %= t td => $c_info->{is_nullable}
        </tr>
    % }
   </table>
   <div class="pure-u-1">
   <pre>
   %== dumper $src_obj->columns_info
   </pre>
   </div>
</div>

@@ layouts/dbic-admin.html.ep
<!DOCTYPE html>
<html>
<head>
    %= stylesheet "http://yui.yahooapis.com/pure/0.1.0/pure-min.css"
    % if(my $stylesheet = $config->{stylesheet}) {
        %= stylesheet $stylesheet;
    % }
    %= stylesheet begin
       #layout {
            padding-left: 152px;
            left:0;
       }
       #menu {
            margin-left: -150px;
            width: 150px;
            position: fixed;
            top: 0;
            left: 150px;
            bottom: 0;
            z-index: 1000;
            background: #191818;
            overflow-y: auto;
       }
       #main {
            width: 100%;
            font-size:14px;
       }
       #menu .pure-menu-heading {
            font-size: 110%;
            font-widget: bolder;
            color: white;
       }
       #menu .pure-menu ul {
            border-top: 1px solid #333;
       }
       #menu .pure-menu-open {
            background: transparent;
            border:0;
       }
       #menu .pure-menu-selected {
       background: #1f8dd6;
       }
       #menu .pure-menu-selected a {
           color:white;
       }
       #menu .pure-menu li a:hover {
           background: #333;
       }
       #menu li.pure-menu-selected a:hover {
           background: none;
       }
       #menu a {
           color: #999;
           border: none;
           white-space: normal;
           padding: 0.6em 0 0.6em 0.6em;
       }
    % end
    <title>DBIC - Paging</title>
</head>
<body>
    <div class="pure-skin-dbic pure-g-r" id="layout">
    <div class='pure-u' id='menu'>
       <div class='pure-menu pure-menu-open'>
       %= link_to "DBIC::Admin" => url_for('dbic-admin-index') => ( class => "pure-menu-heading" )
       <ul>
            <li
                <% if (current_route eq 'dbic-admin-list') { %>
                class="pure-menu-selected"
                <% } %>
              >
               %= link_to List => url_for('dbic-admin-list')
            </li>
            <li
                 <% if (current_route eq 'dbic-admin-search-select-source') { %>
                 class="pure-menu-selected"
                 <% } %>
              >
               %= link_to Search => url_for('dbic-admin-search-select-source')
            </li>
            <li
                <% if (current_route eq 'dbic-admin-info-select-source') { %>
                class="pure-menu-selected"
                 <% } %>
              >
               %= link_to Meta => url_for('dbic-admin-info-select-source')
            </li>
         </ul>
         </div>
    </div>
    <div class="pure-u" id="main">
        <%= content %>
    </div>
  </div>
</body>
</html>
