package Plack::App::Libarchive;

use strict;
use warnings;
use 5.034;
use parent qw( Plack::Component );
use experimental qw( signatures postderef try );
use Plack::MIME;
use Plack::Util::Accessor qw( archive tt tt_include_path );
use Path::Tiny qw( path );
use Archive::Libarchive qw( ARCHIVE_WARN ARCHIVE_EOF );
use Template;
use File::ShareDir::Dist qw( dist_share );
use Encode qw( encode );

# ABSTRACT: Serve an archive via libarchive as a PSGI web app
our $VERSION = '0.02'; # VERSION


sub prepare_app ($self)
{
  my $path = path($self->archive);
  $self->{data}  = $path->slurp_raw;

  unless(defined $self->tt_include_path)
  {
    $self->tt_include_path([]);
  }

  unless(defined $self->tt)
  {
    my @path = ($self->tt_include_path->@*, dist_share(__PACKAGE__));
    my $sep  = $^O eq 'MSWin32' ? ';' : ':';

    $self->tt(
      Template->new(
        WRAPPER            => 'wrapper.html.tt',
        DELIMITER          => $sep,
        INCLUDE_PATH       => join($sep, @path),
        render_die         => 1,
        TEMPLATE_EXTENSION => '.tt',
        ENCODING           => 'utf8',
      )
    );
  };
}

sub call ($self, $env)
{
  my $path = $env->{PATH_INFO} || '/';
  return $self->return_400 if $path =~ /\0/;
  return $self->return_index($env) if $path eq '/';
  return $self->return_entry($path);
}

sub return_entry ($self, $path)
{
  $path =~ s{^/}{};

  my $ar = Archive::Libarchive::ArchiveRead->new;
  $ar->support_filter_all;
  $ar->support_format_all;

  my $ret = $ar->open_memory(\$self->{data});
  if($ret == ARCHIVE_WARN)
  {
    warn $ar->error_string;
  }
  elsif($ret < ARCHIVE_WARN)
  {
    warn $ar->error_string;
    return $self->return_500;
  }

  my $e = Archive::Libarchive::Entry->new;
  while(1)
  {
    my $ret = $ar->next_header($e);
    if($ret == ARCHIVE_EOF)
    {
      last;
    }
    elsif($ret == ARCHIVE_WARN)
    {
      warn $ar->error_string;
    }
    elsif($ret < ARCHIVE_WARN)
    {
      warn $ar->error_string;
      return $self->return_500;
    }

    if($e->pathname eq $path)
    {
      my $content_type = Plack::MIME->mime_type($path);
      $content_type .= "; charset=utf-8" if $content_type =~ /^text\/(html|plain)$/;

      my $res = [ 200, [ 'Content-Type' => $content_type ], [ '' ] ];

      if($e->size > 0)
      {
        while(1)
        {
          my $buffer;
          my $ret = $ar->read_data(\$buffer);
          last if $ret == 0;
          if($ret == ARCHIVE_WARN)
          {
            warn $ar->error_string;
          }
          elsif($ret < ARCHIVE_WARN)
          {
            warn $ar->error_string;
            return $self->return_500;
          }
          $res->[2]->[0] .= $buffer;
        }
      }

      push $res->[1]->@*, 'Content-Length' => length($res->[2]->[0]);

      return $res;
    }
    $ar->read_data_skip;
  }

  if($path =~ /^\/?favicon.ico$/)
  {
    my $content = path(dist_share(__PACKAGE__))->child('favicon.ico')->slurp_raw;
    return [ 200,
      [
        'Content-Type'   => 'image/vnd.microsoft.icon',
        'Content-Length' => length $content,
      ],
      [ $content ],
    ];
  }

  return $self->return_404;
}

sub return_index ($self, $env)
{
  if($env->{PATH_INFO} eq '') {
    my $url = $env->{REQUEST_URI};
    $url =~ s/\/*$/\//;
    if($url ne $env->{REQUEST_URI})
    {
      return
        [ 301,
          [
            'Location'       => $url,
            'Content-Type'   => 'text/plain',
            'Content-Length' => 8,
          ],
          [ 'Redirect' ],
        ];
    }
  }

  my $ar = Archive::Libarchive::ArchiveRead->new;
  $ar->support_filter_all;
  $ar->support_format_all;

  my $ret = $ar->open_memory(\$self->{data});
  if($ret == ARCHIVE_WARN)
  {
    warn $ar->error_string;
  }
  elsif($ret < ARCHIVE_WARN)
  {
    warn $ar->error_string;
    return $self->return_500;
  }

  my $html = '';
  my $entry = Archive::Libarchive::Entry->new;

  try
  {
    $self->tt->process('archive_index.html.tt', {
      archive => {
        name           => path($self->archive)->basename,
        get_next_entry => sub {
          my $ret = $ar->next_header($entry);
          return undef if $ret == ARCHIVE_EOF;
          warn $ar->error_string if $ret == ARCHIVE_WARN;
          die $ar->error_string if $ret < ARCHIVE_WARN;
          $ret = $ar->read_data_skip;
          warn $ar->error_string if $ret == ARCHIVE_WARN;
          die $ar->error_string if $ret < ARCHIVE_WARN;
          return $entry;
        },
      }
    }, \$html);
    $html = encode('UTF-8', $html, Encode::FB_CROAK);
  }
  catch ($error)
  {
    warn $error;
    return $self->return_500;
  }

  return [ 200,
         [ 'Content-Type' => 'text/html; charset=utf-8', 'Content-Length' => length($html) ],
         [ $html ]
  ]
}

sub return_500 ($self)
{
  return [500, ['Content-Type' => 'text/plain', 'Content-Length' => 21], ['Internal Server Error']];
}

sub return_400 ($self)
{
  return [400, ['Content-Type' => 'text/plain', 'Content-Length' => 11], ['Bad Request']];
}

sub return_404 ($self)
{
  return [404, ['Content-Type' => 'text/plain', 'Content-Length' => 9], ['Not Found']];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::Libarchive - Serve an archive via libarchive as a PSGI web app

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Plack::App::Libarchive;
 my $app = Plack::App::Libarchive->new( archive => 'foo.tar.tz' )->to_app;

=head1 DESCRIPTION

This L<PSGI> application serves the content of an archive (any format supported
by C<libarchive> via L<Archive::Libarchive>).  A request to the root for the
app will return an index of the files contained within the archive.

The index is generated using L<Template>.  There is a bundled template that
will list the entry files and link to their content.  If you want to customize
the index you can provide your own template.  Here are the template variables
that are available from within the template:

=over 4

=item C<archive>

A hash reference containing information about the archive

=item C<archive.name>

The basename of the archive filename.  For example: C<foo.tar.gz>.

=item C<archive.get_next_entry>

Get the next L<Archive::Libarchive::Entry> object from the archive.

=back

Here is the default wrapper.html.tt:

 <!doctype html>
 <html>
   <head>
     <meta charset="utf-8" />
     <title>[% archive.name %]</title>
   </head>
   <body>
     [% content %]
   </body>
 </html>

and the default archive_index.html.tt

 <ul>
   [% WHILE (entry = archive.get_next_entry) %]
     <li><a href="[% entry.pathname | uri %]">[% entry.pathname | html %]</a></li>
   [% END %]
 </ul>

=head1 CONFIGURATION

=over 4

=item archive

The relative or absolute path to the archive.

=item tt

Instance of L<Template> that will be used to generate the html index.  The default
is:

 Template->new(
   WRAPPER            => 'wrapper.html.tt',
   INCLUDE_PATH       => File::ShareDir::Dist::dist_share('Plack-App-Libarchive'),
   DELIMITER          => ':',
   render_die         => 1,
   TEMPLATE_EXTENSION => '.tt',
   ENCODING           => 'utf8',
 )

On C<MSWin32> a delimiter of C<;> is used instead.

=item tt_include_path

Array reference of additional L<Template INCLUDE_PATH directories|Template/INCLUDE_PATH>.  This
id useful for writing your own custom template.

=back

=head1 SEE ALSO

=over 4

=item L<Archive::Libarchive>

=item L<Plack>

=item L<PSGI>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
