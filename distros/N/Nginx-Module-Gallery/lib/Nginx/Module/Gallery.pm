package Nginx::Module::Gallery;

use strict;
use warnings;
use utf8;
use 5.10.1;

=head1 NAME

Nginx::Module::Gallery - Gallery perl module for nginx. Like simple file index
but thumbnail replace default icon for image.

=head1 SYNOPSIS

Example of nginx http section:

    http{
        ...
        # Path to Gallery.pm
        perl_modules  /usr/share/perl5/;
        perl_require  Nginx/Module/Gallery.pm;
    }

Example of nginx server section:

    server {
        listen                  80;

        server_name             gallery.localhost;

        location / {
            perl  Nginx::Module::Gallery::handler;
            # Path to image files
            root /usr/share/images;
        }
    }

=head1 DESCRIPTION

This module not for production servers! But for single user usage.
Gallery don`t use nginx event machine, so one nginx worker per connect
(typically 8) used for slow create thumbnails!

All thumbnails cached on first request. Next show will be more fast.

=cut

=head1 VARIABLES

=cut

# Module version
our $VERSION = '0.3.0';

our %CONFIG;

# Fixed thumbnails
use constant ICON_FOLDER    => '/folder.png';
use constant ICON_UPDIR     => '/updir.png';
use constant ICON_FAVICON   => '/favicon.png';
use constant ICON_ARCHIVE   => '/archive.png';

# MIME type of unknown files
use constant MIME_UNKNOWN   => 'x-unknown/x-unknown';

# Buffer size for output archive to client
use constant ARCHIVE_BUFFER_SIZE => 4096;

# Timeout for index create
use constant EVENT_TIMEOUT  => 1;

# Nginx module is ugly
eval{ require nginx; };
die $@ if $@;

use Mojo::Template;
use MIME::Types;
use File::Spec;
use File::Basename;
use File::Path qw(make_path);
use File::Temp qw(tempfile);
use File::Find;
use Digest::MD5 'md5_hex';
use URI::Escape qw(uri_escape);
use Image::Magick;

# MIME definition objects
our $mimetypes = MIME::Types->new;
our $mime_unknown   = MIME::Type->new(
    simplified  => 'unknown/unknown',
    type        => 'x-unknown/x-unknown'
);

# Default mime for thumbnails
our $mime_png   = $mimetypes->mimeTypeOf( 'png' );

# Templates
our $mt = Mojo::Template->new;
$mt->encoding('UTF-8');

=head1 HANDLERS

=cut

=head2 index $r

Directory index handler

=cut

sub index($)
{
    my $r = shift;

    # Get configuration variables
    _get_variables($r);

    # Stop unless GET or HEAD
    return HTTP_BAD_REQUEST unless grep {$r->request_method eq $_} qw{GET HEAD};
    # Stop unless dir or file
    return HTTP_NOT_FOUND unless -f $r->filename or -d _;
    # Stop if header only
    return OK if $r->header_only;

    # show file
    return show_image($r) if -f _;
    # show directory index
    return show_index($r);
}

=head2 archive $r

Online archive response

=cut

sub archive($)
{
    my $r = shift;

    # Get configuration variables
    _get_variables($r);

    # Stop unless GET or HEAD
    return HTTP_BAD_REQUEST unless grep {$r->request_method eq $_} qw{GET HEAD};
    # Stop if header only
    return OK if $r->header_only;

    # send archive to client
    return show_archive($r);
}

=head1 FUNCTIONS

=cut

=head2 show_image

Send image to client

=cut

sub show_image($)
{
    my ($r) = @_;
    $r->send_http_header;
    $r->sendfile( $r->filename );
    return OK;
}

=head2 show_index

Send directory index to client. Try do it like event base, but use sleep.

=cut

sub show_index($)
{
    my ($r) = @_;

    $r->send_http_header("text/html; charset=utf-8");
    # Send top of index page
    $r->sleep(EVENT_TIMEOUT, sub{
        $_[0]->print( _get_index_top($_[0]->uri) );
        # Send updir link if need
        $_[0]->sleep(EVENT_TIMEOUT, sub{
            $_[0]->print( _get_index_updir($_[0]->uri) );
            # Send directory archive link
            $_[0]->sleep(EVENT_TIMEOUT, sub{
                $_[0]->print( _get_index_archive($_[0]->uri) );
                $_[0]->flush;
                # Get directory index
                $_[0]->sleep(EVENT_TIMEOUT, sub{
                    my $mask  =
                        File::Spec->catfile(_escape_path($_[0]->filename), '*');
                    my @index =
                        sort {-d $b cmp -d $a}
                        sort {uc $a cmp uc $b}
                        glob $mask;
                    if( @index ) {
                        $_[0]->variable('gallery_index', join("\n\r", @index));
                        # Send directory index
                        $_[0]->sleep(EVENT_TIMEOUT, \&_make_icon);
                    } else {
                        # Send bottom of index page
                        $_[0]->print( _get_index_bottom() );
                        $_[0]->flush;
                    }
                    return OK;
                });
                return OK;
            });
            return OK;
        });
        return OK;
    });
    return OK;
}

=head2 _make_icon

Send index item to client, or init send index bottom.

=cut

sub _make_icon {
    my ($r) = @_;

    my $index   = $r->variable('gallery_index');
    my $url = $r->uri;

    my @index = split "\n\r", $index;
    return OK unless @index;

    my $path  = shift @index;

    $r->print( _get_index_item($url, $path) ) ;
    $r->flush;

    if( @index ) {
        $r->variable('gallery_index', join("\n\r", @index));
        $r->sleep(EVENT_TIMEOUT, \&_make_icon);
        return OK;
    }
    else {
        $r->sleep(EVENT_TIMEOUT, sub {
            my ($r) = @_;
            $r->print( _get_index_bottom() );
            $r->flush;
            return OK;
        });
        return OK;
    }

    return OK;
}

=head2 show_archive

Sent archive file to client

=cut

sub show_archive($)
{
    my ($r) = @_;

    my ($filename, $dir) = File::Basename::fileparse( $r->filename );

    # Set read buffer size
    local $/ = ARCHIVE_BUFFER_SIZE;

    # Get image params
    open my $pipe1, '-|:raw',
        '/bin/tar',
        '--create',
        '--force-local',
        '--bzip2',
        '--exclude-caches-all',
        '--exclude-vcs',
        '--directory', $dir,
        '.'
            or return HTTP_NOT_FOUND;

    $r->header_out("Content-Encoding", 'bzip2');
    $r->send_http_header("application/x-tar");

    while(my $data = <$pipe1>) {
        $r->print( $data );
    }
    close $pipe1;

    return OK;
}

=head2 get_icon_form_cache $path

Check icon for image by $path in cache and return it if exists

=cut

sub get_icon_form_cache($$)
{
    my ($path, $uri) = @_;

    my ($filename, $dir) = File::Basename::fileparse($path);

    # Find icon
    my $mask = File::Spec->catfile(
        _escape_path( File::Spec->catdir($CONFIG{CACHE_PATH}, $dir) ),
        sprintf( '%s.*', _get_md5_image( $path ) )
    );
    my ($cache_path) = glob $mask;

    # Icon not found
    return unless $cache_path;

    my ($image_width, $image_height, $ext) =
        $cache_path =~ m{^.*\.(\d+)x(\d+)\.(\w+)$}i;

    my ($icon_filename, $icon_dir) = File::Basename::fileparse($cache_path);

    return {
        href        => _escape_url($CONFIG{CACHE_PREFIX}, $uri, $icon_filename),
        filename    => $icon_filename,
        mime        => $mimetypes->mimeTypeOf( $ext ),
        image       => {
            width   => $image_width,
            height  => $image_height,
        },
        thumb       => 1,
        cached      => 1,
    };
}

=head2 update_icon_in_cache $path, $uri, $mime

Get $path and $uri of image and make icon for it

=cut

sub update_icon_in_cache($$;$)
{
    my ($path, $uri, $mime ) = @_;

    # Get MIME type of original file
    $mime //= $mimetypes->mimeTypeOf( $path ) || $mime_unknown;

    my $icon;

    # Get raw thumbnail data
    if($mime->subType eq 'vnd.microsoft.icon')
    {
        $icon = _get_icon_thumb( $path );
    }
    elsif( $mime->mediaType eq 'video' )
    {
        $icon = _get_video_thumb( $path );
    }
    elsif( $mime->mediaType eq 'image' )
    {
        $icon = _get_image_thumb( $path );
    }

    return unless $icon;

    # Save thunbnail
    $icon = _save_thumb($icon);

    # Make href on thumbnail
    $icon->{href} =
        _escape_url( $CONFIG{CACHE_PREFIX}, $uri, $icon->{filename} );

    # Cleanup
    delete $icon->{raw};

    return wantarray ?%$icon :$icon;
}

=head1 PRIVATE FUNCTIONS

=cut

=head2 _get_video_thumb $path

Get raw thumbnail data for video file by it`s $path

=cut

sub _get_video_thumb($)
{
    my ($path) = @_;

    # Get standart extension
    my @ext     = $mime_png->extensions;
    my $suffix  = $ext[0] || 'png';

    # Full file read
    local $/;

    # Convert to temp thumbnail file
    my ($fh, $filename) =
        tempfile( UNLINK => 1, OPEN => 1, SUFFIX => '.'.$suffix );
    return unless $fh;

    system '/usr/bin/ffmpegthumbnailer',
        '-s', $CONFIG{ICON_MAX_DIMENSION},
        '-q', $CONFIG{ICON_QUALITY_LEVEL},
#            '-f',
        '-i', $path,
        '-o', $filename;

    # Get image
    my $raw = <$fh>;
    close $fh or return;
    return unless $raw;

    my $mime = $mime_png || $mime_unknown;

    my %result = (
        raw     => $raw,
        mime    => $mime,
        orig    => {
            path    => $path,
        },
    );

    return wantarray ?%result :\%result;
}

=head2 _get_image_thumb $path

Get raw thumbnail data for image file by it`s $path

=cut

sub _get_image_thumb($)
{
    my ($path) = @_;

    # Get image and attributes
    my $image = Image::Magick->new;
    $image->Read($path);
    my ($image_width, $image_height, $image_size) =
        $image->Get("width", "height", "filesize");

    # Save image on disk:
    # Remove any sequences (for GIF)
    for (my $x = 1; $image->[$x]; $x++) {
        undef $image->[$x];
    }
    # Remove original comments, EXIF, etc.
    $image->Strip;
    # make tumbnail
    $image->Thumbnail(geometry =>
        $CONFIG{ICON_MAX_DIMENSION}.'x'.$CONFIG{ICON_MAX_DIMENSION}.'>');
    # Set colors
    $image->Quantize(colorspace => 'RGB');
    # Orient
    $image->AutoOrient;
    # Some compression
    $image->Set(quality => $CONFIG{ICON_COMPRESSION_LEVEL});

    # Get mime type as icon type
    my $mime = $mime_png || $mime_unknown;

    my %result = (
        mime    => $mime,
        orig    => {
            path    => $path,
            width   => $image_width,
            heigth  => $image_height,
            size    => $image_size,
        },
        save    => sub {
            my ($cache) = @_;
            my $msg = $image->Write( $cache );
            undef $image;
            warn "$msg" if "$msg";
            return 1;
        }
    );

    return wantarray ?%result :\%result;
}

=head2 _get_image_thumb $path

Get raw thumbnail data for icon file by it`s $path

=cut

sub _get_icon_thumb($)
{
    my ($path) = @_;

    # Show just small icons
    return unless -s $path < $CONFIG{ICON_MAX_SIZE};

    # Full file read
    local $/;

    # Get image
    open my $fh, '<:raw', $path or return;
    my $raw = <$fh>;
    close $fh or return;
    return unless $raw;

    my $mime = $mimetypes->mimeTypeOf( $path ) || $mime_unknown;

    my %result = (
        raw     => $raw,
        mime    => $mime,
        orig    => {
            path    => $path,
        },
    );

    return wantarray ?%result :\%result;
}

=head2 _save_thumb $icon

Save $icon in cache

=cut

sub _save_thumb($)
{
    my ($icon) = @_;

    my ($filename, $dir) = File::Basename::fileparse($icon->{orig}{path});

    # Create dirs unless exists
    my $path = File::Spec->catdir($CONFIG{CACHE_PATH}, $dir);
    unless(-d $path) {
        my $error;
        make_path(
            $path,
            {
                mode    => oct $CONFIG{CACHE_MODE},
                error   => \$error,
            }
        );
        return if @$error;
    }

    my $icon_filename = sprintf( '%s.%dx%d.%s',
        _get_md5_image( $icon->{orig}{path} ),
        $icon->{orig}{width},
        $icon->{orig}{height},
        $icon->{mime}->subType
    );

    # Make path
    my $cache = File::Spec->catfile(
        $CONFIG{CACHE_PATH}, $dir, $icon_filename );

    # Store icon on disk
    if( $icon->{save} ) {
        $icon->{save}->( $cache );
    } else {
        open my $f, '>:raw', $cache or return;
        print $f $icon->{raw};
        close $f;
    }

    # Set path and flag
    $icon->{path}       = $cache;
    $icon->{thumb}      = 1;
    $icon->{cached}     = 1;
    $icon->{filename}   = $icon_filename;

    return $icon;
}

=head2 _template $name

Retrun template my $name

=cut

sub _template($)
{
    my ($name) = @_;

    # Return template if loaded
    our %template;
    return $template{ $name } if $template{ $name };

    # Load template
    my $path = File::Spec->catfile($CONFIG{TEMPLATE_PATH}, $name.'.html.ep');
    open my $f, '<:utf8', $path or return;
    local $/;
    $template{ $name } = <$f>;
    close $f;

    return $template{ $name };
}

=head2 _icon_mime $path

Return mime icon for file by $path

=cut

sub _icon_mime
{
    my ($path) = @_;

    my ($filename, $dir) = File::Basename::fileparse($path);
    my ($extension) = $filename =~ m{\.(\w+)$};

    my $mime    = $mimetypes->mimeTypeOf( $path ) || $mime_unknown;
    my $str     = "$mime";
    my $media   = $mime->mediaType;
    my $sub     = $mime->subType;
    my $full    = join '-', $mime =~ m{^(.*?)/(.*)$};

    my @ext = $mime_png->extensions;

    my $href = _escape_url(
        $CONFIG{MIME_PREFIX},
        sprintf( '%s.%s', $full, ($ext[0] || 'png') ),
    );

    return {
        mime    => $mime,
        href    => $href,
    };
}

=head2 as_human_size(NUM)

converts big numbers to small 1024 = 1K, 1024**2 == 1M, etc

=cut

sub _as_human_size($)
{
    my ($size, $sign) = (shift, 1);

    my %result = (
        original    => $size,
        digit       => 0,
        letter      => '',
        human       => 'N/A',
        byte        => '',
    );

    {{
        last unless $size;
        last unless $size >= 0;

        my @suffixes = ('', 'K', 'M', 'G', 'T', 'P', 'E');
        my ($limit, $div) = (1024, 1);
        for (@suffixes)
        {
            if ($size < $limit || $_ eq $suffixes[-1])
            {
                $size = $sign * $size / $div;
                if ($size < 10)
                {
                    $size = sprintf "%1.2f", $size;
                }
                elsif ($size < 50)
                {
                    $size = sprintf "%1.1f", $size;
                }
                else
                {
                    $size = int($size);
                }
                s/(?<=\.\d)0$//, s/\.00?$// for $size;
                $result{digit}  = $size;
                $result{letter} = $_;
                $result{byte}   = 'B';
                last;
            }
            $div = $limit;
            $limit *= 1024;
        }
    }}

    $result{human} = $result{digit} . $result{letter} . $result{byte};

    return ($result{digit}, $result{letter}, $result{byte}, $result{human})
        if wantarray;
    return $result{human};
}

=head2 _get_md5_image $path

Return unque MD5 hex string for image file by it`s $path

=cut

sub _get_md5_image($)
{
    my ($path) = @_;
    my ($size, $mtime) = ( stat($path) )[7,9];
    return md5_hex
        join( ',', $path, $size, $mtime,
            $CONFIG{ICON_MAX_DIMENSION}, $CONFIG{ICON_COMPRESSION_LEVEL},
            $CONFIG{ICON_QUALITY_LEVEL}
        );
}

=head2 _escape_path $path

Return escaped $path

=cut

sub _escape_path($)
{
    my ($path) = @_;
    my $escaped = $path;
    $escaped =~ s{([\s'".?*\(\)\+\}\{\]\[])}{\\$1}g;
    return $escaped;
}

=head2 _escape_url @path

Return escaped uri for list of @path partitions

=cut

sub _escape_url(@)
{
    my (@path) = @_;
    my @dirs;
    push @dirs, File::Spec->splitdir( $_ ) for @path;
    $_ = uri_escape $_ for @dirs;
    return File::Spec->catfile( @dirs );
}

=head2 _get_variables $r

Get configuration variables from request $r

=cut

sub _get_variables
{
    my ($r) = @_;

    $CONFIG{$_} //= $r->variable( $_ )
        for qw(ICON_MAX_DIMENSION   ICON_MAX_SIZE   ICON_COMPRESSION_LEVEL
               ICON_QUALITY_LEVEL
               CACHE_PATH           CACHE_MODE      CACHE_PREFIX
               TEMPLATE_PATH
               ICONS_PREFIX         MIME_PREFIX     ARCHIVE_PREFIX);
    return 1;
}

=head2 _make_title $url

Make title from url

=cut

sub _make_title($)
{
    my ($url) = @_;
    my @tpath =  File::Spec->splitdir( $url );
    @tpath = grep {$_} @tpath;
    push @tpath, '/' unless @tpath;
    return 'Gallery - ' . join ' : ', @tpath;
}

sub _get_index_top($) {
    my ($url) = @_;

    return
        $mt->render(
            _template('top'),
            path    => $CONFIG{TEMPLATE_PATH},
            title   =>  _make_title( $url ),
            size    => $CONFIG{ICON_MAX_DIMENSION},
            favicon => {
                icon => {
                    href => _escape_url( $CONFIG{ICONS_PREFIX}, ICON_FAVICON ),
                },
            },
        );
}

sub _get_index_updir($) {
    my ($url) = @_;

    # Add updir for non root directory
    return '' if $url eq '/';

    # make link on updir
    my @updir = File::Spec->splitdir( $url );
    pop @updir;
    my $href = _escape_url( File::Spec->catdir( @updir ) );

    # Send updir icon
    my %item = (
        path        => File::Spec->updir,
        filename    => File::Spec->updir,
        href        => $href,
        icon        => {
            href    => _escape_url( $CONFIG{ICONS_PREFIX}, ICON_UPDIR ),
        },
        class       => 'updir',
    );

    return $mt->render( _template('item'), item => \%item );
}

sub _get_index_archive($) {
    my ($url) = @_;

    my @dir = File::Spec->splitdir( $url );
    my $filename = $dir[-1] || 'AllGallery';
    $filename .= '.tar.bz';
    my $href = _escape_url(
        $CONFIG{ARCHIVE_PREFIX},
        File::Spec->catfile( @dir, $filename )
    );

     # Send updir icon
    my %item = (
        path        => $filename,
        filename    => $filename,
        href        => $href,
        icon        => {
            href    => _escape_url( $CONFIG{ICONS_PREFIX}, ICON_ARCHIVE ),
        },
        class       => 'archive',
    );

    return $mt->render( _template('item'), item => \%item );
}

sub _get_index_item($$) {
    my ($url, $path) = @_;

    # Get filename
    my ($filename, $dir) = File::Basename::fileparse($path);
    my ($digit, $letter, $bytes, $human) = _as_human_size( -s $path );
    my $mime = $mimetypes->mimeTypeOf( $path ) || $mime_unknown;

    my @href = File::Spec->splitdir( $url );
    my $href = _escape_url( File::Spec->catfile( @href, $filename ) );

    # Make item info hash
    my %item = (
        path        => $path,
        filename    => $filename,
        href        => $href,
        size        => $human,
        mime        => $mime,
    );

    # For folders get standart icon
    if( -d _ )
    {
        $item{icon}{href} = _escape_url($CONFIG{ICONS_PREFIX}, ICON_FOLDER);

        # Remove directory fails
        delete $item{size};
        delete $item{mime};
    }
    # For images make icons and get some information
    elsif( $mime->mediaType eq 'image' or $mime->mediaType eq 'video' )
    {
        # Load icon from cache
        my $icon = get_icon_form_cache( $path, $url );
        # Try to make icon
        $icon = update_icon_in_cache( $path, $url, $mime ) unless $icon;
        # Make mime image icon
        $icon = _icon_mime( $path ) unless $icon;

        # Save icon and some image information
        $item{icon} = $icon;
        $item{image}{width}     = $icon->{orig}{width}
            if defined $icon->{orig}{width};
        $item{image}{height}    = $icon->{orig}{height}
            if defined $icon->{orig}{height};
    }
    # Show mime icon for file
    else
    {
        # Load mime icon
        $item{icon} = _icon_mime( $path );
    }

    return $mt->render( _template('item'), item => \%item );
}

sub _get_index_bottom() {
    return $mt->render( _template('bottom') )
}

1;

=head1 AUTHORS

Copyright (C) 2012 Dmitry E. Oboukhov <unera@debian.org>,

Copyright (C) 2012 Roman V. Nikolaev <rshadow@rambler.ru>

=head1 LICENSE

This program is free software: you can redistribute  it  and/or  modify  it
under the terms of the GNU General Public License as published by the  Free
Software Foundation, either version 3 of the License, or (at  your  option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even  the  implied  warranty  of  MERCHANTABILITY  or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public  License  for
more details.

You should have received a copy of the GNU  General  Public  License  along
with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
