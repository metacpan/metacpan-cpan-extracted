package Mojolicious::Plugin::StaticShare;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::File qw(path);
use Mojolicious::Types;
use Mojo::Path;
use Mojo::Util qw(encode);

our $VERSION = '0.02';
my $PKG = __PACKAGE__;

has [qw(app config)];
has root_url => sub { Mojo::Path->new(encode('UTF-8', shift->config->{root_url}))->leading_slash(1)->trailing_slash(1) };
has root_dir => sub { Mojo::Path->new(shift->config->{root_dir} // '.')->trailing_slash(1) };
has markdown => sub {# parser
  my $self = shift;
   __internal__::Markdown->new($self->config->{markdown_pkg});
};
has is_markdown => sub { qr{[.]m(?:d(?:own)?|kdn?|arkdown)$}i };
has is_pod => sub { qr{p(?:od|m|l)} };
has mime => sub { Mojolicious::Types->new };

sub register {
  my ($self, $app, $args) = @_;
  $self->config($args);
  $self->app($app);
  
  require Mojolicious::Plugin::StaticShare::Templates
    and push @{$app->renderer->classes}, "$PKG\::Templates"
    and push @{$app->static->paths}, path(__FILE__)->sibling('StaticShare')->child('static') 
    unless defined($args->{render_dir}) && $args->{render_dir} eq 0
          && defined($args->{render_markdown}) && $args->{render_markdown} eq 0;
  
  $args->{markdown_pkg} //= 'Text::Markdown::Hoedown';
  $args->{dir_index} //= [qw(README.md INDEX.md README.pod INDEX.pod)];
  $args->{public_uploads} //= 0;
  
  my $route = $self->root_url->clone->merge('*pth');#"$args->{root_url}/*pth";
  my $r = $app->routes;
  $r->get($self->root_url->to_route)->to(namespace=>$PKG, controller=>"Controller", action=>'get', pth=>'', plugin=>$self)->name("$PKG ROOT");
  $r->post($self->root_url->to_route)->to(namespace=>$PKG, controller=>"Controller", action=>'post', pth=>'', plugin=>$self)->name("$PKG ROOT POST");
  $r->get($route->to_route)->to(namespace=>$PKG, controller=>"Controller", action=>'get', plugin=>$self )->name("$PKG GET");
  $r->post($route->to_route)->to(namespace=>$PKG, controller=>"Controller", action=>'post', plugin=>$self )->name("$PKG POST");

  $app->helper(i18n => sub { &i18n(@_) });
  
  #POD
  $self->app->plugin(PODRenderer => {no_perldoc => 1})
    unless $self->app->renderer->helpers->{'pod_to_html'} || defined($args->{render_pod}) && $args->{render_pod} eq 0;
  
  return $app;
}

my %loc = (
  'ru-ru'=>{
    'Not found'=>"Не найдено",
    'Error on path'=>"Ошибка в",
    'Error'=>"Ошибка",
    'Permission denied'=>"Нет доступа",
    'Cant open directory'=>"Нет доступа в папку",
    'Share'=>'Обзор',
    'Index of'=>'Содержание',
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

1;
=pod

=encoding utf8

Доброго всем

=head1 Mojolicious::Plugin::StaticShare

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::StaticShare - browse, upload, copy, move, delete static files/dirs.

=head VERSION

0.02

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('StaticShare', <options>);

  # Mojolicious::Lite
  plugin 'StaticShare', <options>;
  
  # oneliner
  $ perl -MMojolicious::Lite -E 'plugin("StaticShare", root_url=>"/my/share",)->secrets([rand])->start' daemon


=head1 DESCRIPTION

This plugin for share static files/dirs and has public and admin functionality:

=head2 Public interface

Can browse and upload files if name not exists.

=head2 Admin interface

Can copy, move, delete files/dirs.

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

C<pth>, C<url_path>, C<file_path>, C<language>, C<dirs>, C<files>, C<index>

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

Filename for markdown or pod rendering in page below dirs and files.

=head2 render_markdown

Same as B<render_dir> but for markdown files. Defaults to builtin things.

  render_markdown =>  'foo/markdown',
  render_markdown => {template => 'foo/markdown', foo=>...},
  # Disable markdown rendering
  render_markdown => 0,

=head2 markdown_pkg

Module name for render markdown. Must contains C<sub markdown {}>. Defaults to L<Text::Markdown::Hoedown>.

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

Boolean to disable/enable uploads for public users. Defaults to 0 (disable).

  public_uploads=>1, # enable

=head1 UTF-8

Everywhere  and everything: module, files, content.

=head1 METHODS

L<Mojolicious::Plugin::StaticShare> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

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
