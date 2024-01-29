#! perl

# This is a simple example of a font handler callback that uses the
# fontconfig system to find a font given its style properties.
# NOTE: This probably works on Linux only.

# Remember the fc-match program, if found.
my $fallback;

# Cache the fonts so we can reuse them.
my $fontcache;

sub fc_fallback {

    my ( $self, $pdf, $xo, $style ) = @_;

    my $ffamily = $style->{'font-family'};
    my $fstyle  = $style->{'font-style'}  // "";
    my $fweight = $style->{'font-weight'} // "";
    my $fsize   = $style->{'font-size'};

    # The cache key.
    my $key = join( "|", $ffamily, $fstyle, $fweight );

    # Resolve from cache.
    if ( $fontcache->{$pdf}->{$key} ) {
	# Found it, set and return success.
	$xo->font( $fontcache->{$pdf}->{$key}, $fsize );
	return 1;
    }

    # First, find the fc-match program.
    unless ( defined $fallback ) {
	$fallback = '';
	foreach ( split( /:/, $ENV{PATH} ) ) {
	    next unless -f -x "$_/fc-match";
	    $fallback = "$_/fc-match";
	    last;
	}
    }
    return unless $fallback;	# fail

    # Create the fc-match pattern.
    my $pattern = $ffamily;
    $pattern .= ":$fstyle" if $fstyle;
    $pattern .= ":$fweight" if $fweight;

    # Run fc-match.
    open( my $fd, '-|',
	  $fallback, '-s', '--format=%{file}\n', $pattern )
      or do { $fallback = ''; return };

    # Read the results (and use the first one).
    my $res;
    while ( <$fd> ) {
	chomp;
	next unless -f -r $_;
	next unless /\.[ot]tf$/i;
	$res = $_;
	last;
    }
    close($fd);

    # Create the font.
    my $font = $pdf->font($res);

    # Cache it.
    $fontcache->{$pdf}->{$key} = $font;

    # Set it.
    $xo->font( $font, $fsize );

    # Return success.
    return 1;
}

