package Module::Dependency::Grapher;
use strict;
use Module::Dependency::Info;

use vars qw/$VERSION @TIERS %LOOKUP %COLOURS
    @numElements $colWidth $rowHeight
    $nOffset $eOffset $sOffset $wOffset
    /;

$VERSION = (q$Revision: 6632 $ =~ /(\d+)/g)[0];

%COLOURS = (
    type      => [ 0,   0,   0 ],
    links     => [ 164, 192, 255 ],
    blob_to   => [ 192, 0,   0 ],
    blob_from => [ 0,   192, 0 ],
    border    => [ 192, 192, 192 ],
    title1    => [ 64,  0,   0 ],
    test      => [ 255, 0,   0 ],
    black     => [ 0,   0,   0 ],
    white     => [ 255, 255, 255 ],
);

### PUBLIC INTERFACE FUNCTIONS

sub setIndex {
    Module::Dependency::Info::setIndex(@_);
}

sub makeText {
    my ( $kind, $seeds, $filename, $options ) = @_;
    my ( $maxitems, $pushed ) =
        _makeCols( $kind, $seeds, $options->{IncludeRegex}, $options->{ExcludeRegex} );
    my $imgtitle = $options->{'Title'} || 'Dependency Tree';

    # print the text out
    TRACE("Printing text to $filename");
    local *TXT;
    open( TXT, "> $filename" ) or die("Can't open $filename for text write: $!");
    print TXT $imgtitle, "\n", ( '-' x length($imgtitle) ) . "\n\n";
    print TXT q[Key: Parent> indicates parent dependencies
      Child> are child dependencies
       ****> indicates the item(s) from which the relationships are drawn

]                                                                unless $options->{'NoLegend'};
    print( TXT "Grapher.pm $VERSION - " . localtime() . "\n\n" ) unless $options->{'NoVersion'};

    my $pref = 'Parent>';
    for ( 0 .. $#TIERS ) {
        if    ( $_ == $pushed )     { $pref = '****>'; }
        elsif ( $_ == $pushed + 1 ) { $pref = 'Child>'; }
        printf( TXT "%8s %s %s\n", $pref, '+-', join( ', ', sort { $a cmp $b } @{ $TIERS[$_] } ) );
        print( TXT "         |\n" ) unless ( $_ == $#TIERS );
    }
    close TXT;
}

sub makeHtml {
    my ( $kind, $seeds, $filename, $options ) = @_;
    my ( $maxitems, $pushed ) =
        _makeCols( $kind, $seeds, $options->{IncludeRegex}, $options->{ExcludeRegex} );

    my %rowclasses = (
        parent => 'MDGraphParent',
        seed   => 'MDGraphSeed',
        child  => 'MDGraphChild',
    );

    my %notes = (
        parent => 'Parent',
        seed   => '****',
        child  => 'Child',
    );

    my $imgtitle = $options->{'Title'} || 'Dependency Tree';

    # print the HTML out
    TRACE("Printing HTML to $filename");
    local *HTML;
    open( HTML, "> $filename" ) or die("Can't open $filename for HTML write: $!");
    print HTML qq(<div class="MDGraph"><h2>$imgtitle</h2>\n);
    print( HTML "<h4>Grapher.pm $VERSION - " . localtime() . "</h4>\n" )
        unless $options->{'NoVersion'};
    print HTML qq[Key:<br />$notes{'parent'} indicates parent dependencies<br />
	$notes{'seed'} indicates the item(s) from which the relationships are drawn<br />
    $notes{'child'} are child dependencies<br />\n\n] unless $options->{'NoLegend'};

    my $type = 'parent';
    print HTML qq(<table class="MDGraphTable">\n);
    print HTML qq(<tr><th>Kind</th><th>Items</th></tr>\n);
    for ( 0 .. $#TIERS ) {
        if    ( $_ == $pushed )     { $type = 'seed'; }
        elsif ( $_ == $pushed + 1 ) { $type = 'child'; }
        print( HTML
                qq(<tr><td class="$rowclasses{$type}">$notes{$type}</td><td class="$rowclasses{$type}">),
            join( ', ', sort { $a cmp $b } @{ $TIERS[$_] } ),
            "</td></tr>\n"
        );
    }
    print HTML "</table>\n</div>\n";

    # create the imagemap
    my $rv = 1;
    if ( $options->{ImageMap} ) {
        my $code = $options->{ImageMapCode} || \&_imgmapdefault;
        my $frmt = $options->{HrefFormat}   || '';
        _imageDimsSet();
        if ( $maxitems < 8 ) {
            $rowHeight = 8 * $rowHeight * 1.5 / $maxitems;
        }
        elsif ( $maxitems < 16 ) {
            $rowHeight = 16 * $rowHeight / $maxitems;
        }
        _packObjects( $rowHeight * $maxitems, 5 );
        my $str = qq(<map name="dependence">\n);
        foreach my $v ( values %LOOKUP ) { $str .= $code->( $v, $frmt ); }
        $str .= qq(</map>\n);

        if ( lc( $options->{ImageMap} ) eq 'print' ) {
            print HTML $str;
        }
        else {
            $rv = $str;
        }
    }

    close HTML;

    return $rv;
}

sub _imgmapdefault {
    my ( $v, $frmt ) = @_;
    my $pack = $v->{'package'};
    my $alt  = "Root the dependency tree on '$pack'";
    return qq(<!-- PACK $pack --><area href=")
        . sprintf( $frmt, $pack )
        . q(" shape="rect" coords=")
        . int( $v->{'x'} - 3 ) . ','
        . int( $v->{'y'} - 1 ) . ','
        . int( $v->{'x2'} + 3 ) . ','
        . int( $v->{'y'} + 9 )
        . qq(" alt="$alt" title="$alt" />\n);
}

sub makeImage {
    require GD;
    import GD;

    my ( $kind, $seeds, $filename, $options ) = @_;
    my $type     = uc( $options->{'Format'} ) || 'PNG';
    my $imgtitle = $options->{'Title'}        || 'Dependency Chart';

    my ( $maxitems, $pushed ) =
        _makeCols( $kind, $seeds, $options->{IncludeRegex}, $options->{ExcludeRegex} );
    _imageDimsSet();

    LOG("Making image to $filename");

    if ( $maxitems < 8 ) {
        $rowHeight = 8 * $rowHeight * 1.5 / $maxitems;
    }
    elsif ( $maxitems < 16 ) {
        $rowHeight = 16 * $rowHeight / $maxitems;
    }

    my $imgWidth  = $colWidth * ( scalar(@TIERS) < 3 ? 3 : scalar(@TIERS) );
    my $imgHeight = $rowHeight * $maxitems;

    my $realImgWidth  = $imgWidth + $wOffset + $eOffset;
    my $realImgHeight = $imgHeight + $nOffset + $sOffset;
    LOG("Rows are $rowHeight px, maxitems is $maxitems, image is $realImgWidth * $realImgWidth");

    # set up image object
    my $im = new GD::Image( $imgWidth + $wOffset + $eOffset, $imgHeight + $nOffset + $sOffset )
        || die("Couldn't build GD object: $!");
    my $colours;
    $im->colorAllocate( 255, 255, 255 );
    while ( my ( $k, $v ) = each %COLOURS ) { $colours->{$k} = $im->colorAllocate(@$v); }

    _packObjects( $imgHeight, 5 );    # gdTinyFont has 5 pixel wide characters
    _linkObjects( $im, $colours );
    _labelObjects( $im, $colours );

    # add legend and prettiness
    TRACE("Drawing legend etc");
    $im->string( gdMediumBoldFont(), 5, 3, $imgtitle, $colours->{'title1'} );
    $im->string( gdSmallFont(), 5, 17, "Grapher.pm $VERSION - " . localtime(),
        $colours->{'title1'} )
        unless $options->{'NoVersion'};

    _drawLegend( $im, $colours, $realImgWidth - 160 - $eOffset, 3 ) unless $options->{'NoLegend'};

    TRACE("Printing image");
    local *IMG;
    open( IMG, "> $filename" ) or die("Can't open $filename for image write: $!");
    binmode(IMG);
    if ( $type eq 'GIF' ) {
        print IMG $im->gif;
    }
    elsif ( $type eq 'PNG' ) {
        print IMG $im->png;
    }
    elsif ( $type eq 'JPG' ) {
        print IMG $im->jpg;
    }
    elsif ( $type eq 'GD' ) {
        print IMG $im->gd;
    }
    else { die("Unrecognized image type $type"); }
    close IMG;
}

# SVG has an origin at the top-left, like GD, and an SVG image can use unitless coordinates: so we can borrow a lot from makeImage()
sub makeSvg {
    require SVG;
    import SVG;

    my ( $kind, $seeds, $filename, $options ) = @_;
    my $imgtitle = $options->{'Title'} || 'Dependency Chart';

    my ( $maxitems, $pushed ) =
        _makeCols( $kind, $seeds, $options->{IncludeRegex}, $options->{ExcludeRegex} );
    _imageDimsSet();

    LOG("Making SVG to $filename");

    if ( $maxitems < 8 ) {
        $rowHeight = 8 * $rowHeight * 1.5 / $maxitems;
    }
    elsif ( $maxitems < 16 ) {
        $rowHeight = 16 * $rowHeight / $maxitems;
    }

    my $imgWidth  = $colWidth * ( scalar(@TIERS) < 3 ? 3 : scalar(@TIERS) );
    my $imgHeight = $rowHeight * $maxitems;

    my $realImgWidth  = $imgWidth + $wOffset + $eOffset;
    my $realImgHeight = $imgHeight + $nOffset + $sOffset;
    LOG("Rows are $rowHeight px, maxitems is $maxitems, image is $realImgWidth * $realImgWidth");

    my $im = new SVG(
        'viewBox' => (
                  '0 0 '
                . ( $imgWidth + $wOffset + $eOffset ) . ' '
                . ( $imgHeight + $nOffset + $sOffset )
        ),
        'preserveAspectRatio' => 'xMidYMid',
        '-indent'             => "\t"
    );

    # set up image object
    my $colours;
    while ( my ( $k, $v ) = each %COLOURS ) {
        $colours->{$k} = sprintf( '#%2.2x%2.2x%2.2x', @$v );
    }

    $im->rectangle(
        'x'      => 0,
        'y'      => 0,
        'width'  => ( $imgWidth + $wOffset + $eOffset ),
        'height' => ( $imgHeight + $nOffset + $sOffset ),
        stroke   => $colours->{'black'},
        fill     => 'none'
    );
    _packObjects( $imgHeight, 5 );
    _linkObjects( $im, $colours );

    # are things clickable? Bit of a kludge, this
    $colours->{'_HREF_FORMAT'} = $options->{'HrefFormat'};
    _labelObjects( $im, $colours );
    delete $colours->{'_HREF_FORMAT'};

    # add legend and prettiness
    TRACE("Drawing legend etc");

    $im->text(
        'x'     => 5,
        'y'     => 12,
        'fill'  => $colours->{'title1'},
        'style' => { 'font-size' => '12px' }
    )->cdata($imgtitle);
    $im->text(
        'x'     => 5,
        'y'     => 23,
        'fill'  => $colours->{'title1'},
        'style' => { 'font-size' => '9px' }
        )->cdata( "Grapher.pm $VERSION - " . localtime() )
        unless $options->{'NoVersion'};
    _drawLegend( $im, $colours, $realImgWidth - 160 - $eOffset, 3 ) unless $options->{'NoLegend'};

    $im->title( id => 'document-title' )->cdata($imgtitle);
    $im->desc( id => 'document-desc' )
        ->cdata('This image shows dependency relationships between perl programs and modules');

    TRACE("Printing SVG");
    local *IMG;
    open( IMG, "> $filename" ) or die("Can't open $filename for image write: $!");
    print IMG $im->xmlify;
    close IMG;
}

sub makePs {
    require PostScript::Simple;

    my ( $kind, $seeds, $filename, $options ) = @_;
    my $imgtitle = $options->{'Title'} || 'Dependency Chart';
    my $eps = ( uc( $options->{'Format'} ) eq 'PS' ) ? 0 : 1;
    my $colour = exists( $options->{'Colour'} ) ? $options->{'Colour'} : 1;
    my $font = $options->{'Font'} || 'Helvetica';

    my ( $maxitems, $pushed ) =
        _makeCols( $kind, $seeds, $options->{IncludeRegex}, $options->{ExcludeRegex} );
    _psDimsSet();

    LOG("Making postscript to $filename");

    if ( $maxitems < 8 ) {
        $rowHeight = 8 * $rowHeight * 1.5 / $maxitems;
    }
    elsif ( $maxitems < 16 ) {
        $rowHeight = 16 * $rowHeight / $maxitems;
    }

    my $imgWidth  = $colWidth * ( scalar(@TIERS) < 3 ? 3 : scalar(@TIERS) );
    my $imgHeight = $rowHeight * $maxitems;

    my $realImgWidth  = $imgWidth + $wOffset + $eOffset;
    my $realImgHeight = $imgHeight + $nOffset + $sOffset;
    LOG("Rows are $rowHeight px, maxitems is $maxitems, image is $realImgWidth * $realImgWidth");

    my $p = new PostScript::Simple(
        eps       => $eps,
        colour    => $colour,
        clip      => 1,
        landscape => ( !$eps ),
        xsize     => $realImgWidth,
        ysize     => $realImgHeight,
        units     => 'bp'
        )    # we use points because they're close to pixels, as used in GD
        || die("Can't build Postscript object: $!");
    $p->setlinewidth(0.5);
    $p->setfont( $font, 9 );

    _packObjects( $imgHeight, 5.5 );
    _linkObjects($p);
    $p->setcolour( @{ $COLOURS{'type'} } );
    _labelObjects($p);

    # add legend and prettiness
    TRACE("Drawing legend etc");
    _drawPsLegend( $p, $realImgWidth - 160 - $eOffset, 16 ) unless $options->{'NoLegend'};

    $p->setfont( $font, 16 );
    $p->setcolour( @{ $COLOURS{'title1'} } );
    $p->text( 15, 18, $imgtitle );

    $p->setfont( $font, 12 );
    $p->setcolour( @{ $COLOURS{'title1'} } );
    $p->text( 15, 35, "Grapher.pm $VERSION - " . localtime() ) unless $options->{'NoVersion'};

# 	$p->setcolour( @{$COLOURS{'test'}} ); 	$p->line( 0, $nOffset, $realImgWidth, $nOffset); 	$p->line( 0, $realImgHeight-$sOffset, $realImgWidth, $realImgHeight-$sOffset); 	$p->line( $wOffset, 0, $wOffset, $realImgHeight); 	$p->line( $realImgWidth-$eOffset, 0, $realImgWidth-$eOffset, $realImgHeight);

    TRACE("Printing image");
    $p->output($filename);
}

### PRIVATE INTERNAL ROUTINES

# algorithm which sorts dependencies into a series of generations (the @TIERS array)
sub _makeCols {
    my $kind  = shift();
    my $seeds = shift();
    my $re    = shift() || '';
    my $xre   = shift() || '';

    $kind = uc($kind);
    TRACE("makeCols: kind <$kind> re <$re> xre <$xre>");
    unless ( ref($seeds) ) { $seeds = [$seeds]; }
    unless ( $kind eq 'CHILD' || $kind eq 'PARENT' || $kind eq 'BOTH' ) {
        die("unrecognized sort of tree required: $kind - should be 'child', 'parent' or 'both'");
    }

    @TIERS = ();
    my %seen = ();

    # this entry is where we start the tree discovery off from
    my $seedrow = [@$seeds];
    push( @TIERS, $seedrow );

    my $found = 0;
    my $ptr   = 0;

    # get child dependencies
    if ( $kind eq 'CHILD' || $kind eq 'BOTH' ) {
        TRACE("makeCols: child dependencies");
        do {
            $found = 0;
            my $temp = [];
            foreach ( @{ $TIERS[$ptr] } ) {
                my $obj = Module::Dependency::Info::getItem($_);
                next unless $obj->{filename};
                $LOOKUP{$_} = $obj;
                $seen{$_}   = 1;
                TRACE("...for $obj->{'package'}");

                foreach my $dep ( @{ $obj->{'depends_on'} } ) {
                    next if $seen{$dep};
                    if ( ( $re && $dep !~ m/$re/ ) || ( $xre && $dep =~ m/$xre/ ) )
                    {    # if given regexps then apply filter
                        TRACE("  !..$dep skipped by regex");
                        $seen{$dep} = 1;
                        next;
                    }
                    TRACE("  ...found $dep");
                    $LOOKUP{$dep} = Module::Dependency::Info::getItem($dep)
                        || do { $seen{$dep} = 1; next; };
                    push( @$temp, $dep );
                    $seen{$dep} = 1;
                    $found = 1;
                }
            }
            push( @TIERS, $temp ) if $found;
            $ptr++;
        } while ( $found == 1 );
    }

    my $pushed = 0;

    # get parent dependencies
    if ( $kind eq 'PARENT' || $kind eq 'BOTH' ) {
        TRACE("makeCols: parent dependencies");
        do {
            $found = 0;
            my $temp = [];
            foreach ( @{ $TIERS[0] } ) {
                my $obj = Module::Dependency::Info::getItem($_);
                next unless $obj->{filename};
                $LOOKUP{$_} = $obj;
                $seen{$_}   = 1;
                TRACE("...for $obj->{'package'}");

                foreach my $dep ( @{ $obj->{'depended_upon_by'} } ) {
                    next if $seen{$dep};
                    if ( ( $re && $dep !~ m/$re/ ) || ( $xre && $dep =~ m/$xre/ ) )
                    {    # if given regexps then apply filter
                        TRACE("  !..$dep skipped by regex");
                        $seen{$dep} = 1;
                        next;
                    }
                    TRACE("  ...found $dep");
                    $LOOKUP{$dep} = Module::Dependency::Info::getItem($dep)
                        || do { $seen{$dep} = 1; next; };
                    push( @$temp, $dep );
                    $seen{$dep} = 1;
                    $found = 1;
                }
            }
            if ($found) {
                unshift( @TIERS, $temp );
                $pushed += 1;
            }
        } while ( $found == 1 );
    }

    # extract sizes of each column
    @numElements = ();
    my $maxitems = 1;
    foreach (@TIERS) {
        my $num = $#{$_} + 1;
        $maxitems = $num if $num > $maxitems;
        push( @numElements, $num );
    }
    return ( $maxitems, $pushed );
}

# work out _where_ we're going to put the items
sub _packObjects {
    my ( $imgHeight, $charwidth ) = @_;
    TRACE("Packing objects");
    for my $x ( 0 .. $#TIERS ) {
        my $y = 0;
        foreach ( sort { $a cmp $b } @{ $TIERS[$x] } ) {
            my $obj = $LOOKUP{$_};
            my $cx  = ( $colWidth * $x ) + $wOffset;
            my $cy  = ( ( $imgHeight * ( $y + 1 ) ) / ( $numElements[$x] + 1 ) ) + $nOffset;

            #			TRACE( "Putting text $obj->{'package'} at $cx, $cy" );
            # use the first, i.e. highest up the food chain, coordinates only
            unless ( exists $obj->{'x'} ) {
                $obj->{'x'}  = $cx;
                $obj->{'y'}  = $cy;
                $obj->{'x2'} =
                    $cx + 1 + $charwidth * length( $obj->{'package'} )
                    ;    # gdTinyFont has characters 5 pixels wide
            }
            $y++;
        }
    }
}

sub _linkObjects {
    my ( $im, $colours ) = @_;

    # draw a load of lines...
    TRACE("Drawing links between items");
    foreach my $x (@TIERS) {

        #...for every object
        foreach (@$x) {
            my $obj = $LOOKUP{$_};

            #...link to all its dependencies
            foreach my $dep ( @{ $obj->{'depends_on'} } ) {
                next unless ( exists $LOOKUP{$dep} );
                my $depObj = $LOOKUP{$dep};
                TRACE( $obj->{'package'} . ' -> ' . $depObj->{'package'} );
                _drawLink( $im, $colours, $obj->{'x2'}, $obj->{'y'}, $depObj->{'x'},
                    $depObj->{'y'} );
            }
        }
    }
}

sub _labelObjects {
    my ( $p, $colours ) = @_;
    TRACE("Drawing the text");
    foreach my $x (@TIERS) {
        foreach (@$x) {
            my $obj = $LOOKUP{$_};
            _drawText( $p, $colours, $obj->{'x'}, $obj->{'y'}, $obj->{'package'} );
        }
    }
}

# ! behaves differently for each image type
sub _drawLegend {
    my ( $im, $colours, $x, $y ) = @_;
    my $type = ref($im);

    if ( $type =~ m/^GD/ ) {
        $im->rectangle( $x, $y, $x + 138, $y + 37, $colours->{'border'} );
    }
    elsif ( $type =~ m/SVG/ ) {
        $im->rectangle(
            'x'      => $x,
            'y'      => $y,
            'width'  => 138,
            'height' => 37,
            stroke   => 'none',
            stroke   => $colours->{'border'},
            fill     => 'none'
        );
    }
    $x += 4;
    $y += 3;

    _drawText( $im, $colours, $x, $y, 'Legend' );
    if ( $type =~ m/^GD/ ) {
        $im->line( $x, $y + 8, $x + 30, $y + 8, $colours->{'type'} );
    }
    elsif ( $type =~ m/SVG/ ) {
        $im->line(
            x1     => $x,
            y1     => $y + 8,
            x2     => $x + 30,
            y2     => $y + 8,
            stroke => $colours->{'type'}
        );
    }
    $y += 12;
    _drawLink( $im, $colours, $x + 31, $y, 100 + $x, $y );
    _drawText( $im, $colours, $x, $y, 'Foo.pl' );
    _drawText( $im, $colours, 100 + $x, $y, 'Bar' );
    $y += 12;
    _drawText( $im, $colours, $x, $y, 'Foo.pl depends upon Bar.pm' );
}

sub _drawPsLegend {
    my ( $p, $x, $y ) = @_;

    _drawText( $p, undef, $x + 2, $y + 26, 'Legend' );
    $p->setlinewidth(0.4);
    $p->line( $x + 2, $y + 25, $x + 32, $y + 25 );
    _drawText( $p, undef, $x + 2,   $y + 14, 'Foo.pl' );
    _drawText( $p, undef, $x + 102, $y + 14, 'Bar' );
    _drawText( $p, undef, $x + 2,   $y + 2,  'Foo.pl depends upon Bar.pm' );
    _drawLink( $p, undef, $x + 29, $y + 14, $x + 102, $y + 14 );

    $p->setlinewidth(0.25);
    $p->setcolour( @{ $COLOURS{'black'} } );
    $p->box( $x, $y - 1, $x + 120, $y + 34 );
}

# ! behaves differently for each image type
sub _drawText {
    my ( $im, $colours, $x, $y, $text ) = @_;
    my $type = ref($im);

    #	TRACE("_drawText for $type");

    if ( $type =~ m/^GD/ ) {
        $im->string( gdTinyFont(), $x, $y, $text, $colours->{'type'} );
    }
    elsif ( $type =~ m/^PostScript/ ) {
        $im->text( $x, $y, $text );
    }
    elsif ( $type =~ m/^SVG/ ) {
        if ( $colours->{'_HREF_FORMAT'} ) {
            $im->anchor( -href => sprintf( $colours->{'_HREF_FORMAT'}, $text ) )->text(
                'x'     => $x,
                'y'     => $y + 5.5,
                'fill'  => $colours->{'type'},
                'style' => { 'font-size' => '8px', 'font-family' => 'Courier, Monaco, monospaced' }
            )->cdata($text);
        }
        else {
            $im->text(
                'x'     => $x,
                'y'     => $y + 5.5,
                'fill'  => $colours->{'type'},
                'style' => { 'font-size' => '8px', 'font-family' => 'Courier, Monaco, monospaced' }
            )->cdata($text);
        }
    }
}

# ! behaves differently for each image type
sub _drawLink {
    my ( $im, $colours, $xa, $ya, $xb, $yb ) = @_;
    my $type = ref($im);

    #	TRACE("_drawLink for $type");

    if ( $type =~ m/^GD/ ) {
        $im->line( $xa, $ya + 3, $xb - 3, $yb + 3, $colours->{'links'} );
        $im->rectangle( $xa, $ya + 2, $xa + 1, $ya + 4, $colours->{'blob_from'} );
        $im->rectangle( $xb - 3, $yb + 2, $xb - 4, $yb + 4, $colours->{'blob_to'} );
    }
    elsif ( $type =~ m/^PostScript/ ) {
        $im->setlinewidth(0.22);
        $im->line( $xa, $ya + 3, $xb - 3, $yb + 3, @{ $COLOURS{'black'} } );
        $im->setcolour( @{ $COLOURS{'white'} } );
        $im->circle( $xb - 3, $yb + 3, 1, 1 );
        $im->setcolour( @{ $COLOURS{'black'} } );
        $im->circle( $xa, $ya + 3, 1, 1 );
        $im->circle( $xb - 3, $yb + 3, 1, 0 );
    }
    elsif ( $type =~ m/^SVG/ ) {
        $im->line(
            x1     => $xa,
            y1     => $ya + 3,
            x2     => $xb - 3,
            y2     => $yb + 3,
            stroke => $colours->{'links'}
        );
        $im->rectangle(
            'x'      => $xa,
            'y'      => $ya + 2,
            'width'  => 2,
            'height' => 2,
            stroke   => 'none',
            fill     => $colours->{'blob_from'}
        );
        $im->rectangle(
            'x'      => $xb - 4,
            'y'      => $yb + 2,
            'width'  => 2,
            'height' => 2,
            stroke   => 'none',
            fill     => $colours->{'blob_to'}
        );
    }
    else {
        die 'This indicates that the object model has changed somewhere. Should not happen.';
    }
}

sub _imageDimsSet {
    $colWidth  = 200;
    $rowHeight = 12;

    $nOffset = 40;
    $sOffset = 10;
    $wOffset = 20;
    $eOffset = 1;
}

sub _psDimsSet {
    $colWidth  = 150;
    $rowHeight = 12;

    $nOffset = 60;
    $sOffset = 40;
    $wOffset = 40;
    $eOffset = 30;
}

sub TRACE { }
sub LOG   { }

1;

=head1 NAME

Module::Dependency::Grapher - creates visual dependency charts and accessible text versions

=head1 SYNOPSIS

	use Module::Dependency::Grapher;
	Module::Dependency::Grapher::setIndex( '/var/tmp/dependence/unified.dat' );
	Module::Dependency::Grapher::makeImage( 'both', ['Foo::Bar', 'Foo::Baz'], '/home/www/foodep.png', {Format => 'png'} );
	Module::Dependency::Grapher::makePs( 'both', ['Foo::Bar', 'Foo::Baz'], '/home/www/foodep.eps' );
	Module::Dependency::Grapher::makeText( 'both', ['Foo::Bar', 'Foo::Baz'], '/home/www/foodep.txt', {NoLegend => 1} );
	Module::Dependency::Grapher::makeHtml( 'both', ['Foo::Bar', 'Foo::Baz'], '/home/www/foodep.ssi', {NoLegend => 1} );

=head1 DESCRIPTION

=over 4

=item Module::Dependency::Grapher::setIndex( $filename );

This tells the module where the database is. It doesn't affect the other
modules - they have their own setIndex routines. The default is /var/tmp/dependence/unified.dat

=item Module::Dependency::Grapher::makeImage( $kind, $seeds, $filename, $options );

Draws an image showing the dependency links between a set of items. The 'tree' of dependencies is
started at the item or items named in the $seeds array reference. The code then links to all
the parent and/or child dependencies of those seeds. And repeat for those items, etc.

$kind is 'parent', 'child' or 'both'. This parameter tells the code whether to plot (respectively)
things that depend upon the seed items, things that the seed items depend upon, or both directions.

$seeds is a reference to an array of item names

$filename is the file to which the output should go. Use '-' for STDOUT. Clobbers existing files.

See below for the options. See README.EXAMPLES too.

=item Module::Dependency::Grapher::makePs( $kind, $seeds, $filename, $options );

As makeImage() but does it in PostScript or EPS. EPS is the default. See below for the options. See README.EXAMPLES too.

=item Module::Dependency::Grapher::makeSvg( $kind, $seeds, $filename, $options );

As makeImage() but does it in SVG. See below for the options. See README.EXAMPLES too.

=item Module::Dependency::Grapher::makeText( $kind, $seeds, $filename, $options );

Creates a plain-text rendition of the dependency heirarchy. As it's only ASCII it can't plot
the individual links between items, so it simplifies and presents only each level of the 
tree as a whole.

Parameters are as for makeImage()

See below for options. See README.EXAMPLES too.

=item Module::Dependency::Grapher::makeHtml( $kind, $seeds, $filename, $options );

Creates an HTML fragment rendition of the dependency heirarchy. As it's only text it can't plot
the individual links between items, so it simplifies and presents only each level of the 
tree. Information comes out in a table, and the whole fragment uses CLASS attributes so that you
can apply CSS to it. Typical fragment is:

	<div class="MDGraph"><h2>Dependencies for all scripts</h2>
	<h4>Grapher.pm 1.7 - Fri Jan 11 00:00:56 2002</h4>
	Key:<br />Parent indicates parent dependencies<br />
		**** indicates the item(s) from which the relationships are drawn<br />
	    Child are child dependencies<br />

	<table class="MDGraphTable">
	<tr><th>Kind</th><th>Items</th></tr>
	<tr><td class="MDGraphSeed">****</td><td class="MDGraphSeed">x.pl, y.pl</td></tr>
	<tr><td class="MDGraphChild">Child</td><td class="MDGraphChild">a, b, c</td></tr>
	</table>
	</div>

Parameters are as for makeImage(). 

See below for options - especially the ImageMap (and related) options, which allows this method to return an HTML client-side
imagemap. See README.EXAMPLES too.

=back

=head2 OPTIONS

Options are case-sensitive, and you pass them in as a hash reference, e.g.

	Module::Dependency::Grapher::makeImage( $kind, $objlist, $IMGFILE, {Title => $title, Format => 'GIF'} );

These are the recognized options:

=over 4

=item Title

Sets the title of the output to whatever string you want. Displayed at the top.

=item Format

The output image format - can be (case-insensitive) GIF, PNG, GD, or JPG - but some may not be available
depending on how your local copy of libgd was compiled. You'll need to examine you local GD setup (PNG is
pretty standard thesedays though) Default is PNG.

The makePs() method recognizes only 'EPS' or 'PS' as format options. Default is 'EPS'.

=item IncludeRegex

A regular expression use to filter the items displayed. If this is '::' for example then the output will only
show dependencies that contain those characters.

=item ExcludeRegex

A regular expression use to filter the items displayed. If this is '::' for example then the output will B<not>
show dependencies that contain those characters.

=item NoLegend

If true, don't print the 'legend' box/text

=item NoVersion

If true, don't print the version/date line.

=item Colour

Used by makePs() only - if 1 it makes a colour image, if 0 it makes a greyscale image. Default is 1.

=item Font

sed by makePs() only. Set the font used in the drawing. Default is 'Helvetica'.

=item ImageMap

Used by makeHtml() only - if set to 'print' it will print a skeleton imagemap to the output file; if set to 'return' then the imagemap text
is the return value of makeHtml() so that the caller can process the string further.

An imagemap looks like this example, but you can change the href attributes using the HrefFormat option (see below) so that they match what your CGI
program is expecting.

	<map name="dependence">
	<!-- PACK a --><area href="" shape="rect" coords="217,110,229,122" alt="Root dependency tree on a" title="Root dependency tree on a">
	<!-- PACK x.pl --><area href="" shape="rect" coords="17,110,44,122" alt="Root dependency tree on x.pl" title="Root dependency tree on x.pl">
	</map>

If you want to totally change the format of each 'area' element see the ImageMapCode option below.

Note that the href attributes are deliberately left empty, for users of the 'return' method to easily post-process the string. The PACK comment
at the start of each line is provided to tell you what the package or scriptname is. The imagemap corresponds to the image that _would_
be produced by makeImage() if it were given the same arguments.

See the bundled 'cgidepend.plx' CGI program to see a use for this imagemap.

=item ImageMapCode

Used by makeHtml() only - must be a code reference. Called once for each 'area' required. The first argument is the package name
that the 'area' corresponds to, 'Foo::Bar' or 'baz.pl' for example. The second argument is the current HrefFormat setting, but you
may ignore that, seeing as you're going to be writing the entire element. The default coderef creates the 'area' elements as shown above
and respects the HrefFormat option.

=item HrefFormat

Used by makeHtml() and makeSvg() only - default is ''. A sprintf() formatting string used to format the 'href'
attribute in EACH 'area' element of the imagemap, or the href of the anchors in SVG output.
E.g. '?myparam=%s' would create an href of '?myparam=Foo'.

If empty (as is the default) then you get no clickable links in the SVG output.

=back

=head1 PREREQUISITES

If you want to use the makePs() method you'll need PostScript::Simple installed.
If you want to use the makeImage() method you'll need GD installed.
If you want to use the makeSvg() method you'll need the SVG module.
However, these modules are 'require'd as needed so you can quite happily use the makeText and makeHtml routines.

=head1 SEE ALSO

Module::Dependency and the README files.

=head1 VERSION

$Id: Grapher.pm 6632 2006-07-11 14:00:38Z timbo $

=cut

