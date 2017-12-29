package Mojolicious::Plugin::StaticShare::Controller;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::File qw(path);
use HTTP::AcceptLanguage;
use Mojo::Path;
use Mojo::Util qw ( decode encode url_unescape xml_escape);# 
use Time::Piece;# module replaces the standard localtime and gmtime functions with implementations that return objects
#~ use Mojo::Asset::File;

has plugin => sub {   shift->stash('plugin') };
has public_uploads => sub { shift->plugin->public_uploads };
has is_admin => sub {
  my $c = shift;
  $c->plugin->is_admin($c);
};

sub get {
  my ($c) = @_;
  
  $c->_stash();
  
  return $c->not_found
    if !$c->is_admin && grep {/^\./} @{$c->stash('url_path')->parts};
  
  if ($c->plugin->access) {
    my $access = ref $c->plugin->access eq 'CODE' ? $c->plugin->access->($c) : $c->plugin->access;
    
    return $c->not_found
      unless $access;
    
    return $c->render(%$access)
      if ref $access eq 'HASH';
  }
  
  if ($c->is_admin && $c->param('admin')) {
    # Temporary Redirect
    $c->res->code(307);
    return $c->redirect_to($c->req->url->to_abs->path);
  }

  my $file_path = $c->stash('file_path');
  
  return $c->dir($file_path)
    if -d $file_path;
  return $c->file($file_path)
    if -f $file_path;

  $c->not_found;
}

sub post {
  my ($c) = @_;
  $c->_stash();
  
  #~ if ($c->is_admin && $c->param('admin')) {
    # Temporary Redirect
    #~ $c->res->code(307);
    #~ return $c->redirect_to($c->req->url->to_abs->path);
  #~ }
  
  my $file_path = $c->stash('file_path');
  
  if ($c->is_admin && (my $dir = $c->param('dir'))) {
    return $c->new_dir($file_path, $dir);
  } elsif ($c->is_admin && (my $rename = $c->param('rename'))) {
    return $c->rename($file_path, $rename);
  } elsif ($c->is_admin && (my $delete = $c->param('delete[]') && $c->every_param('delete[]'))) {
    return $c->delete($file_path, $delete);
  } elsif ($c->is_admin && defined(my $edit = $c->param('edit'))) {
    return $c->_edit($file_path, $edit);
  }
  
  return $c->render(json=>{error=>$c->i18n('target directory not found')})
    if !$c->is_admin && grep {/^\./} @{$c->stash('url_path')->parts};
  
  return $c->render(json=>{error=>$c->i18n('you cant upload')})
    unless $c->is_admin || $c->public_uploads;
  
  
  return $c->render(json=>{error=>$c->i18n('Cant open target directory')})
    unless -w $file_path;
  #~ $c->req->max_message_size(0);
  # Check file size
  return $c->render(json=>{error=>$c->i18n('upload is too big')}, status=>417)
    if $c->req->is_limit_exceeded;

  my $file = $c->req->upload('file')
    or return $c->render(json=>{error=>$c->i18n('Where is your upload file?')});
  my $name = url_unescape($c->param('name') || $file->filename);
  utf8::upgrade($name);
  return $c->render(json=>{error=>$c->i18n('Provide the name of upload file')})
    unless $name =~ /\S/i;
  
  my $to = $file_path->child($name);
  
  return $c->render(json=>{error=>$c->i18n('path is not a directory')})
    unless -d $file_path;
  return $c->render(json=>{error=>$c->i18n('file already exists')})
    if -e $to;
  
  eval { $file->asset->move_to($to) }
    or return $c->render(json=>{error=>$@  =~ /(.+) at /});
  
  $c->render(json=>{ok=> $c->stash('url_path')->merge($name)->to_route});
}

sub _stash {
  my ($c) = @_;

  my $lang = HTTP::AcceptLanguage->new($c->req->headers->accept_language || 'en;q=0.5');
  $c->stash('language' => $lang);
  
  my $pth = Mojo::Path->new($c->stash('pth'))->leading_slash(0)->trailing_slash(0);
  $pth = $pth->trailing_slash(1)->merge('.'.$c->stash('format'))
    if $c->stash('format');
  $c->stash('pth' => $pth);
  my $url_path = $c->plugin->root_url->clone->merge($pth)->trailing_slash(1);
  $c->stash('url_path' => $url_path);
  #~ $c->stash('file_path' => $c->plugin->root_dir->clone->merge($c->stash('pth')));
  $c->stash('file_path' => path(decode('UTF-8', url_unescape($c->plugin->root_dir->clone->merge($pth)))));
  $c->stash('title' => $c->i18n('Share')." ".$url_path->to_route);
}


sub dir {
  my ($c, $path) = @_;
  
  return $c->not_found
    if ($c->plugin->render_dir // '') eq 0;
  
  my $ex = Mojo::Exception->new($c->i18n(qq{Cant open directory}));
  opendir(my $dir, $path)
    or return $c->render_maybe('Mojolicious-Plugin-StaticShare/exception', format=>'html', handler=>'ep', status=>500, exception=>$ex)
      || $c->reply->exception($ex);
  
  my $files = $c->stash('files' => [])->stash('files');
  my $dirs = $c->stash('dirs' => [])->stash('dirs');
  
  while (readdir $dir) {
    next
      if $_ eq '.' || $_ eq '..';
    next
      if !$c->is_admin && /^\./;
    
    my $child = $path->child(decode('UTF-8', $_));
    
    push @$dirs, decode('UTF-8', $_)
      and next
      if -d $child && -r _;
    
    next
      unless -f _;
    
    my @stat = stat $child;
    
    push @$files, {
      name  => decode('UTF-8', $_),
      size  => $stat[7] || 0,
      #~ type  => $c->plugin->mime->type(  (/\.([0-9a-zA-Z]+)$/)[0] || 'txt' ) || 'application/octet-stream',
      mtime => decode('UTF-8', localtime( $stat[9] )->strftime), #->to_datetime, #to_string(),
      #~ mode=> $stat[2] & 07777, #-r _,
    };
  }
  closedir $dir;
  
  for my $index ($c->plugin->dir_index ? @{$c->plugin->dir_index} : ()) {
    my $file = $path->child($index);
    next
      unless -f $file;
    
    $c->_stash_markdown($file)
      and $c->stash(index=>$index)
      and last
      if $index =~ $c->plugin->re_markdown;
    
    $c->_stash_pod($file)
      and $c->stash(index=>$index)
      and last
      if $index =~ $c->plugin->re_pod;

  }
  
  return $c->render(ref $c->plugin->render_dir ? %{$c->plugin->render_dir} : $c->plugin->render_dir,)
    if $c->plugin->render_dir; 
  
  $c->render_maybe("Mojolicious-Plugin-StaticShare/$_/dir", format=>'html', handler=>'ep',)
    and return
    for $c->stash('language')->languages;
  
  return $c->render('Mojolicious-Plugin-StaticShare/dir', format=>'html', handler=>'ep',);

  
  #~ $c->render_maybe('Mojolicious-Plugin-StaticShare/exception', format=>'html', handler=>'ep', status=>500,exception=>Mojo::Exception->new(qq{Template rendering for dir content not found}))
    #~ or $c->reply->exception();
}

sub new_dir {
  my ($c, $path, $dir) = @_;
  
  my $edir = url_unescape($dir);
  utf8::upgrade($edir);
  
  return $c->render(json=>{error=>$c->i18n('provide the name of new directory')})
    unless $edir =~ /\S/;
  
  my $to = $path->child($edir);#
  
  return $c->render(json=>{error=>$c->i18n('dir or file exists')})
    if -e $to;
  
  $to->make_path;
  
  $c->render(json=>{ok=> $c->stash('url_path')->clone->merge($dir)->trailing_slash(1)->to_route});
  
}

sub rename {
  my ($c, $path, $rename) = @_;
  
  my $ename = url_unescape($rename);
  utf8::upgrade($ename);
  
  return $c->render(json=>{error=>$c->i18n('provide new name')})
    unless $ename =~ /\S/;
  
  my $to = $path->sibling($ename);
  
  return $c->render(json=>{error=>$c->i18n('dir or file exists')})
    if -e $to;
  
  my $move = eval { $path->move_to($to) }
    or return $c->render(json=>{error=>$@ =~ /(.+) at /});
  
  $c->render(json=>{ok=> $c->stash('url_path')->trailing_slash(0)->to_dir->merge($rename)->to_route});
  
}

sub delete {
  my ($c, $path, $delete) = @_;
  my @delete = ();
  for (@$delete) {
    my $del = url_unescape($_);
    utf8::upgrade($del);
    push @delete, $c->i18n('provide the name of deleted dir')
      and next
      unless $del =~ /\S/;
    my $d = $path->sibling($del);
    push @delete, $c->i18n('dir or file does not exists')
      and next
      unless -e $d;
    push @delete, eval {$d->remove_tree()} ? 1 : 0,
  }
  
  $c->render(json=>{ok=>\@delete});
}

sub file {
  my ($c, $path) = @_;
  
  my $ex = Mojo::Exception->new($c->i18n(qq{Permission denied}));
  return $c->render_maybe('Mojolicious-Plugin-StaticShare/exception', format=>'html', handler=>'ep', status=>500,exception=>$ex)
    || $c->reply->exception($ex)
    unless -r $path;
  
  return $c->_edit($path)
    if $c->is_admin && $c->param('edit');
  
  my $filename = $path->basename;
  
  return $c->_markdown($path)
    unless ($c->plugin->render_markdown || '') eq 0 || $c->param('attachment') || $filename !~ $c->plugin->re_markdown;
  
  return $c->_pod($path)
    unless ($c->plugin->render_pod || '') eq 0 || $c->param('attachment') || $filename !~ $c->plugin->re_pod;
  
  my $asset = $c->_html($path)
    unless $c->param('attachment') || $filename !~ $c->plugin->re_html;
  
  $c->res->headers->content_disposition($c->param('attachment') ? "attachment; filename=$filename;" : "inline");
  my $type  =$c->plugin->mime->type(  ( $path =~ /\.([0-9a-zA-Z]+)$/)[0] || 'txt' ) || $c->plugin->mime->type('txt');#'application/octet-stream';
  $c->res->headers->content_type($type);
  $c->reply->asset($asset || Mojo::Asset::File->new(path => $path));
}

sub _html {# disable scripts inside html
  my ($c, $path) = @_;
  my $file = Mojo::Asset::File->new(path => $path);
  my $content = $file->slurp;
  my $dom = Mojo::DOM->new($content);
  $dom->find('script')->each(\&_sanitize_script)->size
    or return $file;
  
  my $asset = Mojo::Asset::Memory->new;
  $asset->add_chunk($dom)->mtime($file->mtime);
  return $asset;
}

sub _markdown {# file
  my ($c, $path) = @_;

  my $ex = Mojo::Exception->new($c->i18n(qq{Please install or verify markdown module (default to Text::Markdown::Hoedown) with markdown(\$str) sub or parse(\$str) method}));

  $c->_stash_markdown($path)
    or return $c->render_maybe('Mojolicious-Plugin-StaticShare/exception', format=>'html', handler=>'ep', status=>500,exception=>$ex)
        || $c->reply->exception($ex);
  
  return $c->plugin->render_markdown
    ? $c->render(ref $c->plugin->render_markdown ? %{$c->plugin->render_markdown} : $c->plugin->render_markdown,)
    : $c->render('Mojolicious-Plugin-StaticShare/markdown', format=>'html', handler=>'ep',);
}

my $layout_re = qr|^(?:\s*%+\s*layouts/(.+)[;\s]+)|;

sub _stash_markdown {
  my ($c, $path) = @_;
  my $md = $c->plugin->markdown
    or return; # not installed
  my $content = decode('UTF-8', $path->slurp);
  $content =~ s|$layout_re|$c->_layout_index($1)|e;#) {# || $content =~ s/(?:%\s*layout\s+"([^"]+)";?)//m
  my $dom = Mojo::DOM->new($md->parse($content));
  $dom->find('script')->each(\&_sanitize_script);
  $dom->find('*')->each(\&_dom_attrs);
  $c->stash(markdown => $dom->at('body') || $dom);
  #~ my $filename = $path->basename;
  #~ $c->stash('title'=>$filename);
}

my $layout_ext_re = qr|\.([^/\.;\s]+)?\.?([^/\.;\s]+)?$|; # .html.ep

sub _layout_index {# from regexp execute
  my ($c, @match) = @_;#
  $match[0] =~ s|[;\s]+$||;
  #~ utf8::encode($match[0]);
  push @match, $1, $2
    if $match[0] =~ s|$layout_ext_re||;
  my $found = $c->app->renderer->template_path({
      template => "layouts/$match[0]",
      format   => $match[1] || 'html',
      handler  => $match[2] || 'ep',
    });
  $c->layout($match[0])#encode('UTF-8', $match[0]))
    and return ''
    if $found;
  my $err = "layout [$match[0]].$match[1].$match[2] not found";
  $c->app->log->error("$err", "\t app->renderer->paths: ", @{$c->app->renderer->paths});
  return "<div style='color:red;'>$err</div>";
}

sub _sanitize_script {# for markdown
  my $el = shift;
  my $text = xml_escape $el->text;
  $el->replace("<code class=script>$text</code>");
}

sub _dom_attrs {# for markdown
# translate ^{...} to id, style, class attributes
# берем только первый child и он должен быть текстом
  my $el = shift;
  my $text = $el->text
    or return;
  my $child1 = $el->child_nodes->first;
  my $parent = $child1->parent;
  return
    unless $parent && $parent->type eq 'tag' && $child1->type eq 'text';
  my $content = $child1->content;
  if ($content =~ s|^(?:\s*\{([^\}]+)\}\s*)||) {
    my $attrs = $1;
    utf8::upgrade($attrs);
    # styles
    $parent->{style} .= " $1"
      while $attrs =~ s|(\S+\s*:\s*[^;]+;)||;
    # id
    $parent->{id}  = $1
      while $attrs =~ s|#(\S+)||;
    # classes
    $parent->{class} .= " $1"
      while $attrs =~ s|\.?([^\.\s]+)||;
    $child1->content($content);# replace
  }
}

sub _pod {# file
  my ($c, $path) = @_;

  $c->_stash_pod($path)
    or return;# $c->render_maybe('Mojolicious-Plugin-StaticShare/exception', format=>'html', handler=>'ep', status=>500,exception=>$ex)
        #~ || $c->reply->exception($ex);
  
  return $c->plugin->render_pod
    ? $c->render(ref $c->plugin->render_pod ? %{$c->plugin->render_pod} : $c->plugin->render_pod,)
    : $c->render('Mojolicious-Plugin-StaticShare/pod', format=>'html', handler=>'ep',);
  
}

sub _stash_pod {
  my ($c, $path) = @_;
  return
    unless $c->app->renderer->helpers->{'pod_to_html'};

  my $content = decode('UTF-8', $path->slurp);
  $content =~ s|$layout_re|$c->_layout_index($1)|e;#) {# || $content =~ s/(?:%\s*layout\s+"([^"]+)";?)//m
  my $dom = Mojo::DOM->new($c->pod_to_html($content));
  $dom->find('script')->each(\&_sanitize_script);
  $dom->find('*')->each(\&_dom_attrs);
  $c->stash(pod =>  $dom->at('body') || $dom);
  #~ my $filename = $path->basename;
  #~ $c->stash('title'=>$filename);
}

sub not_found {
  my $c = shift;
  $c->render_maybe('Mojolicious-Plugin-StaticShare/not_found', format=>'html', handler=>'ep', status=>404,)
    or $c->reply->not_found;
  
};

sub _edit {
  my ($c, $path, $edit) = @_;
  unless (defined $edit) {# get
    $c->stash('edit'=> decode('UTF-8', $path->slurp));
    $c->stash('title' => $c->i18n('Edit')." ".$c->stash('url_path')->to_route);
    return $c->render('Mojolicious-Plugin-StaticShare/edit', format=>'html', handler=>'ep',);
  }
  
  # save
  $path->spurt(encode('UTF-8', $edit));
  $c->render(json=>{ok=>$path->to_string});
}

1;

=pod

=encoding utf8

Доброго всем

=head1 Mojolicious::Plugin::StaticShare::Controller

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::StaticShare::Controller - is an internal controller for L<Mojolicious::Plugin::StaticShare>.


=cut