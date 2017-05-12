package Net::Azure::StorageClient::MIMEType;
use strict;
use warnings;
{
  $Net::Azure::StorageClient::MIMEType = '0.1';
}

sub new {
    my $class = shift;
    my $obj = bless {}, $class;
    $obj->init( @_ );
}

sub init {
    my $obj = shift;
    my %args = @_;
    $obj->{ default } = $args{ default } || 'application/octet-stream';
    return $obj;
}

sub get_mimetype {
    my $self = shift;
    my $filename = shift;
    my $default = shift;
    if ( ( ref $self ) ne 'Azure::StorageClient::MIMEType' ) {
        $default = $filename;
        $filename = $self;
    }
    my $mime_types = {
        'css'    => 'text/css',
        'html'   => 'text/html',
        'mtml'   => 'text/html',
        'xhtml'  => 'application/xhtml+xml',
        'htm'    => 'text/html',
        'txt'    => 'text/plain',
        'rtx'    => 'text/richtext',
        'tsv'    => 'text/tab-separated-values',
        'csv'    => 'text/csv',
        'hdml'   => 'text/x-hdml; charset=Shift_JIS',
        'xml'    => 'application/xml',
        'rdf'    => 'application/rss+xml',
        'xsl'    => 'text/xsl',
        'mpeg'   => 'video/mpeg',
        'mpg'    => 'video/mpeg',
        'mpe'    => 'video/mpeg',
        'qt'     => 'video/quicktime',
        'avi'    => 'video/x-msvideo',
        'movie'  => 'video/x-sgi-movie',
        'ice'    => 'x-conference/x-cooltalk',
        'svr'    => 'x-world/x-svr',
        'vrml'   => 'x-world/x-vrml',
        'wrl'    => 'x-world/x-vrml',
        'vrt'    => 'x-world/x-vrt',
        'spl'    => 'application/futuresplash',
        'hqx'    => 'application/mac-binhex40',
        'doc'    => 'application/msword',
        'pdf'    => 'application/pdf',
        'ai'     => 'application/postscript',
        'eps'    => 'application/postscript',
        'ps'     => 'application/postscript',
        'ppt'    => 'application/vnd.ms-powerpoint',
        'rtf'    => 'application/rtf',
        'dcr'    => 'application/x-director',
        'dir'    => 'application/x-director',
        'dxr'    => 'application/x-director',
        'js'     => 'application/javascript',
        'dvi'    => 'application/x-dvi',
        'gtar'   => 'application/x-gtar',
        'gzip'   => 'application/x-gzip',
        'latex'  => 'application/x-latex',
        'lzh'    => 'application/x-lha',
        'swf'    => 'application/x-shockwave-flash',
        'sit'    => 'application/x-stuffit',
        'tar'    => 'application/x-tar',
        'tcl'    => 'application/x-tcl',
        'tex'    => 'application/x-texinfo',
        'texinfo'=> 'application/x-texinfo',
        'texi'   => 'application/x-texi',
        'src'    => 'application/x-wais-source',
        'zip'    => 'application/zip',
        'au'     => 'audio/basic',
        'snd'    => 'audio/basic',
        'midi'   => 'audio/midi',
        'mid'    => 'audio/midi',
        'kar'    => 'audio/midi',
        'mpga'   => 'audio/mpeg',
        'mp2'    => 'audio/mpeg',
        'mp3'    => 'audio/mpeg',
        'ra'     => 'audio/x-pn-realaudio',
        'ram'    => 'audio/x-pn-realaudio',
        'rm'     => 'audio/x-pn-realaudio',
        'rpm'    => 'x-pn-realaudio-plugin',
        'wav'    => 'audio/x-wav',
        'bmp'    => 'image/bmp',
        'gif'    => 'image/gif',
        'jpeg'   => 'image/jpeg',
        'jpg'    => 'image/jpeg',
        'jpe'    => 'image/jpeg',
        'png'    => 'image/png',
        'tiff'   => 'image/tiff',
        'tif'    => 'image/tiff',
        'pnm'    => 'image/x-portable-anymap',
        'ras'    => 'image/x-cmu-raster',
        'pnm'    => 'image/x-portable-anymap',
        'pbm'    => 'image/x-portable-bitmap',
        'pgm'    => 'image/x-portable-graymap',
        'ppm'    => 'image/x-portable-pixmap',
        'rgb'    => 'image/x-rgb',
        'xbm'    => 'image/x-xbitmap',
        'xls'    => 'application/vnd.ms-excel',
        'xpm'    => 'image/x-pixmap',
        'xwd'    => 'image/x-xwindowdump',
        'ico'    => 'image/vnd.microsoft.icon',
        'docx'   => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'pptx'   => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'xlsx'   => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'json'   => 'application/json',
    };
    if ( $filename =~ /\.([^.]+)\z/ ) {
        my $extension = lc( $1 );
        if ( $extension && $mime_types->{ $extension } ) {
            return $mime_types->{ $extension };
        }
    }
    if (! $default ) {
        if ( ( ref $self ) eq 'Azure::StorageClient::MIMEType' ) {
            $default = $self->{ default };
        }
    }
    $default = 'application/octet-stream' unless $default;
    return $default;
}

1;