package Mojolicious::Plugin::Pager;
use Mojo::Base 'Mojolicious::Plugin';

use POSIX ();

use constant PAGE_PARAM  => 'page_param_name';
use constant WINDOW_SIZE => 'pager.window_size';

our $VERSION = '0.02';

sub pager_link {
  my ($self, $c, $page, @args) = @_;
  my $url = $c->url_with;
  my @text = ref @args eq 'CODE' ? () : ($page->{n});
  my (@extra, @classes);

  push @classes, $self->{classes}{current} if $page->{current};
  push @classes, $self->{classes}{first}   if $page->{first};
  push @classes, $self->{classes}{last}    if $page->{last};
  push @classes, $self->{classes}{next}    if $page->{next};
  push @classes, $self->{classes}{prev}    if $page->{prev};
  push @classes, $self->{classes}{normal} unless @classes;
  push @extra, rel => 'next' if $page->{next};
  push @extra, rel => 'prev' if $page->{prev};

  $url->query->param($c->stash(PAGE_PARAM) => $page->{n} || 1);
  return $c->link_to(@text, $url, class => join(' ', @classes), @extra, @args);
}

sub pages_for {
  my $c            = shift;
  my $args         = ref $_[0] ? shift : {total_pages => shift || 1};
  my $current_page = $args->{current} || $c->param($c->stash(PAGE_PARAM)) || 1;
  my $pager_size   = $args->{size} || 8;
  my $window_size  = ($pager_size / 2) - 1;
  my $total_pages  = POSIX::ceil($args->{total_pages});
  my ($start_page, @pages);

  if ($current_page < $window_size) {
    $start_page = 1;
  }
  elsif ($current_page + $pager_size - $window_size > $total_pages) {
    $start_page = 1 + $total_pages - $pager_size;
  }
  else {
    $start_page = 1 + $current_page - $window_size;
  }

  for my $n ($start_page .. $total_pages) {
    last if @pages >= $pager_size;
    push @pages, {n => $n};
    $pages[-1]{first}   = 1 if $n == 1;
    $pages[-1]{last}    = 1 if $n == $total_pages;
    $pages[-1]{current} = 1 if $n == $current_page;
  }

  return @pages unless @pages;
  return @pages unless $total_pages > $pager_size;

  unshift @pages, {prev => 1, n => $current_page - 1} if $current_page > 1;
  push @pages,    {next => 1, n => $current_page + 1} if $current_page < $total_pages;

  return @pages;
}

sub register {
  my ($self, $app, $config) = @_;

  $app->defaults(PAGE_PARAM,  $config->{param_name}  || 'page');
  $app->defaults(WINDOW_SIZE, $config->{window_size} || 3);

  $self->{classes}{current} = $config->{classes}{current} || 'active';
  $self->{classes}{first}   = $config->{classes}{first}   || 'first';
  $self->{classes}{last}    = $config->{classes}{last}    || 'last';
  $self->{classes}{next}    = $config->{classes}{next}    || 'next';
  $self->{classes}{prev}    = $config->{classes}{prev}    || 'prev';
  $self->{classes}{normal}  = $config->{classes}{normal}  || 'page';

  $app->helper(pager_link => sub { $self->pager_link(@_) });
  $app->helper(pages_for => \&pages_for);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Pager - Pagination plugin for Mojolicious

=head1 SYNOPSIS

=head2 Example lite app

  use Mojolicious::Lite;

  plugin "pager";

  get "/" => sub {
    my $c = shift;
    $c->stash(total_entries => 1431, entries_per_page => 20);
  };

=head2 Example template

  <ul class="pager">
    % for my $page (pages_for $total_entries / $entries_per_page) {
      <li><%= pager_link $page %></li>
    % }
  </ul>

=head2 Custom template

  <ul class="pager">
    % for my $page (pages_for $total_entries / $entries_per_page) {
      % my $url = url_with; $url->query->param(x => $page->{n});
      <li><%= link_to "hey!", $url %></li>
    % }
  </ul>

=head1 DESCRIPTION

L<Mojolicious::Plugin::Pager> is a L<Mojolicious> plugin for creating paged
navigation, without getting in the way. There are other plugins which ship with
complete markup, but this is often not the markup that I<you> want.

Note that this plugin is currently EXPERIMENTAL.

=head1 HELPERS

=head2 pager_link

  $bytestream = $c->pager_link(\%page, @args);
  $bytestream = $c->pager_link(\%page, @args, sub { int(rand 100) });

Takes a C<%page> hash and creates an anchor using
L<Mojolicious::Controller/link_to>. C<@args> is passed on, without
modification, to C<link_to()>. The anchor generated has some classes added.

See L</pages_for> for detail about C<%page>.

Examples output:

  <a href="?page=2" class="prev" rel="prev">12</a>
  <a href="?page=1" class="first">1</a>
  <a href="?page=2" class="page">2</a>
  <a href="?page=3" class="active">3</a>
  <a href="?page=4" class="page">4</a>
  <a href="?page=5" class="page">5</a>
  <a href="?page=6" class="last">6</a>
  <a href="?page=3" class="next" rel="next">3</a>

=head2 pages_for

  @pages = $self->pages_for($total_pages);

Returns a list of C<%page> hash-refs, that can be passed on to L</pager_link>.

Example C<%page>:

  {
    n       => 2,    # page number
    current => 1,    # if page number matches "page" query parameter
    first   => 1,    # if this is the first page
    last    => 1,    # if this is the last page
    next    => 1,    # if this is last, that brings you to the next page
    prev    => 1,    # if this is first, that brings you to the previous page
  }

=head1 METHODS

=head2 register

  $app->plugin("pager" => \%config);

Used to register this plugin and the L</HELPERS> above. C<%config> can be:

=over 4

=item * classes

Used to set default class names, used by L</pager_link>.

Default:

  {
    current => "active",
    first   => "first",
    last    => "last",
    next    => "next",
    prev    => "prev",
    normal  => "page",
  }

=item * param_name

The query parameter that will be looked up to figure out which page you are on.
Can also be set in L<Mojolicious::Controller/stash> on each request under the
name "page_param_name".

Default: "page"

=item * window_size

Used to decide how many pages to show after/before the current page.

Default: 3

=back

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
