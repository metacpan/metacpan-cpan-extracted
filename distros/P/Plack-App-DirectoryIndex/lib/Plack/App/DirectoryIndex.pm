package Plack::App::DirectoryIndex;

use parent qw[Plack::App::Directory];

use strict;
use warnings;

use Plack::Util::Accessor qw[dir_index icons pretty];
use WebServer::DirIndex;

our $VERSION = '0.2.3';

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

  my %dir_index_args = (
    dir     => $dir,
    dir_url => $dir_url,
  );

  $dir_index_args{pretty} = $self->pretty if defined $self->pretty;
  $dir_index_args{icons}  = $self->icons  if defined $self->icons;
 
  my $di   = WebServer::DirIndex->new(%dir_index_args);
  my $page = $di->to_html($env->{PATH_INFO});

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

  # Use the prettier CSS for directory listings
  my $app = Plack::App::DirectoryIndex->new({
    root   => '/path/to/htdocs',
    pretty => 1,
  })->to_app;

  # Disable icons in directory listings
  my $app = Plack::App::DirectoryIndex->new({
    root  => '/path/to/htdocs',
    icons => 0,
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

=item icons

If set to a true value, the directory listing page will include Font
Awesome icons for popular file types. Defaults to true (i.e. icons
are shown). Set to a false value to disable icons entirely.

=item pretty

If set to a true value, the directory listing page will be rendered
using an enhanced CSS stylesheet for a more attractive appearance.
Defaults to false (i.e. the standard minimal CSS is used).

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
