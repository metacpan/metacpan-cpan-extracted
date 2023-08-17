package Plack::App::DirectoryIndex;

use parent qw[Plack::App::Directory];

use strict;
use warnings;

use Plack::Util::Accessor qw[dir_index pretty];
use URI::Escape;

our $VERSION = '0.0.4';

sub standard_css {
  return <<CSS;
table {
  width: 100%;
}
.name {
  text-align:l eft;
}
.size, .mtime {
  text-align: right;
}
.type {
  width: 11em;
}
.mtime {
  width: 15em;
}
CSS
}

sub pretty_css {
  return <<CSS;
body {
  color: #000;
  background-color: #fff; 
  font-family: Calibri, Candara, Segoe, Segoe UI, Helvetica Neue, Helvetica, Optima, Arial, sans-serif;
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
  border: 1px solid #aaa;
  border-collapse: collapse;
  background-color: #eee;
}

thead {
  background-color: #bbb;
  font-weight: 700;
  font-size: 1.300em;
}

td, th {
  padding: 1em;
  text-align: left;
  border-bottom: 1px solid #999999;
  color: #000;
}

tr:nth-child(even) {
  background: #ccc;
}

.size {
  text-align: right;
  padding-right: 1.700em;
}

a:link {
  font-size: 1.200em;
  font-weight: 500;
  color: #000;
  text-decoration: none;
}

a:link:hover {
  text-decoration: underline;
}

a:visited {
  font-size: 1.200em;
  font-weight: 500;
  color: #301934;
  text-decoration: none;
}
CSS
}

sub file_html {
  return <<FILE;
  <tr>
    <td class='name'><a href='%s'>%s</a></td>
    <td class='size'>%s</td>
    <td class='type'>%s</td>
    <td class='mtime'>%s</td>
  </tr>
FILE
}

sub dir_html {
  return <<DIR;
<html>
  <head>
    <title>%s</title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <style type='text/css'>
%s
    </style>
  </head>
  <body>
    <h1>%s</h1>
    <hr />
    <table>
      <thead>
        <tr>
          <th class='name'>Name</th>
          <th class='size'>Size</th>
          <th class='type'>Type</th>
          <th class='mtime'>Last Modified</th>
        </tr>
      </thead>
      <tbody>
%s
      </tbody>
    </table>
    <hr />
  </body>
</html>
DIR
}

# NOTE: Copied from Plack::App::Directory as that module makes it
# impossible to override the HTML.

sub serve_path {
  my $self = shift;
  my ($env, $dir) = @_;

  my $dir_index = $self->dir_index // 'index.html';

  if (-d $dir and $dir_index and -f "$dir$dir_index") {
    $dir .= $dir_index;
  }

  if (-f $dir) {
    return $self->SUPER::serve_path($env, $dir);
  }
 
  my $dir_url = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
 
  if ($dir_url !~ m{/$}) {
    return $self->return_dir_redirect($env);
  }
 
  my @files = ([ "../", "Parent Directory", '', '', '' ]);
 
  my $dh = DirHandle->new($dir);
  my @children;
  while (defined(my $ent = $dh->read)) {
    next if $ent eq '.' or $ent eq '..';
    push @children, $ent;
  }
 
  for my $basename (sort { $a cmp $b } @children) {
    my $file = "$dir/$basename";
    my $url = $dir_url . $basename;
 
    my $is_dir = -d $file;
    my @stat = stat _;
 
    $url = join '/', map {uri_escape($_)} split m{/}, $url;
 
    if ($is_dir) {
      $basename .= "/";
      $url      .= "/";
    }
 
    my $mime_type = $is_dir ? 'directory' : ( Plack::MIME->mime_type($file) || 'text/plain' );
    push @files, [ $url, $basename, $stat[7], $mime_type, HTTP::Date::time2str($stat[9]) ];
  }
 
  my $path  = Plack::Util::encode_html("Index of $env->{PATH_INFO}");
  my $files = join "\n", map {
    my $f = $_;
    sprintf $self->file_html, map Plack::Util::encode_html($_), @$f;
  } @files;
  my $page  = sprintf $self->dir_html, $path,
                      ($self->pretty ? $self->pretty_css : $self->standard_css),
                      $path, $files;
 
  return [ 200, ['Content-Type' => 'text/html; charset=utf-8'], [ $page ] ];
}

1;

__END__
 
=head1 NAME
 
Plack::App::DirectoryIndex - Serve static files from document root with an index file.
 
=head1 SYNOPSIS
 
  # app.psgi
  use Plack::App::DirectoryIndex;

  # Use the default index file (index.html)
  my $app = Plack::App::DirectoryIndex->new({
    root => '/path/to/htdocs',
  })->to_app;

  # Use a different index file
  my $app = Plack::App::DirectoryIndex->new({
    root      => '/path/to/htdocs',
    dir_index => 'default.html',
  })->to_app;

  # Don't use an index file (but you're probably better
  # off just using Plack::App::Directory instead)
  my $app = Plack::App::DirectoryIndex->new({
    root      => '/path/to/htdocs',
    dir_index => '',
  })->to_app;
  

=head1 DESCRIPTION
 
This is a static file server PSGI application with directory index like
Apache's mod_autoindex. Unlike L<Plack::App::Directory>, it will also
look for a default index file (e.g. index.html) and serve that instead
of a directory listing.
 
=head1 CONFIGURATION
 
=over 4
 
=item root
 
Document root directory. Defaults to the current directory.

=item dir_index

The name of the directory index file that you want to use. This will
default to using C<index.html>. You can turn it off by setting this
value to an empty string (but if you don't want a default index file,
then you should probably use L<Plack::App::Directory> instead).

=back
 
=head1 AUTHOR
 
Dave Cross E<lt>dave@perlhacks.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2020 Magnum Solutions Limited. All rights reserved.

=head1 LICENCE

This code is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=head1 SEE ALSO

=over 4
 
=item L<Plack::App::File>

A Plack application for serving static files from a directory. This
app only returns files. If you request a directory, you will get a
404 error.

=item L<Plack::App::Directory>

Another Plack application for serving static files from a directory.
This app will serve a directory listing if you request one, but it
doesn't support default directory index files like C<index.html>.

=item L<Plack::Middleware::DirIndex>

This is Plack middleware that it intended to add support for a
default directory index file to an existing Plack application.
Unfortunately, it is an all-or-nothing solution. If you use this
middleware, then whenever you request a directory, it will add
the directory index filename to the end of the request path. If
your directory doesn't contain a file with the correct name
(ususally C<index.html>), then it will return a 404 error.

=back

=cut
