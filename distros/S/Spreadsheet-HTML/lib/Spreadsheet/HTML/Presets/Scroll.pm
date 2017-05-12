package Spreadsheet::HTML::Presets::Scroll;
use strict;
use warnings FATAL => 'all';

sub scroll {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );

    $args->{fgdirection} ||= ($args->{bgdirection} || $args->{bx} || $args->{by}) ? '' : 'right';
    $args->{bgdirection} ||= '';
    $args->{interval}    ||= 200;

    my @cells;
    for my $r ( 0 .. $args->{_max_rows} - 1 ) {
        for my $c ( 0 .. $args->{_max_cols} - 1 ) {
            my $cell = sprintf '-r%sc%s', $r, $c;
            push @cells, $cell => {
                id     => join( '-', $r, $c ),
                class  => 'scroll',
            };
        }
    }

    my @args = (
        caption  => { '<button id="toggle" onClick="toggle()">Start</button>' => { align => 'bottom' } },
        @_,
        @cells,
    );

    my $js = _javascript( %$args );
    return( $js, @args ) if $args->{scroll};

    my $table = $self ? $self->generate( @args ) : Spreadsheet::HTML::generate( @args );
    return $js . $table;
}

sub _javascript {
    my %args = @_;

    my %fmap = (
        right => { fx =>  1, fy => 0 },
        left  => { fx => -1, fy => 0 },
        up    => { fy =>  1, fx => 0 },
        down  => { fy => -1, fx => 0 },
    );

    my %bmap = (
        right => { bx =>  1, by => 0 },
        left  => { bx => -1, by => 0 },
        up    => { by =>  1, bx => 0 },
        down  => { by => -1, bx => 0 },
    );

    $args{fx} = (defined $args{fx} or defined $args{fy}) ? $args{fx} : $fmap{ $args{fgdirection} }{fx};
    $args{fy} ||= $fmap{ $args{fgdirection} }{fy};
    $args{bx} ||= $bmap{ $args{bgdirection} }{bx};
    $args{by} ||= $bmap{ $args{bgdirection} }{by};

    my $js = sprintf _js_tmpl(),
        $args{_max_rows},
        $args{_max_cols},
        $args{fx} || 0,
        $args{fy} || 0,
        $args{bx} || 0,
        $args{by} || 0,
        $args{interval},
    ;

    return Spreadsheet::HTML::Presets::_js_wrapper( code => $js, %args );
}

sub _js_tmpl {
    return <<'END_JAVASCRIPT';

/* Copyright 2017 Jeff Anderson */
/* install JavaScript::Minifier to minify this code */
var ROW = %s;
var COL = %s;
var FGX = %s;
var FGY = %s;
var BGX = %s;
var BGY = %s;
var INTERVAL = %s;
var tid;

function toggle() {
    if ($('#toggle').html() === 'Start') {
        tid = setInterval( move, INTERVAL );
        $('#toggle').html( 'Stop' );
    } else {
        clearInterval( tid );
        $('#toggle').html( 'Start' );
    }
}

function move() {

    if (FGX) {
        for (var row = 0; row < ROW; row++) {
            var vals = new Array(); 
            for (var col = 0; col < COL; col++) {
                vals.push( $('#' + row + '-' + col ).clone() );
            }

            if (FGX > 0) {
                vals.unshift( vals.pop() );
            } else {
                vals.push( vals.shift() );
            }

            for (var col = 0; col < COL; col++) {
                $('#' + row + '-' + col ).html( vals[col].html() );
            }
        }
    }

    if (FGY) {
        for (var col = 0; col < COL; col++) {
            var vals = new Array(); 
            for (var row = 0; row < ROW; row++) {
                vals.push( $('#' + row + '-' + col ).clone() );
            }

            if (FGY > 0) {
                vals.push( vals.shift() );
            } else {
                vals.unshift( vals.pop() );
            }

            for (var row = 0; row < ROW; row++) {
                $('#' + row + '-' + col ).html( vals[row].html() );
            }
        }
    }

    if (BGX) {
        for (var row = 0; row < ROW; row++) {
            var vals = new Array(); 
            for (var col = 0; col < COL; col++) {
                vals.push( $('#' + row + '-' + col ).clone() );
            }

            if (BGX > 0) {
                vals.unshift( vals.pop() );
            } else {
                vals.push( vals.shift() );
            }

            for (var col = 0; col < COL; col++) {
                $('#' + row + '-' + col ).attr( 'style', vals[col].attr( 'style' ) );
            }
        }
    }

    if (BGY) {
        for (var col = 0; col < COL; col++) {
            var vals = new Array(); 
            for (var row = 0; row < ROW; row++) {
                vals.push( $('#' + row + '-' + col ).clone() );
            }

            if (BGY > 0) {
                vals.push( vals.shift() );
            } else {
                vals.unshift( vals.pop() );
            }

            for (var row = 0; row < ROW; row++) {
                $('#' + row + '-' + col ).attr( 'style', vals[row].attr( 'style' ) );
            }
        }
    }
}
END_JAVASCRIPT
}

=head1 NAME

Spreadsheet::HTML::Presets::Scroll - Generate scrolling HTML table cells and backgrounds.

=head1 DESCRIPTION

This is a container for L<Spreadsheet::HTML> preset methods.
These methods are not meant to be called from this package.
Instead, use the Spreadsheet::HTML interface:

  use Spreadsheet::HTML;
  my $generator = Spreadsheet::HTML->new( data => \@data );
  print $generator->scroll;

  # or
  use Spreadsheet::HTML qw( scroll );
  print scroll( data => \@data );

=head1 METHODS

=over 4

=item * C<scroll( fgdirection, bgdirection, interval, jquery, %params )>

Moves the contents (C<fgdirection> for CDATA, C<bgdirection>
for attributes) of each cell in the direction specified.
Valid values are C<up>, C<down>, C<left> and C<right>, or
you can optionally use C<fx> and/or C<fy> instead of C<fgdirection>
to specify which axis(es) to scroll, as well as C<bx> and
C<by> instead of C<bgdirection>.

  scroll( fgdirection => 'left' )

  # same as
  scroll( fx => -1 )

  # produce diagonal (left and up)
  scroll( fx => -1, fy => -1 )

Set the timer with C<interval> (defaults to 200 miliseconds).

  scroll( fgdirection => 'right', interval => 500 )

Uses Google's jQuery API unless you specify another URI via
the C<jquery> param. Javascript will be minified via
L<Javascript::Minifier> if it is installed.

Virtually all other Spreadsheet::HTML generating methods/procedures
also can additionally specify C<scroll> et. al. as a literal parameters:

  print $generator->landscape( scroll => 1, by => -1, bx => 1 )

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
