package Mojolicious::Plugin::Directory::Stylish;
$Mojolicious::Plugin::Directory::Stylish::VERSION = '1.006';
# ABSTRACT: Serve static files from document root with directory index using Mojolicious templates
use strict;
use warnings;

use Cwd ();
use Encode ();
use DirHandle;
use Mojo::Base qw{ Mojolicious::Plugin };
use Mojolicious::Types;
use Mojo::Asset::File;
use Mojo::File;

my $types = Mojolicious::Types->new;

sub register {
    my ( $self, $app, $args ) = @_;

    my $root        = Mojo::File->new( $args->{root} || Cwd::getcwd );
    my $handler     = $args->{handler};
    my $index       = $args->{dir_index};
    my $enable_json = $args->{enable_json};
    my $auto_index  = $args->{auto_index} // 1;

    my $css         = $args->{css} || 'style';
    my $render_opts = $args->{render_opts} || {};
    $render_opts->{template} = $args->{dir_template} || 'list';
    push @{ $app->renderer->classes }, __PACKAGE__;
    push @{ $app->static->classes }, __PACKAGE__;

    $app->hook(
        before_dispatch => sub {
            my $c = shift;

            return render_file( $c, $root ) if ( -f $root->to_string() );

            my $child = Mojo::Util::url_unescape( $c->req->url->path );
            $child =~ s!^/!!g;
            my $path = $root->child( $child );
            $handler->( $c, $path ) if ( ref $handler eq 'CODE' );

            if ( -f $path ) {
                render_file( $c, $path ) unless ( $c->tx->res->code );
            }
            elsif ( -d $path ) {
                if ( $index && ( my $file = locate_index( $index, $path ) ) ) {
                    return render_file( $c, $file );
                }
                if ( $auto_index ) {
                  $c->stash(css => $css),
                    render_indexes( $c, $path, $render_opts, $enable_json )
                        unless ( $c->tx->res->code );
                }
            }
        },
    );
    return $app;
}

sub locate_index {
    my $index = shift || return;
    my $dir   = shift || Cwd::getcwd;

    my $root  = Mojo::Home->new($dir);

    $index = ( ref $index eq 'ARRAY' ) ? $index : ["$index"];
    for (@$index) {
        my $path = $root->rel_file($_);
        return $path if ( -e $path );
    }
}

sub render_file {
    my ( $c, $file ) = @_;

    my $asset = Mojo::Asset::File->new(path => $file);
    $c->reply->asset($asset);
}

sub render_indexes {
    my ( $c, $dir, $render_opts, $enable_json ) = @_;

    my @files =
        ( $c->req->url eq '/' )
        ? ()
        : ( { url => '../', name => 'Parent Directory', size => '', type => '', mtime => '' } );

    my ( $current, $list ) = list_files( $c, $dir );
    push @files, @$list;

    $c->stash( files   => \@files );
    $c->stash( current => $current );

    my %respond = ( any => $render_opts );
    $respond{json} = { json => { files => \@files, current => $current } }
        if ($enable_json);

    $c->respond_to(%respond);
}

sub list_files {
    my ( $c, $dir ) = @_;

    my $current = Encode::decode_utf8( Mojo::Util::url_unescape( $c->req->url->path ) );

    return ( $current, [] ) unless $dir;

    my $dh = DirHandle->new($dir);
    my @children;
    while ( defined( my $ent = $dh->read ) ) {
        next if $ent eq '.' or $ent eq '..';
        push @children, Encode::decode_utf8($ent);
    }

    my @files;
    for my $basename ( sort { $a cmp $b } @children ) {
        my $file = "$dir/$basename";
        my $url  = Mojo::Path->new($current)->trailing_slash(0);
        push @{ $url->parts }, $basename;

        my $is_dir = -d $file;
        my @stat   = stat _;
        if ($is_dir) {
            $basename .= '/';
            $url->trailing_slash(1);
        }

        my $mime_type =
            ($is_dir)
            ? 'directory'
            : ( $types->type( get_ext($file) || 'txt' ) || 'text/plain' );
        my $mtime = Mojo::Date->new( $stat[9] )->to_string();

        push @files, {
            url   => $url,
            name  => $basename,
            size  => $stat[7] || 0,
            type  => $mime_type,
            mtime => $mtime,
        };
    }

    return ( $current, \@files );
}

sub get_ext {
    $_[0] =~ /\.([0-9a-zA-Z]+)$/ || return;
    return lc $1;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Directory::Stylish - Serve static files from document root with directory index using Mojolicious templates

=head1 VERSION

version 1.006

=head1 SYNOPSIS

  use Mojolicious::Lite;
  plugin 'Directory::Stylish';
  app->start;

or

  > perl -Mojo -E 'a->plugin("Directory::Stylish")->start' daemon

=head1 DESCRIPTION

L<Mojolicious::Plugin::Directory::Stylish> is a static file server directory index a la Apache's mod_autoindex.

=head1 METHODS

L<Mojolicious::Plugin::Directory::Stylish> inherits all methods from L<Mojolicious::Plugin>.

=head1 OPTIONS

L<Mojolicious::Plugin::Directory::Stylish> supports the following options.

=head2 C<root>

  plugin 'Directory::Stylish' => { root => "/path/to/htdocs" };

Document root directory. Defaults to the current directory.

If root is a file, serve only root file.

=head2 C<auto_index>

  # Mojolicious::Lite
  plugin 'Directory::Stylish' => { auto_index => 0 };

Automatically generate index page for directory, default true.

=head2 C<dir_index>

  plugin 'Directory::Stylish' => { dir_index => [qw/index.html index.htm/] };

Like a Apache's DirectoryIndex directive.

=head2 C<dir_template>

  plugin 'Directory::Stylish' => { dir_template => 'index' };

  # with 'render_opts' option
  plugin 'Directory::Stylish' => {
      dir_template => 'index',
      render_opts  => { format => 'html', handler => 'ep' },
  };

  ...

  __DATA__

  @@ index.html.ep
  % layout 'default';
  % title 'DirectoryIndex';
  <h1>Index of <%= $current %></h1>
  <ul>
  % for my $file (@$files) {
  <li><a href='<%= $file->{url} %>'><%== $file->{name} %></a></li>
  % }

  @@ layouts/default.html.ep
  <!DOCTYPE html>
  <html>
    <head><title><%= title %></title></head>
    <body><%= content %></body>
    %= include $css;
  </html>

A name for the template to use for the index page.

"$files", "$current", and "$css" are passed in stash.

=over 2

=item * $files: Array[Hash]

list of files and directories

=item * $current: String

current path

=item * $css: String

name of template with css that you want to include

=back

=head2 C<handler>

  use Text::Markdown qw{ markdown };
  use Path::Class;
  use Encode qw{ decode_utf8 };

  plugin 'Directory::Stylish' => {
      handler => sub {
          my ($c, $path) = @_;
          if ($path =~ /\.(md|mkdn)$/) {
              my $text = file($path)->slurp;
              my $html = markdown( decode_utf8($text) );
              $c->render( inline => $html );
          }
      }
  };

CODEREF for handle a request file.

If not rendered in CODEREF, serve as static file.

=head2 C<enable_json>

  # http://host/directory?format=json
  plugin 'Directory::Stylish' => { enable_json => 1 };

enable json response.

=head2 C<css>

  plugin 'Directory::Stylish' => { css => 'custom_template' };

  ...
  __DATA__

  @@ custom_template.html.ep
  <style type="text/css">
  body { background: black; color: white; }
  </style>

A name for the template with css that will be included by the default template
for the index.

This name will be available as C<$css> in the stash.

=head1 CONTRIBUTORS

Many thanks to the contributors for their work.

=over 2

=item * ChinaXing

=item * Su-Shee

=back

=head1 SEE ALSO

=over 2

=item * L<Mojolicious::Plugin::Directory>

=item * L<Plack::App::Directory>

=back

=head1 ORIGINAL AUTHOR

hayajo E<lt>hayajo@cpan.orgE<gt> - Original author of L<Mojolicious::Plugin::Directory>

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Hayato Imai, Andreas Guldstrand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    %= include $css;
  </head>
  <body>

<%= content %>

  </body>
</html>

@@ list.html.ep
% title "index of $current";
% layout 'default';
<h2>listing <%= $current %></h2>

<div id="container">
<table>
  <thead>
  <tr>
    <th>filename</th>
    <th class="size">size</th>
    <th>type</th>
    <th>last modified</th>
  </tr>
  </thead>
  <tbody>
  % for my $file (@$files) {
  <tr>
    <td class='name'><a href='<%= $file->{url} %>'><%== $file->{name} %></a></td>
    <td class='size'><%= $file->{size} %></td>
    <td class='type'><%= $file->{type} %></td>
    <td class='mtime'><%= $file->{mtime} %></td>
  </tr>
  % }
  </tbody>
</table>
</div>

@@ style.html.ep
<style type='text/css'>
body {
  font-size: normal 1em sans-serif;
  text-align: center;
  padding: 0;
  margin: 0;
}

h2 {
 font-size: 2.000em;
 font-weight: 700;
}

table {
  width: 90%;
  margin: 3em;
  border: 1px solid #222255;
  border-collapse: collapse;
}

thead {
  background-color: #b9b9ff;
  font-weight: 700;
  font-size: 1.300em;
}

td, th {
  padding: 1em;
  text-align: left;
  border-bottom: 1px solid #999999;
}

tr:nth-child(even) {
  background: #dfdfff;
}

.size {
  text-align: right;
  padding-right: 1.700em;
}

a {
  font-size: 1.200em;
  font-weight: 500;
  color: #534588;
  text-decoration: none;
}
</style>
