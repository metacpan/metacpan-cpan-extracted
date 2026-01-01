package PDF::Builder::NamedDestination;

use base 'PDF::Builder::Basic::PDF::Dict';

use strict;
use warnings;

use Carp;
use Encode qw(:all);

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.028'; # manually update whenever code is changed

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::NamedDestination - Add named destinations (views) to a PDF

Inherits from L<PDF::Builder::Basic::PDF::Dict>

=head2 Usage

A Named Destination is defined in a PDF which is intended to be the target of
a specified Name (string), from within the same PDF, from another PDF, or
from a PDF Reader command line (e.g, MyBigPDF.pdf#nameddest=foo). The advantage
over going to a specific I<page> is that a Named Destination always points to
the same content in the document, even if that location moves around (i.e., to
a different page number).

Some Operating Systems support command line invocation (e.g., 
E<gt> MyPDF.pdf#name=bar), and some browsers' PDF readers also support it. 
C<#nameddest=foo> is the most basic form, and if Named Destinations are 
supported, this form should work. Some readers support the shortcut 
C<#name=foo>, and some even support the bare name: C<#foo> (similar to HTML). 
Named Destination syntax on the command line can vary widely by Reader.

A Named Destination must be unique within a given PDF, and is defined at the
top level in the C<$pdf> object. There are often limitations on the length of
a Named Destination string (name), including the length of whatever means is 
used to invoke it (e.g., C<#nameddest=foo> takes up 11 characters before you 
even get to the name 'foo' itself, so if the limit is 32, you're left with
perhaps 21 characters for the name itself). Be aware of this, and keep the 
names as short as reasonably possible. Spaces within a name are not permitted, 
and allowable punctuation is limited. Consult the PDF documentation for 
specifics, but A-Z, a-z, 0-9, and '_' (underscore) are generally permitted. 
Usually names are case-sensitive ('foo' is a different destination than 'Foo').

    # create a Named Destination 'foo' in this PDF file on page $page
    my $dest = PDF::Builder::NamedDestination->new($pdf);
    # its action will be to go to this page object $page, and a window within it
    # (various 'fits' can be defined
    $dest->goto($page, 'xyz', (undef, undef, undef));
    $pdf->named_destination('Dests', 'foo', $dest);

See L<PDF::Builder/named_destination> and L<PDF::Builder::Docs/Page Fit Options>
for information on named destinations.

=head1 METHODS

=head2 new

    $dest = PDF::Builder::NamedDestination->new($pdf)

    $dest = PDF::Builder::NamedDestination->new($pdf, @args)

=over

Creates a new named destination object. Any optional additional arguments
will be passed on to destination processing for "goto".

    $dest = PDF::Builder::NamedDestination->new($pdf, $page, 'xyz', 0,700, 1.5);

This will create a Named Destination which goes to ("goto") page object 
C<$page>, with fit XYZ at position 0,700 and zoom factor 1.5. 

It is possible to then call `goto()` to override the `new()` defined I<fit>:

    $dest->goto($page, 'fitb'); # overrides XYZ fit 

If you did B<not> give I<fit> options in the `new()` call (just `$pdf`), it 
will be necessary to call `goto()` with I<fit> settings, anyway:

    $dest = PDF::Builder::NamedDestination->new($pdf);
    $dest->goto($page, 'fit');

Finally, however you created the Named Destination, its action, and its page
fit, you need to tell the system 
to insert an entry into the Named Destination directory:

    $pdf->named_destination('Dests', "foo", $dest);

This is where you actually I<name> the destination. Consult 
L<PDF::Builder/named_destination> and L<PDF::Builder::Docs/Page Fit Options> 
for more information.

=back

=cut

sub new {
    my $class = shift;
    my $pdf = shift;

    $pdf = $pdf->{'pdf'} if $pdf->isa('PDF::Builder');
    my $self = $class->SUPER::new($pdf);
    $pdf->new_obj($self);

    if (@_) { # leftover arguments? page_obj + fit + data
	my $page = shift;
	my %opts = $self->list2hash(@_); # may be empty
	$self->{'S'} = PDFName('GoTo'); # default
	$self->{'D'} = $self->dest($page, %opts); 
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

# returns an anonymous array with page object and page fit info
sub dest {
    my ($self, $page, @args) = @_;

    # $page is either 1. a page object (from goto)
    #                 2. a formatted page number (from pdf)
    #                 3. a named destination string (from pdf)
    my %opts = $self->list2hash(@args);  # may be empty!

    my ($location, @arglist, $ptr);

    my %arg_counts = (
	# key = location given by user
	# [0] = required number of arguments, [1] = name for PDF
        'xyz'   => [3, 'XYZ'  ],  # s/b array ref
        'fit'   => [0, 'Fit'  ],  # 1 (scalar) ignored
        'fith'  => [1, 'FitH' ],  # s/b scalar
        'fitv'  => [1, 'FitV' ],  # s/b scalar
        'fitr'  => [4, 'FitR' ],  # s/b array ref
        'fitb'  => [0, 'FitB' ],  # 1 (scalar) ignored
        'fitbh' => [1, 'FitBH'],  # s/b scalar
        'fitbv' => [1, 'FitBV'],  # s/b scalar
    );

    # do any of the options contain a fit location, and if so, the right
    # number of data values (put into @arglist)?
    foreach (keys %arg_counts) {
	if (defined $opts{$_}) {
	    # this fit $_ is given in the options
	    $location = $_;
	    if (ref($opts{$_}) eq 'ARRAY') {
		# it's an anonymous array with presumably 3 or 4 elements
		@arglist = @{$opts{$_}};
	    } else {
		# it's a scalar value
		@arglist = ($opts{$_});
	    }
	}
    }
    if (!defined $location) {
	# no fit location given. default to xyz undef undef undef
	$location = 'xyz';
	@arglist = (undef, undef, undef);
    }
    if ($location eq 'fit' || $location eq 'fitb') {
	# these two locations take no location data, and hash would contain
	# a dummy value
	@arglist = ();
    }
    # check number of arguments given for location
    if      (@arglist > $arg_counts{$location}->[0]) {
	carp "Too many items given for '$location' location. Excess discarded.";
	splice(@arglist, $arg_counts{$location}->[0]);
    } elsif (@arglist < $arg_counts{$location}->[0]) {
	croak "Too few items given for '$location' location.";
    }

    if      (ref($page) ne '') {
        # it's an object
    } elsif ($page =~ /^\d+$/) {
	# it's a number
	$page = PDFNum($page);
    } else {
	# is a string, and therefore a Named Destination (?) shouldn't see here
	croak "string (Named Destination) passed to dest()";
    }
    return _array($page, $arg_counts{$location}->[1], @arglist);
}

# internal utilities 

sub _array {
    my $page = shift();
    my $location = shift();
    # remaining @_ is list of any args needed
    return PDFArray($page, PDFName($location),
                    map { defined($_) ? PDFNum($_) : PDFNull() } @_);
}

=head2 Target Destinations

Note that the usual practice for a Named Destination, invoked when the PDF is
opened with a Named Destination specified, is to I<goto> a point in the 
document. It is I<possible>, though unusual, to go to a point in another 
document (C<pdf()>), launch a local application (C<launch()>), or launch a web 
browser (C<uri()>).

The only "options" supported for C<goto> and C<pdf> are if you wish to give
the location and its arguments (data) in the form of a hash element (anonymous
array if more than one value). Unlike Annotation's "action" methods (C<goto>, 
C<pdf>, C<uri>, and C<launch>), there is no defining a "click area" (button)
for the user interaction; thus, no B<rect>, B<border>, or B<color> entries
are recognized in NamedDestination. Any found will be ignored.

See L<PDF::Builder::Docs/Page Fit Options> for a listing of the available
locations and their syntax.

"xyz" is the B<default> fit setting, with position (left and top) and zoom
all the same as the calling page's.

=head3 goto, link

    $dest->goto($page, $location, @args)  # preferred

    $dest->goto($page, %opts)  # opts including location and data

=over

A go-to (link) action changes the view to a specified destination (page object, 
location code, and various pieces of data for it). This is a jump I<within>
the current PDF document (B<internal>), and is the usual way of doing things.

B<Alternate name:> C<link>

Originally this method was C<link>, but PDF::API2 changed the name
to C<goto>, to match the internal PDF command C<GoTo>. "link" is retained 
for compatibility.

B<Notes:> C<goto> is a reserved Perl keyword (go to a label), so take care when
using this in code that the Perl interpreter doesn't see this as a Perl 'goto'.
If you receive an error message about a "missing label" or something equally
puzzling, this may have happened. C<link> is a built-in Perl function (Unix
C<ln> style command), so take care when using this code that the Perl 
interpreter doesn't see this as a Perl 'link' call (e.g., error message about
"not enough arguments for link").

=back

=cut

# link is also a Perl built-in function call
sub link { return goto(@_); } ## no critic

# goto is also a Perl keyword
sub goto {  ## no critic
    my $self = shift();
    my $page = shift();
    # remainder of input is any location hash

    $self->{'S'} = PDFName('GoTo');
    $self->{'D'} = $self->dest($page, @_);
    return;
}

=head3 pdf, pdf_file, pdfile

    $dest->pdf($pdffile, $page_number, $location, @args) # preferred

    $dest->pdf($pdffile, $page_number, %opts) # location is a hash element

=over

Defines the destination as an B<external> PDF-file with filepath C<$pdffile>, 
on page C<$page_number> (numeric value), and 
either options %opts (location/fit => any data for it as a scalar or anonymous 
array) or one of two formats: an array of location/fit string and any data for 
it, or a location/fit string and an array with any data needed for it.

To go to a Named Destination and then immediately jump to a point in another
PDF document is unusual, but possible.

B<Alternate names:> C<pdf_file> and C<pdfile>

Originally this method was C<pdfile>, and had been earlier renamed to 
C<pdf_file>, but PDF::API2 changed the name to C<pdf>. "pdfile" and 
"pdf_file" are retained for compatibility. 

=back

=cut

sub pdf_file { return pdf(@_); } ## no critic
sub pdfile { return pdf(@_); } ## no critic

sub pdf{
    my ($self, $file, $pnum, @args) = @_;

    $self->{'S'} = PDFName('GoToR');
    $self->{'F'} = PDFString($file, 'u');

    # $pnum should be a page number 1.. 
    if ($pnum =~ /^\d+$/) {
	# it's a page number
        $self->{'D'} = $self->dest(PDFNum($pnum-1), @args);
    } else {
	croak "pdf action for a Named Destination is using a Named Destination!";
       #if ($pnum =~ /^[#\/](.*)$/) {
       #    $pnum = $1;
       #}
       #$self->{'D'} = $self->dest(PDFString($pnum, 'u'), @args);
    }

    return $self;
}

=head3 uri, url

    $dest->uri($url)

=over

Defines the destination as launch-url (typically a web page) with uri C<$url>.
There are no options available.

To go to a Named Destination and then immediately launch a web browser
is unusual, but possible.

B<Alternate name:> C<url>

Originally this method was C<url>, but PDF::API2 changed the name
to C<uri> to match the PDF command. "url" is retained for compatibility.

=back

=cut

sub url { return uri(@_); } ## no critic

sub uri {
    my ($self, $uri, %opts) = @_;
    # currently no options supported

    $self->{'S'} = PDFName('URI');
    $self->{'URI'} = PDFString($uri, 'u');

    return $self;
}

=head3 launch, file

    $dest->launch($file)

=over

Defines the destination as launch-file with filepath C<$file> and
page-fit options %opts. The target application is run. Note that this is
B<not> a PDF I<or> a browser file -- it is a usually a local application, 
such as a text editor or photo viewer.
There are no options available.

To go to a Named Destination and then immediately launch a local application
is unusual, but possible.

B<Alternate name:> C<file>

Originally this method was C<file>, but PDF::API2 changed the name
to C<launch> to match the PDF command. "file" is retained for compatibility.

=back

=cut

sub file { return launch(@_); } ## no critic

sub launch {
    my ($self, $file, %opts) = @_;
    # currently no options supported

    $self->{'S'} = PDFName('Launch');
    $self->{'F'} = PDFString($file, 'u');

    return $self;
}

# return an array as a hash, with key leading -'s removed
# assumes possible hash elements already as scalars or arrayrefs
# leading element(s) may be a list, turn it into one name=>[list]
sub list2hash {
    my ($self, @args) = @_;

    # nothing passed in?
    if (!@args) { return @args; }

    my %arg_counts = (
	# key = location given by user
	# value = required number of arguments
        'xyz'   => 3,
        'fit'   => 0,
        'fith'  => 1,
        'fitv'  => 1,
        'fitr'  => 4,
        'fitb'  => 0,
        'fitbh' => 1,
        'fitbv' => 1,
    );
    my $location;

    # try to match first element as location name
    if ($args[0] =~ /^-(.*)$/) {
        $args[0] = $1;
    }
    my $num_args = scalar(@args);
    my $match = -1;
    my @keylist = keys %arg_counts;
    for (my $i=0; $i<@keylist; $i++) {
	if ($args[0] eq $keylist[$i]) {
	    $match = $arg_counts{$keylist[$i]};
	    # note that if hash element and not list, minimum is 1 data value
	    last;
	}
    }
    if ($match > -1) {
	# first element is a location value, but is it a hash element or a list?
	$location = $args[0];

	if (ref($args[1]) eq 'ARRAY' || $arg_counts{$location} == 1) {
	    # location and args supplied as hash element OR
	    # single value hash element or list, so entire array should be hash

	} elsif ($arg_counts{$location} == 3) {
	    # 3 elements should follow location, so as long as none
	    # are arrayrefs, we should be good. already checked that is not
	    # one arrayref for element
	    my @vals;
	    for (my $i=0; $i<3; $i++) {
                $vals[$i] = $args[$i+1];
		if (ref($vals[$i]) eq '') { next; }
		croak "list of elements contains non-scalars in list2hash()!";
	    }
	    splice(@args, 0, 4);
	    unshift @args, ($location, \@vals);

	} elsif ($arg_counts{$location} == 4) {
	    # 4 elements should follow location, so as long as none
	    # are arrayrefs, we should be good. already checked that is not
	    # one arrayref for element
	    my @vals;
	    for (my $i=0; $i<4; $i++) {
                $vals[$i] = $args[$i+1];
		if (ref($vals[$i]) eq '') { next; }
		croak "list of elements contains non-scalars in list2hash()!";
	    }
	    splice(@args, 0, 5);
	    unshift @args, ($location, \@vals);

	} elsif ($arg_counts{$location} == 0) {
	    # 0 data items, but if is hash element, will have a dummy value
	    if ($num_args%2) {
		# assume was list, with no args values following location
		splice(@args, 0, 1); # drop location
		unshift @args, ($location, 1); # hash element with dummy 1
	    } else {
		# assume was hash element, with dummy value after location
		# e.g., 'fit'=>1
	    }
	}
    }

    # any pair already string, scalar or arrayref can simply be copied over
    if (scalar(@args)%2) {
	croak "list2hash() sees hash with odd number of elements!";
    }
    for (my $i=0; $i<scalar(@args)-1; $i+=2) {
	if (ref($args[$i]) ne '') {
	    croak "list2hash() sees hash element with non scalar key.";
	}
	if (ref($args[$i+1]) ne '' && ref($args[$i+1]) ne 'ARRAY') {
	    croak "argument structure list2hash() can't handle!";
	}
	# elements look OK for hash, remove leading -'s
	if ($args[$i] =~ /^-(.*)$/) {
	    $args[$i] = $1;
	}
    }

    return @args;   # see as %opts by caller
}

1;
