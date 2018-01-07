package Term::TablePrint;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '0.056';
use Exporter 'import';
our @EXPORT_OK = qw( print_table );

use Carp         qw( carp croak );
use List::Util   qw( sum );
use Scalar::Util qw( looks_like_number );

use Term::Choose           qw( choose );
use Term::Choose::LineFold qw( line_fold cut_to_printwidth print_columns );
use Term::Choose::Util     qw( term_size insert_sep unicode_sprintf );
use Term::ProgressBar      qw();

use constant CLEAR_SCREEN => "\e[H\e[J"; #


sub new {
    my $class = shift;
    croak "new: called with " . @_ . " arguments - 0 or 1 arguments expected." if @_ > 1;
    my ( $opt ) = @_;
    my $self = bless {}, $class;
    if ( defined $opt ) {
        croak "new: The (optional) argument is not a HASH reference." if ref $opt ne 'HASH';
        $self->__validate_options( $opt );
    }
    return $self;
}


sub __validate_options {
    my ( $self, $opt ) = @_;
    my $valid = {
        max_rows        => '[ 0-9 ]+',
        min_col_width   => '[ 0-9 ]+',
        progress_bar    => '[ 0-9 ]+',
        tab_width       => '[ 0-9 ]+',
        add_header      => '[ 0 1 ]',
        binary_filter   => '[ 0 1 ]',
        grid            => '[ 0 1 ]',
        keep_header     => '[ 0 1 ]',
        choose_columns  => '[ 0 1 2 ]',
        table_expand    => '[ 0 1 2 ]',
        mouse           => '[ 0 1 2 3 4 ]',
        binary_string   => '',
        prompt          => '',
        undef           => '',
        #thsd_sep       => '',
        #no_col         => '',
    };
    for my $key ( keys %$opt ) {
        if ( ! exists $valid->{$key} ) {
            carp "print_table: '$key' is not a valid option name.";
            choose( [ 'Press ENTER to continue' ], { prompt => '' } );
            next;
        }
        next if ! defined $opt->{$key};
        if ( $valid->{$key} eq '' ) {
            $self->{$key} = $opt->{$key};
        }
        elsif ( $opt->{$key} =~ /^$valid->{$key}\z/x ) {
            $self->{$key} = $opt->{$key};
        }
        else {
            croak "print_table: '$opt->{$key}' is not a valid value for option '$key'.";
        }
    }
}


sub __set_defaults {
    my ( $self ) = @_;
    $self->{add_header}     = 0      if ! defined $self->{add_header};
    $self->{binary_filter}  = 0      if ! defined $self->{binary_filter};
    $self->{binary_string}  = 'BNRY' if ! defined $self->{binary_string};
    $self->{choose_columns} = 0      if ! defined $self->{choose_columns};
    $self->{grid}           = 0      if ! defined $self->{grid};
    $self->{keep_header}    = 1      if ! defined $self->{keep_header};
    $self->{max_rows}       = 50000  if ! defined $self->{max_rows};
    $self->{min_col_width}  = 30     if ! defined $self->{min_col_width};
    $self->{mouse}          = 0      if ! defined $self->{mouse};
    $self->{progress_bar}   = 40000  if ! defined $self->{progress_bar};
    $self->{prompt}         = ''     if ! defined $self->{prompt};
    $self->{tab_width}      = 2      if ! defined $self->{tab_width};
    $self->{table_expand}   = 1      if ! defined $self->{table_expand};
    $self->{undef}          = ''     if ! defined $self->{undef};
    $self->{thsd_sep} = ',';
    $self->{no_col}   = 'col';
    $self->{tab_w}    = $self->{tab_width};
    $self->{tab_w}++    if $self->{grid} && ! ( $self->{tab_width} % 2 );
}


sub __choose_columns_with_order {
    my ( $self, $avail_cols ) = @_;
    my $col_idxs = [];
    my $ok = '-ok-';
    my @pre = ( $ok );
    my $init_prompt = 'Columns: ';
    my $s_tab = print_columns( $init_prompt );

    while ( 1 ) {
        my @chosen_cols = @$col_idxs ?  @{$avail_cols}[@$col_idxs] : '*';
        my $prompt = $init_prompt . join ', ', @chosen_cols;
        my $choices = [ @pre, @$avail_cols ];
        # Choose
        my @idx = choose(
            $choices,
            { prompt => $prompt, lf => [ 0, $s_tab ], clear_screen => 1,
              no_spacebar => [ 0 .. $#pre ], index => 1, mouse => $self->{mouse} }
        );
        if ( ! @idx || ! defined $choices->[$idx[0]] ) { #
            if ( @$col_idxs ) {
                $col_idxs = [];
                next;
            }
            else {
                return;
            }
        }
        elsif ( $choices->[$idx[0]] eq $ok ) {
            shift @idx;
            push @$col_idxs, map { $_ -= @pre; $_ } @idx;
            return $col_idxs;
        }
        else {
            push @$col_idxs, map { $_ -= @pre; $_ } @idx;
        }
    }
}


sub __choose_columns_simple {
    my ( $self, $avail_cols ) = @_;
    my $all = '-*-';
    my @pre = ( $all );
    my $choices = [ @pre, @$avail_cols ];
    my @idx = choose(
        $choices,
        { prompt => 'Choose: ', no_spacebar => [ 0 .. $#pre ], index => 1, mouse => $self->{mouse} }
    );
    if ( ! @idx ) {
        return;
    }
    if ( $choices->[$idx[0]] eq $all ) {
        return [];
    }
    return [ map { $_ -= @pre; $_ } @idx ];
}


sub print_table {
    if ( ref $_[0] ne 'Term::TablePrint' ) {
        return Term::TablePrint->new( $_[1] )->print_table( $_[0] );
    }
    my $self = shift;
    my ( $table_ref, $opt ) = @_;
    croak "print_table: called with " . @_ . " arguments - 1 or 2 arguments expected." if @_ < 1 || @_ > 2;
    croak "print_table: requires an ARRAY reference as its first argument."            if ref $table_ref  ne 'ARRAY';
    croak "print_table: empty table without header row!"                               if ! @$table_ref;
    if ( defined $opt ) {
        croak "print_table: the (optional) second argument is not a HASH reference."   if ref $opt ne 'HASH';
        $self->{backup_opt} = { map{ $_ => $self->{$_} } keys %$opt };
        $self->__validate_options( $opt );
    }
    $self->__set_defaults();
    if ( $self->{add_header} ) {
        unshift @$table_ref, [ map { $_ . '_' . $self->{no_col} } 1 .. @{$table_ref->[0]} ];
    }
    my $last_row_idx = $self->{max_rows} && $self->{max_rows} < @$table_ref ? $self->{max_rows} : $#$table_ref;
    my $col_idxs = [];
    if ( $self->{choose_columns}  ) {
        $col_idxs = $self->__choose_columns_simple( $table_ref->[0] )     if $self->{choose_columns} == 1;
        $col_idxs = $self->__choose_columns_with_order( $table_ref->[0] ) if $self->{choose_columns} == 2;
        return if ! defined $col_idxs;
    }
    my $a_ref = [];
    if ( @$col_idxs ) {
        $a_ref = [ map { [ @{$table_ref->[$_]}[@$col_idxs] ] } 0 .. $last_row_idx ];
    }
    else {
        $a_ref = $table_ref;
        if ( $last_row_idx < $#$table_ref ) {
            $#$a_ref = $last_row_idx;
        }
    }
    $self->{binray_regexp} = qr/[\x00-\x08\x0B-\x0C\x0E-\x1F]/;
    if ( $self->{progress_bar} ) {
#        print 'Computing: ...' . "\n";
        $self->{show_progress} = int @$a_ref * @{$a_ref->[0]} / $self->{progress_bar};
    }
    $self->__calc_col_width( $a_ref );
    $self->__inner_print_tbl( $a_ref );
    if ( $self->{backup_opt} ) {
        my $backup_opt = delete $self->{backup_opt};
        for my $key ( keys %$backup_opt ) {
            $self->{$key} = $backup_opt->{$key};
        }
    }

}


sub __inner_print_tbl {
    my ( $self, $a_ref ) = @_;
    my ( $term_width ) = term_size();
    my $width_cols = $self->__calc_avail_width( $a_ref, $term_width );
    if ( ! defined $width_cols ) {
        return;
    }
    my ( $list, $len ) = $self->__trunk_col_to_avail_width( $a_ref, $width_cols );
    if ( $self->{max_rows} && @$list - 1 >= $self->{max_rows} ) {
        my $limit = insert_sep( $self->{max_rows}, $self->{thsd_sep} );
        my $reached_limit = 'REACHED LIMIT "MAX_ROWS": ' . $limit;
        if ( print_columns( $reached_limit ) > $len ) {
            $reached_limit = '=LIMIT= ' . $limit;
            $reached_limit = cut_to_printwidth( $reached_limit, $len );
        }
        push @$list, unicode_sprintf( $reached_limit, $len, 0 );
    }
    my $header_sep = '';
    if ( $self->{grid} ) {
        my $tab = ( '-' x int( $self->{tab_w} / 2 ) ) . '|' . ( '-' x int( $self->{tab_w} / 2 ) );
        for my $i ( 0 .. $#$width_cols ) {
            $header_sep .= '-' x $width_cols->[$i];
            $header_sep .= $tab if $i != $#$width_cols;
        }
    }
    my @header;
    if ( length $self->{prompt} ) {
        @header = ( $self->{prompt} );
    }
    if ( $self->{keep_header} ) {
        my $col_names = shift @$list;
        push @header, $col_names;
        push @header, $header_sep if $self->{grid};
    }
    else {
        splice( @$list, 1, 0, $header_sep ) if $self->{grid};
    }
    my $prompt = join( "\n", @header );
    my $old_row = 0;
    my $auto_jumped_to_first_row = 2;
    my $expanded = 0;
    my ( $width ) = term_size();
    while ( 1 ) {
        if ( ( term_size() )[0] != $width ) {
            ( $width ) = term_size();
            $self->__inner_print_tbl( $a_ref );
            return;
        }
        if ( ( $self->{keep_header} && ! @$list ) || ( @$list == 1 ) ) {
            # Choose
            choose(
                [ undef, @{$a_ref->[0]} ],
                { prompt => 'EMPTY table!', layout => 0, clear_screen => 1, mouse => $self->{mouse}, undef => '<<' }
            );
            return;
        }
        # Choose
        my $row = choose(
            $list,
            { prompt => $prompt, index => 1, default => $old_row, ll => $len, layout => 3,
              clear_screen => 1, mouse => $self->{mouse} }
        );
        if ( ! defined $row ) {
            return;
        }
        elsif ( $row == -1 ) {
            next;
        }
        if ( ! $self->{table_expand} ) {
            return if $row == 0;
        }
        else {
            if ( $old_row == $row ) {
                if ( $row == 0 ) {
                    if ( ! $self->{keep_header} ) {
                        return;
                    }
                    elsif ( $self->{table_expand} == 1 ) {
                        return if $expanded;
                        return if $auto_jumped_to_first_row == 1;
                    }
                    elsif ( $self->{table_expand} == 2 ) {
                        return if $expanded;
                    }
                    $auto_jumped_to_first_row = 0;
                }
                else {
                    $old_row = 0;
                    $auto_jumped_to_first_row = 1;
                    $expanded = 0;
                    next;
                }
            }
            $old_row = $row;
            if ( $self->{keep_header} ) {
                $row++;
            }
            else {
                if ( $self->{grid} ) {
                    next   if $row == 1;
                    $row-- if $row > 1;
                }
            }
            $expanded = 1;
            $self->__print_single_row( $a_ref, $row, $self->{longest_col_name} + 1 );
        }
    }
}


sub __print_single_row {
    my ( $self, $a_ref, $row, $len_key ) = @_;
    my ( $term_width ) = term_size();
    $len_key = int( $term_width / 100 * 33 ) if $len_key > int( $term_width / 100 * 33 );
    my $separator = ' : ';
    my $len_sep = print_columns( $separator );
    my $col_max = $term_width - ( $len_key + $len_sep + 1 );
    my $row_data = [ ' Close with ENTER' ];

    for my $col ( 0 .. $#{$a_ref->[0]} ) {
        push @{$row_data}, ' ';
        my $key = cut_to_printwidth( $self->__sanitize_string( $a_ref->[0][$col] ), $len_key );
        my $sep = $separator;
        if ( ! defined $a_ref->[$row][$col] || $a_ref->[$row][$col] eq '' ) {
            push @{$row_data}, sprintf "%*.*s%*s%s", $len_key, $len_key, $key, $len_sep, $sep, '';
        }
        else {
            for my $line ( split /\n+/, line_fold( $a_ref->[$row][$col], $col_max, '', '' ) ) {
                push @{$row_data}, sprintf "%*.*s%*s%s", $len_key, $len_key, $key, $len_sep, $sep, $line;
                $key = '' if $key;
                $sep = '' if $sep;
            }
        }
    }
    # Choose
    choose(
        $row_data,
        { prompt => '', layout => 3, clear_screen => 1, mouse => $self->{mouse} }
    );
}


sub __sanitize_string {
    my ( $self, $str ) = @_;
    if ( ! defined $str ) {
        $str = $self->{undef};
    }
    elsif ( ref $str ) {
        $str = $self->__handle_reference( $str );
    }
    elsif ( $self->{binary_filter} && substr( $str, 0, 100 ) =~ $self->{binray_regexp} ) {
        $str = $self->{binary_string};
    }
    else {
        $str =~ s/^\p{Space}+//;
        $str =~ s/\p{Space}+\z//;
        $str =~ s/\p{Space}+/ /g;
        $str =~ s/\p{C}//g;
    }
    return $str;
}

sub __handle_reference {
    my ( $self, $ref ) = @_;
    if ( ref $ref eq 'ARRAY' ) {
        return 'ref: [' . join( ',', map { '"' . $_ . '"' } @$ref ) . ']';
    }
    elsif ( ref $ref eq 'SCALAR' ) {
        return 'ref: \\' . $$ref;
    }
    elsif ( ref $ref eq 'HASH' ) {
        return 'ref: {' . join( ',', map { $_ . '=>"' . $ref->{$_} . '"' } keys %$ref ) . '}';
    }
    elsif ( ref $ref eq 'Regexp' ) {
        return 'ref: qr/' . $ref . '/';
    }
    elsif ( ref $ref eq 'VSTRING' ) {
        return 'ref: \v' . join '.', unpack 'C*', $$ref;
    }
    elsif ( ref $ref eq 'GLOB' ) {
        return 'ref: \\' . $$ref;
    }
    else {
        return 'ref: ' . ref( $ref );
    }
}


sub __calc_col_width {
    my ( $self, $a_ref ) = @_;
    my $show_progress = $self->{show_progress} >= 2 ? 1 : 0; #
    my $total = @$a_ref;                      #
    my $next_update = 0;                      #
    my $c = 0;                                #
    my $progress;                             #
    if ( $show_progress ) {                   #
        local $| = 1;                         #
        print CLEAR_SCREEN;                   #
        $progress = Term::ProgressBar->new( { #
            name => 'Computing',              #
            count => $total,                  #
            remove => 1 } );                  #
        $progress->minor( 0 );                #
    }                                         #
    $self->{longest_col_name} = 0;
    $self->{width_cols} = [ ( 1 ) x @{$a_ref->[0]} ];
    my $normal_row = 0;
    my @col_idx = ( 0 .. $#{$a_ref->[0]} );

    for my $row ( @$a_ref ) {
        for my $i ( @col_idx ) {
            my $width = print_columns( $self->__sanitize_string( $row->[$i] ) );
            if ( $normal_row ) {
                if ( $width > $self->{width_cols}[$i] ) {
                    $self->{width_cols}[$i] = $width;
                }
                if ( $row->[$i] && ! looks_like_number $row->[$i] ) {
                    ++$self->{not_a_number}[$i];
                }
            }
            else {
                # col name
                $self->{width_head}[$i] = $width;
                if ( $width > $self->{longest_col_name} ) {
                    $self->{longest_col_name} = $width;
                }
                if ( $i == $#$row ) {
                    $normal_row = 1;
                }
            }
        }
        if ( $show_progress ) {                                              #
            $next_update = $progress->update( $c ) if $c >= $next_update;    #
            ++$c;                                                            #
        }                                                                    #
    }
    $progress->update( $total ) if $show_progress && $total >= $next_update; #
}


sub __calc_avail_width {
    my ( $self, $a_ref, $term_width ) = @_;
    my $width_head = [ @{$self->{width_head}} ];
    my $width_cols = [ @{$self->{width_cols}} ];
    my $avail_width = $term_width - $self->{tab_w} * $#$width_cols;
    my $sum = sum( @$width_cols );
    if ( $sum < $avail_width ) {
        # auto cut
        HEAD: while ( 1 ) {
            my $count = 0;
            for my $i ( 0 .. $#$width_head ) {
                if ( $width_head->[$i] > $width_cols->[$i] ) {
                    ++$width_cols->[$i];
                    ++$count;
                    last HEAD if ( $sum + $count ) == $avail_width;
                }
            }
            last HEAD if $count == 0;
            $sum += $count;
        }
        return $width_cols;
    }
    elsif ( $sum > $avail_width ) {
        my $minimum_with = $self->{min_col_width} || 1;
        if ( @$width_head > $avail_width ) {
            my $prompt_1 = 'To many columns - terminal window is not wide enough.';
            choose(
                [ 'Press ENTER to show the column names.' ],
                { prompt => $prompt_1, clear_screen => 1, mouse => $self->{mouse} }
            );
            my $prompt_2 = 'Column names (close with ENTER).';
            choose(
                $a_ref->[0],
                { prompt => $prompt_2, clear_screen => 1, mouse => $self->{mouse} }
            );
            return;
        }
        my @width_cols_tmp = @$width_cols;
        my $percent = 0;

        MIN: while ( $sum > $avail_width ) {
            ++$percent;
            my $count = 0;
            for my $i ( 0 .. $#width_cols_tmp ) {
                if ( $minimum_with >= $width_cols_tmp[$i] ) {
                    next;
                }
                if ( $minimum_with >= _minus_x_percent( $width_cols_tmp[$i], $percent ) ) {
                    $width_cols_tmp[$i] = $minimum_with;
                }
                else {
                    $width_cols_tmp[$i] = _minus_x_percent( $width_cols_tmp[$i], $percent );
                }
                ++$count;
            }
            $sum = sum( @width_cols_tmp );
            $minimum_with-- if $count == 0;
            #last MIN if $minimum_with == 0;
        }
        my $rest = $avail_width - $sum;
        if ( $rest ) {

            REST: while ( 1 ) {
                my $count = 0;
                for my $i ( 0 .. $#width_cols_tmp ) {
                    if ( $width_cols_tmp[$i] < $width_cols->[$i] ) {
                        $width_cols_tmp[$i]++;
                        $rest--;
                        $count++;
                        last REST if $rest == 0;
                    }
                }
                last REST if $count == 0;
            }
        }
        $width_cols = [ @width_cols_tmp ] if @width_cols_tmp;
    }
    return $width_cols;
}

sub _minus_x_percent {
    my ( $value, $percent ) = @_;
    my $new = int( $value - ( $value / 100 * $percent ) );
    return $new > 0 ? $new : 1;
}


sub __trunk_col_to_avail_width {
    my ( $self, $a_ref, $width_cols ) = @_;
    my $total = @$a_ref;                      #
    my $next_update = 0;                      #
    my $c = 0;                                #
    my $progress;                             #
    if ( $self->{show_progress} ) {           #
        local $| = 1;                         #
        print CLEAR_SCREEN;                   #
        $progress = Term::ProgressBar->new( { #
            name => 'Computing',              #
            count => $total,                  #
            remove => 1 } );                  #
        $progress->minor( 0 );                #
    }
    my $tab;
    if ( $self->{grid} ) {
        $tab = ( ' ' x int( $self->{tab_w} / 2 ) ) . '|' . ( ' ' x int( $self->{tab_w} / 2 ) );
    }
    else {
        $tab = ' ' x $self->{tab_w};
    }
    my $list = [];
    for my $row ( @$a_ref ) {
        my $str = '';
        for my $i ( 0 .. $#$width_cols ) {
            $str .= unicode_sprintf(
                $self-> __sanitize_string( $row->[$i] ),
                $width_cols->[$i],
                $self->{not_a_number}[$i] ? 0 : 1
            );
            $str .= $tab if $i != $#$width_cols;
        }
        push @$list, $str;
        if ( $self->{show_progress} ) {                                      #
            $next_update = $progress->update( $c ) if $c >= $next_update;    #
            ++$c;                                                            #
        }                                                                    #
    }
    $progress->update( $total ) if $self->{show_progress} && $total >= $next_update; #
    my $len = sum( @$width_cols, $self->{tab_w} * $#{$width_cols} );
    return $list, $len;
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::TablePrint - Print a table to the terminal and browse it interactively.

=head1 VERSION

Version 0.056

=cut

=head1 SYNOPSIS

    my $table = [ [ 'id', 'name' ],
                  [    1, 'Ruth' ],
                  [    2, 'John' ],
                  [    3, 'Mark' ],
                  [    4, 'Nena' ], ];

    use Term::TablePrint qw( print_table );

    print_table( $table );

    # or OO style:

    use Term::TablePrint;

    my $pt = Term::TablePrint->new();
    $pt->print_table( $table );

=head1 DESCRIPTION

C<print_table> shows a table and lets the user interactively browse it. It provides a cursor which highlights the row
on which it is located. The user can scroll through the table with the different cursor keys - see L</KEYS>.

If the table has more rows than the terminal, the table is divided up on as many pages as needed automatically. If the
cursor reaches the end of a page, the next page is shown automatically until the last page is reached. Also if the
cursor reaches the topmost line, the previous page is shown automatically if it is not already the first one.

If the terminal is too narrow to print the table, the columns are adjusted to the available width automatically.

If the option table_expand is enabled and a row is selected with Return, each column of that row is output in its own
line preceded by the column name. This might be useful if the columns were cut due to the too low terminal width.

To get a proper output C<print_table> uses the C<columns> method from L<Unicode::GCString> to calculate the string
length.

The following modifications are made (at a copy of the original data) before the output.

Leading and trailing spaces are removed from the array elements

    s/^\p{Space}+//;
    s/\p{Space}+\z//;

and spaces are squashed to a single white-space.

    s/\p{Space}+/ /g;

In addition, characters of the Unicode property C<Other> are removed.

    s/\p{C}//g;

In C<Term::TablePrint> the C<utf8> C<warnings> are disabled.

    no warnings 'utf8';

The elements in a column are right-justified if one or more elements of that column do not look like a number, else they
are left-justified.

=head1 METHODS

=head2 new

The C<new> method returns a C<Term::TablePrint> object. As an argument it can be passed a reference to a hash which
holds the options - the available options are listed in L</OPTIONS>.

    my $tp = Term::TablePrint->new( [ \%options ] );

=head2 print_table

The C<print_table> method prints the table passed with the first argument.

    $tp->print_table( $array_ref, [ \%options ] );

The first argument is a reference to an array of arrays. The first array of these arrays holds the column names. The
following arrays are the table rows where the elements are the field values.

As a second and optional argument a hash reference can be passed which holds the options - the available options are
listed in L</OPTIONS>.

=head1 SUBROUTINES

=head2 print_table

The C<print_table> subroutine prints the table passed with the first argument.

    print_table( $array_ref, [ \%options ] );

The subroutine C<print_table> takes the same arguments as the method L</print_table>.

=head1 USAGE

=head2 KEYS

Keys to move around:

=over

=item *

the C<ArrowDown> key (or the C<j> key) to move down and  the C<ArrowUp> key (or the C<k> key) to move up.

=item *

the C<PageUp> key (or C<Ctrl-B>) to go back one page, the C<PageDown> key (or C<Ctrl-F>) to go forward one page.

=item *

the C<Home> key (or C<Ctrl-A>) to jump to the first row of the table, the C<End> key (or C<Ctrl-E>) to jump to the last
row of the table.

=back

With I<keep_header> disabled the C<Return> key closes the table if the cursor is on the header row.

If I<keep_header> is enabled and I<table_expand> is set to C<0>, the C<Return> key closes the table if the cursor is on
the first row.

If I<keep_header> and I<table_expand> are enabled and the cursor is on the first row, pressing C<Return> three times in
succession closes the table. If I<table_expand> is set to C<1> and the cursor is auto-jumped to the first row, it is
required only one C<Return> to close the table.

If the cursor is not on the first row:

=over

=item *

with the option I<table_expand> disabled the cursor jumps to the table head if C<Return> is pressed.

=item *

with the option I<table_expand> enabled each column of the selected row is output in its own line preceded by the
column name if C<Return> is pressed. Another C<Return> closes this output and goes back to the table output. If a row is
selected twice in succession, the pointer jumps to the head of the table or to the first row if I<keep_header> is
enabled.

=back

If the size of the window is changed, the screen is rewritten as soon as the user presses a key.

If the option I<choose_columns> is enabled, the C<SpaceBar> key (or the right mouse key) can be used to select columns -
see option L</choose_columns>.

=head2 OPTIONS

Defaults may change in a future release.

=head3 prompt

String displayed above the table.

=head3 add_header

If I<add_header> is set to 1, C<print_table> adds a header row - the columns are numbered starting with 1.

Default: 0

=head3 binary_filter

If I<binary_filter> is set to 1, "BNRY" is printed instead of arbitrary binary data.

If the data matches the repexp C</[\x00-\x08\x0B-\x0C\x0E-\x1F]/>, it is considered arbitrary binary data.

Printing arbitrary binary data could break the output.

Default: 0

=head3 choose_columns

If I<choose_columns> is set to 1, the user can choose which columns to print. The columns can be marked with the
C<SpaceBar>. The list of marked columns including the highlighted column are printed as soon as C<Return> is pressed.

If I<choose_columns> is set to 2, it is possible to change the order of the columns. Columns can be added (with
the C<SpaceBar> and the C<Return> key) until the user confirms with the I<-ok-> menu entry.

Default: 0

=head3 grid

If enabled, columns are separated from each other with lines and the header row is separated with a line from the rest
of the table.

Default: 0

=head3 keep_header

If I<keep_header> is set to 1, the table header is shown on top of each page.

If I<keep_header> is set to 0, the table header is shown on top of the first page.

Default: 1

=head3 max_rows

Set the maximum number of used table rows. The used table rows are kept in memory.

To disable the automatic limit set I<max_rows> to 0.

If the number of table rows is equal to or higher than I<max_rows>, the last row of the output says "REACHED LIMIT" or
"=LIMIT=" if "REACHED LIMIT" doesn't fit in the row.

Default: 50_000

=head3 min_col_width

The columns with a width below or equal I<min_col_width> are only trimmed if it is still required to lower the row width
despite all columns wider than I<min_col_width> have been trimmed to I<min_col_width>.

Default: 30

=head3 mouse

Set the I<mouse> mode (see option C<mouse> in L<Term::Choose/OPTIONS>).

Default: 0

=head3 progress_bar

Set the progress bar threshold. If the number of fields (rows x columns) is higher than the threshold, a progress bar is
shown while preparing the data for the output.

Default: 40_000

=head3 tab_width

Set the number of spaces between columns.

Default: 2

=head3 table_expand

If the option I<table_expand> is set to C<1> or C<2> and C<Return> is pressed, the selected table row is printed with
each column in its own line. Exception: if I<table_expand> is set to C<1> and the cursor auto-jumped to the first row,
the first row will not be expanded.

If I<table_expand> is set to 0, the cursor jumps to the to first row (if not already there) when C<Return> is pressed.

Default: 1

=head3 undef

Set the string that will be shown on the screen instead of an undefined field.

Default: "" (empty string)

=head1 ERROR HANDLING

=head2 Carp

C<print_table> warns

=over

=item

if an unknown option name is passed.

=back

=head2 Croak

C<print_table> dies

=over

=item

if an invalid number of arguments is passed.

=item

if an invalid argument is passed.

=item

if an invalid option value is passed.

=back

if the first argument refers to an empty array.

=head1 REQUIREMENTS

=head2 Perl version

Requires Perl version 5.8.3 or greater.

=head2 Decoded strings

C<print_table> expects decoded strings.

=head2 Encoding layer for STDOUT

For a correct output it is required to set an encoding layer for C<STDOUT> matching the terminal's character set.

=head2 Monospaced font

It is required a terminal that uses a monospaced font which supports the printed characters.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::TablePrint

=head1 SEE ALSO

L<App::DBBrowser>

=head1 CREDITS

Thanks to the L<Perl-Community.de|http://www.perl-community.de> and the people form
L<stackoverflow|http://stackoverflow.com> for the help.

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2018 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
