package PDF::Builder;

use strict;
use warnings;

# $VERSION defined here so developers can run PDF::Builder from git.
# it should be automatically updated as part of the CPAN build.
our $VERSION = '3.024'; # VERSION
our $LAST_UPDATE = '3.024'; # manually update whenever code is changed

# updated during CPAN build
my $GrTFversion = 19;    # minimum version of Graphics::TIFF
my $HBShaperVer = 0.024; # minimum version of HarfBuzz::Shaper
my $LpngVersion = 0.57;  # minimum version of Image::PNG::Libpng

use Carp;
use Encode qw(:all);
use English;
use FileHandle;

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Util;

use PDF::Builder::Basic::PDF::File;
use PDF::Builder::Basic::PDF::Pages;
use PDF::Builder::Page;

use PDF::Builder::Resource::XObject::Form::Hybrid;

use PDF::Builder::Resource::ExtGState;
use PDF::Builder::Resource::Pattern;
use PDF::Builder::Resource::Shading;

use PDF::Builder::NamedDestination;

use List::Util qw(max);
use Scalar::Util qw(weaken);

my @font_path = __PACKAGE__->set_font_path(
                  '/usr/share/fonts',
		  '/usr/local/share/fonts',
		  'C:/Windows/Fonts',
		  'C:/WinNT/Fonts'
	                                  );

our @MSG_COUNT = (0,  # [0] Graphics::TIFF not installed
	          0,  # [1] Image::PNG::Libpng not installed
		  0,  # [2] TBD...
	         );
our $outVer = 1.4; # desired PDF version for output, bump up w/ warning on read or feature output
our $msgVer = 1;   # 0=don't, 1=do issue message when PDF output version is bumped up
our $myself;       # holds self->pdf
our $global_pdf;   # holds self ($pdf)

=head1 NAME

PDF::Builder - Facilitates the creation and modification of PDF files

=head1 SYNOPSIS

    use PDF::Builder;

    # Create a blank PDF file
    $pdf = PDF::Builder->new();

    # Open an existing PDF file
    $pdf = PDF::Builder->open('some.pdf');

    # Add a blank page
    $page = $pdf->page();

    # Retrieve an existing page
    $page = $pdf->open_page($page_number);

    # Set the page size
    $page->size('Letter');  # or mediabox('Letter')

    # Add a built-in font to the PDF
    $font = $pdf->font('Helvetica-Bold'); # or corefont('Helvetica-Bold')

    # Add an external TrueType (TTF) font to the PDF
    $font = $pdf->font('/path/to/font.ttf');  # or ttfont() in this case

    # Add some text to the page
    $text = $page->text();
    $text->font($font, 20);
    $text->position(200, 700);  # or translate()
    $text->text('Hello World!');

    # Save the PDF
    $pdf->saveas('/path/to/new.pdf');

=head1 SOME SPECIAL NOTES

See the file README.md (in downloadable package and on CPAN) for a summary of 
prerequisites and tools needed to install PDF::Builder, both mandatory and 
optional.

=head2 SOFTWARE DEVELOPMENT KIT

There are four levels of involvement with PDF::Builder. Depending on what you
want to do, different kinds of installs are recommended.
See L<PDF::Builder::Docs/Software Development Kit> for suggestions.

=head2 OPTIONAL LIBRARIES

PDF::Builder can make use of some optional libraries, which are not I<required>
for a successful installation, but improve speed and capabilities. See 
L<PDF::Builder::Docs/Optional Libraries> for more information.

=head2 STRINGS (CHARACTER TEXT)

There are some things you should know about character encoding (for text),
before you dive in to coding. Please go to L<PDF::Builder::Docs/Strings (Character Text)> and have a read.

=head2 RENDERING ORDER

Invoking "text" and "graphics" methods can lead to unexpected results (a 
different ordering of output than intended). See L<PDF::Builder::Docs/Rendering Order> for more information.

=head2 PDF VERSIONS SUPPORTED

PDF::Builder is mostly PDF 1.4-compliant, but there I<are> complications you
should be aware of. Please read L<PDF::Builder::Docs/PDF Versions Supported>
for details.

=head2 SUPPORTED PERL VERSIONS (BACKWARDS COMPATIBILITY GOALS)

PDF::Builder intends to support all major Perl versions that were released in
the past six years, plus one, in order to continue working for the life of
most long-term-stable (LTS) server distributions.
See the L<https://www.cpan.org/src/> table 
B<First release in each branch of Perl> x.xxxx0 "Major" release dates.

For example, a version of PDF::Builder released on 2018-06-05 would support 
the last major version of Perl released I<on or after> 2012-06-05 (5.18), and 
then one before that, which would be 5.16. Alternatively, the last major 
version of Perl released I<before> 2012-06-05 is 5.16.

The intent is to avoid expending unnecessary effort in supporting very old
(obsolete) versions of Perl.

=head3 Anticipated Support Cutoff Dates

=over

=item * 5.24 current minimum supported version, until next PDF::Builder release after 30 May, 2023

=item * 5.26 future minimum supported version, until next PDF::Builder release after 23 June, 2024

=item * 5.28 future minimum supported version, until next PDF::Builder release after 22 May, 2025

=item * 5.30 future minimum supported version, until next PDF::Builder release after 20 June, 2026

=item * 5.32 future minimum supported version, until next PDF::Builder release after 20 May, 2027

=item * 5.34 future minimum supported version, until next PDF::Builder release after 28 May, 2028

=back

If you need to use this module on a server with an extremely out-of-date version
of Perl, consider using either plenv or Perlbrew to run a newer version of Perl
without needing admin privileges.

On the other hand, any feature in PDF::Builder should continue to work 
unchanged for the life of most long-term-stable (LTS) server distributions.
Their lifetime is usually about six (6) years. Note that this does B<not>
constitute a statement of warranty, but that we I<intend> to try to keep any
particular release of PDF::Builder working for a period of years. Of course,
it helps if you periodically update your Perl installation to something
released in the recent past.

=head2 KNOWN ISSUES

This module does not work with perl's -l command-line switch.

There is a file INFO/KNOWN_INCOMP which lists known incompatibilities with 
PDF::API2, in case you're thinking of porting over something from that world, 
or have experience there and want to try PDF::Builder. There is also a file 
INFO/DEPRECATED, which lists things which are planned to be removed at some 
point.

=head2 HISTORY

The history of PDF::Builder is a complex and exciting saga... OK, it may be
mildly interesting. Have a look at L<PDF::Builder::Docs/History> section.

=head2 AUTHOR

PDF::API2 was originally written by Alfred Reibenschuh. See the HISTORY section
for more information.

It was maintained by Steve Simms, who is still contributing new code to it
(which often ends up in PDF::Builder).

PDF::Builder is currently being maintained by Phil M. Perry.

=head2 SUPPORT

The full source is on https://github.com/PhilterPaper/Perl-PDF-Builder.

The release distribution is on CPAN: https://metacpan.org/pod/PDF::Builder.

Bug reports are on https://github.com/PhilterPaper/Perl-PDF-Builder/issues?q=is%3Aissue+sort%3Aupdated-desc 
(with "bug" label), feature requests have an "enhancement" label, and general 
discussions (architecture, roadmap, etc.) have a "general discussion" label.

Do B<not> under I<any> circumstances open a PR (Pull Request) to report a bug. 
It is a waste of both your and our time and effort. Open a regular ticket 
(issue), and attach a Perl (.pl) program illustrating the problem, if possible. 
If you believe that you have a program patch, and offer to share it as a PR, we 
may give the go-ahead. Unsolicited PRs may be closed without further action.

=head2 LICENSE

This software is Copyright (c) 2017-2022 by Phil M. Perry.

This is free software, licensed under:

The GNU Lesser General Public License (LGPL) Version 2.1, February 1999

  (The master copy of this license lives on the GNU website.)
  (A copy is provided in the INFO/LICENSE file for your convenience.)

This section of Builder.pm is intended only as a very brief summary 
of the license; please consider INFO/LICENSE to be the controlling version, 
if there is any conflict or ambiguity between the two.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License, as published by the Free
Software Foundation, either version 2.1 of the License, or (at your option) any
later version of this license.

NOTE: there are several files in this distribution which were incorporated from
outside sources and carry different licenses. If a file states that it is under 
a license different than LGPL 2.1, that license and its terms will apply to 
that file, and not LGPL 2.1.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

=head1 GENERAL PURPOSE METHODS

=over

=item $pdf = PDF::Builder->new(%opts)

Creates a new PDF object. 

B<Options>

=over

=item file

If you will be saving it as a file and
already know the filename, you can give the 'file' option to minimize
possible memory requirements later on (the file is opened immediately for
writing, rather than waiting until the C<save>). The C<file> may also be
a filehandle.

=item compress

The 'compress' option can be
given to specify stream compression: default is 'flate', 'none' (or 0) is no
compression. No other compression methods are currently supported.

=item outver

The 'outver' option defaults to 1.4 as the output PDF version and the highest 
allowed feature version (attempts to use anything higher will give a warning).
If an existing PDF with a higher version is read in, C<outver> will be 
increased to that version, with a warning.

=item msgver

The 'msgver' option value of 1 (default) gives a warning message if the 
'outver' PDF level has to be bumped up due to either a higher PDF level file 
being read in, or a higher level feature was requested. A value of 0 
suppresses the warning message.

=item diaglevel

The 'diaglevel' option can be
given to specify the level of diagnostics given by IntegrityCheck(). The
default is level 2 (errors and warnings). 
See L<PDF::Builder::Docs/IntegrityCheck> for more information.

=back

B<Example:>

    $pdf = PDF::Builder->new();
    ...
    print $pdf->to_string();

    $pdf = PDF::Builder->new(compress => 'none');
    # equivalent to $pdf->{'forcecompress'} = 'none'; (or older, 0)

    $pdf = PDF::Builder->new();
    ...
    $pdf->saveas('our/new.pdf');

    $pdf = PDF::Builder->new(file => 'our/new.pdf');
    ...
    $pdf->save();

=cut

sub new {
    my ($class, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-compress'} && !defined $opts{'compress'}) { $opts{'compress'} = delete($opts{'-compress'}); }
    if (defined $opts{'-diaglevel'} && !defined $opts{'diaglevel'}) { $opts{'diaglevel'} = delete($opts{'-diaglevel'}); }
    if (defined $opts{'-outver'} && !defined $opts{'outver'}) { $opts{'outver'} = delete($opts{'-outver'}); }
    if (defined $opts{'-msgver'} && !defined $opts{'msgver'}) { $opts{'msgver'} = delete($opts{'-msgver'}); }
    if (defined $opts{'-file'} && !defined $opts{'file'}) { $opts{'file'} = delete($opts{'-file'}); }

    my $self = {};
    bless $self, $class;
    $self->{'pdf'} = PDF::Builder::Basic::PDF::File->new();

    # make available to other routines
    $myself = $self->{'pdf'};

    # default output version
    $self->{'pdf'}->{' version'} = $outVer;
    $self->{'pages'} = PDF::Builder::Basic::PDF::Pages->new($self->{'pdf'});
    $self->{'pages'}->proc_set(qw(PDF Text ImageB ImageC ImageI));
    $self->{'pages'}->{'Resources'} ||= PDFDict();
    $self->{'pdf'}->new_obj($self->{'pages'}->{'Resources'}) 
        unless $self->{'pages'}->{'Resources'}->is_obj($self->{'pdf'});
    $self->{'catalog'} = $self->{'pdf'}->{'Root'};
    weaken $self->{'catalog'};
    $self->{'fonts'} = {};
    $self->{'pagestack'} = [];

    $self->{'pdf'}->{' userUnit'} = 1.0; # default global User Unit
    $self->mediabox('letter');  # PDF defaults to US Letter 8.5in x 11in 

    if      (exists $opts{'compress'}) {
      $self->{'forcecompress'} = $opts{'compress'};
      # at this point, no validation of given value! none/flate (0/1).
      # note that >0 is often used as equivalent to 'flate'
    } else {
      $self->{'forcecompress'} = 'flate';
      # code should also allow integers 0 (= 'none') and >0 (= 'flate') 
      # for compatibility with old usage where forcecompress is directly set. 
    }
    if (exists $opts{'diaglevel'}) {
	my $diaglevel = $opts{'diaglevel'};
	if ($diaglevel < 0 || $diaglevel > 5) {
	    print "diaglevel must be in range 0-5. using 2\n";
	    $diaglevel = 2;
	}
	$self->{'diaglevel'} = $diaglevel;
    } else {
	$self->{'diaglevel'} = 2; # default: errors and warnings
    }

    $self->preferences(%opts);
    if (defined $opts{'outver'}) {
        if ($opts{'outver'} >= 1.4) {
	    $self->{'pdf'}->{' version'} = $opts{'outver'};
	} else {
	    print STDERR "Invalid outver given, or less than 1.4. Ignored.\n";
	}
    }
    if (defined $opts{'msgver'}) {
        if ($opts{'msgver'} == 0 || $opts{'msgver'} == 1) {
            $msgVer = $opts{'msgver'};
        } else {
            print STDERR "Invalid msgver given, not 0 or 1. Ignored.\n";
        }
    }
    if ($opts{'file'}) {
        $self->{'pdf'}->create_file($opts{'file'});
        $self->{'partial_save'} = 1;
    }
    # used by info and infoMetaAttributes but not by their replacements
    $self->{'infoMeta'} = [qw(Author CreationDate ModDate Creator Producer 
	                      Title Subject Keywords)];

    my $version = eval { $PDF::Builder::VERSION } || '(Development Version)';
   #$self->info('Producer' => "PDF::Builder $version [$^O]");
    $self->info('Producer' => "PDF::Builder $version [see ".
                "https://github.com/PhilterPaper/Perl-PDF-Builder/blob/master/INFO/SUPPORT]");

    $global_pdf = $self;
    return $self;
} # end of new()

=item $pdf->default_page_size($size); # Set

=item @rectangle = $pdf->default_page_size() # Get

Set the default physical size for pages in the PDF.  If called without
arguments, return the coordinates of the rectangle describing the default
physical page size.

This is essentially an alternate method of defining the C<mediabox()> call,
and added for compatibility with PDF::API2.

See L<PDF::Builder::Page/Page Sizes> for possible values.

=cut

sub default_page_size {
    my $self = shift();

    # Set
    if (@_) {
        return $self->default_page_boundaries(media => @_);
    }

    # Get
    my $boundaries = $self->default_page_boundaries();
    return @{$boundaries->{'media'}};
}

=item $pdf->default_page_boundaries(%boundaries); # Set

=item %boundaries = $pdf->default_page_boundaries(); # Get

Set default prepress page boundaries for pages in the PDF.  If called without
arguments, returns the coordinates of the rectangles describing each of the
supported page boundaries.

See the equivalent C<page_boundaries> method in L<PDF::Builder::Page> for 
details.

=cut

# Called by PDF::Builder::Page::boundaries via the default_page_* methods below
sub _bounding_box {
    my $self = shift();
    my $type = shift();

    # Get
    unless (scalar @_) {
        unless ($self->{'pages'}->{$type}) {
            return if $type eq 'MediaBox';

            # Use defaults per PDF 1.7 section 14.11.2 Page Boundaries
            return $self->_bounding_box('MediaBox') if $type eq 'CropBox';
            return $self->_bounding_box('CropBox');
        }
        return map { $_->val() } $self->{'pages'}->{$type}->elements();
    }

    # Set
    $self->{'pages'}->{$type} = PDFArray(map { PDFNum(float($_)) } @_);
    return $self;
}

sub default_page_boundaries {
    return PDF::Builder::Page::boundaries(@_);
}

# Deprecated; use default_page_size or default_page_boundaries
# alternate implementations of media, crop, etc. boxes
#sub mediabox {
#    my $self = shift();
#    return $self->_bounding_box('MediaBox') unless @_;
#    return $self->_bounding_box('MediaBox', page_size(@_));
#}

# Deprecated; use default_page_boundaries
#sub cropbox {
#    my $self = shift();
#    return $self->_bounding_box('CropBox') unless @_;
#    return $self->_bounding_box('CropBox', page_size(@_));
#}

# Deprecated; use default_page_boundaries
#sub bleedbox {
#    my $self = shift();
#    return $self->_bounding_box('BleedBox') unless @_;
#    return $self->_bounding_box('BleedBox', page_size(@_));
#}

# Deprecated; use default_page_boundaries
#sub trimbox {
#    my $self = shift();
#    return $self->_bounding_box('TrimBox') unless @_;
#    return $self->_bounding_box('TrimBox', page_size(@_));
#}

# Deprecated; use default_page_boundaries
#sub artbox {
#    my $self = shift();
#    return $self->_bounding_box('ArtBox') unless @_;
#    return $self->_bounding_box('ArtBox', page_size(@_));
#}

=back

=head1 INPUT/OUTPUT METHODS

=over

=item $pdf = PDF::Builder->open($pdf_file, %opts)

Opens an existing PDF file. See C<new()> for options.

B<Example:>

    $pdf = PDF::Builder->open('our/old.pdf');
    ...
    $pdf->saveas('our/new.pdf');

    $pdf = PDF::Builder->open('our/to/be/updated.pdf');
    ...
    $pdf->update();

=cut

sub open {  ## no critic
    my ($class, $file, %opts) = @_;
    croak "File '$file' does not exist" unless -f $file;
    croak "File '$file' is not readable" unless -r $file;

    my $content;
    my $scalar_fh = FileHandle->new();
    CORE::open($scalar_fh, '+<', \$content) or die "Can't begin scalar IO";
    binmode $scalar_fh, ':raw';

    my $disk_fh = FileHandle->new();
    CORE::open($disk_fh, '<', $file) or die "Can't open $file for reading: $!";
    binmode $disk_fh, ':raw';
    $disk_fh->seek(0, 0);
    my $data;
    while (not $disk_fh->eof()) {
        $disk_fh->read($data, 512);
        $scalar_fh->print($data);
    }
    # check if final %%EOF lacks a carriage return on the end (add one)
    if ($data =~ m/%%EOF$/) {
       #print "open() says missing final EOF\n";
        $scalar_fh->print("\n");
    }
    $disk_fh->close();
    $scalar_fh->seek(0, 0);

    my $self = $class->from_string($content, %opts);
    $self->{'pdf'}->{' fname'} = $file;

    return $self;
} # end of open()

=item $pdf = PDF::Builder->from_string($pdf_string, %opts)

Opens a PDF contained in a string. See C<new()> for other options.

=over

=item diags => 1

Display warnings when non-conforming PDF structure is found, and fix up
where possible. See L<PDF::Builder::Basic::PDF::File> for more information.

=back

B<Example:>

    # Read a PDF into a string, for the purpose of demonstration
    open $fh, 'our/old.pdf' or die $@;
    undef $/;  # Read the whole file at once
    $pdf_string = <$fh>;

    $pdf = PDF::Builder->from_string($pdf_string);
    ...
    $pdf->saveas('our/new.pdf');

B<Alternate name:> C<open_scalar>

C<from_string> was formerly known as C<open_scalar> (and even before that,
as C<openScalar>), and this older name is still
valid as an alternative to C<from_string>. It is I<possible> that C<open_scalar>
will be deprecated and then removed some time in the future, so it may be
advisable to use C<from_string> in new work.

=cut

sub open_scalar { return from_string(@_); } ## no critic
sub openScalar { return from_string(@_); } ## no critic

sub from_string {
    my ($class, $content, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-diags'} && !defined $opts{'diags'}) { $opts{'diags'} = delete($opts{'-diags'}); }
    if (defined $opts{'-compress'} && !defined $opts{'compress'}) { $opts{'compress'} = delete($opts{'-compress'}); }
    if (defined $opts{'-diaglevel'} && !defined $opts{'diaglevel'}) { $opts{'diaglevel'} = delete($opts{'-diaglevel'}); }

    my $self = {};
    bless $self, $class;
    foreach my $parameter (keys %opts) {
        $self->default($parameter, $opts{$parameter});
    }

    $self->{'content_ref'} = \$content;
    my $diaglevel = 2;
    if (defined $self->{'diaglevel'}) { $diaglevel = $self->{'diaglevel'}; }
    if ($diaglevel < 0 || $diaglevel > 5) { $diaglevel = 2; }
    my $newVer = $self->IntegrityCheck($diaglevel, $content);
    # if Version override defined in PDF, need to overwrite the %PDF-x.y
    # statement with the new (if higher) value. it's too late to wait until
    # after File->open, as it's already complained about some >1.4 features.
    if (defined $newVer) {
	my ($verStr, $currentVer, $pos);
	$pos = index $content, "%PDF-";
	if ($pos < 0) { die "no PDF version found in PDF input!\n"; }
	# assume major and minor PDF version numbers max 2 digits each for now
	# (are 1 or 2 and 0-7 at this writing)
	$verStr = substr($content, $pos, 10);
	if ($verStr =~ m#^%PDF-(\d+)\.(\d+)#) {
	    $currentVer = "$1.$2";
	} else {
	    die "unable to get PDF input's version number.\n";
        }
        if ($newVer > $currentVer) {
	    if (length($newVer) > length($currentVer)) {
		print STDERR "Unable to update 'content' version because override '$newVer' is longer ".
          "than header version '$currentVer'.\nYou may receive warnings about features ".
          "that bump up the PDF level.\n";
	    } else {
		if (length($newVer) < length($currentVer)) {
		    # unlikely, but cover all the bases
		    $newVer = substr($newVer, 0, length($currentVer));
		} 
	        substr($content, $pos+5, length($newVer)) = $newVer;
		$self->version($newVer);
            }
	}
    }

    my $fh;
    CORE::open($fh, '+<', \$content) or die "Can't begin scalar IO";

    # this would replace any existing self->pdf with a new one
    $self->{'pdf'} = PDF::Builder::Basic::PDF::File->open($fh, 1, %opts);
    $self->{'pdf'}->{'Root'}->realise();
    $self->{'pages'} = $self->{'pdf'}->{'Root'}->{'Pages'}->realise();
    weaken $self->{'pages'};

    $self->{'pdf'}->{' version'} ||= 1.4; # default minimum
    # if version higher than desired output PDF level, give warning and
    # bump up desired output PDF level
    $self->verCheckInput($self->{'pdf'}->{' version'});

    my @pages = _proc_pages($self->{'pdf'}, $self->{'pages'});
    $self->{'pagestack'} = [sort { $a->{' pnum'} <=> $b->{' pnum'} } @pages];
    weaken $self->{'pagestack'}->[$_] for (0 .. scalar @{$self->{'pagestack'}});
    $self->{'catalog'} = $self->{'pdf'}->{'Root'};
    weaken $self->{'catalog'};
    $self->{'opened_scalar'} = 1;
    if (exists $opts{'compress'}) {
      $self->{'forcecompress'} = $opts{'compress'};
      # at this point, no validation of given value! none/flate (0/1).
      # note that >0 is often used as equivalent to 'flate'
    } else {
      $self->{'forcecompress'} = 'flate';
      # code should also allow integers 0 (= 'none') and >0 (= 'flate') 
      # for compatibility with old usage where forcecompress is directly set. 
    }
    if (exists $opts{'diaglevel'}) {
      $self->{'diaglevel'} = $opts{'diaglevel'};
      if ($self->{'diaglevel'} < 0 || $self->{'diaglevel'} > 5) {
        $self->{'diaglevel'} = 2;
      }
    } else {
      $self->{'diaglevel'} = 2;
    }
    $self->{'fonts'} = {};
    $self->{'infoMeta'} = [qw(Author CreationDate ModDate Creator Producer Title Subject Keywords)];

    return $self;
} # end of from_string()

=item $string = $pdf->to_string()

Return the document as a string and remove the object structure from memory.

B<Caution:> Although the object C<$pdf> will still exist, it is no longer
usable for any purpose after invoking this method! You will receive error
messages about "can't call method new_obj on an undefined value".

B<Example:>

    $pdf = PDF::Builder->new();
    ...
    print $pdf->to_string();

B<Alternate name:> C<stringify>

C<to_string> was formerly known as C<stringify>, and this older name is still
valid as an alternative to C<to_string>. It is I<possible> that C<stringify>
will be deprecated and then removed some time in the future, so it may be
advisable to use C<to_string> in new work.

=cut

# Maintainer's note: The object is being destroyed because it contains
# circular references that would otherwise result in memory not being
# freed if the object merely goes out of scope.  If possible, the
# circular references should be eliminated so that to_string doesn't
# need to be destructive. See t/circular-references.t.
#
# I've opted not to just require a separate call to release() because
# it would likely introduce memory leaks in many existing programs
# that use this module.
# - Steve S. (see bug RT 81530)

sub stringify { return to_string(@_); } ## no critic

sub to_string {
    my $self = shift();

    my $string = '';
    # is only set to 1 (within from_string()), otherwise is undef
    if ($self->{'opened_scalar'}) { 
        $self->{'pdf'}->append_file();
        $string = ${$self->{'content_ref'}};
    } else {
        my $fh = FileHandle->new();
        # we should be writing to the STRING $str
        CORE::open($fh, '>', \$string) || die "Can't begin scalar IO";
        $self->{'pdf'}->out_file($fh);
        $fh->close();
    }

    # This can be eliminated once we're confident that circular references are
    # no longer an issue. See t/circular-references.t
    $self->end();

    return $string;
}

=item $pdf->finishobjects(@objects)

Force objects to be written to file if possible.

B<Example:>

    $pdf = PDF::Builder->new(file => 'our/new.pdf');
    ...
    $pdf->finishobjects($page, $gfx, $txt);
    ...
    $pdf->save();

B<Note:> this method is now considered obsolete, and may be deprecated. It
allows for objects to be written to disk in advance of finally
saving and closing the file.  Otherwise, it's no different than just calling
C<save()> when all changes have been made.  There's no memory advantage since
C<ship_out> doesn't remove objects from memory.

=cut

# obsolete, use save instead
#
# This method allows for objects to be written to disk in advance of finally
# saving and closing the file.  Otherwise, it's no different than just calling
# save when all changes have been made.  There's no memory advantage since
# ship_out doesn't remove objects from memory.
sub finishobjects {
    my ($self, @objs) = @_;

    if ($self->{'opened_scalar'}) {
        die "invalid method invocation: no file, use 'saveas' instead.";
    } elsif ($self->{'partial_save'}) {
        $self->{'pdf'}->ship_out(@objs);
    } else {
        die "invalid method invocation: no file, use 'saveas' instead.";
    }

    return;
}

sub _proc_pages {
    my ($pdf, $object) = @_;

    if (defined $object->{'Resources'}) {
        eval {
            $object->{'Resources'}->realise();
        };
    }

    my @pages;
    $pdf->{' apipagecount'} ||= 0;
    foreach my $page ($object->{'Kids'}->elements()) {
        $page->realise();
        if ($page->{'Type'}->val() eq 'Pages') {
            push @pages, _proc_pages($pdf, $page);
        }
        else {
            $pdf->{' apipagecount'}++;
            $page->{' pnum'} = $pdf->{' apipagecount'};
            if (defined $page->{'Resources'}) {
                eval {
                    $page->{'Resources'}->realise();
                };
            }
            push @pages, $page;
        }
    }

    return @pages;
} # end of _proc_pages()

=item $pdf->update()

Saves a previously opened document.

B<Example:>

    $pdf = PDF::Builder->open('our/to/be/updated.pdf');
    ...
    $pdf->update();

B<Note:> it is considered better to simply C<save()> the file, rather than
calling C<update()>. They end up doing the same thing, anyway. This method
may be deprecated in the future.

=cut

# obsolete, use save instead
sub update {
    my $self = shift();
    $self->saveas($self->{'pdf'}->{' fname'});
    return;
}

=item $pdf->saveas($file)

Save the document to $file and remove the object structure from memory.

B<Caution:> Although the object C<$pdf> will still exist, it is no longer
usable for any purpose after invoking this method! You will receive error
messages about "can't call method new_obj on an undefined value".

B<Example:>

    $pdf = PDF::Builder->new();
    ...
    $pdf->saveas('our/new.pdf');

=cut

sub saveas {
    my ($self, $file) = @_;

    if ($self->{'opened_scalar'}) {
        $self->{'pdf'}->append_file();
        my $fh;
        CORE::open($fh, '>', $file) or die "Can't open $file for writing: $!";
        binmode($fh, ':raw');
        print $fh ${$self->{'content_ref'}};
        CORE::close($fh);
    } elsif ($self->{'partial_save'}) {
        $self->{'pdf'}->close_file();
    } else {
        $self->{'pdf'}->out_file($file);
    }

    $self->end();
    return;
}

=item $pdf->save()

=item $pdf->save(filename)

Save the document to an already-defined file (or filename) and 
remove the object structure from memory.
Optionally, a new filename may be given.

B<Caution:> Although the object C<$pdf> will still exist, it is no longer
usable for any purpose after invoking this method! You will receive error
messages about "can't call method new_obj on an undefined value".

B<Example:>

    $pdf = PDF::Builder->new(file => 'file_to_output');
    ...
    $pdf->save();

B<Note:> now that C<save()> can take a filename as an argument, it effectively
is interchangeable with C<saveas()>. This is strictly for compatibility with
recent changes to PDF::API2. Unlike PDF::API2, we are not deprecating
the C<saveas()> method, because in user interfaces, "save" normally means that
the current filename is known and is to be used, while "saveas" normally means
that (whether or not there is a current filename) a new filename is to be used.

=cut

sub save {
    my ($self, $file) = @_;

    if (defined $file) {
	return $self->saveas($file);
    }

    # NOTE: the current PDF::API2 version is quite different, but this may be
    # a consequence of merging save() and saveas(). Let's give this unchanged
    # version a try.
    if      ($self->{'opened_scalar'}) {
        die "Invalid method invocation: use 'saveas' instead of 'save'.";
    } elsif ($self->{'partial_save'}) {
        $self->{'pdf'}->close_file();
    } else {
        die "Invalid method invocation: use 'saveas' instead of 'save'.";
    }

    $self->end();
    return;
}

=item $pdf->close();

Close an open file (if relevant) and remove the object structure from memory.

PDF::API2 contains circular references, so this call is necessary in
long-running processes to keep from running out of memory.

This will be called automatically when you save or stringify a PDF.
You should only need to call it explicitly if you are reading PDF
files and not writing them.

B<Alternate names:> C<release> and C<end>

=cut

=item $pdf->end()

Remove the object structure from memory. PDF::Builder contains circular
references, so this call is necessary in long-running processes to
keep from running out of memory.

This will be called automatically when you save or to_string a PDF.
You should only need to call it explicitly if you are reading PDF
files and not writing them.

This (and I<release>) are older and now deprecated names formerly used in 
PDF::API2 and PDF::Builder. You should try to avoid having to explicitly
call them.

=cut

# Deprecated (renamed)
sub release { return $_[0]->close(); }
sub end     { return $_[0]->close(); }

sub close {
    my $self = shift();
    $self->{'pdf'}->release() if defined $self->{'pdf'};

    foreach my $key (keys %$self) {
        $self->{$key} = undef;
        delete $self->{$key};
    }

    return;
}

=back

=head2 METADATA METHODS

=over

=item $title = $pdf->title();

=item $pdf = $pdf->title($title);

Get/set/clear the document's title.

=cut

sub title {
    my $self = shift();
    return $self->info_metadata('Title', @_);
}

=item $author = $pdf->author();

=item $pdf = $pdf->author($author);

Get/set/clear the name of the person who created the document.

=cut

sub author {
    my $self = shift();
    return $self->info_metadata('Author', @_);
}

=item $subject = $pdf->subject();

=item $pdf = $pdf->subject($subject);

Get/set/clear the subject of the document.

=cut

sub subject {
    my $self = shift();
    return $self->info_metadata('Subject', @_);
}

=item $keywords = $pdf->keywords();

=item $pdf = $pdf->keywords($keywords);

Get/set/clear a space-separated string of keywords associated with the document.

=cut

sub keywords {
    my $self = shift();
    return $self->info_metadata('Keywords', @_);
}

=item $creator = $pdf->creator();

=item $pdf = $pdf->creator($creator);

Get/set/clear the name of the product that created the document prior to its
conversion to PDF.

=cut

sub creator {
    my $self = shift();
    return $self->info_metadata('Creator', @_);
}

=item $producer = $pdf->producer();

=item $pdf = $pdf->producer($producer);

Get/set/clear the name of the product that converted the original document to
PDF.

PDF::Builder fills in this field when creating a PDF.

=cut

sub producer {
    my $self = shift();
    return $self->info_metadata('Producer', @_);
}

=item $date = $pdf->created();

=item $pdf = $pdf->created($date);

Get/set/clear the document's creation date.

The date format is C<D:YYYYMMDDHHmmSSOHH'mm>, where C<D:> is a static prefix
identifying the string as a PDF date.  The date may be truncated at any point
after the year.  C<O> is one of C<+>, C<->, or C<Z>, with the following C<HH'mm>
representing an offset from UTC.

When setting the date, C<D:> will be prepended automatically if omitted.

=cut

sub created {
    my $self = shift();
    return $self->info_metadata('CreationDate', @_);
}

=item $date = $pdf->modified();

=item $pdf = $pdf->modified($date);

Get/set/clear the document's modification date.  The date format is as described
in C<created> above.

=cut

sub modified {
    my $self = shift();
    return $self->info_metadata('ModDate', @_);
}

sub _is_date {
    my $value = shift();

    # PDF 1.7 section 7.9.4 describes the required date format.  Other than the
    # D: prefix and the year, all components are optional but must be present if
    # a later component is present.  No provision is made in the specification
    # for leap seconds, etc.
    return unless $value =~ /^D:([0-9]{4})        # D:YYYY (required)
                             (?:([01][0-9])       # Month (01-12)
                             (?:([0123][0-9])     # Day (01-31)
                             (?:([012][0-9])      # Hour (00-23)
                             (?:([012345][0-9])   # Minute (00-59)
                             (?:([012345][0-9])   # Second (00-59)
                             (?:([Z+-])           # UT Offset Direction
                             (?:([012][0-9])      # UT Offset Hours
                             (?:\'([012345][0-9]) # UT Offset Minutes
                             )?)?)?)?)?)?)?)?$/x;
    my ($year, $month, $day, $hour, $minute, $second, $od, $oh, $om)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9);

    # Do some basic validation to catch accidental date formatting issues.
    # Complete date validation is out of scope.
    if (defined $month) {
        return unless $month >= 1 and $month <= 12;
    }
    if (defined $day) {
        return unless $day >= 1 and $day <= 31;
    }
    if (defined $hour) {
        return unless $hour <= 23;
    }
    if (defined $minute) {
        return unless $minute <= 59;
    }
    if (defined $second) {
        return unless $second <= 59;
    }
    if (defined $od) {
        return if $od eq 'Z' and defined($oh);
    }
    if (defined $oh) {
        return unless $oh <= 23;
    }
    if (defined $om) {
        return unless $om <= 59;
    }

    return 1;
}

=item %info = $pdf->info_metadata(); # Get all keys and values

=item $value = $pdf->info_metadata($key); # Get the value of one key

=item $pdf = $pdf->info_metadata($key, $value); # Set the value of one key

Get/set/clear a key in the document's information dictionary.  The standard keys
(title, author, etc.) have their own accessors, so this is primarily intended
for interacting with custom metadata.

Pass C<undef> as the value in order to remove the key from the dictionary.

=cut

sub info_metadata {
    my $self = shift();
    my $field = shift();

    # Return a hash of the Info table if called without arguments
    unless (defined $field) {
        return unless exists $self->{'pdf'}->{'Info'};
        $self->{'pdf'}->{'Info'}->realise();
        my %info;
        foreach my $key (keys %{$self->{'pdf'}->{'Info'}}) {
            next if $key =~ /^ /;
            next unless defined $self->{'pdf'}->{'Info'}->{$key};
            $info{$key} = $self->{'pdf'}->{'Info'}->{$key}->val();
        }
        return %info;
    }

    # Set
    if (@_) {
        my $value = shift();
        $value = undef if defined($value) and not length($value);

        if ($field eq 'CreationDate' or $field eq 'ModDate') {
            if (defined ($value)) {
                $value = 'D:' . $value unless $value =~ /^D:/;
                croak "Invalid date string: $value" unless _is_date($value);
            }
        }

        unless (exists $self->{'pdf'}->{'Info'}) {
            return $self unless defined $value;
            $self->{'pdf'}->{'Info'} = PDFDict();
            $self->{'pdf'}->new_obj($self->{'pdf'}->{'Info'});
        }
        else {
            $self->{'pdf'}->{'Info'}->realise();
        }

        if (defined $value) {
            $self->{'pdf'}->{'Info'}->{$field} = PDFStr($value);
        }
        else {
            delete $self->{'pdf'}->{'Info'}->{$field};
        }

        return $self;
    }

    # Get
    return unless $self->{'pdf'}->{'Info'};
    $self->{'pdf'}->{'Info'}->realise();
    return unless $self->{'pdf'}->{'Info'}->{$field};
    return $self->{'pdf'}->{'Info'}->{$field}->val();
}

=item %infohash = $pdf->info()

=item %infohash = $pdf->info(%infohash)

Gets/sets the info structure of the document.

See L<PDF::Builder::Docs/info Example> section for an example of the use
of this method.

B<Note:> this method is still available, for compatibility purposes. It is
better to use individual accessors or C<info_metadata> instead.

=cut

sub info {
    my ($self, %opt) = @_;

    if (not defined($self->{'pdf'}->{'Info'})) {
        $self->{'pdf'}->{'Info'} = PDFDict();
        $self->{'pdf'}->new_obj($self->{'pdf'}->{'Info'});
    } else {
        $self->{'pdf'}->{'Info'}->realise();
    }

    # Maintenance Note: Since we're not shifting at the beginning of
    # this sub, this "if" will always be true
    if (scalar @_) {
        foreach my $k (@{$self->{'infoMeta'}}) {
            next unless defined $opt{$k};
            $self->{'pdf'}->{'Info'}->{$k} = PDFString($opt{$k} || 'NONE', 'm');
        }
        $self->{'pdf'}->out_obj($self->{'pdf'}->{'Info'});
    }

    if (defined $self->{'pdf'}->{'Info'}) {
        %opt = ();
        foreach my $k (@{$self->{'infoMeta'}}) {
            next unless defined $self->{'pdf'}->{'Info'}->{$k};
            $opt{$k} = $self->{'pdf'}->{'Info'}->{$k}->val();
            if ((unpack('n', $opt{$k}) == 0xfffe) or (unpack('n', $opt{$k}) == 0xfeff)) {
                $opt{$k} = decode('UTF-16', $self->{'pdf'}->{'Info'}->{$k}->val());
            }
        }
    }

    return %opt;
} # end of info()

=item @metadata_attributes = $pdf->infoMetaAttributes()

=item @metadata_attributes = $pdf->infoMetaAttributes(@metadata_attributes)

Gets/sets the supported info-structure tags.

B<Example:>

    @attributes = $pdf->infoMetaAttributes;
    print "Supported Attributes: @attr\n";

    @attributes = $pdf->infoMetaAttributes('CustomField1');
    print "Supported Attributes: @attributes\n";

B<Note:> this method is still available for compatibility purposes, but the
use of C<info_metadata> instead is encouraged.

=cut

sub infoMetaAttributes {
    my ($self, @attr) = @_;

    if (scalar @attr) {
        my %at = map { $_ => 1 } @{$self->{'infoMeta'}}, @attr;
        @{$self->{'infoMeta'}} = keys %at;
    }

    return @{$self->{'infoMeta'}};
}

=item $xml = $pdf->xml_metadata();

=item $pdf = $pdf->xml_metadata($xml);

Gets/sets the document's XML metadata stream.

=cut

sub xml_metadata {
    my ($self, $value) = @_;

    if (not defined($self->{'catalog'}->{'Metadata'})) {
        $self->{'catalog'}->{'Metadata'} = PDFDict();
        $self->{'catalog'}->{'Metadata'}->{'Type'} = PDFName('Metadata');
        $self->{'catalog'}->{'Metadata'}->{'Subtype'} = PDFName('XML');
        $self->{'pdf'}->new_obj($self->{'catalog'}->{'Metadata'});
    }
    else {
        $self->{'catalog'}->{'Metadata'}->realise();
        $self->{'catalog'}->{'Metadata'}->{' stream'} = unfilter($self->{'catalog'}->{'Metadata'}->{'Filter'}, $self->{'catalog'}->{'Metadata'}->{' stream'});
        delete $self->{'catalog'}->{'Metadata'}->{' nofilt'};
        delete $self->{'catalog'}->{'Metadata'}->{'Filter'};
    }

    my $md = $self->{'catalog'}->{'Metadata'};

    if (defined $value) {
        $md->{' stream'} = $value;
        delete $md->{'Filter'};
        delete $md->{' nofilt'};
        $self->{'pdf'}->out_obj($md);
        $self->{'pdf'}->out_obj($self->{'catalog'});
    }

    return $md->{' stream'};
}

=item $xml = $pdf->xmpMetadata()  # Get

=item $xml = $pdf->xmpMetadata($xml)  # Set (also returns $xml value)

Gets/sets the XMP XML data stream.

See L<PDF::Builder::Docs/XMP XML example> section for an example of the use
of this method.

This method is considered B<obsolete>. Use C<xml_metadata> instead.

=cut

sub xmpMetadata {
    my ($self, $value) = @_;

    if (@_) {  # Set
        my $value = shift();
        $self->xml_metadata($value);
        return $value;
    }

    # Get
    return $self->xml_metadata();
} 

=item $val = $pdf->default($parameter)

=item $pdf->default($parameter, $value)

Gets/sets the default value for a behavior of PDF::Builder.

B<Supported Parameters:>

=over

=item nounrotate

prohibits Builder from rotating imported/opened page to re-create a
default pdf-context.

=item pageencaps

enables Builder's adding save/restore commands upon importing/opening
pages to preserve graphics-state for modification.

=item copyannots

enables importing of annotations (B<*EXPERIMENTAL*>).

=back

B<CAUTION:> Perl::Critic (tools/1_pc.pl) has started flagging the name 
"default" as a reserved keyword in higher Perl versions. Use with caution, and
be aware that this name I<may> have to be changed in the future.

=cut

sub default {
    my ($self, $parameter, $value) = @_;

    # Parameter names may consist of lowercase letters, numbers, and underscores
    $parameter = lc $parameter;
    $parameter =~ s/[^a-z\d_]//g;

    my $previous_value = $self->{$parameter};
    if (defined $value) {
        $self->{$parameter} = $value;
    }

    return $previous_value;
}

=item $version = $pdf->version() # Get

=item $version = $pdf->version($version) # Set (also returns newly set version)

Gets/sets the PDF version (e.g., 1.5). 
For compatibility with earlier releases, if no decimal point is given, assume
"1." precedes the number given.

A warning message is given if you attempt to I<decrease> the PDF version, as you
might have already read in a higher level file, or used a higher level feature.

See L<PDF::Builder::Basic::PDF::File> for additional information on the
C<version> method.

=cut

sub version {
    my $self = shift();  # includes any %opts

    return $self->{'pdf'}->version(@_); # just pass it over to the "real" one
}

# when outputting a PDF feature, verCheckOutput(n, 'feature name') returns TRUE 
# if n > $pdf->{' version'), plus a warning message. It returns FALSE otherwise.
#
#  a typical use:
#
#  $PDF::Builder::global_pdf->verCheckOutput(1.6, "portzebie with foo-dangle");
#
#  if msgver defaults to 1, a message will be output if the output PDF version 
#  has to be increased to 1.6 in order to use the "portzebie" feature
#
# this is still somewhat experimental, and as experience is gained, the code 
# might have to be modified.
#
sub verCheckOutput {
    my ($self, $PDFver, $featureName) = @_;

    # check if feature required PDF version is higher than planned output
    my $version = $self->version(); # current version
    if ($PDFver > $version) {
        if ($msgVer) {
	    print "PDF version of requested feature '$featureName' is higher\n".                  "  than current output version $version ".
                  "(version reset to $PDFver)\n";
	}
        $self->version($PDFver);
        return 1;
    } else {
        return 0;
    }
}

# when reading in a PDF, verCheckInput(n) gives a warning message if n (the PDF 
# version just read in) > version, and resets version to n. return TRUE if 
# version changed, FALSE otherwise.
#
# this is still somewhat experimental, and as experience is gained, the code 
# might have to be modified.
#
#    WARNING: just because the PDF output version has been increased does NOT 
#    guarantee that any particular content will be handled correctly! There are 
#    many known cases of PDF 1.5 and up files being read in, that have content 
#    that PDF::Builder does not handle correctly, corrupting the resulting PDF. 
#    Pay attention to run-time warning messages that the PDF output level has 
#    been increased due to a PDF file being read in, and check the resulting 
#    file carefully.

sub verCheckInput {
    my ($self, $PDFver) = @_;

    my $version = $self->version();
    # warning message and bump up version if read-in PDF level higher
    if ($PDFver > $version) {
        if ($msgVer) {
	    print "PDF version just read in is higher than version of $version (version reset to $PDFver)\n";
	}
        $self->version($PDFver);
        return 1;
    } else {
        return 0;
    }
}

=item $bool = $pdf->is_encrypted()

Checks if the previously opened PDF is encrypted.

B<Alternate name:> C<isEncrypted>

This is the older name; it is kept for compatibility with PDF::API2.

=cut

sub isEncrypted { return is_encrypted(@_); } ## no critic

sub is_encrypted {
    my $self = shift();
    return defined($self->{'pdf'}->{'Encrypt'}) ? 1 : 0;
}

=back

=head1 INTERACTIVE FEATURE METHODS

=over

=item $otls = $pdf->outline()

Creates (if needed) and returns the document's 'outline' tree, which is also 
known as its 'bookmarks' or the 'table of contents', depending on the 
PDF reader being used.

To examine or modify the outline tree, see L<PDF::Builder::Outlines>.

B<Alternate name:> C<outlines>

This is the older name; it is kept for compatibility.

=cut

sub outlines { return outline(@_); } ## no critic

sub outline {
    my $self = shift();

    require PDF::Builder::Outlines;
    my $obj = $self->{'pdf'}->{'Root'}->{'Outlines'};
    if ($obj) {
	$obj->realise();
        bless $obj, 'PDF::Builder::Outlines';
        $obj->{' api'} = $self;
        weaken $obj->{' api'};
    } else {
	$obj = PDF::Builder::Outlines->new($self);

	$self->{'pdf'}->{'Root'}->{'Outlines'} = $obj;
        $self->{'pdf'}->new_obj($obj) unless $obj->is_obj($self->{'pdf'});
        $self->{'pdf'}->out_obj($obj);
        $self->{'pdf'}->out_obj($self->{'pdf'}->{'Root'});
    }
    return $obj;
}

=item $pdf = $pdf->open_action($page, $location, @args);

Set the destination in the PDF that should be displayed when the document is
opened.

C<$page> may be either a page number or a page object.  The other parameters are
as described in L<PDF::Builder::NamedDestination>.

This has been split out from C<preferences()> for compatibility with PDF::API2.
It also can both set (assign) and get (query) the settings used.

=cut

sub open_action {
    my ($self, $page, @args) = @_;

    # $page can be either a page number or a page object
    $page = PDFNum($page) unless ref($page);

    require PDF::Builder::NamedDestination;
    my $array = PDF::Builder::NamedDestination::_destination($page, @args);
    $self->{'catalog'}->{'OpenAction'} = $array;
    $self->{'pdf'}->out_obj($self->{'catalog'});
    return $self;
}

=item $layout = $pdf->page_layout();

=item $pdf = $pdf->page_layout($layout);

Gets/sets the page layout that should be used when the PDF is opened.

C<$layout> is one of the following:

=over

=item single_page (or undef)

Display one page at a time.

=item one_column

Display the pages in one column (a.k.a. continuous).

=item two_column_left

Display the pages in two columns, with odd-numbered pages on the left.

=item two_column_right

Display the pages in two columns, with odd-numbered pages on the right.

=item two_page_left

Display two pages at a time, with odd-numbered pages on the left.

=item two_page_right

Display two pages at a time, with odd-numbered pages on the right.

=back

This has been split out from C<preferences()> for compatibility with PDF::API2.
It also can both set (assign) and get (query) the settings used.

=cut

sub page_layout {
    my $self = shift();

    unless (@_) {
        return 'single_page' unless $self->{'catalog'}->{'PageLayout'};
        my $layout = $self->{'catalog'}->{'PageLayout'}->val();
        return 'single_page' if $layout eq 'SinglePage';
        return 'one_column' if $layout eq 'OneColumn';
        return 'two_column_left' if $layout eq 'TwoColumnLeft';
        return 'two_column_right' if $layout eq 'TwoColumnRight';
        return 'two_page_left'  if $layout eq 'TwoPageLeft';
        return 'two_page_right' if $layout eq 'TwoPageRight';
        warn "Unknown page layout: $layout";
        return $layout;
    }

    my $name = shift() // 'single_page';
    my $layout = ($name eq 'single_page'      ? 'SinglePage'     :
                  $name eq 'one_column'       ? 'OneColumn'      :
                  $name eq 'two_column_left'  ? 'TwoColumnLeft'  :
                  $name eq 'two_column_right' ? 'TwoColumnRight' :
                  $name eq 'two_page_left'    ? 'TwoPageLeft'    :
                  $name eq 'two_page_right'   ? 'TwoPageRight'   : '');

    croak "Invalid page layout: $name" unless $layout;
    $self->{'catalog'}->{'PageMode'} = PDFName($layout);
    $self->{'pdf'}->out_obj($self->{'catalog'});
    return $self;
}

=item $mode = $pdf->page_mode(); # Get

=item $pdf = $pdf->page_mode($mode); # Set

Gets/sets the page mode, which describes how the PDF should be displayed when
opened.

C<$mode> is one of the following:

=over

=item none (or undef)

Neither outlines nor thumbnails should be displayed.

=item outlines

Show the document outline.

=item thumbnails

Show the page thumbnails.

=item full_screen

Open in full-screen mode, with no menu bar, window controls, or any other window
visible.

=item optional_content

Show the optional content group panel.

=item attachments

Show the attachments panel.

=back

This has been split out from C<preferences()> for compatibility with PDF::API2.
It also can both set (assign) and get (query) the settings used.

=cut

sub page_mode {
    my $self = shift();

    unless (@_) {
        return 'none' unless $self->{'catalog'}->{'PageMode'};
        my $mode = $self->{'catalog'}->{'PageMode'}->val();
        return 'none'             if $mode eq 'UseNone';
        return 'outlines'         if $mode eq 'UseOutlines';
        return 'thumbnails'       if $mode eq 'UseThumbs';
        return 'full_screen'      if $mode eq 'FullScreen';
        return 'optional_content' if $mode eq 'UseOC';
        return 'attachments'      if $mode eq 'UseAttachments';
        warn "Unknown page mode: $mode";
        return $mode;
    }

    my $name = shift() // 'none';
    my $mode = ($name eq 'none'             ? 'UseNone'        :
                $name eq 'outlines'         ? 'UseOutlines'    :
                $name eq 'thumbnails'       ? 'UseThumbs'      :
                $name eq 'full_screen'      ? 'FullScreen'     :
                $name eq 'optional_content' ? 'UseOC'          :
                $name eq 'attachments'      ? 'UseAttachments' : '');

    croak "Invalid page mode: $name" unless $mode;
    $self->{'catalog'}->{'PageMode'} = PDFName($mode);
    $self->{'pdf'}->out_obj($self->{'catalog'});
    return $self;
}

=item %preferences = $pdf->viewer_preferences(); # Get

=item $pdf = $pdf->viewer_preferences(%preferences); # Set

Gets/sets PDF viewer preferences, as described in
L<PDF::Builder::ViewerPreferences>.

This has been split out from C<preferences()> for compatibility with PDF::API2.
It also can both set (assign) and get (query) the settings used.

=cut

sub viewer_preferences {
    my $self = shift();
    require PDF::Builder::ViewerPreferences;
    my $prefs = PDF::Builder::ViewerPreferences->new($self);
    unless (@_) {
        return $prefs->get_preferences();
    }
    return $prefs->set_preferences(@_);
}

=item $pdf->preferences(%opts)

Controls viewing preferences for the PDF, including the B<Page Mode>, 
B<Page Layout>, B<Viewer>, and B<Initial Page> Options. See 
L<PDF::Builder::Docs/Preferences - set user display preferences> for details 
on all these 
option groups, and L<PDF::Builder::Docs/Page Fit Options> for page positioning.

B<Note:> the various preferences have been split out into their own methods.
It is preferred that you use these specific methods.

=cut

sub preferences {
    my ($self, %opts) = @_;
    # copy dashed option names to the preferred undashed format
    # Page Mode Options
    if (defined $opts{'-fullscreen'} && !defined $opts{'fullscreen'}) { $opts{'fullscreen'} = delete($opts{'-fullscreen'}); }
    if (defined $opts{'-thumbs'} && !defined $opts{'thumbs'}) { $opts{'thumbs'} = delete($opts{'-thumbs'}); }
    if (defined $opts{'-outlines'} && !defined $opts{'outlines'}) { $opts{'outlines'} = delete($opts{'-outlines'}); }
    # Page Layout Options
    if (defined $opts{'-singlepage'} && !defined $opts{'singlepage'}) { $opts{'singlepage'} = delete($opts{'-singlepage'}); }
    if (defined $opts{'-onecolumn'} && !defined $opts{'onecolumn'}) { $opts{'onecolumn'} = delete($opts{'-onecolumn'}); }
    if (defined $opts{'-twocolumnleft'} && !defined $opts{'twocolumnleft'}) { $opts{'twocolumnleft'} = delete($opts{'-twocolumnleft'}); }
    if (defined $opts{'-twocolumnright'} && !defined $opts{'twocolumnright'}) { $opts{'twocolumnright'} = delete($opts{'-twocolumnright'}); }
    # Viewer Preferences
    if (defined $opts{'-hidetoolbar'} && !defined $opts{'hidetoolbar'}) { $opts{'hidetoolbar'} = delete($opts{'-hidetoolbar'}); }
    if (defined $opts{'-hidemenubar'} && !defined $opts{'hidemenubar'}) { $opts{'hidemenubar'} = delete($opts{'-hidemenubar'}); }
    if (defined $opts{'-hidewindowui'} && !defined $opts{'hidewindowui'}) { $opts{'hidewindowui'} = delete($opts{'-hidewindowui'}); }
    if (defined $opts{'-fitwindow'} && !defined $opts{'fitwindow'}) { $opts{'fitwindow'} = delete($opts{'-fitwindow'}); }
    if (defined $opts{'-centerwindow'} && !defined $opts{'centerwindow'}) { $opts{'centerwindow'} = delete($opts{'-centerwindow'}); }
    if (defined $opts{'-displaytitle'} && !defined $opts{'displaytitle'}) { $opts{'displaytitle'} = delete($opts{'-displaytitle'}); }
    if (defined $opts{'-righttoleft'} && !defined $opts{'righttoleft'}) { $opts{'righttoleft'} = delete($opts{'-righttoleft'}); }
    if (defined $opts{'-afterfullscreenthumbs'} && !defined $opts{'afterfullscreenthumbs'}) { $opts{'afterfullscreenthumbs'} = delete($opts{'-afterfullscreenthumbs'}); }
    if (defined $opts{'-afterfullscreenoutlines'} && !defined $opts{'afterfullscreenoutlines'}) { $opts{'afterfullscreenoutlines'} = delete($opts{'-afterfullscreenoutlines'}); }
    if (defined $opts{'-printscalingnone'} && !defined $opts{'printscalingnone'}) { $opts{'printscalingnone'} = delete($opts{'-printscalingnone'}); }
    if (defined $opts{'-simplex'} && !defined $opts{'simplex'}) { $opts{'simplex'} = delete($opts{'-simplex'}); }
    if (defined $opts{'-duplexfliplongedge'} && !defined $opts{'duplexfliplongedge'}) { $opts{'duplexfliplongedge'} = delete($opts{'-duplexfliplongedge'}); }
    if (defined $opts{'-duplexflipshortedge'} && !defined $opts{'duplexflipshortedge'}) { $opts{'duplexflipshortedge'} = delete($opts{'-duplexflipshortedge'}); }
    # Open Action
    if (defined $opts{'-firstpage'} && !defined $opts{'firstpage'}) { $opts{'firstpage'} = delete($opts{'-firstpage'}); }
    if (defined $opts{'-fit'} && !defined $opts{'fit'}) { $opts{'fit'} = delete($opts{'-fit'}); }
    if (defined $opts{'-fith'} && !defined $opts{'fith'}) { $opts{'fith'} = delete($opts{'-fith'}); }
    if (defined $opts{'-fitb'} && !defined $opts{'fitb'}) { $opts{'fitb'} = delete($opts{'-fitb'}); }
    if (defined $opts{'-fitbh'} && !defined $opts{'fitbh'}) { $opts{'fitbh'} = delete($opts{'-fitbh'}); }
    if (defined $opts{'-fitv'} && !defined $opts{'fitv'}) { $opts{'fitv'} = delete($opts{'-fitv'}); }
    if (defined $opts{'-fitbv'} && !defined $opts{'fitbv'}) { $opts{'fitbv'} = delete($opts{'-fitbv'}); }
    if (defined $opts{'-fitr'} && !defined $opts{'fitr'}) { $opts{'fitr'} = delete($opts{'-fitr'}); }
    if (defined $opts{'-xyz'} && !defined $opts{'xyz'}) { $opts{'xyz'} = delete($opts{'-xyz'}); }

    # Page Mode Options
    if      ($opts{'fullscreen'}) {
        $self->{'catalog'}->{'PageMode'} = PDFName('FullScreen');
    } elsif ($opts{'thumbs'}) {
        $self->{'catalog'}->{'PageMode'} = PDFName('UseThumbs');
    } elsif ($opts{'outlines'}) {
        $self->{'catalog'}->{'PageMode'} = PDFName('UseOutlines');
    } else {
        $self->{'catalog'}->{'PageMode'} = PDFName('UseNone');
    }

    # Page Layout Options
    if      ($opts{'singlepage'}) {
        $self->{'catalog'}->{'PageLayout'} = PDFName('SinglePage');
    } elsif ($opts{'onecolumn'}) {
        $self->{'catalog'}->{'PageLayout'} = PDFName('OneColumn');
    } elsif ($opts{'twocolumnleft'}) {
        $self->{'catalog'}->{'PageLayout'} = PDFName('TwoColumnLeft');
    } elsif ($opts{'twocolumnright'}) {
        $self->{'catalog'}->{'PageLayout'} = PDFName('TwoColumnRight');
    } else {
        $self->{'catalog'}->{'PageLayout'} = PDFName('SinglePage');
    }

    # Viewer Preferences
    $self->{'catalog'}->{'ViewerPreferences'} ||= PDFDict();
    $self->{'catalog'}->{'ViewerPreferences'}->realise();

    if ($opts{'hidetoolbar'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'HideToolbar'} = PDFBool(1);
    }
    if ($opts{'hidemenubar'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'HideMenubar'} = PDFBool(1);
    }
    if ($opts{'hidewindowui'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'HideWindowUI'} = PDFBool(1);
    }
    if ($opts{'fitwindow'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'FitWindow'} = PDFBool(1);
    }
    if ($opts{'centerwindow'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'CenterWindow'} = PDFBool(1);
    }
    if ($opts{'displaytitle'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'DisplayDocTitle'} = PDFBool(1);
    }
    if ($opts{'righttoleft'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'Direction'} = PDFName('R2L');
    }

    if      ($opts{'afterfullscreenthumbs'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'NonFullScreenPageMode'} = PDFName('UseThumbs');
    } elsif ($opts{'afterfullscreenoutlines'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'NonFullScreenPageMode'} = PDFName('UseOutlines');
    } else {
        $self->{'catalog'}->{'ViewerPreferences'}->{'NonFullScreenPageMode'} = PDFName('UseNone');
    }

    if ($opts{'printscalingnone'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'PrintScaling'} = PDFName('None');
    }

    if      ($opts{'simplex'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'Duplex'} = PDFName('Simplex');
    } elsif ($opts{'duplexfliplongedge'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'Duplex'} = PDFName('DuplexFlipLongEdge');
    } elsif ($opts{'duplexflipshortedge'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'Duplex'} = PDFName('DuplexFlipShortEdge');
    }

    # Open Action
    if ($opts{'firstpage'}) {
        my ($page, %args) = @{$opts{'firstpage'}};
        $args{'fit'} = 1 unless scalar keys %args;

        # $page can be either a page number (which needs to be wrapped
        # in PDFNum) or a page object (which doesn't).
        $page = PDFNum($page) unless ref($page);

	# copy dashed args names to preferred undashed names
	if (defined $args{'-fit'} && !defined $args{'fit'}) { $args{'fit'} = delete($args{'-fit'}); }
	if (defined $args{'-fith'} && !defined $args{'fith'}) { $args{'fith'} = delete($args{'-fith'}); }
	if (defined $args{'-fitb'} && !defined $args{'fitb'}) { $args{'fitb'} = delete($args{'-fitb'}); }
	if (defined $args{'-fitbh'} && !defined $args{'fitbh'}) { $args{'fitbh'} = delete($args{'-fitbh'}); }
	if (defined $args{'-fitv'} && !defined $args{'fitv'}) { $args{'fitv'} = delete($args{'-fitv'}); }
	if (defined $args{'-fitbv'} && !defined $args{'fitbv'}) { $args{'fitbv'} = delete($args{'-fitbv'}); }
	if (defined $args{'-fitr'} && !defined $args{'fitr'}) { $args{'fitr'} = delete($args{'-fitr'}); }
	if (defined $args{'-xyz'} && !defined $args{'xyz'}) { $args{'xyz'} = delete($args{'-xyz'}); }
	
        if      (defined $args{'fit'}) {
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('Fit'));
        } elsif (defined $args{'fith'}) {
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('FitH'), PDFNum($args{'fith'}));
        } elsif (defined $args{'fitb'}) {
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('FitB'));
        } elsif (defined $args{'fitbh'}) {
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('FitBH'), PDFNum($args{'fitbh'}));
        } elsif (defined $args{'fitv'}) {
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('FitV'), PDFNum($args{'fitv'}));
        } elsif (defined $args{'fitbv'}) {
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('FitBV'), PDFNum($args{'fitbv'}));
        } elsif (defined $args{'fitr'}) {
            croak 'insufficient parameters to fitr => []' unless scalar @{$args{'fitr'}} == 4;
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('FitR'), 
                map { PDFNum($_) } @{$args{'fitr'}});
        } elsif (defined $args{'xyz'}) {
            croak 'insufficient parameters to xyz => []' unless scalar @{$args{'xyz'}} == 3;
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('XYZ'), 
                map { PDFNum($_) } @{$args{'xyz'}});
        }
    }
    $self->{'pdf'}->out_obj($self->{'catalog'});

    return $self;
}  # end of preferences()

sub proc_pages {
    my ($pdf, $object) = @_;

    if (defined $object->{'Resources'}) {
        eval {
            $object->{'Resources'}->realise();
        };
    }

    my @pages;
    $pdf->{' apipagecount'} ||= 0;
    foreach my $page ($object->{'Kids'}->elements()) {
        $page->realise();
        if ($page->{'Type'}->val() eq 'Pages') {
            push @pages, proc_pages($pdf, $page);
        }
        else {
            $pdf->{' apipagecount'}++;
            $page->{' pnum'} = $pdf->{' apipagecount'};
            if (defined $page->{'Resources'}) {
                eval {
                    $page->{'Resources'}->realise();
                };
            }
            push @pages, $page;
        }
    }

    return @pages;
}

=back

=head1 PAGE METHODS

=over

=item $page = $pdf->page()

=item $page = $pdf->page($page_number)

Returns a I<new> page object.  By default, the page is added to the end
of the document.  If you give an existing page number, the new page
will be inserted in that position, pushing existing pages back by 1 (e.g., 
C<page(5)> would insert an empty page 5, with the old page 5 now page 6,
etc.

If $page_number is -1, the new page is inserted as the second-to-last page;
if $page_number is 0, the new page is inserted as the last page.

B<Example:>

    $pdf = PDF::Builder->new();

    # Add a page.  This becomes page 1.
    $page = $pdf->page();

    # Add a new first page.  $page becomes page 2.
    $another_page = $pdf->page(1);

=cut

sub page {
    my $self = shift();
    my $index = shift() || 0;  # default to new "last" page
    my $page;

    if ($index == 0) {
        $page = PDF::Builder::Page->new($self->{'pdf'}, $self->{'pages'});
    } else {
        $page = PDF::Builder::Page->new($self->{'pdf'}, $self->{'pages'}, $index-1);
    }
    $page->{' apipdf'} = $self->{'pdf'};
    $page->{' api'} = $self;
    weaken $page->{' apipdf'};
    weaken $page->{' api'};
    $self->{'pdf'}->out_obj($page);
    $self->{'pdf'}->out_obj($self->{'pages'});
    if ($index == 0) {
        push @{$self->{'pagestack'}}, $page;
        weaken $self->{'pagestack'}->[-1];
    } elsif ($index < 0) {
        splice @{$self->{'pagestack'}}, $index, 0, $page;
        weaken $self->{'pagestack'}->[$index];
    } else {
        splice @{$self->{'pagestack'}}, $index-1, 0, $page;
        weaken $self->{'pagestack'}->[$index - 1];
    }

    #   $page->{'Resources'}=$self->{'pages'}->{'Resources'};
    return $page;
} # end of page()

=item $page = $pdf->open_page($page_number)

Returns the L<PDF::Builder::Page> object of page $page_number.
This is similar to C<< $page = $pdf->page() >>, except that C<$page> is 
I<not> a new, empty page; but contains the contents of that existing page.

If $page_number is 0 or -1, it will return the last page in the
document.

B<Example:>

    $pdf  = PDF::Builder->open('our/99page.pdf');
    $page = $pdf->open_page(1);   # returns the first page
    $page = $pdf->open_page(99);  # returns the last page
    $page = $pdf->open_page(-1);  # returns the last page
    $page = $pdf->open_page(999); # returns undef

B<Alternate name:> C<openpage>

This is the older name; it is kept for compatibility until after June 2023
(deprecated, as previously announced).

=cut

sub openpage { return open_page(@_); } ## no critic

sub open_page {
    my $self = shift();
    my $index = shift() || 0;
    my ($page, $rotate, $media, $trans);

    if ($index == 0) {
        $page = $self->{'pagestack'}->[-1];
    } elsif ($index < 0) {
        $page = $self->{'pagestack'}->[$index];
    } else {
        $page = $self->{'pagestack'}->[$index - 1];
    }
    return unless ref($page);

    if (ref($page) ne 'PDF::Builder::Page') {
        bless $page, 'PDF::Builder::Page';
        $page->{' apipdf'} = $self->{'pdf'};
        $page->{' api'} = $self;
        weaken $page->{' apipdf'};
        weaken $page->{' api'};
        $self->{'pdf'}->out_obj($page);
        if (($rotate = $page->find_prop('Rotate')) and not $page->{' opened'}) {
            $rotate = ($rotate->val() + 360) % 360;

            if ($rotate != 0 and not $self->default('nounrotate')) {
                $page->{'Rotate'} = PDFNum(0);
                foreach my $mediatype (qw(MediaBox CropBox BleedBox TrimBox ArtBox)) {
                    if ($media = $page->find_prop($mediatype)) {
                        $media = [ map { $_->val() } $media->elements() ];
                    } else {
                        $media = [0, 0, 612, 792]; # US Letter default
                        next if $mediatype ne 'MediaBox';
                    }
                    if ($rotate == 90) {
                        $trans = "0 -1 1 0 0 $media->[2] cm" if $mediatype eq 'MediaBox';
                        $media = [$media->[1], $media->[0], $media->[3], $media->[2]];
                    } elsif ($rotate == 180) {
                        $trans = "-1 0 0 -1 $media->[2] $media->[3] cm" if $mediatype eq 'MediaBox';
                    } elsif ($rotate == 270) {
                        $trans = "0 1 -1 0 $media->[3] 0 cm" if $mediatype eq 'MediaBox';
                        $media = [$media->[1], $media->[0], $media->[3], $media->[2]];
                    }
                    $page->{$mediatype} = PDFArray(map { PDFNum($_) } @$media);
                }
            } else {
                $trans = '';
            }
        } else {
            $trans = '';
        }

        if (defined $page->{'Contents'} and not $page->{' opened'}) {
            $page->fixcontents();
            my $uncontent = delete $page->{'Contents'};
            my $content = $page->gfx();
            $content->add(" $trans ");

            if ($self->default('pageencaps')) {
                $content->{' stream'} .= ' q ';
            }
            foreach my $k ($uncontent->elements()) {
                $k->realise();
                $content->{' stream'} .= ' ' . unfilter($k->{'Filter'}, $k->{' stream'}) . ' ';
            }
            if ($self->default('pageencaps')) {
                $content->{' stream'} .= ' Q ';
            }

            # if we like compress we will do it now to do quicker saves
            if ($self->{'forcecompress'} eq 'flate' || 
                $self->{'forcecompress'} =~ m/^[1-9]\d*$/) {
                $content->{' stream'} = dofilter($content->{'Filter'}, $content->{' stream'});
                $content->{' nofilt'} = 1;
                delete $content->{'-docompress'};
                $content->{'Length'} = PDFNum(length($content->{' stream'}));
            }
        }
        $page->{' opened'} = 1;
    }

    $self->{'pdf'}->out_obj($page);
    $self->{'pdf'}->out_obj($self->{'pages'});
    $page->{' apipdf'} = $self->{'pdf'};
    $page->{' api'} = $self;
    weaken $page->{' apipdf'};
    weaken $page->{' api'};

    return $page;
} # end of open_page()

=item $page = $pdf->import_page($source_pdf)

=item $page = $pdf->import_page($source_pdf, $source_page_number)

=item $page = $pdf->import_page($source_pdf, $source_page_number, $target_page_number)

=item $page = $pdf->import_page($source_pdf, $source_page_number, $target_page_object)

Imports a page from $source_pdf and adds it to the specified position
in $pdf.

If the C<$source_page_number> is omitted, 0, or -1; the last page of the 
source is imported.
If the C<$target_page_number> is omitted, 0, or -1; the imported page will be
placed as the new last page of the target (C<$pdf>).
Otherwise, as with the C<page()> method, the page will be inserted before an 
existing page of that number.

B<Note:> If you pass a page I<object> instead of a page I<number> for
C<$target_page_number>, the contents of the page will be B<merged> into the
existing page.

B<Example:>

    my $pdf = PDF::Builder->new();
    my $source = PDF::Builder->open('source.pdf');

    # Add page 2 from the old PDF as page 1 of the new PDF
    my $page = $pdf->import_page($source, 2);

    $pdf->saveas('sample.pdf');

B<Note:> You can only import a page from an existing PDF file.

=cut

# removed years ago, but is still in API2, so for code compatibility...
sub importpage{ return import_page(@_); } ## no critic

sub import_page {
    my ($self, $s_pdf, $s_idx, $t_idx) = @_;

    $s_idx ||= 0;  # default to last page
    $t_idx ||= 0;  # default to last page
    my ($s_page, $t_page);

    unless (ref($s_pdf) and $s_pdf->isa('PDF::Builder')) {
        die "Invalid usage: first argument must be PDF::Builder instance, not: " . ref($s_pdf);
    }

    if (ref($s_idx) eq 'PDF::Builder::Page') {
        $s_page = $s_idx;
    } else {
        $s_page = $s_pdf->open_page($s_idx);
	die "Unable to open page '$s_idx' in source PDF" unless defined $s_page;
    }

    if (ref($t_idx) eq 'PDF::Builder::Page') {
        $t_page = $t_idx;
    } else {
        if ($self->pages() < $t_idx) {
            $t_page = $self->page();
        } else {
            $t_page = $self->page($t_idx);
        }
    }

    $self->{'apiimportcache'} = $self->{'apiimportcache'} || {};
    $self->{'apiimportcache'}->{$s_pdf} = $self->{'apiimportcache'}->{$s_pdf} || {};

    # we now import into a form to keep
    # all those nasty resources from polluting
    # our very own resource naming space.
    my $xo = $self->importPageIntoForm($s_pdf, $s_page);

    # copy all page dimensions
    foreach my $k (qw(MediaBox ArtBox TrimBox BleedBox CropBox)) {
        my $prop = $s_page->find_prop($k);
        next unless defined $prop;

        my $box = _walk_obj({}, $s_pdf->{'pdf'}, $self->{'pdf'}, $prop);
        my $method = lc $k;

        $t_page->$method(map { $_->val() } $box->elements());
    }

    $t_page->gfx()->formimage($xo, 0, 0, 1);

    # copy annotations and/or form elements as well
    if (exists $s_page->{'Annots'} and $s_page->{'Annots'} and $self->{'copyannots'}) {
        # first set up the AcroForm, if required
        my $AcroForm;
        if (my $a = $s_pdf->{'pdf'}->{'Root'}->realise()->{'AcroForm'}) {
            $a->realise();

            $AcroForm = _walk_obj({}, $s_pdf->{'pdf'}, $self->{'pdf'}, $a, 
                        qw(NeedAppearances SigFlags CO DR DA Q));
        }
        my @Fields = ();
        my @Annots = ();
        foreach my $a ($s_page->{'Annots'}->elements()) {
            $a->realise();
            my $t_a = PDFDict();
            $self->{'pdf'}->new_obj($t_a);
            # these objects are likely to be both annotations and Acroform fields
            # key names are copied from PDF Reference 1.4 (Tables)
            my @k = (
                qw( Type Subtype Contents P Rect NM M F BS Border AP AS C CA T Popup A AA StructParent Rotate
                ),                                  # Annotations - Common (8.10)
                qw( Subtype Contents Open Name ),   # Text Annotations (8.15)
                qw( Subtype Contents Dest H PA ),   # Link Annotations (8.16)
                qw( Subtype Contents DA Q ),        # Free Text Annotations (8.17)
                qw( Subtype Contents L BS LE IC ),  # Line Annotations (8.18)
                qw( Subtype Contents BS IC ),       # Square and Circle Annotations (8.20)
                qw( Subtype Contents QuadPoints ),  # Markup Annotations (8.21)
                qw( Subtype Contents Name ),        # Rubber Stamp Annotations (8.22)
                qw( Subtype Contents InkList BS ),  # Ink Annotations (8.23)
                qw( Subtype Contents Parent Open ), # Popup Annotations (8.24)
                qw( Subtype FS Contents Name ),     # File Attachment Annotations (8.25)
                qw( Subtype Sound Contents Name ),  # Sound Annotations (8.26)
                qw( Subtype Movie Contents A ),     # Movie Annotations (8.27)
                qw( Subtype Contents H MK ),        # Widget Annotations (8.28)
                                                    # Printers Mark Annotations (none)
                                                    # Trap Network Annotations (none)
            );
            push @k, (
                qw( Subtype FT Parent Kids T TU TM Ff V DV AA
                ),                                  # Fields - Common (8.49)
                qw( DR DA Q ),                      # Fields containing variable text (8.51)
                qw( Opt ),                          # Checkbox field (8.54)
                qw( Opt ),                          # Radio field (8.55)
                qw( MaxLen ),                       # Text field (8.57)
                qw( Opt TI I ),                     # Choice field (8.59)
            ) if $AcroForm;

            # sorting out dupes
            my %ky = map { $_ => 1 } @k;
            # we do P separately, as it points to the page the Annotation is on
            delete $ky{'P'};
            # copy everything else
            foreach my $k (keys %ky) {
                next unless defined $a->{$k};
                $a->{$k}->realise();
                $t_a->{$k} = _walk_obj({}, $s_pdf->{'pdf'}, $self->{'pdf'}, $a->{$k});
            }
            $t_a->{'P'} = $t_page;
            push @Annots, $t_a;
            push @Fields, $t_a if ($AcroForm and $t_a->{'Subtype'}->val() eq 'Widget');
        }
        $t_page->{'Annots'} = PDFArray(@Annots);
        $AcroForm->{'Fields'} = PDFArray(@Fields) if $AcroForm;
        $self->{'pdf'}->{'Root'}->{'AcroForm'} = $AcroForm;
    }
    $t_page->{' imported'} = 1;

    $self->{'pdf'}->out_obj($t_page);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $t_page;
} # end of import_page()

=item $xoform = $pdf->embed_page($source_pdf, $source_page_number)

Returns a Form XObject created by extracting the specified page from 
C<$source_pdf>.

This is useful if you want to transpose the imported page somewhat
differently onto a page (e.g. two-up, four-up, etc.).

If C<$source_page_number> is 0 or -1, it will return the last page in the
document.

B<Example:>

    my $pdf = PDF::Builder->new();
    my $source = PDF::Builder->open('source.pdf');
    my $page = $pdf->page();

    # Import Page 2 from the source PDF
    my $object = $pdf->embed_page($source, 2);

    # Add it to the new PDF's first page at 1/2 scale
    my ($x, $y) = (0, 0);
    $page->object($xo, $x, $y, 0.5);

    $pdf->save('sample.pdf');

B<Note:> You can only import a page from an existing PDF file.

B<Alternate name:> C<importPageIntoForm>

This is the older name; it is kept for compatibility.

=cut

sub importPageIntoForm { return embed_page(@_); } ## no critic

sub embed_page {
    my ($self, $s_pdf, $s_idx) = @_;
    $s_idx ||= 0;

    unless (ref($s_pdf) and $s_pdf->isa('PDF::Builder')) {
        die "Invalid usage: first argument must be PDF::Builder instance, not: " . ref($s_pdf);
    }

    my ($s_page, $xo);

    $xo = $self->xo_form();

    if (ref($s_idx) eq 'PDF::Builder::Page') {
        $s_page = $s_idx;
    } else {
        $s_page = $s_pdf->open_page($s_idx);
	die "Unable to open page '$s_idx' in source PDF" unless defined $s_page;
    }

    $self->{'apiimportcache'} ||= {};
    $self->{'apiimportcache'}->{$s_pdf} ||= {};

    # This should never get past MediaBox, since it's a required object.
    foreach my $k (qw(MediaBox ArtBox TrimBox BleedBox CropBox)) {
       #next unless defined $s_page->{$k};
       #my $box = _walk_obj($self->{'apiimportcache'}->{$s_pdf}, $s_pdf->{'pdf'}, 
       #   $self->{'pdf'}, $s_page->{$k});
        next unless defined $s_page->find_prop($k);
        my $box = _walk_obj($self->{'apiimportcache'}->{$s_pdf}, $s_pdf->{'pdf'}, 
            $self->{'pdf'}, $s_page->find_prop($k));
        $xo->bbox(map { $_->val() } $box->elements());
        last;
    }
    $xo->bbox(0,0, 612,792) unless defined $xo->{'BBox'}; # US Letter default

    foreach my $k (qw(Resources)) {
        $s_page->{$k} = $s_page->find_prop($k);
        next unless defined $s_page->{$k};
        $s_page->{$k}->realise() if ref($s_page->{$k}) =~ /Objind$/;

        foreach my $sk (qw(XObject ExtGState Font ProcSet Properties ColorSpace Pattern Shading)) {
            next unless defined $s_page->{$k}->{$sk};
            $s_page->{$k}->{$sk}->realise() if ref($s_page->{$k}->{$sk}) =~ /Objind$/;
            foreach my $ssk (keys %{$s_page->{$k}->{$sk}}) {
                next if $ssk =~ /^ /;
                $xo->resource($sk, $ssk, _walk_obj($self->{'apiimportcache'}->{$s_pdf}, 
                              $s_pdf->{'pdf'}, $self->{'pdf'}, $s_page->{$k}->{$sk}->{$ssk}));
            }
        }
    }

    # create a whole content stream
    ## technically it is possible to submit an unfinished
    ## (e.g., newly created) source-page, but that's nonsense,
    ## so we expect a page fixed by open_page and die otherwise
    unless ($s_page->{' opened'}) {
        croak join(' ',
		   "Pages may only be imported from a complete PDF.",
		   "Save and reopen the source PDF object first.");
    }

    if (defined $s_page->{'Contents'}) {
        $s_page->fixcontents();

        $xo->{' stream'} = '';
        # open_page pages only contain one stream
        my ($k) = $s_page->{'Contents'}->elements();
        $k->realise();
        if ($k->{' nofilt'}) {
            # we have a finished stream here, so we unfilter
            $xo->add('q', unfilter($k->{'Filter'}, $k->{' stream'}), 'Q');
        } else {
            # stream is an unfinished/unfiltered content
            # so we just copy it and add the required "qQ"
            $xo->add('q', $k->{' stream'}, 'Q');
        }
        $xo->compressFlate() if $self->{'forcecompress'} eq 'flate' ||
	                        $self->{'forcecompress'} =~ m/^[1-9]\d*$/;
    }

    return $xo;
} # end of embed_page()

# internal utility used by embed_page and import_page

sub _walk_obj {
    my ($object_cache, $source_pdf, $target_pdf, $source_object, @keys) = @_;

    if (ref($source_object) =~ /Objind$/) {
        $source_object->realise();
    }

    return $object_cache->{scalar $source_object} if defined $object_cache->{scalar $source_object};
   #die "infinite loop while copying objects" if $source_object->{' copied'};

    my $target_object = $source_object->copy($source_pdf); ## thanks to: yaheath // Fri, 17 Sep 2004

   #$source_object->{' copied'} = 1;
    $target_pdf->new_obj($target_object) if $source_object->is_obj($source_pdf);

    $object_cache->{scalar $source_object} = $target_object;

    if (ref($source_object) =~ /Array$/) {
        $target_object->{' val'} = [];
        foreach my $k ($source_object->elements()) {
            $k->realise() if ref($k) =~ /Objind$/;
            $target_object->add_elements(_walk_obj($object_cache, $source_pdf, $target_pdf, $k));
        }
    } elsif (ref($source_object) =~ /Dict$/) {
        @keys = keys(%$target_object) unless scalar @keys;
        foreach my $k (@keys) {
            next if $k =~ /^ /;
            next unless defined $source_object->{$k};
            $target_object->{$k} = _walk_obj($object_cache, $source_pdf, $target_pdf, $source_object->{$k});
        }
        if ($source_object->{' stream'}) {
            if ($target_object->{'Filter'}) {
                $target_object->{' nofilt'} = 1;
            } else {
                delete $target_object->{' nofilt'};
                $target_object->{'Filter'} = PDFArray(PDFName('FlateDecode'));
            }
            $target_object->{' stream'} = $source_object->{' stream'};
        }
    }
    delete $target_object->{' streamloc'};
    delete $target_object->{' streamsrc'};

    return $target_object;
} # end of _walk_obj()

=item $count = $pdf->page_count()

Returns the number of pages in the document.

B<Alternate name:> C<pages>

This is the old name; it is kept for compatibility.

=cut

sub pages { return page_count(@_); } ## no critic

sub page_count {
    my $self = shift();
    return scalar @{$self->{'pagestack'}};
}

=item $pdf->page_labels($page_number, $opts)

Sets page label numbering format, for the Reader's page-selection slider thumb 
(I<not> the outline/bookmarks). At this time, there is no method to 
automatically synchronize a page's label with the outline/bookmarks, or to 
somewhere on the printed page.

Note that many PDF Readers ignore these settings, and (at most) simply give
you the physical page number 1, 2, 3,... instead of the page label specified 
here.

    # Generate a 30-page PDF
    my $pdf = PDF::Builder->new();
    $pdf->page() for 1..30;

    # Number pages i to v, 1 to 20, and A-1 to A-5, respectively
    $pdf->page_labels(1, 'style' => 'roman');
    $pdf->page_labels(6, 'style' => 'decimal');
    $pdf->page_labels(26, 'style' => 'decimal', 'prefix' => 'A-');

    $pdf->save('sample.pdf');

B<Supported Options:>

=over

=item style

B<Roman> (I,II,III,...), B<roman> (i,ii,iii,...), B<decimal> (1,2,3,...), 
B<Alpha> (A,B,C,...), B<alpha> (a,b,c,...), or B<nocounter>. This is the 
styling of the counter part of the label (unless C<nocounter>, in which case 
there is no counter output).

=item start

(Re)start numbering the I<counter> at given page number (this is a decimal 
integer, I<not> the styled counter). By default it starts at 1, and B<resets>
to 1 at each call to C<page_labels()>! You need to explicitly give C<start> if 
you want to I<continue> counting at the current page number when you call
C<page_labels()>, whether or not you are changing the format.

Also note that the counter starts at physical page B<1>, while the page 
C<$index> number in the C<page_labels()> call (as well as the PDF PageLabels 
dictionary) starts at logical page (index) B<0>.

=item prefix

Text prefix for numbering, such as an Appendix letter B<B->. If C<style> is 
I<nocounter>, just this text is used, otherwise a styled counter will be 
appended. If C<style> is omitted, remember that it will default to a decimal 
number, which will be appended to the prefix.

According to the Adobe/ISO PDF specification, a prefix of 'Content' has a 
special meaning, in that any /S counter is ignored and only that text is used. 
However, this appears to be ignored (use a style of I<nocounter> to suppress
the counter).

=back

B<Example:>

    # Start with lowercase Roman Numerals at the 1st page, starting with i (1)
    $pdf->page_labels(0, 
        'style' => 'roman',
    );

    # Switch to Arabic (decimal) at the 5th page, starting with 1
    $pdf->page_labels(4, 
        'style' => 'decimal',
    );

    # invalid style at the 25th page, should just continue 
    # with decimal at the current counter
    $pdf->page_labels(24, 
        'style' => 'raman_noodles',  # fail over to decimal
	   # note that PDF::API2 will see the 'r' and treat it as 'roman'
	'start' => 21,  # necessary, otherwise would restart at 1
    );

    # No page label at the 31st and 32nd pages. Note that this could be
    # confusing to the person viewing the PDF, but may be appropriate if
    # the page itself has no numbering.
    $pdf->page_labels(30, 
        'style' => 'nocounter',
    );

    # Numbering for Appendix A at the 33rd page, A-1, A-2,...
    $pdf->page_labels(32, 
        'start' => 1,  # unnecessary
        'prefix' => 'A-'
    );

    # Numbering for Appendix B at the 37th page, B-1, B-2,...
    $pdf->page_labels( 36, 
        'prefix' => 'B-'
    );

    # Numbering for the Index at the 41st page, Index I, Index II,...
    $pdf->page_labels(40, 
        'style' => 'Roman',
        'start' => 1,  # unnecessary
        'prefix' => 'Index '  # note trailing space
    );

    # Unnumbered 'Index' at the 45th page, Index, Index,...
    $pdf->page_labels(40, 
        'style' => 'nocounter',
        'prefix' => 'Index '
    );

B<Alternate name:> C<pageLabel>

This old method name is retained for compatibility with old user code.
Note that with C<pageLabel>, you need to make the "options" list an anonymous
hash by placing B<{ }> around the entire list, even if it has only one item
in it.

=cut

# in the new method, parameters are organized a bit differently than in the 
# old pageLabel(). rather than an opts hashref, it is a hash.
sub page_labels { 
    my ($self, $page_number, %opts) = @_;
    return pageLabel($self, $page_number, \%opts);
}

# actually, the old code
sub pageLabel {
    my $self = shift();

    $self->{'catalog'}->{'PageLabels'} ||= PDFDict();
    $self->{'catalog'}->{'PageLabels'}->{'Nums'} ||= PDFArray();

    my $nums = $self->{'catalog'}->{'PageLabels'}->{'Nums'};
    while (scalar @_) { # should we have only one trip through here?
        my $index = shift();
        my $opts = shift();
        # copy dashed options to preferred undashed option names
        if (defined $opts->{'-style'} && !defined $opts->{'style'}) { $opts->{'style'} = delete($opts->{'-style'}); }
        if (defined $opts->{'-prefix'} && !defined $opts->{'prefix'}) { $opts->{'prefix'} = delete($opts->{'-prefix'}); }
        if (defined $opts->{'-start'} && !defined $opts->{'start'}) { $opts->{'start'} = delete($opts->{'-start'}); }

        $nums->add_elements(PDFNum($index));

        my $d = PDFDict();
        if (defined $opts->{'style'}) {
	    if ($opts->{'style'} ne 'nocounter') {
		# defaults to decimal if unrecogized style given
                $d->{'S'} = PDFName($opts->{'style'} eq 'Roman' ? 'R' :
                                    $opts->{'style'} eq 'roman' ? 'r' :
                                    $opts->{'style'} eq 'Alpha' ? 'A' :
                                    $opts->{'style'} eq 'alpha' ? 'a' : 'D');
	    } else {
		# for nocounter (no styled counter), do not create /S entry
	    }
        } else {
	    # default to decimal counter if no style given
            $d->{'S'} = PDFName('D');
        }

        if (defined $opts->{'prefix'}) {
	    # 'Content' supposedly treated differently
            $d->{'P'} = PDFString($opts->{'prefix'}, 's');
        }

        if (defined $opts->{'start'}) {
            $d->{'St'} = PDFNum($opts->{'start'});
        }

        $nums->add_elements($d);
    }

    return;
} # end of page_labels()

# set global User Unit scale factor (default 1.0)

=item $pdf->userunit($value)

Sets the global UserUnit, defining the scale factor to multiply any size or
coordinate by. For example, C<userunit(72)> results in a User Unit of 72 points,
or 1 inch.

See L<PDF::Builder::Docs/User Units> for more information.

=cut

sub userunit {
    my ($self, $value) = @_;

    if (float($value) <= 0.0) {
        warn "Invalid User Unit value '$value', set to 1.0";
        $value = 1.0;
    }

    $self->verCheckOutput(1.6, "set User Unit");
    $self->{'pdf'}->{' userUnit'} = float($value);
    $self->{'pages'}->{'UserUnit'} = PDFNum(float($value));
    if (defined $self->{'pages'}->{'MediaBox'}) { # should be default letter
        if ($value != 1.0) { # divide points by User Unit
            my @corners = ( 0, 0, 612/$value, 792/$value );
            $self->{'pages'}->{'MediaBox'} = PDFArray( map { PDFNum(float($_)) } @corners );
        }
    }

    return $self;
}

# utility to handle calling page_size, and name with or without 'orient' setting
sub _bbox {
    my ($self, @corners) = @_;

    # if 1 or 3 elements in @corners, and [0] contains a letter, it's a name
    my $isName = 0;
    if (scalar @corners && $corners[0] =~ m/[a-z]/i) { $isName = 1; }

    if (scalar @corners == 3) {
	    # name plus one option (orient)
	    my ($name, %opts) = @corners;
	    # copy dashed name options to preferred undashed name
	    if (defined $opts{'-orient'} && !defined $opts{'orient'}) { $opts{'orient'} = delete($opts{'-orient'}); }

	    @corners = page_size(($name)); # now 4 numeric values
	    if (defined $opts{'orient'}) {
	        if ($opts{'orient'} =~ m/^l/i) { # 'landscape' or just 'l'
		        # 0 0 W H -> 0 0 H W
		        my $temp;
		        $temp = $corners[2]; $corners[2] = $corners[3]; $corners[3] = $temp;
	        }
	    }
    } else {
        # name without [orient] option, or numeric coordinates given
        @corners = page_size(@corners);
    }

    my $UU = $self->{'pdf'}->{' userUnit'};
    # scale down size if User Unit given (e.g., Letter => 0 0 8.5 11)
    if ($isName && $UU != 1.0) {
        for (my $i=0; $i<4; $i++) {
            $corners[$i] /= $UU;
        }
    }

    return (@corners);
} # end of _bbox()

# utility to get a bounding box by name
sub _get_bbox {
    my ($self, $boxname) = @_;

    # if requested box not set, return next higher box's corners
    # MediaBox should always at least have a default value
    if (not defined $self->{'pages'}->{$boxname}) {
        if      ($boxname eq 'CropBox') {
	    $boxname = 'MediaBox';
        } elsif ($boxname eq 'BleedBox' ||
	         $boxname eq 'TrimBox' ||
	         $boxname eq 'ArtBox' ) {
	    if (defined $self->{'pages'}->{'CropBox'}) {
	        $boxname = 'CropBox';
	    } else {
	        $boxname = 'MediaBox';
	    }
	} else { 
            # invalid box name (silent error). just use MediaBox
	    $boxname = 'MediaBox';
	}
    }

    # now $boxname is known to exist
    return map { $_->val() } $self->{'pages'}->{$boxname}->elements();

} # end of _get_bbox()

=item $pdf->mediabox($name)

=item $pdf->mediabox($name, 'orient' => 'orientation')

=item $pdf->mediabox($w,$h)

=item $pdf->mediabox($llx,$lly, $urx,$ury)

=item ($llx,$lly, $urx,$ury) = $pdf->mediabox()

Sets (or gets) the global MediaBox, defining the width and height (or by 
corner coordinates, or by standard name) of the output page itself, such as 
the physical paper size. 

See L<PDF::Builder::Docs/Media Box> for more information.
The method always returns the current bounds (after any set operation).

=cut

sub mediabox {
    my ($self, @corners) = @_;
    if (defined $corners[0]) {
        @corners = $self->_bbox(@corners);
        $self->{'pages'}->{'MediaBox'} = PDFArray( map { PDFNum(float($_)) } @corners );
    }

    return $self->_get_bbox('MediaBox');
}

=item $pdf->cropbox($name)

=item $pdf->cropbox($name, 'orient' => 'orientation')

=item $pdf->cropbox($w,$h)

=item $pdf->cropbox($llx,$lly, $urx,$ury)

=item ($llx,$lly, $urx,$ury) = $pdf->cropbox()

Sets (or gets) the global CropBox. This will define the media size to which 
the output will later be clipped. 

See L<PDF::Builder::Docs/Crop Box> for more information.
The method always returns the current bounds (after any set operation).

=cut

sub cropbox {
    my ($self, @corners) = @_;
    if (defined $corners[0]) {
        @corners = $self->_bbox(@corners);
        $self->{'pages'}->{'CropBox'} = PDFArray( map { PDFNum(float($_)) } @corners );
    }

    return $self->_get_bbox('CropBox');
}

=item $pdf->bleedbox($name)

=item $pdf->bleedbox($name, 'orient' => 'orientation')

=item $pdf->bleedbox($w,$h)

=item $pdf->bleedbox($llx,$lly, $urx,$ury)

=item ($llx,$lly, $urx,$ury) = $pdf->bleedbox()

Sets (or gets) the global BleedBox. This is typically used for hard copy 
printing where you want ink to go to the edge of the cut paper.

See L<PDF::Builder::Docs/Bleed Box> for more information.
The method always returns the current bounds (after any set operation).

=cut

sub bleedbox {
    my ($self, @corners) = @_;
    if (defined $corners[0]) {
        @corners = $self->_bbox(@corners);
        $self->{'pages'}->{'BleedBox'} = PDFArray( map { PDFNum(float($_)) } @corners );
    }

    return $self->_get_bbox('BleedBox');
}

=item $pdf->trimbox($name)

=item $pdf->trimbox($name, 'orient' => 'orientation')

=item $pdf->trimbox($w,$h)

=item $pdf->trimbox($llx,$lly, $urx,$ury)

=item ($llx,$lly, $urx,$ury) = $pdf->trimbox()

Sets (or gets) the global TrimBox. This is supposed to be the actual 
dimensions of the finished page (after trimming of the paper). 

See L<PDF::Builder::Docs/Trim Box> for more information.
The method always returns the current bounds (after any set operation).

=cut

sub trimbox {
    my ($self, @corners) = @_;
    if (defined $corners[0]) {
        @corners = $self->_bbox(@corners);
        $self->{'pages'}->{'TrimBox'} = PDFArray( map { PDFNum(float($_)) } @corners );
    }

    return $self->_get_bbox('TrimBox');
}

=item $pdf->artbox($name)

=item $pdf->artbox($name, 'orient' => 'orientation')

=item $pdf->artbox($w,$h)

=item $pdf->artbox($llx,$lly, $urx,$ury)

=item ($llx,$lly, $urx,$ury) = $pdf->artbox()

Sets (or gets) the global ArtBox. This is supposed to define "the extent of 
the page's I<meaningful> content". 

See L<PDF::Builder::Docs/Art Box> for more information.
The method always returns the current bounds (after any set operation).

=cut

sub artbox {
    my ($self, @corners) = @_;
    if (defined $corners[0]) {
        @corners = $self->_bbox(@corners);
        $self->{'pages'}->{'ArtBox'} = PDFArray( map { PDFNum(float($_)) } @corners );
    }

    return $self->_get_bbox('ArtBox');
}

=back

=head1 FONT METHODS

=over

=item $font = $pdf->corefont($fontname, %opts)

Returns a new Adobe core font object. For details, 
see L<PDF::Builder::Docs/Core Fonts>. Note that this is an Adobe-standard
corefont I<name>, and not a file name.

See also L<PDF::Builder::Resource::Font::CoreFont>.

=cut

sub corefont {
    my ($self, $name, %opts) = @_;
    # copy dashed name options to preferred undashed format
    if (defined $opts{'-unicodemap'} && !defined $opts{'unicodemap'}) { $opts{'unicodemap'} = delete($opts{'-unicodemap'}); }

    require PDF::Builder::Resource::Font::CoreFont;
    my $obj = PDF::Builder::Resource::Font::CoreFont->new($self->{'pdf'}, $name, %opts);
    $self->{'pdf'}->out_obj($self->{'pages'});
    $obj->tounicodemap() if $opts{'unicodemap'}; # UTF-8 not usable

    return $obj;
}

=item $font = $pdf->psfont($ps_file, %opts)

Returns a new Adobe Type1 ("PostScript") font object.
For details, see L<PDF::Builder::Docs/PS Fonts>.

See also L<PDF::Builder::Resource::Font::Postscript>.

=cut

sub psfont {
    my ($self, $psf, %opts) = @_;
    # copy dashed name options to preferred undashed format
    if (defined $opts{'-afmfile'} && !defined $opts{'afmfile'}) { $opts{'afmfile'} = delete($opts{'-afmfile'}); }
    if (defined $opts{'-pfmfile'} && !defined $opts{'pfmfile'}) { $opts{'pfmfile'} = delete($opts{'-pfmfile'}); }
    if (defined $opts{'-unicodemap'} && !defined $opts{'unicodemap'}) { $opts{'unicodemap'} = delete($opts{'-unicodemap'}); }

    foreach my $o (qw(afmfile pfmfile)) {
        next unless defined $opts{$o};
        $opts{$o} = _findFont($opts{$o});
    }
    $psf = _findFont($psf);
    require PDF::Builder::Resource::Font::Postscript;
    my $obj = PDF::Builder::Resource::Font::Postscript->new($self->{'pdf'}, $psf, %opts);

    $self->{'pdf'}->out_obj($self->{'pages'});
    $obj->tounicodemap() if $opts{'unicodemap'}; # UTF-8 not usable

    return $obj;
}

=item $font = $pdf->ttfont($ttf_file, %opts)

Returns a new TrueType (or OpenType) font object.
For details, see L<PDF::Builder::Docs/TrueType Fonts>.

=cut

sub ttfont {
    my ($self, $file, %opts) = @_;
    # copy dashed name options to preferred undashed format
    if (defined $opts{'-unicodemap'} && !defined $opts{'unicodemap'}) { $opts{'unicodemap'} = delete($opts{'-unicodemap'}); }
    if (defined $opts{'-noembed'} && !defined $opts{'noembed'}) { $opts{'noembed'} = delete($opts{'-noembed'}); }

    # PDF::Builder doesn't set BaseEncoding for TrueType fonts, so text
    # isn't searchable unless a ToUnicode CMap is included.  Include
    # the ToUnicode CMap by default, but allow it to be disabled (for
    # performance and file size reasons) by setting 'unicodemap' to 0.
    $opts{'unicodemap'} = 1 unless exists $opts{'unicodemap'};
    $opts{'noembed'}    = 0 unless exists $opts{'noembed'};

    $file = _findFont($file);
    require PDF::Builder::Resource::CIDFont::TrueType;
    my $obj = PDF::Builder::Resource::CIDFont::TrueType->new($self->{'pdf'}, $file, %opts);

    $self->{'pdf'}->out_obj($self->{'pages'});
    $obj->tounicodemap() if $opts{'unicodemap'};

    return $obj;
}

=item $font = $pdf->bdfont($bdf_file, @opts)

Returns a new BDF (bitmapped distribution format) font object, based on the 
specified Adobe BDF file.

See also L<PDF::Builder::Resource::Font::BdFont>

=cut

sub bdfont {
    my ($self, $bdf_file, @opts) = @_;

    require PDF::Builder::Resource::Font::BdFont;
    my $obj = PDF::Builder::Resource::Font::BdFont->new($self->{'pdf'}, $bdf_file, @opts);

    $self->{'pdf'}->out_obj($self->{'pages'});
    # $obj->tounicodemap(); # does not support Unicode!

    return $obj;
}

=item $font = $pdf->cjkfont($cjkname, %opts)

Returns a new CJK font object. These are TrueType-like fonts for East Asian
languages (Chinese, Japanese, Korean).
For details, see L<PDF::Builder::Docs/CJK Fonts>.

B<NOTE:> C<cjkfont> is quite old and is not well supported. We recommend that
you try using C<ttfont> (or another font routine, if not TTF/OTF) with the
appropriate CJK font file. Most appear to be .ttf or .otf format. PDFs created
using C<cjkfont> may not be fully portable, and support for
C<cjkfont> I<may> be dropped in a future release. We would appreciate hearing
from you if you are successfully using C<cjkfont>, and are unable to use
C<ttfont> instead.

Among other things, C<cjkfont> selections are limited, as they require CMAP
files; they may or may not subset correctly; and they can not be used as the
base for synthetic fonts.

See also L<PDF::Builder::Resource::CIDFont::CJKFont>

=cut

sub cjkfont {
    my ($self, $name, %opts) = @_;
    # copy dashed name options to preferred undashed format
    if (defined $opts{'-unicodemap'} && !defined $opts{'unicodemap'}) { $opts{'unicodemap'} = delete($opts{'-unicodemap'}); }

    require PDF::Builder::Resource::CIDFont::CJKFont;
    my $obj = PDF::Builder::Resource::CIDFont::CJKFont->new($self->{'pdf'}, $name, %opts);

    $self->{'pdf'}->out_obj($self->{'pages'});
    $obj->tounicodemap() if $opts{'unicodemap'};

    return $obj;
}

=item $font = $pdf->font($name, %opts)

A convenience function to add a font to the PDF without having to specify the
format. Returns the font object, to be used by L<PDF::Builder::Content>.

The font C<$name> is either the name of one of the standard 14 fonts 
(L<PDF::Builder::Resource::Font::CoreFont/STANDARD FONTS>), such as
Helvetica or the path to a font file.
There are 15 additional core fonts on a Windows system.
Note that the exact name of a core font needs to be given.
The file extension (if path given) determines what type of font file it is.

    my $pdf = PDF::Builder->new();
    my $font1 = $pdf->font('Helvetica-Bold');
    my $font2 = $pdf->font('/path/to/ComicSans.ttf');
    my $page = $pdf->page();
    my $content = $page->text();

    $content->position(1 * 72, 9 * 72);
    $content->font($font1, 24);
    $content->text('Hello, World!');

    $content->position(0, -36);
    $content->font($font2, 12);
    $content->text('This is some sample text.');

    $pdf->saveas('sample.pdf');

The path can be omitted if the font file is in the current directory or one of
the directories returned by C<font_path>.

TrueType (ttf/otf), Adobe PostScript Type 1 (pfa/pfb), and Adobe Glyph Bitmap
Distribution Format (bdf) fonts are supported.

The following options (C<%opts>) are available:

=over

=item format

The font format is normally detected automatically based on the file's
extension.  If you're using a font with an atypical extension, you can set
C<format> to one of C<truetype> (TrueType or OpenType), C<type1> (PostScript
Type 1), or C<bitmap> (Adobe Bitmap).

=item dokern

Kerning (automatic adjustment of space between pairs of characters) is enabled
by default if the font includes this information.  Set this option to false to
disable.

=item afm_file (PostScript Type 1 fonts only)

Specifies the location of the font metrics file.

=item pfm_file (PostScript Type 1 fonts only)

Specifies the location of the printer font metrics file.  This option overrides
the encode option.

=item embed (TrueType fonts only)

Fonts are embedded in the PDF by default, which is required to ensure that they
can be viewed properly on a device that doesn't have the font installed. Set
this option to false to prevent the font from being embedded.

=back

=cut

sub font {
    my ($self, $name, %opts) = @_;
    # copy dashed name options to preferred undashed format
    if (defined $opts{'-encode'} && !defined $opts{'encode'}) { $opts{'encode'} = delete($opts{'-encode'}); }
    if (defined $opts{'-kerning'} && !defined $opts{'kerning'}) { $opts{'kerning'} = delete($opts{'-kerning'}); }
    if (defined $opts{'-dokern'} && !defined $opts{'dokern'}) { $opts{'dokern'} = delete($opts{'-dokern'}); }
    if (defined $opts{'-embed'} && !defined $opts{'embed'}) { $opts{'embed'} = delete($opts{'-embed'}); }
    if (defined $opts{'-afmfile'} && !defined $opts{'afmfile'}) { $opts{'afmfile'} = delete($opts{'-afmfile'}); }
    if (defined $opts{'-pfmfile'} && !defined $opts{'pfmfile'}) { $opts{'pfmfile'} = delete($opts{'-pfmfile'}); }

    if (exists $opts{'kerning'}) {
        $opts{'dokern'} = delete $opts{'kerning'};
    }
    $opts{'dokern'} //= 1; # kerning ON by default for font()

    require PDF::Builder::Resource::Font::CoreFont;
    if (PDF::Builder::Resource::Font::CoreFont->is_standard($name)) {
        return $self->corefont($name, %opts);
    }

    my $format = $opts{'format'};
    $format //= ($name =~ /\.[ot]tf$/i ? 'truetype' :
                 $name =~ /\.pf[ab]$/i ? 'type1'    :
                 $name =~ /\.bdf$/i    ? 'bitmap'   : '');

    if      ($format eq 'truetype') {
        $opts{'embed'} //= 1;
        return $self->ttfont($name, %opts);
    } elsif ($format eq 'type1') {
        if (exists $opts{'afm_file'}) {
            $opts{'afmfile'} = delete $opts{'afm_file'};
        }
        if (exists $opts{'pfm_file'}) {
            $opts{'pfmfile'} = delete $opts{'pfm_file'};
        }
        return $self->psfont($name, %opts);
    } elsif ($format eq 'bitmap') {
        return $self->bdfont($name, %opts);
    } elsif ($format) {
        croak "Unrecognized font format: $format";
    } elsif ($name =~ /(\..*)$/) {
        croak "Unrecognized font file extension: $1";
    } else {
        croak "Unrecognized font: $name";
    }
}

=item @directories = PDF::Builder->font_path()

Return the list of directories that will be searched (in order) in addition to
the current directory when you add a font to a PDF without including the full
path to the font file.

=cut

sub font_path {
    return @font_path;
}

=item @directories = PDF::Builder::add_to_font_path('/my/fonts', '/path/to/fonts', ...)

Adds one or more directories to the list of paths to be searched for font files.

Returns the font search path.

B<Alternate name:> C<addFontDirs>

Prior to recent changes to PDF::API2, this method was addFontDirs(). This 
method is still available, but may be deprecated some time in the future.

=cut

sub addFontDirs { return add_to_font_path(@_); } ## no critic

sub add_to_font_path {
    # Allow this method to be called using either :: or -> notation.
    shift() if ref($_[0]);
    shift() if $_[0] eq __PACKAGE__;

    push @font_path, @_;
    return @font_path;
}

=item @directories = PDF::Builder->set_font_path('/my/fonts', '/path/to/fonts');

Replace the existing font search path. This should only be necessary if you
need to remove a directory from the path for some reason, or if you need to
reorder the list.

Returns the font search path.

=cut

# I don't know why there are separate set and query methods, but to maintain
# compatibility, we'll follow that convention...

sub set_font_path {
    # Allow this method to be called using either :: or -> notation.
    shift() if ref($_[0]);
    shift() if $_[0] eq __PACKAGE__;

    @font_path = ((map { "$_/PDF/Builder/fonts" } @INC), @_);

    return @font_path;
}

sub _findFont {
    my $font = shift();

    # Check the current directory
    return $font if -f $font;

    # Check the font search path
    foreach my $directory (@font_path) {
        return "$directory/$font" if -f "$directory/$font";
    }

    return;
}

=item $font = $pdf->synfont($basefont, %opts)

Returns a new synthetic font object. These are modifications to a core (or 
PS/T1 or TTF/OTF) font, where the font may be replaced by a Type1 or Type3 
PostScript font.
This does not appear to work with CJK fonts (created with C<cjkfont> method).
For details, see L<PDF::Builder::Docs/Synthetic Fonts>.

See also L<PDF::Builder::Resource::Font::SynFont>

B<Alternate name:> C<synthetic_font>

Prior to recent PDF::API2 changes, the routine to create modified fonts was
"synfont". PDF::API2 has renamed it to "synthetic_font", which I don't like,
but to maintain compatibility, "synthetic_font" is available as an alias.

There are also some minor option differences (incompatibilities) 
discussed in C<SynFont>, including the value of 'bold' between the two entry
points.

=cut

sub synthetic_font { return synfont(@_, '-entry_point'=>'synthetic_font'); } ## no critic

sub synfont {
    my ($self, $font, %opts) = @_;
    # copy dashed name options to preferred undashed format
    if (defined $opts{'-unicodemap'} && !defined $opts{'unicodemap'}) { $opts{'unicodemap'} = delete($opts{'-unicodemap'}); }
    # define entry point in options if synfont
    if (!defined $opts{'-entry_point'}) { $opts{'-entry_point'} = 'synfont'; }

    # PDF::Builder doesn't set BaseEncoding for TrueType fonts, so text
    # isn't searchable unless a ToUnicode CMap is included.  Include
    # the ToUnicode CMap by default, but allow it to be disabled (for
    # performance and file size reasons) by setting unicodemap to 0.
    $opts{'unicodemap'} = 1 unless exists $opts{'unicodemap'};

    require PDF::Builder::Resource::Font::SynFont;
    my $obj = PDF::Builder::Resource::Font::SynFont->new($self->{'pdf'}, $font, %opts);

    $self->{'pdf'}->out_obj($self->{'pages'});
    $obj->tounicodemap() if $opts{'unicodemap'};

    return $obj;
}

=item $font = $pdf->unifont(@fontspecs, %opts)

Returns a new uni-font object, based on the specified fonts and options.

B<BEWARE:> This is not a true PDF-object, but a virtual/abstract font definition!

See also L<PDF::Builder::Resource::UniFont>.

Valid options (C<%opts>) are:

=over

=item encode

Changes the encoding of the font from its default.

=back

=cut

# tentatively deprecated in PDF::API2. suggests using Unicode-supporting
# TTF instead. see also Resource/UniFont.pm (POD removed to discourage use).
sub unifont {
    my ($self, @opts) = @_;
    # must leave opts as an array, rather than as a hash, so option fixup 
    # needs to be done within new(). opts is not just options (hash), but
    # also a variable-length array of refs, which doesn't take kindly to
    # being hashified!

    require PDF::Builder::Resource::UniFont;
    my $obj = PDF::Builder::Resource::UniFont->new($self->{'pdf'}, @opts);

    return $obj;
}

=back

=head1 IMAGE METHODS

=over

=item $object = $pdf->image($file, %opts);

A convenience function to attempt to determine the image type, and import a 
file of that type and return an object that can be placed as part of a page's 
content:

    my $pdf = PDF::Builder->new();
    my $page = $pdf->page();

    my $image = $pdf->image('/path/to/image.jpg');
    $page->object($image, 100, 100);

    $pdf->save('sample.pdf');

C<$file> may be either a file name, a filehandle, or a 
L<PDF::Builder::Resource::XObject::Image::GD> object.

B<Caution:> Do not confuse this C<image> ($pdf-E<gt>) with the image method 
found in the graphics (gfx) class ($gfx-E<gt>), used to actually place a
read-in or decoded image on the page!

See L<PDF::Builder::Content/image> for details about placing images on a page
once they're imported.

The image format is normally detected automatically based on the file's
extension (.gif, .png, .tif/.tiff, .jpg/.jpeg, .pnm/.pbm/.pgm/.ppm). If passed 
a filehandle, image formats GIF, JPEG, PNM, and PNG will be
detected based on the file's header. Unfortunately, at this time, other image
formats (TIFF and GD) cannot be automatically detected. (TIFF I<could> be, 
except that C<image_tiff()> cannot use a filehandle anyway as input when using 
the libtiff library, which is highly recommended.)

If the file has an atypical extension or the filehandle is for a different kind
of image, you can set the C<format> option to one of the supported types:
C<gif>, C<jpeg>, C<png>, C<pnm>, or C<tiff>.

B<Note:> PNG images that include an alpha (transparency) channel go through a
relatively slow process of splitting the image into separate RGB and alpha
components as is required by images in PDFs. If you're having performance
issues, install Image::PNG::Libpng to speed this process up by
an order of magnitude; either module will be used automatically if available.
See the C<image_png> method for details.

B<Note:> TIFF image processing is very slow if using the pure Perl decoder.
We highly recommend using the Graphics::TIFF library to improve performance.
See the C<image_tiff> method for details.

=cut

sub image {
    my ($self, $file, %opts) = @_;

    my $format = lc($opts{'format'} // '');

    if (ref($file) eq 'GD::Image') {
        return image_gd($file, %opts);
    }
    elsif (ref($file)) {
        $format ||= _detect_image_format($file);
	# JPEG, PNG, GIF, and P*M files can be detected
	# TIFF files cannot currently be detected
	# GD images are created on-the-fly and don't have files
    }
    unless (ref($file)) {
        $format ||= ($file =~ /\.jpe?g$/i    ? 'jpeg' :
                     $file =~ /\.png$/i      ? 'png'  :
                     $file =~ /\.gif$/i      ? 'gif'  :
                     $file =~ /\.tiff?$/i    ? 'tiff' :
                     $file =~ /\.p[bgpn]m$/i ? 'pnm'  : '');
	# GD images are created on-the-fly and don't have files
    }

    if ($format eq 'jpeg') {
        return $self->image_jpeg($file, %opts);
    }
    elsif ($format eq 'png') {
        return $self->image_png($file, %opts);
    }
    elsif ($format eq 'gif') {
        return $self->image_gif($file, %opts);
    }
    elsif ($format eq 'tiff') {
        return $self->image_tiff($file, %opts);
    }
    elsif ($format eq 'pnm') {
        return $self->image_pnm($file, %opts);
    }
    elsif ($format) {
        croak "Unrecognized image format: $format";
    }
    elsif (ref($file)) {
        croak "Unspecified image format";
    }
    elsif ($file =~ /(\..*)$/) {
        croak "Unrecognized image extension: $1";
    }
    else {
        croak "Unrecognized image: $file";
    }
}

# if passed a filehandle, attempt to read the format header to determine type
sub _detect_image_format {
    my $fh = shift();
    $fh->seek(0, 0);
    binmode $fh, ':raw';

    my $test;
    my $bytes_read = $fh->read($test, 8);
    $fh->seek(0, 0);
    return unless $bytes_read and $bytes_read == 8;

    return 'gif'  if $test =~ /^GIF\d\d[a-z]/;
    return 'jpeg' if $test =~ /^\xFF\xD8\xFF/;
    return 'png'  if $test =~ /^\x89PNG\x0D\x0A\x1A\x0A/;
    return 'pnm'  if $test =~ /^\s*P[1-6]/;
    # potentially could handle TIFF, except that libtiff cannot accept
    # a filehandle as input for image_tiff(). GD images do not have files.
    return;
}

=item $jpeg = $pdf->image_jpeg($file, %opts)

Imports and returns a new JPEG image object. C<$file> may be either a filename 
or a filehandle.

See L<PDF::Builder::Resource::XObject::Image::JPEG> for additional information
and C<examples/Content.pl> for some examples of placing an image on a page.

=cut

sub image_jpeg {
    my ($self, $file, %opts) = @_;

    require PDF::Builder::Resource::XObject::Image::JPEG;
    my $obj = PDF::Builder::Resource::XObject::Image::JPEG->new($self->{'pdf'}, $file, %opts);

    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $tiff = $pdf->image_tiff($file, %opts)

Imports and returns a new TIFF image object. C<$file> may be either a filename 
or a filehandle.
For details, see L<PDF::Builder::Docs/TIFF Images>.

See L<PDF::Builder::Resource::XObject::Image::TIFF> and
L<PDF::Builder::Resource::XObject::Image::TIFF_GT> for additional information
and C<examples/Content.pl>
for some examples of placing an image on a page (JPEG, but the principle is
the same). 
There is an optional TIFF library (TIFF_GT) described, that gives more
capability than the default one. However, note that C<$file> can only be
a filename when using this library.

=cut

sub image_tiff {
    my ($self, $file, %opts) = @_;
    # copy dashed name options to preferred undashed format
    if (defined $opts{'-nouseGT'} && !defined $opts{'nouseGT'}) { $opts{'nouseGT'} = delete($opts{'-nouseGT'}); }
    if (defined $opts{'-silent'} && !defined $opts{'silent'}) { $opts{'silent'} = delete($opts{'-silent'}); }

    my ($rc, $obj);
    $rc = $self->LA_GT();
    if ($rc) {
	# Graphics::TIFF available
	if (defined $opts{'nouseGT'} && $opts{'nouseGT'} == 1) {
	   $rc = -1;  # don't use it
	}
    }
    if ($rc == 1) {
	# Graphics::TIFF (_GT suffix) available and to be used
        require PDF::Builder::Resource::XObject::Image::TIFF_GT;
        $obj = PDF::Builder::Resource::XObject::Image::TIFF_GT->new($self->{'pdf'}, $file, %opts);
        $self->{'pdf'}->out_obj($self->{'pages'});
    } else {
	# Graphics::TIFF not available, or is but is not to be used
        require PDF::Builder::Resource::XObject::Image::TIFF;
        $obj = PDF::Builder::Resource::XObject::Image::TIFF->new($self->{'pdf'}, $file, %opts);
        $self->{'pdf'}->out_obj($self->{'pages'});

	if ($rc == 0 && $MSG_COUNT[0]++ == 0) {
	    # give warning message once, unless silenced (silent) or
	    # deliberately not using Graphics::TIFF (rc == -1)
	    if (!defined $opts{'silent'} || $opts{'silent'} == 0) {
	        print STDERR "Your system does not have Graphics::TIFF installed, ".
                         "so some\nTIFF functions may not run correctly.\n";
		# even if silent only once, COUNT still incremented
	    }
	}
    }
    $obj->{'usesGT'} = PDFNum($rc);  # -1 available but unused
                                     #  0 not available
                                     #  1 available and used
                                     # $tiff->usesLib() to get number

    return $obj;
}

=item $rc = $pdf->LA_GT()

Returns 1 if the library name (package) Graphics::TIFF is installed, and 
0 otherwise. For this optional library, this call can be used to know if it 
is safe to use certain functions. For example:

    if ($pdf->LA_GT() {
        # is installed and usable
    } else {
        # not available. you will be running the old, pure PERL code
    }

=cut

# there doesn't seem to be a way to pass in a string (or bare) package name,
# to make a generic check routine
sub LA_GT {
    my ($self) = @_;

    my ($rc);
    $rc = eval {
        require Graphics::TIFF;
        1;
    };
    if (!defined $rc) { $rc = 0; }  # else is 1
    if ($rc) {
	# installed, but not up to date?
	if ($Graphics::TIFF::VERSION < $GrTFversion) { $rc = 0; }
    }

    return $rc;
}

=item $pnm = $pdf->image_pnm($file, %opts)

Imports and returns a new PNM image object. C<$file> may be either a filename 
or a filehandle.

See L<PDF::Builder::Resource::XObject::Image::PNM> for additional information
and C<examples/Content.pl> for some examples of placing an image on a page
(JPEG, but the principle is the same).

=cut

sub image_pnm {
    my ($self, $file, %opts) = @_;

    $opts{'compress'} //= $self->{'forcecompress'};

    require PDF::Builder::Resource::XObject::Image::PNM;
    my $obj = PDF::Builder::Resource::XObject::Image::PNM->new($self->{'pdf'}, $file, %opts);

    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $png = $pdf->image_png($file, %opts) 

Imports and returns a new PNG image object. C<$file> may be either 
a filename or a filehandle.
For details, see L<PDF::Builder::Docs/PNG Images>.

See L<PDF::Builder::Resource::XObject::Image::PNG> and
L<PDF::Builder::Resource::XObject::Image::PNG_IPL> for additional information
and C<examples/Content.pl>
for some examples of placing an image on a page (JPEG, but the principle is
the same). 

There is an optional PNG library (PNG_IPL) described, that gives more
capability than the default one. However, note that C<$file> can only be
a filename when using this library.

=cut

sub image_png {
    my ($self, $file, %opts) = @_;
    # copy dashed name options to preferred undashed format
    if (defined $opts{'-nouseIPL'} && !defined $opts{'nouseIPL'}) { $opts{'nouseIPL'} = delete($opts{'-nouseIPL'}); }
    if (defined $opts{'-silent'} && !defined $opts{'silent'}) { $opts{'silent'} = delete($opts{'-silent'}); }

    my ($rc, $obj);
    $rc = $self->LA_IPL();
    if ($rc) {
        # Image::PNG::Libpng available
        if (defined $opts{'nouseIPL'} && $opts{'nouseIPL'} == 1) {
            $rc = -1;  # don't use it
        }
    }
    if ($rc == 1) {
        # Image::PNG::Libpng (_IPL suffix) available and to be used
        require PDF::Builder::Resource::XObject::Image::PNG_IPL;
        $obj = PDF::Builder::Resource::XObject::Image::PNG_IPL->new($self->{'pdf'}, $file, %opts);
        $self->{'pdf'}->out_obj($self->{'pages'});
    } else {
        # Image::PNG::Libpng not available, or is but is not to be used
        require PDF::Builder::Resource::XObject::Image::PNG;
        $obj = PDF::Builder::Resource::XObject::Image::PNG->new($self->{'pdf'}, $file, %opts);
        $self->{'pdf'}->out_obj($self->{'pages'});

        if ($rc == 0 && $MSG_COUNT[1]++ == 0) {
            # give warning message once, unless silenced (silent) or
            # deliberately not using Image::PNG::Libpng (rc == -1)
            if (!defined $opts{'silent'} || $opts{'silent'} == 0) {
                print STDERR "Your system does not have Image::PNG::Libpng installed, ".
                             "so some\nPNG functions may not run correctly.\n";
                # even if silent only once, COUNT still incremented
            }
        }
    }
    $obj->{'usesIPL'} = PDFNum($rc);  # -1 available but unused
                                      #  0 not available
                                      #  1 available and used
                                      # $png->usesLib() to get number
    return $obj;
}

=item $rc = $pdf->LA_IPL()

Returns 1 if the library name (package) Image::PNG::Libpng is installed, and 
0 otherwise. For this optional library, this call can be used to know if it 
is safe to use certain functions. For example:

    if ($pdf->LA_IPL() {
        # is installed and usable
    } else {
        # not available. don't use 16bps or interlaced PNG image files
    }

=cut

# there doesn't seem to be a way to pass in a string (or bare) package name,
# to make a generic check routine
sub LA_IPL {
    my ($self) = @_;

    my ($rc);
    $rc = eval {
        require Image::PNG::Libpng;
        1;
    };
    if (!defined $rc) { $rc = 0; }  # else is 1
    if ($rc) {
	# installed, but not up to date?
	if ($Image::PNG::Libpng::VERSION < $LpngVersion) { $rc = 0; }
    }

    return $rc;
}

=item $gif = $pdf->image_gif($file, %opts)

Imports and returns a new GIF image object. C<$file> may be either a filename 
or a filehandle.

See L<PDF::Builder::Resource::XObject::Image::GIF> for additional information
and C<examples/Content.pl> for some examples of placing an image on a page 
(JPEG, but the principle is the same).

=cut

sub image_gif {
    my ($self, $file, %opts) = @_;

    require PDF::Builder::Resource::XObject::Image::GIF;
    my $obj = PDF::Builder::Resource::XObject::Image::GIF->new($self->{'pdf'}, $file);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $gdf = $pdf->image_gd($gd_object, %opts)

Imports and returns a new image object from Image::GD.

See L<PDF::Builder::Resource::XObject::Image::GD> for additional information
and C<examples/Content.pl> for some examples of placing an image on a page 
(JPEG, but the principle is the same).

=cut

sub image_gd {
    my ($self, $gd, %opts) = @_;

    require PDF::Builder::Resource::XObject::Image::GD;
    my $obj = PDF::Builder::Resource::XObject::Image::GD->new($self->{'pdf'}, $gd, %opts);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=back

=head1 COLORSPACE METHODS

=over

=item $colorspace = $pdf->colorspace($type, @arguments)

Colorspaces can be added to a PDF to either specifically control the output
color on a particular device (spot colors, device colors) or to save space by
limiting the available colors to a defined color palette (web-safe palette, ACT
file).

Once added to the PDF, they can be used in place of regular hex codes or named
colors:

    my $pdf = PDF::Builder->new();
    my $page = $pdf->page();
    my $content = $page->graphics();

    # Add colorspaces for a spot color and the web-safe color palette
    my $spot = $pdf->colorspace('spot', 'PANTONE Red 032 C', '#EF3340');
    my $web = $pdf->colorspace('web');

    # Fill using the spot color with 100% coverage
    $content->fill_color($spot, 1.0);

    # Stroke using the first color of the web-safe palette
    $content->stroke_color($web, 0);

    # Add a rectangle to the page
    $content->rectangle(100, 100, 200, 200);
    $content->paint();

    $pdf->save('sample.pdf');

The following types of colorspaces are supported

=over

=item spot

    my $spot = $pdf->colorspace('spot', $tint, $alt_color);

Spot colors are used to instruct a device (usually a printer) to use or emulate
a particular ink color (C<$tint>) for parts of the document. An C<$alt_color>
is provided for devices (e.g. PDF viewers) that don't know how to produce the
named color. It can either be an approximation of the color in RGB, CMYK, or
HSV formats, or a wildly different color (e.g. 100% magenta, C<%0F00>) to make
it clear if the spot color isn't being used as expected.

=item web

    my $web = $pdf->colorspace('web');

The web-safe color palette is a historical collection of colors that was used
when many display devices only supported 256 colors.

=item act

    my $act = $pdf->colorspace('act', $filename);

An Adobe Color Table (ACT) file provides a custom palette of colors that can be
referenced by PDF graphics and text drawing commands.

=item device

    my $devicen = $pdf->colorspace('device', @colorspaces);

A device-specific colorspace allows for precise color output on a given device
(typically a printing press), bypassing the normal color interpretation
performed by raster image processors (RIPs).

Device colorspaces are also needed if you want to blend spot colors:

    my $pdf = PDF::Builder->new();
    my $page = $pdf->page();
    my $content = $page->graphics();

    # Create a two-color device colorspace
    my $yellow = $pdf->colorspace('spot', 'Yellow', '%00F0');
    my $spot = $pdf->colorspace('spot', 'PANTONE Red 032 C', '#EF3340');
    my $device = $pdf->colorspace('device', $yellow, $spot);

    # Fill using a blend of 25% yellow and 75% spot color
    $content->fill_color($device, 0.25, 0.75);

    # Stroke using 100% spot color
    $content->stroke_color($device, 0, 1);

    # Add a rectangle to the page
    $content->rectangle(100, 100, 200, 200);
    $content->paint();

    $pdf->save('sample.pdf');

=back

=cut

sub colorspace {
    my $self = shift();
    my $type = shift();

    if      ($type eq 'act') {
        my $file = shift();
        return $self->colorspace_act($file);
    } elsif ($type eq 'web') {
        return $self->colorspace_web();
    } elsif ($type eq 'hue') {
        # This type is undocumented until either a reference can be found for
        # this being a standard palette like the web color palette, or POD is
        # added to the Hue colorspace class that describes how to use it.
        return $self->colorspace_hue();
    } elsif ($type eq 'spot') {
        my $name = shift();
        my $alt_color = shift();
        return $self->colorspace_separation($name, $alt_color);
    } elsif ($type eq 'device') {
        my @colors = @_;
        return $self->colorspace_devicen(\@colors);
    } else {
        croak "Unrecognized or unsupported colorspace: $type";
    }
}

=item $cs = $pdf->colorspace_act($file)

Returns a new colorspace object based on an Adobe Color Table file.

See L<PDF::Builder::Resource::ColorSpace::Indexed::ACTFile> for a
reference to the file format's specification.

=cut

sub colorspace_act {
    my ($self, $file) = @_;

    require PDF::Builder::Resource::ColorSpace::Indexed::ACTFile;
    return PDF::Builder::Resource::ColorSpace::Indexed::ACTFile->new($self->{'pdf'}, $file);
}

=item $cs = $pdf->colorspace_web()

Returns a new colorspace-object based on the "web-safe" color palette.

=cut

sub colorspace_web {
    my ($self) = @_;

    require PDF::Builder::Resource::ColorSpace::Indexed::WebColor;
    return PDF::Builder::Resource::ColorSpace::Indexed::WebColor->new($self->{'pdf'});
}

=item $cs = $pdf->colorspace_hue()

Returns a new colorspace-object based on the hue color palette.

See L<PDF::Builder::Resource::ColorSpace::Indexed::Hue> for an explanation.

=cut

sub colorspace_hue {
    my ($self) = @_;

    require PDF::Builder::Resource::ColorSpace::Indexed::Hue;
    return PDF::Builder::Resource::ColorSpace::Indexed::Hue->new($self->{'pdf'});
}

=item $cs = $pdf->colorspace_separation($tint, $color)

Returns a new separation colorspace object based on the parameters.

I<$tint> can be any valid ink identifier, including but not limited
to: 'Cyan', 'Magenta', 'Yellow', 'Black', 'Red', 'Green', 'Blue' or
'Orange'.

I<$color> must be a valid color specification limited to: '#rrggbb',
'!hhssvv', '%ccmmyykk' or a "named color" (rgb).

The colorspace model will automatically be chosen based on the
specified color.

=cut

sub colorspace_separation {
    my ($self, $tint, @clr) = @_;

    require PDF::Builder::Resource::ColorSpace::Separation;
    return PDF::Builder::Resource::ColorSpace::Separation->new($self->{'pdf'}, 
	                                                       pdfkey(), 
							       $tint, 
							       @clr);
}

=item $cs = $pdf->colorspace_devicen(\@tintCSx, $samples)

=item $cs = $pdf->colorspace_devicen(\@tintCSx)

Returns a new DeviceN colorspace object based on the parameters.

B<Example:>

    $cy = $pdf->colorspace_separation('Cyan',    '%f000');
    $ma = $pdf->colorspace_separation('Magenta', '%0f00');
    $ye = $pdf->colorspace_separation('Yellow',  '%00f0');
    $bk = $pdf->colorspace_separation('Black',   '%000f');

    $pms023 = $pdf->colorspace_separation('PANTONE 032CV', '%0ff0');

    $dncs = $pdf->colorspace_devicen( [ $cy,$ma,$ye,$bk, $pms023 ] );

The colorspace model will automatically be chosen based on the first
colorspace specified.

=cut

sub colorspace_devicen {
    my ($self, $clrs, $samples) = @_;
    $samples ||= 2;

    require PDF::Builder::Resource::ColorSpace::DeviceN;
    return PDF::Builder::Resource::ColorSpace::DeviceN->new($self->{'pdf'}, 
	                                                    pdfkey(), 
							    $clrs, 
							    $samples);
}

=back

=head1 BARCODE METHODS

=over

These are glue routines to the actual barcode rendering routines found
elsewhere.

=over

=item $bc = $pdf->xo_codabar(%opts)

=item $bc = $pdf->xo_code128(%opts)

=item $bc = $pdf->xo_2of5int(%opts)

=item $bc = $pdf->xo_3of9(%opts)

=item $bc = $pdf->xo_ean13(%opts)

Creates the specified barcode object as a form XObject.

=cut

# TBD PDF::API2 now has a convenience function to handle all the barcodes,
# but still keeps all the existing barcodes
#
# TBD consider moving these to a BarCodes subdirectory, as the number of bar
# code routines increases

sub xo_code128 {
    my ($self, @opts) = @_;

    require PDF::Builder::Resource::XObject::Form::BarCode::code128;
    my $obj = PDF::Builder::Resource::XObject::Form::BarCode::code128->new($self->{'pdf'}, @opts);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

sub xo_codabar {
    my ($self, @opts) = @_;

    require PDF::Builder::Resource::XObject::Form::BarCode::codabar;
    my $obj = PDF::Builder::Resource::XObject::Form::BarCode::codabar->new($self->{'pdf'}, @opts);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

sub xo_2of5int {
    my ($self, @opts) = @_;

    require PDF::Builder::Resource::XObject::Form::BarCode::int2of5;
    my $obj = PDF::Builder::Resource::XObject::Form::BarCode::int2of5->new($self->{'pdf'}, @opts);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

sub xo_3of9 {
    my ($self, @opts) = @_;

    require PDF::Builder::Resource::XObject::Form::BarCode::code3of9;
    my $obj = PDF::Builder::Resource::XObject::Form::BarCode::code3of9->new($self->{'pdf'}, @opts);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

sub xo_ean13 {
    my ($self, @opts) = @_;

    require PDF::Builder::Resource::XObject::Form::BarCode::ean13;
    my $obj = PDF::Builder::Resource::XObject::Form::BarCode::ean13->new($self->{'pdf'}, @opts);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=back

=back

=head1 OTHER METHODS

=over

=item $xo = $pdf->xo_form()

Returns a new form XObject.

=cut

sub xo_form {
    my $self = shift();

    my $obj = PDF::Builder::Resource::XObject::Form::Hybrid->new($self->{'pdf'});
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $egs = $pdf->egstate()

Returns a new extended graphics state object, as described
in L<PDF::Builder::Resource::ExtGState>.

=cut

sub egstate {
    my $self = shift();

    my $obj = PDF::Builder::Resource::ExtGState->new($self->{'pdf'}, pdfkey());
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $obj = $pdf->pattern(%opts)

Returns a new pattern object.

=cut

sub pattern {
    my ($self, %opts) = @_;

    my $obj = PDF::Builder::Resource::Pattern->new($self->{'pdf'}, undef, %opts);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $obj = $pdf->shading(%opts)

Returns a new shading object.

=cut

sub shading {
    my ($self, %opts) = @_;

    my $obj = PDF::Builder::Resource::Shading->new($self->{'pdf'}, undef, %opts);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $ndest = $pdf->named_destination()

Returns a new or existing named destination object.

=cut

sub named_destination {
    my ($self, $cat, $name, $obj) = @_;
    my $root = $self->{'catalog'};

    $root->{'Names'} ||= PDFDict();
    $root->{'Names'}->{$cat} ||= PDFDict();
    $root->{'Names'}->{$cat}->{'-vals'}  ||= {};
    $root->{'Names'}->{$cat}->{'Limits'} ||= PDFArray();
    $root->{'Names'}->{$cat}->{'Names'}  ||= PDFArray();

    unless (defined $obj) {
        $obj = PDF::Builder::NamedDestination->new($self->{'pdf'});
    }
    $root->{'Names'}->{$cat}->{'-vals'}->{$name} = $obj;

    my @names = sort {$a cmp $b} keys %{$root->{'Names'}->{$cat}->{'-vals'}};

    $root->{'Names'}->{$cat}->{'Limits'}->{' val'}->[0] = PDFString($names[0], 'n');
    $root->{'Names'}->{$cat}->{'Limits'}->{' val'}->[1] = PDFString($names[-1], 'n');

    @{$root->{'Names'}->{$cat}->{'Names'}->{' val'}} = ();

    foreach my $k (@names) {
        push @{$root->{'Names'}->{$cat}->{'Names'}->{' val'}},
        (   PDFString($k, 'n'),
            $root->{'Names'}->{$cat}->{'-vals'}->{$k}
        );
    }

    return $obj;
} # end of named_destination()

=back

=cut

# ==================================================
# input: level of checking, PDF as a string
#   level: 0 just return with any version override
#          1 return version override, and errors
#          2 return version override, and errors and warnings
#          3 return version override, plus errors, warnings, notes
#          4 like (3), plus dump analysis data
#          5 like (4), plus dump $self (PDF) contents
# returns any /Version value found in Catalog, last one if multiple ones found,
#   else undefined

sub IntegrityCheck {
    my ($self, $level, $string) = @_;

    my $level_nodiag   = 0;
    my $level_error    = 1;
    my $level_warning  = 2;
    my $level_note     = 3;
    my $level_dump     = 4;
    my $level_dumpself = 5;

    my $IC = "PDF Integrity Check:";

   #print "$IC level $level\n" if $level >= $level_error;
    my $Version = undef;
    my ($Info, $Root, $str, $pos, $Parent, @Kids, @others);

    my $idx_defined  = 0;  # has this object been explicitly defined?
    my $idx_refcount = 1;  # count of all pointing to this obj except as Kid
    my $idx_par_clmd = 2;  # other object claiming this object as Kid
    my $idx_parent   = 3;  # this object's /Parent entry
    my $idx_kid_cnt  = 4;  # size of kid_list
    my $idx_kid_list = 5;  # this object's /Kids list
    # intialize each element to [ 0 0 -1 -1 -1 [] ]

    return $Version if !length($string);  # nothing to examine?
    # even if $level 0, still want to get any higher /Version
    # build analysis data and issue errors/warnings at appropriate $level
    my @major = split /%%EOF/, $string; # typically [0] entire PDF [1] empty
    my %objList;
    my $update = -1;
    foreach (@major) {
	# update section number 0, 1, 2... with %%EOF in-between
	$update++;
	next if !length($_);

	# split on "endobj"
	my @rawObjects = split /endobj/, $_;
	# each element contains an object plus leading stuff, not incl endobj
	
	foreach my $rawObject (@rawObjects) {
	    next if !length($rawObject);

	    # remove bulky and unwanted stream...endstream
	    if ($rawObject =~ m/^(.*)stream\s.*\sendstream(.*)$/s) {
	        $rawObject = $1.$2;
	    }
            
            # trim off anything before obj clause. endobj already gone.
	    if ($rawObject =~ m/^(.*?)\s?(\d+) (\d+) obj\s(.*)$/s ||
	        $rawObject =~ m/^(.*?)\s?(\d+) (\d+) obj(.*)$/s) {
		$rawObject = $4;

		# found an obj, full string is $rawObject. parse into
		# selected fields, build $objList{key} entry.
		my $objKey = "$2.$3";  # e.g., 4 0 obj -> 4.0
		# if this is a replacement object in an update, clear Parent
		# and Kids
		if (defined $objList{$objKey} && $update > 0) {
		    $objList{$objKey}->[$idx_parent]   = -1;
		    $objList{$objKey}->[$idx_kid_cnt]  = -1;
		    $objList{$objKey}->[$idx_kid_list] = [];
		}
		# might have already created this object element as target 
		#  from another object 
		if (!defined $objList{$objKey}) {
		    $objList{$objKey} = [0, 0, -1, -1, -1, []];
		}
		# mark object as defined
		$objList{$objKey}->[$idx_defined] = 1;

                # found an object
                # looking for /Parent x y R
		#             /Kids [ x y R ]
		#             /Type = /Catalog -> /Version /x.y
		#              for now, ignoring any /BaseVersion
		#             all other x y R
		# remove from $rawObject as we find a match

		# /Parent x y R  -> $Parent
		if ($rawObject =~ m#/Parent(\s+)(\d+)(\s+)(\d+)(\s+)R#) {
		    $Parent = "$2.$4";
		    $str = "/Parent$1$2$3$4$5R";
		    $pos = index $rawObject, $str;
		    substr($rawObject, $pos, length($str)) = '';
		   # TBD realistically, do we need to check for >1 /Parent ?
                   #if ($objList{$objKey}->[$idx_parent] == -1) {
			# first /Parent (should not be more)
		        $objList{$objKey}->[$idx_parent] = $Parent;
		   #} else {
		   #    print STDERR "$IC Additional Parent ($Parent) in object $objKey, already list ".
           #                 "$objList{$objKey}->[$idx_parent] as Parent.\n" if $level >= $level_error;
		   #}
		}

		# /Kids [ x y R ] -> @Kids
		# should we check for multiple Kids arrays in one object (error)?
		if ($rawObject =~ m#/Kids(\s+)\[(.*)\]#) {
		    $str = "/Kids$1\[$2\]";
		    $pos = index $rawObject, $str;
		    substr($rawObject, $pos, length($str)) = '';

		    my $str2 = " $2"; # guarantee a leading \s
		    @Kids = ();
                    while (1) {
		        if ($str2 =~ m#(\s+)(\d+)(\s+)(\d+)(\s+)R#) {
			    $str = "$1$2$3$4$5R";
			    push @Kids, "$2.$4";
		            $pos = index $str2, $str;
		            substr($str2, $pos, length($str)) = '';
		        } else {
			    last;
		        }
		    }
		   # TBD: realistically, any need to check for >1 /Kids?
                   #if (!scalar(@{$objList{$objKey}->[$idx_kid_list]})) {
			# first /Kids (should not be more)
		        @{$objList{$objKey}->[$idx_kid_list]} = @Kids;
			$objList{$objKey}->[$idx_kid_cnt] = scalar(@Kids);
		   #} else {
		   #    print STDERR "$IC Multiple Kids lists in object $objKey, already list ".
           #                 "@{$objList{$objKey}->[$idx_kid_list]} as Kids.\n" if $level >= $level_error;
		   #}
		}

		# /Type /Catalog -> /Version /x.y -> $Version
		# both x and y are normally single digits, but allow room
		# just global $Version, assuming that each one physically
		#   later overrides any earlier ones
		if ($rawObject =~ m#/Type(\s+)/Catalog#) {
		    my $sp1 = $1;
		    if ($rawObject =~ m#/Version /(\d+)\.(\d+)#) {
			$Version = "$1.$2";
		        $str = "/Version$sp1/$Version";
		        $pos = index $rawObject, $str;
		        substr($rawObject, $pos, length($str)) = '';
		    }
		}

		# if using cross-reference stream, will find /Root x y R
		# and /Info x y R entries in an object of /Type /Xref
		#   it looks like last ones will win
		if ($rawObject =~ m#/Type(\s+)/XRef# ||
		    $rawObject =~ m#/Type/XRef#) {
		    if ($rawObject =~ m#/Root(\s+)(\d+)(\s+)(\d+)(\s+)R#) {
			$Root = "$2.$4";
		        $str = "/Root$1$2$3$4$5R";
		        $pos = index $rawObject, $str;
		        substr($rawObject, $pos, length($str)) = '';
		    }
		    if ($rawObject =~ m#/Info(\s+)(\d+)(\s+)(\d+)(\s+)R#) {
			$Info = "$2.$4";
		        $str = "/Info$1$2$3$4$5R";
		        $pos = index $rawObject, $str;
		        substr($rawObject, $pos, length($str)) = '';
		    }
		}

		# all other x y R -> @others
                @others = ();
		while (1) {
		    if ($rawObject =~ m#(\d+)(\s+)(\d+)(\s+)R#) {
			$str = "$1$2$3$4R";
			push @others, "$1.$3";
		        $pos = index $rawObject, $str;
		        substr($rawObject, $pos, length($str)) = '';
		    } else {
			last;
		    }
		}
		# go through all other refs and create element if necessary,
		#   then increment its refcnt array element
		foreach (@others) {
                    if (!defined $objList{$_}) {
		        $objList{$_} = [0, 0, -1, -1, -1, []];
		    }
		    $objList{$_}->[$idx_refcount]++;
		}
		foreach (@Kids) {
                    if (!defined $objList{$_}) {
		        $objList{$_} = [0, 0, -1, -1, -1, []];
		    }
		    $objList{$_}->[$idx_refcount]++;
		}

	    } else {
		# not an object, but could be other stuff of interest
		# looking for trailer -> /Root x y R & /Info x y R
		if ($rawObject =~ m/trailer/) {
                    if ($rawObject =~ m#trailer(.*)/Info(\s+)(\d+)(\s+)(\d+)(\s+)R#s) {
			$Info = "$3.$5";
		    }
                    if ($rawObject =~ m#trailer(.*)/Root(\s+)(\d+)(\s+)(\d+)(\s+)R#s) {
			$Root = "$3.$5";
		    }
		}
	    }
	}
    }

    # increment Root and Info objects reference counts
    # they probably SHOULD already be defined (issue warning if not)
    if (!defined $Root) {
	print STDERR "$IC No Root object defined!\n" if $level >= $level_error;
    } else {
        if (!defined $objList{$Root}) {
	    $objList{$Root} = [1, 0, -1, -1, -1, []];
	    print STDERR "$IC Root object $Root not found!\n" if $level >= $level_error;
        }
        $objList{$Root}->[$idx_refcount]++;
    }

    # Info is optional
    if (!defined $Info) {
	print STDERR "$IC No Info object defined!\n" if $level >= $level_note;
    } else {
        if (!defined $objList{$Info}) {
	    $objList{$Info} = [1, 0, -1, -1, -1, []];
	    print STDERR "$IC Info object $Info not found!\n" if $level >= $level_note;
	    # possibly in a deleted object (on free list)
        }
        $objList{$Info}->[$idx_refcount]++;
    }

    # revisit each element in objList
    #  visit each Kid, their $idx_par_clmd should be -1 (set to this object)
    #                    (if not -1, is on multiple Kids lists)
    #                  their $idx_parent should be this object
    #                  they should have a Parent declared
    #  any element with ref count of 0 and no Parent give warning unreachable
    #  TBD: anything else to add to things to check?
    foreach my $thisObj (sort keys %objList) {

	# was an object actually defined for this entry?
	# missing Info and Root messages already given, so flag is 1 ("defined")
	if ($objList{$thisObj}->[$idx_defined] == 0) {
	    print STDERR "$IC object $thisObj referenced, but no entry found.\n" if $level >= $level_note;
	    # it's apparently OK if the missing object is on the free list --
	    # it will just be ignored
	}

	# check any Kids
	if ($objList{$thisObj}[$idx_kid_cnt] > 0) {
	    # this object has children (/Kids), so explore them one level deep
	    for (my $kidObj=0; $kidObj<$objList{$thisObj}[$idx_kid_cnt]; $kidObj++) {
	        my $child = $objList{$thisObj}[$idx_kid_list]->[$kidObj];
		# child's claimed parent should be -1, set to thisObj
		if ($objList{$child}[$idx_par_clmd] == -1) {
		    # no one has claimed to be parent, so set to thisObj
		    $objList{$child}[$idx_par_clmd] = $thisObj;
		} else {
		    # someone else has already claimed to be parent
		    print STDERR "$IC object $thisObj wants to claim object $child as its child, ".
                         "but $objList{$child}[$idx_par_clmd] already has!\nPossibly $child ".
                         "is on more than one /Kids list?\n" if $level >= $level_error;
		}
	        # if no object defined for child, already flagged as missing
		if ($objList{$child}[$idx_defined] == 1) {
		    # child should list thisObj as its Parent
		    if      ($objList{$child}[$idx_parent] == -1) {
		        print STDERR "$IC object $thisObj claims $child as a child (/Kids), but ".
                             "$child claims no Parent!\n" if $level >= $level_error;
		        $objList{$child}[$idx_parent] = $thisObj;
		    } elsif ($objList{$child}[$idx_parent] != $thisObj) {
		        print STDERR "$IC object $thisObj claims $child as a child (/Kids), but ".
                             "$child claims $objList{$child}[$idx_parent] as its parent!\n" 
                    if $level >= $level_error;
                    }
		}
	    }
	}

 	if ($objList{$thisObj}[$idx_parent] == -1 &&
 	    $objList{$thisObj}[$idx_refcount] == 0) {
 	    print STDERR "$IC Warning: object $thisObj appears to be unreachable.\n" if $level >= $level_note;
 	}
    }

    if ($level >= $level_dump) {
	# dump analysis data
        use Data::Dumper;
        my $d = Data::Dumper->new([\%objList]);
	print "========= dump of $IC analysis data ===========\n";
        print $d->Dump();
    }

    # if have entire processed PDF in $self
    if ($level >= $level_dumpself) {
    	# dump whole data
        use Data::Dumper;
        my $d = Data::Dumper->new([$self]);
	print "========= dump of $IC PDF (self) data ===========\n";
        print $d->Dump();
    }

    return $Version;
}

1;

__END__
