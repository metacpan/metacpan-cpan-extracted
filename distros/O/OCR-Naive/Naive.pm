# $Id: Naive.pm,v 1.13 2009/02/10 08:04:55 dk Exp $
package OCR::Naive;

use strict;
use warnings;
use Prima;
require Exporter;

our $VERSION = '0.07';
use base qw(Exporter);

our @EXPORT_OK   = qw(
	load_dictionary save_dictionary find_images 
	image2db_key suggest_glyph_order enhance_image
	recognize
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK);

sub load_dictionary
{
	my ( $file) = @_;

	return unless open DB, '<', $file;

	my %db;

	while (<DB>) {
		chomp;
		s/^\s*\#.*//;
		next unless length;
		my %k = m/(\w+)='((?:\\[\\']|[^\\'])*)'\s*/g;
		unless ( 4 == grep { exists $k{$_}} qw(w h t d)) {
			warn ("malformed line in $file, line $.\n");
			next;
		}
		s/\\(.)/$1/g for values %k;
		if ( $k{w} <= 0 or $k{h} <= 0) {
			warn ("malformed line in $file, line $.\n");
			next;
		}

		$k{d} =~ s/(..)/chr(hex($1))/ge;
		my $i = Prima::Image-> create(
			width  => $k{w},
			height => $k{h},
			data   => $k{d},
			type   => im::BW,
		);
		$db{$k{d}} = {
			width   => $k{w},
			height  => $k{h},
			text    => $k{t},
			image   => $i,
		};
	}

	close DB;
	return \%db;
}

sub save_dictionary
{
	my ( $file, $db) = @_;

	return unless open DB, ">", $file;

	while ( my ( $k, $v) = each %$db) {
		next unless defined $v-> {text};
		my $t = $v->{text};
		$k =~ s/(.)/sprintf("%02x",ord($1))/ges;
		$t =~ s/(['\\])/\\$1/ge;
		print DB "t='$t' w='$v->{width}' h='$v->{height}' d='$k'\n";
	}
	close DB;
	return 1;
}

sub find_images
{
        my ( $image, $subimage, $multiple) = @_;

        my $G   = $image-> data;
        my $W   = $image-> width;
        my $w   = $subimage-> width;
        my $h   = $subimage-> height;
        my $bpp = ($image-> type & im::BPP) / 8;
	die "won't do images with less than 256 colors"
		if $bpp < 0;
	if ( $subimage-> type != $image-> type) {
		$subimage = $subimage-> dup;
		$subimage-> type( $image-> type);
	}
        my $I   = $subimage-> data;
        my $gw  = int(( $W * ( $image->    type & im::BPP) + 31) / 32) * 4;
        my $iw  = int(( $w * ( $subimage-> type & im::BPP) + 31) / 32) * 4;
        my $ibw = $w * $bpp;
        my $dw  = $gw - $ibw;
        
        my $rx  = join( ".{$dw}", map { quotemeta substr( $I, $_ * $iw, $ibw) } 
                (0 .. $subimage-> height - 1));
        my ( $x, $y);
	my @ret;
	my $blanker = ("\0" x ( $bpp * $w));

	while ( 1) {
		pos($G) = 0;
  		study $G;
		my @loc_ret;
		while ( 1) {
		        unless ( $G =~ m/\G.*?$rx/gcs) {
				return unless $multiple;
				last;
			}
			my $p = pos($G);
			$x = ($p - $w * $bpp) % $gw / $bpp;
			$y = int(($p - ( $x + $w) * $bpp) / $gw) + 1;
			next if $x + $w > $W; # scanline wrap
        		push @loc_ret, [ $x, $y - $h ];
			return @{ $loc_ret[0] } unless $multiple;
		}
		# blank zeros over the found stuff to avoid overlapping matches
		for ( @loc_ret) {
			my ( $x, $y) = @$_;
			my $pos = $y * $gw + $x;
			for ( my $i = 0; $i < $h; $i++, $pos += $gw) {
				substr( $G, $pos, $w * $bpp) = $blanker;
			}
		}
		push @ret, @loc_ret;
		return @ret unless @loc_ret;
		@loc_ret = ();
	}
}

sub image2db_key { $_[0]-> data }

# suggest OCR order so that glyphs covering larger area come first (so f.ex.)
# (i) is recognized before (.) and (dotlessi).
sub suggest_glyph_order
{
	my $db = $_[0];
	return map {
		$$_[0]
	} sort {
		$$b[1] <=> $$a[1]
	} map {
		[ $_, $db->{$_}->{width} * $db->{$_}->{height} ]
	} keys %$db;
}

sub enhance_image
{
	my ( $i, %options) = @_;

	require IPA;
	require IPA::Misc;
	require IPA::Point;

	my $min_contrast = $options{min_contrast} || 128;

	# convert to grayscale
	$i-> type(im::Byte);
	
	# get histogram and peaks
	my @h = (0, IPA::Misc::histogram( $i), 0);
	my @peaks =
		map { $_ - 1 }
		sort { $h[$b] <=> $h[$a] } 
		grep { $h[$_] > $h[$_-1] and $h[$_] > $h[$_+1] } 
		1..256;
	@h = @h[1..256];
	
	die "Image's not clear enough"
		if @peaks < 2;

	warn "peaks: @peaks / @h[@peaks]\n"
		if $options{verbose};
	
	# make BW
	my $peak = 1;
	my ( $bg, $fg) = @peaks[0,1];
	while ( abs( $bg - $fg) < $min_contrast) {
		$bg = $fg if $bg < $fg;
		$fg = $peaks[ ++$peak ];
		die "Image's not clear enough (min_contrast required more than $min_contrast)"
			unless defined $fg;
	}
	my $threshold = int(($bg + $fg) / 2);
	warn "fg=$fg bg=$bg threshold=$threshold\n"
		if $options{verbose};
	$i = IPA::Point::threshold( $i, minvalue => $threshold);

	# invert if any; we need white glyphs on black background
	if ( $bg > $fg) {
		warn "invert\n"
			if $options{verbose};
		$i-> put_image( 0, 0, $i, rop::NotPut);
		( $bg, $fg) = ( $fg, $bg);
	}
	
	return $i;
}

sub recognize
{
	my ( $i, $db, %options) = @_;

	unless ( scalar keys %$db) {
		warn "empty dictionary"
			if $options{verbose};
	}

	my @sorted_glyphs = suggest_glyph_order( $db);
	
	# OCR and get glyph positions
	my $num = 0;
	my $max_line_height = 1;
	my @vmap = ( 0 x ( $i-> height));
	my @unsorted = map { 
		my $v = $_;
		my @positions = find_images( $i, $v-> {image}, 1);
	
		my $h = $v-> {image}-> height - 1;
		for my $p ( @positions) {
			# erase glyphs
			$i-> put_image( @$p, $v-> {image}, rop::Blackness);
			# put on vmap
			$vmap[ $$p[1] + $_ ]++ for 0 .. $h;
		}
		$max_line_height = $h + 1 if $max_line_height <= $h;
		$num++; 
		
		warn "$num/", scalar(@sorted_glyphs), ", '$v->{text}' found ", scalar(@positions), " times\n"
			if $options{verbose};
		
		map { [ $v, @$_ ] } @positions;
	} @$db { @sorted_glyphs  };
	$max_line_height *= 2;
	warn "max line height $max_line_height\n"
		if $options{verbose};
	
	# vmap-> rle vmap
	{
		my @chunks   = ([]);
		for ( my $j = 0; $j < @vmap; $j++) {
			if ( $vmap[$j]) {
				push @{ $chunks[-1] }, $j unless @{ $chunks[-1] };
				push @{ $chunks[-1] }, $vmap[$j];
			} else {
				push @chunks, [] if @{ $chunks[-1] };
			}
		}
		@vmap = @chunks;
	}

	# vmap-> occupied ranges; detect number of lines
	my ( @ready_vmap);
	while ( @vmap) {
		my @new;
		for my $v ( @vmap) {
			if ( $#$v > $max_line_height) {
				# split further -- subtract the minimum
				my $min = $v->[1];
				for ( @$v) {
					$min = $_ if $min > $_;
				}
				my @new_chunks = [];
				for ( my $i = 1; $i < @$v; $i++) {
					my $reduced = $v->[$i] - $min;
					if ( $reduced > 0) {
						push @{ $new_chunks[-1]}, $v->[0] + $i - 1
							unless @{ $new_chunks[-1] };
						push @{ $new_chunks[-1]}, $reduced;
					} else {
						push @new_chunks, [ $v-> [0] + $i - 1, 1], [];
					}
				}
				@new_chunks = grep { @$_ } @new_chunks;
				push @new, @new_chunks;
				warn "too wide vline $v->[0]:$#$v split into ", 
					scalar( @new_chunks), " chunks\n"
						if $options{verbose};
				# warn "@$_\n" for @new_chunks;
			} else {
				warn "new vline $v->[0]:$#$v\n"
					if $options{verbose};
				push @ready_vmap, $v;
			}
		}
		@vmap = @new;
	}

	# assign Y-> textline map
	my ( @vlines, %ranges);
	for my $v ( sort { $a->[0] <=> $b->[0] } @ready_vmap) {
		push @vlines, [];
		for ( my $i = 0; $i < $#$v; $i++) {
			$ranges{ $v->[0] + $i } = $#vlines;
		}
	}
	undef @ready_vmap;
	warn "glyphs grouped in " ,scalar(@vlines), " lines of text\n"
		if $options{verbose};
	
	# put glyphs into lines sorted by X
	for ( @unsorted) {
		my ( $v, $x, $y) = @$_;
		push @{ $vlines[ $ranges{$y} ] }, $_;
	}
	
	# sort vlines
	for ( @vlines) {
		@$_ = sort { $$a[1] <=> $$b[1] } @$_;
	}

	my $minspace;
	unless ( defined $options{minspace}) {
		# Calculate min space. 
		# - get average glyph width:
		my $ave_width = 0;
		$ave_width += $_-> {width} for values %$db;
		$ave_width /= scalar keys %$db;
		# - one line of text occupies up to $i-> width, right?
		my $max_chars_in_line = 0;
		for ( @vlines) {
			$max_chars_in_line = @$_ if $max_chars_in_line < @$_;
		}
		$minspace = int($ave_width + .5);
		warn "minspace: $minspace \n"
			if $options{verbose};
	} else {
		$minspace = $options{minspace};
	}
	
	my @text;
	for my $l ( reverse @vlines) {
		my $last = $#$l;
		my $text = '';
		if ( $last >= 0) {
			my $first = $l->[0]->[1] / $minspace;
			$text .= (' ' x $first) if $first > 0;
			for ( my $i = 0; $i < $last; $i++) {
				my $v = $l-> [$i];
				my $dist = ($l-> [$i+1]-> [1] - $v->[1] - $v->[0]->{width}) / $minspace;
				$text .= $v-> [0]-> {text};
				$text .= (' ' x $dist) if $dist > 0;
			}
			$text .= $l-> [-1]-> [0]-> {text};
		}
		push @text, $text;
	}

	return @text;
}

1;

=pod

=head1 NAME

OCR::Naive - convert images into text in an extremely naive fashion

=head1 DESCRIPTION

The module implements a very simple and unsophisticated OCR by finding all
known images in a larger image. The known images are mapped to text using the
preexisting dictionary, and the text lines are returned.

The interesting stuff here is the image finding itself - it is done by a
regexp!  For all practical reasons, images can be easily treated as byte
strings, and regexps are not exception. For example, one needs to locate an
image 2x2 in larger 7x7 image. The regexp constructed should be the first
scanline of smaller image, 2 bytes, verbatim, then 7 - 2 = 5 of any character,
and finally the second scanline, 2 bytes again. Of course there are some quirks,
but these explained in API section.

Dictionaries for different fonts can be created interactively by
C<bin/makedict>; the non-interactive recognition is performed by C<bin/ocr>
which is a mere wrapper to this module.

=head1 SYNOPSIS

    use Prima::noX11; # Prima imaging required
    use OCR::Naive;

    # load a dictionary created by bin/makedict
    $db = load_dictionary( 'my.dict');

    # load image to recognize
    my $i = Prima::Image-> load( 'screenshot.png' );
    $i = enhance_image( $i );

    # ocr!
    print "$_\n" for recognize( $i, $db);

=head1 API

=over

=item load_dictionary $FILE

Loads a glyph dictionary from $FILE, returns a dictionary hash table. If not loaded,
returns C<undef> and C<$!> contains the error.

=item save_dictionary $FILE, $DB 

Saves a glyph dictionary from $DB into $FILE, returns success flag. If failed,
C<$!> contains the error.

=item image2db_key $IMAGE

The dictionary is intended to be a simple hash, where the key is the image pixel data,
and value is a hash of image attributes - width, height, text, and possible something
more for the future. The key currently is image data verbatim, and C<image2db_key> 
returns the data of $IMAGE.

=item find_images $IMAGE, $SUBIMAGE, $MULTIPLE

Locates a $SUBIMAGE in $IMAGE, returns one or many matches, depending on $MULTIPLE.
If single match is requested, stops on the first match, and returns a pair of (X,Y)
coordinates. If $MULTIPLE is 1, returns array of (X,Y) pairs. In both modes, returns
empty list if nothing was found.

=item suggest_glyph_order $DB

When more than one subimage is to be found on a larger image, it is important that 
parts of larger glyphs are not eventually attributed to smaller ones. For example,
letter C<('i')> might be detected as a combination of C<('dot')> and C<('dotlessi')>.
To avoid this C<suggest_glyph_order> sorts all dictionary entries by their occupied
area, larger first, and returns sorted set of keys.

=item enhance_image $IMAGE, %OPTIONS

Glyphs in dictionary are black-and-white images, and the ideal detection should
also happed on 2-color images. C<enhance_image> tries to enhance the contrast of
the image, find histogram peaks, and detect what is foreground and what is background,
and finally converts the image into a black-and-white.

This procedure is of course nowhere near any decent pre-OCR image processing, so
don't expect much. OTOH it might be serve a good-enough quick hack for screen dumps.

If C<$OPTIONS{verbose}> is set, prints details is it goes.

=item recognize $IMAGE, $DB, %OPTIONS

Given a dictionary $DB, recognizes all text it can find on $IMAGE. Returns
array of text lines.

The spaces are a problem with approach, and even though C<recognize> tries to
deduce a minimal width in pixels that should not be treated a <C('space')>
character, it will inevitably fail. Set C<$OPTION{minspace}> to the space
width if you happen to know what font you're detecting.

If C<$OPTIONS{verbose}> is set, prints details is it goes.

=back

=head1 PREREQUISITES

L<Prima>, L<IPA>

=head1 SEE ALSO

L<OCR::PerfectCR>, L<PDF::OCR>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 capmon ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
