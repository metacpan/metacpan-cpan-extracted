package MzML::CommonParams;

use strict;
use warnings;
use v5.12;
use Moose::Role;
use MzML::ReferenceableParamGroupRef;
use MzML::CvParam;
use MzML::UserParam;

has 'referenceableParamGroupRef' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::ReferenceableParamGroupRef]',
    );

has 'cvParam' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::CvParam]',
    );

has 'userParam' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::UserParam]',
    );
 
1;
