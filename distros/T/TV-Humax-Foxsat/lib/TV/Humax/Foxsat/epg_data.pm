#!/usr/bin/perl
package TV::Humax::Foxsat::epg_data;

=head1 NAME

TV::Humax::Foxsat::hmt_data - Package representing Humax TV show metadata

=head1 VERSION

version 0.06

=cut

use namespace::autoclean;
use DateTime;
use Moose;
use Moose::Util::TypeConstraints;
use TV::Humax::Foxsat;

our $VERSION = '0.06'; # VERSION

use Trait::Attribute::Derived Unpack => {
    fields    => { 'unpacker' => 'Str' },
    processor => sub {
        my ($self, $value, $fields) = @_;
        return unpack( $fields->{'unpacker' }, $value)
    },
};

# The raw data that all the fields are extracted from.
has 'rawEPGBlock' => (
    is  => 'rw',
    isa => 'Str',
);

# In theory there are usefull fields here, but in practice we don't use them.
has 'rawGuideBlock' => (
    is  => 'rw',
    isa => 'Str',
);

has 'startTime' => (
    is       => 'rw', 
    isa      => 'DateTime',
    source    => 'rawEPGBlock',
    traits   => [ Unpack ],
    unpacker => '@4 N',
    postprocessor   =>  sub { return DateTime->from_epoch( epoch => $_, time_zone => 'GMT' ) },
);

has 'duration' => (
    is       => 'rw', 
    isa      => 'Int',
    source    => 'rawEPGBlock',
    traits   => [ Unpack ],
    unpacker => '@10 n',
);

has 'progName' => (
    is       => 'rw', 
    isa      => 'Str',
    source    => 'rawEPGBlock',
    traits   => [ Unpack ],
    unpacker => '@21 A52',
);

has 'guideInfo' => (
    is       => 'rw', 
    isa      => 'Str',
    source    => 'rawEPGBlock',
    traits   => [ Unpack ],
    unpacker => '@277 A255',
);

has 'guideFlag' => (
    is       => 'rw', 
    isa      => 'Bool',
    source    => 'rawEPGBlock',
    traits   => [ Unpack ],
    unpacker => '@534 c',
    postprocessor   =>  sub { return !!( $_ & 0x01 ) },
);

has 'guideBlockLen' => (
    is       => 'rw', 
    isa      => 'Int',
);

# All done 
1;
