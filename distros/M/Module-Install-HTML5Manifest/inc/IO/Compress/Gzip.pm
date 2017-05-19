#line 1

package IO::Compress::Gzip ;

require 5.004 ;

use strict ;
use warnings;
use bytes;


use IO::Compress::RawDeflate 2.030 ;

use Compress::Raw::Zlib  2.030 ;
use IO::Compress::Base::Common  2.030 qw(:Status :Parse createSelfTiedObject);
use IO::Compress::Gzip::Constants 2.030 ;
use IO::Compress::Zlib::Extra 2.030 ;

BEGIN
{
    if (defined &utf8::downgrade ) 
      { *noUTF8 = \&utf8::downgrade }
    else
      { *noUTF8 = sub {} }  
}

require Exporter ;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS, $GzipError);

$VERSION = '2.030';
$GzipError = '' ;

@ISA    = qw(Exporter IO::Compress::RawDeflate);
@EXPORT_OK = qw( $GzipError gzip ) ;
%EXPORT_TAGS = %IO::Compress::RawDeflate::DEFLATE_CONSTANTS ;
push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
Exporter::export_ok_tags('all');

sub new
{
    my $class = shift ;

    my $obj = createSelfTiedObject($class, \$GzipError);

    $obj->_create(undef, @_);
}


sub gzip
{
    my $obj = createSelfTiedObject(undef, \$GzipError);
    return $obj->_def(@_);
}

#sub newHeader
#{
#    my $self = shift ;
#    #return GZIP_MINIMUM_HEADER ;
#    return $self->mkHeader(*$self->{Got});
#}

sub getExtraParams
{
    my $self = shift ;

    return (
            # zlib behaviour
            $self->getZlibParams(),

            # Gzip header fields
            'Minimal'   => [0, 1, Parse_boolean,   0],
            'Comment'   => [0, 1, Parse_any,       undef],
            'Name'      => [0, 1, Parse_any,       undef],
            'Time'      => [0, 1, Parse_any,       undef],
            'TextFlag'  => [0, 1, Parse_boolean,   0],
            'HeaderCRC' => [0, 1, Parse_boolean,   0],
            'OS_Code'   => [0, 1, Parse_unsigned,  $Compress::Raw::Zlib::gzip_os_code],
            'ExtraField'=> [0, 1, Parse_any,       undef],
            'ExtraFlags'=> [0, 1, Parse_any,       undef],

        );
}


sub ckParams
{
    my $self = shift ;
    my $got = shift ;

    # gzip always needs crc32
    $got->value('CRC32' => 1);

    return 1
        if $got->value('Merge') ;

    my $strict = $got->value('Strict') ;


    {
        if (! $got->parsed('Time') ) {
            # Modification time defaults to now.
            $got->value('Time' => time) ;
        }

        # Check that the Name & Comment don't have embedded NULLs
        # Also check that they only contain ISO 8859-1 chars.
        if ($got->parsed('Name') && defined $got->value('Name')) {
            my $name = $got->value('Name');
                
            return $self->saveErrorString(undef, "Null Character found in Name",
                                                Z_DATA_ERROR)
                if $strict && $name =~ /\x00/ ;

            return $self->saveErrorString(undef, "Non ISO 8859-1 Character found in Name",
                                                Z_DATA_ERROR)
                if $strict && $name =~ /$GZIP_FNAME_INVALID_CHAR_RE/o ;
        }

        if ($got->parsed('Comment') && defined $got->value('Comment')) {
            my $comment = $got->value('Comment');

            return $self->saveErrorString(undef, "Null Character found in Comment",
                                                Z_DATA_ERROR)
                if $strict && $comment =~ /\x00/ ;

            return $self->saveErrorString(undef, "Non ISO 8859-1 Character found in Comment",
                                                Z_DATA_ERROR)
                if $strict && $comment =~ /$GZIP_FCOMMENT_INVALID_CHAR_RE/o;
        }

        if ($got->parsed('OS_Code') ) {
            my $value = $got->value('OS_Code');

            return $self->saveErrorString(undef, "OS_Code must be between 0 and 255, got '$value'")
                if $value < 0 || $value > 255 ;
            
        }

        # gzip only supports Deflate at present
        $got->value('Method' => Z_DEFLATED) ;

        if ( ! $got->parsed('ExtraFlags')) {
            $got->value('ExtraFlags' => 2) 
                if $got->value('Level') == Z_BEST_SPEED ;
            $got->value('ExtraFlags' => 4) 
                if $got->value('Level') == Z_BEST_COMPRESSION ;
        }

        my $data = $got->value('ExtraField') ;
        if (defined $data) {
            my $bad = IO::Compress::Zlib::Extra::parseExtraField($data, $strict, 1) ;
            return $self->saveErrorString(undef, "Error with ExtraField Parameter: $bad", Z_DATA_ERROR)
                if $bad ;

            $got->value('ExtraField', $data) ;
        }
    }

    return 1;
}

sub mkTrailer
{
    my $self = shift ;
    return pack("V V", *$self->{Compress}->crc32(), 
                       *$self->{UnCompSize}->get32bit());
}

sub getInverseClass
{
    return ('IO::Uncompress::Gunzip',
                \$IO::Uncompress::Gunzip::GunzipError);
}

sub getFileInfo
{
    my $self = shift ;
    my $params = shift;
    my $filename = shift ;

    my $defaultTime = (stat($filename))[9] ;

    $params->value('Name' => $filename)
        if ! $params->parsed('Name') ;

    $params->value('Time' => $defaultTime) 
        if ! $params->parsed('Time') ;
}


sub mkHeader
{
    my $self = shift ;
    my $param = shift ;

    # stort-circuit if a minimal header is requested.
    return GZIP_MINIMUM_HEADER if $param->value('Minimal') ;

    # METHOD
    my $method = $param->valueOrDefault('Method', GZIP_CM_DEFLATED) ;

    # FLAGS
    my $flags       = GZIP_FLG_DEFAULT ;
    $flags |= GZIP_FLG_FTEXT    if $param->value('TextFlag') ;
    $flags |= GZIP_FLG_FHCRC    if $param->value('HeaderCRC') ;
    $flags |= GZIP_FLG_FEXTRA   if $param->wantValue('ExtraField') ;
    $flags |= GZIP_FLG_FNAME    if $param->wantValue('Name') ;
    $flags |= GZIP_FLG_FCOMMENT if $param->wantValue('Comment') ;
    
    # MTIME
    my $time = $param->valueOrDefault('Time', GZIP_MTIME_DEFAULT) ;

    # EXTRA FLAGS
    my $extra_flags = $param->valueOrDefault('ExtraFlags', GZIP_XFL_DEFAULT);

    # OS CODE
    my $os_code = $param->valueOrDefault('OS_Code', GZIP_OS_DEFAULT) ;


    my $out = pack("C4 V C C", 
            GZIP_ID1,   # ID1
            GZIP_ID2,   # ID2
            $method,    # Compression Method
            $flags,     # Flags
            $time,      # Modification Time
            $extra_flags, # Extra Flags
            $os_code,   # Operating System Code
            ) ;

    # EXTRA
    if ($flags & GZIP_FLG_FEXTRA) {
        my $extra = $param->value('ExtraField') ;
        $out .= pack("v", length $extra) . $extra ;
    }

    # NAME
    if ($flags & GZIP_FLG_FNAME) {
        my $name .= $param->value('Name') ;
        $name =~ s/\x00.*$//;
        $out .= $name ;
        # Terminate the filename with NULL unless it already is
        $out .= GZIP_NULL_BYTE 
            if !length $name or
               substr($name, 1, -1) ne GZIP_NULL_BYTE ;
    }

    # COMMENT
    if ($flags & GZIP_FLG_FCOMMENT) {
        my $comment .= $param->value('Comment') ;
        $comment =~ s/\x00.*$//;
        $out .= $comment ;
        # Terminate the comment with NULL unless it already is
        $out .= GZIP_NULL_BYTE
            if ! length $comment or
               substr($comment, 1, -1) ne GZIP_NULL_BYTE;
    }

    # HEADER CRC
    $out .= pack("v", crc32($out) & 0x00FF ) if $param->value('HeaderCRC') ;

    noUTF8($out);

    return $out ;
}

sub mkFinalTrailer
{
    return '';
}

1; 

__END__

