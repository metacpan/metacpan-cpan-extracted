package Mojolicious::Plugin::RenderCGI;

use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Plugin::RenderCGI::Template;
use Mojo::Util qw(encode md5_sum);

our $VERSION = '0.102';
my $pkg = __PACKAGE__;

has qw(app);
has handler_name => 'cgi.pl';
has default => 0;
has cgi_import => sub { [qw(:html :form)] };
has exception => sub { {'handler'=>'ep', 'layout' => undef,} };
has cache => sub { {} };

sub register {
  my ($plugin, $app, $conf) = @_;
  
  $plugin->app($app);
  
  map $plugin->$_($conf->{$_}), grep defined($conf->{$_}), qw(name default import exception);
  #~ $app->renderer->default_handler($plugin->handler_name) не работает
  $app->log->debug("Set default render handler ".$plugin->handler_name)
    and $app->defaults('handler'=>$plugin->handler_name)
    if $plugin->default;
    
  $app->renderer->add_handler(
    $plugin->handler_name => sub {$plugin->handler(@_)}
  );
}

sub handler {
  my ($plugin, $renderer, $c, $output, $options) = @_;
  my $app = $c->app;
  #~ $app->log->debug($app->dumper($options));
  
  # относительный путь шаблона
  my $content = $options->{inline};# встроенный шаблон
  my $name = defined $content ? md5_sum encode('UTF-8', $content) : undef;
  return unless defined($name //= $renderer->template_path($options) || $renderer->template_name($options));
  
  #~ my $url = Mojo::URL->new($name);
  #~ ($name, my $param) = (url_unescape($url->path), $url->query->to_hash);
    #~ utf8::decode($name);
  
  my ($template, $from) = ($plugin->cache->{$name}, 'cache');# подходящий шаблон из кэша 
  
  my $stash = $c->stash($pkg);
  $c->stash($pkg => {stack => []})
    unless $stash;
  $stash ||= $c->stash($pkg);
  my $last_template = $stash->{stack}[-1];
  #~ if ($last_template && $last_template eq $name) {
    #~ $$output = $plugin->error("Stop looping template [$name]!", $c);
    #~ return;
  #~ }
  push @{$stash->{stack}}, $name;
  
  $$output = '';
  
  unless ($template) {#не кэш
    if (defined $content) {# инлайн
      $from = 'inline';
    } else {
      # подходящий шаблон в секции DATA
      ($content, $from) = ($renderer->get_data_template($options), 'DATA section');#,, $name
      
      unless (defined $content) {# file
      #  абсолютный путь шаблона
        if (my $path = $renderer->template_path($options)) {
          my $file = Mojo::Asset::File->new(path => $path);
          ($content, $from) = ($file->slurp, 'file');
          
        } else {
          $$output = $plugin->error(sprintf(qq{Template "%s" does not found}, $name), $c);
          return;
        }
      }
    }
    
    $app->log->debug(sprintf(qq{Empty or nothing template "%s"}, $name))
      and return
      unless $content =~ /\w/;
    
    utf8::decode($content);
    
    $template = Mojolicious::Plugin::RenderCGI::Template->new(_import=>$plugin->cgi_import, _plugin=>$plugin, );

    my $err = $template->_compile($content);
    
    $$output = $plugin->error(sprintf(qq{Compile time error for template "%s" from the %s: %s}, $name, $from, $err), $c)
      and return
      unless ref $err; # ref success
    
  }
  
  $app->log->debug(sprintf(qq{Rendering template "%s" from the %s}, $name, $from,));
  $plugin->cache->{$name} ||= $template;
  
  my @out = eval { $template->_run($c)};
  $$output = $plugin->error(sprintf(qq{Runtime error for template "%s" from the %s:\n%s}, $name, $from, $@), $c)
    and return
    if $@;
  
  $$output = join "\n", grep defined, @out;
  
}

sub error {# харе
    my ($plugin, $error, $c) = @_;
    $c->stash(%{$plugin->exception})
      and die $error
      if ref($plugin->exception) eq 'HASH';
    
    $c->app->log->error($error);# лог после die!
    return $error
      if $plugin->exception eq 'template';
    
    return "<!-- $error -->"
      if $plugin->exception =~ m'comment';
  };

1;


=pod

=encoding utf8

Доброго всем

=head1 Mojolicious::Plugin::RenderCGI

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::RenderCGI - Rendering Mojoliciuos template by CGI.pm subs as tags.

=head1 SYNOPSIS

  $app->plugin('RenderCGI');

=head1 Template

Template is a Perl code that generate content as list of statements. Similar to C<do BLOCK>. Template file name like "templates/foo/bar.html.cgi.pl"

  # There are predefined variables:
  # $self  is a     Mojolicious::Plugin::RenderCGI::Template object
  # $c     is a     current controller object
  # $cgi   is a     CGI object
  
  $c->layout('default', handler=>'ep',);# set handler 'ep' for all templates/includes !!! even default handler cgi
  my $foo = $c->stash('foo')
    or die "Where is your FOO?";
  
  #=======================================
  #======= content comma list! ===========
  #=======================================
  
  h1({}, "Welcome"),# but this template handlered CGI
  div({-class=>"container"},
    span('Okay here'),
    p(['blah', 'blaz']),
  ),
  
  $c->include('foo', handler=>'cgi.pl'),# change handler against layout
  $c->include('bar'); # handler still "ep" unless template "foo" (and its includes) didn`t changes it by $c->stash('handler'=>...)
  
  <<END_HTML,
  <!-- comment -->
  END_HTML
  
  $self->app->log->info("Template has done")
    && undef,

There are NO Mojolicious helpers without OO-style prefixes: C<< $c-> >>.

B<REMEMBER!> Escapes untrusted data. No auto escapes!

  div({}, esc(...UNTRUSTED DATA...)),

C<esc> is a shortcut for &CGI::escapeHTML.

=head1 NOTE about autoloading subs and methods

In template you can generate any tag:

  # <foo-tag class="class1">...</foo-tag>
  foo_tag({-class=>"class1",}, '...'),
  # same
  $self->foo_tag({-class=>"class1",}, '...'),

=head1 OPTIONS

=head2 handler_name ( string )

  # Mojolicious::Lite
  plugin RenderCGI => {handler_name => 'pl'};

Handler name, defaults to B<cgi.pl>.

=head2 default (bool)

When C<true> then default handler. Defaults - 0 (no this default handler for app).

  default => 1,

Is similar to C<< $app->defaults(handler=> <name above>); >>

=head2 cgi_import ( string (space delims) | arrayref )

What subs do you want from CGI.pm import

  $app->plugin('RenderCGI', cgi_import=>':html ...');
  # or 
  $app->plugin('RenderCGI', cgi_import=>[qw(:html ...)]);

See at perldoc CGI.pm section "USING THE FUNCTION-ORIENTED INTERFACE".
Default is ':html :form' (string) same as [qw(:html :form)] (arrayref).

  cgi_import=>[], # none import subs CGI

=head2 exception ( string | hashref )

To show fatal errors (not found, compile and runtime errors) as content of there template you must set string B<template>.

Set string B<comment> same above but include html comment tag

  <!-- $error -->

To show fatals as standard Mojolicious 'exception.<mode>.html.ep' page  - set hashref like {'handler'=>'ep', 'layout' => undef,}.

Overwise fatals are skips (empty string whole template).

By default set to hashref C<< {'handler'=>'ep', 'layout' => undef,} >>.

  exception => 'template', 

=head1 Methods, subs, helpers...

Implements register method only. Register new renderer handler. No new helpers.

=head1 SEE ALSO

L<CGI>

L<CGI::HTML::Functions>

L<Mojolicious::Plugin::TagHelpers>

L<HTML::Tiny>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-RenderCGI/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016+ Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut