package PDF::Builder::Resource::XObject::Form::Hybrid;

use base qw(PDF::Builder::Content PDF::Builder::Content::Text PDF::Builder::Resource::XObject::Form);

use strict;
use warnings;

our $VERSION = '3.023'; # VERSION
our $LAST_UPDATE = '3.016'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Dict;
use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Resource::XObject::Form;
=head1 NAME

PDF::Builder::Resource::XObject::Form::Hybrid - support routines for Forms. Inherits from L<PDF::Builder::Content>, L<PDF::Builder::Content::Text>, and L<PDF::Builder::Resource::XObject::Form>

=cut

sub new {
    my $self = PDF::Builder::Resource::XObject::Form::new(@_);

    $self->{' stream'}      = '';
    $self->{' poststream'}  = '';
    $self->{' font'}        = undef;
    $self->{' fontsize'}    = 0;
    $self->{' charspace'}   = 0;
    $self->{' hscale'}      = 100;
    $self->{' wordspace'}   = 0;
    $self->{' lead'}        = 0;
    $self->{' rise'}        = 0;
    $self->{' render'}      = 0;
    $self->{' matrix'}      = [1, 0, 0, 1, 0, 0];
    $self->{' fillcolor'}   = [0];
    $self->{' strokecolor'} = [0];
    $self->{' translate'}   = [0, 0];
    $self->{' scale'}       = [1, 1];
    $self->{' skew'}        = [0, 0];
    $self->{' rotate'}      = 0;
    $self->{' apiistext'}   = 0;

    $self->{'Resources'}    = PDFDict();
    $self->{'Resources'}->{'ProcSet'} = PDFArray(map { PDFName($_) } qw(PDF Text ImageB ImageC ImageI));

    $self->compressFlate();

    return $self;
}

sub outobjdeep {
    my ($self) = shift();

    $self->textend() unless $self->{' nofilt'};

#   # Maintainer's Note: This list of keys isn't the same as the list
#   # in new().  Should it be?
#   # missing: stream, poststream, apiistext
#   # added:   api, apipdf, apipage
#   foreach my $key (qw(api apipdf apipage font fontsize charspace hscale
#                       wordspace lead rise render matrix fillcolor
#                       strokecolor translate scale skew rotate)) {
#       delete $self->{" $key"};
#   }
    return PDF::Builder::Basic::PDF::Dict::outobjdeep($self, @_);
}

1;
