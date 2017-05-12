package Parse::Liberty::Constants;

use strict;
use warnings;

use Exporter 'import';
our $VERSION    = 0.13;
our @EXPORT     = qw();
our @EXPORT_OK  = qw($e $e2 %errors %attribute_types %value_types);


our $e = 1;
our $e2 = 2;

our %errors = (
    $liberty::SI2DR_NO_ERROR                        => 'NO ERROR',
    $liberty::SI2DR_INTERNAL_SYSTEM_ERROR           => 'INTERNAL SYSTEM ERROR',
    $liberty::SI2DR_INVALID_VALUE                   => 'INVALID VALUE',
    $liberty::SI2DR_INVALID_NAME                    => 'INVALID NAME',
    $liberty::SI2DR_INVALID_OBJECTTYPE              => 'INVALID OBJECTTYPE',
    $liberty::SI2DR_INVALID_ATTRTYPE                => 'INVALID ATTRTYPE',
    $liberty::SI2DR_UNUSABLE_OID                    => 'UNUSABLE OID',
    $liberty::SI2DR_OBJECT_ALREADY_EXISTS           => 'OBJECT ALREADY EXISTS',
    $liberty::SI2DR_OBJECT_NOT_FOUND                => 'OBJECT NOT FOUND',
    $liberty::SI2DR_SYNTAX_ERROR                    => 'SYNTAX ERROR',
    $liberty::SI2DR_TRACE_FILES_CANNOT_BE_OPENED    => 'TRACE FILES CANNOT BE OPENED',
    $liberty::SI2DR_PIINIT_NOT_CALLED               => 'PIINIT NOT CALLED',
    $liberty::SI2DR_SEMANTIC_ERROR                  => 'SEMANTIC ERROR',
    $liberty::SI2DR_REFERENCE_ERROR                 => 'REFERENCE ERROR',
    ''                                              => 'UNKNOWN ERROR',
);

our %attribute_types = (
    $liberty::SI2DR_SIMPLE  => 'simple',
    $liberty::SI2DR_COMPLEX => 'complex',
    ''                      => 'unknown',
);

our %value_types = (
    $liberty::SI2DR_BOOLEAN => {
        type        => 'boolean',
        simple_get  => \&liberty::si2drSimpleAttrGetBooleanValue,
        simple_set  => \&liberty::si2drSimpleAttrSetBooleanValue,
        complex_get => \&liberty::si2drComplexValGetBooleanValue,
        complex_add => \&liberty::si2drComplexAttrAddBooleanValue,
    },
    $liberty::SI2DR_INT32 => {
        type        => 'integer',
        simple_get  => \&liberty::si2drSimpleAttrGetInt32Value,
        simple_set  => \&liberty::si2drSimpleAttrSetInt32Value,
        complex_get => \&liberty::si2drComplexValGetInt32Value,
        complex_add => \&liberty::si2drComplexAttrAddInt32Value,
    },
    $liberty::SI2DR_FLOAT64 => {
        type        => 'float',
        simple_get  => \&liberty::si2drSimpleAttrGetFloat64Value,
        simple_set  => \&liberty::si2drSimpleAttrSetFloat64Value,
        complex_get => \&liberty::si2drComplexValGetFloat64Value,
        complex_add => \&liberty::si2drComplexAttrAddFloat64Value,
    },
    $liberty::SI2DR_STRING => {
        type        => 'string',
        simple_get  => \&liberty::si2drSimpleAttrGetStringValue,
        simple_set  => \&liberty::si2drSimpleAttrSetStringValue,
        complex_get => \&liberty::si2drComplexValGetStringValue,
        complex_add => \&liberty::si2drComplexAttrAddStringValue,
    },
    $liberty::SI2DR_EXPR => {
        type        => 'expression',
        simple_get  => \&liberty::si2drSimpleAttrGetExprValue,
        simple_set  => \&liberty::si2drSimpleAttrSetExprValue,
        complex_get => \&liberty::si2drComplexValGetExprValue,
        complex_add => \&liberty::si2drComplexAttrAddExprValue,
    },
    $liberty::SI2DR_UNDEFINED_VALUETYPE => {
        type        => 'undefined',
        simple_get  => undef,
        simple_set  => undef,
        complex_get => undef,
        complex_add => undef,
    },
);


1;
