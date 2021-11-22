package Term::TablePrint;

use warnings;
use strict;
use 5.10.0;

our $VERSION = '0.149';
use Exporter 'import';
our @EXPORT_OK = qw( print_table );

use Carp qw( croak );

use List::Util   qw( sum max );
use Scalar::Util qw( looks_like_number );

use Term::Choose                  qw( choose );
use Term::Choose::Constants       qw( WIDTH_CURSOR );
use Term::Choose::LineFold        qw( line_fold cut_to_printwidth print_columns );
use Term::Choose::Screen          qw( hide_cursor show_cursor );
use Term::Choose::ValidateOptions qw( validate_options );
use Term::Choose::Util            qw( get_term_width insert_sep unicode_sprintf );
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
        choose_columns    => '[ 0 1 ]',   # removed 04.06.2021
        keep_header       => '[ 0 1 ]',   # removed 04.06.2021
        f3                => '[ 0 1 2 ]', # renamed 20.08.2021
        grid              => '[ 0 1 2 ]', # removed 04.06.2021
        table_name        => 'Str',       # renamed 24.06.2021

        binary_filter     => '[ 0 1 ]',
        codepage_mapping  => '[ 0 1 ]',
        hide_cursor       => '[ 0 1 ]', # documentation
        mouse             => '[ 0 1 ]',
        squash_spaces     => '[ 0 1 ]',
        trunc_fract_first => '[ 0 1 ]',
        color             => '[ 0 1 2 ]',
        page              => '[ 0 1 2 ]', # undocumented
        search            => '[ 0 1 2 ]', #
        table_expand      => '[ 0 1 2 ]', # '[ 0 1 ]',  04.06.2021
        keep              => '[ 1-9 ][ 0-9 ]*', # undocumented
        max_rows          => '[ 0-9 ]+',
        min_col_width     => '[ 0-9 ]+', ##
        progress_bar      => '[ 0-9 ]+',
        tab_width         => '[ 0-9 ]+',
        binary_string     => 'Str',
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
        choose_columns    => 0, # removed 04.06.2021
        codepage_mapping  => 0,
        color             => 0,
        decimal_separator => '.',
        footer            => undef,
        grid              => 1, # removed 04.06.2021
        hide_cursor       => 1,
        info              => undef,
        keep              => undef,
        keep_header       => 1, # removed 04.06.2021
        max_rows          => 200000,
        min_col_width     => 30,
        mouse             => 0,
        page              => 2, ##
        progress_bar      => 40000,
        prompt            => '',
        search            => 1,
        squash_spaces     => 0,
        tab_width         => 2,
        table_expand      => 1,
        table_name        => undef,
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
        ###############################################################################################
        my @removed = qw( choose_columns f3 keep_header grid table_name );
        my @message;
        for my $r ( @removed ) {
            if ( exists $opt->{$r} ) {
                push @message, "The option '$r' has been removed or renamed.";
                delete $opt->{$r};
            }
        }
        if ( @message ) {
            unshift @message, "'print_table':";
            push @message, "Upgrade 'App::DBBrowser' to the latest version.";
            my $prompt = join "\n", @message;
            choose(
                [ 'Continue with ENTER' ],
                { prompt => $prompt, layout => 0, clear_screen => 1 }
            );
            print hide_cursor;
        }
        ###############################################################################################
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
    }
    if ( ! @$tbl_orig ) {
        # Choose
        choose(
            [ 'Close with ENTER' ],
            { prompt => "'print_table': empty table without header row!", hide_cursor => 0 }
        );
        $self->__reset();
        return;
    }
    my $data_row_count = @$tbl_orig - 1;
    my $info_row = '';
    if ( $self->{max_rows} && $data_row_count >= $self->{max_rows} ) {
        $info_row = sprintf( 'Reached the row LIMIT %s', insert_sep( $self->{max_rows}, $self->{thsd_sep} ) );
        # App::DBBrowser: $table_rows_count already cut to $self->{max_rows} so total rows are not known at this point.
        # Therefore add 'total' only if $table_rows_count > $self->{max_rows}
        if ( $data_row_count > $self->{max_rows} ) {
            $info_row .= sprintf( '  (total %s)', insert_sep( $data_row_count, $self->{thsd_sep} ) );
        }
        $data_row_count = $self->{max_rows};
    }
    my $progress = Term::TablePrint::ProgressBar->new( {
        data_row_count => $data_row_count,
        col_count => scalar @{$tbl_orig->[0]},
        threshold => $self->{progress_bar},
        count_progress_bars => 3,
    } );

    my $tbl_copy = $self->__copy_table( $tbl_orig, $progress );
    my $ds = quotemeta( $self->{decimal_separator} );
    #my $regex_digits = qr/^([-+]?[0-9]*)($ds[0-9]+)?\z/; # slower
    my $regex_digits = "^([-+]?[0-9]*)(${ds}[0-9]+)?\\z";
    my ( $w_head, $w_cols, $w_int, $w_fract ) = $self->__calc_col_width( $tbl_copy, $progress, $regex_digits );
    my $cc = {  # These values don't change.
        extra_w        => $^O eq 'MSWin32' || $^O eq 'cygwin' ? 0 : WIDTH_CURSOR,
        regex_digits   => $regex_digits,
        data_row_count => $data_row_count,
        info_row       => $info_row,
        w_head         => $w_head,
        w_cols         => $w_cols,
        w_int          => $w_int,
        w_fract        => $w_fract,
    };
    my $vw = { # These values change when the screen width changes. The values have to survive the write_table loops.
        term_w      => 0,
        tbl_print => [],
        header      => [],
        table_w     => 0,
        w_cols_calc => [],
    };
    my $vs = {  # These values change when Ctrl-F is pressed
        filter => '',
        map_indexes => [],
    };
    my $mr = { # Map `__write_table` return values
        last                         => 0,
        window_width_changed         => 1,
        enter_search_string          => 2,
        returned_from_filtered_table => 3,
    };
    my $next;

    WRITE_TABLE: while ( 1 ) {
        if ( defined $next ) {
            $progress = Term::TablePrint::ProgressBar->new( {
                data_row_count => $data_row_count,
                col_count => scalar @{$tbl_orig->[0]},
                threshold => $self->{progress_bar},
                count_progress_bars => 2,
            } );
        }
        $next = $self->__write_table( $tbl_orig, $tbl_copy, $cc, $vs, $vw, $mr, $progress );
        if ( ! defined $next ) {
            die;
        }
        elsif ( $next == $mr->{last} ) {
            last WRITE_TABLE;
        }
        elsif ( $next == $mr->{window_width_changed} ) {
            next WRITE_TABLE;
        }
        elsif ( $next == $mr->{enter_search_string} ) {
            $self->__search( $tbl_orig, $cc, $vs );
            next WRITE_TABLE;
        }
        elsif ( $next == $mr->{returned_from_filtered_table} ) {
            $self->__reset_search( $vs );
            next WRITE_TABLE;
        }
    }
    $self->__reset();
    return;
}


sub __write_table {
    my ( $self, $tbl_orig, $tbl_copy, $cc, $vs, $vw, $mr, $progress ) = @_;
    if ( ! $vw->{term_w} || $vw->{term_w} != get_term_width() + $cc->{extra_w} ) {
        if ( $vw->{term_w} ) {
            # If term_w is set, __write_table has been called more than once and $tbl_copy has been overwritten.
            $tbl_copy = $self->__copy_table( $tbl_orig, $progress );
        }
        $vw->{term_w} = get_term_width() + $cc->{extra_w};
        $vw->{w_cols_calc} = $self->__calc_avail_col_width( $tbl_copy, $cc, $vw );
        if ( ! defined $vw->{w_cols_calc} ) {
            return $mr->{last};
        }
        $vw->{table_w} = sum( @{$vw->{w_cols_calc}}, $self->{tab_w} * $#{$vw->{w_cols_calc}} );
        $vw->{tbl_print} = $self->__cols_to_string( $tbl_orig, $tbl_copy, $cc, $vw, $progress );
        $vw->{header} = [];
        if ( length $self->{prompt} ) {
            push @{$vw->{header}}, $self->{prompt};
        }
        if ( length $self->{info} || length $self->{prompt} ) {
            push @{$vw->{header}}, $self->__header_sep( $vw );
        }
        my $col_names = shift @{$vw->{tbl_print}};
        push @{$vw->{header}}, $col_names, $self->__header_sep( $vw );
        if ( $cc->{info_row} ) {
            if ( print_columns( $cc->{info_row} ) > $vw->{table_w} ) {
                push @{$vw->{tbl_print}}, cut_to_printwidth( $cc->{info_row}, $vw->{table_w} - 3 ) . '...';
            }
            else {
                push @{$vw->{tbl_print}}, $cc->{info_row};
            }
        }
    }
    my @idxs_tbl_print;
    my $return = $mr->{last};
    if ( $vs->{filter} ) {
        @idxs_tbl_print = map { $_ - 1 } @{$vs->{map_indexes}}; # because of the removed header row from tbl_print
        $return = $mr->{returned_from_filtered_table};
    }
    my $prompt = join( "\n", @{$vw->{header}} );
    my $footer;
    if ( $self->{footer} ) {
        $footer = $self->{footer};
        if ( $vs->{filter} ) {
            $footer .= '/' . $vs->{filter} . '/';
        }
    }
    my $old_row = exists $ENV{TC_POS_AT_SEARCH} && ! $vs->{filter} ? delete( $ENV{TC_POS_AT_SEARCH} ) : 0;
    my $auto_jumped_to_first_row = 2;
    my $row_is_expanded = 0;

    while ( 1 ) {
        if ( $vw->{term_w} != get_term_width() + $cc->{extra_w} ) {
            return $mr->{window_width_changed};
        }
        if ( ! @{$vw->{tbl_print}} ) {
            push @{$vw->{tbl_print}}, ''; # so that going back requires always the same amount of keystrokes
        }
        $ENV{TC_RESET_AUTO_UP} = 0;
        # Choose
        my $row = choose(
            @idxs_tbl_print ? [ @{$vw->{tbl_print}}[@idxs_tbl_print] ]
                            :     $vw->{tbl_print},
            { info => $self->{info}, prompt => $prompt, index => 1, default => $old_row, ll => $vw->{table_w},
              layout => 2, clear_screen => 1, mouse => $self->{mouse}, hide_cursor => 0, footer => $footer,
              color => $self->{color}, codepage_mapping => $self->{codepage_mapping}, search => $self->{search},
              keep => $self->{keep}, page => $self->{page} }
        );
        if ( ! defined $row ) {
            return $return;
        }
        elsif ( $row < 0 ) {
            if ( $row == -1 ) { # with option `ll` set and changed window width `choose` returns -1;
                return $mr->{window_width_changed};
            }
            elsif ( $row == -13 ) { # with option `ll` set `choose` returns -13 if `Ctrl-F` was pressed
                if ( $vs->{filter} ) {
                    $self->__reset_search( $vs );
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
            if ( $cc->{info_row} && $row == $#{$vw->{tbl_print}} ) {
                # Choose
                choose(
                    [ 'Close' ],
                    { prompt => $cc->{info_row}, clear_screen => 1, mouse => $self->{mouse}, hide_cursor => 0 }
                );
                next;
            }
            my $orig_row;
            if ( @{$vs->{map_indexes}} ) {
                $orig_row = $vs->{map_indexes}[$row];
            }
            else {
                $orig_row = $row + 1; # because $tbl_print has no header row while $tbl_orig has a header row
            }
            $self->__print_single_row( $tbl_orig, $cc, $orig_row, $footer );
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
                $str =~ s/\x{feff}//g;
                $str =~ s/\e\[[\d;]*m/\x{feff}/g;
            }
            if ( $self->{binary_filter} && substr( $str, 0, 100 ) =~ /[\x00-\x08\x0B-\x0C\x0E-\x1F]/ ) {
                $str = $self->{binary_string};
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
    my ( $self, $tbl_copy, $progress, $regex_digits ) = @_;
    my $count = $progress->set_progress_bar();            #
    my @col_idx = ( 0 .. $#{$tbl_copy->[0]} );
    my $col_count = @col_idx;
    my $w_head = [];
    my $w_cols = [ ( 1 ) x $col_count ];
    my $w_int   = [ ( 0 ) x $col_count ];
    my $w_fract = [ ( 0 ) x $col_count ];
    my $ds = quotemeta( $self->{decimal_separator} );
    my $col_names = shift @$tbl_copy;
    for my $col ( @col_idx ) {
        $w_head->[$col] = print_columns( $col_names->[$col] );
    }

    for my $row ( 0 .. $#$tbl_copy ) {
        for my $col ( @col_idx ) {
            if ( ! length $tbl_copy->[$row][$col] ) {
                # nothing to do
            }
            elsif ( $tbl_copy->[$row][$col] =~ /$regex_digits/ ) {
                if ( defined $1 && length $1 > $w_int->[$col] ) {
                    $w_int->[$col] = length $1;
                }
                if ( defined $2 && length $2 > $w_fract->[$col] ) {
                    $w_fract->[$col] = length $2;
                }
            }
            else {
                my $width = print_columns( $tbl_copy->[$row][$col] );
                if ( $width > $w_cols->[$col] ) {
                    $w_cols->[$col] = $width;
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
    return $w_head, $w_cols, $w_int, $w_fract;
}


sub __calc_avail_col_width {
    my ( $self, $tbl_copy, $cc, $vw ) = @_;
    my $w_head = [ @{$cc->{w_head}} ];
    my $w_cols_calc = [ @{$cc->{w_cols}} ];
    my $avail_w = $vw->{term_w} - $self->{tab_w} * $#$w_cols_calc;
    my $sum = sum( @$w_cols_calc );
    if ( $sum < $avail_w ) {

        HEAD: while ( 1 ) {
            my $prev_sum = $sum;
            for my $col ( 0 .. $#$w_head ) {
                if ( $w_head->[$col] > $w_cols_calc->[$col] ) {
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
                    if (   $cc->{w_fract}[$col] && $cc->{w_fract}[$col] > 3
                        # 3 == 1 decimal separator + 2 decimal places
                        && $cc->{w_int}[$col] + $cc->{w_fract}[$col] == $w_cols_calc->[$col]
                        # the column width could be larger than w_int + w_fract, if the column contains non-digit strings
                    ) {
                        --$cc->{w_fract}[$col];
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
        my $min_col_width = $self->{min_col_width} < 2 ? 2 : $self->{min_col_width};
        my $percent = 4;

        TRUNC_COLS: while ( $sum > $avail_w ) {
            ++$percent;
            for my $col ( 0 .. $#$w_cols_calc ) {
                if ( $w_cols_calc->[$col] > $min_col_width ) {
                    my $reduced_col_w = _minus_x_percent( $w_cols_calc->[$col], $percent );
                    if ( $reduced_col_w < $min_col_width ) {
                        $w_cols_calc->[$col] = $min_col_width;
                    }
                    else {
                        $w_cols_calc->[$col] = $reduced_col_w;
                    }
                }
            }
            my $prev_sum = $sum;
            $sum = sum( @$w_cols_calc );
            if ( $sum == $prev_sum ) {
                --$min_col_width;
                if ( $min_col_width == 1 ) { # a character could have a print width of 2
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
                    if ( $w_cols_calc->[$col] < $cc->{w_cols}[$col] ) {
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
    #    #$sum == $avail_w
    #}
    return $w_cols_calc;
}


sub __cols_to_string {
    my ( $self, $tbl_orig, $tbl_copy, $cc, $vw, $progress ) = @_;
    my $count = $progress->set_progress_bar();            #
    my $tab = ( ' ' x int( $self->{tab_w} / 2 ) ) . '|' . ( ' ' x int( $self->{tab_w} / 2 ) );
    my $w_cols_calc = $vw->{w_cols_calc};
    my $regex_digits = $cc->{regex_digits};

    ROW: for my $row ( 0 .. $#{$tbl_copy} ) {
        my $str = '';
        COL: for my $col ( 0 .. $#{$w_cols_calc} ) {
            if ( ! length $tbl_copy->[$row][$col] ) {
                $str = $str . ' ' x $w_cols_calc->[$col];
            }
            elsif ( $tbl_copy->[$row][$col] =~ /$regex_digits/ ) {
                my $all = '';
                if ( $cc->{w_fract}[$col] ) {
                    if ( defined $2 ) {
                        if ( length $2 > $cc->{w_fract}[$col] ) {
                            $all = substr( $2, 0, $cc->{w_fract}[$col] );
                        }
                        else {
                            $all = $2 . ' ' x ( $cc->{w_fract}[$col] - length $2 );
                        }
                    }
                    else {
                        $all = ' ' x $cc->{w_fract}[$col];
                    }
                }
                if ( defined $1 ) {
                    $all = $1 . $all;
                }
                if ( length $all > $w_cols_calc->[$col] ) {
                    $str = $str . substr( $all, 0, $w_cols_calc->[$col] );
                }
                else {
                    $str = $str . ' ' x ( $w_cols_calc->[$col] - length $all ) . $all;
                }
            }
            else {
                $str = $str . unicode_sprintf( $tbl_copy->[$row][$col], $w_cols_calc->[$col] );
            }
            if ( $self->{color} ) {
                if ( defined $tbl_orig->[$row][$col] ) {
                    my @color = $tbl_orig->[$row][$col] =~ /(\e\[[\d;]*m)/g;
                    $str =~ s/\x{feff}/shift @color/ge;
                    if ( @color ) {
                        $str = $str . $color[-1];
                    }
                }
            }
            if ( $col != $#$w_cols_calc ) {
                $str = $str . $tab;
            }
        }
        #if ( $self->{color} ) {
        #    $str = $str . RESET; # reset colors after each row
        #}
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
    my ( $self, $tbl_orig, $cc, $row, $footer ) = @_;
    my $term_w = get_term_width();
    my $len_key = max( @{$cc->{w_head}} ) + 1;
    if ( $len_key > int( $term_w / 100 * 33 ) ) {
        $len_key = int( $term_w / 100 * 33 );
    }
    my $separator = ' : ';
    my $len_sep = length( $separator );
    my $col_max = $term_w - ( $len_key + $len_sep + 1 );
    my $separator_row = ' ';
    my $row_data = [ ' Close with ENTER' ];

    for my $col ( 0 .. $#{$tbl_orig->[0]} ) {
        push @$row_data, $separator_row;
        my $key = $tbl_orig->[0][$col];
        if ( ! defined $key ) {
            $key = $self->{undef};
        }
        if ( $self->{color} ) {
            $key =~ s/\e\[[\d;]*m//g;
        }
        $key =~ s/\t/ /g;
        $key =~ s/\v+/\ \ /g;
        $key =~ s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]//g;
        $key = cut_to_printwidth( $key, $len_key );
        my $copy_sep = $separator;
        my $value = $tbl_orig->[$row][$col];
        if ( ! defined $value || ! length $value ) {
            $value = ' '; # to show also keys/columns with no values
        }
        if ( $self->{color} ) {
            $value =~ s/\e\[[\d;]*m//g;
        }
        if ( ref $value ) {
            $value = _handle_reference( $value );
        }
        for my $line ( line_fold( $value, $col_max, { join => 0 } ) ) {
            push @$row_data, sprintf "%*.*s%*s%s", $len_key, $len_key, $key, $len_sep, $copy_sep, $line;
            $key      = '' if $key;
            $copy_sep = '' if $copy_sep;
        }
    }
    my $regex = qr/^\Q$separator_row\E\z/;
    # Choose
    choose(
        $row_data,
        { prompt => '', layout => 2, clear_screen => 1, mouse => $self->{mouse}, hide_cursor => 0,
          search => $self->{search}, skip_items => $regex, footer => $footer, page => $self->{page} }
    );
}


sub __search {
    my ( $self, $tbl_orig, $cc, $vs ) = @_;
    if ( ! $self->{search} ) {
        return;
    }
    require Term::Form;
    Term::Form->VERSION(0.530);
    my $term = Term::Form->new();
    my $error_message;
    my $prompt = '> search-pattern: ';
    my $default = '';

    READ: while ( 1 ) {
        my $string = $term->readline(
            $prompt,
            { info => $error_message, hide_cursor => 2, clear_screen => defined $error_message ? 1 : 2,
              color => $self->{color}, default => $default }
        );
        if ( ! length $string ) {
            return;
        }
        print "\r${prompt}${string}";
        if ( ! eval {
            $vs->{filter} = $self->{search} == 1 ? "(?i)$string" : $string;
            'Teststring' =~ $vs->{filter};
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
    for my $idx_row ( 1 .. $cc->{data_row_count} ) {
        for ( @col_idx ) {
            if ( $tbl_orig->[$idx_row][$_] =~ /$vs->{filter}/ ) {
                push @{$vs->{map_indexes}}, $idx_row;
                last;
            }
        }
    }
    if ( ! @{$vs->{map_indexes}} ) {
        my $message = '/' . $vs->{filter} . '/: No matches found.';
        # Choose
        choose(
            [ 'Continue with ENTER' ],
            { prompt => $message, layout => 0, clear_screen => 1 }
        );
        $vs->{filter} = '';
        return;
    }
    return;
}


sub __reset_search {
    my ( $self, $vs ) = @_;
    $vs->{map_indexes} = [];
    $vs->{filter} = '';
}


sub __header_sep {
    my ( $self, $vw ) = @_;
    my $tab = ( '-' x int( $self->{tab_w} / 2 ) ) . '|' . ( '-' x int( $self->{tab_w} / 2 ) );
    my $header_sep = '';
    my $w_cols_calc= $vw->{w_cols_calc};
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
    return 'ref: ' . Data::Dumper::Dumper( $_[0] );
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

Version 0.149

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

If the option L</table_expand> is enabled and a row is selected with C<Return>, each column of that row is output in its
own line preceded by the column name. This might be useful if the columns were cut due to the too low terminal width.

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

If an element looks like a number it is left-justified, else it is right-justified.

=back

If the terminal width is not wide enough to display all columns:

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

If I<binary_filter> is set to 1, "BNRY" is printed instead of arbitrary binary data.

If the data matches the repexp C</[\x00-\x08\x0B-\x0C\x0E-\x1F]/>, it is considered arbitrary binary data.

Printing arbitrary binary data could break the output.

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

Setting I<color> to C<1> enables the support for color and text formatting escape sequences except for the current
selected element. If set to C<2>, also for the current selected element the color support is enabled (inverted colors).

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

If the number of table rows is equal to or higher than I<max_rows>, the last row of the output tells that the limit has
been reached.

Default: 200_000

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

=head3 table_name RENAMDED

The option I<table_name> has been renamed to I<footer>. Use I<footer> instead of I<table_name>. The I<table_name> will
be removed.

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

Copyright 2013-2021 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
