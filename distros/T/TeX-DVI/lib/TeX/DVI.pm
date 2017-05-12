
=head1 NAME

TeX::DVI -- write out TeX's DVI (DeVice Independent) file

=cut

package TeX::DVI;

use FileHandle;
use Font::TFM;

$VERSION = '1.01';

sub new
	{
	my ($class, $filename) = @_;
	my $fh = new FileHandle "> $filename";
	if (not defined $fh)
		{ return undef; }
	binmode $fh;
	my $self = {};
	bless $self;
	$self->{fh} = $fh;
	$self->{totallength} = 0;
	$self->{pagenum} = 0;
	$self->{previouspage} = -1;
	$self->{currdvipush} = $self->{maxdvipush} = 0;
	$self;
	}
sub close
	{ shift->{fh}->close; }
sub output
	{
	my $self = shift;
	my $outstring = pack(shift(@_), @_);
	$self->{totallength} += length $outstring;
	print { $self->{fh} } $outstring;
	}
sub preamble
	{
	my $self = shift;
	my (@currenttime, $currentasciitime, $comment, $commentlength);
	@currenttime = gmtime time;
	$currentasciitime = sprintf "%02d/%02d/%02d %02d:%02d:%02d GMT", $currenttime[3],
		$currenttime[4] + 1, $currenttime[5] % 100, @currenttime[2, 1, 0];
	$comment = "TeX::DVI.pm output ".$currentasciitime;
	$commentlength = length $comment;
	my @preamble = (247, 2, 25400000, 473628672, 1000,
			$commentlength, $comment);
	$self->output("CCNNNCA$commentlength", @preamble);
	}
sub begin_page
	{
	my $self = shift;
	$self->{pagenum}++;
	my $previous = $self->{previouspage};
	$self->{previouspage} = $self->{totallength};
	$self->output("CN10N", 139, $self->{pagenum}, (0) x 9, $previous);
	}
sub end_page
	{
	my $self = shift;
	$self->output("C", 140);
	}

sub postamble
	{
	my $self = shift;
	my $postamblestart = $self->{totallength};
	
	# postamble
	$self->output("CNNNNNNnn", 248, $self->{previouspage},
		25400000, 473628672, 1000, 1000000, 1000000,
		$self->{maxdvipush}, $self->{pagenum});

	for (0 .. $#{$self->{fonts}})
		{
		$self->print_font_def($_);
		}
	# postpostamble
	$self->output("CNCC4", 249, $postamblestart, 2, (223) x 4);
	}

sub font_def
	{
	my ($self, $font) = @_;
	my $fontnumber = $#{$self->{fonts}} + 1;
	$self->{fonts}[$fontnumber] = $font;
	$self->print_font_def($fontnumber);
	$fontnumber;
	}
sub print_font_def
	{
	my ($self, $fontnumber) = @_;
	my $font = $self->{fonts}[$fontnumber];
	my $name = $font->{name};
	my $fontnamelength = length $name;
	$self->output("CCNNNCCA$fontnamelength", 243, $fontnumber,
		$font->checksum(), $font->{fontsize} * 65536,
		$font->{designsize} * 65536, 0, $fontnamelength, $name);
	}
sub font
	{
	my ($self, $fontnumber) = @_;
	$self->output("C", 171 + $fontnumber);
	$self->{actualfontnumber} = $fontnumber;
	$self->{actualfont} = $self->{fonts}[$fontnumber];
	}
sub pop
	{
	$self = shift;
	$self->{currdvipush}--;
	$self->output("C", 142);
	}
sub push
	{
	$self = shift;
	$self->{currdvipush}++;
	$self->{maxdvipush} = $self->{currdvipush}
		if ($self->{currdvipush} > $self->{maxdvipush});
	$self->output("C", 141);
	}
sub hskip
	{
	my ($self, $skip) = @_;
	$self->output("CN", 146, int($skip));
	return $skip;
	}
sub vskip
	{
	my ($self, $skip) = @_;
	$self->output("CN", 160, int($skip));
	return $skip;
	}
sub black_box
	{
	my ($self, $width, $height, $depth) = @_;
	$width = 0 unless (defined $width);
	$height = 0 unless (defined $height);
	$depth = 0 unless (defined $depth);
	$self->vskip($depth);
	$self->output("CNN", 137, int($height + $depth), int($width));
	$self->vskip(-$depth);
	}
sub special
	{
	my ($self, $text) = @_;
	my $length = length $text;
	$self->output("CNA$length", 242, $length, $text);
	}

sub word
	{
	my ($self, $text) = @_;
	my @expanded = $self->{actualfont}->expand($text);
	while (@expanded)
		{
		my $word = shift @expanded;
		$word =~ s/([\200-\377])/\200${1}/gs;
		$self->output('A*', $word);
		last if (not @expanded);
		my $kern = shift @expanded;
		$self->hskip($kern);
		}
	}
1;

=head1 SYNOPSIS

	use TeX::DVI;
	use Font::TFM;

	my $dvi = new TeX::DVI "texput.dvi";
	my $font = new_at Font::TFM "cmr10", 12
		or die "Error loading cmr10 at 12 pt: $Font::TFM::errstr\n";
	$dvi->preamble();
	$dvi->begin_page();
	$dvi->push();
	my $fn = $dvi->font_def($font);
	$dvi->font($fn);
	$dvi->word("difficulty");
	$dvi->hskip($font->space());
	$dvi->word("AVA");
	$dvi->black_box($font->em_width(), $font->x_height());
	$dvi->pop();
	$dvi->end_page();
	$dvi->postamble();
	$dvi->close();

=head1 DESCRIPTION

Method B<TeX::DVI::new> creates a new DVI object in memory and opens
the output DVI file. After that, elements can be written into the
file using appropriate methods.

These are the methods available on the B<Font::TFM> object:

=over

=item preamble, postamble, begin_page, end_page, push, pop

Writes out appropriate command of the C<.dvi> file.

=item font_def

The parameter is a reference to a B<Font::TFM> object. Info out of this
object will be printed out. The method returns the internal number
of the font in this C<.dvi> file.

=item font

Writes out the font_sel command, the parametr is the number returned
by B<font_def>.

=item hskip, vskip

Skips.

=item black_box

Creates a black box, can be used for hrules and vrules.

=item special

Writes out the special command, one parameter is written as the
command.

=item word

Writes out a word given as the first parameter. The currently selected
font is used to gather information about ligatures and kernings,
that's why it's possible to say

	$dvi->word("difficulty");
	
and the C<ffi> will be ligatured all right.

=item close

Close the file.

=back

=head1 BUGS

The error handling is rather weak -- the modul currently assumes you
know why you call the method you call.

=head1 VERSION

1.01

=head1 AVAILABLE FROM

http://www.adelton.com/perl/TeX-DVI/

=head1 AUTHOR

(c) 1996--2011 Jan Pazdziora.

All rights reserved. This package is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

Contact the author at jpx dash perl at adelton dot com.

=head1 SEE ALSO

Font::TFM(3), TeX::DVI::Parse(3), perl(1).

=cut

