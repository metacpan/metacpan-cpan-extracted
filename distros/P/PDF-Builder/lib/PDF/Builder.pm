package PDF::Builder;

use strict;
use warnings;
#no warnings qw[ deprecated recursion uninitialized ];

# $VERSION defined here so developers can run PDF::Builder from git.
# it should be automatically updated as part of the CPAN build.
our $VERSION = '3.021'; # VERSION
my $LAST_UPDATE = '3.021'; # manually update whenever code is changed

my $GrTFversion = 7;     # minimum version of Graphics::TIFF
my $LpngVersion = 0.56;  # minimum version of Image::PNG::Libpng

use Carp;
use Encode qw(:all);
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

use Scalar::Util qw(weaken);

our @FontDirs = ( (map { "$_/PDF/Builder/fonts" } @INC),
                  qw[ /usr/share/fonts /usr/local/share/fonts c:/windows/fonts c:/winnt/fonts ] );
our @MSG_COUNT = (0,  # [0] Graphics::TIFF not installed
	          0,  # [1] Image::PNG::Libpng not installed
		  0,  # [2] TBD...
	         );
our $outVer = 1.4; # desired PDF version for output, bump up w/ warning on read or feature output
our $msgVer = 1;   # 0=don't, 1=do issue message when PDF output version is bumped up
our $myself;       # holds self->pdf

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
    $page = $pdf->openpage($page_number);

    # Set the page size
    $page->mediabox('Letter');

    # Add a built-in font to the PDF
    $font = $pdf->corefont('Helvetica-Bold');

    # Add an external TTF font to the PDF
    $font = $pdf->ttfont('/path/to/font.ttf');

    # Add some text to the page
    $text = $page->text();
    $text->font($font, 20);
    $text->translate(200, 700);
    $text->text('Hello World!');

    # Save the PDF
    $pdf->saveas('/path/to/new.pdf');

=head1 SOME SPECIAL NOTES

See the file README (in downloadable package and on CPAN) for a summary of 
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

=head2 SUPPORTED PERL VERSIONS

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
If you need to use this module on a server with an extremely out-of-date version
of Perl, consider using either plenv or Perlbrew to run a newer version of Perl
without needing admin privileges.

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

=head1 AUTHOR

PDF::API2 was originally written by Alfred Reibenschuh. See the HISTORY section
for more information.

It was maintained by Steve Simms.

PDF::Builder is currently being maintained by Phil M. Perry.

=head2 SUPPORT

The full source is on https://github.com/PhilterPaper/Perl-PDF-Builder.

The release distribution is on CPAN: https://metacpan.org/pod/PDF::Builder.

Bug reports are on https://github.com/PhilterPaper/Perl-PDF-Builder/issues?q=is%3Aissue+sort%3Aupdated-desc (with "bug" label), feature requests have an "enhancement" label, and general discussions (architecture, roadmap, etc.) have a "general discussion" label.

Do B<not> under I<any> circumstances open a PR (Pull Request) to report a bug. It is a waste of both your and our time and effort. Open a regular ticket (issue), and attach a Perl (.pl) program illustrating the problem, if possible. If you believe that you have a program patch, and offer to share it as a PR, we may give the go-ahead. Unsolicited PRs may be closed without further action.

=head1 LICENSE

This software is Copyright (c) 2017-2020 by Phil M. Perry.

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

=head1 GENERIC METHODS

=over

=item $pdf = PDF::Builder->new(%options)

=item $pdf = PDF::Builder->new()

Creates a new PDF object. 

B<Options>

=over

=item -file

If you will be saving it as a file and
already know the filename, you can give the '-file' option to minimize
possible memory requirements later on. 

=item -compress

The '-compress' option can be
given to specify stream compression: default is 'flate', 'none' is no
compression. No other compression methods are currently supported.

=item -outver

The '-outver' option defaults to 1.4 as the output PDF version and the highest 
allowed feature version (attempts to use anything higher will give a warning).
If an existing PDF with a higher version is read in, -outver will be increased 
to that version, with a warning.

=item -msgver

The '-msgver' option value of 1 (default) gives a warning message if the 
'-outver' PDF level has to be bumped up due to either a higher PDF level file 
being read in, or a higher level feature was requested. A value of 0 
suppresses the warning message.

=item -diaglevel

The '-diaglevel' option can be
given to specify the level of diagnostics given by IntegrityCheck(). The
default is level 2 (errors and warnings). 
See L<PDF::Builder::Docs/IntegrityCheck> for more information.

=back

B<Example:>

    $pdf = PDF::Builder->new();
    ...
    print $pdf->stringify();

    $pdf = PDF::Builder->new(-compress => 'none');
    # equivalent to $pdf->{'forcecompress'} = 'none'; (or older, 0)

    $pdf = PDF::Builder->new();
    ...
    $pdf->saveas('our/new.pdf');

    $pdf = PDF::Builder->new(-file => 'our/new.pdf');
    ...
    $pdf->save();

=cut

sub new {
    my ($class, %options) = @_;

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
    $self->{'pdf'}->new_obj($self->{'pages'}->{'Resources'}) unless $self->{'pages'}->{'Resources'}->is_obj($self->{'pdf'});
    $self->{'catalog'} = $self->{'pdf'}->{'Root'};
    weaken $self->{'catalog'};
    $self->{'fonts'} = {};
    $self->{'pagestack'} = [];

    $self->{'pdf'}->{' userUnit'} = 1.0; # default global User Unit
    $self->mediabox('letter');  # default to US Letter 8.5in x 11in 

    if (exists $options{'-compress'}) {
      $self->{'forcecompress'} = $options{'-compress'};
      # at this point, no validation of given value! none/flate (0/1).
      # note that >0 is often used as equivalent to 'flate'
    } else {
      $self->{'forcecompress'} = 'flate';
      # code should also allow integers 0 (= 'none') and >0 (= 'flate') 
      # for compatibility with old usage where forcecompress is directly set. 
    }
    if (exists $options{'-diaglevel'}) {
	my $diaglevel = $options{'-diaglevel'};
	if ($diaglevel < 0 || $diaglevel > 5) {
	    print "-diaglevel must be in range 0-5. using 2\n";
	    $diaglevel = 2;
	}
	$self->{'diaglevel'} = $diaglevel;
    } else {
	$self->{'diaglevel'} = 2; # default: errors and warnings
    }

    $self->preferences(%options);
    if (defined $options{'-outver'}) {
        if ($options{'-outver'} >= 1.4) {
	    $self->{'pdf'}->{' version'} = $outVer = $options{'-outver'};
	} else {
	    print STDERR "Invalid -outver given, or less than 1.4. Ignored.\n";
	}
    }
    if (defined $options{'-msgver'}) {
        if ($options{'-msgver'} == 0 || $options{'-msgver'} == 1) {
            $msgVer = $options{'-msgver'};
        } else {
            print STDERR "Invalid -msgver given, not 0 or 1. Ignored.\n";
        }
    }
    if ($options{'-file'}) {
        $self->{'pdf'}->create_file($options{'-file'});
        $self->{'partial_save'} = 1;
    }
    $self->{'infoMeta'} = [qw(Author CreationDate ModDate Creator Producer Title Subject Keywords)];

    my $version = eval { $PDF::Builder::VERSION } || '(Unreleased Version)';
   #$self->info('Producer' => "PDF::Builder $version [$^O]");
    $self->info('Producer' => "PDF::Builder $version [see https://github.com/PhilterPaper/Perl-PDF-Builder/blob/master/INFO/SUPPORT]");

    return $self;
} # end of new()

=item $pdf = PDF::Builder->open($pdf_file, %options)

=item $pdf = PDF::Builder->open($pdf_file)

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
    my ($class, $file, %options) = @_;
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

    my $self = $class->open_scalar($content, %options);
    $self->{'pdf'}->{' fname'} = $file;

    return $self;
} # end of open()

# when outputting a PDF feature, verCheckOutput(n, 'feature name') returns TRUE 
# if n > $pdf->{' version'), plus a warning message. It returns FALSE otherwise.
#
#  a typical use:
#
#  PDF::Builder->verCheckOutput(1.6, "portzebie with foo-dangle");
#
#  if -msgver defaults to 1, a message will be output if the output PDF version 
#  has to be increased to 1.6 in order to use the "portzebie" feature
#
# this is still somewhat experimental, and as experience is gained, the code 
# might have to be modified.
#
sub verCheckOutput {
    my ($dummy, $PDFver, $featureName) = @_;  # $self will be this package's

    # check if feature required PDF version is higher than planned output
    # ' version' should be the same as $outVer
    if ($PDFver > $outVer) {
        if ($msgVer) {
	    print "PDF version of requested feature '$featureName'\n  is higher than outVer of $outVer (outVer reset to $PDFver)\n";
	}
        $outVer = $myself->{' version'} = $PDFver;
        return 1;
    } else {
        return 0;
    }
}
# when reading in a PDF, verCheckInput(n) gives a warning message if n (the PDF 
# version just read in) > outVer, and resets outVer to n. return TRUE if 
# outVer changed, FALSE otherwise. outVer is used instead of 
# $pdf->{' version'} because the latter is often overwritten by a file read 
# operation.
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

    # warning message and bump up outVer if read-in PDF level higher
    if ($PDFver > $outVer) {
        if ($msgVer) {
	    print "PDF version just read in is higher than outVer of $outVer (outVer reset to $PDFver)\n";
	}
        $outVer = $self->{'pdf'}->{' version'} = $PDFver;
        return 1;
    } else {
        return 0;
    }
}

=item $pdf = PDF::Builder->open_scalar($pdf_string, %options)

=item $pdf = PDF::Builder->open_scalar($pdf_string)

Opens a PDF contained in a string. See C<new()> for other options.

=over

=item -diags => 1

Display warnings when non-conforming PDF structure is found, and fix up
where possible. See L<PDF::Builder::Basic::PDF::File> for more information.

=back

B<Example:>

    # Read a PDF into a string, for the purpose of demonstration
    open $fh, 'our/old.pdf' or die $@;
    undef $/;  # Read the whole file at once
    $pdf_string = <$fh>;

    $pdf = PDF::Builder->open_scalar($pdf_string);
    ...
    $pdf->saveas('our/new.pdf');


=cut

sub open_scalar {
    my ($class, $content, %options) = @_;

    my $self = {};
    bless $self, $class;
    foreach my $parameter (keys %options) {
        $self->default($parameter, $options{$parameter});
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
		print STDERR "Unable to update 'content' version because override '$newVer' is longer than header version '$currentVer'.\nYou may receive warnings about features that bump up the PDF level.\n";
	    } else {
		if (length($newVer) < length($currentVer)) {
		    # unlikely, but cover all the bases
		    $newVer = substr($newVer, 0, length($currentVer));
		} 
	        substr($content, $pos+5, length($newVer)) = $newVer;
		$outVer = $newVer;
            }
	}
    }

    my $fh;
    CORE::open($fh, '+<', \$content) or die "Can't begin scalar IO";

    # this would replace any existing self->pdf with a new one
    $self->{'pdf'} = PDF::Builder::Basic::PDF::File->open($fh, 1, %options);
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
    if (exists $options{'-compress'}) {
      $self->{'forcecompress'} = $options{'-compress'};
      # at this point, no validation of given value! none/flate (0/1).
      # note that >0 is often used as equivalent to 'flate'
    } else {
      $self->{'forcecompress'} = 'flate';
      # code should also allow integers 0 (= 'none') and >0 (= 'flate') 
      # for compatibility with old usage where forcecompress is directly set. 
    }
    if (exists $options{'-diaglevel'}) {
      $self->{'diaglevel'} = $options{'-diaglevel'};
      if ($self->{'diaglevel'} < 0 || $self->{'diaglevel'} > 5) {
        $self->{'diaglevel'} = 2;
      }
    } else {
      $self->{'diaglevel'} = 2;
    }
    $self->{'fonts'} = {};
    $self->{'infoMeta'} = [qw(Author CreationDate ModDate Creator Producer Title Subject Keywords)];

    return $self;
} # end of open_scalar()

=item $pdf->preferences(%options)

Controls viewing preferences for the PDF, including the B<Page Mode>, 
B<Page Layout>, B<Viewer>, and B<Initial Page> Options. See 
L<PDF::Builder::Docs/Preferences - set user display preferences> for details on all these 
option groups.

=cut

sub preferences {
    my ($self, %options) = @_;

    # Page Mode Options
    if      ($options{'-fullscreen'}) {
        $self->{'catalog'}->{'PageMode'} = PDFName('FullScreen');
    } elsif ($options{'-thumbs'}) {
        $self->{'catalog'}->{'PageMode'} = PDFName('UseThumbs');
    } elsif ($options{'-outlines'}) {
        $self->{'catalog'}->{'PageMode'} = PDFName('UseOutlines');
    } else {
        $self->{'catalog'}->{'PageMode'} = PDFName('UseNone');
    }

    # Page Layout Options
    if      ($options{'-singlepage'}) {
        $self->{'catalog'}->{'PageLayout'} = PDFName('SinglePage');
    } elsif ($options{'-onecolumn'}) {
        $self->{'catalog'}->{'PageLayout'} = PDFName('OneColumn');
    } elsif ($options{'-twocolumnleft'}) {
        $self->{'catalog'}->{'PageLayout'} = PDFName('TwoColumnLeft');
    } elsif ($options{'-twocolumnright'}) {
        $self->{'catalog'}->{'PageLayout'} = PDFName('TwoColumnRight');
    } else {
        $self->{'catalog'}->{'PageLayout'} = PDFName('SinglePage');
    }

    # Viewer Preferences
    $self->{'catalog'}->{'ViewerPreferences'} ||= PDFDict();
    $self->{'catalog'}->{'ViewerPreferences'}->realise();

    if ($options{'-hidetoolbar'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'HideToolbar'} = PDFBool(1);
    }
    if ($options{'-hidemenubar'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'HideMenubar'} = PDFBool(1);
    }
    if ($options{'-hidewindowui'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'HideWindowUI'} = PDFBool(1);
    }
    if ($options{'-fitwindow'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'FitWindow'} = PDFBool(1);
    }
    if ($options{'-centerwindow'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'CenterWindow'} = PDFBool(1);
    }
    if ($options{'-displaytitle'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'DisplayDocTitle'} = PDFBool(1);
    }
    if ($options{'-righttoleft'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'Direction'} = PDFName('R2L');
    }

    if      ($options{'-afterfullscreenthumbs'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'NonFullScreenPageMode'} = PDFName('UseThumbs');
    } elsif ($options{'-afterfullscreenoutlines'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'NonFullScreenPageMode'} = PDFName('UseOutlines');
    } else {
        $self->{'catalog'}->{'ViewerPreferences'}->{'NonFullScreenPageMode'} = PDFName('UseNone');
    }

    if ($options{'-printscalingnone'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'PrintScaling'} = PDFName('None');
    }

    if      ($options{'-simplex'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'Duplex'} = PDFName('Simplex');
    } elsif ($options{'-duplexfliplongedge'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'Duplex'} = PDFName('DuplexFlipLongEdge');
    } elsif ($options{'-duplexflipshortedge'}) {
        $self->{'catalog'}->{'ViewerPreferences'}->{'Duplex'} = PDFName('DuplexFlipShortEdge');
    }

    # Open Action
    if ($options{'-firstpage'}) {
        my ($page, %args) = @{$options{'-firstpage'}};
        $args{'-fit'} = 1 unless scalar keys %args;

        # $page can be either a page number (which needs to be wrapped
        # in PDFNum) or a page object (which doesn't).
        $page = PDFNum($page) unless ref($page);

        if      (defined $args{'-fit'}) {
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('Fit'));
        } elsif (defined $args{'-fith'}) {
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('FitH'), PDFNum($args{'-fith'}));
        } elsif (defined $args{'-fitb'}) {
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('FitB'));
        } elsif (defined $args{'-fitbh'}) {
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('FitBH'), PDFNum($args{'-fitbh'}));
        } elsif (defined $args{'-fitv'}) {
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('FitV'), PDFNum($args{'-fitv'}));
        } elsif (defined $args{'-fitbv'}) {
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('FitBV'), PDFNum($args{'-fitbv'}));
        } elsif (defined $args{'-fitr'}) {
            croak 'insufficient parameters to -fitr => []' unless scalar @{$args{'-fitr'}} == 4;
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('FitR'), map { PDFNum($_) } @{$args{'-fitr'}});
        } elsif (defined $args{'-xyz'}) {
            croak 'insufficient parameters to -xyz => []' unless scalar @{$args{'-xyz'}} == 3;
            $self->{'catalog'}->{'OpenAction'} = PDFArray($page, PDFName('XYZ'), map { PDFNum($_) } @{$args{'-xyz'}});
        }
    }
    $self->{'pdf'}->out_obj($self->{'catalog'});

    return $self;
}  # end of preferences()

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

=item $version = $pdf->version($new_version)

=item $version = $pdf->version()

Get/set the PDF version (e.g. 1.4). 

For compatibility with earlier releases, if no decimal point is given, assume
"1." precedes the number given.

A warning message is given if you attempt to I<decrease> the PDF version, as you
might have already read in a higher level file, or used a higher level feature.

=cut

sub version {
    my $self = shift();
    if (scalar @_) {
        my $version = shift();
	if ($version =~ m/^\d+$/) { $version = "1.$version"; }  # no x.? assume it's 1.something
        croak "Invalid version $version" unless $version =~ /^(\d+\.\d+)$/;
	if ($outVer > $1) { 
	    print "Warning: call to self->version() to LOWER the output PDF version number!\n";
	}
        $self->{'pdf'}->{' version'} = $outVer = $1;
    }

    return $self->{'pdf'}->{' version'};
}

=item $bool = $pdf->isEncrypted()

Checks if the previously opened PDF is encrypted.

=cut

sub isEncrypted {
    my $self = shift();
    return defined($self->{'pdf'}->{'Encrypt'}) ? 1 : 0;
}

=item %infohash = $pdf->info(%infohash)

Gets/sets the info structure of the document.

See L<PDF::Builder::Docs/info Example> section for an example of the use
of this method.

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

=item @metadata_attributes = $pdf->infoMetaAttributes(@metadata_attributes)

Gets/sets the supported info-structure tags.

B<Example:>

    @attributes = $pdf->infoMetaAttributes;
    print "Supported Attributes: @attr\n";

    @attributes = $pdf->infoMetaAttributes('CustomField1');
    print "Supported Attributes: @attributes\n";

=cut

sub infoMetaAttributes {
    my ($self, @attr) = @_;

    if (scalar @attr) {
        my %at = map { $_ => 1 } @{$self->{'infoMeta'}}, @attr;
        @{$self->{'infoMeta'}} = keys %at;
    }

    return @{$self->{'infoMeta'}};
}

=item $xml = $pdf->xmpMetadata($xml)

Gets/sets the XMP XML data stream.

See L<PDF::Builder::Docs/XMP XML example> section for an example of the use
of this method.

=cut

sub xmpMetadata {
    my ($self, $value) = @_;

    if (not defined($self->{'catalog'}->{'Metadata'})) {
        $self->{'catalog'}->{'Metadata'} = PDFDict();
        $self->{'catalog'}->{'Metadata'}->{'Type'} = PDFName('Metadata');
        $self->{'catalog'}->{'Metadata'}->{'Subtype'} = PDFName('XML');
        $self->{'pdf'}->new_obj($self->{'catalog'}->{'Metadata'});
    } else {
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
} # end of xmpMetadata()

=item $pdf->pageLabel($index, $options)

Sets page label options.

B<Supported Options:>

=over

=item -style

Roman, roman, decimal, Alpha or alpha.

=item -start

Restart numbering at given number.

=item -prefix

Text prefix for numbering.

=back

B<Example:>

    # Start with Roman Numerals
    $pdf->pageLabel(0, {
        -style => 'roman',
    });

    # Switch to Arabic
    $pdf->pageLabel(4, {
        -style => 'decimal',
    });

    # Numbering for Appendix A
    $pdf->pageLabel(32, {
        -start => 1,
        -prefix => 'A-'
    });

    # Numbering for Appendix B
    $pdf->pageLabel( 36, {
        -start => 1,
        -prefix => 'B-'
    });

    # Numbering for the Index
    $pdf->pageLabel(40, {
        -style => 'Roman'
        -start => 1,
        -prefix => 'Index '
    });

=cut

sub pageLabel {
    my $self = shift();

    $self->{'catalog'}->{'PageLabels'} ||= PDFDict();
    $self->{'catalog'}->{'PageLabels'}->{'Nums'} ||= PDFArray();

    my $nums = $self->{'catalog'}->{'PageLabels'}->{'Nums'};
    while (scalar @_) {
        my $index = shift();
        my $opts = shift();

        $nums->add_elements(PDFNum($index));

        my $d = PDFDict();
        if (defined $opts->{'-style'}) {
            $d->{'S'} = PDFName($opts->{'-style'} eq 'Roman' ? 'R' :
                                $opts->{'-style'} eq 'roman' ? 'r' :
                                $opts->{'-style'} eq 'Alpha' ? 'A' :
                                $opts->{'-style'} eq 'alpha' ? 'a' : 'D');
        } else {
            $d->{'S'} = PDFName('D');
        }

        if (defined $opts->{'-prefix'}) {
            $d->{'P'} = PDFString($opts->{'-prefix'}, 's');
        }

        if (defined $opts->{'-start'}) {
            $d->{'St'} = PDFNum($opts->{'-start'});
        }

        $nums->add_elements($d);
    }

    return;
} # end of pageLabel()

=item $pdf->finishobjects(@objects)

Force objects to be written to file if possible.

B<Example:>

    $pdf = PDF::Builder->new(-file => 'our/new.pdf');
    ...
    $pdf->finishobjects($page, $gfx, $txt);
    ...
    $pdf->save();

=cut

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

=cut

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

Save the document to an already-defined file (or filename) and 
remove the object structure from memory.

B<Caution:> Although the object C<$pdf> will still exist, it is no longer
usable for any purpose after invoking this method! You will receive error
messages about "can't call method new_obj on an undefined value".

B<Example:>

    $pdf = PDF::Builder->new(-file => 'file_to_output');
    ...
    $pdf->save();

=cut

sub save {
    my ($self) = @_;

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

=item $string = $pdf->stringify()

Return the document as a string and remove the object structure from memory.

B<Caution:> Although the object C<$pdf> will still exist, it is no longer
usable for any purpose after invoking this method! You will receive error
messages about "can't call method new_obj on an undefined value".

B<Example:>

    $pdf = PDF::Builder->new();
    ...
    print $pdf->stringify();

=cut

# Maintainer's note: The object is being destroyed because it contains
# circular references that would otherwise result in memory not being
# freed if the object merely goes out of scope.  If possible, the
# circular references should be eliminated so that stringify doesn't
# need to be destructive.
#
# I've opted not to just require a separate call to release() because
# it would likely introduce memory leaks in many existing programs
# that use this module.
# - Steve S. (see bug RT 81530)

sub stringify {
    my $self = shift();

    my $str = '';
    # is only set to 1 (within open_scalar()), otherwise is undef
    if ($self->{'opened_scalar'}) { 
        $self->{'pdf'}->append_file();
        $str = ${$self->{'content_ref'}};
    } else {
        my $fh = FileHandle->new();
        # we should be writing to the STRING $str
        CORE::open($fh, '>', \$str) || die "Can't begin scalar IO";
        $self->{'pdf'}->out_file($fh);
        $fh->close();
    }
    $self->end();

    return $str;
}

# there IS a release() method defined and documented in Basic/PDF/File.pm
# it's not clear whether this release is just an internal (rename to _release)
sub release {
    my $self = shift();
    $self->end();
    return;
}

=item $pdf->end()

Remove the object structure from memory. PDF::Builder contains circular
references, so this call is necessary in long-running processes to
keep from running out of memory.

This will be called automatically when you save or stringify a PDF.
You should only need to call it explicitly if you are reading PDF
files and not writing them.

=cut

sub end {
    my $self = shift();
    $self->{'pdf'}->release() if defined $self->{'pdf'};

    foreach my $key (keys %$self) {
        $self->{$key} = undef;
        delete $self->{$key};
    }

    return;
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

If $page_number is -1, the new page is inserted as the second-last page;
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

=item $page = $pdf->openpage($page_number)

Returns the L<PDF::Builder::Page> object of page $page_number.
This is similar to C<< $page = $pdf->page() >>, except that C<$page> is 
I<not> a new, empty page; but contains the contents of that existing page.

If $page_number is 0 or -1, it will return the last page in the
document.

B<Example:>

    $pdf  = PDF::Builder->open('our/99page.pdf');
    $page = $pdf->openpage(1);   # returns the first page
    $page = $pdf->openpage(99);  # returns the last page
    $page = $pdf->openpage(-1);  # returns the last page
    $page = $pdf->openpage(999); # returns undef

=cut

sub openpage {
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
        if ((not defined($page->{' fixed'}) or $page->{' fixed'} < 1) and 
            ($rotate = $page->find_prop('Rotate')) ) {
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

        if (defined $page->{'Contents'} and (not defined($page->{' fixed'}) or $page->{' fixed'} < 1)) {
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

            ## $content->{'Length'} = PDFNum(length($content->{' stream'}));
            # this will be fixed by the following code or content or filters

            ## if we like compress we will do it now to do quicker saves
            if ($self->{'forcecompress'} eq 'flate' || 
                $self->{'forcecompress'} =~ m/^[1-9]\d*$/) {
                # $content->compressFlate();
                $content->{' stream'} = dofilter($content->{'Filter'}, $content->{' stream'});
                $content->{' nofilt'} = 1;
                delete $content->{'-docompress'};
                $content->{'Length'} = PDFNum(length($content->{' stream'}));
            }
        }
        $page->{' fixed'} = 1;
    }

    $self->{'pdf'}->out_obj($page);
    $self->{'pdf'}->out_obj($self->{'pages'});
    $page->{' apipdf'} = $self->{'pdf'};
    $page->{' api'} = $self;
    weaken $page->{' apipdf'};
    weaken $page->{' api'};

    return $page;
} # end of openpage()

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

=item $xoform = $pdf->importPageIntoForm($source_pdf, $source_page_number)

Returns a Form XObject created by extracting the specified page from 
$source_pdf.

This is useful if you want to transpose the imported page somewhat
differently onto a page (e.g. two-up, four-up, etc.).

If $source_page_number is 0 or -1, it will return the last page in the
document.

B<Example:>

    $pdf = PDF::Builder->new();
    $old = PDF::Builder->open('our/old.pdf');
    $page = $pdf->page();
    $gfx = $page->gfx();

    # Import Page 2 from the old PDF
    $xo = $pdf->importPageIntoForm($old, 2);

    # Add it to the new PDF's first page at 1/2 scale
    $gfx->formimage($xo, 0, 0, 0.5);

    $pdf->saveas('our/new.pdf');

B<Note:> You can only import a page from an existing PDF file.

=cut

sub importPageIntoForm {
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
        $s_page = $s_pdf->openpage($s_idx);
    }

    $self->{'apiimportcache'} ||= {};
    $self->{'apiimportcache'}->{$s_pdf} ||= {};

    # This should never get past MediaBox, since it's a required object.
    foreach my $k (qw(MediaBox ArtBox TrimBox BleedBox CropBox)) {
       #next unless defined $s_page->{$k};
       #my $box = _walk_obj($self->{'apiimportcache'}->{$s_pdf}, $s_pdf->{'pdf'}, $self->{'pdf'}, $s_page->{$k});
        next unless defined $s_page->find_prop($k);
        my $box = _walk_obj($self->{'apiimportcache'}->{$s_pdf}, $s_pdf->{'pdf'}, $self->{'pdf'}, $s_page->find_prop($k));
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
                $xo->resource($sk, $ssk, _walk_obj($self->{'apiimportcache'}->{$s_pdf}, $s_pdf->{'pdf'}, $self->{'pdf'}, $s_page->{$k}->{$sk}->{$ssk}));
            }
        }
    }

    # create a whole content stream
    ## technically it is possible to submit an unfinished
    ## (e.g., newly created) source-page, but that's nonsense,
    ## so we expect a page fixed by openpage and die otherwise
    die "page not processed via openpage ..." unless $s_page->{' fixed'} == 1;

    # since the source page comes from openpage it may already
    # contain the required starting 'q' without the final 'Q'
    # if forcecompress is in effect
    if (defined $s_page->{'Contents'}) {
        $s_page->fixcontents();

        $xo->{' stream'} = '';
        # openpage pages only contain one stream
        my ($k) = $s_page->{'Contents'}->elements();
        $k->realise();
        if ($k->{' nofilt'}) {
            # we have a finished stream here
            # so we unfilter
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
} # end of importPageIntoForm()

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

    $pdf = PDF::Builder->new();
    $old = PDF::Builder->open('our/old.pdf');

    # Add page 2 from the old PDF as page 1 of the new PDF
    $page = $pdf->import_page($old, 2);

    $pdf->saveas('our/new.pdf');

B<Note:> You can only import a page from an existing PDF file.

=cut

# importpage() renamed to import_page()

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
        $s_page = $s_pdf->openpage($s_idx);
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

            $AcroForm = _walk_obj({}, $s_pdf->{'pdf'}, $self->{'pdf'}, $a, qw(NeedAppearances SigFlags CO DR DA Q));
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

=item $count = $pdf->pages()

Returns the number of pages in the document.

=cut

sub pages {
    my $self = shift();
    return scalar @{$self->{'pagestack'}};
}

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

    PDF::Builder->verCheckOutput(1.6, "set User Unit");
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

# utility to handle calling page_size, and name with or without -orient setting
sub _bbox {
    my ($self, @corners) = @_;

    # if 1 or 3 elements in @corners, and [0] contains a letter, it's a name
    my $isName = 0;
    if (scalar @corners && $corners[0] =~ m/[a-z]/i) { $isName = 1; }

    if (scalar @corners == 3) {
	    # name plus one option (-orient)
	    my ($name, %opts) = @corners;
	    @corners = page_size(($name)); # now 4 numeric values
	    if (defined $opts{'-orient'}) {
	        if ($opts{'-orient'} =~ m/^l/i) { # 'landscape' or just 'l'
		        # 0 0 W H -> 0 0 H W
		        my $temp;
		        $temp = $corners[2]; $corners[2] = $corners[3]; $corners[3] = $temp;
	        }
	    }
    } else {
        # name without [-orient] option, or numeric coordinates given
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

=item $pdf->mediabox($name, -orient => 'orientation')

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

=item $pdf->cropbox($name, -orient => 'orientation')

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

=item $pdf->bleedbox($name, -orient => 'orientation')

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

=item $pdf->trimbox($name, -orient => 'orientation')

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

=item $pdf->artbox($name, -orient => 'orientation')

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

=item @directories = PDF::Builder::addFontDirs($dir1, $dir2, ...)

Adds one or more directories to the search path for finding font
files.

Returns the list of searched directories.

=cut

sub addFontDirs {
    my @dirs = @_;
    push @FontDirs, @dirs;
    return @FontDirs;
}

sub _findFont {
    my $font = shift();

    my @fonts = ($font, map { "$_/$font" } @FontDirs);
    shift @fonts while scalar(@fonts) and not -f $fonts[0];

    return $fonts[0];
}

=item $font = $pdf->corefont($fontname, %options)

=item $font = $pdf->corefont($fontname)

Returns a new Adobe core font object. For details, see L<PDF::Builder::Docs/Core Fonts>.

See also L<PDF::Builder::Resource::Font::CoreFont>.

=cut

sub corefont {
    my ($self, $name, %opts) = @_;

    require PDF::Builder::Resource::Font::CoreFont;
    my $obj = PDF::Builder::Resource::Font::CoreFont->new($self->{'pdf'}, $name, %opts);
    $self->{'pdf'}->out_obj($self->{'pages'});
    $obj->tounicodemap() if $opts{'-unicodemap'}; # UTF-8 not usable

    return $obj;
}

=item $font = $pdf->psfont($ps_file, %options)

=item $font = $pdf->psfont($ps_file)

Returns a new Adobe Type1 ("PostScript") font object.
For details, see L<PDF::Builder::Docs/PS Fonts>.

See also L<PDF::Builder::Resource::Font::Postscript>.

=cut

sub psfont {
    my ($self, $psf, %opts) = @_;

    foreach my $o (qw(-afmfile -pfmfile)) {
        next unless defined $opts{$o};
        $opts{$o} = _findFont($opts{$o});
    }
    $psf = _findFont($psf);
    require PDF::Builder::Resource::Font::Postscript;
    my $obj = PDF::Builder::Resource::Font::Postscript->new($self->{'pdf'}, $psf, %opts);

    $self->{'pdf'}->out_obj($self->{'pages'});
    $obj->tounicodemap() if $opts{'-unicodemap'}; # UTF-8 not usable

    return $obj;
}

=item $font = $pdf->ttfont($ttf_file, %options)

=item $font = $pdf->ttfont($ttf_file)

Returns a new TrueType (or OpenType) font object.
For details, see L<PDF::Builder::Docs/TrueType Fonts>.

=cut

sub ttfont {
    my ($self, $file, %opts) = @_;

    # PDF::Builder doesn't set BaseEncoding for TrueType fonts, so text
    # isn't searchable unless a ToUnicode CMap is included.  Include
    # the ToUnicode CMap by default, but allow it to be disabled (for
    # performance and file size reasons) by setting -unicodemap to 0.
    $opts{'-unicodemap'} = 1 unless exists $opts{'-unicodemap'};

    $file = _findFont($file);
    require PDF::Builder::Resource::CIDFont::TrueType;
    my $obj = PDF::Builder::Resource::CIDFont::TrueType->new($self->{'pdf'}, $file, %opts);

    $self->{'pdf'}->out_obj($self->{'pages'});
    $obj->tounicodemap() if $opts{'-unicodemap'};

    return $obj;
}

=item $font = $pdf->cjkfont($cjkname, %options)

=item $font = $pdf->cjkfont($cjkname)

Returns a new CJK font object. These are TrueType-like fonts for East Asian
languages (Chinese, Japanese, Korean).
For details, see L<PDF::Builder::Docs/CJK Fonts>.

See also L<PDF::Builder::Resource::CIDFont::CJKFont>

=cut

sub cjkfont {
    my ($self, $name, %opts) = @_;

    require PDF::Builder::Resource::CIDFont::CJKFont;
    my $obj = PDF::Builder::Resource::CIDFont::CJKFont->new($self->{'pdf'}, $name, %opts);

    $self->{'pdf'}->out_obj($self->{'pages'});
    $obj->tounicodemap() if $opts{'-unicodemap'};

    return $obj;
}

=item $font = $pdf->synfont($basefont, %options)

=item $font = $pdf->synfont($basefont)

Returns a new synthetic font object. These are modifications to a core (or 
PS/T1 or TTF/OTF) font, where the font may be replaced by a Type1 or Type3 
PostScript font.
This does not appear to work with CJK fonts (created with C<cjkfont> method).
For details, see L<PDF::Builder::Docs/Synthetic Fonts>.

See also L<PDF::Builder::Resource::Font::SynFont>

=cut

sub synfont {
    my ($self, $font, %opts) = @_;

    # PDF::Builder doesn't set BaseEncoding for TrueType fonts, so text
    # isn't searchable unless a ToUnicode CMap is included.  Include
    # the ToUnicode CMap by default, but allow it to be disabled (for
    # performance and file size reasons) by setting -unicodemap to 0.
    $opts{'-unicodemap'} = 1 unless exists $opts{'-unicodemap'};

    require PDF::Builder::Resource::Font::SynFont;
    my $obj = PDF::Builder::Resource::Font::SynFont->new($self->{'pdf'}, $font, %opts);

    $self->{'pdf'}->out_obj($self->{'pages'});
    $obj->tounicodemap() if $opts{'-unicodemap'};

    return $obj;
}

=item $font = $pdf->bdfont($bdf_file, @options)

=item $font = $pdf->bdfont($bdf_file)

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

=item $font = $pdf->unifont(@fontspecs, %options)

=item $font = $pdf->unifont(@fontspecs)

Returns a new uni-font object, based on the specified fonts and options.

B<BEWARE:> This is not a true PDF-object, but a virtual/abstract font definition!

See also L<PDF::Builder::Resource::UniFont>.

Valid %options are:

=over

=item -encode

Changes the encoding of the font from its default.

=back

=cut

sub unifont {
    my ($self, @opts) = @_;

    require PDF::Builder::Resource::UniFont;
    my $obj = PDF::Builder::Resource::UniFont->new($self->{'pdf'}, @opts);

    return $obj;
}

=back

=head1 IMAGE METHODS

=over

=item $jpeg = $pdf->image_jpeg($file)

Imports and returns a new JPEG image object. C<$file> may be either a filename 
or a filehandle.

See L<PDF::Builder::Resource::XObject::Image::JPEG> for additional information
and C<examples/Content.pl> for some examples of placing an image on a page.

=cut

# =item $jpeg = $pdf->image_jpeg($file, %options)   no current options

sub image_jpeg {
    my ($self, $file, %opts) = @_;

    require PDF::Builder::Resource::XObject::Image::JPEG;
    my $obj = PDF::Builder::Resource::XObject::Image::JPEG->new($self->{'pdf'}, $file);

    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $tiff = $pdf->image_tiff($file, %opts)

=item $tiff = $pdf->image_tiff($file)

Imports and returns a new TIFF image object. C<$file> may be either a filename 
or a filehandle.
For details, see L<PDF::Builder::Docs/TIFF Images>.

See L<PDF::Builder::Resource::XObject::Image::TIFF> and
L<PDF::Builder::Resource::XObject::Image::TIFF_GT> for additional information
and C<examples/Content.pl>
for some examples of placing an image on a page (JPEG, but the principle is
the same). There is an optional TIFF library described, that gives more
capability than the default one.

=cut

sub image_tiff {
    my ($self, $file, %opts) = @_;

    my ($rc, $obj);
    $rc = $self->LA_GT();
    if ($rc) {
	# Graphics::TIFF available
	if (defined $opts{'-nouseGT'} && $opts{'-nouseGT'} == 1) {
	   $rc = -1;  # don't use it
	}
    }
    if ($rc == 1) {
	# Graphics::TIFF (_GT suffix) available and to be used
        require PDF::Builder::Resource::XObject::Image::TIFF_GT;
        $obj = PDF::Builder::Resource::XObject::Image::TIFF_GT->new($self->{'pdf'}, $file, 'Ix'.pdfkey(), %opts);
        $self->{'pdf'}->out_obj($self->{'pages'});
    } else {
	# Graphics::TIFF not available, or is but is not to be used
        require PDF::Builder::Resource::XObject::Image::TIFF;
        $obj = PDF::Builder::Resource::XObject::Image::TIFF->new($self->{'pdf'}, $file, 'Ix'.pdfkey(), %opts);
        $self->{'pdf'}->out_obj($self->{'pages'});

	if ($rc == 0 && $MSG_COUNT[0]++ == 0) {
	    # give warning message once, unless silenced (-silent) or
	    # deliberately not using Graphics::TIFF (rc == -1)
	    if (!defined $opts{'-silent'} || $opts{'-silent'} == 0) {
	        print STDERR "Your system does not have Graphics::TIFF installed, so some\nTIFF functions may not run correctly.\n";
		# even if -silent only once, COUNT still incremented
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

=item $pnm = $pdf->image_pnm($file)

Imports and returns a new PNM image object. C<$file> may be either a filename 
or a filehandle.

See C<examples/Content.pl>
for some examples of placing an image on a page (JPEG, but the principle is
the same).

=cut

# =item $pnm = $pdf->image_pnm($file, %options)   no current options

sub image_pnm {
    my ($self, $file, %opts) = @_;

    require PDF::Builder::Resource::XObject::Image::PNM;
    my $obj = PDF::Builder::Resource::XObject::Image::PNM->new($self->{'pdf'}, $file);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $png = $pdf->image_png($file, %options) 

=item $png = $pdf->image_png($file)

Imports and returns a new PNG image object. C<$file> may be either 
a filename or a filehandle.
For details, see L<PDF::Builder::Docs/PNG Images>.

See L<PDF::Builder::Resource::XObject::Image::PNG> and
L<PDF::Builder::Resource::XObject::Image::PNG_IPL> for additional information
and C<examples/Content.pl>
for some examples of placing an image on a page (JPEG, but the principle is
the same). There is an optional PNG library (PNG_IPL) described, that gives more
capability than the default one.

=cut

sub image_png {
    my ($self, $file, %opts) = @_;

    my ($rc, $obj);
    $rc = $self->LA_IPL();
    if ($rc) {
        # Image::PNG::Libpng available
        if (defined $opts{'-nouseIPL'} && $opts{'-nouseIPL'} == 1) {
            $rc = -1;  # don't use it
        }
    }
    if ($rc == 1) {
        # Image::PNG::Libpng (_IPL suffix) available and to be used
        require PDF::Builder::Resource::XObject::Image::PNG_IPL;
        $obj = PDF::Builder::Resource::XObject::Image::PNG_IPL->new($self->{'pdf'}, $file, 'Px'.pdfkey(), %opts);
        $self->{'pdf'}->out_obj($self->{'pages'});
    } else {
        # Image::PNG::Libpng not available, or is but is not to be used
        require PDF::Builder::Resource::XObject::Image::PNG;
        $obj = PDF::Builder::Resource::XObject::Image::PNG->new($self->{'pdf'}, $file, 'Px'.pdfkey(), %opts);
        $self->{'pdf'}->out_obj($self->{'pages'});

        if ($rc == 0 && $MSG_COUNT[1]++ == 0) {
            # give warning message once, unless silenced (-silent) or
            # deliberately not using Image::PNG::Libpng (rc == -1)
            if (!defined $opts{'-silent'} || $opts{'-silent'} == 0) {
                print STDERR "Your system does not have Image::PNG::Libpng installed, so some\nPNG functions may not run correctly.\n";
                # even if -silent only once, COUNT still incremented
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

=item $gif = $pdf->image_gif($file)

Imports and returns a new GIF image object. C<$file> may be either a filename 
or a filehandle.

See L<PDF::Builder::Resource::XObject::Image::GIF> for additional information
and C<examples/Content.pl> for some examples of placing an image on a page 
(JPEG, but the principle is the same).

=cut

# =item $gif = $pdf->image_gif($file, %options)   no current options

sub image_gif {
    my ($self, $file, %opts) = @_;

    require PDF::Builder::Resource::XObject::Image::GIF;
    my $obj = PDF::Builder::Resource::XObject::Image::GIF->new($self->{'pdf'}, $file);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $gdf = $pdf->image_gd($gd_object, %options)

=item $gdf = $pdf->image_gd($gd_object)

Imports and returns a new image object from Image::GD.

Valid %options are:

=over

=item -lossless => 1

Use lossless compression.

=back

See L<PDF::Builder::Resource::XObject::Image::GD> for additional information
and C<examples/Content.pl> for some examples of placing an image on a page 
(JPEG, but the principle is the same).

=cut

sub image_gd {
    my ($self, $gd, %options) = @_;

    require PDF::Builder::Resource::XObject::Image::GD;
    my $obj = PDF::Builder::Resource::XObject::Image::GD->new($self->{'pdf'}, $gd, undef, %options);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=back

=head1 COLORSPACE METHODS

=over

=item $cs = $pdf->colorspace_act($file)

Returns a new colorspace object based on an Adobe Color Table file.

See L<PDF::Builder::Resource::ColorSpace::Indexed::ACTFile> for a
reference to the file format's specification.

=cut

# =item $cs = $pdf->colorspace_act($file, %options)   no current options

sub colorspace_act {
    my ($self, $file, %opts) = @_;

    require PDF::Builder::Resource::ColorSpace::Indexed::ACTFile;
    my $obj = PDF::Builder::Resource::ColorSpace::Indexed::ACTFile->new($self->{'pdf'}, $file);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $cs = $pdf->colorspace_web()

Returns a new colorspace-object based on the "web-safe" color palette.

=cut

# =item $cs = $pdf->colorspace_web($file, %options)   no current options
# =item $cs = $pdf->colorspace_web($file)   no current file

sub colorspace_web {
    my ($self, $file, %opts) = @_;

    require PDF::Builder::Resource::ColorSpace::Indexed::WebColor;
    my $obj = PDF::Builder::Resource::ColorSpace::Indexed::WebColor->new($self->{'pdf'});

    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $cs = $pdf->colorspace_hue()

Returns a new colorspace-object based on the hue color palette.

See L<PDF::Builder::Resource::ColorSpace::Indexed::Hue> for an explanation.

=cut

# =item $cs = $pdf->colorspace_hue($file, %options)   no current options
# =item $cs = $pdf->colorspace_hue($file)   no current file

sub colorspace_hue {
    my ($self, $file, %opts) = @_;

    require PDF::Builder::Resource::ColorSpace::Indexed::Hue;
    my $obj = PDF::Builder::Resource::ColorSpace::Indexed::Hue->new($self->{'pdf'});
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
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
    my $obj = PDF::Builder::Resource::ColorSpace::Separation->new($self->{'pdf'}, pdfkey(), $tint, @clr);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
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
    my $obj = PDF::Builder::Resource::ColorSpace::DeviceN->new($self->{'pdf'}, pdfkey(), $clrs, $samples);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=back

=head1 BARCODE METHODS

These are glue routines to the actual barcode rendering routines found
elsewhere.

=over

=item $bc = $pdf->xo_codabar(%options)

=item $bc = $pdf->xo_code128(%options)

=item $bc = $pdf->xo_2of5int(%options)

=item $bc = $pdf->xo_3of9(%options)

=item $bc = $pdf->xo_ean13(%options)

Creates the specified barcode object as a form XObject.

=cut

# TBD consider moving these to a BarCodes subdirectory, as the number of bar
# code routines increases

sub xo_code128 {
    my ($self, @options) = @_;

    require PDF::Builder::Resource::XObject::Form::BarCode::code128;
    my $obj = PDF::Builder::Resource::XObject::Form::BarCode::code128->new($self->{'pdf'}, @options);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

sub xo_codabar {
    my ($self, @options) = @_;

    require PDF::Builder::Resource::XObject::Form::BarCode::codabar;
    my $obj = PDF::Builder::Resource::XObject::Form::BarCode::codabar->new($self->{'pdf'}, @options);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

sub xo_2of5int {
    my ($self, @options) = @_;

    require PDF::Builder::Resource::XObject::Form::BarCode::int2of5;
    my $obj = PDF::Builder::Resource::XObject::Form::BarCode::int2of5->new($self->{'pdf'}, @options);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

sub xo_3of9 {
    my ($self, @options) = @_;

    require PDF::Builder::Resource::XObject::Form::BarCode::code3of9;
    my $obj = PDF::Builder::Resource::XObject::Form::BarCode::code3of9->new($self->{'pdf'}, @options);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

sub xo_ean13 {
    my ($self, @options) = @_;

    require PDF::Builder::Resource::XObject::Form::BarCode::ean13;
    my $obj = PDF::Builder::Resource::XObject::Form::BarCode::ean13->new($self->{'pdf'}, @options);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

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

Returns a new extended graphics state object.

=cut

sub egstate {
    my $self = shift();

    my $obj = PDF::Builder::Resource::ExtGState->new($self->{'pdf'}, pdfkey());
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $obj = $pdf->pattern(%options)

=item $obj = $pdf->pattern()

Returns a new pattern object.

=cut

sub pattern {
    my ($self, %options) = @_;

    my $obj = PDF::Builder::Resource::Pattern->new($self->{'pdf'}, undef, %options);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $obj = $pdf->shading(%options)

=item $obj = $pdf->shading()

Returns a new shading object.

=cut

sub shading {
    my ($self, %options) = @_;

    my $obj = PDF::Builder::Resource::Shading->new($self->{'pdf'}, undef, %options);
    $self->{'pdf'}->out_obj($self->{'pages'});

    return $obj;
}

=item $otls = $pdf->outlines()

Returns a new or existing outlines object.

=cut

sub outlines {
    my $self = shift();

    require PDF::Builder::Outlines;
    $self->{'pdf'}->{'Root'}->{'Outlines'} ||= PDF::Builder::Outlines->new($self);

    my $obj = $self->{'pdf'}->{'Root'}->{'Outlines'};
#    bless $obj, 'PDF::Builder::Outlines';
#    $obj->{' apipdf'} = $self->{'pdf'};
#    $obj->{' api'}    = $self;
#    weaken $obj->{' apipdf'};
#    weaken $obj->{' api'};

    $self->{'pdf'}->new_obj($obj) unless $obj->is_obj($self->{'pdf'});
    $self->{'pdf'}->out_obj($obj);
    $self->{'pdf'}->out_obj($self->{'pdf'}->{'Root'});

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
		   #    print STDERR "$IC Additional Parent ($Parent) in object $objKey, already list $objList{$objKey}->[$idx_parent] as Parent.\n" if $level >= $level_error;
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
		   #    print STDERR "$IC Multiple Kids lists in object $objKey, already list @{$objList{$objKey}->[$idx_kid_list]} as Kids.\n" if $level >= $level_error;
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
		    print STDERR "$IC object $thisObj wants to claim object $child as its child, but $objList{$child}[$idx_par_clmd] already has!\nPossibly $child is on more than one /Kids list?\n" if $level >= $level_error;
		}
	        # if no object defined for child, already flagged as missing
		if ($objList{$child}[$idx_defined] == 1) {
		    # child should list thisObj as its Parent
		    if      ($objList{$child}[$idx_parent] == -1) {
		        print STDERR "$IC object $thisObj claims $child as a child (/Kids), but $child claims no Parent!\n" if $level >= $level_error;
		        $objList{$child}[$idx_parent] = $thisObj;
		    } elsif ($objList{$child}[$idx_parent] != $thisObj) {
		        print STDERR "$IC object $thisObj claims $child as a child (/Kids), but $child claims $objList{$child}[$idx_parent] as its parent!\n" if $level >= $level_error;
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

=back

=cut
