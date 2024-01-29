package Spreadsheet::HTML::Presets::Calculator;
use strict;
use warnings FATAL => 'all';

sub calculator {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );

    $data = [
        [ 'C', '&plusmn;', '&divide;', '&times;' ],
        [ 7, 8, 9, '&minus;' ],
        [ 4, 5, 6, '+' ],
        [ 1, 2, 3, '=' ],
        [ 0, '.' ],
    ];

    my %attrs = (
        height => 65,
        width  => 65,
        align  => 'center',
        %{ $args->{td} || {} },
        style  => { 
            'font-size' => 'xx-large',
            padding => 0,
            margins => 0,
            %{ $args->{td}{style} || {} },
        },
    );

    my $attrs = 'font-size: xx-large; font-weight: bold; font-family: monospace;';

    my @args = (
        @_,
        table => {
            width => '20%',
            %{ $args->{table} || {} },
            style => {
                border  => 'thick outset',
                padding => 0,
                margins => 0,
                %{ $args->{table}{style} || {} },
            },
        },
        caption     => qq(<input id="display" style="background-color: #F1FACA; height: 8%; width: 80%; text-align: right; $attrs" />),
        td          => [ { %attrs }, sub { qq(<button style="width: 100%; height: 100%; $attrs">$_[0]</button>) } ],
        -r3c3       => { rowspan => 2, %attrs },
        -r4c0       => { colspan => 2, %attrs },
        _layout     => 1,
        data        => $data,
        theta       => 0,
        flip        => 0,
        tgroups     => 0,
        headless    => 0,
        pinhead     => 0,
        wrap        => 0,
        matrix      => 1,
    );

    my $js = _javascript( %$args );
    my $table = $self ? $self->generate( @args ) : Spreadsheet::HTML::generate( @args );
    return $js . $table;
}

sub _javascript {
    return Spreadsheet::HTML::Presets::_js_wrapper( code => _js_tmpl(), @_ );
}

sub _js_tmpl {
    return <<'END_JAVASCRIPT';

/* Copyright 2024 Jeff Anderson */
/* install JavaScript::Minifier to minify this code */

var DISPLAY = [ 0 ];
var OPERAND = '';

$(document).ready(function(){

    $('#display').prop( 'readonly', 'readonly' );

    $('button').click( function( data ) {

        var html = $(this).html();
        var val  = $('<div/>').html(html).text();

        if (val === '.' && ( DISPLAY[0] === 0 || DISPLAY[0].indexOf('.') === -1 )) {

            DISPLAY[0] += val;

        } else if (+val === parseInt( val )) {

            if (DISPLAY[0] === "0.") {
                DISPLAY[0] += val;
            } else if (DISPLAY[0] == 0) {
                DISPLAY[0] = val;
            } else {
                DISPLAY[0] += val;
            }

        } else if (val === '+') {

            if (OPERAND) {
                var value = eval( DISPLAY[1] + OPERAND + DISPLAY[0] );
                DISPLAY = [ value ];
            }

            update();
            OPERAND = val;
            DISPLAY.unshift( '' );
            return;

        } else if (val.charCodeAt(0) == 8722) {

            if (OPERAND) {
                var value = eval( DISPLAY[1] + OPERAND + DISPLAY[0] );
                DISPLAY = [ value ];
            }

            update();
            OPERAND = '-';
            DISPLAY.unshift( '' );
            return;

        } else if (val.charCodeAt(0) == 215) {

            if (OPERAND) {
                var value = eval( DISPLAY[1] + OPERAND + DISPLAY[0] );
                DISPLAY = [ value ];
            }

            update();
            OPERAND = '*';
            DISPLAY.unshift( '' );
            return;

        } else if (val.charCodeAt(0) == 247) {

            if (OPERAND) {
                var value = eval( DISPLAY[1] + OPERAND + DISPLAY[0] );
                DISPLAY = [ value ];
            }

            update();
            OPERAND = '/';
            DISPLAY.unshift( '' );
            return;

        } else if (val.charCodeAt(0) == 177) {

            DISPLAY[0] *= -1;

        } else if (val === '=') {

            var value = eval( DISPLAY[1] + OPERAND + DISPLAY[0] );
            OPERAND = '';
            DISPLAY = [ value ];
            update();
            DISPLAY = [ 0 ];
            return;

        } else if (val === 'C') {

            DISPLAY = [ 0 ];
        }

        update();
    });

    update();
});

function update() { $('#display').val( DISPLAY[0] ) }

END_JAVASCRIPT
}

=head1 NAME

Spreadsheet::HTML::Presets::Calculator - Generate HTML table basic calculator.

=head1 DESCRIPTION

This is a container for L<Spreadsheet::HTML> preset methods.
These methods are not meant to be called from this package.
Instead, use the Spreadsheet::HTML interface:

  use Spreadsheet::HTML;
  my $generator = Spreadsheet::HTML->new;
  print $generator->calculator;

  # or
  use Spreadsheet::HTML qw( calculator );
  print calculator();

=head1 METHODS

=over 4

=item * C<calculator( jquery, %params )>

Generates a simple calculator.

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
