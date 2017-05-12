#!/bin/perl
#
# @(#)Labels.pm 1.8 01/02/10
#
# Perl package of routines to produce mailing label PDFs
#

# PDF::Labels - create Mailing Labels in PDF files
# Author: Owen DeLong <owen@delong.com>
# Version: 0.01
# Copyright 2001 Owen DeLong <owen@delong.com>
#
# bugs:
# - ...

package PDF::Labels;

use PDF::Create;
use strict;
use vars qw(@ISA @EXPORT $VERSION $DEBUG);
use Exporter;

@ISA	 = qw(Exporter);
@EXPORT  = qw();
$VERSION = 1.8;
$DEBUG   = 0;

# Remainder of code appears at end of documentation

=head1 NAME

PDF::Labels - Routines to produce formatted pages of mailing labels in PDF

=head1 SYNOPSIS

    use PDF::Labels;

    Requires: PDF::Create

=head1 DESCRIPTION

=head2 GENERAL

Provides package PDF::Labels

Package Global Variables:

	@PDF::Labels:PageFormats is a list of known page formats.  Each
	page format is a : delimited list of fields which provide the
	following properties about a page of labels:

		pagewidth	Width of actual page in inches
		pageheight	Height of actual page in inches
		pagexoffset	Offset from left edge of page to left
				edge of first column of labels in inches
		pageyoffset	Offset from bottom edge of page to
				bottom edge of lowest row of labels
		xlabels		Number of labels in each row
		ylabels		Number of labels in each column
		labelwidth	Width of each label in inches, including
				margin
		labelheight	Height of each label in inches, including
				margin
		labelxmar	Minimum Distance to offset printing from
				left and right edges of label
		labelymar	Minimum distance to offset printing from
				top and bottom edges of label
		fontsize	Size of font to use with this label
		linespacing	Line spacing (points) to use with this
				label

=head2 SYNTAX

    Example

	use PDF::Create;
	use PDF::Labels;

	$pdf = new PDF::Labels(
			$PDF::Labels::PageFormats[0],
				filename=>'labels.pdf',
				Author=>'PDF Labelmaker',
				Title=>'My Labels'
		);

	$pdf->setlabel(5);	# Start with label 5 on first page

	$pdf->label('John Doe', '1234 Some Street',
			'Anytown, ID', '12345');
	$pdf->label('Jane Doe', '5493 Other Drive',
			'Nowhere, CA', '92213');
	$pdf->label('Bob Smith', '392 Cedar Lane',
			'Deep Shit, AR', '72134');

	$pdf->close();

	The above example will produce 3 labels on an 8.5x11 sheet with
	three labels in a row and 10 rows of labels.  The labels are
	2.625"x1".  This is a common sheet-feed label.  In this case, the
	three labels will be the last label of the second row and the
	first two labels of the third row.  The labels can be moved by
	changing the parameter to the setlabel call.

    Creation

	$pdf = new PDF::Labels(
			$PageFormat,
			PDF::Create parameters
		)

	$PageFormat is a string containing a single element of PageFormats
	or a custom page format specification in the same format.

	PDF::Create parameters are described in the PDF::Create pod.

    Setup

	$pdf->setlabel(n)

	n is a number from 0 to maxlabels.  Subsequent calls to create
	labels will create labels starting from this position on the
	page.  Position 0 is the upper left label, working across each
	row down in columns.

		i.e.	0 1 2
			3 4 5
			6 7 8
			...

	Setlabel will not go backwards.  If n is less than the current
	cursor position, a new page will be created.

    Label Creation

	$pdf->label('string1', 'string2', 'string3'[, 'string4'...])

	As much of each string as possible will be placed on a seperate
	line of the label.  If there are more strings than the label can
	hold, extra strings will not be printed.

	@(#) Labels.pm Last updated 01/02/10 18:59:54 (SCCS Version 1.8)

=head1 AUTHOR

Owen DeLong, owen@delong.com

=cut


@PDF::Labels::PageFormats=(
	# pw:ph:xof:yof:x:yl:lwid:lh:lxma:lymar:fs:ls   # Page   quan labelsize
	# Sheet labels (laser or inkjet)
	"8.5:11:0.2:0.5:3:10:2.75:1:0.25:0.15:10:12",   # 8.5x11 3x10 2.75x1"
	"8.5:11:0.2:0.5:2:10:4.25:1:0.25:0.15:10:12",   # 8.5x11 2x10 4x1"
	"8.5:11:0.25:0.4:4:20:2.0625:0.5:0.25:0.1:6:7",  # 8.5x11 4x20 1.75x0.5"
	# Pin feed labels (dot matrix)
	"4.25:5:0:0:1:5:3.5:1:0.25:0.135:12:14"         # 4.25x5 1x5 3.5x.9375"
);

@PDF::Labels::FriendlyNames=(
	"8.5x11 3 columns, 10 rows, 2.65x1 inch labels",
	"8.5x11 2 columns, 10 rows, 4x1 inch labels",
	"8.5x11 4 columns, 20 rows, 2x1/2 inch labels",
	"Pin Feed 3.5x1 inch labels, single column, 5 per fanfold"
	);

# creation routine
sub new {
	my $this = shift;
	my $PageFormat = shift;
	my %params = @_;

	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	$self->{'data'}='';
	$self->{'PageFormat'}=$PageFormat;
	my ($pw, $ph, $xof, $yof, $xl, $yl, $lw, $lh, $lxm, $lym, $fp, $ls)=
		split(/:/, $PageFormat);
	$self->{'PageWidth'}=$pw;
	$self->{'PageHeight'}=$ph;
	$self->{'Xoffset'}=$xof;
	$self->{'Yoffset'}=$yof;
	$self->{'Xlabels'}=$xl;
	$self->{'Ylabels'}=$yl;
	$self->{'LabelWidth'}=$lw;
	$self->{'LabelHeight'}=$lh;
	$self->{'LabelXMargin'}=$lxm;
	$self->{'LabelYMargin'}=$lym;
	$self->{'FontSize'}=$fp;
	$self->{'LineSpacing'}=$ls;

	$self->{'PDF'}=new PDF::Create(%params) || die('Couldn\'t create PDF');
	if (!defined($self->{'PDF'}->{'fh'}))
	{
		print "ERROR NO FH!\n";
	}

	$self->{'rootpage'}=$self->{'PDF'}->new_page(
			'MediaBox' => [0,0,$self->{'PageWidth'}*72,
				$self->{'PageHeight'}*72],
			);

	$self->{'NormalFont'}=$self->{'PDF'}->font(
			'Basefont' => 'Helvetica'
			);

	$self->{'BoldFont'}=$self->{'PDF'}->font(
			'Basefont' => 'Helvetica-Bold'
			);


	$self->{'Pages'}=[];

	push(@{$self->{'Pages'}}, $self->{'rootpage'}->new_page());

	$self->{'CurrentLabel'}=0;

	return($self);
}

sub close {
	my $self = shift;
	my %params = @_;

	$self->{'PDF'}->close();
}

sub setlabel {
	my $self = shift;
	my $lnum = shift;

	my $maxlabel = ($self->{'Xlabels'} * $self->{'Ylabels'}) - 1;
	if ($lnum > $maxlabel)
	{
		return(-1);
	}
	if ($lnum < $self->{'CurrentLabel'})
	{
		print "$lnum Requires new page ($self->{'CurrentLabel'})\n";
		$self->newpage();
	}
	$self->{'CurrentLabel'}=$lnum;
	return($lnum);
}

sub label {
	my $self = shift;

	my $lnum = $self->{'CurrentLabel'};
	my $y = int($lnum/$self->{'Xlabels'});
	my $x = $lnum%$self->{'Xlabels'};

	my $fn=$self->{'NormalFont'};
	my $fb=$self->{'BoldFont'};

	my $fs=$self->{'FontSize'};
	my $ls=$self->{'LineSpacing'};

	my $lw=($self->{'LabelWidth'}-$self->{'LabelXMargin'}*2) *72;
	my $lh=($self->{'LabelHeight'}-$self->{'LabelYMargin'}) *72;
	my $linecount=int($lh-($self->{'LabelYMargin'}*72))/$ls;

	my $X=($x*$self->{'LabelWidth'}+$self->{'LabelXMargin'}+
		$self->{'Xoffset'})*72;
	my $Y=(($self->{'Ylabels'}-$y-1)*$self->{'LabelHeight'}+
		$self->{'LabelYMargin'}+$self->{'Yoffset'})*72;

	my $q;

	$q=0;
	foreach(@_)
	{
		$q++;
		next unless $linecount; # Skip lines beyond bottom of label.
		# Should add code here to check width of test
		${$self->{'Pages'}}[scalar(@{$self->{'Pages'}})-1]->string(
			$fn, $fs, $X, $Y+$linecount*$ls, $_);
		$linecount--;
	}
#	${$self->{'Pages'}}[scalar(@{$self->{'Pages'}})-1]->newpath();
#	${$self->{'Pages'}}[scalar(@{$self->{'Pages'}})-1]->rectangle(
#							$X, $Y, $lw, $lh);
#	${$self->{'Pages'}}[scalar(@{$self->{'Pages'}})-1]->stroke();

	$self->{'CurrentLabel'}++;
	if ($self->{'CurrentLabel'} >= $self->{'Xlabels'}*$self->{'Ylabels'})
	{
		$self->newpage();
		$self->{'CurrentLabel'}=0;
	}
	return(1);
}

sub newpage()
{
	my $self = shift;

	push(@{$self->{'Pages'}}, $self->{'rootpage'}->new_page());
	return(1);
}

