package Spreadsheet::HTML::Presets::Draughts;
use strict;
use warnings FATAL => 'all';

sub draughts {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );

    my $on  = $args->{on}  || 'red';
    my $off = $args->{off} || 'white';

    $args->{size} = 8;
    my $id   = 1;
    my (@data, @cells);
    for my $r (0 .. $args->{size} - 1) {
        for my $c (0 .. $args->{size} - 1) {
            my $cell = sprintf '-r%sc%s', $r, $c;
            if ($r % 2 xor $c % 2) {
                push @cells, $cell => { id => $id++, class => 'cell on' };
                push @data, ($r == 3 || $r == 4) ? '' : '&#9814';
            } else {
                push @cells, $cell => { class => 'cell off' };
                push @data, '';
            }
        }
    }

    my @args = (
        @_,
        table => { id => 'checkers', %{ $args->{table} || {} }, },
        #td => [ { %{ $args->{td} || {} } }, sub { $_[0] ? qq(<div class="game-piece">$_[0]</div>) : '' } ],
        @cells,
        tgroups  => 0,
        headless => 0,
        pinhead  => 0,
        matrix   => 1,
        wrap     => $args->{size},
        data     => \@data,
    );

    my $js    = Spreadsheet::HTML::Presets::Draughts::_javascript( %$args );
    my $css   = Spreadsheet::HTML::Presets::Draughts::_css_tmpl();
    my $table = $self ? $self->generate( @args ) : Spreadsheet::HTML::generate( @args );
    return $js . $css . $table;
}

sub _javascript {
    my %args = @_;

    my $js = sprintf _js_tmpl(),
        $args{size},
    ;

    #$args{jqueryui} = 'http://ajax.googleapis.com/ajax/libs/jqueryui/1.11.4/jquery-ui.min.js';

    return Spreadsheet::HTML::Presets::_js_wrapper( code => $js, %args );
}

sub _js_tmpl {
    return <<'END_JAVASCRIPT';

/* Copyright 2024 Jeff Anderson */
/* install JavaScript::Minifier to minify this code */
var MATRIX;
var SELECTED;
var SIZE = %s;

$(document).ready(function(){

    //$(function() { $( '.game-piece' ).draggable() });

    $('td.on').click( function( data ) {
        if (this.className == 'cell on' && SELECTED) {
            $('#'+SELECTED).removeClass( 'curr' );
            $('#'+SELECTED).addClass( 'on' );
            this.innerHTML = $('#'+SELECTED).html();
            $('#'+SELECTED).html('&nbsp;');
            SELECTED = 0;
        } else if (this.className == 'cell on') {
            this.className = 'cell curr';
            SELECTED = this.id;
        } else {
            this.className = 'cell on';
            SELECTED = 0;
        }
    });

});

END_JAVASCRIPT
}

sub _css_tmpl {
    return <<'END_CSS';
<style type="text/css">
.cell { height: 64px; width: 64px; text-align: center; border: thin inset; }
.off  { background-color: white; }
.on   { background-color: red; font-size: x-large;  }
.curr { background-color: green; font-size: xx-large; }
.p1   { color: cyan; position: relative; }
.p2   { color: yellow; position: relative; }
#checkers { border: thick outset; }
</style>
END_CSS
}

=head1 NAME

Spreadsheet::HTML::Presets::Draughts - Draughts/checkers board implemented with Javascript and an HTML table.

=head1 DESCRIPTION

This is a container for L<Spreadsheet::HTML> preset methods.
These methods are not meant to be called from this package.
Instead, use the Spreadsheet::HTML interface:

  use Spreadsheet::HTML;
  my $generator = Spreadsheet::HTML->new;
  print $generator->checkers;
  print $generator->draughts;

  # or
  use Spreadsheet::HTML qw( draughts );
  print draughts();

  # or
  use Spreadsheet::HTML qw( checkers );
  print checkers();

=head1 METHODS

=over 4

=item * C<draughts( on, off, jquery, jqueryui, %params )>

Generates a draughts game board. Currently you can only
move the pieces around without regard to any rules.

  print draughts( %params );

  # checkers is an alias for draughts
  checkers( %params );

Defaults to red and white squares which can be overriden
with C<on> and C<off>, respectively:

  checkers( on => 'blue', off => 'gray' ) 

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
