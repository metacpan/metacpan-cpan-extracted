package MzML::CvList;
use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'cv' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::Cv]',
    );
1;
