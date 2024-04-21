package Term::TablePrint;

use warnings;
use strict;
use 5.10.0;

our $VERSION = '0.163';
use Exporter 'import';
our @EXPORT_OK = qw( print_table );

use Carp qw( croak );

use List::Util   qw( sum max );
use Scalar::Util qw( looks_like_number );

use Term::Choose                  qw( choose );
use Term::Choose::Constants       qw( WIDTH_CURSOR PH SGR_ES );
use Term::Choose::LineFold        qw( line_fold cut_to_printwidth print_columns );
use Term::Choose::Screen          qw( hide_cursor show_cursor );
use Term::Choose::ValidateOptions qw( validate_options );
use Term::Choose::Util            qw( get_term_width insert_sep );
use Term::TablePrint::ProgressBar qw();


BEGIN {
    if ( $^O eq 'MSWin32' ) {
        require Win32::Console::ANSI;
    }
}

my $save_memory = 0;

sub new {
    my $class = shift;
    croak "new: called with " . @_ . " arguments - 0 or 1 arguments expected." if @_ > 1;
    my ( $opt ) = @_;
    my $instance_defaults = _defaults();
    if ( defined $opt ) {
        croak "new: The (optional) argument is not a HASH reference." if ref $opt ne 'HASH';
        validate_options( _valid_options(), $opt, 'new' );
        for my $key ( keys %$opt ) {
            $instance_defaults->{$key} = $opt->{$key} if defined $opt->{$key};
        }
    }
    my $self = bless $instance_defaults, $class;
    $self->{backup_instance_defaults} = { %$instance_defaults };
    return $self;
}


sub _valid_options {
    return {
        codepage_mapping  => '[ 0 1 ]',
        hide_cursor       => '[ 0 1 ]', # documentation
        mouse             => '[ 0 1 ]',
        squash_spaces     => '[ 0 1 ]',
        table_expand      => '[ 0 1 ]',
        trunc_fract_first => '[ 0 1 ]',
        binary_filter     => '[ 0 1 2 ]',
        color             => '[ 0 1 2 ]',
        page              => '[ 0 1 2 ]', # undocumented
        search            => '[ 0 1 2 ]', #
        keep              => '[ 1-9 ][ 0-9 ]*', # undocumented
        max_rows          => '[ 0-9 ]+',
        min_col_width     => '[ 0-9 ]+', ##
        progress_bar      => '[ 0-9 ]+',
        tab_width         => '[ 0-9 ]+',
        binary_string     => 'Str', ##
        decimal_separator => 'Str',
        footer            => 'Str',
        info              => 'Str',
        prompt            => 'Str',
        undef             => 'Str',
        #thsd_sep         => 'Str',
    };
}


sub _defaults {
    return {
        binary_filter     => 0,
        binary_string     => 'BNRY',
        codepage_mapping  => 0,
        color             => 0,
        decimal_separator => '.',
        footer            => undef,
        hide_cursor       => 1,
        info              => undef,
        keep              => undef,
        max_rows          => 0,
        min_col_width     => 30,
        mouse             => 0,
        page              => 2, ##
        progress_bar      => 40000,
        prompt            => '',
        search            => 1,
        squash_spaces     => 0,
        tab_width         => 2,
        table_expand      => 1,
        trunc_fract_first => 1,
        undef             => '',
        thsd_sep          => ',', #
    }
}


sub __reset {
    my ( $self ) = @_;
    if ( $self->{hide_cursor} ) {
        print show_cursor();
    }
    if ( exists $self->{backup_instance_defaults} ) {
        my $instance_defaults = $self->{backup_instance_defaults};
        for my $key ( keys %$self ) {
            if ( $key eq 'plugin' || $key eq 'backup_instance_defaults' ) {
                next;
            }
            elsif ( exists $instance_defaults->{$key} ) {
                $self->{$key} = $instance_defaults->{$key};
            }
            else {
                delete $self->{$key};
            }
        }
    }
}


sub print_table {
    if ( ref $_[0] ne __PACKAGE__ ) {
        my $ob = __PACKAGE__->new();
        delete $ob->{backup_instance_defaults};
        return $ob->print_table( @_ );
    }
    my $self = shift;
    my ( $tbl_orig, $opt ) = @_;
    croak "print_table: called with " . @_ . " arguments - 1 or 2 arguments expected." if @_ < 1 || @_ > 2;
    croak "print_table: requires an ARRAY reference as its first argument."            if ref $tbl_orig  ne 'ARRAY';
    if ( defined $opt ) {
        croak "print_table: the (optional) second argument is not a HASH reference."   if ref $opt ne 'HASH';
        validate_options( _valid_options(), $opt, 'print_table' );
        for my $key ( keys %$opt ) {
            $self->{$key} = $opt->{$key} if defined $opt->{$key};
        }
    }
    $self->{tab_w} = $self->{tab_width};
    if ( ! ( $self->{tab_width} % 2 ) ) {
        ++$self->{tab_w};
    }
    local $| = 1;
    local $SIG{INT} = sub {
        $self->__reset();
        print "\n";
        exit;
    };
    if ( print_columns( $self->{decimal_separator} ) != 1 ) {
        $self->{decimal_separator} = '.';
    }
    if ( $self->{decimal_separator} ne '.' ) {
        $self->{thsd_sep} = '_';
    }
    if ( $self->{hide_cursor} ) {
        print hide_cursor();
        # 'choose' functions: Deactivate 'hide_cursor', because if 'hide_cursor' is
        # activated (default), 'choose' activates the cursor before returning.
    }
    if ( ! @$tbl_orig || !@{$tbl_orig->[0]} ) {
        my $message;
        if ( ! @$tbl_orig ) {
            $message = "'print_table': empty table without header row!";
        }
        else {
            $message = "'print_table': no columns!";
        }
        # Choose
        choose(
            [ 'Close with ENTER' ],
            { prompt => $message, hide_cursor => 0 }
        );
        $self->__reset();
        return;
    }
    my $data_row_count = @$tbl_orig - 1;
    my $info_row = '';
    if ( $self->{max_rows} && $data_row_count > $self->{max_rows} ) {
        $info_row = sprintf( 'Limited to %s rows', insert_sep( $self->{max_rows}, $self->{thsd_sep} ) );
        $info_row .= sprintf( ' (total %s)', insert_sep( $data_row_count, $self->{thsd_sep} ) );
        $data_row_count = $self->{max_rows};
    }
    my $const = {
        extra_w        => $^O eq 'MSWin32' || $^O eq 'cygwin' ? 0 : WIDTH_CURSOR,
        data_row_count => $data_row_count,
        info_row       => $info_row,
        regex_number   => "^([^.EeNn]*)(\Q$self->{decimal_separator}\E[0-9]+)?\\z",
    };
    my $search = {
        filter => '',
        map_indexes => [],
    };
    my $mr = {
        last                         => 0,
        window_width_changed         => 1,
        enter_search_string          => 2,
        returned_from_filtered_table => 3,
    };

    my ( $term_w, $tbl_print, $tbl_w, $header_rows, $w_col_names ) = $self->__get_data( $tbl_orig, $const );
    if ( ! defined $term_w ) {
        $self->__reset();
        return;
    }

    WRITE_TABLE: while ( 1 ) {
        my $next = $self->__write_table(
            $term_w, $tbl_orig, $tbl_print, $tbl_w, $header_rows, $w_col_names, $const, $search, $mr
        );
        if ( ! defined $next ) {
            die;
        }
        elsif ( $next == $mr->{last} ) {
            last WRITE_TABLE;
        }
        elsif ( $next == $mr->{window_width_changed} ) {
            ( $term_w, $tbl_print, $tbl_w, $header_rows, $w_col_names ) = $self->__get_data( $tbl_orig, $const );
            if ( ! defined $term_w ) {
                last WRITE_TABLE;
            }
            next WRITE_TABLE;
        }
        elsif ( $next == $mr->{enter_search_string} ) {
            $self->__search( $tbl_orig, $const, $search );
            next WRITE_TABLE;
        }
        elsif ( $next == $mr->{returned_from_filtered_table} ) {
            $self->__reset_search( $search );
            next WRITE_TABLE;
        }
    }
    $self->__reset();
    return;
}


sub __get_data {
    my ( $self, $tbl_orig, $const ) = @_;
    my $term_w = get_term_width() + $const->{extra_w};
    my $progress = Term::TablePrint::ProgressBar->new( {
        data_row_count => $const->{data_row_count},
        col_count => scalar @{$tbl_orig->[0]},
        threshold => $self->{progress_bar},
        count_progress_bars => 3,
    } );
    my $tbl_copy = $self->__copy_table( $tbl_orig, $progress );
    my ( $w_col_names, $w_cols, $w_int, $w_fract ) = $self->__calc_col_width( $tbl_copy, $const, $progress );
    my $w_cols_calc = $self->__calc_avail_col_width( $term_w, $tbl_copy, $w_col_names, $w_cols, $w_int, $w_fract );
    if ( ! defined $w_cols_calc ) {
        return;
    }
    my $tbl_w = sum( @{$w_cols_calc}, $self->{tab_w} * $#{$w_cols_calc} );
    my $tbl_print = $self->__cols_to_string( $tbl_orig, $tbl_copy, $w_cols_calc, $w_fract, $const, $progress );
    my @tmp_header_rows;
    if ( length $self->{prompt} ) {
        push @tmp_header_rows, $self->{prompt};
    }
    if ( length $self->{info} || length $self->{prompt} ) {
        push @tmp_header_rows, $self->__header_sep( $w_cols_calc );
    }
    my $col_names = shift @{$tbl_print};
    push @tmp_header_rows, $col_names, $self->__header_sep( $w_cols_calc );
    my $header_rows = join "\n", @tmp_header_rows;
    if ( $const->{info_row} ) {
        if ( print_columns( $const->{info_row} ) > $tbl_w ) {
            push @{$tbl_print}, cut_to_printwidth( $const->{info_row}, $tbl_w - 3 ) . '...';
        }
        else {
            push @{$tbl_print}, $const->{info_row};
        }
    }
    return $term_w, $tbl_print, $tbl_w, $header_rows, $w_col_names;
}


sub __write_table {
    my ( $self, $term_w, $tbl_orig, $tbl_print, $tbl_w, $header_rows, $w_col_names, $const, $search, $mr ) = @_;
    my @idxs_tbl_print;
    my $return = $mr->{last};
    if ( $search->{filter} ) {
        @idxs_tbl_print = map { $_ - 1 } @{$search->{map_indexes}}; # because of the removed tbl_print header row
        $return = $mr->{returned_from_filtered_table};
    }
    my $footer;
    if ( $self->{footer} ) {
        $footer = $self->{footer};
        if ( $search->{filter} ) {
            $footer .= "[$search->{filter}]";
        }
    }
    my $old_row = exists $ENV{TC_POS_AT_SEARCH} && ! $search->{filter} ? delete( $ENV{TC_POS_AT_SEARCH} ) : 0;
    my $auto_jumped_to_first_row = 2;
    my $row_is_expanded = 0;

    while ( 1 ) {
        if ( $term_w != get_term_width() + $const->{extra_w} ) {
            return $mr->{window_width_changed};
        }
        if ( ! @{$tbl_print} ) {
            push @{$tbl_print}, ''; # so that going back requires always the same amount of keystrokes
        }
        $ENV{TC_RESET_AUTO_UP} = 0;
        # Choose
        my $row = choose(
            @idxs_tbl_print ? [ @{$tbl_print}[@idxs_tbl_print] ]
                            :     $tbl_print,
            { info => $self->{info}, prompt => $header_rows, index => 1, default => $old_row, ll => $tbl_w, layout => 2,
              clear_screen => 1, mouse => $self->{mouse}, hide_cursor => 0, footer => $footer, color => $self->{color},
              codepage_mapping => $self->{codepage_mapping}, search => $self->{search}, keep => $self->{keep},
              page => $self->{page} }
        );
        if ( ! defined $row ) {
            return $return;
        }
        elsif ( $row < 0 ) {
            if ( $row == -1 ) { # with option `ll` set and changed window width `choose` returns -1;
                return $mr->{window_width_changed};
            }
            elsif ( $row == -13 ) { # with option `ll` set `choose` returns -13 if `Ctrl-F` was pressed
                if ( $search->{filter} ) {
                    $self->__reset_search( $search );
                }
                return $mr->{enter_search_string};
            }
            else {
                return $mr->{last};
            }
        }
        if ( ! $self->{table_expand} ) {
            if ( $row == 0 ) {
                return $return;
            }
            next;
        }
        else {
            if ( $old_row == $row ) {
                if ( $row == 0 ) {
                    if ( $self->{table_expand} ) {
                        if ( $row_is_expanded ) {
                            return $return;
                        }
                        if ( $auto_jumped_to_first_row == 1 ) {
                            return $return;
                        }
                    }
                    $auto_jumped_to_first_row = 0;
                }
                elsif ( $ENV{TC_RESET_AUTO_UP} ) {
                    $auto_jumped_to_first_row = 0;
                }
                else {
                    $old_row = 0;
                    $auto_jumped_to_first_row = 1;
                    $row_is_expanded = 0;
                    next;
                }
            }
            $old_row = $row;
            $row_is_expanded = 1;
            if ( $const->{info_row} && $row == $#{$tbl_print} ) {
                # Choose
                choose(
                    [ 'Close' ],
                    { prompt => $const->{info_row}, clear_screen => 1, mouse => $self->{mouse}, hide_cursor => 0 }
                );
                next;
            }
            my $orig_row;
            if ( @{$search->{map_indexes}} ) {
                $orig_row = $search->{map_indexes}[$row];
            }
            else {
                $orig_row = $row + 1; # because $tbl_print has no header row while $tbl_orig has a header row
            }
            $self->__print_single_row( $tbl_orig, $orig_row, $w_col_names, $footer );
        }
        delete $ENV{TC_RESET_AUTO_UP};
    }
}


sub __copy_table {
    my ( $self, $tbl_orig, $progress ) = @_;
    my $tbl_copy = [];
    my $count = $progress->set_progress_bar();            #
    ROW: for my $row ( @$tbl_orig ) {
        my $tmp_row = [];
        COL: for ( @$row ) {
            my $str = $_; # this is where the copying happens
            $str = $self->{undef}            if ! defined $str;
            $str = _handle_reference( $str ) if ref $str;
            if ( $self->{squash_spaces} ) {
                $str =~ s/^\p{Space}+//;
                $str =~ s/\p{Space}+\z//;
                $str =~ s/\p{Space}+/ /g;
            }
            if ( $self->{color} ) {
                $str =~ s/${\PH}//g;
                $str =~ s/${\SGR_ES}/${\PH}/g;
            }
            if ( $self->{binary_filter} && substr( $str, 0, 100 ) =~ /[\x00-\x08\x0B-\x0C\x0E-\x1F]/ ) {
                if ( $self->{binary_filter} == 2 ) {
                    ( $str = sprintf("%v02X", $_ // $self->{undef} ) ) =~ tr/./ /;
                }
                else {
                    $str = $self->{binary_string};
                }
            }
            $str =~ s/\t/ /g;
            $str =~ s/\v+/\ \ /g;
            $str =~ s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]//g;
            push @$tmp_row, $str;
        }
        push @$tbl_copy, $tmp_row;
        if ( @$tbl_copy == $self->{max_rows} ) {
            last;
        }
        if ( $progress->{count_progress_bars} ) {         #
            if ( $count >= $progress->{next_update} ) {   #
                $progress->update_progress_bar( $count ); #
            }                                             #
            ++$count;                                     #
        }                                                 #
    }
    if ( $progress->{count_progress_bars} ) {             #
        $progress->last_update_progress_bar( $count );    #
    }                                                     #
    return $tbl_copy
}


sub __calc_col_width {
    my ( $self, $tbl_copy, $const, $progress ) = @_;
    my $count = $progress->set_progress_bar();            #
    my @col_idx = ( 0 .. $#{$tbl_copy->[0]} );
    my $col_count = @col_idx;
    my $w_col_names = [];
    my $w_cols = [ ( 1 ) x $col_count ];
    my $w_int   = [ ( 0 ) x $col_count ];
    my $w_fract = [ ( 0 ) x $col_count ];
    my $regex_number = $const->{regex_number};
    my $col_names = shift @$tbl_copy;
    for my $col ( @col_idx ) {
        $w_col_names->[$col] = print_columns( $col_names->[$col] );
    }

    for my $row ( 0 .. $#$tbl_copy ) {
        for my $col ( @col_idx ) {
            if ( ! length $tbl_copy->[$row][$col] ) {
                # nothing to do
            }
            elsif ( looks_like_number $tbl_copy->[$row][$col] ) {
                if ( $tbl_copy->[$row][$col] =~ /$regex_number/ ) {
                    if ( ( length $1 // 0 ) > $w_int->[$col] ) {
                        $w_int->[$col] = length $1;
                    }
                    if ( ( length $2 // 0 ) > $w_fract->[$col] ) {
                        $w_fract->[$col] = length $2;
                    }
                }
                else {
                    # scientific notation, NaN, Inf, Infinity
                    if ( length $tbl_copy->[$row][$col] > $w_cols->[$col] ) {
                        $w_cols->[$col] = length $tbl_copy->[$row][$col];
                    }
                }
            }
            else {
                my $str_w = print_columns( $tbl_copy->[$row][$col] );
                if ( $str_w > $w_cols->[$col] ) {
                    $w_cols->[$col] = $str_w;
                }
            }
        }
        if ( $progress->{count_progress_bars} ) {         #
            if ( $count >= $progress->{next_update} ) {   #
                $progress->update_progress_bar( $count ); #
            }                                             #
            ++$count;                                     #
        }                                                 #
    }
    for my $col ( @col_idx ) {
        if ( $w_int->[$col] + $w_fract->[$col] > $w_cols->[$col] ) {
            $w_cols->[$col] = $w_int->[$col] + $w_fract->[$col];
        }
    }
    unshift @$tbl_copy, $col_names;
    if ( $progress->{count_progress_bars} ) {             #
        $progress->last_update_progress_bar( $count );    #
    }                                                     #
    return $w_col_names, $w_cols, $w_int, $w_fract;
}


sub __calc_avail_col_width {
    my ( $self, $term_w, $tbl_copy, $w_col_names, $w_cols, $w_int, $w_fract ) = @_;
    my $w_cols_calc = [ @{$w_cols} ];
    my $avail_w = $term_w - $self->{tab_w} * $#$w_cols_calc;
    my $sum = sum( @$w_cols_calc );
    if ( $sum < $avail_w ) {

        HEAD: while ( 1 ) {
            my $prev_sum = $sum;
            for my $col ( 0 .. $#$w_col_names ) {
                if ( $w_col_names->[$col] > $w_cols_calc->[$col] ) {
                    ++$w_cols_calc->[$col];
                    ++$sum;
                    if ( $sum == $avail_w ) {
                        last HEAD;
                    }
                }
            }
            if ( $sum == $prev_sum ) {
                last HEAD;
            }
        }
    }
    elsif ( $sum > $avail_w ) {
        if ( $self->{trunc_fract_first} ) {

            TRUNC_FRACT: while ( $sum > $avail_w ) {
                my $prev_sum = $sum;
                for my $col ( 0 .. $#$w_cols_calc ) {
                    if (   $w_fract->[$col] && $w_fract->[$col] > 3 # 3 == 1 decimal separator + 2 decimal places
                       #&& $w_int->[$col] + $w_fract->[$col] == $w_cols_calc->[$col] #
                       ## the column width could be larger than w_int + w_fract, if the column contains non-digit strings
                    ) {
                        --$w_fract->[$col];
                        --$w_cols_calc->[$col];
                        --$sum;
                        if ( $sum == $avail_w ) {
                            last TRUNC_FRACT;
                        }
                    }
                }
                if ( $sum == $prev_sum ) {
                    last TRUNC_FRACT;
                }
            }
        }
        my $min_col_width = $self->{min_col_width} < 2 ? 2 : $self->{min_col_width}; # n
        my $percent = 4;

        TRUNC_COLS: while ( $sum > $avail_w ) {
            ++$percent;
            for my $col ( 0 .. $#$w_cols_calc ) {
                if ( $w_cols_calc->[$col] > $min_col_width ) {
                    my $reduced_col_w = _minus_x_percent( $w_cols_calc->[$col], $percent );
                    if ( $reduced_col_w < $min_col_width ) {
                        $reduced_col_w = $min_col_width;
                    }
                    if ( $w_fract->[$col] > 2 ) {
                        $w_fract->[$col] -= $w_cols_calc->[$col] - $reduced_col_w;
                        if ( $w_fract->[$col] < 2 ) {
                            $w_fract->[$col] = 2;
                        }
                    }
                    #if ( $w_fract->[$col] > 0 ) {
                    #     $w_fract->[$col] -= $w_cols_calc->[$col] - $reduced_col_w;
                    #     if ( $w_fract->[$col] < 1 ) {
                    #         $w_fract->[$col] = "0 but true";
                    #         # keep it true eaven if it is 0 for __cols_to_string to work properly.
                    #     }
                    #}
                    $w_cols_calc->[$col] = $reduced_col_w;
                }
            }
            my $prev_sum = $sum;
            $sum = sum( @$w_cols_calc );
            if ( $sum == $prev_sum ) {
                --$min_col_width;
                if ( $min_col_width == 2 ) { # a character could have a print width of 2
                    $self->__print_term_not_wide_enough_message( $tbl_copy );
                    return;
                }
            }
        }
        my $remainder_w = $avail_w - $sum;
        if ( $remainder_w ) {

            REMAINDER_W: while ( 1 ) {
                my $prev_remainder_w = $remainder_w;
                for my $col ( 0 .. $#$w_cols_calc ) {
                    if ( $w_cols_calc->[$col] < $w_cols->[$col] ) {
                        ++$w_cols_calc->[$col];
                        --$remainder_w;
                        if ( $remainder_w == 0 ) {
                            last REMAINDER_W;
                        }
                    }
                }
                if ( $remainder_w == $prev_remainder_w ) {
                    last REMAINDER_W;
                }
            }
        }
    }
    #else {
    #    #$sum == $avail_w, nothing to do
    #}
    return $w_cols_calc;
}

sub __cols_to_string {
    my ( $self, $tbl_orig, $tbl_copy, $w_cols_calc, $w_fract, $const, $progress ) = @_;
    my $count = $progress->set_progress_bar();            #
    my $tab = ( ' ' x int( $self->{tab_w} / 2 ) ) . '|' . ( ' ' x int( $self->{tab_w} / 2 ) );
    my $regex_number = $const->{regex_number};
    my $one_precision_w = length sprintf "%.1e", 123;

    ROW: for my $row ( 0 .. $#{$tbl_copy} ) {
        my $str = '';
        COL: for my $col ( 0 .. $#{$w_cols_calc} ) {
            if ( ! length $tbl_copy->[$row][$col] ) {
                $str = $str . ' ' x $w_cols_calc->[$col];
            }
            elsif ( looks_like_number $tbl_copy->[$row][$col] ) {
                my $number = '';
                if ( $w_fract->[$col] ) {
                    my $fract = '';
                    if ( $tbl_copy->[$row][$col] =~ /$regex_number/ ) {
                        if ( length $2 ) {
                            if ( length $2 > $w_fract->[$col] ) {
                                $fract = substr( $2, 0, $w_fract->[$col] );
                            }
                            elsif ( length $2 < $w_fract->[$col] ) {
                                $fract = $2 . ' ' x ( $w_fract->[$col] - length $2 );
                            }
                            else {
                                $fract = $2;
                            }
                        }
                        else {
                            $fract = ' ' x $w_fract->[$col];
                        }
                        $number = ( length $1 ? $1 : '' ) . $fract;
                    }
                    else {
                        # scientific notation, NaN, Inf, Infinity, '0 but true'
                        $number = $tbl_copy->[$row][$col];
                    }
                }
                else {
                    $number = $tbl_copy->[$row][$col];
                }
                if ( length $number > $w_cols_calc->[$col] ) {
                    my $signed_1_precision_w = $one_precision_w + ( $number =~ /^-/ ? 1 : 0 );
                    my $precision;
                    if ( $w_cols_calc->[$col] < $signed_1_precision_w ) {
                        # special treatment because zero precision has no dot
                        $precision = 0;
                    }
                    else {
                        $precision = $w_cols_calc->[$col] - ( $signed_1_precision_w - 1 );
                    }
                    $number = sprintf "%.*e", $precision, $number;
                    # if $number is a scientific-notation-string which is to big for a conversation to a number
                    # 'sprintf' returns 'Inf' instead of reducing the precision.
                    if ( length( $number ) > $w_cols_calc->[$col] ) {
                        $str = $str . ( '-' x $w_cols_calc->[$col] );
                    }
                    elsif ( length $number < $w_cols_calc->[$col] ) {
                        # if $w_cols_calc->[$col] == zero_precision_w + 1 or if $number == Inf
                        $str = $str . ' ' x ( $w_cols_calc->[$col] - length $number ) . $number;
                    }
                    else {
                        $str = $str . $number;
                    }
                }
                elsif ( length $number < $w_cols_calc->[$col] ) {
                    $str = $str . ' ' x ( $w_cols_calc->[$col] - length $number ) . $number;
                }
                else {
                    $str = $str . $number;
                }
            }
            else {
                my $str_w = print_columns( $tbl_copy->[$row][$col] );
                if ( $str_w > $w_cols_calc->[$col] ) {
                    $str = $str . cut_to_printwidth( $tbl_copy->[$row][$col], $w_cols_calc->[$col] );
                }
                elsif ( $str_w < $w_cols_calc->[$col] ) {
                    $str =  $str . $tbl_copy->[$row][$col] . ' ' x ( $w_cols_calc->[$col] - $str_w );
                }
                else {
                    $str = $str . $tbl_copy->[$row][$col];
                }
            }
            if ( $self->{color} ) {
                if ( defined $tbl_orig->[$row][$col] ) {
                    my @color = $tbl_orig->[$row][$col] =~ /(${\SGR_ES})/g;
                    if ( @color ) {
                        $str =~ s/${\PH}/shift @color/ge;
                        $str .= "\e[0m";
                    }
                    #if ( @color ) {
                    #    if ( $color[-1] !~ /^\e\[0?m/ ) {
                    #        push @color, "\e[0m";
                    #    }
                    #    $str =~ s/${\PH}/shift @color/ge;
                    #    if ( @color ) {
                    #        $str .= $color[-1];
                    #    }
                    #}
                }
            }
            if ( $col != $#$w_cols_calc ) {
                $str = $str . $tab;
            }
        }
        $tbl_copy->[$row] = $str;   # overwrite $tbl_copy to save memory
        if ( $progress->{count_progress_bars} ) {         #
            if ( $count >= $progress->{next_update} ) {   #
                $progress->update_progress_bar( $count ); #
            }                                             #
            ++$count;                                     #
        }                                                 #
    }
    if ( $progress->{count_progress_bars} ) {             #
        $progress->last_update_progress_bar( $count );    #
    }                                                     #
    return $tbl_copy; # $tbl_copy is now $tbl_print
}


sub __print_single_row {
    my ( $self, $tbl_orig, $row, $w_col_names, $footer ) = @_;
    my $term_w = get_term_width();
    my $max_key_w = max( @{$w_col_names} ) + 1;
    if ( $max_key_w > int( $term_w / 3 ) ) {
        $max_key_w = int( $term_w / 3 );
    }
    my $separator = ' : ';
    my $sep_w = length( $separator );
    my $max_value_w = $term_w - ( $max_key_w + $sep_w + 1 );
    my $separator_row = ' ';
    my $row_data = [ ' Close with ENTER' ];

    for my $col ( 0 .. $#{$tbl_orig->[0]} ) {
        push @$row_data, $separator_row;
        my $key = $tbl_orig->[0][$col] // $self->{undef};
        my @key_color;
        if ( $self->{color} ) {
            $key =~ s/${\PH}//g;
            $key =~ s/(${\SGR_ES})/push( @key_color, $1 ) && ${\PH}/ge;
        }
        if ( $self->{binary_filter} && substr( $key, 0, 100 ) =~ /[\x00-\x08\x0B-\x0C\x0E-\x1F]/ ) {
            if ( $self->{binary_filter} == 2 ) {
                ( $key = sprintf("%v02X", $tbl_orig->[0][$col] // $self->{undef} ) ) =~ tr/./ /;
            }
            else {
                $key = $self->{binary_string};
            }
            if ( @key_color ) {
                @key_color = ();
            }
        }
        $key =~ s/\t/ /g;
        $key =~ s/\v+/\ \ /g;
        $key =~ s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]//g;
        my $key_w = print_columns( $key );
        if ( $key_w > $max_key_w ) {
            $key = cut_to_printwidth( $key, $max_key_w );
        }
        elsif ( $key_w < $max_key_w ) {
            $key = ( ' ' x ( $max_key_w - $key_w ) ) . $key;
        }
        if ( @key_color ) {
            $key =~ s/${\PH}/shift @key_color/ge;
            $key .= "\e[0m";
        }
        my $value = $tbl_orig->[$row][$col];
        # $value: color and invalid char handling in `line_fold`
        if ( ! length $value ) {
            $value = ' '; # to show also keys/columns with no values
        }
        if ( ref $value ) {
            $value = _handle_reference( $value );
        }
        my $subseq_tab = ' ' x ( $max_key_w + $sep_w );
        my $count;

        for my $line ( line_fold( $value, $max_value_w, { join => 0, color => $self->{color}, binary_filter => $self->{binary_filter} } ) ) {
            if ( ! $count++ ) {
                push @$row_data, $key . $separator . $line;
            }
            else {
                push @$row_data, $subseq_tab . $line;
            }
        }
    }
    my $regex = qr/^\Q$separator_row\E\z/;
    # Choose
    choose(
        $row_data,
        { prompt => '', layout => 2, clear_screen => 1, mouse => $self->{mouse}, hide_cursor => 0, empty => ' ',
          search => $self->{search}, skip_items => $regex, footer => $footer, page => $self->{page},
          color => $self->{color} }
    );
}


sub __search {
    my ( $self, $tbl_orig, $const, $search ) = @_;
    if ( ! $self->{search} ) {
        return;
    }
    require Term::Form::ReadLine;
    Term::Form::ReadLine->VERSION(0.544);
    my $term = Term::Form::ReadLine->new();
    my $error_message;
    my $prompt = "> \e[4msearch\e[0m: ";
    my $default = '';

    READ: while ( 1 ) {
        my $string = $term->readline(
            $prompt,
            { info => $error_message, hide_cursor => 2, clear_screen => defined $error_message ? 1 : 2,
              default => $default, color => 1 }
        );
        if ( ! length $string ) {
            return;
        }
        print "\r${prompt}${string}";
        if ( ! eval {
            $search->{filter} = $self->{search} == 1 ? "(?i:$string)" : $string;
            'Teststring' =~ $search->{filter};
            1
        } ) {
            $default = $default eq $string ? '' : $string;
            $error_message = "$@";
            next READ;
        }
        last READ;
    }
    no warnings 'uninitialized';
    my @col_idx = ( 0 .. $#{$tbl_orig->[0]} );
    # begin: "1" to skipp the header row
    # end: "data_row_count" as it its because +1 for the header row and -1 to get the 0-based index
    for my $idx_row ( 1 .. $const->{data_row_count} ) {
        for ( @col_idx ) {
            if ( $tbl_orig->[$idx_row][$_] =~ /$search->{filter}/ ) {
                push @{$search->{map_indexes}}, $idx_row;
                last;
            }
        }
    }
    if ( ! @{$search->{map_indexes}} ) {
        my $message = '/' . $search->{filter} . '/: No matches found.';
        # Choose
        choose(
            [ 'Continue with ENTER' ],
            { prompt => $message, layout => 0, clear_screen => 1, hide_cursor => 0 }
        );
        $search->{filter} = '';
        return;
    }
    return;
}


sub __reset_search {
    my ( $self, $search ) = @_;
    $search->{map_indexes} = [];
    $search->{filter} = '';
}


sub __header_sep {
    my ( $self, $w_cols_calc ) = @_;
    my $tab = ( '-' x int( $self->{tab_w} / 2 ) ) . '|' . ( '-' x int( $self->{tab_w} / 2 ) );
    my $header_sep = '';
    for my $col ( 0 .. $#$w_cols_calc ) {
        $header_sep .= '-' x $w_cols_calc->[$col];
        if ( $col != $#$w_cols_calc ) {
            $header_sep .= $tab;
        }
    }
    return $header_sep;
}


sub _handle_reference {
    require Data::Dumper;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Maxdepth = 2;
    return Data::Dumper::Dumper( $_[0] );
}


sub __print_term_not_wide_enough_message {
    my ( $self, $tbl_copy ) = @_;
    my $prompt_1 = 'To many columns - terminal window is not wide enough.';
    # Choose
    choose(
        [ 'Press ENTER to show the column names.' ],
        { prompt => $prompt_1, clear_screen => 1, mouse => $self->{mouse}, hide_cursor => 0 }
    );
    my $prompt_2 = 'Column names (close with ENTER).';
    # Choose
    choose(
        $tbl_copy->[0],
        { prompt => $prompt_2, clear_screen => 1, mouse => $self->{mouse}, hide_cursor => 0, search => $self->{search} }
    );
}


sub _minus_x_percent {
    #my ( $value, $percent ) = @_;
    return int( $_[0] - ( $_[0] / 100 * $_[1] ) ) || 1;
}








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::TablePrint - Print a table to the terminal and browse it interactively.

=head1 VERSION

Version 0.163

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
on which it is located. The user can scroll through the table with the different cursor keys.

=head2 KEYS

Keys to move around:

=over

=item *

the C<ArrowDown> key (or the C<j> key) to move down and  the C<ArrowUp> key (or the C<k> key) to move up.

=item *

the C<PageUp> key (or C<Ctrl-P>) to go to the previous page, the C<PageDown> key (or C<Ctrl-N>) to go to the next page.

=item *

the C<Insert> key to go back 10 pages, the C<Delete> key to go forward 10 pages.

=item *

the C<Home> key (or C<Ctrl-A>) to jump to the first row of the table, the C<End> key (or C<Ctrl-E>) to jump to the last
row of the table.

=back

If I<table_expand> is set to C<0>, the C<Return> key closes the table if the cursor is on the first row.

If I<table_expand> is enabled and the cursor is on the first row, pressing C<Return> three times in succession closes
the table. If the cursor is auto-jumped to the first row, it is required only one C<Return> to close the table.

If the cursor is not on the first row:

=over

=item *

with the option I<table_expand> disabled the cursor jumps to the table head if C<Return> is pressed.

=item *

with the option I<table_expand> enabled each column of the selected row is output in its own line preceded by the
column name if C<Return> is pressed. Another C<Return> closes this output and goes back to the table output. If a row is
selected twice in succession, the pointer jumps to the first row.

=back

If the size of the window has changed, the screen is rewritten as soon as the user presses a key.

C<Ctrl-F> opens a prompt. A regular expression is expected as input. This enables one to only display rows where at
least one column matches the entered pattern. See option L</search>.

=head2 Output

If the option L</table_expand> is enabled and a row is selected with C<Return>, each column of that row is output in its
own line preceded by the column name.

If the table has more rows than the terminal, the table is divided up on as many pages as needed automatically. If the
cursor reaches the end of a page, the next page is shown automatically until the last page is reached. Also if the
cursor reaches the topmost line, the previous page is shown automatically if it is not already the first page.

For the output on the screen the table elements are modified. All the modifications are made on a copy of the original
table data.

=over

=item *

If an element is not defined the value from the option I<undef> is assigned to that element.

=item *

Each character tabulation (C<\t>) is replaces with a space.

=item *

Vertical tabulations (C<\v+>) are squashed to two spaces.

=item *

Code points from the ranges of C<control>, C<surrogate> and C<noncharacter> are removed.

=item *

If the option I<squash_spaces> is enabled leading and trailing spaces are removed and multiple consecutive spaces are
squashed to a single space.

=item *

If an element looks like a number it is right-justified, else it is left-justified.

=back

If the terminal is too narrow to print the table, the columns are adjusted to the available width automatically.

=over

=item *

First, if the option I<trunc_fract_first> is enabled and if there are numbers that have a fraction, the fraction is
truncated up to two decimal places.

=item *

Then columns wider than I<min_col_width> are trimmed. See option L</min_col_width>.

=item *

If it is still required to lower the row width all columns are trimmed until they fit into the terminal.

=back

=head1 METHODS

=head2 new

The C<new> method returns a C<Term::TablePrint> object. As an argument it can be passed a reference to a hash which
holds the options - the available options are listed in L</OPTIONS>.

    my $tp = Term::TablePrint->new( \%options );

=head2 print_table

The C<print_table> method prints the table passed with the first argument.

    $tp->print_table( $array_ref, \%options );

The first argument is a reference to an array of arrays. The first array of these arrays holds the column names. The
following arrays are the table rows where the elements are the field values.

As a second and optional argument a hash reference can be passed which holds the options - the available options are
listed in L</OPTIONS>.

=head1 SUBROUTINES

=head2 print_table

The C<print_table> subroutine prints the table passed with the first argument.

    print_table( $array_ref, \%options );

The subroutine C<print_table> takes the same arguments as the method L</print_table>.

=head2 OPTIONS

=head3 binary_filter

How to print arbitrary binary data:

0 - print the binary data as it is

1 - "BNRY" is printed instead of the binary data

2 - the binary data is printed in hexadecimal format

If the substring of the first 100 characters of the data matches the repexp C</[\x00-\x08\x0B-\x0C\x0E-\x1F]/>, the data
is considered arbitrary binary data.

Printing unfiltered arbitrary binary data could break the output.

Default: 0

=head3 codepage_mapping

This option has only meaning if the operating system is MSWin32.

If the OS is MSWin32, L<Win32::Console::ANSI> is used. By default C<Win32::Console::ANSI> converts the characters from
Windows code page to DOS code page (the so-called ANSI to OEM conversion). This conversation is disabled by default in
C<Term::Choose> but one can enable it by setting this option.

Setting this option to C<1> enables the codepage mapping offered by L<Win32::Console::ANSI>.

0 - disable automatic codepage mapping

1 - keep automatic codepage mapping

Default: 0

=head3 color

Enable the support for ANSI SGR escape sequences.

0 - off (default)

1 - enabled except for the current selected row

2 - enabled

Colors are reset to normal after the end of each table field.

Numbers with added escape sequences are aligned to the left.

Default: 0

=head3 decimal_separator

Set the decimal separator. Numbers with a decimal separator are formatted as number if this option is set to the right
value.

Allowed values: a character with a print width of C<1>. If an invalid values is passed, I<decimal_separator> falls back
to the default value.

Default: . (dot)

=head3 footer

If set (string), I<footer> is added in the bottom line to the page number. It is up to the user to add leading and
trailing separators.

If a footer string is passed with this option, the option I<page> is automatically set to C<2>.

Default: undef

=head3 info

Expects as its value a string. The info text is printed above the prompt string.

Default: undef

=head3 max_rows

Set the maximum number of used table rows. The used table rows are kept in memory.

To disable the automatic limit set I<max_rows> to 0.

If the number of table rows is higher than I<max_rows>, the last row of the output tells that the limit has been
reached.

Default: 0

=head3 min_col_width

The columns with a width below or equal I<min_col_width> are only trimmed, if it is still required to lower the row width
despite all columns wider than I<min_col_width> have been trimmed to I<min_col_width>.

Default: 30

=head3 mouse

Set the I<mouse> mode (see option C<mouse> in L<Term::Choose/OPTIONS>).

Default: 0

=head3 progress_bar

Set the progress bar threshold. If the number of fields (rows x columns) is higher than the threshold, a progress bar is
shown while preparing the data for the output.

Default: 40_000

=head3 prompt

String displayed above the table.

=head3 search

Set the behavior of C<Ctrl-F>.

0 - off

1 - case-insensitive search

2 - case-sensitive search

When C<Ctrl-F> is pressed and a regexp is entered, the regexp is appended to the end of the footer.

Default: 1

=head3 squash_spaces

If I<squash_spaces> is enabled, consecutive spaces are squashed to one space and leading and trailing spaces are
removed.

Default: 0

=head3 tab_width

Set the number of spaces between columns.

Default: 2

=head3 table_expand

If the option I<table_expand> is enabled and C<Return> is pressed, the selected table row is printed with
each column in its own line. Exception: if the cursor auto-jumped to the first row, the first row will not be expanded.

If I<table_expand> is set to 0, the cursor jumps to the to first row (if not already there) when C<Return> is pressed.

0 - off

1 - on

Default: 1

=head3 trunc_fract_first

If the terminal width is not wide enough and this option is enabled, the first step to reduce the width of the columns
is to truncate the fraction part of numbers to 2 decimal places.

=head3 undef

Set the string that will be shown on the screen instead of an undefined field.

Default: "" (empty string)

=head1 ERROR HANDLING

C<print_table> croaks

=over

=item

if an invalid number of arguments is passed.

=item

if an invalid argument is passed.

=item

if an unknown option name is passed.

=item

if an invalid option value is passed.

=back

=head1 REQUIREMENTS

=head2 Perl version

Requires Perl version 5.10.0 or greater.

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

Copyright 2013-2024 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
