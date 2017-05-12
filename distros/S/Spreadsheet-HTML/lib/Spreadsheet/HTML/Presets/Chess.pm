package Spreadsheet::HTML::Presets::Chess;
use strict;
use warnings FATAL => 'all';

sub chess {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );

    my @data = (
        [ '&#9820;', '&#9822;', '&#9821;', '&#9819;', '&#9818;', '&#9821;', '&#9822;', '&#9820;' ],
        [ '&#9823;', '&#9823;', '&#9823;', '&#9823;', '&#9823;', '&#9823;', '&#9823;', '&#9823;' ],
        [ ('') x 8 ], [ ('') x 8 ], [ ('') x 8 ], [ ('') x 8 ],
        [ '&#9817;', '&#9817;', '&#9817;', '&#9817;', '&#9817;', '&#9817;', '&#9817;', '&#9817;' ],
        [ '&#9814;', '&#9816;', '&#9815;', '&#9813;', '&#9812;', '&#9815;', '&#9816;', '&#9814;' ],
    );

    my $on  = $args->{on}  || '#aaaaaa';
    my $off = $args->{off} || 'white';

    my @args = (
        table => {
            width => '65%',
            style => {
                border => 'thick outset',
                %{ $args->{table}{style} || {} },
            },
            %{ $args->{table} || {} },
        },
        @_,
        td => [
            {
                height => 65,
                width  => 65,
                align  => 'center',
                style  => { 
                    'font-size' => 'xx-large',
                    border => 'thin inset',
                    'background-color'  => [ ($off, $on)x4, ($on, $off)x4 ],
                    %{ $args->{td}{style} || {} },
                },
                %{ $args->{td} || {} },
            }, sub { $_[0] ? qq(<div class="game-piece">$_[0]</div>) : '' }
        ],
        tgroups  => 0,
        headless => 0,
        pinhead  => 0,
        matrix   => 1,
        wrap     => 0,
        fill     => '8x8',
        data     => \@data,
    );

    my $js    = Spreadsheet::HTML::Presets::Chess::_javascript( %$args );
    my $table = $self ? $self->generate( @args ) : Spreadsheet::HTML::generate( @args );
    return $js . $table;
}

sub _javascript {
    my %args = @_;

    my $js = sprintf _js_tmpl(),
    ;

    $args{jqueryui} = 'http://ajax.googleapis.com/ajax/libs/jqueryui/1.11.4/jquery-ui.min.js';

    return Spreadsheet::HTML::Presets::_js_wrapper( code => $js, %args );
}

sub _js_tmpl {
    return <<'END_JAVASCRIPT';

/* Copyright 2017 Jeff Anderson */
/* install JavaScript::Minifier to minify this code */

$(document).ready(function(){

    $(function() {
        $( '.game-piece' ).draggable();
    });

});

END_JAVASCRIPT
}

=head1 NAME

Spreadsheet::HTML::Presets::Chess - Chess/checkers boards implemented with Javascript and HTML tables.

=head1 DESCRIPTION

This is a container for L<Spreadsheet::HTML> preset methods.
These methods are not meant to be called from this package.
Instead, use the Spreadsheet::HTML interface:

  use Spreadsheet::HTML;
  my $generator = Spreadsheet::HTML->new;
  print $generator->chess;

  # or
  use Spreadsheet::HTML qw( chess );
  print chess();

=head1 METHODS

=over 4

=item * C<chess( on, off, jquery, jqueryui, %params )>

Generates a chess game board. Currently you can only
move the pieces around without regard to any rules.

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
