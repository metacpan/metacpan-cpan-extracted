package Term::Choose;

use warnings;
use strict;
use 5.10.1;

our $VERSION = '1.775';
use Exporter 'import';
our @EXPORT_OK = qw( choose );

use Carp qw( croak carp );

use Term::Choose::Constants       qw( :all );
use Term::Choose::LineFold        qw( line_fold print_columns cut_to_printwidth );
use Term::Choose::Screen          qw( :all );
use Term::Choose::ValidateOptions qw( validate_options );

my $Plugin;

BEGIN {
    if ( $^O eq 'MSWin32' ) {
        require Win32::Console::ANSI;
        require Term::Choose::Win32;
        $Plugin = 'Term::Choose::Win32';
    }
    else {
        require Term::Choose::Linux;
        $Plugin = 'Term::Choose::Linux';
    }
}

END {
    if ( $? == 255 ) {
        if( $^O eq 'MSWin32' ) {
            my $input = Win32::Console->new( Win32::Console::constant( "STD_INPUT_HANDLE",  0 ) );
            $input->Mode( 0x0001|0x0002|0x0004 );
            $input->Flush;
        }
        elsif ( TERM_READKEY ) {
            Term::ReadKey::ReadMode( 'restore' );
        }
        else {
            system( "stty sane" );
        }
        print "\n", clear_to_end_of_screen;
        print show_cursor;
    }
}


sub new {
    my $class = shift;
    my ( $opt ) = @_;
    croak "new: called with " . @_ . " arguments - 0 or 1 arguments expected" if @_ > 1;
    my $instance_defaults = _defaults();
    if ( defined $opt ) {
        croak "new: the (optional) argument must be a HASH reference" if ref $opt ne 'HASH';
        validate_options( _valid_options(), $opt, 'new' );
        for my $key ( keys %$opt ) {
            $instance_defaults->{$key} = $opt->{$key} if defined $opt->{$key};
        }
    }
    my $self = bless $instance_defaults, $class;
    $self->{backup_instance_defaults} = { %$instance_defaults };
    $self->{plugin} = $Plugin->new();
    return $self;
}


sub _valid_options {
    return {
        beep                => '[ 0 1 ]',
        clear_screen        => '[ 0 1 ]',
        codepage_mapping    => '[ 0 1 ]',
        hide_cursor         => '[ 0 1 ]',
        index               => '[ 0 1 ]',
        mouse               => '[ 0 1 ]',
        order               => '[ 0 1 ]',
        alignment           => '[ 0 1 2 ]',
        color               => '[ 0 1 2 ]',
        include_highlighted => '[ 0 1 2 ]',
        layout              => '[ 0 1 2 ]',
        page                => '[ 0 1 2 ]',
        search              => '[ 0 1 2 ]',
        keep                => '[ 1-9 ][ 0-9 ]*',
        ll                  => '[ 1-9 ][ 0-9 ]*',
        max_cols            => '[ 1-9 ][ 0-9 ]*',
        max_height          => '[ 1-9 ][ 0-9 ]*',
        max_width           => '[ 1-9 ][ 0-9 ]*',
        default             => '[ 0-9 ]+',
        pad                 => '[ 0-9 ]+',
        margin              => 'Array_Int',
        mark                => 'Array_Int',
        meta_items          => 'Array_Int',
        no_spacebar         => 'Array_Int',
        tabs_info           => 'Array_Int',
        tabs_prompt         => 'Array_Int',
        skip_items          => 'Regexp',
        empty               => 'Str',
        footer              => 'Str',
        info                => 'Str',
        prompt              => 'Str',
        undef               => 'Str',
        busy_string         => 'Str',
    };
};


sub _defaults {
    return {
        alignment           => 0,
        beep                => 0,
        clear_screen        => 0,
        codepage_mapping    => 0,
        color               => 0,
        #default            => undef,
        empty               => '<empty>',
        #footer             => undef,
        hide_cursor         => 1,
        include_highlighted => 0,
        index               => 0,
        info                => '',
        keep                => 5,
        layout              => 1,
        #ll                 => undef,
        #margin             => undef,
        #mark               => undef,
        #max_cols           => undef,
        #max_height         => undef,
        #max_width          => undef,
        #meta_items         => undef,
        mouse               => 0,
        #no_spacebar        => undef,
        order               => 1,
        pad                 => 2,
        page                => 1,
        #prompt             => undef,
        search              => 1,
        #skip_items         => undef,
        #tabs_info          => undef,
        #tabs_prompt        => undef,
        undef               => '<undef>',
        #busy_string        => undef,
    };
}


sub __copy_orig_list {
    my ( $self, $orig_list_ref ) = @_;
    if ( $self->{ll} ) {
        $self->{list} = $orig_list_ref;
    }
    else {
        $self->{list} = [ @$orig_list_ref ];
        if ( $self->{color} ) {
            $self->{orig_list} = $orig_list_ref;
        }
        for ( @{$self->{list}} ) {
            if ( ! $_ ) {
                $_ = $self->{undef} if ! defined $_;
                $_ = $self->{empty} if ! length $_;
            }
            if ( $self->{color} ) {
                s/${\PH}//g;
                s/${\SGR_ES}/${\PH}/g;
            }
            s/\t/ /g;
            s/\v+/\ \ /g;
            # \p{Cn} might not be up to date and remove assigned codepoints
            # therefore only \p{Noncharacter_Code_Point}
            s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]//g;
        }
    }
}


sub __length_list_elements {
    my ( $self ) = @_;
    my $list = $self->{list};
    if ( $self->{ll} ) {
        $self->{col_width} = $self->{ll};
    }
    else {
        my $length_elements = [];
        my $longest = 0;
        for my $i ( 0 .. $#$list ) {
            $length_elements->[$i] = print_columns( $list->[$i] );
            $longest = $length_elements->[$i] if $length_elements->[$i] > $longest;
        }
        $self->{width_elements} = $length_elements;
        $self->{col_width} = $longest;
    }
}


sub __init_term {
    my ( $self ) = @_;
    my $config = {
        mode => 'ultra-raw',
        mouse => $self->{mouse},
        hide_cursor => $self->{hide_cursor},
    };
    $self->{mouse} = $self->{plugin}->__set_mode( $config );
}


sub __reset_term {
    my ( $self, $clear_choose ) = @_;
    if ( defined $self->{plugin} ) {
        $self->{plugin}->__reset_mode( { mouse => $self->{mouse}, hide_cursor => $self->{hide_cursor} } );
    }
    if ( $clear_choose ) {
        my $up = $self->{i_row} + $self->{count_prompt_lines};
        print up( $up ) if $up;
        print "\r" . clear_to_end_of_screen();
    }
    if ( exists $self->{backup_instance_defaults} ) {  # backup_instance_defaults exists if ObjectOriented
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


sub __get_key {
    my ( $self ) = @_;
    my $key;
    if ( defined $self->{skip_items} ) {
        my $idx = $self->{rc2idx}[$self->{pos}[ROW]][$self->{pos}[COL]];
        if ( $self->{list}[$idx] =~ $self->{skip_items} ) {
            $key = $self->Term::Choose::Opt::SkipItems::__key_skipped();
        }
    }
    if ( ! defined $key ) {
        $key = $self->{plugin}->__get_key_OS( $self->{mouse} );
    }
    return $key if ref $key ne 'ARRAY';
    return $self->Term::Choose::Opt::Mouse::__mouse_info_to_key( @$key );
}


sub __modify_options {
    my ( $self ) = @_;
    if ( defined $self->{max_cols} && $self->{max_cols} == 1 ) {
        $self->{layout} = 2;
    }
    if ( length $self->{footer} && $self->{page} != 2 ) {
        $self->{page} = 2;
    }
    if ( $self->{page} == 2 && ! $self->{clear_screen} ) {
        $self->{clear_screen} = 1;
    }
    if ( $self->{max_cols} && $self->{layout} == 1 ) {
        $self->{layout} = 0;
    }
    if ( ! defined $self->{prompt} ) {
        $self->{prompt} = defined $self->{wantarray} ? 'Your choice:' : 'Close with ENTER';
    }
    if ( defined $self->{margin} ) {
        ( $self->{margin_top}, $self->{margin_right}, $self->{margin_bottom}, $self->{margin_left} ) = @{$self->{margin}};
        if ( ! defined $self->{tabs_prompt} ) {
            $self->{tabs_prompt} = [ $self->{margin_left}, $self->{margin_left}, $self->{margin_right} ];
        }
        if ( ! defined $self->{tabs_info} ) {
            $self->{tabs_info} = [ $self->{margin_left}, $self->{margin_left}, $self->{margin_right} ];
        }
    }
}


sub choose {
    if ( ref $_[0] ne __PACKAGE__ ) {
        my $ob = __PACKAGE__->new();
        delete $ob->{backup_instance_defaults};
        return $ob->__choose( @_ );
    }
    my $self = shift;
    return $self->__choose( @_ );
}


sub __choose {
    my $self = shift;
    my ( $orig_list_ref, $opt ) = @_;
    croak "choose: called with " . @_ . " arguments - 1 or 2 arguments expected" if @_ < 1 || @_ > 2;
    croak "choose: the first argument must be an ARRAY reference" if ref $orig_list_ref ne 'ARRAY';
    if ( defined $opt ) {
        croak "choose: the (optional) second argument must be a HASH reference" if ref $opt ne 'HASH';
        validate_options( _valid_options(), $opt, 'choose' );
        for my $key ( keys %$opt ) {
            $self->{$key} = $opt->{$key} if defined $opt->{$key};
        }
    }
    if ( ! @$orig_list_ref ) {
        return;
    }
    local $\ = undef;
    local $, = undef;
    local $| = 1;
    if ( defined $self->{busy_string} ) {
        print "\r" . clear_to_end_of_line();
        print $self->{busy_string};
    }
    $self->{wantarray} = wantarray;
    $self->__modify_options();
    if ( $self->{mouse} ) {
        require Term::Choose::Opt::Mouse;
    }
    if ( $^O eq 'MSWin32' ) {
        print $opt->{codepage_mapping} ? "\e(K" : "\e(U";
    }
    $self->__copy_orig_list( $orig_list_ref );
    $self->__length_list_elements();
    if ( defined $self->{skip_items} ) {
        require Term::Choose::Opt::SkipItems;
        $self->Term::Choose::Opt::SkipItems::__prepare_default();
    }
    if ( exists $ENV{TC_RESET_AUTO_UP} ) {
        $ENV{TC_RESET_AUTO_UP} = 0;
    }
    local $SIG{INT} = sub {
        $self->__reset_term();
        exit;
    };
    $self->__init_term();
    ( $self->{term_width}, $self->{term_height} ) = get_term_size();
    $self->__wr_first_screen();
    my $fast_page = 10;
    if ( $self->{pp_count} > 10_000 ) {
        $fast_page = 20;
    }
    my $saved_pos;

    GET_KEY: while ( 1 ) {
        my $key = $self->__get_key();
        if ( ! defined $key ) {
            $self->__reset_term( 1 );
            carp "EOT: $!";
            return;
        }
        $self->{pressed_key} = $key;
        my ( $new_width, $new_height ) = get_term_size();
        if ( $new_width != $self->{term_width} || $new_height != $self->{term_height} ) {
            if ( $self->{ll} ) {
                $self->__reset_term( 0 );
                return -1;
            }
            ( $self->{term_width}, $self->{term_height} ) = ( $new_width, $new_height );
            $self->__copy_orig_list( $orig_list_ref );
            $self->{default} = $self->{rc2idx}[$self->{pos}[ROW]][$self->{pos}[COL]];
            if ( $self->{wantarray} && @{$self->{marked}} ) {
                $self->{mark} = $self->__marked_rc2idx();
            }
            my $up = $self->{i_row} + $self->{count_prompt_lines};
            print up( $up ) if $up;
            print "\r" . clear_to_end_of_screen();
            $self->__wr_first_screen();
            next GET_KEY;
        }
        next GET_KEY if $key == NEXT_get_key;
        next GET_KEY if $key == KEY_Tilde;
        if ( exists $ENV{TC_RESET_AUTO_UP} && $ENV{TC_RESET_AUTO_UP} == 0 ) {
            if ( $key != LINE_FEED && $key != CARRIAGE_RETURN ) {
                $ENV{TC_RESET_AUTO_UP} = 1;
            }
        }
        my $page_step = 1;
        if ( $key == VK_INSERT ) {
            $page_step = $fast_page if $self->{first_page_row} - $fast_page * $self->{avail_height} >= 0;
            $key = VK_PAGE_UP;
        }
        elsif ( $key == VK_DELETE ) {
            $page_step = $fast_page if $self->{last_page_row} + $fast_page * $self->{avail_height} <= $#{$self->{rc2idx}};
            $key = VK_PAGE_DOWN;
        }
        if ( $saved_pos && $key != VK_PAGE_UP && $key != CONTROL_B && $key != VK_PAGE_DOWN && $key != CONTROL_F ) {
            $saved_pos = undef;
        }
        # $self->{rc2idx} holds the new list (AoA) formatted in "__list_idx2rc" appropriate to the chosen layout.
        # $self->{rc2idx} does not hold the values directly but the respective list indexes from the original list.
        # If the original list would be ( 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' ) and the new formatted list should be
        #     a d g
        #     b e h
        #     c f
        # then the $self->{rc2idx} would look like this
        #     0 3 6
        #     1 4 7
        #     2 5
        # So e.g. the second value in the second row of the new list would be $self->{list}[ $self->{rc2idx}[1][1] ].
        # On the other hand the index of the last row of the new list would be $#{$self->{rc2idx}}
        # or the index of the last column in the first row would be $#{$self->{rc2idx}[0]}.

        if ( $key == VK_DOWN || $key == KEY_j ) {
            if (     ! $self->{rc2idx}[$self->{pos}[ROW]+1]
                  || ! $self->{rc2idx}[$self->{pos}[ROW]+1][$self->{pos}[COL]]
            ) {
                $self->__beep();
            }
            else {
                $self->{pos}[ROW]++;
                if ( $self->{pos}[ROW] <= $self->{last_page_row} ) {
                    $self->__wr_cell( $self->{pos}[ROW] - 1, $self->{pos}[COL] );
                    $self->__wr_cell( $self->{pos}[ROW]    , $self->{pos}[COL] );
                }
                else {
                    $self->{first_page_row} = $self->{last_page_row} + 1;
                    $self->{last_page_row}  = $self->{last_page_row} + $self->{avail_height};
                    $self->{last_page_row}  = $#{$self->{rc2idx}} if $self->{last_page_row} > $#{$self->{rc2idx}};
                    $self->__wr_screen();
                }
            }
        }
        elsif ( $key == VK_UP || $key == KEY_k ) {
            if ( $self->{pos}[ROW] == 0 ) {
                $self->__beep();
            }
            else {
                $self->{pos}[ROW]--;
                if ( $self->{pos}[ROW] >= $self->{first_page_row} ) {
                    $self->__wr_cell( $self->{pos}[ROW] + 1, $self->{pos}[COL] );
                    $self->__wr_cell( $self->{pos}[ROW]    , $self->{pos}[COL] );
                }
                else {
                    $self->{last_page_row}  = $self->{first_page_row} - 1;
                    $self->{first_page_row} = $self->{first_page_row} - $self->{avail_height};
                    $self->{first_page_row} = 0 if $self->{first_page_row} < 0;
                    $self->__wr_screen();
                }
            }
        }
        elsif ( $key == KEY_TAB || $key == CONTROL_I ) { # KEY_TAB == CONTROL_I
            if (    $self->{pos}[ROW] == $#{$self->{rc2idx}}
                 && $self->{pos}[COL] == $#{$self->{rc2idx}[$self->{pos}[ROW]]}
            ) {
                $self->__beep();
            }
            else {
                if ( $self->{pos}[COL] < $#{$self->{rc2idx}[$self->{pos}[ROW]]} ) {
                    $self->{pos}[COL]++;
                    $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] - 1 );
                    $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
                }
                else {
                    $self->{pos}[ROW]++;
                    if ( $self->{pos}[ROW] <= $self->{last_page_row} ) {
                        $self->{pos}[COL] = 0;
                        $self->__wr_cell( $self->{pos}[ROW] - 1, $#{$self->{rc2idx}[$self->{pos}[ROW] - 1]} );
                        $self->__wr_cell( $self->{pos}[ROW]    , $self->{pos}[COL] );
                    }
                    else {
                        $self->{first_page_row} = $self->{last_page_row} + 1;
                        $self->{last_page_row}  = $self->{last_page_row} + $self->{avail_height};
                        $self->{last_page_row}  = $#{$self->{rc2idx}} if $self->{last_page_row} > $#{$self->{rc2idx}};
                        $self->{pos}[COL] = 0;
                        $self->__wr_screen();
                    }
                }
            }
        }
        elsif ( $key == KEY_BSPACE || $key == KEY_BTAB || $key == CONTROL_H ) { # KEY_BTAB == CONTROL_H
            if ( $self->{pos}[COL] == 0 && $self->{pos}[ROW] == 0 ) {
                $self->__beep();
            }
            else {
                if ( $self->{pos}[COL] > 0 ) {
                    $self->{pos}[COL]--;
                    $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] + 1 );
                    $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
                }
                else {
                    $self->{pos}[ROW]--;
                    if ( $self->{pos}[ROW] >= $self->{first_page_row} ) {
                        $self->{pos}[COL] = $#{$self->{rc2idx}[$self->{pos}[ROW]]};
                        $self->__wr_cell( $self->{pos}[ROW] + 1, 0 );
                        $self->__wr_cell( $self->{pos}[ROW]    , $self->{pos}[COL] );
                    }
                    else {
                        $self->{last_page_row}  = $self->{first_page_row} - 1;
                        $self->{first_page_row} = $self->{first_page_row} - $self->{avail_height};
                        $self->{first_page_row} = 0 if $self->{first_page_row} < 0;
                        $self->{pos}[COL] = $#{$self->{rc2idx}[$self->{pos}[ROW]]};
                        $self->__wr_screen();
                    }
                }
            }
        }
        elsif ( $key == VK_RIGHT || $key == KEY_l ) {
            if ( $self->{pos}[COL] == $#{$self->{rc2idx}[$self->{pos}[ROW]]} ) {
                $self->__beep();
            }
            else {
                $self->{pos}[COL]++;
                $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] - 1 );
                $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
            }
        }
        elsif ( $key == VK_LEFT || $key == KEY_h ) {
            if ( $self->{pos}[COL] == 0 ) {
                $self->__beep();
            }
            else {
                $self->{pos}[COL]--;
                $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] + 1 );
                $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
            }
        }
        elsif ( $key == VK_PAGE_UP || $key == CONTROL_P ) {
            if ( $self->{first_page_row} <= 0 ) {
                $self->__beep();
            }
            else {
                $self->{first_page_row} = $self->{avail_height} * ( int( $self->{pos}[ROW] / $self->{avail_height} ) - $page_step );
                $self->{last_page_row}  = $self->{first_page_row} + $self->{avail_height} - 1;
                if ( $saved_pos ) {
                    $self->{pos}[ROW] = $saved_pos->[ROW] + $self->{first_page_row};
                    $self->{pos}[COL] = $saved_pos->[COL];
                    $saved_pos = undef;
                }
                else {
                    $self->{pos}[ROW] -= $self->{avail_height} * $page_step;
                }
                $self->__wr_screen();
            }
        }
        elsif ( $key == VK_PAGE_DOWN || $key == CONTROL_N ) {
            if ( $self->{last_page_row} >= $#{$self->{rc2idx}} ) {
                $self->__beep();
            }
            else {
                my $backup_p_begin = $self->{first_page_row};
                $self->{first_page_row} = $self->{avail_height} * ( int( $self->{pos}[ROW] / $self->{avail_height} ) + $page_step );
                $self->{last_page_row}  = $self->{first_page_row} + $self->{avail_height} - 1;
                $self->{last_page_row}  = $#{$self->{rc2idx}} if $self->{last_page_row} > $#{$self->{rc2idx}};
                if (   $self->{pos}[ROW] + $self->{avail_height} > $#{$self->{rc2idx}}
                    || $self->{pos}[COL] > $#{$self->{rc2idx}[$self->{pos}[ROW] + $self->{avail_height}]}
                ) {
                    $saved_pos = [ $self->{pos}[ROW] - $backup_p_begin, $self->{pos}[COL] ];
                    $self->{pos}[ROW] = $#{$self->{rc2idx}};
                    if ( $self->{pos}[COL] > $#{$self->{rc2idx}[$self->{pos}[ROW]]} ) {
                        $self->{pos}[COL] = $#{$self->{rc2idx}[$self->{pos}[ROW]]};
                    }
                }
                else {
                    $self->{pos}[ROW] += $self->{avail_height} * $page_step;
                }
                $self->__wr_screen();
            }
        }
        elsif ( $key == VK_HOME || $key == CONTROL_A ) {
            if ( $self->{pos}[COL] == 0 && $self->{pos}[ROW] == 0 ) {
                $self->__beep();
            }
            else {
                $self->{pos}[ROW] = 0;
                $self->{pos}[COL] = 0;
                $self->{first_page_row} = 0;
                $self->{last_page_row}  = $self->{first_page_row} + $self->{avail_height} - 1;
                $self->{last_page_row}  = $#{$self->{rc2idx}} if $self->{last_page_row} > $#{$self->{rc2idx}};
                $self->__wr_screen();
            }
        }
        elsif ( $key == VK_END || $key == CONTROL_E ) {
            if ( $self->{order} == 1 && $self->{idx_of_last_col_in_last_row} < $#{$self->{rc2idx}[0]} ) {
                if (    $self->{pos}[ROW] == $#{$self->{rc2idx}} - 1
                     && $self->{pos}[COL] == $#{$self->{rc2idx}[$self->{pos}[ROW]]}
                ) {
                    $self->__beep();
                }
                else {
                    $self->{first_page_row} = @{$self->{rc2idx}} - ( @{$self->{rc2idx}} % $self->{avail_height} || $self->{avail_height} );
                    $self->{pos}[ROW] = $#{$self->{rc2idx}} - 1;
                    $self->{pos}[COL] = $#{$self->{rc2idx}[$self->{pos}[ROW]]};
                    if ( $self->{first_page_row} == $#{$self->{rc2idx}} ) {
                        $self->{first_page_row} = $self->{first_page_row} - $self->{avail_height};
                        $self->{last_page_row}  = $self->{first_page_row} + $self->{avail_height} - 1;
                    }
                    else {
                        $self->{last_page_row}  = $#{$self->{rc2idx}};
                    }
                    $self->__wr_screen();
                }
            }
            else {
                if (    $self->{pos}[ROW] == $#{$self->{rc2idx}}
                     && $self->{pos}[COL] == $#{$self->{rc2idx}[$self->{pos}[ROW]]}
                ) {
                    $self->__beep();
                }
                else {
                    $self->{first_page_row} = @{$self->{rc2idx}} - ( @{$self->{rc2idx}} % $self->{avail_height} || $self->{avail_height} );
                    $self->{last_page_row}  = $#{$self->{rc2idx}};
                    $self->{pos}[ROW] = $#{$self->{rc2idx}};
                    $self->{pos}[COL] = $#{$self->{rc2idx}[$self->{pos}[ROW]]};
                    $self->__wr_screen();
                }
            }
        }
        elsif ( $key == KEY_q || $key == CONTROL_Q ) {
            $self->__reset_term( 1 );
            return;
        }
        elsif ( $key == CONTROL_C ) {
            $self->__reset_term( 1 );
            print STDERR "^C\n";
            exit 1;
        }
        elsif ( $key == LINE_FEED || $key == CARRIAGE_RETURN ) { # LINE_FEED == CONTROL_J, CARRIAGE_RETURN == CONTROL_M      # ENTER key
            if ( length $self->{search_info} ) {
                require Term::Choose::Opt::Search;
                $self->Term::Choose::Opt::Search::__search_end();
                next GET_KEY;
            }
            my $opt_index = $self->{index} || $self->{ll};
            my $list_idx = $self->{rc2idx}[$self->{pos}[ROW]][$self->{pos}[COL]];
            if ( ! defined $self->{wantarray} ) {
                $self->__reset_term( 1 );
                return;
            }
            elsif ( $self->{wantarray} ) {
                if ( $self->{include_highlighted} == 1 ) {
                    $self->{marked}[$self->{pos}[ROW]][$self->{pos}[COL]] = 1;
                }
                elsif ( $self->{include_highlighted} == 2 ) {
                    my $chosen = $self->__marked_rc2idx();
                    if ( ! @$chosen ) {
                        $self->{marked}[$self->{pos}[ROW]][$self->{pos}[COL]] = 1;
                    }
                }
                if ( defined $self->{meta_items} && ! $self->{marked}[$self->{pos}[ROW]][$self->{pos}[COL]] ) {
                    for my $meta_item ( @{$self->{meta_items}} ) {
                        if ( $meta_item == $list_idx ) {
                            $self->{marked}[$self->{pos}[ROW]][$self->{pos}[COL]] = 1;
                            last;
                        }
                    }
                }
                my $chosen = $self->__marked_rc2idx();
                $self->__reset_term( 1 );
                return $opt_index ? @$chosen : @{$orig_list_ref}[@$chosen];
            }
            else {
                my $chosen = $opt_index ? $list_idx : $orig_list_ref->[$list_idx];
                $self->__reset_term( 1 );
                return $chosen;
            }
        }
        elsif ( $key == KEY_SPACE ) {
            if ( $self->{wantarray} ) {
                my $list_idx = $self->{rc2idx}[$self->{pos}[ROW]][$self->{pos}[COL]];
                my $locked = 0;
                if ( defined $self->{no_spacebar} || defined $self->{meta_items} ) {
                    for my $no_spacebar ( @{$self->{no_spacebar}||[]}, @{$self->{meta_items}||[]} ) {
                        if ( $list_idx == $no_spacebar ) {
                            ++$locked;
                            last;
                        }
                    }
                }
                if ( $locked ) {
                    $self->__beep();
                }
                else {
                    $self->{marked}[$self->{pos}[ROW]][$self->{pos}[COL]] = ! $self->{marked}[$self->{pos}[ROW]][$self->{pos}[COL]];
                    $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
                }
            }
            else {
                $self->__beep();
            }
        }
        elsif ( $key == CONTROL_SPACE ) {
            if ( $self->{wantarray} ) {
                for my $i ( 0 .. $#{$self->{rc2idx}} ) {
                    for my $j ( 0 .. $#{$self->{rc2idx}[$i]} ) {
                        $self->{marked}[$i][$j] = ! $self->{marked}[$i][$j];
                    }
                }
                if ( $self->{skip_items} ) {
                    $self->Term::Choose::Opt::SkipItems::__unmark_skip_items();
                }
                if ( defined $self->{no_spacebar} ) {
                    $self->__marked_idx2rc( $self->{no_spacebar}, 0 );
                }
                if ( defined $self->{meta_items} ) {
                    $self->__marked_idx2rc( $self->{meta_items}, 0 );
                }

                $self->__wr_screen();
            }
            else {
                $self->__beep();
            }
        }
        elsif ( $key == CONTROL_F && $self->{search} ) {
            require Term::Choose::Opt::Search;
            if ( $self->{ll} ) {
                $ENV{TC_POS_AT_SEARCH} = $self->{rc2idx}[$self->{pos}[ROW]][$self->{pos}[COL]];
                $self->__reset_term( 0 );
                return -13;
            }
            if ( length $self->{search_info} ) {
                $self->Term::Choose::Opt::Search::__search_end();
            }
            $self->Term::Choose::Opt::Search::__search_begin();
        }
        else {
            $self->__beep();
        }
    }
}


sub __beep {
    my ( $self, $beep ) = @_;
    if ( $beep ) {
        print bell();
    }
}


sub __prepare_info_and_prompt_lines {
    my ( $self ) = @_;
    my $info_w = $self->{term_width} + EXTRA_W;
    if ( $self->{max_width} && $info_w > $self->{max_width} ) { ##
        $info_w = $self->{max_width};
    }
    my @tmp_prompt;
    if ( $self->{margin_top} ) {
        push @tmp_prompt, ( '' ) x $self->{margin_top};
    }
    if ( length $self->{info} ) {
        my $init     = $self->{tabs_info}[0] // 0;
        my $subseq   = $self->{tabs_info}[1] // 0;
        my $r_margin = $self->{tabs_info}[2] // 0;
        push @tmp_prompt, line_fold(
            $self->{info},
            { width => $info_w - $r_margin, init_tab => ' ' x $init, subseq_tab => ' ' x $subseq,
              color => $self->{color}, join => 0 }
        );
    }
    if ( length $self->{prompt} ) {
        my $init     = $self->{tabs_prompt}[0] // 0;
        my $subseq   = $self->{tabs_prompt}[1] // 0;
        my $r_margin = $self->{tabs_prompt}[2] // 0;
        push @tmp_prompt, line_fold(
            $self->{prompt},
            { width => $info_w - $r_margin, init_tab => ' ' x $init, subseq_tab => ' ' x $subseq,
              color => $self->{color}, join => 0 }
        );
    }
    if ( length $self->{search_info} ) {
        push @tmp_prompt, ( $self->{margin_left} ? ' ' x $self->{margin_left} : '' ) . $self->{search_info};
    }
    $self->{count_prompt_lines} = @tmp_prompt;
    if ( ! $self->{count_prompt_lines} ) {
        $self->{prompt_copy} = '';
        return;
    }
    $self->{prompt_copy} = join( "\n\r", @tmp_prompt ) . "\n\r"; #
    # \n\r -> stty 'raw' mode and Term::Readkey 'ultra-raw' mode don't translate newline to carriage_return/newline
}


sub __prepare_footer_line {
    my ( $self ) = @_;
    if ( exists $self->{footer_fmt} ) {
        delete $self->{footer_fmt};
    }
    my $pp_total = int( $#{$self->{rc2idx}} / $self->{avail_height} ) + 1;
    if ( $self->{page} == 0 ) {
        # nothing to do
    }
    elsif ( $self->{page} == 1 && $pp_total == 1 ) {
        $self->{avail_height}++;
    }
    else {
        my $pp_total_width = length $pp_total;
        $self->{footer_fmt} = '--- %0' . $pp_total_width . 'd/' . $pp_total . ' --- ';
        if ( defined $self->{footer} ) {
            $self->{footer_fmt} .= $self->{footer};
        }
        if ( print_columns( sprintf $self->{footer_fmt}, $pp_total ) > $self->{avail_width} ) { # color
            $self->{footer_fmt} = '%0' . $pp_total_width . 'd/' . $pp_total;
            if ( length( sprintf $self->{footer_fmt}, $pp_total ) > $self->{avail_width} ) {
                $pp_total_width = $self->{avail_width} if $pp_total_width > $self->{avail_width};
                $self->{footer_fmt} = '%0' . $pp_total_width . '.' . $pp_total_width . 's';
            }
        }
    }
    $self->{pp_count} = $pp_total;
}


sub __set_cell {
    my ( $self, $list_idx ) = @_;
    if ( $self->{current_layout} == 2 ) {
        $self->{pos} = [ $list_idx, 0 ];
    }
    else {
        LOOP: for my $i ( 0 .. $#{$self->{rc2idx}} ) {
            for my $j ( 0 .. $#{$self->{rc2idx}[$i]} ) {
                if ( $list_idx == $self->{rc2idx}[$i][$j] ) {
                    $self->{pos} = [ $i, $j ];
                    last LOOP;
                }
            }
        }
    }
    $self->{first_page_row} = $self->{avail_height} * int( $self->{pos}[ROW] / $self->{avail_height} );
    $self->{last_page_row} = $self->{first_page_row} + $self->{avail_height} - 1;
    $self->{last_page_row} = $#{$self->{rc2idx}} if $self->{last_page_row} > $#{$self->{rc2idx}};
}


sub __wr_first_screen {
    my ( $self ) = @_;
    $self->__avail_screen_size();
    $self->__current_layout();
    $self->__list_idx2rc();
    $self->__prepare_footer_line();
    $self->{first_page_row} = 0;
    my $avail_height_idx = $self->{avail_height} - 1;
    $self->{last_page_row}  = $avail_height_idx > $#{$self->{rc2idx}} ? $#{$self->{rc2idx}} : $avail_height_idx;
    $self->{i_row}  = 0;
    $self->{i_col}  = 0;
    $self->{pos}    = [ 0, 0 ];
    $self->{marked} = [];
    if ( $self->{wantarray} && defined $self->{mark} ) {
        $self->__marked_idx2rc( $self->{mark}, 1 );
    }
    if ( defined $self->{default} && $self->{default} <= $#{$self->{list}} ) {
        $self->__set_cell( $self->{default} );
    }
    if ( $self->{clear_screen} ) {
        print clear_screen();
    }
    else {
        print "\r" . clear_to_end_of_screen();
    }
    if ( $self->{prompt_copy} ne '' ) {
        print $self->{prompt_copy};
    }
    $self->__wr_screen();
    if ( $self->{mouse} ) {
        my $abs_cursor_y = $self->{plugin}->__get_cursor_row();
        $self->{offset_rows} = $abs_cursor_y - 1 - $self->{i_row};
    }
}


sub __wr_screen {
    my ( $self ) = @_;
    $self->__goto( 0, 0 );
    print "\r" . clear_to_end_of_screen();
    if ( defined $self->{footer_fmt} ) {
        my $pp_line = sprintf $self->{footer_fmt}, int( $self->{first_page_row} / $self->{avail_height} ) + 1;
        if ( $self->{margin_left} ) {
            print right( $self->{margin_left} );
        }
        print "\n" x ( $self->{avail_height} );
        print $pp_line . "\r";
        if ( $self->{margin_bottom} ) {
            print "\n" x $self->{margin_bottom};
            print up( $self->{margin_bottom} );
        }
        print up( $self->{avail_height} );
    }
    elsif ( $self->{margin_bottom} ) {
        my $count = ( $self->{last_page_row} - $self->{first_page_row} ) + $self->{margin_bottom};
        print "\n" x $count;
        print up( $count );
    }
    if ( $self->{margin_left} ) {
        print right( $self->{margin_left} ); # left margin after each "\r"
    }
    my $pad_str = ' ' x $self->{pad};
    for my $row ( $self->{first_page_row} .. $self->{last_page_row} ) {
        my $line = $self->__prepare_cell( $row, 0 );
        if ( $#{$self->{rc2idx}[$row]} ) { #
            for my $col ( 1 .. $#{$self->{rc2idx}[$row]} ) {
                $line = $line . $pad_str . $self->__prepare_cell( $row, $col );
            }
        }
        print $line . "\n\r";
        if ( $self->{margin_left} ) {
            print right( $self->{margin_left} );
        }
    }
    print up( $self->{last_page_row} - $self->{first_page_row} + 1 );
    # relativ cursor pos: 0, 0
    $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
}


sub __prepare_cell {
    my( $self, $row, $col ) = @_;
    my $is_current_pos = $row == $self->{pos}[ROW] && $col == $self->{pos}[COL];
    my $emphasised = ( $self->{marked}[$row][$col] ? bold_underline() : '' ) . ( $is_current_pos ? reverse_video() : '' );
    my $idx = $self->{rc2idx}[$row][$col];
    if ( $self->{ll} ) {
        if ( $self->{color} ) {
            my $str = $self->{list}[$idx];
            if ( $emphasised ) {
                if ( $is_current_pos && $self->{color} == 1 ) {
                    # no color for the selected cell if color == 1
                    $str =~ s/${\SGR_ES}//g;
                }
                else {
                    # keep marked cells marked after color escapes
                    $str =~ s/(${\SGR_ES})/${1}$emphasised/g;
                }
                $str = $emphasised . $str;
            }
            return $str . normal();
        }
        else {
            if ( $emphasised ) {
                return $emphasised . $self->{list}[$idx] . normal();
            }
            else {
                return $self->{list}[$idx];
            }
        }
    }
    else {
        my $str = $self->{current_layout} == -1 ? $self->{list}[$idx] : $self->__pad_str_to_colwidth( $idx );
        if ( $self->{color} ) {
            my @color;
            if ( ! $self->{orig_list}[$idx] ) {
                if ( ! defined $self->{orig_list}[$idx] ) {
                    @color = $self->{undef} =~ /(${\SGR_ES})/g;
                }
                elsif ( ! length $self->{orig_list}[$idx] ) {
                    @color = $self->{empty} =~ /(${\SGR_ES})/g;
                }
            }
            else {
                @color = $self->{orig_list}[$idx] =~ /(${\SGR_ES})/g;
            }
            if ( $emphasised ) {
                for ( @color ) {
                    # keep marked cells marked after color escapes
                    $_ .= $emphasised;
                }
                $str = $emphasised . $str . normal();
                if ( $is_current_pos && $self->{color} == 1 ) {
                    # no color for the selected cell if color == 1
                    @color = ();
                    $str =~ s/${\PH}//g;
                }
            }
            if ( @color ) {
                $str =~ s/${\PH}/shift @color/ge;
                if ( ! $emphasised ) {
                    $str .= normal();
                }
            }
            return $str;
        }
        else {
            if ( $emphasised ) {
                $str = $emphasised . $str . normal();
            }
            return $str;
        }
    }
}


sub __wr_cell {
    my( $self, $row, $col ) = @_;
    my $idx = $self->{rc2idx}[$row][$col];
    if ( $self->{current_layout} == -1 ) {
        my $x = 0;
        if ( $col > 0 ) {
            for my $cl ( 0 .. $col - 1 ) {
                my $i = $self->{rc2idx}[$row][$cl];
                $x += $self->{width_elements}[$i] + $self->{pad};
            }
        }
        $self->__goto( $row - $self->{first_page_row}, $x );
        $self->{i_col} = $self->{i_col} + $self->{width_elements}[$idx];
    }
    else {
        $self->__goto( $row - $self->{first_page_row}, $col * $self->{col_width_plus} );
        $self->{i_col} = $self->{i_col} + $self->{col_width};
    }
    print $self->__prepare_cell( $row, $col );
}


sub __pad_str_to_colwidth {
    my ( $self, $idx ) = @_;
    if ( $self->{width_elements}[$idx] < $self->{col_width} ) {
        if ( $self->{alignment} == 0 ) {
            return $self->{list}[$idx] . ( " " x ( $self->{col_width} - $self->{width_elements}[$idx] ) );
        }
        elsif ( $self->{alignment} == 1 ) {
            return " " x ( $self->{col_width} - $self->{width_elements}[$idx] ) . $self->{list}[$idx];
        }
        elsif ( $self->{alignment} == 2 ) {
            my $all = $self->{col_width} - $self->{width_elements}[$idx];
            my $half = int( $all / 2 );
            return ( " " x $half ) . $self->{list}[$idx] . ( " " x ( $all - $half ) );
        }
    }
    elsif ( $self->{width_elements}[$idx] > $self->{col_width} ) {
        if ( $self->{col_width} > 6 ) {
            return cut_to_printwidth( $self->{list}[$idx], $self->{col_width} - 3 ) . '...';
        }
        else {
            return cut_to_printwidth( $self->{list}[$idx], $self->{col_width} );
        }
    }
    else {
        return $self->{list}[$idx];
    }
}


sub __goto {
    my ( $self, $newrow, $newcol ) = @_;
    # requires up, down, left or right to be 1 or greater
    if ( $newrow > $self->{i_row} ) {
        print down( $newrow - $self->{i_row} );
        $self->{i_row} = $newrow;
    }
    elsif ( $newrow < $self->{i_row} ) {
        print up( $self->{i_row} - $newrow );
        $self->{i_row} = $newrow;
    }
    if ( $newcol > $self->{i_col} ) {
        print right( $newcol - $self->{i_col} );
        $self->{i_col} = $newcol;
    }
    elsif ( $newcol < $self->{i_col} ) {
        print left( $self->{i_col} - $newcol );
        $self->{i_col} = $newcol;
    }
}


sub __avail_screen_size {
    my ( $self ) = @_;
    ( $self->{avail_width}, $self->{avail_height} ) = ( $self->{term_width}, $self->{term_height} );
    if ( $self->{margin_left} ) {
        $self->{avail_width} -= $self->{margin_left};
    }
    if ( $self->{margin_right} ) {
        $self->{avail_width} -= $self->{margin_right};
    }

    if ( $self->{margin_right} || ( $self->{col_width} > $self->{avail_width} ) ) {
        $self->{avail_width} += EXTRA_W;
        # + EXTRA_W: use also the last terminal column if there is only one item-column;
        #            with only one item-column the output doesn't get messed up if an item
        #            reaches the right edge of the terminal on a non-MSWin32-OS (EXTRA_W is 0 if OS is MSWin32)
    }
    if ( $self->{max_width} && $self->{avail_width} > $self->{max_width} ) {
        $self->{avail_width} = $self->{max_width};
    }
    if ( $self->{avail_width} < 1 ) {
        $self->{avail_width} = 1;
    }
    #if ( $self->{ll} && $self->{ll} > $self->{avail_width} ) {
    #    return -2;
    #}
    $self->__prepare_info_and_prompt_lines();
    if ( $self->{count_prompt_lines} ) {
        $self->{avail_height} -= $self->{count_prompt_lines};
    }
    if ( $self->{page} ) {
        $self->{avail_height}--;
    }
    if ( $self->{margin_bottom} ) {
        $self->{avail_height} -= $self->{margin_bottom};
    }
    if ( $self->{avail_height} < $self->{keep} ) {
        $self->{avail_height} = $self->{term_height} >= $self->{keep} ? $self->{keep} : $self->{term_height};
    }
    if ( $self->{max_height} && $self->{max_height} < $self->{avail_height} ) {
        $self->{avail_height} = $self->{max_height};
    }
}


sub __current_layout {
    my ( $self ) = @_;
    my $all_in_first_row;
    if ( $self->{layout} <= 1 && ! $self->{ll} && ! $self->{max_cols} ) {
        my $firstrow_width = 0;
        for my $list_idx ( 0 .. $#{$self->{list}} ) {
            $firstrow_width += $self->{width_elements}[$list_idx] + $self->{pad};
            if ( $firstrow_width - $self->{pad} > $self->{avail_width} ) {
                $firstrow_width = 0;
                last;
            }
        }
        $all_in_first_row = $firstrow_width;
    }
    if ( $all_in_first_row ) {
        $self->{current_layout} = -1;
    }
    elsif ( $self->{col_width} >= $self->{avail_width} ) {
        $self->{current_layout} = 2;
        $self->{col_width} = $self->{avail_width};
    }
    else {
        $self->{current_layout} = $self->{layout};
    }
    $self->{col_width_plus} = $self->{col_width} + $self->{pad};
    # 'col_width_plus' no effects if layout == 2
}


sub __list_idx2rc {
    my ( $self ) = @_;
    my $layout = $self->{current_layout};
    $self->{rc2idx} = [];
    if ( $layout == -1 ) {
        $self->{rc2idx}[0] = [ 0 .. $#{$self->{list}} ];
        $self->{idx_of_last_col_in_last_row} = $#{$self->{list}};
    }
    elsif ( $layout == 2 ) {
        for my $list_idx ( 0 .. $#{$self->{list}} ) {
            $self->{rc2idx}[$list_idx][0] = $list_idx;
            $self->{idx_of_last_col_in_last_row} = 0;
        }
    }
    else {
        my $tmp_avail_width = $self->{avail_width} + $self->{pad};
        # auto_format
        if ( $layout == 1 ) {
            my $tmc = int( @{$self->{list}} / $self->{avail_height} );
            $tmc++ if @{$self->{list}} % $self->{avail_height};
            $tmc *= $self->{col_width_plus};
            if ( $tmc < $tmp_avail_width ) {
                $tmc = int( $tmc + ( ( $tmp_avail_width - $tmc ) / 1.5 ) );
                $tmp_avail_width = $tmc;
            }
        }
        # order
        my $cols_per_row = int( $tmp_avail_width / $self->{col_width_plus} );
        if ( $self->{max_cols} && $cols_per_row > $self->{max_cols} ) {
            $cols_per_row = $self->{max_cols};
        }
        $cols_per_row = 1 if $cols_per_row < 1;
        $self->{idx_of_last_col_in_last_row} = ( @{$self->{list}} % $cols_per_row || $cols_per_row ) - 1;
        if ( $self->{order} == 1 ) {
            my $rows = int( ( @{$self->{list}} - 1 + $cols_per_row ) / $cols_per_row );
            my @rearranged_idx;
            my $begin = 0;
            my $end = $rows - 1 ;
            for my $c ( 0 .. $cols_per_row - 1 ) {
                --$end if $c > $self->{idx_of_last_col_in_last_row};
                $rearranged_idx[$c] = [ $begin .. $end ];
                $begin = $end + 1;
                $end = $begin + $rows - 1;
            }
            for my $r ( 0 .. $rows - 1 ) {
                my @temp_idx;
                for my $c ( 0 .. $cols_per_row - 1 ) {
                    next if $r == $rows - 1 && $c > $self->{idx_of_last_col_in_last_row};
                    push @temp_idx, $rearranged_idx[$c][$r];
                }
                push @{$self->{rc2idx}}, \@temp_idx;
            }
        }
        else {
            my $begin = 0;
            my $end = $cols_per_row - 1;
            $end = $#{$self->{list}} if $end > $#{$self->{list}};
            push @{$self->{rc2idx}}, [ $begin .. $end ];
            while ( $end < $#{$self->{list}} ) {
                $begin += $cols_per_row;
                $end   += $cols_per_row;
                $end    = $#{$self->{list}} if $end > $#{$self->{list}};
                push @{$self->{rc2idx}}, [ $begin .. $end ];
            }
        }
    }
}


sub __marked_idx2rc {
    my ( $self, $list_of_indexes, $boolean ) = @_;
    my $last_list_idx = $#{$self->{list}};
    if ( $self->{current_layout} == 2 ) {
        for my $list_idx ( @$list_of_indexes ) {
            if ( $list_idx > $last_list_idx ) {
                next;
            }
            $self->{marked}[$list_idx][0] = $boolean;
        }
        return;
    }
    my ( $row, $col );
    my $cols_per_row = @{$self->{rc2idx}[0]};
    if ( $self->{order} == 0 ) {
        for my $list_idx ( @$list_of_indexes ) {
            if ( $list_idx > $last_list_idx ) {
                next;
            }
            $row = int( $list_idx / $cols_per_row );
            $col = $list_idx % $cols_per_row;
            $self->{marked}[$row][$col] = $boolean;
        }
    }
    elsif ( $self->{order} == 1 ) {
        my $rows_per_col = @{$self->{rc2idx}};
        my $col_count_last_row = $self->{idx_of_last_col_in_last_row} + 1;
        my $last_list_idx_in_cols_full = $rows_per_col * $col_count_last_row - 1;
        my $first_list_idx_in_cols_short = $last_list_idx_in_cols_full + 1;

        for my $list_idx ( @$list_of_indexes ) {
            if ( $list_idx > $last_list_idx ) {
                next;
            }
            if ( $list_idx < $last_list_idx_in_cols_full ) {
                $row = $list_idx % $rows_per_col;
                $col = int( $list_idx / $rows_per_col );
            }
            else {
                my $rows_per_col_short = $rows_per_col - 1;
                $row = ( $list_idx - $first_list_idx_in_cols_short ) % $rows_per_col_short;
                $col = int( ( $list_idx - $col_count_last_row ) / $rows_per_col_short );
            }
            $self->{marked}[$row][$col] = $boolean;
        }
    }
}


sub __marked_rc2idx {
    my ( $self ) = @_;
    my $list_idx = [];
    if ( $self->{order} == 1 ) {
        for my $col ( 0 .. $#{$self->{rc2idx}[0]} ) {
            for my $row ( 0 .. $#{$self->{rc2idx}} ) {
                if ( $self->{marked}[$row][$col] ) {
                    push @$list_idx, $self->{rc2idx}[$row][$col];
                }
            }
        }
    }
    else {
        for my $row ( 0 .. $#{$self->{rc2idx}} ) {
            for my $col ( 0 .. $#{$self->{rc2idx}[$row]} ) {
                if ( $self->{marked}[$row][$col] ) {
                    push @$list_idx, $self->{rc2idx}[$row][$col];
                }
            }
        }
    }
    return $list_idx;
}


1;


__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Choose - Choose items from a list interactively.

=head1 VERSION

Version 1.775

=cut

=head1 SYNOPSIS

Functional interface:

    use Term::Choose qw( choose );

    my $array_ref = [ qw( one two three four five ) ];

    my $choice = choose( $array_ref );                            # single choice
    print "$choice\n";

    my @choices = choose( [ 1 .. 100 ], { alignment => 1 } );     # multiple choice
    print "@choices\n";

    choose( [ 'Press ENTER to continue' ], { prompt => '' } );    # no choice

Object-oriented interface:

    use Term::Choose;

    my $array_ref = [ qw( one two three four five ) ];

    my $new = Term::Choose->new();

    my $choice = $new->choose( $array_ref );                       # single choice
    print "$choice\n";

    my @choices = $new->choose( [ 1 .. 100 ] );                    # multiple choice
    print "@choices\n";

    my $stopp = Term::Choose->new( { prompt => '' } );
    $stopp->choose( [ 'Press ENTER to continue' ] );               # no choice

=head1 DESCRIPTION

Choose interactively from a list of items.

C<Term::Choose> provides a functional interface (L</SUBROUTINES>) and an object-oriented interface (L</METHODS>).

=head1 EXPORT

Nothing by default.

    use Term::Choose qw( choose );

=head1 METHODS

=head2 new

    $new = Term::Choose->new( \%options );

This constructor returns a new C<Term::Choose> object.

To set the different options it can be passed a reference to a hash as an optional argument.

For detailed information about the options see L</OPTIONS>.

=head2 choose

The method C<choose> allows the user to choose from a list.

The first argument is an array reference which holds the list of the available choices.

As a second and optional argument it can be passed a reference to a hash where the keys are the option names and the
values the option values.

Options set with C<choose> overwrite options set with C<new>. Before leaving C<choose> restores the
overwritten options.

    $choice = $new->choose( $array_ref, \%options );

    @choices= $new->choose( $array_ref, \%options );

              $new->choose( $array_ref, \%options );

When in the documentation is mentioned "array" or "list" or "elements" or "items" (of the array/list) than these
refer to this array passed as a reference as the first argument.

For more information how to use C<choose> and its return values see L<USAGE AND RETURN VALUES>.

=head1 SUBROUTINES

=head2 choose

The function C<choose> allows the user to choose from a list. It takes the same arguments as the method L</choose>.

    $choice = choose( $array_ref, \%options );

    @choices= choose( $array_ref, \%options );

              choose( $array_ref, \%options );

See the L</OPTIONS> section for more details about the different options and how to set them.

See also the following section L<USAGE AND RETURN VALUES>.

=head1 USAGE AND RETURN VALUES

=over

=item *

If C<choose> is called in a I<scalar context>, the user can choose an item by using the L</Keys to move around> and
confirming with C<Return>.

C<choose> then returns the chosen item.

=item *

If C<choose> is called in an I<list context>, the user can also mark an item with the C<SpaceBar>.

C<choose> then returns - when C<Return> is pressed - the list of marked items (including the highlighted item if the
option I<include_highlighted> is set to C<1>).

In I<list context> C<Ctrl-SpaceBar> (or C<Ctrl-@>) inverts the choices: marked items are unmarked and unmarked items are
marked.

=item *

If C<choose> is called in an I<void context>, the user can move around but mark nothing; the output shown by C<choose>
can be closed with C<Return>.

Called in void context C<choose> returns nothing.

If the first argument refers to an empty array, C<choose> returns nothing.

=back

If the items of the list don't fit on the screen, the user can scroll to the next (previous) page(s).

If the window size is changed, then as soon as the user enters a keystroke C<choose> rewrites the screen.

C<choose> returns C<undef> or an empty list in list context if the C<q> key (or C<Ctrl-Q>) is pressed.

If the I<mouse> mode is enabled, an item can be chosen with the left mouse key, in list context the right mouse key can
be used instead the C<SpaceBar> key.

Pressing the C<Ctrl-F> allows one to enter a regular expression so that only the items that match the regular expression
are displayed. When going back to the unfiltered menu (C<Enter>) the item highlighted in the filtered menu keeps the
highlighting. Also (in I<list context>) marked items retain there markings. The Perl function C<readline> is used to
read the regular expression if L<Term::Form::ReadLine> is not available. See option I<search>.

=head2 Keys to move around

=over

=item *

the C<Arrow> keys (or the C<h,j,k,l> keys) to move up and down or to move to the right and to the left,

=item *

the C<Tab> key (or C<Ctrl-I>) to move forward, the C<BackSpace> key (or C<Ctrl-H> or C<Shift-Tab>) to move backward,

=item *

the C<PageUp> key (or C<Ctrl-P>) to go to the previous page, the C<PageDown> key (or C<Ctrl-N>) to go to the next page,

=item *

the C<Insert> key to go back 10 pages, the C<Delete> key to go forward 10 pages,

=item *

the C<Home> key (or C<Ctrl-A>) to jump to the beginning of the list, the C<End> key (or C<Ctrl-E>) to jump to the end of
the list.

=back

=head2 Modifications for the output

For the output on the screen the array elements are modified.

All the modifications are made on a copy of the original array so C<choose> returns the chosen elements as they were
passed to the function without modifications.

Modifications:

=over

=item *

If an element is not defined the value from the option I<undef> is assigned to the element.

=item *

If an element holds an empty string the value from the option I<empty> is assigned to the element.

=item *

Tab characters in elements are replaces with a space.

    $element =~ s/\t/ /g;

=item *

Vertical spaces in elements are squashed to two spaces.

    $element =~ s/\v+/\ \ /g;

=item *

Code points from the ranges of control, surrogate and noncharacter are removed.

    $element =~ s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]//g;

=item *

If the length of an element is greater than the width of the screen the element is cut and at the end of the string are
added three dots.

=back

=head1 OPTIONS

Options which expect a number as their value expect integers.

=head3 alignment

0 - elements ordered in columns are aligned to the left (default)

1 - elements ordered in columns are aligned to the right

2 - elements ordered in columns are centered

=head3 beep

0 - off (default)

1 - on

=head3 clear_screen

0 - off (default)

1 - clears the screen before printing the choices

=head3 codepage_mapping

This option has only meaning if the operating system is MSWin32.

If the OS is MSWin32, L<Win32::Console::ANSI> is used. By default C<Win32::Console::ANSI> converts the characters from
Windows code page to DOS code page (the so-called ANSI to OEM conversion). This conversation is disabled by default in
C<Term::Choose> but one can enable it by setting this option.

Setting this option to C<1> enables the codepage mapping offered by L<Win32::Console::ANSI>.

0 - disable automatic codepage mapping (default)

1 - keep automatic codepage mapping

=head3 color

Enable the support for ANSI SGR escape sequences.

0 - off (default)

1 - enabled but the current selected element is not colored.

2 - enabled

=head3 default

With the option I<default> it can be selected an element, which will be highlighted as the default instead of the first
element.

I<default> expects a zero indexed value, so e.g. to highlight the third element the value would be I<2>.

If the passed value is greater than the index of the last array element the first element is highlighted.

Allowed values: 0 or greater

(default: undefined)

=head3 empty

Sets the string displayed on the screen instead an empty string.

(default: "<empty>")

=head3 footer

Add a string in the bottom line.

If a footer string is passed with this option, the option I<page> is automatically set to C<2>.

(default: undefined)

=head3 hide_cursor

0 - keep the terminals highlighting of the cursor position

1 - hide the terminals highlighting of the cursor position (default)

=head3 info

Expects as its value a string. The info text is printed above the prompt string.

(default: not set)

=head3 index

0 - off (default)

1 - return the index of the chosen element instead of the chosen element respective the indices of the chosen elements
instead of the chosen elements.

=head3 keep

I<keep> prevents that all the terminal rows are used by the prompt lines.

Setting I<keep> ensures that at least I<keep> terminal rows are available for printing list rows.

If the terminal height is less than I<keep> I<keep> is set to the terminal height.

Allowed values: 1 or greater

(default: 5)

=head3 layout

=over

=item *

0 - layout off

 .----------------------.   .----------------------.   .----------------------.   .----------------------.
 | .. .. .. .. .. .. .. |   | .. .. .. .. .. .. .. |   | .. .. .. .. .. .. .. |   | .. .. .. .. .. .. .. |
 |                      |   | .. .. .. .. .. .. .. |   | .. .. .. .. .. .. .. |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   | .. .. .. .. ..       |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   |                      |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   |                      |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   |                      |   | .. .. .. .. .. .. .. |
 '----------------------'   '----------------------'   '----------------------'   '----------------------'

=item *

1 - default

 .----------------------.   .----------------------.   .----------------------.   .----------------------.
 | .. .. .. .. .. .. .. |   | .. .. .. .. ..       |   | .. .. .. .. .. ..    |   | .. .. .. .. .. .. .. |
 |                      |   | .. .. .. .. ..       |   | .. .. .. .. .. ..    |   | .. .. .. .. .. .. .. |
 |                      |   | .. ..                |   | .. .. .. .. .. ..    |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   | .. .. .. .. .. ..    |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   | .. .. ..             |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   |                      |   | .. .. .. .. .. .. .. |
 '----------------------'   '----------------------'   '----------------------'   '----------------------'

2 - all in a single column

 .----------------------.   .----------------------.   .----------------------.   .----------------------.
 | ..                   |   | ..                   |   | ..                   |   | ..                   |
 | ..                   |   | ..                   |   | ..                   |   | ..                   |
 | ..                   |   | ..                   |   | ..                   |   | ..                   |
 |                      |   | ..                   |   | ..                   |   | ..                   |
 |                      |   |                      |   | ..                   |   | ..                   |
 |                      |   |                      |   |                      |   | ..                   |
 '----------------------'   '----------------------'   '----------------------'   '----------------------'

=back

If I<layout> is set to C<0> or C<1> and the unformatted list items fit in one row,  the list items are placed in one row
without column formatting. This behavior can be disabled by setting I<max_cols>.

=head3 ll

If all elements have the same length, the length can be passed with this option. C<choose> then doesn't calculate the
length of the longest element itself but uses the passed value. I<length> refers here to the number of print columns
the element will use on the terminal.

If I<ll> is set, C<choose> returns always the index(es) of the chosen item(s) regardless of how I<index> is set.

Undefined list elements are not allowed.

The replacements described in L</Modifications for the output> are not applied. If elements contain unsupported
characters the output might break.

If I<ll> is set to a value less than the length of the elements, the output could break.

If I<ll> is set and the window size has changed, choose returns immediately C<-1>.

Allowed values: 1 or greater

(default: undefined)

=head3 margin

The option I<margin> allows one to set a margin on all four sides.

I<margin> expects a reference to an array with four elements in the following order:

- top margin (number of terminal lines)

- right margin (number of terminal columns)

- bottom margin (number of terminal lines)

- left margin (number of terminal columns)

See also L</tabs_info> and L</tabs_prompt>.

Allowed values: 0 or greater. Elements beyond the fourth are ignored.

(default: undefined)

=head3 max_cols

Limit the number of columns to I<max_cols>.

I<layout> set to C<2> has always one column.

Allowed values: 1 or greater

(default: undefined)

=head3 max_height

If defined sets the maximal number of rows used for printing list items.

If the available height is less than I<max_height> then I<max_height> is set to the available height.

Height in this context means print rows.

I<max_height> overwrites I<keep> if I<max_height> is set to a value less than I<keep>.

Allowed values: 1 or greater

(default: undefined)

=head3 max_width

If defined, sets the maximal output width to I<max_width> if the terminal width is greater than I<max_width>.

To prevent the "auto-format" to use a width less than I<max_width> set I<layout> to C<0>.

Width refers here to the number of print columns.

Allowed values: 1 or greater

(default: undefined)

=head3 mouse

0 - off (default)

1 - on. Enables the Any-Event-Mouse-Mode (1003) and the Extended-SGR-Mouse-Mode (1006).

If the option I<mouse> is enabled layers for C<STDIN> are changed. Then before leaving C<choose> as a cleanup C<STDIN>
is marked as C<UTF-8> with C<:encoding(UTF-8)>. This doesn't apply if the OS is MSWin32.

If the OS is MSWin32 the mouse is enabled with the help of L<Win32::Console>.

=head3 order

If the output has more than one row and more than one column:

0 - elements are ordered horizontally

1 - elements are ordered vertically (default)

Default may change in a future release.

=head3 pad

Sets the number of whitespaces between columns. (default: 2)

Allowed values: 0 or greater

=head3 page

0 - off

1 - print the page number on the bottom of the screen. If all the choices fit into one page, the page number is not
displayed. (default)

2 - the page number is always displayed even with only one page. Setting I<page> to C<2> automatically enables the
option L<clear_screen>.

=head3 prompt

If I<prompt> is undefined, a default prompt-string will be shown.

If the I<prompt> value is an empty string (""), no prompt-line will be shown.

default in list and scalar context: C<Your choice:>

default in void context: C<Close with ENTER>

=head3 search

Set the behavior of C<Ctrl-F>.

0 - off

1 - case-insensitive search (default)

2 - case-sensitive search

=head3 skip_items

When navigating through the list, the elements that match the regex pattern passed with this option will be skipped.

In list context: these elements cannot be marked.

Expected value: a regex quoted with the C<qr> operator.

(default: undefined)

=head3 tabs_info

The option I<tabs_info> allows one to insert spaces at the beginning and the end of I<info> lines.

I<tabs_info> expects a reference to an array with one to three elements:

- the first element (initial tab) sets the number of spaces inserted at beginning of paragraphs

- the second element (subsequent tab) sets the number of spaces inserted at the beginning of all broken lines apart from
the beginning of paragraphs

- the third element sets the number of spaces used as a right margin.

Allowed values: 0 or greater. Elements beyond the third are ignored.

default: If I<margin> is defined, the initial tab and the subsequent tab are set to left-I<margin> and the right margin
is set to right-I<margin>. If I<margin> is not defined, the default is undefined.

=head3 tabs_prompt

The option I<tabs_prompt> allows one to insert spaces at the beginning and the end of I<prompt> lines.

I<tabs_prompt> expects a reference to an array with one to three elements:

- the first element (initial tab) sets the number of spaces inserted at beginning of paragraphs

- the second element (subsequent tab) sets the number of spaces inserted at the beginning of all broken lines apart from
the beginning of paragraphs

- the third element sets the number of spaces used as a right margin.

Allowed values: 0 or greater. Elements beyond the third are ignored.

default: If I<margin> is defined, the initial tab and the subsequent tab are set to left-I<margin> and the right margin
is set to right-I<margin>. If I<margin> is not defined, the default is undefined.

=head3 undef

Sets the string displayed on the screen instead an undefined element.

default: "<undef>"

=head2 Options List Context

=head3 include_highlighted

In list context when C<Return> is pressed

0 - C<choose> returns the items marked with the C<SpaceBar>. (default)

1 - C<choose> returns the items marked with the C<SpaceBar> plus the highlighted item.

2 - C<choose> returns the items marked with the C<SpaceBar>. If no items are marked with the C<SpaceBar>, the
highlighted item is returned.

=head3 mark

I<mark> expects as its value a reference to an array. The elements of the array are list indexes. C<choose> preselects
the list-elements correlating to these indexes.

Elements greater than the last index of the list are ignored.

This option has only meaning in list context.

(default: undefined)

=head3 meta_items

I<meta_items> expects as its value a reference to an array. The elements of the array are list indexes. These elements
can not be marked with the C<SpaceBar> or with the right mouse key but if one of these elements is the highlighted item
it is added to the chosen items when C<Return> is pressed.

Elements greater than the last index of the list are ignored.

This option has only meaning in list context.

(default: undefined)

=head3 no_spacebar

I<no_spacebar> expects as its value a reference to an array. The elements of the array are indexes of the list which
should not be markable with the C<SpaceBar> or with the right mouse key.

If an element is preselected with the option I<mark> and also marked as not selectable with the option I<no_spacebar>,
the user can not remove the preselection of this element.

I<no_spacebar> elements greater than the last index of the list are ignored.

This option has only meaning in list context.

(default: undefined)

=head1 ERROR HANDLING

=head2 croak

C<new|choose> croaks if passed invalid arguments.

=head2 carp

If pressing a key results in an undefined value C<choose> carps with C<EOT: $!> and returns I<undef> or an empty list in
list context.

=head1 REQUIREMENTS

=head2 Perl version

Requires Perl version 5.10.1 or higher.

=head2 Optional modules

=head3 Term::Choose::LineFold::XS

If L<Term::Choose::LineFold::XS> is installed, its functions will be used automatically in place of the pure-Perl
implementations, providing faster performance. C<Term::Choose::LineFold::XS> requires Perl version 5.16.0 or higher.

=head3 Term::ReadKey

If L<Term::ReadKey> is available it is used C<ReadKey> to read the user input and C<GetTerminalSize> to get the
terminal size. Without C<Term::ReadKey> C<getc> is used to read the input and C<stty size> to get the terminal size.

If the OS is MSWin32 it is used L<Win32::Console> to read the user input and to get the terminal size.

=head2 Decoded strings

C<choose> expects decoded strings as array elements.

=head2 Encoding layer for STDOUT

For a correct output it is required an appropriate encoding layer for STDOUT matching the terminal's character set.

=head2 Monospaced font

It is required a terminal that uses a monospaced font which supports the printed characters.

=head2 Ambiguous width characters

By default ambiguous width characters are treated as half width. If the environment variable
C<TC_AMBIGUOUS_WIDTH_IS_WIDE> is set to a true value, ambiguous width characters are treated as full width.

The support for the old variable name C<TC_AMBIGUOUS_WIDE> will be removed.

=head2 Escape sequences

By default C<Term::Choose> uses C<tput> to get the appropriate escape sequences. If the environment variable
C<TC_ANSI_ESCAPES> is set to a true value, hardcoded ANSI escape sequences are used directly without calling C<tput>.

The escape sequences to enable the I<mouse> mode are always hardcoded.

=head2 Other environment variables

If the environment variable C<TC_RESET_AUTO_UP> existed when calling C<choose>: C<TC_RESET_AUTO_UP> is set to C<0> if
the C<LINE_FEED>/C<CARRIAGE_RETURN> key was the only key pressed and C<TC_RESET_AUTO_UP> is set to C<1> if other keys
than C<LINE_FEED>/C<CARRIAGE_RETURN> were also pressed.

=head2 MSWin32

If the OS is MSWin32 L<Win32::Console> and L<Win32::Console::ANSI> with ANSI escape sequences are used. See also
L</codepage_mapping>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::Choose

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 CREDITS

Based on the C<choose> function from the L<Term::Clui> module.

Thanks to the L<Perl-Community.de|http://www.perl-community.de> and the people form
L<stackoverflow|http://stackoverflow.com> for the help.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2025 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
