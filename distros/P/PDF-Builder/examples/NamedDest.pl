#!/usr/bin/perl
# named destination demonstrator, originally by Johan Vromans
# produces this.pdf and that.pdf, each of which has a couple of named
#   destinations, with a link to the other's named destinations and a
#   link to its own named destinations.

use strict;
use warnings;
use utf8;

use PDF::Builder;

# NDthis.pdf multiple links (pages 1, 4) to 'foo' & 'bar' ND in NDthat.pdf (pp 2,3)
# NDthat.pdf multiple links (pages 1, 4) to 'foo' & 'bar' ND in NDthis.pdf (pp 2,3)
makefile("NDthis.pdf", "NDthat.pdf" );
makefile("NDthat.pdf", "NDthis.pdf" );

sub makefile {
    my ( $this, $that ) = @_;

    my $pdf = PDF::Builder->new('compress'=>'none');
    $pdf->default_page_size("A4");
    my $font = $pdf->font("Helvetica");

    for ( 1..4 ) {
	# stuff common to all 4 pages
	my $page = $pdf->page();
        my $gfx = $page->gfx(); # before text, so text overwrites it
	my $text = $page->text();
	$text->fillcolor("black");
	$text->font($font, 80);
	$text->translate( 40, 600 );
	$text->text("Page $_"); # only content on Named Destination pages

	# Page 1: "goto" foo and "goto" bar in this document (two buttons)
	# Page 2: Named Destination 'foo' in this document (no button)
	# Page 3: Named Destination 'bar' in this document (no button)
	#         via the ->new() call (no 'goto' call)
	# Page 4: "goto" foo and "goto" bar in the other document (two buttons)
	if      ( $_ == 1 ) { # page 1
	    # named dest links to 'foo' and 'bar' in current document
	    # draw and label two "buttons"
	    draw_buttons($font, $gfx, $text, "this");
            print "page 1 of $this, goto 'foo' and goto 'bar' this document\n";
            
	    # add annotations to go to another place
	    my $ann = $page->annotation();
	    $ann->border( 0, 0, 1 );
	    $ann->rect( 60, 500, 160, 550);
	    $ann->link( "foo" );
	    # link works in Builder too, as does goto
	    my $ann2 = $page->annotation();
	    $ann2->border( 0, 0, 1 );
	    $ann2->rect( 60, 400, 160, 450);
	    $ann2->link( "bar" );  #  '#bar' also allowed
	    # Builder can also handle $ann->goto( "foo" );
	    # could also use 'pdf()' to '$this' target

	} elsif ( $_ == 2 ) { # page 2
	    # Create a named dest "foo" on page 2, no links.
            print "page 2 of $this, define Named Destination 'foo'\n";
	    $text->translate(50, 500);
	    $text->font($font, 30);
	    $text->text("Named Destination 'foo'");
	    my $dest = PDF::Builder::NamedDestination->new($pdf);
	    $dest->goto( $page, 'xyz'=>(undef,undef,undef) ); # original form
	    $pdf->named_destination( 'Dests', 'foo', $dest );
	    # '#foo' also allowed here, for API2 compatibility

	} elsif ( $_ == 3 ) { # page 3
	    # Create a named dest "bar" on page 2, no links.
	    # using new() w/o goto()
            print "page 3 of $this, define Named Destination 'bar'\n";
	    $text->translate(50, 500);
	    $text->font($font, 30);
	    $text->text("Named Destination 'bar'");  #  '#bar' also allowed

            my $d2=PDF::Builder::NamedDestination->new($pdf, $page, 'xyz', 0,700, 1.5);
           #$d2->goto($page, 'fit');  # IS needed!
            $pdf->named_destination('Dests', 'bar', $d2);
	    # '#bar' also allowed here, for API2 compatibility

	} elsif ( $_ == 4 ) { # page 4
	    # named dest links to 'foo' and 'bar' in the other document
	    # draw and label two "buttons"
	    draw_buttons($font, $gfx, $text, "other");
            print "page 4 of $this, pdf to 'foo' and pdf to 'bar' in $that\n";
            
	    # add annotations to go to another document
	    my $ann = $page->annotation();
	    $ann->border( 0, 0, 1 );
	    $ann->rect( 60, 500, 160, 550);
	    $ann->pdf( $that, "#foo" ); # 'foo' also allowed
	    my $ann2 = $page->annotation();
	    $ann2->border( 0, 0, 1 );
	    $ann2->rect( 60, 400, 160, 450);
	    $ann2->pdf( $that, "#bar" );  # 'bar' also allowed
	    # Builder can also handle $ann->pdf( $that, "foo" );

	}
    }

    my $dirpath = $0;
    $dirpath =~ s/NamedDest\.pl//; # includes final / or \
    $pdf->saveas("$dirpath$this");

    return;
}

sub draw_buttons {
    my ($font, $gfx, $text, $where) = @_;

    $text->font($font, 30);
    $gfx->rect( 60, 500, 100,  50);
    $gfx->fill_color("yellow");
    $gfx->fill();
    $text->fill_color("black");
    $text->translate(20, 515);
    $text->text("to");
    $text->translate(85, 515);
    $text->text("foo");
    $text->translate(175, 515);
    $text->text("in $where document");
    $gfx->rect( 60, 400, 100,  50);
    $gfx->fill_color("yellow");
    $gfx->fill();
    $text->fill_color("black");
    $text->translate(20, 415);
    $text->text("to");
    $text->translate(85, 415);
    $text->text("bar");
    $text->translate(175, 415);
    $text->text("in $where document");

    return;
}
