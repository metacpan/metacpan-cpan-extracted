package POE::Filter::SimpleHTTP::Error;
our $VERSION = '0.091710';

use Moose;
use Moose::Util::TypeConstraints;

use constant
{
   UNPARSABLE_PREAMBLE          => 0,
   TRAILING_DATA                => 1,
   CHUNKED_ISNT_LAST            => 2,
   INFLATE_FAILED_INIT          => 3,
   INFLATE_FAILED_INFLATE       => 4,
   UNCOMPRESS_FAILED            => 5,
   GUNZIP_FAILED                => 6,
   UNKNOWN_TRANSFER_ENCODING    => 7,
};

extends('Exporter');

our @EXPORT = qw/ UNPARSABLE_PREAMBLE TRAILING_DATA CHUNKED_ISNT_LAST 
    INFLATE_FAILED_INIT INFLATE_FAILED_INFLATE UNCOMPRESS_FAILED
    GUNZIP_FAILED UNKNOWN_TRANSFER_ENCODING /;

subtype 'ErrorType'
    => as 'Int'
    => where { -1 < $_ && $_ < 8 }
    => message { 'Invalid ErrorType' };

has 'error' =>
(
    is => 'rw',
    isa => 'ErrorType'
);

has 'context' =>
(
    is => 'rw',
    isa => 'Str',
);


=pod

=head1 NAME

POE::Filter::SimpleHTTP::Error - An error object for SimpleHTTP

=head1 VERSION

version 0.091710

=head1 SYNOPSIS

use 5.010;
use POE::Filter::SimpleHTTP;
use POE::Filter::SimpleHTTP::Error; #exports constants by default

my $filter = POE::Filter::SimpleHTTP->new();
$filter->get_one_start([qw/junk data goes here/]);
my $ret = $filter->get_one()->[0];

if($ret->isa('POE::Filter::SimpleHTTP::Error'))
{
    say $ret->error(); # 0 (aka. UNPARSABLE_PREAMBLE);
    say $ret->context(); # junkdatagoeshere
}

=head1 DESCRIPTION

This module provides the error class and exported constants for use downstream
from the filter to determine what went wrong.

=head1 PUBLIC ACCESSORS

=over 4

=item error()

error() contains the actual error code from the filter that corresponds with
the exported constants. Suitable for use in numeric comparisons (ie. ==)

=item context()

If the error has any context associated with it, it will be stored here. Note 
that some decompression routines do not provide a status message, just return 
undef, and so there is no context returned.

=back

=head1 EXPORTED CONSTANTS

=over 4

=item UNPARSABLE_PREAMBLE

The data provided doesn't parse for some reason as either a Response or 
Request. Context provided.

=item TRAILING_DATA

The message contains trailing data that isn't allowed by the RFC.
Context provided.

=item CHUNKED_ISNT_LAST

chunked isn't last in the transfer encodings. This isn't allowed by the RFC.
Context provided.

=item INFLATE_FAILED_INIT

Compress::Zlib::inflateInit failed. Context provided.

=item INFLATE_FAILED_INFLATE

inflate() failed. Context provided.

=item UNCOMPRESS_FAILED

uncompress() failed. No context.

=item GUNZIP_FAILED

memGunzip() failed. No context.

=item UNKNOWN_TRANSFER_ENCODING

A transfer encoding was not recognized. Context provided.

=back

=head1 AUTHOR

Copyright 2009 Nicholas Perez.
Licensed and distributed under the GPL.

=cut

__PACKAGE__->meta->make_immutable();
no Moose;

1;