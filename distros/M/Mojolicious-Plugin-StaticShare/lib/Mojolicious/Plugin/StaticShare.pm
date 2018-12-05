package Mojolicious::Plugin::StaticShare;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::File qw(path);
use Mojolicious::Types;
use Mojo::Path;
use Mojo::Util;# qw(decode);

my $PKG = __PACKAGE__;

has [qw(app)] => undef, weak => 1;
has [qw(config)];# => undef, weak => 1;
has root_url => sub { Mojo::Path->new(shift->config->{root_url})->leading_slash(1)->trailing_slash(1) };
has root_dir => sub { Mojo::Path->new(shift->config->{root_dir} // '.')->trailing_slash(1) };
has admin_pass => sub { shift->config->{admin_pass} };
has access => sub { shift->config->{access} };
has public_uploads => sub { !! shift->config->{public_uploads} };
has render_dir =>  sub { shift->config->{render_dir} };
has dir_index => sub { shift->config->{dir_index} // [qw(README.md INDEX.md README.pod INDEX.pod)] };
has render_pod =>  sub { shift->config->{render_pod} };
has render_markdown =>  sub { shift->config->{render_markdown} };
has markdown_pkg => sub { shift->config->{markdown_pkg} // 'Text::Markdown::Hoedown' };
has templates_dir => sub { shift->config->{templates_dir} };
has markdown => sub {# parser object
   __internal__::Markdown->new(shift->markdown_pkg);
};
has re_markdown => sub { qr{[.]m(?:d(?:own)?|kdn?|arkdown)$}i };
has re_pod => sub { qr{[.]p(?:od|m|l)$} };
has re_html => sub { qr{[.]html?$} };
has mime => sub { Mojolicious::Types->new };
has max_upload_size => sub { shift->config->{max_upload_size} };
has routes_names => sub {
  my $self = shift;
  return [$self." ROOT GET (#1)", $self." ROOT POST (#2)", $self." PATH GET (#3)", $self." PATH POST (#4)"];
};
has debug => sub { shift->config->{debug} // $ENV{StaticShare_DEBUG} };


sub register {# none magic
  my ($self, $app, $args) = @_;
  $self->config($args);
  $self->app($app);
  
  my $push_class = "$PKG\::Templates";
  my $push_path = path(__FILE__)->sibling('StaticShare')->child('static');
  
  require Mojolicious::Plugin::StaticShare::Templates
    and push @{$app->renderer->classes}, grep($_ eq $push_class, @{$app->renderer->classes}) ? () : $push_class
    and push @{$app->static->paths}, grep($_ eq $push_path, @{$app->static->paths}) ? () : $push_path
    unless ($self->render_dir // '') eq 0
          && ($self->render_markdown // '') eq 0;
  push @{$app->renderer->paths}, ref $self->templates_dir ? @{$self->templates_dir} : $self->templates_dir
    if $self->templates_dir;
  
  # ROUTING 4 routes
  my $route = $self->root_url->clone->merge('*pth');#"$args->{root_url}/*pth";
  my $r = $app->routes;
  my $names = $self->routes_names;
  $r->get($self->root_url->to_route)->to(namespace=>$PKG, controller=>"Controller", action=>'get', pth=>'', plugin=>$self, )->name($names->[0]);#$PKG
  $r->post($self->root_url->to_route)->to(namespace=>$PKG, controller=>"Controller", action=>'post', pth=>'', plugin=>$self, )->name($names->[1]);#->name("$PKG ROOT POST");
  $r->get($route->to_route)->to(namespace=>$PKG, controller=>"Controller", action=>'get', plugin=>$self, )->name($names->[2]);#;
  $r->post($route->to_route)->to(namespace=>$PKG, controller=>"Controller", action=>'post', plugin=>$self, )->name($names->[3]);#;
  
  
  
  path($self->config->{root_dir})->make_path
    unless !$self->config->{root_dir} || -e $self->config->{root_dir};

  $app->helper(i18n => \&i18n);
  #~ $app->helper(StaticShareIsAdmin => sub { $self->is_admin(@_) });
  
  #POD
  $self->app->plugin(PODRenderer => {no_perldoc => 1})
    unless $self->app->renderer->helpers->{'pod_to_html'} && ($self->render_pod // '') eq 0 ;
  
  # PATCH EMIT CHUNK
  $self->_patch_emit_chunk()
    if defined $self->max_upload_size;
  
  #~ warn $self, Mojo::Util::dumper($self->config);
  
  return ($app, $self);
}

my %loc = (
  'ru-ru'=>{
    'Not found'=>"Не найдено",
    'Error on path'=>"Ошибка в",
    'Error'=>"Ошибка",
    'Permission denied'=>"Нет доступа",
    'Cant open directory'=>"Нет доступа в папку",
    'Share'=>'Обзор',
    'Edit'=>'Редактировать',
    'Index of'=>'Содержание',
    'Dirs'=>'Папки',
    'Files'=>'Файлы',
    'Name'=>'Название файла',
    'Size'=>'Размер',
    'Last Modified'=>'Дата изменения',
    'Up'=>'Выше',
    'Down'=>'Ниже',
    'Add uploads'=>'Добавить файлы',
    'Add dir'=>'Добавить папку',
    'root'=>"корень",
    'Uploading'=>'Загружается',
    'file is too big'=>'слишком большой файл',
    'path is not directory'=>"нет такого каталога/папки",
    'file already exists' => "такой файл уже есть",
    'new dir name'=>"имя новой папки",
    'Confirm to delete these files'=>"Подтвердите удаление этих файлов",
     'Confirm to delete these dirs'=>"Подтвердите удаление этих папок", 
    'I AM SURE'=>"ДА",
    'Save'=> 'Сохранить',
    'Success saved' => "Успешно сохранено",
    'you cant delete'=>"Удаление запрещено, обратитесь к админу",
    'you cant upload'=>"Запрещено, обратитесь к админу",
    'you cant create dir'=>"Создание папки запрещено, обратитесь к админу",
    'you cant rename'=>"Переименование запрещено, обратитесь к админу",
    'you cant edit' => "Редактирование запрещено, обратитесь к админу",
  },
);
sub i18n {# helper
  my ($c, $str, $lang) = @_;
  #~ $lang //= $c->stash('language');
  return $str
    unless $c->stash('language');
  my $loc;
  for ($c->stash('language')->languages) {
    return $str
      if /en/;
    $loc = $loc{$_} || $loc{lc $_} || $loc{lc "$_-$_"}
      and last;
  }
  return $loc->{$str} || $loc->{lc $str} || $str
    if $loc;
  return $str;
}

sub is_admin {# as helper
  my ($self, $c) = @_;
  return 
    unless my $pass = $self->admin_pass;
  my $sess = $c->session;
  $sess->{StaticShare}{admin} = 1
    if $c->param('admin') && $c->param('admin') eq $pass;
  return $sess->{StaticShare} && $sess->{StaticShare}{admin};
}

sub _patch_emit_chunk {
  my $self = shift;
  
  Mojo::Util::monkey_patch 'Mojo::Transaction::HTTP', 'server_read' => sub {
    my ($self, $chunk) = @_;
    
    $self->emit('chunk before req parse'=>$chunk);### только одна строка патча этот эмит
   
    # Parse request
    my $req = $self->req;
    $req->parse($chunk) unless $req->error;
    
    $self->emit('chunk'=>$chunk);### только одна строка патча этот эмит
   
    # Generate response
    $self->emit('request') if $req->is_finished && !$self->{handled}++;
    
  };
  
  #~ my $r1 = $self->app->routes->lookup($self->routes_names->[1]);
  #~ warn  'POST ROUTE #2', $r1;
  #~ my $r2 = $self->app->routes->lookup($self->routes_names->[3]);
  #~ warn  'POST ROUTE #4', $r2;
  
  $self->app->hook(after_build_tx => sub {
    my ($tx, $app) = @_;
      $tx->once('chunk'=>sub {
      my ($tx, $chunk) = @_;
      return unless $tx->req->method =~ /PUT|POST/;
      my $url = $tx->req->url->to_abs;
      my $match = Mojolicious::Routes::Match->new(root => $self->app->routes);
      $match->find(undef, {method => $tx->req->method, path => $tx->req->url->path->to_route,});# websocket => $ws
      my $route = $match->endpoint
        || return;
      
      #~ warn "TX CHUNK ROUTE: ", $route->name;# eq $self->routes_names->[1] || $route->name eq $self->routes_names->[3]);#Mojo::Util::dumper($url);, length($chunk)
      $tx->req->max_message_size($self->max_upload_size)
        if $route->name eq $self->routes_names->[1] || $route->name eq $self->routes_names->[3]
      # TODO admin session
      
    });
  });
  
}

##############################################
package __internal__::Markdown;
sub new {
  my $class  = shift;
  my $pkg = shift;
  return
    unless eval "require $pkg;  1";#
  #~ $pkg->import
    #~ if $pkg->can('import');
  return $pkg->new()
    if $pkg->can('new') && $pkg->can('parse');
  return
    unless $pkg->can('markdown');
  bless {pkg=>$pkg} => $class;
}

sub parse { my $self = shift; no strict 'refs'; ($self->{pkg}.'::markdown')->(@_); }

our $VERSION = '0.070';
=pod

=encoding utf8

Доброго всем

=head1 Mojolicious::Plugin::StaticShare

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::StaticShare - browse, upload, copy, move, delete, edit, rename static files and dirs.

=head1 VERSION

0.070

=head1 SYNOPSIS

  # Mojolicious
  $app->plugin('StaticShare', <options>);

  # Mojolicious::Lite
  plugin 'StaticShare', <options>;
  
  # oneliner
  $ perl -MMojolicious::Lite -E 'plugin("StaticShare", root_url=>"/my/share",)->secrets([rand])->start' daemon

L</MULTI-PLUGIN> also.

=head1 DESCRIPTION

This plugin allow to share static files/dirs/markdown and has public and admin functionality:

=head2 Public interface

Can browse and upload files if name not exists.

=head2 Admin interface

Can copy, move, delete, rename and edit content of files/dirs.

Append param C<< admin=<admin_pass> option >> to any url inside B<root_url> requests (see below).

=head1 OPTIONS

=head2 root_dir

Absolute or relative file system path root directory. Defaults to '.'.

  root_dir => '/mnt/usb',
  root_dir => 'foo', 

=head2 root_url

This prefix to url path. Defaults to '/'.

  root_url => '/', # mean route '/*pth'
  root_url => '', # mean also route '/*pth'
  root_url => '/my/share', # mean route '/my/share/*pth'

See L<Mojolicious::Guides::Routing#Wildcard-placeholders>.

=head2 admin_pass

Admin password (be sure https) for admin tasks. None defaults.

  admin_pass => '$%^!!9nes--', # 

Signin to admin interface C< https://myhost/my/share/foo/bar?admin=$%^!!9nes-- >

=head2 render_dir

Template path, format, handler, etc  which render directory index. Defaults to builtin things.

  render_dir => 'foo/dir_index', 
  render_dir => {template => 'foo/my_directory_index', foo=>...},
  # Disable directory index rendering
  render_dir => 0,

=head3 Usefull stash variables

Plugin make any stash variables for rendering: C<pth>, C<url_path>, C<file_path>, C<language>, C<dirs>, C<files>, C<index>

=head4 pth

Path of request exept C<root_url> option, as L<Mojo::Path> object.

=head4 url_path

Path of request with C<root_url> option, as L<Mojo::Path> object.

=head4 language

Req header AcceptLanguage as L<HTTP::AcceptLanguage> object.

=head4 dirs

List of scalars dirnames. Not sorted.

=head4 files

List of hashrefs (C<name, size, mtime> keys) files. Not sorted.

=head4 index

Filename for markdown or pod rendering in page below the column dirs and column files.

=head2 templates_dir

String or arrayref strings. Simply C<< push @{$app->renderer->paths}, <templates_dir>; >>. None defaults.

Mainly needs for layouting markdown. When you set this option then you can define layout inside markdown/pod files like syntax:

  % layouts/foo.html.ep
  # Foo header

=head2 render_markdown

Same as B<render_dir> but for markdown files. Defaults to builtin things.

  render_markdown =>  'foo/markdown',
  render_markdown => {template => 'foo/markdown', foo=>...},
  # Disable markdown rendering
  render_markdown => 0,

=head2 markdown_pkg

Module name for render markdown. Must contains sub C<markdown($str)> or method C<parse($str)>. Defaults to L<Text::Markdown::Hoedown>.

  markdown_pkg =>  'Foo::Markup';

Does not need to install if C<< render_markdown => 0 >> or never render md files.

=head2 render_pod

Template path, format, handler, etc  which render pod files. Defaults to builtin things.

  render_pod=>'foo/pod',
  render_pod => {template => 'foo/pod', layout=>'pod', foo=>...},
  # Disable pod rendering
  render_pod => 0,

=head2 dir_index

Arrayref to match files to include to directory index page. Defaults to C<< [qw(README.md INDEX.md README.pod INDEX.pod)] >>.

  dir_index => [qw(DIR.md)],
  dir_index => 0, # disable include markdown to index dir page

=head2 public_uploads

Boolean to disable/enable uploads for public users. Defaults to undef (disable).

  public_uploads=>1, # enable

=head2 max_upload_size

  max_upload_size=>0, # unlimited

Numeric value limiting uploads size for route. See L<Mojolicious#max_request_size>, L<Mojolicious#build_tx>.

=head1 Extended markdown & pod

You can place attributes like:

=head2 id (# as prefix)

=head2 classnames (dot as prefix and separator)

=head2 css-style rules (key:value; colon separator and semicolon terminator)

to markup elements as below.

In markdown:

  # {#foo123 .class1 .class2 padding: 0 0.5rem;} Header 1
  {.brown-text} brown paragraph text ...

In pod:

  =head2 {.class1.blue-text border-bottom: 1px dotted;} Header 2
  
  {.red-text} red color text...

=head1 METHODS

L<Mojolicious::Plugin::StaticShare> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 MULTI PLUGIN

A possible:

  # Mojolicious
  $app->plugin('StaticShare', <options-1>)
           ->plugin('StaticShare', <options-2>); # and so on ...
  
  # Mojolicious::Lite
  app->config(...)
         ->plugin('StaticShare', <options-1>)
         ->plugin('StaticShare', <options-2>) # and so on ...
         ...

=head1 UTF-8

Everywhere  and everything: module, files, content.

=head1 WINDOWS OS

It was not tested but I hope you dont worry and have happy.

=head1 SEE ALSO

L<Mojolicious::Plugin::Directory>

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-StaticShare/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2017 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
