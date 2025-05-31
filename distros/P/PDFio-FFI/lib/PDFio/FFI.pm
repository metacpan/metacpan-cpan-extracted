package PDFio::FFI;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';
use FFI::CheckLib      qw( find_lib_or_die );
use FFI::Platypus;


my $ffi = FFI::Platypus->new(
    api => 2,
    lib => find_lib_or_die( lib => 'pdfio', alien => 'Alien::PDFio' ),
);

$ffi->mangler(sub {
  my($symbol) = @_;
  return "pdfio" . ucfirst($symbol);
});

$ffi->type( 'object(PDFio::FFI::File)' => 'pdfio_file_t' );
$ffi->type( 'object(PDFio::FFI::Array)' => 'pdfio_array_t' );
$ffi->type( 'object(PDFio::FFI::Dict)' => 'pdfio_dict_t' );
$ffi->type( 'object(PDFio::FFI::Stream)' => 'pdfio_stream_t' );
$ffi->type( 'object(PDFio::FFI::Object)' => 'pdfio_obj_t' );
$ffi->type( 'object(PDFio::FFI::Rect)' => 'pdfio_rect_t' );
$ffi->type( 'object(PDFio::FFI::Encryption)' => 'pdfio_encryption_t' );

my %functions = (
    fileCreate => [ 
        ['string', 'string', 'pdfio_rect_t', 'pdfio_rect_t', 'opaque', 'opaque'] => 'pdfio_file_t'
    ],
    fileClose => [
        ['pdfio_file_t'] => 'bool'
    ],
    fileCreatePage => [
        ['pdfio_file_t', 'pdfio_dict_t'] => 'pdfio_stream_t'
    ],
    arrayAppendArray => [
        ['pdfio_array_t', 'pdfio_array_t'] => 'bool'
    ],
    arrayAppendBinary => [
        ['pdfio_array_t', 'opaque', 'size_t'] => 'bool'
    ],
    arrayAppendBoolean => [
        ['pdfio_array_t', 'bool'] => 'bool'
    ],
    arrayAppendDate => [
        ['pdfio_array_t', 'time_t'] => 'bool'
    ],
    arrayAppendDict => [
        ['pdfio_array_t', 'pdfio_dict_t'] => 'bool'
    ],
    arrayAppendName => [
        ['pdfio_array_t', 'string'] => 'bool'
    ],
    arrayAppendNumber => [
        ['pdfio_array_t', 'double'] => 'bool'
    ],
    arrayAppendObj => [
        ['pdfio_array_t', 'pdfio_obj_t'] => 'bool'
    ],
    arrayAppendString => [
        ['pdfio_array_t', 'string'] => 'bool'
    ],
    arrayCopy => [
        ['pdfio_file_t', 'pdfio_array_t'] => 'pdfio_array_t'
    ],
    arrayCreate => [
        ['pdfio_file_t'] => 'pdfio_array_t'
    ],
    arrayGetArray => [
        ['pdfio_array_t', 'size_t'] => 'pdfio_array_t'
    ],
    arrayGetBinary => [
        ['pdfio_array_t', 'size_t', 'opaque'] => 'opaque'
    ],
    arrayGetBoolean => [
        ['pdfio_array_t', 'size_t'] => 'bool'
    ],
    arrayGetDate => [
        ['pdfio_array_t', 'size_t'] => 'time_t'
    ],
    arrayGetDict => [
        ['pdfio_array_t', 'size_t'] => 'pdfio_dict_t'
    ],
    arrayGetName => [
        ['pdfio_array_t', 'size_t'] => 'string'
    ],
    arrayGetNumber => [
        ['pdfio_array_t', 'size_t'] => 'double'
    ],
    arrayGetObj => [
        ['pdfio_array_t', 'size_t'] => 'pdfio_obj_t'
    ],
    arrayGetSize => [
        ['pdfio_array_t'] => 'size_t'
    ],
    arrayGetString => [
        ['pdfio_array_t', 'size_t'] => 'string'
    ],
    arrayGetType => [
        ['pdfio_array_t', 'size_t'] => 'int'
    ],
    arrayRemove => [
        ['pdfio_array_t', 'size_t'] => 'bool'
    ],
    dictClear => [
        ['pdfio_dict_t', 'string'] => 'bool'
    ],
    dictCopy => [
        ['pdfio_file_t', 'pdfio_dict_t'] => 'pdfio_dict_t'
    ],
    dictCreate => [
        ['pdfio_file_t'] => 'pdfio_dict_t'
    ],
    dictGetArray => [
        ['pdfio_dict_t', 'string'] => 'pdfio_array_t'
    ],
    dictGetBinary => [
        ['pdfio_dict_t', 'string', 'opaque'] => 'opaque'
    ],
    dictGetBoolean => [
        ['pdfio_dict_t', 'string'] => 'bool'
    ],
    dictGetDate => [
        ['pdfio_dict_t', 'string'] => 'time_t'
    ],
    dictGetDict => [
        ['pdfio_dict_t', 'string'] => 'pdfio_dict_t'
    ],
    dictGetKey => [
        ['pdfio_dict_t', 'size_t'] => 'string'
    ],
    dictGetName => [
        ['pdfio_dict_t', 'string'] => 'string'
    ],
    dictGetNumPairs => [
        ['pdfio_dict_t'] => 'size_t'
    ],
    dictGetNumber => [
        ['pdfio_dict_t', 'string'] => 'double'
    ],
    dictGetObj => [
        ['pdfio_dict_t', 'string'] => 'pdfio_obj_t'
    ],
    dictGetRect => [
        ['pdfio_dict_t', 'string', 'pdfio_rect_t'] => 'pdfio_rect_t'
    ],
    dictGetString => [
        ['pdfio_dict_t', 'string'] => 'string'
    ],
    dictGetType => [
        ['pdfio_dict_t', 'string'] => 'int'
    ],
    # dictIterateKeys
    dictSetArray => [
        ['pdfio_dict_t', 'string', 'pdfio_array_t'] => 'bool'
    ],
    dictSetBinary => [
        ['pdfio_dict_t', 'string', 'opaque', 'size_t'] => 'bool'
    ],
    dictSetBoolean => [
        ['pdfio_dict_t', 'string', 'bool'] => 'bool'
    ],
    dictSetDate => [
        ['pdfio_dict_t', 'string', 'time_t'] => 'bool'
    ],
    dictSetDict => [
        ['pdfio_dict_t', 'string', 'pdfio_dict_t'] => 'bool'
    ],
    dictSetName => [
        ['pdfio_dict_t', 'string', 'string'] => 'bool'
    ],
    dictSetNull => [
        ['pdfio_dict_t', 'string'] => 'bool'
    ],
    dictSetNumber => [
        ['pdfio_dict_t', 'string', 'double'] => 'bool'
    ],
    dictSetObj => [
        ['pdfio_dict_t', 'string', 'pdfio_obj_t'] => 'bool'
    ],
    dictSetRect => [
        ['pdfio_dict_t', 'string', 'pdfio_rect_t'] => 'bool'
    ],
    dictSetString => [
        ['pdfio_dict_t', 'string', 'string'] => 'bool'
    ],
    # dictSetStringf
    fileCreateArrayObj => [
        ['pdfio_file_t', 'pdfio_array_t'] => 'pdfio_obj_t'
    ],
    fileCreateNameObj => [
        ['pdfio_file_t', 'string'] => 'pdfio_obj_t'
    ],
    fileCreateNumberObj => [
        ['pdfio_file_t', 'double'] => 'pdfio_obj_t'
    ],
    fileCreateObj => [
        ['pdfio_file_t', 'pdfio_dict_t'] => 'pdfio_obj_t'
    ],
    fileCreateOutput => [
        ['opaque', 'opaque', 'string', 'pdfio_rect_t', 'pdfio_rect_t', 'opaque', 'opaque'] => 'pdfio_file_t'
    ],
    fileCreatePage => [
        ['pdfio_file_t', 'pdfio_dict_t'] => 'pdfio_stream_t'
    ],
    fileCreateStringObj => [
        ['pdfio_file_t', 'string'] => 'pdfio_obj_t'
    ],
    fileCreateTemporary => [
        ['opaque', 'size_t', 'string', 'pdfio_rect_t', 'pdfio_rect_t', 'opaque', 'opaque'] => 'pdfio_file_t'
    ],
    fileFindObj => [
        ['pdfio_file_t', 'size_t'] => 'pdfio_obj_t'
    ],
    fileGetAuthor => [
        ['pdfio_file_t'] => 'string'
    ],
    fileGetCatalog => [
        ['pdfio_file_t'] => 'pdfio_dict_t'
    ],
    fileGetCreationDate => [
        ['pdfio_file_t'] => 'time_t'
    ],
    fileGetCreator => [
        ['pdfio_file_t'] => 'string'
    ],
    fileGetID => [
        ['pdfio_file_t'] => 'pdfio_array_t'
    ],
    fileGetKeywords => [
        ['pdfio_file_t'] => 'string'
    ],
    fileGetModificationDate => [
        ['pdfio_file_t'] => 'time_t'
    ],
    fileGetName => [
        ['pdfio_file_t'] => 'string'
    ],
    fileGetNumObjs => [
        ['pdfio_file_t'] => 'size_t'
    ],
    fileGetNumPages => [
        ['pdfio_file_t'] => 'size_t'
    ],
    fileGetObj => [
        ['pdfio_file_t', 'size_t'] => 'pdfio_obj_t'
    ],
    fileGetPage => [
        ['pdfio_file_t', 'size_t'] => 'pdfio_obj_t'
    ],
    fileGetPermissions => [
        ['pdfio_file_t', 'pdfio_encryption_t'] => 'int'
    ],
    fileGetProducer => [
        ['pdfio_file_t'] => 'string'
    ],
    fileGetSubject => [
        ['pdfio_file_t'] => 'string'
    ],
    fileGetTitle => [
        ['pdfio_file_t'] => 'string'
    ],
    fileGetVersion => [
        ['pdfio_file_t'] => 'string'
    ],
    fileOpen => [
        ['string', 'opaque', 'opaque', 'opaque', 'opaque'] => 'pdfio_file_t'
    ],
    fileSetAuthor => [
        ['pdfio_file_t', 'string'] => 'void'
    ],
    fileSetCreationDate => [
        ['pdfio_file_t', 'time_t'] => 'void'
    ],
    fileSetCreator => [
        ['pdfio_file_t', 'string'] => 'void'
    ],
    fileSetKeywords => [
        ['pdfio_file_t', 'string'] => 'void'
    ],
    fileSetModificationDate => [
        ['pdfio_file_t', 'time_t'] => 'void'
    ],
    fileSetPermissions => [
        ['pdfio_file_t', 'int', 'pdfio_encryption_t', 'string', 'string'] => 'bool'
    ],
    fileSetSubject => [
        ['pdfio_file_t', 'string'] => 'void'
    ],
    fileSetTitle => [
        ['pdfio_file_t', 'string'] => 'void'
    ],
    fileCreateFontObjFromBase => [
        ['pdfio_file_t', 'string'] => 'pdfio_obj_t'
    ],
    fileCreateFontObjFromFile => [
        ['pdfio_file_t', 'string', 'bool'] => 'pdfio_obj_t'
    ],
    fileCreateICCObjFromData => [
        ['pdfio_file_t', 'opaque', 'size_t', 'size_t'] => 'pdfio_obj_t'
    ],
    fileCreateICCObjFromFile => [
        ['pdfio_file_t', 'string', 'size_t'] => 'pdfio_obj_t'
    ],
    fileCreateImageObjFromData => [
        ['pdfio_file_t', 'opaque', 'size_t', 'size_t', 'size_t', 'pdfio_array_t', 'bool', 'bool'] => 'pdfio_obj_t'
    ],
    fileCreateImageObjFromFile => [
        ['pdfio_file_t', 'string', 'bool'] => 'pdfio_obj_t'
    ],
    imageGetBytesPerLine => [
        ['pdfio_obj_t'] => 'size_t'
    ],
    imageGetHeight => [
        ['pdfio_obj_t'] => 'double'
    ],
    imageGetWidth => [
        ['pdfio_obj_t'] => 'double'
    ],
    pageDictAddColorSpace => [
        ['pdfio_dict_t', 'string', 'pdfio_array_t'] => 'bool'
    ],
    pageDictAddFont => [
        ['pdfio_dict_t', 'string', 'pdfio_obj_t'] => 'bool'
    ],
    pageDictAddImage => [
        ['pdfio_dict_t', 'string', 'pdfio_obj_t'] => 'bool'
    ],
    arrayCreateColorFromICCObj => [
        ['pdfio_file_t', 'pdfio_obj_t'] => 'pdfio_array_t'
    ],
    arrayCreateColorFromMatrix => [
        ['pdfio_file_t', 'size_t', 'double', 'opaque', 'opaque'] => 'pdfio_array_t'
    ],
    arrayCreateColorFromPalette => [
        ['pdfio_file_t', 'size_t', 'opaque'] => 'pdfio_array_t'
    ],
    arrayCreateColorFromPrimaries => [
        ['pdfio_file_t', 'size_t', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'] => 'pdfio_array_t'
    ],
    arrayCreateColorFromStandard => [
        ['pdfio_file_t', 'size_t', 'int'] => 'pdfio_array_t'
    ],
    contentClip => [
        ['pdfio_stream_t', 'bool'] => 'bool'
    ],
    contentDrawImage => [
        ['pdfio_stream_t', 'string', 'double', 'double', 'double', 'double'] => 'bool'
    ],
    contentFill => [
        ['pdfio_stream_t', 'bool'] => 'bool'
    ],
    contentFillAndStroke => [
        ['pdfio_stream_t', 'bool'] => 'bool'
    ],
    contentMatrixConcat => [
        ['pdfio_stream_t', 'opaque'] => 'bool'
    ],
    contentMatrixRotate => [
        ['pdfio_stream_t', 'double'] => 'bool'
    ],
    contentMatrixScale => [
        ['pdfio_stream_t', 'double', 'double'] => 'bool'
    ],
    contentMatrixTranslate => [
        ['pdfio_stream_t', 'double', 'double'] => 'bool'
    ],
    contentPathClose => [
        ['pdfio_stream_t'] => 'bool'
    ],
    contentPathCurve => [
        ['pdfio_stream_t', 'double', 'double', 'double', 'double', 'double', 'double'] => 'bool'
    ],
    contentPathCurve13 => [
        ['pdfio_stream_t', 'double', 'double', 'double', 'double'] => 'bool'
    ],
    contentPathCurve23 => [
        ['pdfio_stream_t', 'double', 'double', 'double', 'double'] => 'bool'
    ],
    contentPathEnd => [
        ['pdfio_stream_t'] => 'bool'
    ],
    contentPathLineTo => [
        ['pdfio_stream_t', 'double', 'double'] => 'bool'
    ],
    contentPathMoveTo => [
        ['pdfio_stream_t', 'double', 'double'] => 'bool'
    ],
    contentPathRect => [
        ['pdfio_stream_t', 'double', 'double', 'double', 'double'] => 'bool'
    ],
    contentRestore => [
        ['pdfio_stream_t'] => 'bool'
    ],
    contentSave => [
        ['pdfio_stream_t'] => 'bool'
    ],
    contentSetDashPattern => [
        ['pdfio_stream_t', 'double', 'double', 'double'] => 'bool'
    ],
    contentSetFillColorDeviceCMYK => [
        ['pdfio_stream_t', 'double', 'double', 'double', 'double'] => 'bool'
    ],
    contentSetFillColorDeviceGray => [
        ['pdfio_stream_t', 'double'] => 'bool'
    ],
    contentSetFillColorDeviceRGB => [
        ['pdfio_stream_t', 'double', 'double', 'double'] => 'bool'
    ],
    contentSetFillColorGray => [
        ['pdfio_stream_t', 'double'] => 'bool'
    ],
    contentSetFillColorRGB => [
        ['pdfio_stream_t', 'double', 'double', 'double'] => 'bool'
    ],
    contentSetFillColorSpace => [
        ['pdfio_stream_t', 'string'] => 'bool'
    ],
    contentSetFlatness => [
        ['pdfio_stream_t', 'double'] => 'bool'
    ],
    contentSetLineCap => [
        ['pdfio_stream_t', 'int'] => 'bool'
    ],
    contentSetLineJoin => [
        ['pdfio_stream_t', 'int'] => 'bool'
    ],
    contentSetLineWidth => [
        ['pdfio_stream_t', 'double'] => 'bool'
    ],
    contentSetMiterLimit => [
        ['pdfio_stream_t', 'double'] => 'bool'
    ],
    contentSetStrokeColorDeviceCMYK => [
        ['pdfio_stream_t', 'double', 'double', 'double', 'double'] => 'bool'
    ],
    contentSetStrokeColorDeviceGray => [
        ['pdfio_stream_t', 'double'] => 'bool'
    ],
    contentSetStrokeColorDeviceRGB => [
        ['pdfio_stream_t', 'double', 'double', 'double'] => 'bool'
    ],
    contentSetStrokeColorGray => [
        ['pdfio_stream_t', 'double'] => 'bool'
    ],
    contentSetStrokeColorRGB => [
        ['pdfio_stream_t', 'double', 'double', 'double'] => 'bool'
    ],
    contentSetStrokeColorSpace => [
        ['pdfio_stream_t', 'string'] => 'bool'
    ],
    contentSetTextCharacterSpacing => [
        ['pdfio_stream_t', 'double'] => 'bool'
    ],
    contentSetTextFont => [
        ['pdfio_stream_t', 'string', 'double'] => 'bool'
    ],
    contentSetTextLeading => [
        ['pdfio_stream_t', 'double'] => 'bool'
    ],
    contentSetTextMatrix => [
        ['pdfio_stream_t', 'opaque'] => 'bool'
    ],
    contentSetTextRenderingMode => [
        ['pdfio_stream_t', 'int'] => 'bool'
    ],
    contentSetTextRise => [
        ['pdfio_stream_t', 'double'] => 'bool'
    ],
    contentSetTextWordSpacing => [
        ['pdfio_stream_t', 'double'] => 'bool'
    ],
    contentSetTextXScaling => [
        ['pdfio_stream_t', 'double'] => 'bool'
    ],
    contentStroke => [
        ['pdfio_stream_t'] => 'bool'
    ],
    contentTextBegin => [
        ['pdfio_stream_t'] => 'bool'
    ],
    contentTextEnd => [
        ['pdfio_stream_t'] => 'bool'
    ],
    contentTextMeasure => [
        ['pdfio_obj_t', 'string', 'double'] => 'double'
    ],
    contentTextMoveLine => [
        ['pdfio_stream_t', 'double', 'double'] => 'bool'
    ],
    contentTextMoveTo => [
        ['pdfio_stream_t', 'double', 'double'] => 'bool'
    ],
    contentTextNewLine => [
        ['pdfio_stream_t'] => 'bool'
    ],
    contentTextNewLineShow => [
        ['pdfio_stream_t', 'double', 'double', 'bool', 'string'] => 'bool'
    ],
    contentTextNextLine => [
        ['pdfio_stream_t'] => 'bool'
    ],
    contentTextShow => [
        ['pdfio_stream_t', 'bool', 'string'] => 'bool'
    ],
    contentTextShowJustified => [
        ['pdfio_stream_t', 'bool', 'size_t', 'opaque', 'opaque'] => 'bool'
    ],
    objClose => [
        ['pdfio_obj_t'] => 'bool'
    ],
    objCopy => [
        ['pdfio_file_t', 'pdfio_obj_t'] => 'pdfio_obj_t'
    ],
    objCreateStream => [
        ['pdfio_obj_t', 'int'] => 'pdfio_stream_t'
    ],
    objGetArray => [
        ['pdfio_obj_t'] => 'pdfio_array_t'
    ],
    objGetDict => [
        ['pdfio_obj_t'] => 'pdfio_dict_t'
    ],
    objGetGeneration => [
        ['pdfio_obj_t'] => 'ushort'
    ],
    objGetLength => [
        ['pdfio_obj_t'] => 'size_t'
    ],
    objGetName => [
        ['pdfio_obj_t'] => 'string'
    ],
    objGetNumber => [
        ['pdfio_obj_t'] => 'size_t'
    ],
    objGetSubtype => [
        ['pdfio_obj_t'] => 'string'
    ],
    objGetType => [
        ['pdfio_obj_t'] => 'string'
    ],
    objOpenStream => [
        ['pdfio_obj_t', 'bool'] => 'pdfio_stream_t'
    ],
    pageCopy => [
        ['pdfio_file_t', 'pdfio_obj_t'] => 'bool'
    ],
    pageGetNumStreams => [
        ['pdfio_obj_t'] => 'size_t'
    ],
    pageOpenStream => [
        ['pdfio_obj_t', 'size_t', 'bool'] => 'pdfio_stream_t'
    ],
    streamClose => [
        ['pdfio_stream_t'] => 'bool'
    ],
    streamConsume => [
        ['pdfio_stream_t', 'size_t'] => 'bool'
    ],
    streamGetToken => [
        ['pdfio_stream_t', 'opaque', 'size_t'] => 'bool'
    ],
    streamPeek => [
        ['pdfio_stream_t', 'opaque', 'size_t'] => 'ssize_t'
    ],
    streamPutChar => [
        ['pdfio_stream_t', 'int'] => 'bool'
    ],
    streamPuts => [
        ['pdfio_stream_t', 'string'] => 'bool'
    ],
    streamRead => [
        ['pdfio_stream_t', 'opaque', 'size_t'] => 'ssize_t'
    ],
    streamWrite => [
        ['pdfio_stream_t', 'opaque', 'size_t'] => 'bool'
    ],
    stringCreate => [
        ['pdfio_file_t', 'string'] => 'string'
    ],
);


for my $name (keys %functions) {
    my $args = $functions{$name};
    $ffi->attach( $name => @$args );
}

# export all the functions lexically
sub import {
    my $class = shift;
    my $caller = caller();
    my @export = scalar @_ ? @_ : keys %functions;
    for my $key (@export) {
        no strict 'refs';
        *{"${caller}::$key"} = $class->can($key);
    }
}

1;

package PDFio::FFI::Rect;

sub new { bless $_[1], $_[0] }

1;

package PDFio::FFI::Array;

sub new { bless $_[1], $_[0] }

1;

package PDFio::FFI::Dict;

sub new { bless $_[1], $_[0] }

1;

package PDFio::FFI::Stream;

sub new { bless $_[1], $_[0] }

1;

package PDFio::FFI::Object;

sub new { bless $_[1], $_[0] }

1;

package PDFio::FFI::Encryption;

sub new { bless $_[1], $_[0] }

1;

1;

__END__

=head1 NAME

PDFio::FFI - Perl FFI bindings for the PDFio C library

=head1 VERSION

Version 0.01

=cut

    use PDFio::FFI;

    my $pdf = fileCreate(
        "myoutputfile.pdf",
        "2.0",
        PDFio::FFI::Rect->new([0.0, 0.0, 612.0, 792.0]),
        PDFio::FFI::Rect->new([36.0, 36.0, 576.0, 756.0])
    );

    my $font = fileCreateFontObjFromBase($pdf, "Courier");

    my $dict = dictCreate($pdf);
    pageDictAddFont($dict, "F1", $font);

    my $page = fileCreatePage($pdf, $dict);
    contentTextBegin($page);
    contentSetTextFont($page, "F1", 12); 
    contentTextMoveTo($page, 100, 700);
    contentTextShow($page, 1, "Hello, World!");
    contentTextEnd($page);
    streamClose($page);
    fileClose($pdf);

=head1 SYNOPSIS

=head1 DESCRIPTION

C<PDFio::FFI> provides Perl bindings to the PDFio C library using L<FFI::Platypus>.  
It allows you to read, write, and manipulate PDF files from Perl by exposing the PDFio API.

=head1 EXPORT

=head1 FUNCTIONS

The following functions are exported by default.  
Each function maps directly to a PDFio C API call.

=over 4

=head2 fileCreate

Creates a new PDF file for writing.

  fileCreate($filename, $version, $media_box, $crop_box, $error_cb, $error_data) -> pdfio_file_t

=head2 fileClose

Closes a PDF file and frees resources.

  fileClose($file) -> bool

=head2 fileCreatePage

Creates a new page in the PDF file.

  fileCreatePage($file, $dict) -> pdfio_stream_t

=head2 arrayAppendArray

Appends an array to a PDF array.

  arrayAppendArray($array, $value) -> bool

=head2 arrayAppendBinary

Appends binary data to a PDF array.

  arrayAppendBinary($array, $data, $size) -> bool

=head2 arrayAppendBoolean

Appends a boolean value to a PDF array.

  arrayAppendBoolean($array, $bool) -> bool

=head2 arrayAppendDate

Appends a date value to a PDF array.

  arrayAppendDate($array, $time_t) -> bool

=head2 arrayAppendDict

Appends a dictionary to a PDF array.

  arrayAppendDict($array, $dict) -> bool

=head2 arrayAppendName

Appends a name to a PDF array.

  arrayAppendName($array, $name) -> bool

=head2 arrayAppendNumber

Appends a number to a PDF array.

  arrayAppendNumber($array, $number) -> bool

=head2 arrayAppendObj

Appends an object to a PDF array.

  arrayAppendObj($array, $obj) -> bool

=head2 arrayAppendString

Appends a string to a PDF array.

  arrayAppendString($array, $string) -> bool

=head2 arrayCopy

Copies a PDF array.

  arrayCopy($file, $array) -> pdfio_array_t

=head2 arrayCreate

Creates a new PDF array.

  arrayCreate($file) -> pdfio_array_t

=head2 arrayGetArray

Gets an array element from a PDF array.

  arrayGetArray($array, $index) -> pdfio_array_t

=head2 arrayGetBinary

Gets binary data from a PDF array.

  arrayGetBinary($array, $index, $buffer) -> opaque

=head2 arrayGetBoolean

Gets a boolean value from a PDF array.

  arrayGetBoolean($array, $index) -> bool

=head2 arrayGetDate

Gets a date value from a PDF array.

  arrayGetDate($array, $index) -> time_t

=head2 arrayGetDict

Gets a dictionary from a PDF array.

  arrayGetDict($array, $index) -> pdfio_dict_t

=head2 arrayGetName

Gets a name from a PDF array.

  arrayGetName($array, $index) -> string

=head2 arrayGetNumber

Gets a number from a PDF array.

  arrayGetNumber($array, $index) -> double

=head2 arrayGetObj

Gets an object from a PDF array.

  arrayGetObj($array, $index) -> pdfio_obj_t

=head2 arrayGetSize

Gets the number of elements in a PDF array.

  arrayGetSize($array) -> size_t

=head2 arrayGetString

Gets a string from a PDF array.

  arrayGetString($array, $index) -> string

=head2 arrayGetType

Gets the type of an element in a PDF array.

  arrayGetType($array, $index) -> int

=head2 arrayRemove

Removes an element from a PDF array.

  arrayRemove($array, $index) -> bool

=head2 dictClear

Removes a key from a PDF dictionary.

  dictClear($dict, $key) -> bool

=head2 dictCopy

Copies a PDF dictionary.

  dictCopy($file, $dict) -> pdfio_dict_t

=head2 dictCreate

Creates a new PDF dictionary.

  dictCreate($file) -> pdfio_dict_t

=head2 dictGetArray

Gets an array from a PDF dictionary by key.

  dictGetArray($dict, $key) -> pdfio_array_t

=head2 dictGetBinary

Gets binary data from a PDF dictionary.

  dictGetBinary($dict, $key, $buffer) -> opaque

=head2 dictGetBoolean

Gets a boolean value from a PDF dictionary.

  dictGetBoolean($dict, $key) -> bool

=head2 dictGetDate

Gets a date value from a PDF dictionary.

  dictGetDate($dict, $key) -> time_t

=head2 dictGetDict

Gets a dictionary from a PDF dictionary.

  dictGetDict($dict, $key) -> pdfio_dict_t

=head2 dictGetKey

Gets a key from a PDF dictionary by index.

  dictGetKey($dict, $index) -> string

=head2 dictGetName

Gets a name from a PDF dictionary.

  dictGetName($dict, $key) -> string

=head2 dictGetNumPairs

Gets the number of key-value pairs in a PDF dictionary.

  dictGetNumPairs($dict) -> size_t

=head2 dictGetNumber

Gets a number from a PDF dictionary.

  dictGetNumber($dict, $key) -> double

=head2 dictGetObj

Gets an object from a PDF dictionary.

  dictGetObj($dict, $key) -> pdfio_obj_t

=head2 dictGetRect

Gets a rectangle from a PDF dictionary.

  dictGetRect($dict, $key, $rect) -> pdfio_rect_t

=head2 dictGetString

Gets a string from a PDF dictionary.

  dictGetString($dict, $key) -> string

=head2 dictGetType

Gets the type of a value in a PDF dictionary.

  dictGetType($dict, $key) -> int

=head2 dictSetArray

Sets an array value in a PDF dictionary.

  dictSetArray($dict, $key, $array) -> bool

=head2 dictSetBinary

Sets binary data in a PDF dictionary.

  dictSetBinary($dict, $key, $data, $size) -> bool

=head2 dictSetBoolean

Sets a boolean value in a PDF dictionary.

  dictSetBoolean($dict, $key, $bool) -> bool

=head2 dictSetDate

Sets a date value in a PDF dictionary.

  dictSetDate($dict, $key, $time_t) -> bool

=head2 dictSetDict

Sets a dictionary value in a PDF dictionary.

  dictSetDict($dict, $key, $dict2) -> bool

=head2 dictSetName

Sets a name value in a PDF dictionary.

  dictSetName($dict, $key, $name) -> bool

=head2 dictSetNull

Sets a null value in a PDF dictionary.

  dictSetNull($dict, $key) -> bool

=head2 dictSetNumber

Sets a number value in a PDF dictionary.

  dictSetNumber($dict, $key, $number) -> bool

=head2 dictSetObj

Sets an object value in a PDF dictionary.

  dictSetObj($dict, $key, $obj) -> bool

=head2 dictSetRect

Sets a rectangle value in a PDF dictionary.

  dictSetRect($dict, $key, $rect) -> bool

=head2 dictSetString

Sets a string value in a PDF dictionary.

  dictSetString($dict, $key, $string) -> bool

=head2 fileCreateArrayObj

Creates an array object in a PDF file.

  fileCreateArrayObj($file, $array) -> pdfio_obj_t

=head2 fileCreateNameObj

Creates a name object in a PDF file.

  fileCreateNameObj($file, $name) -> pdfio_obj_t

=head2 fileCreateNumberObj

Creates a number object in a PDF file.

  fileCreateNumberObj($file, $number) -> pdfio_obj_t

=head2 fileCreateObj

Creates an object in a PDF file.

  fileCreateObj($file, $dict) -> pdfio_obj_t

=head2 fileCreateOutput

Creates a PDF file with a custom output callback.

  fileCreateOutput($output_cb, $output_data, $version, $media_box, $crop_box, $error_cb, $error_data) -> pdfio_file_t

=head2 fileCreateStringObj

Creates a string object in a PDF file.

  fileCreateStringObj($file, $string) -> pdfio_obj_t

=head2 fileCreateTemporary

Creates a temporary PDF file.

  fileCreateTemporary($buffer, $bufsize, $version, $media_box, $crop_box, $error_cb, $error_data) -> pdfio_file_t

=head2 fileFindObj

Finds an object in a PDF file by number.

  fileFindObj($file, $number) -> pdfio_obj_t

=head2 fileGetAuthor

Gets the author metadata from a PDF file.

  fileGetAuthor($file) -> string

=head2 fileGetCatalog

Gets the catalog dictionary from a PDF file.

  fileGetCatalog($file) -> pdfio_dict_t

=head2 fileGetCreationDate

Gets the creation date from a PDF file.

  fileGetCreationDate($file) -> time_t

=head2 fileGetCreator

Gets the creator metadata from a PDF file.

  fileGetCreator($file) -> string

=head2 fileGetID

Gets the file ID array from a PDF file.

  fileGetID($file) -> pdfio_array_t

=head2 fileGetKeywords

Gets the keywords metadata from a PDF file.

  fileGetKeywords($file) -> string

=head2 fileGetModificationDate

Gets the modification date from a PDF file.

  fileGetModificationDate($file) -> time_t

=head2 fileGetName

Gets the file name.

  fileGetName($file) -> string

=head2 fileGetNumObjs

Gets the number of objects in a PDF file.

  fileGetNumObjs($file) -> size_t

=head2 fileGetNumPages

Gets the number of pages in a PDF file.

  fileGetNumPages($file) -> size_t

=head2 fileGetObj

Gets an object from a PDF file by number.

  fileGetObj($file, $number) -> pdfio_obj_t

=head2 fileGetPage

Gets a page object from a PDF file by index.

  fileGetPage($file, $index) -> pdfio_obj_t

=head2 fileGetPermissions

Gets permissions from a PDF file.

  fileGetPermissions($file, $encryption) -> int

=head2 fileGetProducer

Gets the producer metadata from a PDF file.

  fileGetProducer($file) -> string

=head2 fileGetSubject

Gets the subject metadata from a PDF file.

  fileGetSubject($file) -> string

=head2 fileGetTitle

Gets the title metadata from a PDF file.

  fileGetTitle($file) -> string

=head2 fileGetVersion

Gets the PDF version.

  fileGetVersion($file) -> string

=head2 fileOpen

Opens a PDF file for reading.

  fileOpen($filename, $password_cb, $password_data, $error_cb, $error_data) -> pdfio_file_t

=head2 fileSetAuthor

Sets the author metadata in a PDF file.

  fileSetAuthor($file, $author) -> void

=head2 fileSetCreationDate

Sets the creation date in a PDF file.

  fileSetCreationDate($file, $time_t) -> void

=head2 fileSetCreator

Sets the creator metadata in a PDF file.

  fileSetCreator($file, $creator) -> void

=head2 fileSetKeywords

Sets the keywords metadata in a PDF file.

  fileSetKeywords($file, $keywords) -> void

=head2 fileSetModificationDate

Sets the modification date in a PDF file.

  fileSetModificationDate($file, $time_t) -> void

=head2 fileSetPermissions

Sets permissions in a PDF file.

  fileSetPermissions($file, $permissions, $encryption, $owner_pass, $user_pass) -> bool

=head2 fileSetSubject

Sets the subject metadata in a PDF file.

  fileSetSubject($file, $subject) -> void

=head2 fileSetTitle

Sets the title metadata in a PDF file.

  fileSetTitle($file, $title) -> void

=head2 fileCreateFontObjFromBase

Creates a font object from a base font.

  fileCreateFontObjFromBase($file, $basefont) -> pdfio_obj_t

=head2 fileCreateFontObjFromFile

Creates a font object from a font file.

  fileCreateFontObjFromFile($file, $filename, $embed) -> pdfio_obj_t

=head2 fileCreateICCObjFromData

Creates an ICC object from data.

  fileCreateICCObjFromData($file, $data, $size, $ncomps) -> pdfio_obj_t

=head2 fileCreateICCObjFromFile

Creates an ICC object from a file.

  fileCreateICCObjFromFile($file, $filename, $ncomps) -> pdfio_obj_t

=head2 fileCreateImageObjFromData

Creates an image object from data.

  fileCreateImageObjFromData($file, $data, $width, $height, $bpc, $decode, $indexed, $mask) -> pdfio_obj_t

=head2 fileCreateImageObjFromFile

Creates an image object from a file.

  fileCreateImageObjFromFile($file, $filename, $mask) -> pdfio_obj_t

=head2 imageGetBytesPerLine

Gets the number of bytes per line in an image.

  imageGetBytesPerLine($obj) -> size_t

=head2 imageGetHeight

Gets the height of an image.

  imageGetHeight($obj) -> double

=head2 imageGetWidth

Gets the width of an image.

  imageGetWidth($obj) -> double

=head2 pageDictAddColorSpace

Adds a color space to a page dictionary.

  pageDictAddColorSpace($dict, $name, $array) -> bool

=head2 pageDictAddFont

Adds a font to a page dictionary.

  pageDictAddFont($dict, $name, $obj) -> bool

=head2 pageDictAddImage

Adds an image to a page dictionary.

  pageDictAddImage($dict, $name, $obj) -> bool

=head2 arrayCreateColorFromICCObj

Creates a color array from an ICC object.

  arrayCreateColorFromICCObj($file, $obj) -> pdfio_array_t

=head2 arrayCreateColorFromMatrix

Creates a color array from a matrix.

  arrayCreateColorFromMatrix($file, $n, $matrix, $decode, $range) -> pdfio_array_t

=head2 arrayCreateColorFromPalette

Creates a color array from a palette.

  arrayCreateColorFromPalette($file, $n, $palette) -> pdfio_array_t

=head2 arrayCreateColorFromPrimaries

Creates a color array from primaries.

  arrayCreateColorFromPrimaries($file, $n, $xr, $xg, $xb, $yr, $yg, $yb, $zr, $zg, $zb, $zw) -> pdfio_array_t

=head2 arrayCreateColorFromStandard

Creates a color array from a standard.

  arrayCreateColorFromStandard($file, $n, $standard) -> pdfio_array_t

=head2 contentClip

Sets the clipping path in a content stream.

  contentClip($stream, $even_odd) -> bool

=head2 contentDrawImage

Draws an image in a content stream.

  contentDrawImage($stream, $name, $x, $y, $width, $height) -> bool

=head2 contentFill

Fills the current path in a content stream.

  contentFill($stream, $even_odd) -> bool

=head2 contentFillAndStroke

Fills and strokes the current path in a content stream.

  contentFillAndStroke($stream, $even_odd) -> bool

=head2 contentMatrixConcat

Concatenates a matrix in a content stream.

  contentMatrixConcat($stream, $matrix) -> bool

=head2 contentMatrixRotate

Rotates the matrix in a content stream.

  contentMatrixRotate($stream, $angle) -> bool

=head2 contentMatrixScale

Scales the matrix in a content stream.

  contentMatrixScale($stream, $sx, $sy) -> bool

=head2 contentMatrixTranslate

Translates the matrix in a content stream.

  contentMatrixTranslate($stream, $tx, $ty) -> bool

=head2 contentPathClose

Closes the current path in a content stream.

  contentPathClose($stream) -> bool

=head2 contentPathCurve

Adds a curve to the current path in a content stream.

  contentPathCurve($stream, $x1, $y1, $x2, $y2, $x3, $y3) -> bool

=head2 contentPathCurve13

Adds a curve (variant 1-3) to the current path.

  contentPathCurve13($stream, $x1, $y1, $x3, $y3) -> bool

=head2 contentPathCurve23

Adds a curve (variant 2-3) to the current path.

  contentPathCurve23($stream, $x2, $y2, $x3, $y3) -> bool

=head2 contentPathEnd

Ends the current path in a content stream.

  contentPathEnd($stream) -> bool

=head2 contentPathLineTo

Adds a line to the current path.

  contentPathLineTo($stream, $x, $y) -> bool

=head2 contentPathMoveTo

Moves to a point in the current path.

  contentPathMoveTo($stream, $x, $y) -> bool

=head2 contentPathRect

Adds a rectangle to the current path.

  contentPathRect($stream, $x, $y, $width, $height) -> bool

=head2 contentRestore

Restores graphics state in a content stream.

  contentRestore($stream) -> bool

=head2 contentSave

Saves graphics state in a content stream.

  contentSave($stream) -> bool

=head2 contentSetDashPattern

Sets the dash pattern in a content stream.

  contentSetDashPattern($stream, $phase, $length, $gap) -> bool

=head2 contentSetFillColorDeviceCMYK

Sets fill color (DeviceCMYK) in a content stream.

  contentSetFillColorDeviceCMYK($stream, $c, $m, $y, $k) -> bool

=head2 contentSetFillColorDeviceGray

Sets fill color (DeviceGray) in a content stream.

  contentSetFillColorDeviceGray($stream, $gray) -> bool

=head2 contentSetFillColorDeviceRGB

Sets fill color (DeviceRGB) in a content stream.

  contentSetFillColorDeviceRGB($stream, $r, $g, $b) -> bool

=head2 contentSetFillColorGray

Sets fill color (Gray) in a content stream.

  contentSetFillColorGray($stream, $gray) -> bool

=head2 contentSetFillColorRGB

Sets fill color (RGB) in a content stream.

  contentSetFillColorRGB($stream, $r, $g, $b) -> bool

=head2 contentSetFillColorSpace

Sets fill color space in a content stream.

  contentSetFillColorSpace($stream, $name) -> bool

=head2 contentSetFlatness

Sets flatness in a content stream.

  contentSetFlatness($stream, $flatness) -> bool

=head2 contentSetLineCap

Sets line cap style in a content stream.

  contentSetLineCap($stream, $cap) -> bool

=head2 contentSetLineJoin

Sets line join style in a content stream.

  contentSetLineJoin($stream, $join) -> bool

=head2 contentSetLineWidth

Sets line width in a content stream.

  contentSetLineWidth($stream, $width) -> bool

=head2 contentSetMiterLimit

Sets miter limit in a content stream.

  contentSetMiterLimit($stream, $limit) -> bool

=head2 contentSetStrokeColorDeviceCMYK

Sets stroke color (DeviceCMYK) in a content stream.

  contentSetStrokeColorDeviceCMYK($stream, $c, $m, $y, $k) -> bool

=head2 contentSetStrokeColorDeviceGray

Sets stroke color (DeviceGray) in a content stream.

  contentSetStrokeColorDeviceGray($stream, $gray) -> bool

=head2 contentSetStrokeColorDeviceRGB

Sets stroke color (DeviceRGB) in a content stream.

  contentSetStrokeColorDeviceRGB($stream, $r, $g, $b) -> bool

=head2 contentSetStrokeColorGray

Sets stroke color (Gray) in a content stream.

  contentSetStrokeColorGray($stream, $gray) -> bool

=head2 contentSetStrokeColorRGB

Sets stroke color (RGB) in a content stream.

  contentSetStrokeColorRGB($stream, $r, $g, $b) -> bool

=head2 contentSetStrokeColorSpace

Sets stroke color space in a content stream.

  contentSetStrokeColorSpace($stream, $name) -> bool

=head2 contentSetTextCharacterSpacing

Sets text character spacing in a content stream.

  contentSetTextCharacterSpacing($stream, $spacing) -> bool

=head2 contentSetTextFont

Sets text font in a content stream.

  contentSetTextFont($stream, $font, $size) -> bool

=head2 contentSetTextLeading

Sets text leading in a content stream.

  contentSetTextLeading($stream, $leading) -> bool

=head2 contentSetTextMatrix

Sets text matrix in a content stream.

  contentSetTextMatrix($stream, $matrix) -> bool

=head2 contentSetTextRenderingMode

Sets text rendering mode in a content stream.

  contentSetTextRenderingMode($stream, $mode) -> bool

=head2 contentSetTextRise

Sets text rise in a content stream.

  contentSetTextRise($stream, $rise) -> bool

=head2 contentSetTextWordSpacing

Sets text word spacing in a content stream.

  contentSetTextWordSpacing($stream, $spacing) -> bool

=head2 contentSetTextXScaling

Sets text X scaling in a content stream.

  contentSetTextXScaling($stream, $scaling) -> bool

=head2 contentStroke

Strokes the current path in a content stream.

  contentStroke($stream) -> bool

=head2 contentTextBegin

Begins a text object in a content stream.

  contentTextBegin($stream) -> bool

=head2 contentTextEnd

Ends a text object in a content stream.

  contentTextEnd($stream) -> bool

=head2 contentTextMeasure

Measures text width in a content stream.

  contentTextMeasure($obj, $string, $size) -> double

=head2 contentTextMoveLine

Moves to the next line in a text object.

  contentTextMoveLine($stream, $dx, $dy) -> bool

=head2 contentTextMoveTo

Moves to a position in a text object.

  contentTextMoveTo($stream, $x, $y) -> bool

=head2 contentTextNewLine

Starts a new line in a text object.

  contentTextNewLine($stream) -> bool

=head2 contentTextNewLineShow

Shows text and starts a new line.

  contentTextNewLineShow($stream, $dx, $dy, $unicode, $string) -> bool

=head2 contentTextNextLine

Moves to the next line in a text object.

  contentTextNextLine($stream) -> bool

=head2 contentTextShow

Shows text in a text object.

  contentTextShow($stream, $unicode, $string) -> bool

=head2 contentTextShowJustified

Shows justified text in a text object.

  contentTextShowJustified($stream, $unicode, $count, $strings, $widths) -> bool

=head2 objClose

Closes a PDF object.

  objClose($obj) -> bool

=head2 objCopy

Copies a PDF object.

  objCopy($file, $obj) -> pdfio_obj_t

=head2 objCreateStream

Creates a stream in a PDF object.

  objCreateStream($obj, $compress) -> pdfio_stream_t

=head2 objGetArray

Gets an array from a PDF object.

  objGetArray($obj) -> pdfio_array_t

=head2 objGetDict

Gets a dictionary from a PDF object.

  objGetDict($obj) -> pdfio_dict_t

=head2 objGetGeneration

Gets the generation number of a PDF object.

  objGetGeneration($obj) -> ushort

=head2 objGetLength

Gets the length of a PDF object.

  objGetLength($obj) -> size_t

=head2 objGetName

Gets the name of a PDF object.

  objGetName($obj) -> string

=head2 objGetNumber

Gets the number of a PDF object.

  objGetNumber($obj) -> size_t

=head2 objGetSubtype

Gets the subtype of a PDF object.

  objGetSubtype($obj) -> string

=head2 objGetType

Gets the type of a PDF object.

  objGetType($obj) -> string

=head2 objOpenStream

Opens a stream from a PDF object.

  objOpenStream($obj, $decode) -> pdfio_stream_t

=head2 pageCopy

Copies a page in a PDF file.

  pageCopy($file, $obj) -> bool

=head2 pageGetNumStreams

Gets the number of streams in a page.

  pageGetNumStreams($obj) -> size_t

=head2 pageOpenStream

Opens a stream from a page.

  pageOpenStream($obj, $index, $decode) -> pdfio_stream_t

=head2 streamClose

Closes a PDF stream.

  streamClose($stream) -> bool

=head2 streamConsume

Consumes bytes from a PDF stream.

  streamConsume($stream, $count) -> bool

=head2 streamGetToken

Gets a token from a PDF stream.

  streamGetToken($stream, $buffer, $size) -> bool

=head2 streamPeek

Peeks at bytes in a PDF stream.

  streamPeek($stream, $buffer, $size) -> ssize_t

=head2 streamPutChar

Writes a character to a PDF stream.

  streamPutChar($stream, $char) -> bool

=head2 streamPuts

Writes a string to a PDF stream.

  streamPuts($stream, $string) -> bool

=head2 streamRead

Reads bytes from a PDF stream.

  streamRead($stream, $buffer, $size) -> ssize_t

=head2 streamWrite

Writes bytes to a PDF stream.

  streamWrite($stream, $buffer, $size) -> bool

=head2 stringCreate

Creates a PDF string object.

  stringCreate($file, $string) -> string

=back

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pdfio-ffi at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=PDFio-FFI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PDFio::FFI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=PDFio-FFI>

=item * Search CPAN

L<https://metacpan.org/release/PDFio-FFI>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of PDFio::FFI
