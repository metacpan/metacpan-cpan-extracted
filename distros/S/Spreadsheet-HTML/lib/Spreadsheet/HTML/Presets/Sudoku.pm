package Spreadsheet::HTML::Presets::Sudoku;
use strict;
use warnings FATAL => 'all';

eval "use Games::Sudoku::Component";
our $NO_SUDOKU = $@;

sub sudoku {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );
    $args->{attempts}   = defined $args->{attempts} ? int($args->{attempts} || 0) : 4;
    $args->{blanks}     = int($args->{blanks} || 0) || 50;
    $args->{size}       = 9; # Games::Sudoku::Component only accepts perfect squares and only 9 is fast

    $data = [];
    my @cells;
    my ($solved,$unsolved) = ('','');
    unless ($NO_SUDOKU) {
        my $board = Games::Sudoku::Component->new( size => $args->{size} );
        while (!$board->is_solved and $args->{attempts}-- > 0) {
            $board->generate( blanks => $args->{blanks} );
            $unsolved = $board->as_string;
            $board->solve;
        }

        my %td_attr = ( style => { border => 'solid thin', 'text-align' => 'center', padding => '.5em', 'font-family' => 'Lucida Grande' } );
        my $auto = HTML::AutoTag->new;
        my %input_attr = ( class => 'sudoku', size=> 1, style => { 'text-align' => 'center', border => '0px', 'font-size' => 'medium',  color => 'red' } );

        if ($board->is_solved) {
            $solved = $board->as_string;
            my @lines = split /\n/, $unsolved;
            for my $row (0 .. $#lines) {
                my @chars = split /\s/, $lines[$row];
                for my $col (0 .. $#chars) {
                    my $id  = "${row}-${col}";
                    my $sub = $chars[$col] ? sub { $chars[$col] } : sub { $auto->tag( tag => 'input', attr => { %input_attr, id => "input-$id" } ) };
                    push @cells, ( "-r${row}c${col}" => [ { %td_attr, id => "td-$id" }, $sub ] );
                }
            }
        }
        else {
            $data = [ ['Error'], ['could not find solution'], ['please try again'] ];
        }
    }
    else {
        $data = [ ['Error'], ['Games::Sudoku::Component not installed'] ];
    }

    my $sqrt = int(sqrt( $args->{size} ));
    my @args = (
        @_,
        @cells,
        table    => { id => 'sudoku', style => { 'border-collapse' => 'collapse' } },
        tbody    => { style => { border => 'solid medium' } },
        tr       => { id => [ map "sudoku-$_", 0 .. $sqrt - 1] },
        colgroup => [ ({ style => { border => 'solid medium' } }) x $sqrt ],
        col      => [ ({}) x $sqrt ],
        data     => $data,
        fill     => sprintf( '%sx%s', ($args->{size}) x 2 ),
        wrap     => 0,
        tgroups  => 1,
        group    => $sqrt,
        matrix   => 1,
        headless => 0,
        theta    => 0,
        scroll  => 0,
    );

    my $js    = _javascript( %$args );
    my $table = $self ? $self->generate( @args ) : Spreadsheet::HTML::generate( @args );
    return $js . $table;
}

sub _javascript {
    my %args = @_;

    my $js = sprintf _js_tmpl(),
        $args{size},
        $args{size},
    ;

    return Spreadsheet::HTML::Presets::_js_wrapper( code => $js, %args );
}

sub _js_tmpl {
    return <<'END_JAVASCRIPT';

/* Copyright 2024 Jeff Anderson */
/* install JavaScript::Minifier to minify this code */

var ROW = %s;
var COL = %s;
var MATRIX;
var next_x = 0;
var next_y = 0;

var size = 9;
var div  = 3;
var ranges = make_ranges( size, div );
var zones  = make_zones( size, ranges );

$(document).ready( function() {

    MATRIX = new Array();
    for (var row = 0; row < ROW; row++) {
        var rows = new Array(); 
        for (var col = 0; col < ROW; col++) {
            var id = row + '-' + col;
            if ($('#input-' + id).attr( 'id' )) {
                rows.push( $('#input-' + id).val() );
            } else {
                rows.push( $('#td-' + id).html() );
            }
        }
        MATRIX.push( rows );
    }

    $('input.sudoku').keyup(function () { 
        this.value = this.value.replace( /[^0-9]/g, '' );

        var matches = this.id.match( /(\d+)-(\d+)/ );
        var id_r = matches[1];
        var id_c = matches[2];

        var seen_r = {};
        var seen_c = {};
        for (var i = 0; i < ROW; i++) {
            seen_r[ MATRIX[id_r][i] ] = true;
            seen_c[ MATRIX[i][id_c] ] = true;
        }

        var zone = find_zone( id_r, id_c, ranges );
        var neighbors = zones[zone];
        var seen_z = {};
        neighbors.forEach( function(z) {
            seen_z[ MATRIX[z[0]][z[1]] ] = true;
        });

        if (seen_r[this.value] || seen_c[this.value] || seen_z[this.value]) {
            this.value = '';
        }

        MATRIX[matches[1]][matches[2]] = this.value;
    });

});

function make_ranges(size, div) {
    var ranges = [];
    var i = 0;
    while (i < size) {
        var j = i;
        i += div - 1;
        ranges.push( [j,i] );
        i++;
    }

    var range_by_zone = {};
    var j = 0;
    ranges.forEach( function(x) {
        ranges.forEach( function(y) {
            range_by_zone[j++] = { x: x, y: y };
        });
    });
    return range_by_zone;
}

function make_zones(size, ranges) {
    var zones = {};
    for (var x = 0; x < size; x++) {
        for (var y = 0; y < size; y++) {
            var zone = find_zone( x, y, ranges );
            if (!zones[zone]) zones[zone] = [];
            zones[zone].push( [x,y] );
        }
    }
    return zones;
}

function find_zone(x, y, ranges) {
    for (key in ranges) {
        var zx = ranges[key]['x'];
        var zy = ranges[key]['y'];
        if (x >= zx[0] && x <= zx[1] && y >= zy[0] && y <= zy[1]) {
            return key;
        }
    }
}
END_JAVASCRIPT
}

=head1 NAME

Spreadsheet::HTML::Presets::Sudoku - Generates 9x9 sudoku boards via HTML tables.

=head1 DESCRIPTION

This is a container for L<Spreadsheet::HTML> preset methods.
These methods are not meant to be called from this package.
Instead, use the Spreadsheet::HTML interface:

  use Spreadsheet::HTML;
  my $generator = Spreadsheet::HTML->new;
  print $generator->sudoku;

  # or
  use Spreadsheet::HTML qw( sudoku );
  print sudoku();

=head1 METHODS

=over 4

=item * C<sudoku( blanks, attempts, jquery, %params )>

Generates a static unsolved 9x9 sudoku board. You must have
L<Games::Sudoku::Component> installed, which currently
has no dependencies and is very fast and reliable. You can
specify how many cells to leave unsolved with the C<blanks> param.

  sudoku( blanks => 50 ) 

Four attempts are made to find a solveable board, you can
override that default with the C<attempts> param.

  sudoku( attempts => 1 ) 

=back

=head1 SEE ALSO

=over 4

=item L<Spreadsheet::HTML>

The interface for this functionality.

=item L<Spreadsheet::HTML::Presets>

More presets.

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Jeff Anderson.

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
