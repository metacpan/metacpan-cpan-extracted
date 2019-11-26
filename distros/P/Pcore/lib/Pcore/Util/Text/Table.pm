package Pcore::Util::Text::Table;

use Pcore -const, -class;
use Pcore::Util::Text::Table::Column;
use Pcore::Util::List qw[pairs];
use Pcore::Util::Text qw[wrap];
use Pcore::Util::Scalar qw[is_plain_arrayref is_plain_hashref];

const our $GRID => {
    ascii => [
        [ q[+], q[+], q[-], q[+] ],    # top line
        [ q[|], q[|], q[|] ],          # header row
        [ q[|], q[|], q[=], q[+] ],    # header row separator line
        [ q[|], q[|], q[|] ],          # data row
        [ q[|], q[|], q[-], q[+] ],    # data rows separator line
        [ q[+], q[+], q[-], q[+] ],    # bottom line
    ],
    utf8 => [
        [ q[┌], q[┐], q[─], q[┬] ],    # top line
        [ q[│], q[│], q[│] ],          # header row
        [ q[╞], q[╡], q[═], q[╪] ],    # header row separator line
        [ q[│], q[│], q[│] ],          # data row
        [ q[├], q[┤], q[─], q[┼] ],    # data rows separator line
        [ q[└], q[┘], q[─], q[┴] ],    # bottom line line\d
    ],
};

const our $STYLE => {
    full => {
        grid         => 'ascii',
        header       => 1,
        top_line     => 1,
        header_line  => 1,
        row_line     => 1,
        bottom_line  => 1,
        left_border  => 1,
        right_border => 1,
    },
    compact => {
        grid         => 'ascii',
        header       => 1,
        top_line     => 1,
        header_line  => 1,
        row_line     => 0,
        bottom_line  => 1,
        left_border  => 1,
        right_border => 1,
    },
    compact_mini => {
        grid         => 'ascii',
        header       => 1,
        top_line     => 0,
        header_line  => 1,
        row_line     => 0,
        bottom_line  => 1,
        left_border  => 0,
        right_border => 0,
    },
};

has cols => ( required => 1 );    # ArrayRef [ InstanceOf ['Pcore::Util::Text::Table::Column'] ]

has style => ();                  # Maybe [ Enum [ keys $STYLE->%* ] ]

has grid   => ('ascii');          # Maybe [ Enum [ keys $GRID->%* ] ]
has header => (1);                # render header

has top_line     => (1);          # Bool
has header_line  => (1);          # Bool
has row_line     => (1);          # Bool
has bottom_line  => (1);          # Bool
has left_border  => (1);          # Bool
has right_border => (1);          # Bool

has color   => (1);               # Bool
has width   => ();                # Maybe [PositiveInt]
has padding => (1);               # PositiveOrZeroInt

has _first_row => ( 1, init_arg => undef );    # Bool

sub BUILDARGS ( $self, $args ) {
    my $cols = [];

    my $idx = 0;

    # create cols objects
    for my $col ( pairs $args->{cols}->@* ) {
        push $cols->@*, Pcore::Util::Text::Table::Column->new( { $col->value->%*, id => $col->key, idx => $idx++ } );
    }

    $args->{cols} = $cols;

    # apply style
    $args = P->hash->merge( $STYLE->{ delete $args->{style} }, $args ) if $args->{style};

    return $args;
}

sub BUILD ( $self, $args ) {
    my $table_width = $self->{width};

    my $var_width_cols;

    # calculate width for columns with variable width
    for my $col ( $self->{cols}->@* ) {
        if ( !$col->{width} ) {
            die q[Table width must be defined if table has variable width columns] if !$table_width;

            push $var_width_cols->@*, $col;
        }
        else {
            $table_width -= $col->{width} if $table_width;
        }
    }

    if ($var_width_cols) {

        # - internal borders
        $table_width -= scalar( $self->{cols}->@* ) + 1;

        # - left / right borders
        $table_width -= 1 if defined $self->{grid} && $self->{left_border};
        $table_width -= 1 if defined $self->{grid} && $self->{right_border};

        my $col_width = int( $table_width / scalar $var_width_cols->@* );

        for my $col ( $var_width_cols->@* ) {
            $col->{width} = $col_width;
        }

        # set width for last col
        $var_width_cols->[-1]->{width} += $table_width % scalar $var_width_cols->@*;
    }

    return;
}

sub render_all ( $self, $data ) {
    $self->{_first_row} = 1;

    my $buf = $self->render_header;

    for my $row ( $data->@* ) {
        $buf .= $self->_render_row($row);
    }

    $buf .= $self->finish;

    return $buf;
}

sub render_header ($self) {
    $self->{_first_row} = 1;

    my $buf;

    # top line
    $buf .= $self->_render_line(0) if $self->{grid} && $self->{top_line};

    # header row
    $buf .= $self->_render_row( [ map { $_->{title} // uc $_->{id} } $self->{cols}->@* ], 1 ) if $self->{header};

    # header separator line
    $buf .= $self->_render_line(2) if $self->{grid} && $self->{header} && $self->{header_line};

    return $buf;
}

sub render_row ( $self, $row ) {
    return $self->_render_row($row);
}

sub render_row_line ($self) {

    # row line
    return $self->_render_line(4);
}

sub finish ($self) {
    if ( $self->{grid} && $self->{bottom_line} ) {

        # bottom line
        return $self->_render_line(5);
    }
    else {
        return $EMPTY;
    }
}

sub _render_row ( $self, $row, $header_row = 0 ) {
    my $buf;

    if ( !$header_row ) {
        if ( $self->{_first_row} ) { $self->{_first_row} = 0 }

        # data row separator line
        elsif ( $self->{grid} && $self->{row_line} ) { $buf .= $self->_render_line(4) }
    }

    my $grid;

    if ( $self->{grid} ) {
        $grid = $header_row ? $GRID->{ $self->{grid} }->[1] : $GRID->{ $self->{grid} }->[3];
    }

    my @cells;

    my $row_height = 1;

    # retrieve and format cells values
    for my $col ( $self->{cols}->@* ) {
        my $val;

        if ( is_plain_arrayref $row ) {

            # ArrayRef
            $val = $row->[ $col->{idx} ];
        }
        elsif ( is_plain_hashref $row ) {

            # HashRef
            $val = $row->{ $col->{id} };
        }
        else {

            # Object
            my $id = $col->{id};

            eval { $val = $row->$id; 1; } or do { $val = $row->{$id} if $@ };
        }

        my $align;

        # format cell and create cell attributes
        if ($header_row) {
            if ( $self->{color} && defined $col->{title_color} ) {
                $val = $col->{title_color} . $val . "\e[0m";
            }

            $align = $col->{title_align};
        }
        else {
            $val = $col->format_val( $val, $row );

            $align = $col->{align};
        }

        $val = wrap $val, $col->{width} - ( $self->{padding} * 2 ), ansi => $self->{color}, align => $align;

        $val = [ $SPACE x ( $col->{width} - $self->{padding} * 2 ) ] if !$val->@*;

        push @cells, $val;

        $row_height = scalar $val->@* if $val->@* > $row_height;
    }

    # valign
    if ( $row_height > 1 ) {
        for my $col ( $self->{cols}->@* ) {
            my $cell = $cells[ $col->{idx} ];

            my $cell_height = scalar $cell->@*;

            if ( $cell_height < $row_height ) {
                my $tmpl = $SPACE x ( $col->{width} - $self->{padding} * 2 );

                my $valign = $header_row ? $col->{title_valign} : $col->{valign};

                if ( $valign == -1 ) {
                    push $cell->@*, ($tmpl) x ( $row_height - $cell_height );
                }
                elsif ( $valign == 1 ) {
                    unshift $cell->@*, ($tmpl) x ( $row_height - $cell_height );
                }
                elsif ( $valign == 0 ) {
                    my $top = int( ( $row_height - $cell_height ) / 2 );

                    my $bottom = $row_height - $cell_height - $top;

                    unshift $cell->@*, ($tmpl) x $top;

                    push $cell->@*, ($tmpl) x $bottom;
                }
                else {
                    die q[Invalid valign value];
                }
            }
        }
    }

    my $padding = $self->{padding} ? $SPACE x $self->{padding} : $EMPTY;

    # render
    for my $line_idx ( 0 .. $row_height - 1 ) {
        $buf .= $grid->[0] if $grid && $self->{left_border};

        $buf .= join $grid ? $grid->[1] : $SPACE, map { $padding . $_->[$line_idx] . $padding } @cells;

        $buf .= $grid->[2] if $grid && $self->{right_border};

        $buf .= "\n";
    }

    return $buf;
}

# 0 - top, 2 - header separator line, 4 - row separator line, 5 - bottom
sub _render_line ( $self, $idx ) {
    my $buf;

    my $grid = $GRID->{ $self->{grid} }->[$idx];

    $buf .= $grid->[0] if $self->{left_border};

    $buf .= join $grid->[3], map { $grid->[2] x $_->{width} } $self->{cols}->@*;

    $buf .= $grid->[1] if $self->{right_border};

    return "$buf\n";
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 190                  | Subroutines::ProhibitExcessComplexity - Subroutine "_render_row" with high complexity score (34)               |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Text::Table

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
