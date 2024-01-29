package Spreadsheet::HTML::Presets;
use strict;
use warnings FATAL => 'all';

use Spreadsheet::HTML;
use Spreadsheet::HTML::Presets::List;
use Spreadsheet::HTML::Presets::Scroll;
use Spreadsheet::HTML::Presets::Beadwork;
use Spreadsheet::HTML::Presets::Calculator;
use Spreadsheet::HTML::Presets::Conway;
use Spreadsheet::HTML::Presets::Chess;
use Spreadsheet::HTML::Presets::Draughts;
use Spreadsheet::HTML::Presets::TicTacToe;
use Spreadsheet::HTML::Presets::Handson;
use Spreadsheet::HTML::Presets::Sudoku;

eval "use JavaScript::Minifier";
our $NO_MINIFY = $@;
eval "use Text::FIGlet";
our $NO_FIGLET = $@;
eval "use Time::Piece";
our $NO_TIMEPIECE = $@;
eval "use List::Util";
our $NO_LISTUTIL = $@;

sub layout {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );

    my @args = (
        @_,
        table   => {
            %{ $args->{table} || {} },
            role => 'presentation',
            ( map {$_ => 0} qw( border cellspacing cellpadding ) ),
        },
        encodes => '',
        matrix  => 1,
        _layout => 1,
    );

    $self ? $self->generate( @args ) : Spreadsheet::HTML::generate( @args );
}

sub checkerboard {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );

    my $colors = $args->{colors} ? $args->{colors} : $args->{class} ? $args->{class} : [qw(red green)];
    $colors = [ $colors ] unless ref $colors;

    my @rows;
    for my $row (0 .. $args->{_max_rows} - 1) {
        my $attr = $args->{class} ? { class => [@$colors] } : { style => { 'background-color' => [@$colors] } };
        push @rows, ( "-r$row" => $attr );
        Tie::Hash::Attribute::_rotate( $colors );
    }

    my @args = (
        @_,
        wrap => 0,
        @rows,
    );

    $self ? $self->generate( @args ) : Spreadsheet::HTML::generate( @args );
}

sub banner {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );

    my @cells = ();
    unless ($NO_FIGLET) {

        my @banner;
        eval {
            @banner = Text::FIGlet
                ->new( -d => $args->{dir}, -f => $args->{emboss} ? 'block' : 'banner' )
                ->figify( -A => uc( $args->{text} || '' ), -w => 9999 );
        };
        if ($@) {
            $data = [ ['Error'], ["could not create banner: $@"] ];
        }

        if (@banner) {
            push @cells, ( fill => join 'x', scalar( @banner ), length( $banner[0] ) );
            my $on  = $args->{on}  || 'black';
            my $off = $args->{off} || 'white';

            for my $row (0 .. $#banner) {
                my @line = split //, $banner[$row];
                for my $col (0 .. $#line) {
                    my $key = sprintf '-r%sc%s', $row, $col;
                    if ($args->{emboss}) {
                        if ($line[$col] eq ' ') {
                            push @cells, ( $key => { style => { 'background-color' => $off } } );
                        } elsif ($line[$col] eq '_') {
                            push @cells, ( $key => { style => { 'background-color' => $off, 'border-bottom' => "1px solid $on" } } );
                        } elsif ($args->{flip}) {
                            push @cells, ( $key => { style => { 'background-color' => $off, 'border-right' => "1px solid $on" } } );
                        } else {
                            push @cells, ( $key => { style => { 'background-color' => $off, 'border-left' => "1px solid $on" } } );
                        }
                    } else {
                        my $color = $line[$col] eq ' ' ? $off : $on;
                        push @cells, ( $key => { style => { 'background-color' => $color } } );
                    }
                }
            }
        }
    }
    else {
        $data = [ ['could not create banner'], [ 'Text::FIGlet not installed' ] ];
    }

    my @args = (
        data => $data,
        @_,
        @cells,
        wrap => 0,
    );

    my $table = $self ? $self->generate( @args ) : Spreadsheet::HTML::generate( @args );
    return $table;
}

sub maze {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );

    my @cells = ();
    unless ($NO_LISTUTIL) {

        my $rows = $args->{_max_rows} == 1 ? 20 : $args->{_max_rows};
        my $cols = $args->{_max_cols} == 1 ? 16 : $args->{_max_cols};
        my $off  = $args->{off}    || 'white';
        my $on   = $args->{on}     || 'black';

        push @cells, ( fill => "${rows}x${cols}" );

        my (@grid,@stack);
        for my $h (0 .. $rows - 1) {
            $grid[$h] = [ map {
                x     => $_, y => $h,
                walls => [1,1,1,1], # W S E N
            }, 0 .. $cols - 1 ];
        }

        my %neighbor = ( 0 => 2, 1 => 3, 2 => 0, 3 => 1 );
        my $visited = 1;
        my $curr = $grid[rand $rows][rand $cols];
        while ($visited < $rows * $cols) {
            my @neighbors;
            for (
                [ 3, $grid[ $curr->{y} - 1 ][ $curr->{x} ] ], # north
                [ 2, $grid[ $curr->{y} ][ $curr->{x} + 1 ] ], # east
                [ 1, $grid[ $curr->{y} + 1 ][ $curr->{x} ] ], # south
                [ 0, $grid[ $curr->{y} ][ $curr->{x} - 1 ] ], # west
            ) { no warnings; push @neighbors, $_ if List::Util::sum( @{ $_->[1]->{walls} } ) == 4 }

            if (@neighbors) {
                my ($pos,$cell) = @{ $neighbors[rand @neighbors] };
                $curr->{walls}[$pos] = 0;
                $cell->{walls}[$neighbor{$pos}] = 0;
                push @stack, $curr;
                $curr = $cell;
                $visited++;
            } else {
                $curr = pop @stack;
            }
            @neighbors = ();
        }

        my %style_map = (
           0 => 'border-left', 
           1 => 'border-bottom', 
           2 => 'border-right', 
           3 => 'border-top', 
        );

        for my $row (0 .. $#grid) {
            for my $col (0 .. @{ $grid[$row] }) {
                my $key = sprintf '-r%sc%s', $row, $col;
                my %style = ( 'background-color' => $off );
                for (0 .. $#{ $grid[$row][$col]{walls} } ) {
                    $style{$style_map{$_}} = "2px solid $on" if $grid[$row][$col]{walls}[$_]; 
                } 
                push @cells, ( $key => { height => '20px', width => '20px', style => {%style} } );
            }
        }
    }

    my @args = (
        @_,
        @cells,
        matrix   => 1,
        tgroups  => 0,
        flip     => 0,
        theta    => 0,
        headless => 0,
    );

    my $table = $self ? $self->generate( @args ) : Spreadsheet::HTML::generate( @args );
    return $table;
}

sub calendar {
    my ($self,$data,$args);
    $self = shift if ref($_[0]) =~ /^Spreadsheet::HTML/;
    ($self,$data,$args) = $self ? $self->_args( @_ ) : Spreadsheet::HTML::_args( @_ );

    my @cal_args;
    unless ($NO_TIMEPIECE) {
        my $time = Time::Piece->strptime(
            join( '-', 
                $args->{month} || (localtime)[4]+1,
                $args->{year}  || (localtime)[5]+1900,
            ), '%m-%Y'
        );
        my $first = $time->wday;
        my $last  = $time->month_last_day;
        my @flat  = ( 
            (map Time::Piece->strptime($_,"%d")->day, 4 .. 10),
            ('') x ($first - 1),
            1 .. $last
        );
        
        push @cal_args, ( data => \@flat );

        my $mday = '-' . Time::Piece->new->mday;
        $args->{$mday} = exists $args->{$mday} ? $args->{$mday} : $args->{today};
        my %day_args = map {($_ => $args->{$_})} grep /^-\d+$/, keys %$args;
        for (keys %day_args) {
            my $day = abs($_);
            next if $day > $last;
            my $index = $day + $first + 5;
            my $row = int($index / 7);
            my $col = $index % 7;
            push @cal_args, ( sprintf( '-r%sc%s', $row, $col ) => $day_args{$_} );
        }

        my $caption = join( ' ', $time->fullmonth, $time->year );
        if ($args->{scroll}) {
            $caption = qq{<p>$caption</p><button id="toggle" onClick="toggle()">Start</button>};
        }

        my $attr = { style => { 'font-weight' => 'bold' } };
        if ($args->{caption} and ref $args->{caption} eq 'HASH') {
            ($attr) = values %{ $args->{caption} };
        }

        push @cal_args, ( caption => { $caption => $attr } );
    }

    my @args = (
        @cal_args,
        @_,
        td => { %{ $args->{td} || {} }, style  => { %{ $args->{td}{style} || {} }, 'text-align' => 'right' } },
        wrap    => 7,
        theta   => 0,
        flip    => 0,
        matrix  => 0,
    );        

    return $self ? $self->generate( @args ) : Spreadsheet::HTML::generate( @args );
}

sub _js_wrapper {
    my %args = @_;

    unless ($NO_MINIFY) {
        $args{code} = JavaScript::Minifier::minify(
            input      => $args{code},
            copyright  => $args{copyright} || 'Copyright 2024 Jeff Anderson',
            stripDebug => 1,
        );
    }

    my $js = $args{_auto}->tag( tag => 'script', cdata => $args{code}, attr => { type => 'text/javascript' } );
    return $js if $args{bare};

    $args{jquery} ||= 'https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js';

    my $html = $args{_auto}->tag( tag => 'script', cdata => '',    attr => { src => $args{jquery} } );
    $html   .= $args{_auto}->tag( tag => 'script', cdata => '',    attr => { src => $args{jqueryui} } ) if $args{jqueryui};
    $html   .= $args{_auto}->tag( tag => 'script', cdata => '',    attr => { src => $args{handsonjs} } ) if $args{handsonjs};
    $html   .= $args{_auto}->tag( tag => 'link', attr => { rel => 'stylesheet', media => 'screen', href => $args{css} } ) if $args{css};

    return $html . $js;
}

=head1 NAME

Spreadsheet::HTML::Presets - Generate preset HTML tables.

=head1 DESCRIPTION

This is a container for L<Spreadsheet::HTML> preset methods.
These methods are not meant to be called from this package.
Instead, use the Spreadsheet::HTML interface:

  use Spreadsheet::HTML;
  my $generator = Spreadsheet::HTML->new( data => \@data );
  print $generator->layout;

  # or
  use Spreadsheet::HTML qw( layout );
  print layout( data => \@data );

=head1 METHODS

=over 4

=item * C<layout( %params )>

Layout tables are not recommended, but if you choose to
use them you should label them as such. This adds W3C
recommended layout attributes to the table tag and features:
emit only <td> tags, no padding or pruning of rows, forces
no HTML entity encoding in table cells.

=item * C<checkerboard( colors, %params )>

Preset for tables with checkerboard colors.

  checkerboard( colors => [qw(yellow orange blue)] )

Forms diagonal patterns by alternating the starting background
colors for each row. C<colors> defaults to red and green.

  checkerboard( class => [qw(foo bar baz)] )

Same thing but alternate class names (for external CSS).

=item * C<banner( dir, text, emboss, on, off, fill, %params )>

Will generate and display a banner using the given C<text> in the
'banner' font. Set C<emboss> to a true value and the font 'block'
will be emulated by highlighting the left and bottom borders of the cell.
Set the foreground color with C<on> and the background with C<off>.
You Must have L<Text::FIGlet> installed AND configured in order to use
this preset. If Text::FIGlet cannot find the fonts directory then it
will silently fail and produce no banner.

  banner( dir => '/path/to/figlet/fonts', text => 'HI', on => 'red' )

=item * C<calendar( month, year, today, %params )>

Generates a static calendar. Defaults to current month and year.

  calendar( month => 7, year => 2012 )

Mark a day of the month like so:

  calendar( month => 12, -25 => { bgcolor => 'red' } )

Or mark today, whenever it is:

  calendar( today => { bgcolor => 'red' } )

Default rules still apply to styling columns by any heading:

  calendar( -Tue => { class => 'ruby' } )

=item * C<maze( on, off, fill, %params )>

Generates a static maze.

  maze( fill => '10x10', on => 'red', off => 'black' ) 

=back

=head1 MORE PRESETS

=over 4

=item * L<Spreadsheet::HTML::Presets::List>

Generate <select>, <ol> and <ul> lists.

=item * L<Spreadsheet::HTML::Presets::Scroll>

Provides the scroll param.

=item * L<Spreadsheet::HTML::Presets::Beadwork>

Turn cell backgrounds into 8-bit pixel art.

=item * L<Spreadsheet::HTML::Presets::Calculator>

A simple HTML table calculator.

=item * L<Spreadsheet::HTML::Presets::Conway>

Turn cell backgrounds into Conway's game of life.

=item * L<Spreadsheet::HTML::Presets::TicTacToe>

Creats a Tic-Tac-Toe board.

=item * L<Spreadsheet::HTML::Presets::Draughts>

AKA Checkers. Work in progress. Hope to interface with pre-existing
Javascript Chess engine someday (or write my own).

=item * L<Spreadsheet::HTML::Presets::Chess>

Work in progress. Hope to interface with a pre-existing
Javascript Chess engine someday.

=item * L<Spreadsheet::HTML::Presets::Handson>

Handsontable HTML tables. See L<http://handsontable.com>.

=item * L<Spreadsheet::HTML::Presets::Sudoku>

Generate 9x9 HTML table sudoku boards.

=back

=head1 SEE ALSO

=over 4

=item * L<Spreadsheet::HTML>

The interface for this functionality.

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
