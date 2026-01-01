#=======================================================================
#
#   THIS IS A REUSED PERL MODULE, FOR PROPER LICENCING TERMS SEE BELOW:
#
#   Copyright Martin Hosken <Martin_Hosken@sil.org>
#
#   No warranty or expression of effectiveness, least of all regarding
#   anyone's safety, is implied in this software or documentation.
#
#   This specific module is licensed under the Perl Artistic License.
#   Effective 28 January 2021, the original author and copyright holder, 
#   Martin Hosken, has given permission to use and redistribute this module 
#   under the MIT license.
#
#=======================================================================
package PDF::Builder::Basic::PDF::Filter;

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Filter::ASCII85Decode;
use PDF::Builder::Basic::PDF::Filter::ASCIIHexDecode;
use PDF::Builder::Basic::PDF::Filter::FlateDecode;
use PDF::Builder::Basic::PDF::Filter::LZWDecode;
use PDF::Builder::Basic::PDF::Filter::RunLengthDecode;
# use PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode;   when TIFF changes in
use Scalar::Util qw(blessed reftype);

=head1 NAME

PDF::Builder::Basic::PDF::Filter - Abstract superclass for PDF stream filters

=head1 SYNOPSIS

    $f = PDF::Builder::Basic::PDF::Filter->new();
    $str = $f->outfilt($str, 1);
    print OUTFILE $str;

    while (read(INFILE, $dat, 4096))
    { $store .= $f->infilt($dat, 0); }
    $store .= $f->infilt("", 1);

=head1 DESCRIPTION

A Filter object contains state information for the process of outputting
and inputting data through the filter. The precise state information stored
is up to the particular filter and may range from nothing to whole objects
created and destroyed.

Each filter stores different state information for input and output and thus
may handle one input filtering process and one output filtering process at
the same time.

=head1 METHODS

=head2 new

    PDF::Builder::Basic::PDF::Filter->new()

=over

Creates a new filter object with empty state information ready for processing
data both input and output.

=back

=head2 infilt

    $dat = $f->infilt($str, $isend)

=over

Filters from output to input the data. Notice that C<$isend == 0> implies that 
there is more data to come and so following it C<$f> may contain state 
information (usually due to the break-off point of C<$str> not being tidy). 
Subsequent calls will incorporate this stored state information.

C<$isend == 1> implies that there is no more data to follow. The final state of 
C<$f> will be that the state information is empty. Error messages are most 
likely to occur here since if there is required state information to be stored 
following this data, then that would imply an error in the data.

=back

=head2 outfilt

    $str = $f->outfilt($dat, $isend)

=over

Filter stored data ready for output. Parallels C<infilt>.

=back

=cut

sub new {
    my $class = shift();
    my $self = {};

    bless $self, $class;

    return $self;
}

sub release {
    my $self = shift();
    return $self unless ref($self);

    # delete stuff that we know we can, here
    my @tofree = map { delete $self->{$_} } keys %$self;

    while (my $item = shift @tofree) {
        my $ref = ref($item);
        if      (blessed($item) and $item->can('release')) {
            $item->release();
        } elsif ($ref eq 'ARRAY') {
            push @tofree, @$item ;
        } elsif (defined(reftype($ref)) and reftype($ref) eq 'HASH') {
            release($item);
        }
    }

    # check that everything has gone
    foreach my $key (keys %$self) {
        # warn ref($self) . " still has '$key' key left after release.\n";
        $self->{$key} = undef;
        delete $self->{$key};
    }
    return;
}

1;
