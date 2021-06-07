package Term::TablePrint;

use warnings;
use strict;
use 5.008003;

our $VERSION = '0.134';
use Exporter 'import';
our @EXPORT_OK = qw( print_table );

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
    die "new: called with " . @_ . " arguments - 0 or 1 arguments expected." if @_ > 1;
    my ( $opt ) = @_;
    my $instance_defaults = _defaults();
    if ( defined $opt ) {
        die "new: The (optional) argument is not a HASH reference." if ref $opt ne 'HASH';
        validate_options( _valid_options(), $opt );
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
        max_rows          => '[ 0-9 ]+',
        min_col_width     => '[ 0-9 ]+',
        progress_bar      => '[ 0-9 ]+',
        tab_width         => '[ 0-9 ]+',
        choose_columns    => '[ 0 1 ]', # removed 04.06.2021
        binary_filter     => '[ 0 1 ]',
        codepage_mapping  => '[ 0 1 ]',
        hide_cursor       => '[ 0 1 ]', # documentation
        keep_header       => '[ 0 1 ]',
        squash_spaces     => '[ 0 1 ]',
        color             => '[ 0 1 2 ]',
        grid              => '[ 0 1 2 ]',
        f3                => '[ 0 1 2 ]',
        table_expand      => '[ 0 1 2 ]', # '[ 0 1 ]',  04.06.2021
        mouse             => '[ 0 1 2 3 4 ]',
        binary_string     => 'Str',
        decimal_separator => 'Str',
        prompt            => 'Str',
        table_name        => 'Str',
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
        f3                => 1,
        grid              => 1,
        hide_cursor       => 1,
        keep_header       => 1,
        squash_spaces     => 0,
        max_rows          => 200000,
        min_col_width     => 30,
        mouse             => 0,
        progress_bar      => 40000,
        prompt            => '',
        tab_width         => 2,
        table_expand      => 1,
        table_name        => undef,
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
    my ( $orig_table, $opt ) = @_;
    die "print_table: called with " . @_ . " arguments - 1 or 2 arguments expected." if @_ < 1 || @_ > 2;
    die "print_table: requires an ARRAY reference as its first argument."            if ref $orig_table  ne 'ARRAY';
    if ( defined $opt ) {
        die "print_table: the (optional) second argument is not a HASH reference."   if ref $opt ne 'HASH';
        validate_options( _valid_options(), $opt );
        for my $key ( keys %$opt ) {
            $self->{$key} = $opt->{$key} if defined $opt->{$key};
        }
    }
    $self->{tab_w} = $self->{tab_width};
    if ( $self->{grid} && ! ( $self->{tab_width} % 2 ) ) {
        ++$self->{tab_w};
    }
    local $| = 1;
    local $SIG{INT} = sub {
        $self->__reset();
        print "\n";
        exit;
    };
    if ( $self->{hide_cursor} ) {
        print hide_cursor();
    }
    if ( ! @$orig_table ) {
        choose(
            [ 'Close with ENTER' ],
            { prompt => "'print_table': empty table without header row!", hide_cursor => 0 }
        );
        $self->__reset();
        return;
    }
    if ( print_columns( $self->{decimal_separator} ) != 1 ) {
        $self->{decimal_separator} = '.';
    }
    if ( $self->{decimal_separator} ne '.' ) {
        $self->{thsd_sep} = '_';
    }
    my $data_row_count = @$orig_table - 1;
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
    if ( $self->{choose_columns} ) { # removed 04.06.2021
        choose( [ 'Continue with ENTER' ], { prompt => "The option 'choose_columns' has been removed.", layout => 0, clear_screen => 1 } );
    }
    my $progress = Term::TablePrint::ProgressBar->new( {
        data_row_count => $data_row_count,
        col_count => scalar @{$orig_table->[0]},
        threshold => $self->{progress_bar},
        count_progress_bars => 3,
    } );

    my $table_copy = $self->__copy_table( $orig_table, $progress );
    my ( $w_head, $w_cols, $w_int, $w_fract ) = $self->__calc_col_width( $table_copy, $progress );
    my $cc = {  # The values don't change.
        extra_w        => $^O eq 'MSWin32' || $^O eq 'cygwin' ? 0 : WIDTH_CURSOR,
        data_row_count => $data_row_count,
        info_row       => $info_row,
        w_head         => $w_head,
        w_cols         => $w_cols,
        w_int          => $w_int,
        w_fract        => $w_fract,
    };
    my $vw = { # The values change when the screen width changes. The values have to survive the write_table loops.
        term_w      => 0,
        print_table => [],
        header      => [],
        table_w     => 0,
        w_cols_calc => [],
    };
    my $vs = {  # The values change when F3 is pressed
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
                col_count => scalar @{$orig_table->[0]},
                threshold => $self->{progress_bar},
                count_progress_bars => 2,
            } );
        }
        $next = $self->__write_table( $orig_table, $table_copy, $cc, $vs, $vw, $mr, $progress );
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
            $self->__search( $orig_table, $cc, $vs );
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
    my ( $self, $orig_table, $table_copy, $cc, $vs, $vw, $mr, $progress ) = @_;
    if ( ! $vw->{term_w} || $vw->{term_w} != get_term_width() + $cc->{extra_w} ) {
        if ( $vw->{term_w} ) {
            # If term_w is set, __write_table has been called more
            # than once, which means that table_copy has been overwritten.
            $table_copy = $self->__copy_table( $orig_table, $progress );
        }
        $vw->{term_w} = get_term_width() + $cc->{extra_w};
        $vw->{w_cols_calc} = $self->__calc_avail_col_width( $table_copy, $cc, $vw );
        if ( ! defined $vw->{w_cols_calc} ) {
            return $mr->{last};
        }
        $vw->{table_w} = sum( @{$vw->{w_cols_calc}}, $self->{tab_w} * $#{$vw->{w_cols_calc}} );
        $vw->{print_table} = $self->__cols_to_string( $orig_table, $table_copy, $cc, $vw, $progress );
        #$self->{info} = 'INFO'; # info info_tabs prompt_tabs
        #$self->{prompt} = 'PROMPT';
        #if ( length $self->{info} ) {
        #    push @{$vw->{header}}, $self->{info};
        #}
        #if ( length $self->{prompt} ) {
        #    push @{$vw->{header}}, $self->{prompt};
        #}
        #if ( length $self->{info} || length $self->{prompt} ) {
        #    push @{$vw->{header}}, $self->__header_sep( $w_cols_calc );
        #    if ( $self->{grid} == 2 ) {
        #        $self->{grid} = 1;
        #    }
        #}
        $vw->{header} = [];
        if ( length $self->{prompt} ) {
            push @{$vw->{header}}, $self->{prompt};
        }
        my $col_names = shift @{$vw->{print_table}};
        my $header_sep = $self->__header_sep( $vw );
        if ( $self->{keep_header} ) {
            if ( $self->{grid} == 1 ) {
                push @{$vw->{header}},              $col_names, $header_sep;
            }
            elsif ( $self->{grid} == 2 ) {
                push @{$vw->{header}}, $header_sep, $col_names, $header_sep;
            }
        }
        else {
            if ( $self->{grid} == 1 ) {
                unshift @{$vw->{print_table}},              $col_names, $header_sep;
            }
            elsif ( $self->{grid} == 2 ) {
                unshift @{$vw->{print_table}}, $header_sep, $col_names, $header_sep;
            }
        }
        if ( $cc->{info_row} ) {
            if ( print_columns( $cc->{info_row} ) > $vw->{table_w} ) {
                push @{$vw->{print_table}}, cut_to_printwidth( $cc->{info_row}, $vw->{table_w} - 3 ) . '...';
            }
            else {
                push @{$vw->{print_table}}, $cc->{info_row};
            }
        }
    }
    my @filtered_idxs_print_table;
    my $return = $mr->{last};
    if ( $vs->{filter} ) {
        if ( $self->{keep_header} ) {
            @filtered_idxs_print_table = map { $_ - 1 } @{$vs->{map_indexes}}; # due to the shifted header row from print_table
        }
        else {
            if ( $self->{grid} ) {
                @filtered_idxs_print_table = map { $_ + $self->{grid} } @{$vs->{map_indexes}}; # due to the following unshifts
                if ( $self->{grid} == 1) {
                    unshift @filtered_idxs_print_table, 0, 1;
                }
                elsif ( $self->{grid} == 2 ) {
                    unshift @filtered_idxs_print_table, 0, 1, 2;
                }
            }
        }
        # __print_single_row: the chosen row-idx was prepared for to use for the $orig_table which has a header row.
        # If filter is active the same row-idx (with the preparation for the $orig_table) is used to select the value
        # from map_indexes, hence the following unshift of 0 (as header row)
        unshift @{$vs->{map_indexes}}, 0;
        $return = $mr->{returned_from_filtered_table};
    }
    my $prompt = join( "\n", @{$vw->{header}} );
    my $footer;
    if ( $self->{table_name} ) {
        $footer = $self->{table_name};
        if ( $vs->{filter} ) {
            $footer .= '   /' . $vs->{filter} . '/';
        }
    }
    my $old_row = 0;
    my $auto_jumped_to_first_row = 2;
    my $row_is_expanded = 0;

    while ( 1 ) {
        if ( $vw->{term_w} != get_term_width() + $cc->{extra_w} ) {
            return $mr->{window_width_changed};
        }
        if ( $self->{keep_header} && ! @{$vw->{print_table}} ) {
            push @{$vw->{print_table}}, ''; # so that going back requires always the same amount of keystrokes
        }
        $ENV{TC_RESET_AUTO_UP} = 0;
        my $row = choose(
            @filtered_idxs_print_table ? [ @{$vw->{print_table}}[@filtered_idxs_print_table] ] : $vw->{print_table},
            { prompt => $prompt, index => 1, default => $old_row, ll => $vw->{table_w}, layout => 3,
              clear_screen => 1, mouse => $self->{mouse}, hide_cursor => 0, footer => $footer,
              color => $self->{color}, codepage_mapping => $self->{codepage_mapping}, f3 => $self->{f3} }
        );
        if ( ! defined $row ) {
            return $return;
        }
        elsif ( $row < 0 ) {
            if ( $row == -1 ) { # with option `ll` set and changed window width `choose` returns -1;
                return $mr->{window_width_changed};
            }
            elsif ( $row == -13 ) { # `choose` returns -13 if `F3` was pressed
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
                    if ( ! $self->{keep_header} ) {
                        return $return;
                    }
                    elsif ( $self->{table_expand} ) {
                        if ( $row_is_expanded ) {
                            return $return;
                        }
                        if ( $auto_jumped_to_first_row == 1 ) { # && $self->{tbl_exp_fast_back} ) {
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
            if ( $cc->{info_row} && $row == $#{$vw->{print_table}} ) {
                choose(
                    [ 'Close' ],
                    { prompt => $cc->{info_row}, clear_screen => 1, mouse => $self->{mouse}, hide_cursor => 0 }
                );
                next;
            }
            if ( $self->{keep_header} ) { # if keep_header: 1. row in $print_table is 2. row in $orig_table
                $row++;                   # because $print_table has the header row shifted to the the prompt line
            }
            else {
                if ( $self->{grid} == 1 ) {
                    if ( $row == 1 ) { # header separator is at pos 1
                        # $row = 0;
                        next;
                    }
                    if ( $row > 1 ) {
                        $row--; # due to the added header separator at pos 1
                    }
                }
                elsif ( $self->{grid} == 2 ) {
                    if ( $row == 0 || $row  == 2 ) { # header separators are at pos 0 and 2
                        #$row = 1;
                        next;
                    }
                    if ( $row == 1 ) { # header row at pos 1
                        $row--; # due to the added header separator at pos 0
                    }
                    else {
                        $row -= 2; # due to the added header separators at pos 0 and 2
                    }
                }
            }
            my $orig_row;
            if ( @{$vs->{map_indexes}} ) {
                $orig_row = $vs->{map_indexes}[$row];
            }
            else {
                $orig_row = $row;
            }
            $self->__print_single_row( $orig_table, $cc, $orig_row, $footer );
        }
        delete $ENV{TC_RESET_AUTO_UP};
    }
}


sub __copy_table {
    my ( $self, $orig_table, $progress ) = @_;
    my $table_copy = [];
    my $count = $progress->set_progress_bar();            #
    ROW: for my $row ( @$orig_table ) {
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
            $str =~ s/[\x{000a}-\x{000d}\x{0085}\x{2028}\x{2029}]+/\ \ /g;
            $str =~ s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]//g;
            push @$tmp_row, $str;
        }
        push @$table_copy, $tmp_row;
        if ( @$table_copy == $self->{max_rows} ) {
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
    return $table_copy
}


sub __calc_col_width {
    my ( $self, $table_copy, $progress ) = @_;
    my $count = $progress->set_progress_bar();            #
    my $w_head  = [];
    my $w_cols  = [ ( 1 ) x @{$table_copy->[0]} ];
    my $w_int   = [ ( 0 ) x @{$table_copy->[0]} ];
    my $w_fract = [ ( 0 ) x @{$table_copy->[0]} ];
    my $ds = quotemeta( $self->{decimal_separator} );
    my @col_idx = ( 0 .. $#{$table_copy->[0]} );
    my $col_names = shift @$table_copy;
    for my $i ( @col_idx ) {
        $w_head->[$i] = print_columns( $col_names->[$i] );
    }
    for my $row ( @$table_copy ) {
        for my $i ( @col_idx ) {
            my $width;
            if ( ! length $row->[$i] ) {
                $width = 0;
            }
            elsif ( $row->[$i] =~/^([-+]?[0-9]*)($ds[0-9]+)?\z/ ) {
                $width = length( $row->[$i] );
                if ( defined $1 && length( $1 ) > $w_int->[$i] ) {
                    $w_int->[$i] = length $1;
                }
                if ( defined $2 && length( $2 ) > $w_fract->[$i] ) {
                    $w_fract->[$i] = length $2;
                }
            }
            else {
                $width = print_columns( $row->[$i] );
            }
            if ( $width > $w_cols->[$i] ) {
                $w_cols->[$i] = $width;
            }
        }
        if ( $progress->{count_progress_bars} ) {         #
            if ( $count >= $progress->{next_update} ) {   #
                $progress->update_progress_bar( $count ); #
            }                                             #
            ++$count;                                     #
        }                                                 #
    }
    unshift @$table_copy, $col_names;
    if ( $progress->{count_progress_bars} ) {             #
        $progress->last_update_progress_bar( $count );    #
    }                                                     #
    return $w_head, $w_cols, $w_int, $w_fract;
}


sub __calc_avail_col_width {
    my ( $self, $table_copy, $cc, $vw ) = @_;
    my $w_head = [ @{$cc->{w_head}} ];
    my $w_cols_calc = [ @{$cc->{w_cols}} ];
    my $avail_w = $vw->{term_w} - $self->{tab_w} * $#$w_cols_calc;
    my $sum = sum( @$w_cols_calc );
    if ( $sum < $avail_w ) {
        # auto cut
        HEAD: while ( 1 ) {
            my $count = 0;
            for my $i ( 0 .. $#$w_head ) {
                if ( $w_head->[$i] > $w_cols_calc->[$i] ) {
                    ++$w_cols_calc->[$i];
                    ++$count;
                    last HEAD if ( $sum + $count ) == $avail_w;
                }
            }
            last HEAD if $count == 0;
            $sum += $count;
        }
        return $w_cols_calc;
    }
    elsif ( $sum > $avail_w ) {
        my $min_width = $self->{min_col_width} || 1;
        if ( @$w_head > $avail_w ) {
            $self->__print_term_not_wide_enough_message( $table_copy );
            return;
        }
        my @w_cols_tmp = @$w_cols_calc;
        my $percent = 0;

        MIN: while ( $sum > $avail_w ) {
            ++$percent;
            my $count = 0;
            for my $i ( 0 .. $#w_cols_tmp ) {
                if ( $min_width >= $w_cols_tmp[$i] ) {
                    next;
                }
                if ( $min_width >= _minus_x_percent( $w_cols_tmp[$i], $percent ) ) {
                    $w_cols_tmp[$i] = $min_width;
                }
                else {
                    $w_cols_tmp[$i] = _minus_x_percent( $w_cols_tmp[$i], $percent );
                }
                ++$count;
            }
            $sum = sum( @w_cols_tmp );
            $min_width-- if $count == 0;
            #last MIN if $min_width == 0;
        }
        my $rest = $avail_w - $sum;
        if ( $rest ) {

            REST: while ( 1 ) {
                my $count = 0;
                for my $i ( 0 .. $#w_cols_tmp ) {
                    if ( $w_cols_tmp[$i] < $w_cols_calc->[$i] ) {
                        $w_cols_tmp[$i]++;
                        $rest--;
                        $count++;
                        last REST if $rest == 0;
                    }
                }
                last REST if $count == 0;
            }
        }
        $w_cols_calc = [ @w_cols_tmp ] if @w_cols_tmp;
    }
    return $w_cols_calc;
}


sub __cols_to_string {
    my ( $self, $orig_table, $table_copy, $cc, $vw, $progress ) = @_;
    my $count = $progress->set_progress_bar();            #
    my $tab;
    if ( $self->{grid} ) {
        $tab = ( ' ' x int( $self->{tab_w} / 2 ) ) . '|' . ( ' ' x int( $self->{tab_w} / 2 ) );
    }
    else {
        $tab = ' ' x $self->{tab_w};
    }
    my $w_cols_calc = $vw->{w_cols_calc};
    for my $col ( 0 .. $#$w_cols_calc ) {
        if ( $w_cols_calc->[$col] - $cc->{w_int}[$col] < $cc->{w_fract}[$col] ) {
            $cc->{w_fract}[$col] = $w_cols_calc->[$col] - $cc->{w_int}[$col];
            $cc->{w_fract}[$col] = 0 if $cc->{w_fract}[$col] < 0;
        }
    }
    my $ds = quotemeta( $self->{decimal_separator} );
    ROW: for my $row ( 0 .. $#{$table_copy} ) {
        my $str = '';
        COL: for my $col ( 0 .. $#{$w_cols_calc} ) {
            if ( ! length $table_copy->[$row][$col] ) {
                $str = $str . ' ' x $w_cols_calc->[$col];
            }
            elsif ( $table_copy->[$row][$col] =~ /^([-+]?[0-9]*)($ds[0-9]+)?\z/ ) {
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
                    if ( $cc->{w_int}[$col] > length $1 ) {
                        $all = ' ' x ( $cc->{w_int}[$col] - length $1 ) . $1 . $all;
                    }
                    else {
                        $all = $1 . $all;
                    }
                }
                if ( length $all > $w_cols_calc->[$col] ) {
                    $str = $str . substr( $all, 0, $w_cols_calc->[$col] );
                }
                else {
                    $str = $str . ' ' x ( $w_cols_calc->[$col] - length $all ) . $all;
                }
            }
            else {
                $str = $str . unicode_sprintf( $table_copy->[$row][$col], $w_cols_calc->[$col] );
            }
            if ( $self->{color} ) {
                my $r = $row;
                if ( defined $orig_table->[$r][$col] ) {
                    my @color = $orig_table->[$r][$col] =~ /(\e\[[\d;]*m)/g;
                    $str =~ s/\x{feff}/shift @color/ge;
                    $str = $str . $color[-1] if @color;
                }
            }
            $str = $str . $tab if $col != $#$w_cols_calc;
        }
        #$str = $str . RESET if $self->{color};
        $table_copy->[$row] = $str;   # overwrite $table_copy to save memory
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
    return $table_copy; # $table_copy is now $print_table
}


sub __print_single_row {
    my ( $self, $orig_table, $cc, $row, $footer ) = @_;
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

    for my $col ( 0 .. $#{$orig_table->[0]} ) {
        push @$row_data, $separator_row;
        my $key = $orig_table->[0][$col];
        if ( ! defined $key ) {
            $key = $self->{undef};
        }
        if ( $self->{color} ) {
            $key =~ s/\e\[[\d;]*m//g;
        }
        $key =~ s/\t/ /g;
        $key =~ s/[\x{000a}-\x{000d}\x{0085}\x{2028}\x{2029}]+/\ \ /g;
        $key =~ s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]//g;
        $key = cut_to_printwidth( $key, $len_key );
        my $copy_sep = $separator;
        my $value = $orig_table->[$row][$col];
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
    choose(
        $row_data,
        { prompt => '', layout => 3, clear_screen => 1, mouse => $self->{mouse},
          hide_cursor => 0, f3 => $self->{f3}, skip_items => "$regex", footer => $footer }
    );
}


sub __search {
    my ( $self, $orig_table, $cc, $vs ) = @_;
    if ( ! $self->{f3} ) {
        return;
    }
    require Term::Form;
    Term::Form->VERSION(0.530);
    my $term = Term::Form->new();
    my $prompt = '> search-pattern: ';
    my $string = '';

    READ: while ( 1 ) {
        $string = $term->readline(
            $prompt,
            { hide_cursor => 2, clear_screen => length $string ? 1 : 2, color => $self->{color}, default => $string }
        );
        if ( ! length $string ) {
            return;
        }
        print "\r${prompt}${string}";
        if ( ! eval {
            $vs->{filter} = $self->{f3} == 1 ? qr/$string/i : qr/$string/;
            'Teststring' =~ $vs->{filter};
            1
        } ) {
            chomp $@;
            choose( [ 'Continue with ENTER' ], { prompt => "$@", layout => 0, clear_screen => 1 } );
            next READ;
        }
        last READ;
    }
    no warnings 'uninitialized';
    my @col_idx = ( 0 .. $#{$orig_table->[0]} );
    # 1: skipp header row
    # data_row_count: +1 for the head row, -1 the get the 0 based index, so nothing to do
    for my $idx_row ( 1 .. $cc->{data_row_count} ) {
        for ( @col_idx ) {
            if ( $orig_table->[$idx_row][$_] =~ $vs->{filter} ) {
                push @{$vs->{map_indexes}}, $idx_row;
                last;
            }
        }
    }
    if ( ! @{$vs->{map_indexes}} ) {
        choose( [ 'Continue with ENTER' ], { prompt => 'No matches found.', layout => 0, clear_screen => 1 } );
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
    for my $i ( 0 .. $#$w_cols_calc ) {
        $header_sep .= '-' x $w_cols_calc->[$i];
        $header_sep .= $tab if $i != $#$w_cols_calc;
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
    my ( $self, $table_copy ) = @_;
    my $prompt_1 = 'To many columns - terminal window is not wide enough.';
    choose(
        [ 'Press ENTER to show the column names.' ],
        { prompt => $prompt_1, clear_screen => 1, mouse => $self->{mouse}, hide_cursor => 0 }
    );
    my $prompt_2 = 'Column names (close with ENTER).';
    choose(
        $table_copy->[0],
        { prompt => $prompt_2, clear_screen => 1, mouse => $self->{mouse}, hide_cursor => 0, f3 => $self->{f3} }
    );
}


sub _minus_x_percent {
    my ( $value, $percent ) = @_;
    my $new = int( $value - ( $value / 100 * $percent ) );
    return $new > 0 ? $new : 1;
}








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::TablePrint - Print a table to the terminal and browse it interactively.

=head1 VERSION

Version 0.134

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

If the option L</table_expand> is enabled and a row is selected with C<Return>, each column of that row is output in its own
line preceded by the column name. This might be useful if the columns were cut due to the too low terminal width.

The following modifications are made (at a copy of the original data) to the table elements before the output.

Tab characters (C<\t>) are replaces with a space.

Vertical spaces (C<\v>) are squashed to two spaces

Control characters, code points of the surrogate ranges and non-characters are removed.

If the option I<squash_spaces> is enabled leading and trailing spaces are removed from the array elements and spaces
are squashed to a single space.

If an element looks like a number it is left-justified, else it is right-justified.

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

the C<Insert> key to go back 10 pages, the C<Delete> key to go forward 10 pages (20 instead of 10 pages if the page
count is greater than 10_000).

=item *

the C<Home> key (or C<Ctrl-A>) to jump to the first row of the table, the C<End> key (or C<Ctrl-E>) to jump to the last
row of the table.

=back

With I<keep_header> disabled the C<Return> key closes the table if the cursor is on the header row.

If I<keep_header> is enabled and I<table_expand> is set to C<0>, the C<Return> key closes the table if the cursor is on
the first row.

If I<keep_header> and I<table_expand> are enabled and the cursor is on the first row, pressing C<Return> three times in
succession closes the table. If the cursor is auto-jumped to the first row, it is required only one C<Return> to close
the table.

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

The C<F3> key opens a prompt. A regular expression is expected as input. This enables one to only display rows where at
least one column matches the entered pattern. See option L</f3>.

=head2 OPTIONS

Defaults may change in a future release.

=head3 prompt

String displayed above the table.

=head3 binary_filter

If I<binary_filter> is set to 1, "BNRY" is printed instead of arbitrary binary data.

If the data matches the repexp C</[\x00-\x08\x0B-\x0C\x0E-\x1F]/>, it is considered arbitrary binary data.

Printing arbitrary binary data could break the output.

Default: 0

=head3 decimal_separator

Set the decimal separator. Numbers with a decimal separator are formatted as number if this option is set to the right
value.

Allowed values: a character with a print width of C<1>. If an invalid values is passed, I<decimal_separator> falls back
to the default value.

Default: . (dot)

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

=head3 f3

Set the behavior of the C<F3> key.

0 - off

1 - case-insensitive search

2 - case-sensitive search

Default: 1

=head3 grid

If I<grid> is set to 0, the table is shown with no grid.

If I<grid> is set to 1, lines separate the columns from each other and the header from the body.

    .----------------------------.
    |col1 | col2   | col3 | col3 |
    |-----|--------|------|------|
    |.... | ...... | .... | .... |
    |.... | ...... | .... | .... |
    |.... | ...... | .... | .... |
    |.... | ...... | .... | .... |
    |.... | ...... | .... | .... |
    |.... | ...... | .... | .... |
    |.... | ...... | .... | .... |
    |.... | ...... | .... | .... |
    '----------------------------'

I<grid> set to 2 is like I<grid> set to 1 plus a separator line on top of the header row.

Default: 1

=head3 keep-header

If I<keep-header> is set to 0, the table header is shown on top of the first page.

If I<keep-header> is set to 1, the table header is shown on top of each page.

Default: 1

=head3 squash_spaces

If I<squash_spaces> is enabled, consecutive spaces are squashed to one space and leading and trailing spaces are
removed.

Default: 0

=head3 max_rows

Set the maximum number of used table rows. The used table rows are kept in memory.

To disable the automatic limit set I<max_rows> to 0.

If the number of table rows is equal to or higher than I<max_rows>, the last row of the output tells that the limit has
been reached.

Default: 200_000

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

If the option I<table_expand> is enabled and C<Return> is pressed, the selected table row is printed with
each column in its own line. Exception: if the cursor auto-jumped to the first row, the first row will not be expanded.

If I<table_expand> is set to 0, the cursor jumps to the to first row (if not already there) when C<Return> is pressed.

0 - off

1 - on

Default: 1

=head3 table_name

If set (string), I<table_name> is added in the bottom line.

=head3 undef

Set the string that will be shown on the screen instead of an undefined field.

Default: "" (empty string)

=head1 ERROR HANDLING

C<print_table> dies

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

Copyright 2013-2021 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
