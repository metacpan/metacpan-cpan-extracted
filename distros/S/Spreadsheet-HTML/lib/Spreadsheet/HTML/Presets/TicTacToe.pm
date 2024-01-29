package Spreadsheet::HTML::Presets::TicTacToe;
use strict;
use warnings FATAL => 'all';

sub tictactoe {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );

    my @args = (
        @_,
        table => { 
            %{ $args->{table} || {} },
            id => 'tictactoe', 
            style => {
                'font-family' => 'cursive, sans-serif',
                'font-size'   => 'xx-large',
                %{ $args->{table}{style} || {} },
            },
        },
        td => {
            %{ $args->{td} || {} },
            height => 100,
            width  => 100,
            align  => 'center',
        },
        -r1      => { style => 'border-top:1px  solid black; border-bottom:1px solid black;' },
        -r0c1    => { style => 'border-left:1px solid black; border-right:1px  solid black;' },
        -r1c1    => { style => 'border-left:1px solid black; border-right:1px  solid black; border-top:1px solid black; border-bottom:1px solid black;' },
        -r2c1    => { style => 'border-left:1px solid black; border-right:1px  solid black;' },
        tgroups  => 0,
        headless => 0,
        pinhead  => 0,
        matrix   => 1,
        wrap     => 0,
        data     => [],
        fill     => '3x3',
    );

    my $js    = _javascript( %$args );
    my $table = $self ? $self->generate( @args ) : Spreadsheet::HTML::generate( @args );
    return $js . $table;
}


sub _javascript {
    my %args = @_;
    $args{copyright} = 'Copyright 2024 Ray Toal http://jsfiddle.net/rtoal/5wKfF/';
    return Spreadsheet::HTML::Presets::_js_wrapper( code => _js_tmpl(), %args );
}

sub _js_tmpl {
    return <<'END_JAVASCRIPT';

/* install JavaScript::Minifier to minify this code */
/* Copyright 2024 Ray Toal */
/* http://jsfiddle.net/rtoal/5wKfF/ */

(function () {

    var squares = [], 
        EMPTY = "\xA0",
        score,
        moves,
        turn = "X",

    /*
     * To determine a win condition, each square is "tagged" from left
     * to right, top to bottom, with successive powers of 2.  Each cell
     * thus represents an individual bit in a 9-bit string, and a
     * player's squares at any given time can be represented as a
     * unique 9-bit value. A winner can thus be easily determined by
     * checking whether the player's current 9 bits have covered any
     * of the eight "three-in-a-row" combinations.
     *
     *     273                 84
     *        \               /
     *          1 |   2 |   4  = 7
     *       -----+-----+-----
     *          8 |  16 |  32  = 56
     *       -----+-----+-----
     *         64 | 128 | 256  = 448
     *       =================
     *         73   146   292
     *
     */
    wins = [7, 56, 448, 73, 146, 292, 273, 84],

    startNewGame = function () {
        var i;
        
        turn = "X";
        score = {"X": 0, "O": 0};
        moves = 0;
        for (i = 0; i < squares.length; i += 1) {
            squares[i].firstChild.nodeValue = EMPTY;
        }
    },

    win = function (score) {
        var i;
        for (i = 0; i < wins.length; i += 1) {
            if ((wins[i] & score) === wins[i]) {
                return true;
            }
        }
        return false;
    },

    set = function () {
        if (this.firstChild.nodeValue !== EMPTY) {
            return;
        }
        this.firstChild.nodeValue = turn;
        moves += 1;
        score[turn] += this.indicator;
        if (win(score[turn])) {
            alert(turn + " wins!");
            startNewGame();
        } else if (moves === 9) {
            alert("Draw!");
            startNewGame();
        } else {
            turn = turn === "X" ? "O" : "X";
        }
    },

    play = function () {
        var indicator = 1;
        $('#tictactoe tr').each( function () {
            var row = new Array;
            $.each( this.cells, function () {
                this.indicator = indicator;
                this.onclick = set;
                squares.push( this );
                indicator += indicator;
            });
        });

        startNewGame();
    };

    if (typeof window.onload === "function") {
        oldOnLoad = window.onload;
        window.onload = function () {
            oldOnLoad(); 
            play();
        };
    } else {
        window.onload = play;
    }

}());
END_JAVASCRIPT
}

=head1 NAME

Spreadsheet::HTML::Presets::TicTacToe - TicTacToe board implemented with Javascript and HTML tables.

=head1 DESCRIPTION

This is a container for L<Spreadsheet::HTML> preset methods.
These methods are not meant to be called from this package.
Instead, use the Spreadsheet::HTML interface:

  use Spreadsheet::HTML;
  my $generator = Spreadsheet::HTML->new;
  print $generator->tictactoe;

  # or
  use Spreadsheet::HTML qw( tictactoe );
  print tictactoe();

=head1 METHODS

=over 4

=item * C<tictactoe( jquery, %params )>

Generates a tictactoe game board implemented with an HTML table
and Javascript. Intended for two human players but plan to 
implement a computer opponent.

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

Copyright 2024 Ray Toal (Javascript) and Jeff Anderson (Perl).

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
