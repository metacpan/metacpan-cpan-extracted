#! perl

use strict;
use warnings;

use PDF::API2;

package PDF::API2::Tweaks;

=head1 NAME

PDF::API2::Tweaks - Assorted handy additions to PDF::API2.

=head1 SYNOPSIS

PDF::API2::Tweaks provides a number of extensions to PDF::API2.

Most of the extensions deal with producing PDF overlays, to fill in
forms. For example,

    # Open an existing PDF file
    my $pdf = PDF::API2->open($form);

    # Retrieve an existing page
    my $page = $pdf->openpage(1);

    # Add a built-in font to the PDF
    my $font = $pdf->corefont('Helvetica');

    # Setup text context.
    my $text = $page->text();
    $text->font($font, 10);
    $text->fillcolor('#000000');
    $text->strokecolor('#000000');

    # So far, this is all basic PDF::API2.

    # The following Tweaks extension will produce a series of lines,
    # the first one starting at position 100,714 and subsequent lines
    # spaced 16 apart:

    $text->textlist( 100, 714, 16, <<'EOD' );
    Now is the time
    for all good man
    to start using Perl
    EOD

    # Save to a file.
    $pdf->saveas("perl.pdf");

=cut

our $VERSION = 0.09;

=head1 TEXT FUNCTIONS

The following functions operate on PDF::API2::Content::Text objects.
In general, these are obtained by a call to the C<text> method on the
page object.

=cut

package PDF::API2::Content::Text;

use Carp;

sub _isnum {
    $_[0] =~ /^[-+]?\d+(.\d+)?$/;
}

my %rotation_for;			# LEAK!!!

sub translate {			# internal
    my ( $self, $x, $y ) = @_;
    if ( $rotation_for{$self} ) {
	($x, $y) = ($y, $x) if $rotation_for{$self} == 90;
	$self->transform( -translate => [ $x, $y ],
			  -rotate => $rotation_for{$self},
			);
	return;
    }

    $self->SUPER::translate( $x, $y );
}

sub set_rotation {		# internal
    my ( $self, $rotation ) = @_;
    $rotation ? $rotation_for{$self} = $rotation : delete($rotation_for{$self});
}

=head2 $text->textlist( X, Y, D, items )

Writes a list of items starting at the given coordinates and
decrementing Y with D for each item. Note that items may contain
newlines that will be dwimmed.

Returns the coordinates of the last item written; in scalar context
the Y coordinate only.

=cut

sub textlist {
    my ( $self, $x, $y, $d, @list ) = @_;
    croak("textlist: coordinates must be numeric, not ($x,$y)")
      unless _isnum($x) && _isnum($y);
    croak("textlist: line spacing must be numeric, not \"$d\"")
      unless _isnum($d);

    foreach ( @list ) {
	foreach ( split /\n/ ) {
	    $self->translate( $x, $y );
	    $self->text($_);
	    $y -= $d;
	}
    }
    wantarray ? ( $x, $y + $d ) : $y + $d;
}

=head2 $text->textline( X, Y, line )

Writes a line of text at the given coordinates.

Returns the coordinates; in scalar context the Y coordinate only.

=cut

sub textline {
    my ( $self, $x, $y, $line ) = @_;
    croak("textline: coordinates must be numeric, not ($x,$y)")
      unless _isnum($x) && _isnum($y);

    $self->translate( $x, $y );
    $self->text($line);
    wantarray ? ( $x, $y ) : $y;
}

=head2 $text->textrline( X, Y, line )

Writes a line of text at the given coordinates, right aligned.

Returns the coordinates; in scalar context the Y coordinate only.

=cut

sub textrline {
    my ( $self, $x, $y, $line ) = @_;
    croak("textrline: coordinates must be numeric, not ($x,$y)")
      unless _isnum($x) && _isnum($y);

    $self->translate( $x, $y );
    $self->text_right($line);
    wantarray ? ( $x, $y ) : $y;
}

=head2 $text->textcline( X, Y, line )

Writes a line of text at the given coordinates, centered.

Returns the coordinates; in scalar context the Y coordinate only.

=cut

sub textcline {
    my ( $self, $x, $y, $line ) = @_;
    croak("textcline: coordinates must be numeric, not ($x,$y)")
      unless _isnum($x) && _isnum($y);

    $self->translate( $x, $y );
    $self->text_center($line);
    wantarray ? ( $x, $y ) : $y;
}

=head2 $text->texthlist( X, Y, item, [ disp, item, ... ] )

Writes a series of items at the given coordinates, each subsequent
item is horizontally offsetted by the displacement that precedes it
in the list.

Returns the coordinates of the last item written; in scalar context
the X coordinate only.

=cut

sub texthlist {
    my ( $self, $x, $y, @list ) = @_;
    croak("texthlist: coordinates must be numeric, not ($x,$y)")
      unless _isnum($x) && _isnum($y);

    $self->translate( $x, $y );
    $self->text( shift(@list) );
    while ( @list ) {
	my $d = shift(@list);
	croak("texthlist: offset must be a number, not \"$d\"")
	  unless _isnum($d);
	$x += $d;
	last unless @list;
	$self->translate( $x, $y );
	$self->text( shift(@list) );
    }
    wantarray ? ( $x, $y ) : $x;
}

=head2 $text->textvlist( X, Y, item, [ disp, item, ... ] )

Writes a series of items at the given coordinates, each subsequent
item is vertically offsetted by the displacement that precedes it
in the list.

Returns the coordinates of the last item written; in scalar context
the Y coordinate only.

=cut

sub textvlist {
    my ( $self, $x, $y, @list ) = @_;
    croak("textvlist: coordinates must be numeric, not ($x,$y)")
      unless _isnum($x) && _isnum($y);

    $self->translate( $x, $y );
    $self->text( shift(@list) );
    while ( @list ) {
	my $d = shift(@list);
	croak("textvlist: offset must be a number, not \"$d\"")
	  unless _isnum($d);
	$y -= $d;
	last unless @list;
	$self->translate( $x, $y );
	$self->text( shift(@list) );
    }
    wantarray ? ( $x, $y ) : $x;
}

=head2 $text->textspread( X, Y, disp, item )

Writes a text at the given coordinates, each individual letter
is horizontally offsetted by the displacement.

Returns the coordinates of the last item written; in scalar context
the X coordinate only.

=cut

sub textspread {
    my ( $self, $x, $y, $d, $line ) = @_;
    croak("textspread: coordinates must be numeric, not ($x,$y)")
      unless _isnum($x) && _isnum($y);
    croak("textspread: spread must be numeric, not \"$d\"")
      unless _isnum($d);

    for ( split( //, $line ) ) {
	$self->translate($x, $y);
	$self->text($_);
	$x += $d;
    }
    $x -= $d;
    wantarray ? ( $x, $y ) : $x;
}

=head2 $text->textpara( X, Y, W, disp, indent, text )

Writes a text in an rectangular area starting at X,Y and W width.
Lines are broken at whitespace.

Returns the coordinates of the last item written; in scalar context
the Y coordinate only.

=cut

sub textpara {
    my ( $self, $x, $y, $w, $d, $indent, $text ) = @_;

    my $t = '';
    my $xx = $x;
    $x += $indent;
    my $l = $indent;

    # Get rid of trailing spaces.
    $text =~ s/\s+$//;

    my @text = split( /\s+/, $text );
    while ( @text ) {
	my $word = shift(@text);
	if ( ( $l += $self->advancewidth(" $word")) > $w ) {
	    $self->textline( $x, $y, $t );
	    $y -= $d;
	    $t = $word;
	    $x = $xx;
	    $l = $self->advancewidth($word)
	}
	else {
	    $t .= " " if length($t);
	    $t .= $word;
	}
    }

    $self->textline( $x, $y, $t);
    wantarray ? ( $xx, $y ) : $y;
}

=head2 $text->textparas( X, Y, W, disp, indent, text )

Writes a text in an rectangular area starting at X,Y and W width.
Lines are broken at whitespace.
A newline indicates a new paragraph start.

Returns the coordinates of the last item written; in scalar context
the Y coordinate only.

=cut

sub textparas {
    my ( $self, $x, $y, $w, $d, $indent, $text ) = @_;

    $text =~ s/\r\n/\n/g;
    my @text = split( /\n/, $text );
    foreach ( @text ) {
	$y = $self->textpara( $x, $y, $w, $d, $indent, $_ );
	$y -= $d;
    }
    wantarray ? ( $x, $y + $d ) : $y;
}

package PDF::API2::Page;

=head1 PAGE FUNCTIONS

The following functions operate on PDF::API2::Page objects.
In general, these are obtained by a call to the C<page> method on the
PDF document object.

=cut

=head2 $page->grid( [ spacing ] )

Draws a grid of coordinates on the page.
Lines a black for every 100, blue otherwise.

=cut

sub grid {
    my ( $self, $spacing ) = @_;

    my $g = $self->gfx;
    my $t = $self->text;

    $g->fillcolor('#000000');
    $g->strokecolor('#000000');
#   $g->font( ... );
    my $colour = sub {
	if ( $_[0] % 100 == 0 ) {
	    $g->linewidth(0.25);
	    $g->strokecolor('#808080');
	}
	else {
	    $g->linewidth(0.25);
	    $g->strokecolor('#aaaaff');
	}
    };

    $g->save;
    $spacing ||= 100;
    $spacing = 20 if $spacing == 1; # for convenience

    my ( $xmax, $ymax ) = ( 600, 900 );
    for ( my $x = $spacing; $x < $xmax; $x += $spacing ) {
	$colour->($x);
	$g->move($x, 0);
	$g->line($x, $ymax);
	$g->stroke;
    }
    for ( my $y = $spacing; $y < $ymax; $y += $spacing ) {
	$colour->($y);
	$g->move(0, $y);
	$g->line($xmax, $y);
	$g->stroke;
#	$g->move(5, $y+5);
#	$g->text("$y");
    }
    $g->restore;
}

=head1 BUGS

There's a small memory leak for every text object that is used. For
normal use this can be ignored since you'll probably need just of
couple of text objects.

=cut

1;
