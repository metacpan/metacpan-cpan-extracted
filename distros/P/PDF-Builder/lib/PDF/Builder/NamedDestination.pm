package PDF::Builder::NamedDestination;

use base 'PDF::Builder::Basic::PDF::Dict';

use strict;
use warnings;

use Carp;
use Encode qw(:all);

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

# TBD: do rect and border apply to Named Destinations (link, url, file)? 
#      There is nothing to implement these options. Perhaps the code was copied 
#      from Annotations and never cleaned up? Disable mention of these options 
#      for now (in the POD). Only link handles the destination page fit option.

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::NamedDestination - Add named destinations (views) to a PDF

Inherits from L<PDF::Builder::Basic::PDF::Dict>

=head1 METHODS

=head2 new

    $dest = PDF::Builder::NamedDestination->new($pdf, ...)

=over

Creates a new named destination object. Any optional additional arguments
will be passed on to C<destination>.

=back

=cut

sub new {
    my $class = shift;
    my $pdf = shift;

    $pdf = $pdf->{'pdf'} if $pdf->isa('PDF::Builder');
    my $self = $class->SUPER::new($pdf);
    $pdf->new_obj($self);

    if (@_) { # leftover arguments?
	return $self->dest(@_);
    }

    return $self;
}

# Note: new_api() removed in favor of new():
#   new_api($api, ...)  replace with new($api->{'pdf'}, ...)
# Appears to be added back in, PDF::API2 2.042
sub new_api {
    my ($class, $api2) = @_;
    warnings::warnif('deprecated',
	             'Call to deprecated method new_api, replace with new');

    my $destination = $class->new($api2);
    return $destination;
}

=head2 Destination types

=head3 dest

    $dest->dest($page, %opts)

=over

A destination (dest) is a particular view of a PDF, consisting of a page 
object, the
location of the window on that page, and possible coordinate and zoom arguments.

    # The XYZ location takes three arguments
    my $dest1 = PDF::Builder::NamedDestination->new($pdf);
    $dest->dest($pdf->open_page(1), 'xyz' => [$x, $y, $zoom]);

    # The Fit location doesn't require any arguments, but one is still
    # needed for the hash array
    my $dest2 = PDF::Builder::NamedDestination->new($pdf);
    $dest->dest($pdf->open_page(2), 'fit' => 1);

See L<PDF::Builder::Docs/Page Fit Options> for a listing of the available
locations and their syntax.

"xyz" is the B<default> fit setting, with position (left and top) and zoom
the same as the calling page's.

=back

=cut

sub dest {
    my ($self, $page, %opts) = @_;

    # copy dashed names over to preferred non-dashed names
    if (defined $opts{'-fit'} && !defined $opts{'fit'}) { $opts{'fit'} = delete($opts{'-fit'}); }
    if (defined $opts{'-fith'} && !defined $opts{'fith'}) { $opts{'fith'} = delete($opts{'-fith'}); }
    if (defined $opts{'-fitb'} && !defined $opts{'fitb'}) { $opts{'fitb'} = delete($opts{'-fitb'}); }
    if (defined $opts{'-fitbh'} && !defined $opts{'fitbh'}) { $opts{'fitbh'} = delete($opts{'-fitbh'}); }
    if (defined $opts{'-fitv'} && !defined $opts{'fitv'}) { $opts{'fitv'} = delete($opts{'-fitv'}); }
    if (defined $opts{'-fitbv'} && !defined $opts{'fitbv'}) { $opts{'fitbv'} = delete($opts{'-fitbv'}); }
    if (defined $opts{'-fitr'} && !defined $opts{'fitr'}) { $opts{'fitr'} = delete($opts{'-fitr'}); }
    if (defined $opts{'-xyz'} && !defined $opts{'xyz'}) { $opts{'xyz'} = delete($opts{'-xyz'}); }

    if (ref($page)) {
	# should be only one 'fit' hash value? other options in hash?
	# TBD: check that single values are scalars, not ARRAYREFs?
	if      (defined $opts{'fit'}) {  # 1 value, ignored
            $self->{'D'} = PDFArray($page, PDFName('Fit'));
        } elsif (defined $opts{ 'fith'}) {
	    croak "Expecting scalar value for fith entry "
	        unless ref($opts{'fith'}) eq '';
            $self->{'D'} = PDFArray($page, PDFName('FitH'), 
		                    PDFNum($opts{'fith'}));
	} elsif (defined $opts{'fitb'}) {  # 1 value, ignored
            $self->{'D'} = PDFArray($page, PDFName('FitB'));
        } elsif (defined $opts{'fitbh'}) {
	    croak "Expecting scalar value for fitbh entry "
	        unless ref($opts{'fitbh'}) eq '';
            $self->{'D'} = PDFArray($page, PDFName('FitBH'),
		                    PDFNum($opts{'fitbh'}));
        } elsif (defined $opts{'fitv'}) {
	    croak "Expecting scalar value for fitv entry "
	        unless ref($opts{'fitv'}) eq '';
            $self->{'D'} = PDFArray($page, PDFName('FitV'), 
		                    PDFNum($opts{'fitv'}));
        } elsif (defined $opts{'fitbv'}) {
	    croak "Expecting scalar value for fitbv entry "
	        unless ref($opts{'fitbv'}) eq '';
            $self->{'D'} = PDFArray($page, PDFName('FitBV'), 
		                    PDFNum($opts{'fitbv'}));
        } elsif (defined $opts{'fitr'}) {  # anon array length 4
            croak "Insufficient parameters to ->dest(page, fitr => []) " 
	        unless ref($opts{'fitr'}) eq 'ARRAY' &&
		       scalar @{$opts{'fitr'}} == 4;
            $self->{'D'} = PDFArray($page, PDFName('FitR'), 
		                    map {PDFNum($_)} @{$opts{'fitr'}});
        } elsif (defined $opts{'xyz'}) {  # anon array length 3
            croak "Insufficient parameters to ->dest(page, xyz => []) " 
	        unless ref($opts{'xyz'}) eq 'ARRAY' &&
		       scalar @{$opts{'xyz'}} == 3;
            $self->{'D'} = PDFArray($page, PDFName('XYZ'), 
		map {defined $_ ? PDFNum($_) : PDFNull()} @{$opts{'xyz'}});
	} else {
	    # no "fit" option found. use default of xyz.
            $opts{'xyz'} = [undef,undef,undef];
            $self->{'D'} = PDFArray($page, PDFName('XYZ'), 
		map {defined $_ ? PDFNum($_) : PDFNull()} @{$opts{'xyz'}});
        }
    }

    return $self;
}

# These targets are similar to what is given in Annotations, and are used to
# provide an Action when the externally visible name is given to the PDF Reader
# (see Named Destination issue #202 for #nameddest= ).

=head2 Target Destinations

=head3 link, goto

    $dest->link($page, %opts)

=over

A go-to (link) action changes the view to a specified destination (page, 
location, and magnification factor).

Parameters are as described in C<dest>.

B<Alternate name:> C<goto>

Originally this method was C<link>, but recently PDF::API2 changed the name
to C<goto>. "goto" is added for compatibility.

=back

=cut

sub link { 
    my $self = shift();
    $self->{'S'} = PDFName('GoTo');
    return $self->dest(@_);
}

sub goto {
    my $self = shift();
    $self->{'S'} = PDFName('GoTo');
    return $self->dest(@_);
}

=head3 uri, url

    $dest->uri($url)

=over

Defines the destination as launch-url with uri C<$url>.

B<Alternate name:> C<url>

Originally this method was C<url>, but recently PDF::API2 changed the name
to C<uri>. "url" is retained for compatibility.

=back

=cut

sub url { return uri(@_); } ## no critic

sub uri {
    my ($self, $uri, %opts) = @_;
    # currently no opts

    $self->{'S'} = PDFName('URI');
    $self->{'URI'} = PDFString($uri, 'u');

    return $self;
}

=head3 launch, file

    $dest->launch($file)

=over

Defines the destination as launch-file with filepath C<$file> and
page-fit options %opts. The target application is run. Note that this is
B<not> a PDF I<or> a browser file -- it is a local application.

B<Alternate name:> C<file>

Originally this method was C<file>, but recently PDF::API2 changed the name
to C<launch>. "file" is retained for compatibility.

=back

=cut

sub file { return launch(@_); } ## no critic

sub launch {
    my ($self, $file, %opts) = @_;
    # currently no opts

    $self->{'S'} = PDFName('Launch');
    $self->{'F'} = PDFString($file, 'u');

    return $self;
}

=head3 pdf, pdf_file, pdfile

    $dest->pdf($pdf_file, $pagenum, %opts)

=over

Defines the destination as a PDF-file with filepath C<$pdf_file>, on page
C<$pagenum>, and options %opts (same as dest()).

B<Alternate names:> C<pdf_file> and C<pdfile>

Originally this method was C<pdfile>, and had been earlier renamed to 
C<pdf_file>, but recently PDF::API2 changed the name to C<pdf>. "pdfile" and 
"pdf_file" are retained for compatibility. B<Note that> the position and zoom
information is still given as a hash element in PDF::Builder, while PDF::API2
has changed to a position string and an array of dimensions.

=back

=cut

sub pdf_file { return pdf(@_); } ## no critic
# deprecated and removed earlier, but still in PDF::API2
sub pdfile { return pdf(@_); } ## no critic

sub pdf{
    my ($self, $file, $pnum, %opts) = @_;

    $self->{'S'} = PDFName('GoToR');
    $self->{'F'} = PDFString($file, 'u');

    $self->dest(PDFNum($pnum), %opts);

    return $self;
}

1;
