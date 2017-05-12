package Spreadsheet::HTML::Presets::Conway;
use strict;
use warnings FATAL => 'all';

eval "use Color::Spectrum";
our $NO_SPECTRUM = $@;

eval "use Encode::Wechsler";
our $NO_WECHSLER = $@;

sub conway {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );

    $args->{on}    ||= '#00BFA5';
    $args->{off}   ||= '#EEEEEE';
    $args->{colors} = ($NO_SPECTRUM or !$args->{fade})
        ? [ ($args->{on}) x 10 ]
        : [ Color::Spectrum::generate( 10, $args->{on}, $args->{off} ) ];

    $args->{interval} ||= 200;

    if ($args->{wechsler} and not $NO_WECHSLER) {
        my $wechsler = Encode::Wechsler->new( pad => defined $args->{pad} ? $args->{pad} : 1 );
        my @grid;
        eval { @grid = $wechsler->decode( $args->{wechsler} ) };
        if ($@) {
            $args->{data} = [[ 'Error' ],[ $@ ]];
            return $self ? $self->generate( %$args ) : Spreadsheet::HTML::generate( %$args );
        }

        $args->{_max_rows} = scalar @grid;
        $args->{_max_cols} = scalar @{ $grid[0] };

        for my $row (0 .. $#grid) {
            for my $col (0 .. $#{ $grid[$row] } ) {
                $args->{"-r${row}c${col}"} = $grid[$row][$col] if $grid[$row][$col];
            }
        }
    } elsif ($args->{wechsler} and $NO_WECHSLER) {
        warn "You specified an argument for wechsler but Encode::Wechsler is not installed\n";
    }

    my ( @cells, @ids );
    for my $r ( 0 .. $args->{_max_rows} - 1 ) {
        for my $c ( 0 .. $args->{_max_cols} - 1 ) {
            my $cell = sprintf '-r%sc%s', $r, $c;
            push @cells,
                $cell => {
                    id     => join( '-', $r, $c ),
                    class  => 'conway',
                    width  => '30px',
                    height => '30px',
                    style  => { 'background-color' => $args->{off} },
                };
            # if alpha param was set to valid value, then
            # only non-alpha cells will be set here
            # TODO: determine alpha value (lightest color) for client
            push @ids, join( '-', $r, $c ) if $args->{$cell};
        }
    }

    # find and remove 'file' param and its value if found
    # because it was already processed via ::File::Loader by way of _args()
    if ($args->{file} and $args->{file} =~ /\.(gif|png|jpe?g)$/) {
        my $index = 0;
        for (0 .. $#_) {
            next if ref $_[$_];
            if ($_[$_] eq 'file') { $index = $_; last }
        }
        splice @_, $index, 2;
        push @_, ( fill => $args->{fill} );
    }

    my @args = (
        @cells,
        data    => $data,
        ( $args->{wechsler} ? (matrix => 1) : () ),
        ( $args->{wechsler} ? (fill => join 'x', $args->{_max_rows}, $args->{_max_cols}) : () ),
        caption => { '<button id="toggle" onClick="toggle()">Start</button>' => { align => 'bottom' } },
        @_,
    );

    my $js    = _javascript( %$args, ids => \@ids );
    my $table = $self ? $self->generate( @args ) : Spreadsheet::HTML::generate( @args );
    return $js . $table;
}

sub _javascript {
    my %args = @_;

    my $js = sprintf _js_tmpl(),
        $args{_max_rows},
        $args{_max_cols},
        $args{interval},
        join( ',', map "'$_'", @{ $args{ids} } ),
        $args{off},
        join( ',', map "'$_'", @{ $args{colors} } ),
    ;

    return Spreadsheet::HTML::Presets::_js_wrapper( code => $js, %args );
}

sub _js_tmpl {
    return <<'END_JAVASCRIPT';

/* Copyright 2017 Jeff Anderson */
/* install JavaScript::Minifier to minify this code */
var MATRIX;
var ROW = %s;
var COL = %s;
var INTERVAL = %s;
var tid;
var ids = [ %s ];

function Cell (id) {
    this.id         = id;
    this.neighbors  = 0;
    this.age        = 0;
    this.off        = '%s';
    this.on         = [ %s ];

    this.grow = function( age ) {
        this.age = age;
        if (age == 0) {
            $('#' + this.id).css( 'background-color', this.off );
        } else {
            $('#' + this.id).css( 'background-color', this.on[age - 1] );
        }
    }

    this.update = function() {
        if (this.age) {
            if ((this.neighbors <= 1) || (this.neighbors >= 4)) {
                this.grow( 0 );
            } else if (this.age < 9) {
                this.grow( ++this.age );
            }
        }
        else {
            if (this.neighbors == 3) {
                this.grow( 1 );
            }
        }
        this.neighbors = 0;
    }
}

function toggle() {
    if ($('#toggle').html() === 'Start') {
        tid = setInterval( update, INTERVAL );
        $('#toggle').html( 'Stop' );
    } else {
        clearInterval( tid );
        $('#toggle').html( 'Start' );
    }
}

$(document).ready(function(){

    $('th.conway, td.conway').click( function( data ) {
        var matches  = this.id.match( /(\d+)-(\d+)/ );
        var selected = MATRIX[matches[1]][matches[2]];
        if (selected.age) {
            selected.grow( 0 );
        } else {
            selected.grow( 1 );
        }
    });

    MATRIX = new Array( ROW );
    for (var row = 0; row < ROW; row++) {
        MATRIX[row] = new Array( COL );
        for (var col = 0; col < COL; col++) {
            MATRIX[row][col] = new Cell( row + '-' + col );
        }
    }

    // activate any "pre-loaded" IDs
    for (var i = 0; i < ids.length; i++) {
        var matches  = ids[i].match( /(\d+)-(\d+)/ );
        var selected = MATRIX[matches[1]][matches[2]];
        selected.grow( 1 );
    }

});

function update() {

    // count neighbors
    for (var row = 0; row < ROW; row++) {
        for (var col = 0; col < COL; col++) {

            for (var r = -1; r <= 1; r++) {
                if ( (row + r >=0) & (row + r < ROW) ) {

                    for (var c = -1; c <= 1; c++) {
                        if ( ((col+c >= 0) & (col+c < COL)) & ((row+r != row) | (col+c != col))) {
                            if (MATRIX[row + r][col + c].age) {
                                MATRIX[row][col].neighbors++;
                            }
                        }
                    }
                }
            }
        }
    }

    // update cells
    for (var row = 0; row < ROW; row++) {
        for (var col = 0; col < COL; col++) {
            MATRIX[row][col].update();    
        }
    }
}
END_JAVASCRIPT
}

=head1 NAME

Spreadsheet::HTML::Presets::Conway - Generate Conway's Game of Life in HTML table cells' background.

=head1 DESCRIPTION

This is a container for L<Spreadsheet::HTML> preset methods.
These methods are not meant to be called from this package.
Instead, use the Spreadsheet::HTML interface:

  use Spreadsheet::HTML;
  my $generator = Spreadsheet::HTML->new( data => \@data );
  print $generator->conway;

  # or
  use Spreadsheet::HTML qw( conway );
  print conway( data => \@data );

=head1 METHODS

=over 4

=item * C<conway( wechsler, on, off, colors, fade, interval, jquery, %params )>

Game of life. From an implementation i wrote back in college.

  conway( on => 'red', off => 'gray' )

Set the timer with C<interval> (defaults to 200 miliseconds).

  conway( interval => 75 )

If you have L<Encode::Wechsler> installed then you can preload the game board
with any valid Wechsler Code:

  conway( wechsler => 'xp3_0ggmligkcz32w46' )

Some codes require additional padding in order to sustain properly.

  conway( wechsler => 'xp30_ccx8k2s3zy3103y531e8', pad => 2 )

Padding defaults to 1, so you may turn it off if you don't need it:

  conway( wechsler => 'xp2_25a4owo4a52zy01221', pad => 0 )

If you have L<Color::Spectrum> installed then you can activate a fading effect like so:

  conway( on => '#FF0000', off => '#999999', fade => 1 )

  # color names via Color::Library
  conway( on => 'red', off => 'gray', fade => 1 )

You can also load a file and pre-populate a game grid if you know which
color will be used as C<alpha>. This example uses #F8F8F8 and tweaks the block
size up to 16:

  conway( file => 'conway.png', alpha => '#f8f8f8', block => 16 )

The C<alpha> param is available whenever you supply an image file.

Uses Google's jQuery API unless you specify another URI via
the C<jquery> param. Javascript will be minified
via L<Javascript::Minifier> if it is installed.

=back

=head1 SEE ALSO

=over 4

=item L<Spreadsheet::HTML>

The interface for this functionality.

=item L<Spreadsheet::HTML::Presets>

More presets.

=item L<Encode::Wechsler>

Wechsler encoder/decoder for Conway's Game of Life boards.

=item L<Color::Spectrum>

Generates spectrums of HTML color strings.

=item L<Color::Library>

Comprehensive named color dictionary.

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
