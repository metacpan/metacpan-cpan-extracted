package Plack::App::Directory::Apaxy;
{
  $Plack::App::Directory::Apaxy::VERSION = '0.004';
}
# ABSTRACT: Serve static files from document root with directory index using Apaxy

use parent qw(Plack::App::Directory);
use strict;
use warnings;

use Plack::MIME;
use Plack::Util;

use Number::Bytes::Human;
use Path::Tiny;
use Time::Piece;
use URI::Escape;

use Plack::Util::Accessor qw( apaxy_root below footer );

our %MIME_TYPE_TO_ALT = (
    "application/atom+xml"                            => q{rss},
    "application/font-woff"                           => q{default},
    "application/java-archive"                        => q{java},
    "application/javascript"                          => q{js},
    "application/json"                                => q{json},
    "application/mathml+xml"                          => q{xml},
    "application/mbox"                                => q{default},
    "application/msword"                              => q{doc},
    "application/octet-stream"                        => q{bin},
    "application/ogg"                                 => q{audio},
    "application/pdf"                                 => q{pdf},
    "application/pgp-encrypted"                       => q{default},
    "application/pgp-signature"                       => q{default},
    "application/postscript"                          => q{ps},
    "application/rdf+xml"                             => q{xml},
    "application/rss+xml"                             => q{rss},
    "application/rtf"                                 => q{rtf},
    "application/vnd.ms-cab-compressed"               => q{archive},
    "application/vnd.ms-excel"                        => q{doc},
    "application/vnd.ms-htmlhelp"                     => q{doc},
    "application/vnd.ms-powerpoint"                   => q{doc},
    "application/vnd.oasis.opendocument.presentation" => q{doc},
    "application/vnd.oasis.opendocument.spreadsheet"  => q{doc},
    "application/vnd.oasis.opendocument.text"         => q{doc},
    "application/wsdl+xml"                            => q{xml},
    "application/x-bittorrent"                        => q{default},
    "application/x-bzip-compressed-tar"               => q{gzip},
    "application/x-bzip2"                             => q{gzip},
    "application/x-debian-package"                    => q{debian},
    "application/x-dvi"                               => q{default},
    "application/x-gzip"                              => q{gzip},
    "application/x-java-jnlp-file"                    => q{java},
    "application/x-msdownload"                        => q{default},
    "application/x-rar-compressed"                    => q{rar},
    "application/x-redhat-package-manager"            => q{rpm},
    "application/x-sh"                                => q{script},
    "application/x-shockwave-flash"                   => q{default},
    "application/x-tar"                               => q{tar},
    "application/x-tcl"                               => q{script},
    "application/x-tex"                               => q{tex},
    "application/x-texinfo"                           => q{tex},
    "application/x-x509-ca-cert"                      => q{default},
    "application/xhtml+xml"                           => q{xml},
    "application/xml"                                 => q{xml},
    "application/xml-dtd"                             => q{xml},
    "application/xslt+xml"                            => q{xml},
    "application/zip"                                 => q{zip},
    "audio/basic"                                     => q{audio},
    "audio/midi"                                      => q{audio},
    "audio/mpeg"                                      => q{audio},
    "audio/x-aiff"                                    => q{audio},
    "audio/x-mpegurl"                                 => q{audio},
    "audio/x-ms-wma"                                  => q{audio},
    "audio/x-pn-realaudio"                            => q{audio},
    "audio/x-wav"                                     => q{audio},
    "image/bmp"                                       => q{bmp},
    "image/gif"                                       => q{gif},
    "image/jpeg"                                      => q{jpg},
    "image/png"                                       => q{png},
    "image/svg+xml"                                   => q{image},
    "image/tiff"                                      => q{tiff},
    "image/vnd.adobe.photoshop"                       => q{psd},
    "image/vnd.djvu"                                  => q{image},
    "image/vnd.microsoft.icon"                        => q{image},
    "image/x-portable-anymap"                         => q{image},
    "image/x-portable-bitmap"                         => q{image},
    "image/x-portable-graymap"                        => q{image},
    "image/x-portable-pixmap"                         => q{image},
    "image/x-xbitmap"                                 => q{image},
    "image/x-xpixmap"                                 => q{image},
    "message/rfc822"                                  => q{default},
    "model/vrml"                                      => q{default},
    "text/cache-manifest"                             => q{text},
    "text/calendar"                                   => q{text},
    "text/css"                                        => q{css},
    "text/csv"                                        => q{text},
    "text/html"                                       => q{html},
    "text/plain"                                      => q{text},
    "text/sgml"                                       => q{text},
    "text/troff"                                      => q{text},
    "text/x-asm"                                      => q{text},
    "text/x-c"                                        => q{c},
    "text/x-diff"                                     => q{diff},
    "text/x-fortran"                                  => q{text},
    "text/x-java-source"                              => q{java},
    "text/x-pascal"                                   => q{text},
    "text/x-script.perl"                              => q{perl},
    "text/x-script.perl-module"                       => q{perl},
    "text/x-script.python"                            => q{py},
    "text/x-script.ruby"                              => q{rb},
    "text/x-vcalendar"                                => q{vcal},
    "text/x-vcard"                                    => q{text},
    "text/yaml"                                       => q{text},
    "video/3gpp"                                      => q{video},
    "video/mp4"                                       => q{video},
    "video/mpeg"                                      => q{video},
    "video/ogg"                                       => q{video},
    "video/quicktime"                                 => q{video},
    "video/x-flv"                                     => q{video},
    "video/x-mng"                                     => q{video},
    "video/x-ms-asf"                                  => q{video},
    "video/x-ms-wmv"                                  => q{video},
    "video/x-ms-wmx"                                  => q{video},
    "video/x-msvideo"                                 => q{video},
);

my $dir_file = q{<tr> <td valign="top"><img src="/_apaxy/icons/%s.png" alt="[%s]" /></td> <td><a href="%s">%s</a></td> <td align="right">%s</td> <td align="right">%s</td> </tr>};

sub _get_dir_page_fmt {
    my $self = shift;

    my $dir_page = <<"END_PAGE";
<!DOCTYPE html>
<html>
  <head>
    <title>%s</title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <link rel="stylesheet" href="/_apaxy/style.css" type="text/css" />
  </head>
  <body>
    <div class="wrapper">
      <div>
        <h1>%s</h1>
        <table>
          <tr>
            <th><img src="/_apaxy/icons/blank.png" alt="[ICO]" /></th>
            <th><a href="?C=N;O=D">Name</a></th>
            <th><a href="?C=M;O=A">Last modified</a></th>
            <th><a href="?C=S;O=A">Size</a></th>
          </tr>
%s
        </table>
      </div>
      <div class="block"> @{[ $self->below ]} </div>
    </div>
    <div class="footer"> @{[ $self->footer ]} </div>
    <script>
      // grab the 2nd child and add the parent class. tr:nth-child(2)
      document.getElementsByTagName('tr')[1].className = 'parent';
    </script>
  </body>
</html>
END_PAGE

    return $dir_page;
}

sub prepare_app {
    my $self = shift;

    $self->below(q{}) unless defined $self->below;

    $self->footer(<<'END_TEXT') unless defined $self->footer;
<a href="https://metacpan.org/module/Plack::App::Directory::Apaxy">Plack::App::Directory::Apaxy</a> is proudly made with
<a href="http://adamwhitcroft.com/apaxy/">Apaxy</a>,
<a href="http://plackperl.org/">Plack</a>
&amp; <a href="http://www.perl.org/">Perl</a>.
END_TEXT

    unless ( $self->apaxy_root ) {
        $self->apaxy_root( path(__FILE__)->parent->child(qw/ Apaxy public /) );
    }
}

# Stolen from Plack::App::File (Plack version 1.0030)
sub call {
    my $self = shift;
    my $env  = shift;

    my ( $file, $path_info ) = $self->file;
    if ( !$file ) {
        ( $file, $path_info ) = $self->locate_file($env);
        if ( ref $file eq 'ARRAY' ) {
            return $file unless $file->[0] == 404;

            ( $file, $path_info ) = $self->locate_apaxy($env);
            return $file if ref $file eq 'ARRAY';
        }
    }

    if ($path_info) {
        $env->{'plack.file.SCRIPT_NAME'} = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
        $env->{'plack.file.SCRIPT_NAME'} =~ s/\Q$path_info\E$//;
        $env->{'plack.file.PATH_INFO'}   = $path_info;
    }
    else {
        $env->{'plack.file.SCRIPT_NAME'} = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
        $env->{'plack.file.PATH_INFO'}   = q{};
    }

    return $self->serve_path( $env, $file );
}

# Stolen from Plack::App::File (Plack version 1.0030)
sub locate_apaxy {
    my ( $self, $env ) = @_;

    my $path = $env->{PATH_INFO} || q{};
    return $self->return_400 if     $path =~ m{\0};
    return $self->return_404 unless $path =~ m{^(/_apaxy/|/favicon.ico$)};

    my $docroot = $self->apaxy_root;
    my @path = split /[\\\/]/, $path;
    if (@path) {
        shift @path if $path[0] eq q{};
    }
    else {
        @path = (q{.});
    }
    return $self->return_403 if grep $_ eq q{..}, @path;

    my $file = path( $docroot, @path );
    return $self->return_404 unless $self->should_handle($file);
    return $self->return_403 unless -r $file;

    return $file, join( q{/}, q{}, @path );
}

# Stolen from Plack::App::Directory (Plack version 1.0030)
sub serve_path {
    my ( $self, $env, $dir ) = @_;

    return $self->SUPER::serve_path( $env, $dir ) if -f $dir;

    if ( $dir =~ m{^(/_apaxy/|/favicon.ico$)} ) {
        my $docroot = $self->apaxy_root;
        my $file    = path( $docroot, $dir );
        return $self->SUPER::serve_path( $env, $file ) if -f $file;
    }

    my $dir_url = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
    return $self->return_dir_redirect($env) if $dir_url !~ m{/$};

    my @files = ([
        q{folder-home},
        q{DIR},
        q{../},
        q{Parent Directory},
        q{},
        q{-},
    ]);

    #
    # sort using C/O/D/H
    #
    my $req       = Plack::Request->new($env);
    my $category  = $req->param('C') || q{N};
    my $order     = $req->param('O') || q{A};
    my $dir_first = $req->param('D') || q{Y};
    my $hide      = $req->param('H') || q{Y};

    my @children;
    if ( $hide eq 'Y' ) {
        @children = map +{ path => $_, stat => $_->stat, is_dir => -d _ }, grep { $_->basename !~ /^\./ } path($dir)->children;
    }
    else {
        @children = map +{ path => $_, stat => $_->stat, is_dir => -d _ }, path($dir)->children;
    }

    if ( $dir_first eq 'Y' ) {
        if ( $order eq 'A' ) {
            if ( $category eq 'M' ) {
                @children = sort {
                    $b->{is_dir} <=> $a->{is_dir}
                    or $a->{stat}->mtime <=> $b->{stat}->mtime
                } @children;
            }
            elsif ( $category eq 'N' ) {
                @children = sort {
                    $b->{is_dir} <=> $a->{is_dir}
                    or $a->{path} cmp $b->{path}
                } @children;
            }
            elsif ( $category eq 'S' ) {
                @children = sort {
                    $b->{is_dir} <=> $a->{is_dir}
                    or $a->{stat}->size <=> $b->{stat}->size
                } @children;
            }
        }
        elsif ( $order eq 'D' ) {
            if ( $category eq 'M' ) {
                @children = sort {
                    $b->{is_dir} <=> $a->{is_dir}
                    or $b->{stat}->mtime <=> $a->{stat}->mtime
                } @children;
            }
            elsif ( $category eq 'N' ) {
                @children = sort {
                    $b->{is_dir} <=> $a->{is_dir}
                    or $b->{path} cmp $a->{path}
                } @children;
            }
            elsif ( $category eq 'S' ) {
                @children = sort {
                    $b->{is_dir} <=> $a->{is_dir}
                    or $b->{stat}->size <=> $a->{stat}->size
                } @children;
            }
        }
    }
    else {
        if ( $order eq 'A' ) {
            if ( $category eq 'M' ) {
                @children = sort { $a->{stat}->mtime <=> $b->{stat}->mtime } @children;
            }
            elsif ( $category eq 'N' ) {
                @children = sort { $a->{path} cmp $b->{path} } @children;
            }
            elsif ( $category eq 'S' ) {
                @children = sort { $a->{stat}->size <=> $b->{stat}->size } @children;
            }
        }
        elsif ( $order eq 'D' ) {
            if ( $category eq 'M' ) {
                @children = reverse sort { $a->{stat}->mtime <=> $b->{stat}->mtime } @children;
            }
            elsif ( $category eq 'N' ) {
                @children = reverse sort { $a->{path} cmp $b->{path} } @children;
            }
            elsif ( $category eq 'S' ) {
                @children = reverse sort { $a->{stat}->size <=> $b->{stat}->size } @children;
            }
        }
    }

    for my $child (@children) {
        my $file = $child->{path};
        my $stat = $child->{stat};

        my $basename = $file->basename;
        my $url      = join '/', map { uri_escape($_) } split m{/}, $dir_url . $basename;

        my $mime_type;
        my $alt;
        my $icon;
        my $size;

        if ( $file->is_dir ) {
            $basename .= "/";
            $url      .= "/";

            $mime_type = q{directory};
            $alt       = q{DIR};
            $icon      = q{folder};
            $size      = q{-};
        }
        else {
            $mime_type = Plack::MIME->mime_type($file)    || 'text/plain';
            $alt       = uc $MIME_TYPE_TO_ALT{$mime_type} || q{   };
            $icon      = $MIME_TYPE_TO_ALT{$mime_type}    || 'default';
            $size      = Number::Bytes::Human::format_bytes( $stat->size );
        }

        my $dt = localtime $stat->mtime;
        push @files, [
            $icon,
            $alt,
            $url,
            $basename,
            sprintf( '%s %02d:%02d', $dt->ymd, $dt->hour, $dt->minute ),
            $size,
        ];
    }

    my $path  = Plack::Util::encode_html("Index of $env->{PATH_INFO}");
    my $files = join "\n", map {
        my $f = $_;
        sprintf q{   } x 8 . $dir_file, map Plack::Util::encode_html($_), @$f;
    } @files;
    my $page  = sprintf $self->_get_dir_page_fmt, $path, $path, $files;

    return [ 200, [ 'Content-Type' => 'text/html; charset=utf-8' ], [$page] ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::Directory::Apaxy - Serve static files from document root with directory index using Apaxy

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    # app.psgi
    use Plack::App::Directory::Apaxy;
    my $app = Plack::App::Directory->new({ root => "/path/to/htdocs" })->to_app;

    # one-liner
    $ plackup -MPlack::App::Directory::Apaxy -e 'Plack::App::Directory::Apaxy->new->to_app'

    # one-liner using Starlet
    $ plackup -s Starlet -MPlack::App::Directory::Apaxy --max-workers=5 -e 'Plack::App::Directory::Apaxy->new->to_app'

=head1 DESCRIPTION

This is a static file server PSGI application with directory index using Apaxy.

=head1 ATTRIBUTES

=head2 root

Document root directory. Defaults to the current directory.

=head2 apaxy_root

Apaxy resource root directory. Usually you don't need to set it up by your hand.

=head2 below

HTML contents what you want to insert to index page.

=head2 footer

HTML contents what you want to insert to index page.

=head1 SEE ALSO

=over 4

=item *

L<Plack::App::Directory>

=item *

L<Apaxy|http://adamwhitcroft.com/apaxy/>

=back

=head1 AUTHOR

Keedi Kim - 김도형 <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
