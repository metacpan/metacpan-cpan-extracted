package Term::Choose;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.712';
use Exporter 'import';
our @EXPORT_OK = qw( choose );

use Carp qw( croak carp );

use Term::Choose::Constants       qw( :keys WIDTH_CURSOR );
use Term::Choose::LineFold        qw( line_fold print_columns cut_to_printwidth );
use Term::Choose::Screen          qw( :all );
use Term::Choose::ValidateOptions qw( validate_options );

use constant {
    ROW => 0,
    COL => 1,
};


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


sub new {
    my $class = shift;
    my ( $opt ) = @_;
    croak "new: called with " . @_ . " arguments - 0 or 1 arguments expected" if @_ > 1;
    my $instance_defaults = _defaults();
    if ( defined $opt ) {
        croak "new: the (optional) argument must be a HASH reference" if ref $opt ne 'HASH';
        validate_options( _valid_options(), $opt );
        for my $key ( keys %$opt ) {
            $instance_defaults->{$key} = $opt->{$key} if defined $opt->{$key};
        }
    }
    my $self = bless $instance_defaults, $class;
    $self->{backup_instance_defaults} = { %$instance_defaults };
    $self->{plugin} = $Plugin->new();
    return $self;
}


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
        #mark               => undef,
        #max_height         => undef,
        #max_width          => undef,
        mouse               => 0,
        #meta_items         => undef,
        #no_spacebar        => undef,
        order               => 1,
        pad                 => 2,
        page                => 1,
        #prompt             => undef,
        #tabs_info          => undef,
        #tabs_prompt        => undef,
        undef               => '<undef>',
        #busy_string        => undef,
    };
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
        page                => '[ 0 1 ]',
        alignment           => '[ 0 1 2 ]',
        color               => '[ 0 1 2 ]',
        include_highlighted => '[ 0 1 2 ]',
        layout              => '[ 0 1 2 3 ]',
        keep                => '[ 1-9 ][ 0-9 ]*',
        ll                  => '[ 1-9 ][ 0-9 ]*',
        max_height          => '[ 1-9 ][ 0-9 ]*',
        max_width           => '[ 1-9 ][ 0-9 ]*',
        default             => '[ 0-9 ]+',
        pad                 => '[ 0-9 ]+',
        mark                => 'Array_Int',
        meta_items          => 'Array_Int',
        no_spacebar         => 'Array_Int',
        tabs_info           => 'Array_Int',
        tabs_prompt         => 'Array_Int',
        empty               => 'Str',
        footer              => 'Str',
        footer_string       => 'Str',   # for Term:TablePrint versions 0.120 - 0.122     22.10.2020
        info                => 'Str',
        prompt              => 'Str',
        undef               => 'Str',
        busy_string         => 'Str',
    };
};


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
                $_ = $self->{empty} if $_ eq '';    #
            }
            if ( $self->{color} ) {
                s/\x{feff}//g;
                s/\e\[[\d;]*m/\x{feff}/g;
            }
            s/\t/ /g;
            s/[\x{000a}-\x{000d}\x{0085}\x{2028}\x{2029}]+/\ \ /g; # \v 5.10
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
        $self->{length} = $length_elements;
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
    my ( $self, $from_choose ) = @_;
    if ( defined $self->{plugin} ) {
        $self->{plugin}->__reset_mode();
    }
    if ( $from_choose ) {
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
    my $key = $self->{plugin}->__get_key_OS( $self->{mouse} );
    return $key if ref $key ne 'ARRAY';
    return $self->__mouse_info_to_key( @$key );
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

        ##### 22.10.2020
        if ( ! defined $opt->{footer} && defined $opt->{footer_string} ) {
            $opt->{footer} = $opt->{footer_string};
        }
        #####

        validate_options( _valid_options(), $opt );
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
    if ( ! defined $self->{prompt} ) {
        $self->{prompt} = defined $self->{wantarray} ? 'Your choice:' : 'Close with ENTER';
    }
    if ( $^O eq "MSWin32" ) {
        print $opt->{codepage_mapping} ? "\e(K" : "\e(U";
    }
    $self->__copy_orig_list( $orig_list_ref );
    $self->__length_list_elements();
    if ( exists $ENV{TC_RESET_AUTO_UP} ) {
        $ENV{TC_RESET_AUTO_UP} = 0;
    }
    local $SIG{INT} = sub {
        $self->__reset_term();
        exit;
    };
    $self->__init_term();
    ( $self->{term_width}, $self->{term_height} ) = get_term_size();
    $self->__write_first_screen();
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
        my ( $new_width, $new_height ) = get_term_size();
        if ( $new_width != $self->{term_width} || $new_height != $self->{term_height} ) {
            if ( $self->{ll} ) {
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
            $self->__write_first_screen();
            next GET_KEY;
        }
        next GET_KEY if $key == NEXT_get_key;
        next GET_KEY if $key == KEY_Tilde;
        if ( exists $ENV{TC_RESET_AUTO_UP} ) {
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
        # $self->{rc2idx} holds the new list (AoA) formatted in "__list_idx_to_rowcol" appropriate to the chosen layout.
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
        elsif ( $key == KEY_TAB || $key == CONTROL_I ) {
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
        elsif ( $key == KEY_BSPACE || $key == CONTROL_H || $key == KEY_BTAB ) {
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
        elsif ( $key == VK_PAGE_UP || $key == CONTROL_B ) {
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
        elsif ( $key == VK_PAGE_DOWN || $key == CONTROL_F ) {
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
            if ( $self->{order} == 1 && $self->{rest} ) {
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
        elsif ( $key == LINE_FEED || $key == CARRIAGE_RETURN ) { # ENTER key
            my $index = $self->{index} || $self->{ll};
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
                        if ( $meta_item == $self->{rc2idx}[$self->{pos}[ROW]][$self->{pos}[COL]] ) {
                            $self->{marked}[$self->{pos}[ROW]][$self->{pos}[COL]] = 1;
                            last;
                        }
                    }
                }
                my $chosen = $self->__marked_rc2idx();
                $self->__reset_term( 1 );
                return $index ? @$chosen : @{$orig_list_ref}[@$chosen];
            }
            else {
                my $i = $self->{rc2idx}[$self->{pos}[ROW]][$self->{pos}[COL]];
                my $chosen = $index ? $i : $orig_list_ref->[$i];
                $self->__reset_term( 1 );
                return $chosen;
            }
        }
        elsif ( $key == KEY_SPACE ) {
            if ( $self->{wantarray} ) {
                my $locked = 0;
                if ( defined $self->{no_spacebar} || defined $self->{meta_items} ) {
                    for my $no_spacebar ( @{$self->{no_spacebar}||[]}, @{$self->{meta_items}||[]} ) {
                        if ( $self->{rc2idx}[$self->{pos}[ROW]][$self->{pos}[COL]] == $no_spacebar ) {
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
        }
        elsif ( $key == CONTROL_SPACE ) {
            if ( $self->{wantarray} ) {
                for my $i ( 0 .. $#{$self->{rc2idx}} ) {
                    for my $j ( 0 .. $#{$self->{rc2idx}[$i]} ) {
                        $self->{marked}[$i][$j] = ! $self->{marked}[$i][$j];
                    }
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


sub __prepare_promptline {
    my ( $self ) = @_;
    my $prompt = '';
    if ( length $self->{info} ) {
        my $init   = $self->{tabs_info}[0] ? $self->{tabs_info}[0] : 0;
        my $subseq = $self->{tabs_info}[1] ? $self->{tabs_info}[1] : 0;
        $prompt .= line_fold(
            $self->{info}, $self->{avail_width},
            { init_tab => ' ' x $init, subseq_tab => ' ' x $subseq, color => $self->{color}, join => 1 }
        );
    }
    if ( length $self->{prompt} ) {
        if ( length $prompt ) {
            $prompt .= "\n";
        }
        my $init   = $self->{tabs_prompt}[0] ? $self->{tabs_prompt}[0] : 0;
        my $subseq = $self->{tabs_prompt}[1] ? $self->{tabs_prompt}[1] : 0;
        $prompt .= line_fold(
            $self->{prompt}, $self->{avail_width},
            { init_tab => ' ' x $init, subseq_tab => ' ' x $subseq, color => $self->{color}, join => 1 }
        );
    }
    if ( $prompt eq '' ) {
        $self->{prompt_copy} = '';
        $self->{count_prompt_lines} = 0;
        return;
    }
    $self->{prompt_copy} = $prompt;
    $self->{prompt_copy} .= "\n\r";
    # s/\n/\n\r/g; -> stty 'raw' mode and Term::Readkey 'ultra-raw' mode
    #                 don't translate newline to carriage return-newline
    $self->{count_prompt_lines} = $self->{prompt_copy} =~ s/\n/\n\r/g;
}


sub __prepare_page_number {
    my ( $self ) = @_;
    if ( ( @{$self->{rc2idx}} / ( $self->{avail_height} + $self->{pp_row} ) > 1 ) || defined $self->{footer} ) {
        my $pp_total = int( $#{$self->{rc2idx}} / $self->{avail_height} ) + 1;
        my $pp_total_w = length $pp_total;
        if ( defined $self->{footer} ) {
            $self->{footer_fmt} = '%0' . $pp_total_w . 'd/' . $pp_total . ' ' . $self->{footer};
        }
        else {
            $self->{footer_fmt} = '--- Page %0' . $pp_total_w . 'd/' . $pp_total . ' ---';
        }
        if ( print_columns( sprintf $self->{footer_fmt}, $pp_total ) > $self->{avail_width} ) { # color, length
            $self->{footer_fmt} = '%0' . $pp_total_w . 'd/' . $pp_total;
            if ( length( sprintf $self->{footer_fmt}, $pp_total ) > $self->{avail_width} ) {
                $pp_total_w = $self->{avail_width} if $pp_total_w > $self->{avail_width};
                $self->{footer_fmt} = '%0' . $pp_total_w . '.' . $pp_total_w . 's';
            }
        }
        $self->{pp_count} = $pp_total;
    }
    else {
        $self->{avail_height} += $self->{pp_row};
        $self->{pp_row} = 0;
        $self->{pp_count} = 1;
    }
}


sub __set_default_cell {
    my ( $self ) = @_;
    LOOP: for my $i ( 0 .. $#{$self->{rc2idx}} ) {
        for my $j ( 0 .. $#{$self->{rc2idx}[$i]} ) {
            if ( $self->{default} == $self->{rc2idx}[$i][$j] ) {
                $self->{pos} = [ $i, $j ];
                last LOOP;
            }
        }
    }
    $self->{first_page_row} = $self->{avail_height} * int( $self->{pos}[ROW] / $self->{avail_height} );
    $self->{last_page_row} = $self->{first_page_row} + $self->{avail_height} - 1;
    $self->{last_page_row} = $#{$self->{rc2idx}} if $self->{last_page_row} > $#{$self->{rc2idx}};
}


sub __write_first_screen {
    my ( $self ) = @_;
    ( $self->{avail_width}, $self->{avail_height} ) = ( $self->{term_width}, $self->{term_height} );
    if ( $self->{col_width} > $self->{avail_width} && $^O ne 'MSWin32' && $^O ne 'cygwin' ) {
        $self->{avail_width} += WIDTH_CURSOR;
        # + WIDTH_CURSOR: use also the last terminal column if there is only one print-column;
        #                 with only one print-column the output doesn't get messed up if an item
        #                 reaches the right edge of the terminal on a non-MSWin32-OS
    }
    #if ( $self->{ll} && $self->{ll} > $self->{avail_width} ) {
    #    return -2;
    #}
    if ( $self->{max_width} && $self->{avail_width} > $self->{max_width} ) {
        $self->{avail_width} = $self->{max_width};
    }
    if ( $self->{avail_width} < 1 ) {
        $self->{avail_width} = 1;
    }
    $self->__prepare_promptline();
    $self->{pp_row} = $self->{page} || $self->{footer} ? 1 : 0;
    $self->{avail_height} -= $self->{count_prompt_lines} + $self->{pp_row};
    if ( $self->{avail_height} < $self->{keep} ) {
        $self->{avail_height} = $self->{term_height} >= $self->{keep} ? $self->{keep} : $self->{term_height};
    }
    if ( $self->{max_height} && $self->{max_height} < $self->{avail_height} ) {
        $self->{avail_height} = $self->{max_height};
    }
    $self->__current_layout();
    $self->__list_idx_to_rowcol();
    if ( $self->{page} ) {
        $self->__prepare_page_number();
    }
    $self->{avail_height_idx} = $self->{avail_height} - 1;
    $self->{first_page_row} = 0;
    $self->{last_page_row}  = $self->{avail_height_idx} > $#{$self->{rc2idx}} ? $#{$self->{rc2idx}} : $self->{avail_height_idx};
    $self->{i_row}  = 0;
    $self->{i_col}  = 0;
    $self->{pos}    = [ 0, 0 ];
    $self->{marked} = [];
    if ( $self->{wantarray} && defined $self->{mark} ) {
        $self->__marked_idx2rc( $self->{mark}, 1 );
    }
    if ( defined $self->{default} && $self->{default} <= $#{$self->{list}} ) {
        $self->__set_default_cell();
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
    if ( $self->{pp_row} ) {
        $self->__goto( $self->{avail_height_idx} + $self->{pp_row}, 0 );
        my $pp_line = sprintf $self->{footer_fmt}, int( $self->{first_page_row} / $self->{avail_height} ) + 1;
        print $pp_line;
        $self->{i_col} += print_columns( $pp_line );
    }
    for my $row ( $self->{first_page_row} .. $self->{last_page_row} ) {
        for my $col ( 0 .. $#{$self->{rc2idx}[$row]} ) {
            $self->__wr_cell( $row, $col );
        }
    }
    $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
}


sub __wr_cell {
    my( $self, $row, $col ) = @_;
    my $is_current_pos = $row == $self->{pos}[ROW] && $col == $self->{pos}[COL];
    my $emphasised = ( $self->{marked}[$row][$col] ? bold_underline() : '' ) . ( $is_current_pos ? reverse_video() : '' );
    my $idx = $self->{rc2idx}[$row][$col];
    if ( $self->{ll} ) {
        $self->__goto( $row - $self->{first_page_row}, $col * $self->{col_width_plus} );
        $self->{i_col} = $self->{i_col} + $self->{col_width};
        if ( $self->{color} ) {
            my $str = $self->{list}[$idx];
            if ( $emphasised ) {
                if ( $is_current_pos && $self->{color} == 1 ) {
                    # no color for selected cell
                    $str =~ s/(\e\[[\d;]*m)//g;
                }
                else {
                    # keep cell marked after color escapes
                    $str =~ s/(\e\[[\d;]*m)/${1}$emphasised/g;
                }
                $str = $emphasised . $str;
            }
            print $str . normal(); # if \e[
        }
        else {
            if ( $emphasised ) {
                print $emphasised . $self->{list}[$idx] . normal();
            }
            else {
                print $self->{list}[$idx];
            }
        }
    }
    else {
        my $str;
        if ( $self->{current_layout} == -1 ) {
            my $x = 0;
            if ( $col > 0 ) {
                for my $cl ( 0 .. $col - 1 ) {
                    my $i = $self->{rc2idx}[$row][$cl];
                    $x += $self->{length}[$i] + $self->{pad};
                }
            }
            $self->__goto( $row - $self->{first_page_row}, $x );
            $self->{i_col} = $self->{i_col} + $self->{length}[$idx];
            $str = $self->{list}[$idx];
        }
        else {
            $self->__goto( $row - $self->{first_page_row}, $col * $self->{col_width_plus} );
            $self->{i_col} = $self->{i_col} + $self->{col_width};
            $str = $self->__pad_str_to_colwidth( $idx );
        }
        if ( $self->{color} ) {
            my @color;
            if ( ! $self->{orig_list}[$idx] ) {
                if ( ! defined $self->{orig_list}[$idx] ) {
                    @color = $self->{undef} =~ /(\e\[[\d;]*m)/g;
                }
                elsif ( ! length $self->{orig_list}[$idx] ) {
                    @color = $self->{empty} =~ /(\e\[[\d;]*m)/g;
                }
            }
            else {
                @color = $self->{orig_list}[$idx] =~ /(\e\[[\d;]*m)/g;
            }
            if ( $emphasised ) {
                for ( @color ) {
                    # keep cell marked after color escapes
                    $_ .= $emphasised;
                }
                $str = $emphasised . $str . normal();
                if ( $is_current_pos && $self->{color} == 1 ) {
                    # no color for selected cell
                    @color = ();
                    $str =~ s/\x{feff}//g;
                }
            }
            if ( @color ) {
                $str =~ s/\x{feff}/shift @color/ge;
                if ( ! $emphasised ) {
                    $str .= normal();
                }
            }
            print $str;
        }
        else {
            if ( $emphasised ) {
                print $emphasised . $str . normal();
            }
            else {
                print $str;
            }
        }
    }
}


sub __pad_str_to_colwidth {
    my ( $self, $idx ) = @_;
    if ( $self->{length}[$idx] < $self->{col_width} ) {
        if ( $self->{alignment} == 0 ) {
            return $self->{list}[$idx] . ( " " x ( $self->{col_width} - $self->{length}[$idx] ) );
        }
        elsif ( $self->{alignment} == 1 ) {
            return " " x ( $self->{col_width} - $self->{length}[$idx] ) . $self->{list}[$idx];
        }
        elsif ( $self->{alignment} == 2 ) {
            my $all = $self->{col_width} - $self->{length}[$idx];
            my $half = int( $all / 2 );
            return ( " " x $half ) . $self->{list}[$idx] . ( " " x ( $all - $half ) );
        }
    }
    elsif ( $self->{length}[$idx] > $self->{col_width} ) {
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
    # up, down, left, right: 1 or greater
    if ( $newrow > $self->{i_row} ) {
        print "\r\n" x ( $newrow - $self->{i_row} );
        $self->{i_row} = $newrow;
        $self->{i_col} = 0;
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


sub __current_layout {
    my ( $self ) = @_;
    my $all_in_first_row;
    if ( $self->{layout} <= 1 && ! $self->{ll} ) {
        my $firstrow_w = 0;
        for my $idx ( 0 .. $#{$self->{list}} ) {
            $firstrow_w += $self->{length}[$idx] + $self->{pad};
            if ( $firstrow_w - $self->{pad} > $self->{avail_width} ) {
                $firstrow_w = 0;
                last;
            }
        }
        $all_in_first_row = $firstrow_w;
    }
    if ( $all_in_first_row ) {
        $self->{current_layout} = -1;
    }
    elsif ( $self->{col_width} >= $self->{avail_width} ) {
        $self->{current_layout} = 3;
        $self->{col_width} = $self->{avail_width};
    }
    else {
        $self->{current_layout} = $self->{layout};
    }
    $self->{col_width_plus} = $self->{col_width} + $self->{pad};
    # 'col_width_plus' no effects if layout == 3
}


sub __list_idx_to_rowcol {
    my ( $self ) = @_;
    my $layout = $self->{current_layout};
    $self->{rc2idx} = [];
    if ( $layout == -1 ) {
        $self->{rc2idx}[0] = [ 0 .. $#{$self->{list}} ];
    }
    elsif ( $layout == 3 ) {
        for my $idx ( 0 .. $#{$self->{list}} ) {
            $self->{rc2idx}[$idx][0] = $idx;
        }
    }
    else {
        my $tmp_avail_width = $self->{avail_width} + $self->{pad};
        # auto_format
        if ( $layout == 1 || $layout == 2 ) {
            my $tmc = int( @{$self->{list}} / $self->{avail_height} );
            $tmc++ if @{$self->{list}} % $self->{avail_height};
            $tmc *= $self->{col_width_plus};
            if ( $tmc < $tmp_avail_width ) {
                $tmc = int( $tmc + ( ( $tmp_avail_width - $tmc ) / 1.5 ) ) if $layout == 1;
                $tmc = int( $tmc + ( ( $tmp_avail_width - $tmc ) / 4 ) )   if $layout == 2;
                $tmp_avail_width = $tmc;
            }
        }
        # order
        my $cols_per_row = int( $tmp_avail_width / $self->{col_width_plus} );
        $cols_per_row = 1 if $cols_per_row < 1;
        $self->{rest} = @{$self->{list}} % $cols_per_row;
        if ( $self->{order} == 1 ) {
            my $rows = int( ( @{$self->{list}} - 1 + $cols_per_row ) / $cols_per_row );
            my @rearranged_idx;
            my $begin = 0;
            my $end = $rows - 1;
            for my $c ( 0 .. $cols_per_row - 1 ) {
                --$end if $self->{rest} && $c >= $self->{rest};
                $rearranged_idx[$c] = [ $begin .. $end ];
                $begin = $end + 1;
                $end = $begin + $rows - 1;
            }
            for my $r ( 0 .. $rows - 1 ) {
                my @temp_idx;
                for my $c ( 0 .. $cols_per_row - 1 ) {
                    next if $r == $rows - 1 && $self->{rest} && $c >= $self->{rest};
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
    if ( $self->{current_layout} == 3 ) {
        for my $idx ( @$list_of_indexes ) {
            next if $idx > $last_list_idx;
            $self->{marked}[$idx][0] = $boolean;
        }
        return;
    }
    my ( $row, $col );
    my $cols_per_row = @{$self->{rc2idx}[0]};
    if ( $self->{order} == 0 ) {
        for my $idx ( @$list_of_indexes ) {
            next if $idx > $last_list_idx;
            $row = int( $idx / $cols_per_row );
            $col = $idx % $cols_per_row;
            $self->{marked}[$row][$col] = $boolean;
        }
    }
    elsif ( $self->{order} == 1 ) {
        my $rows_per_col = @{$self->{rc2idx}};
        my $end_last_full_col = $rows_per_col * ( $self->{rest} || $cols_per_row );
        for my $idx ( @$list_of_indexes ) {
            next if $idx > $last_list_idx;
            if ( $idx <= $end_last_full_col ) {
                $row = $idx % $rows_per_col;
                $col = int( $idx / $rows_per_col );
            }
            else {
                my $rows_per_col_short = $rows_per_col - 1;
                $row = ( $idx - $end_last_full_col ) % $rows_per_col_short;
                $col = int( ( $idx - $self->{rest} ) / $rows_per_col_short );
            }
            $self->{marked}[$row][$col] = $boolean;
        }
    }
}


sub __marked_rc2idx {
    my ( $self ) = @_;
    my $idx = [];
    if ( $self->{order} == 1 ) {
        for my $col ( 0 .. $#{$self->{rc2idx}[0]} ) {
            for my $row ( 0 .. $#{$self->{rc2idx}} ) {
                if ( $self->{marked}[$row][$col] ) {
                    push @$idx, $self->{rc2idx}[$row][$col];
                }
            }
        }
    }
    else {
        for my $row ( 0 .. $#{$self->{rc2idx}} ) {
            for my $col ( 0 .. $#{$self->{rc2idx}[$row]} ) {
                if ( $self->{marked}[$row][$col] ) {
                    push @$idx, $self->{rc2idx}[$row][$col];
                }
            }
        }
    }
    return $idx;
}


sub __mouse_info_to_key {
    my ( $self, $button, $mouse_x, $mouse_y ) = @_;
    if ( $button == 4 ) {
        return VK_PAGE_UP;
    }
    elsif ( $button == 5 ) {
        return VK_PAGE_DOWN;
    }
    # ..._y, ..._x: absolute position, one-based index
    my $mouse_row = $mouse_y - 1 - $self->{offset_rows};
    my $mouse_col = $mouse_x - 1;
    if ( $mouse_row < 0 || $mouse_row > $#{$self->{rc2idx}} ) {
        return NEXT_get_key;
    }
    my $matched_col;
    my $begin_this_col = 0;
    my $row = $mouse_row + $self->{first_page_row};

    COL: for my $col ( 0 .. $#{$self->{rc2idx}[$row]} ) {
        my $begin_next_col;
        if ( $self->{current_layout} == -1 ) {
            my $idx = $self->{rc2idx}[$row][$col];
            $begin_next_col = $begin_this_col + $self->{length}[$idx] + $self->{pad};
        }
        else {
            $begin_next_col = $begin_this_col + $self->{col_width_plus};
        }
        if ( $col == 0 ) {
            $begin_next_col -= int( $self->{pad} / 2 );
        }
        if ( $col == $#{$self->{rc2idx}[$row]} && $begin_next_col > $self->{avail_width} ) {
            $begin_next_col = $self->{avail_width};
        }
        if ( $mouse_col >= $begin_this_col && $mouse_col < $begin_next_col ) {
            $matched_col = $col;
            last COL;
        }
        $begin_this_col = $begin_next_col;
    }
    if ( ! defined $matched_col ) {
        return NEXT_get_key;
    }
    if ( $button == 1 ) {
        $self->{pos}[ROW] = $row;
        $self->{pos}[COL] = $matched_col;
        return LINE_FEED;
    }
    if ( $row != $self->{pos}[ROW] || $matched_col != $self->{pos}[COL] ) {
        my $not_pos = $self->{pos};
        $self->{pos} = [ $row, $matched_col ];
        $self->__wr_cell( $not_pos->[0], $not_pos->[1] );
        $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
    }
    if ( $button == 3 ) {
        return KEY_SPACE;
    }
    else {
        return NEXT_get_key;
    }
}



1;


__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Choose - Choose items from a list interactively.

=head1 VERSION

Version 1.712

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

    $new = Term::Choose->new( [ \%options] );

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

    $choice = $new->choose( $array_ref [, \%options] );

    @choices= $new->choose( $array_ref [, \%options] );

              $new->choose( $array_ref [, \%options] );

When in the documentation is mentioned "array" or "list" or "elements" or "items" (of the array/list) than these
refer to this array passed as a reference as the first argument.

For more information how to use C<choose> and its return values see L<USAGE AND RETURN VALUES>.

=head1 SUBROUTINES

=head2 choose

The function C<choose> allows the user to choose from a list. It takes the same arguments as the method L</choose>.

    $choice = choose( $array_ref [, \%options] );

    @choices= choose( $array_ref [, \%options] );

              choose( $array_ref [, \%options] );

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

=head2 Keys to move around

=over

=item *

the C<Arrow> keys (or the C<h,j,k,l> keys) to move up and down or to move to the right and to the left,

=item *

the C<Tab> key (or C<Ctrl-I>) to move forward, the C<BackSpace> key (or C<Ctrl-H> or C<Shift-Tab>) to move backward,

=item *

the C<PageUp> key (or C<Ctrl-B>) to go back one page, the C<PageDown> key (or C<Ctrl-F>) to go forward one page,

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

Enable the support for color and text formatting escape sequences.

0 - off (default)

1 - Enables the support for color and text formatting escape sequences except for the current selected element.

2 - Enables the support for color and text formatting escape sequences including for the current selected element (shown
in inverted colors).

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

From broad to narrow: 0 > 1 > 2 > 3

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

1 - layout "H" (default)

 .----------------------.   .----------------------.   .----------------------.   .----------------------.
 | .. .. .. .. .. .. .. |   | .. .. .. .. ..       |   | .. .. .. .. .. ..    |   | .. .. .. .. .. .. .. |
 |                      |   | .. .. .. .. ..       |   | .. .. .. .. .. ..    |   | .. .. .. .. .. .. .. |
 |                      |   | .. ..                |   | .. .. .. .. .. ..    |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   | .. .. .. .. .. ..    |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   | .. .. ..             |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   |                      |   | .. .. .. .. .. .. .. |
 '----------------------'   '----------------------'   '----------------------'   '----------------------'

=item *

2 - layout "V"

 .----------------------.   .----------------------.   .----------------------.   .----------------------.
 | .. ..                |   | .. .. ..             |   | .. .. .. ..          |   | .. .. .. .. .. .. .. |
 | .. ..                |   | .. .. ..             |   | .. .. .. ..          |   | .. .. .. .. .. .. .. |
 | ..                   |   | .. .. ..             |   | .. .. .. ..          |   | .. .. .. .. .. .. .. |
 |                      |   | .. ..                |   | .. .. ..             |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   | .. .. ..             |   | .. .. .. .. .. .. .. |
 |                      |   |                      |   |                      |   | .. .. .. .. .. .. .. |
 '----------------------'   '----------------------'   '----------------------'   '----------------------'

=item *

3 - all in a single column

 .----------------------.   .----------------------.   .----------------------.   .----------------------.
 | ..                   |   | ..                   |   | ..                   |   | ..                   |
 | ..                   |   | ..                   |   | ..                   |   | ..                   |
 | ..                   |   | ..                   |   | ..                   |   | ..                   |
 |                      |   | ..                   |   | ..                   |   | ..                   |
 |                      |   |                      |   | ..                   |   | ..                   |
 |                      |   |                      |   |                      |   | ..                   |
 '----------------------'   '----------------------'   '----------------------'   '----------------------'

=back

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

=head3 max_height

If defined sets the maximal number of rows used for printing list items.

If the available height is less than I<max_height> then I<max_height> is set to the available height.

Height in this context means print rows.

I<max_height> overwrites I<keep> if I<max_height> is set to a value less than I<keep>.

Allowed values: 1 or greater

(default: undefined)

=head3 max_width

If defined, sets the maximal output width to I<max_width> if the terminal width is greater than I<max_width>.

To prevent the "auto-format" to use a width less than I<max_width> set I<layout> to 0.

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

1 - print the page number on the bottom of the screen if there is more then one page. (default)

=head3 prompt

If I<prompt> is undefined a default prompt-string will be shown.

If the I<prompt> value is an empty string ("") no prompt-line will be shown.

default in list and scalar context: C<Your choice:>

default in void context: C<Close with ENTER>

=head3 tabs_info

If I<info> lines are folded, the option I<tabs_info> allows one to insert spaces at beginning of the folded lines.

The option I<tabs_info> expects a reference to an array with one or two elements:

- the first element (initial tab) sets the number of spaces inserted at beginning of paragraphs

- a second element (subsequent tab) sets the number of spaces inserted at the beginning of all broken lines apart
from the beginning of paragraphs

Allowed values: 0 or greater. Elements beyond the second are ignored.

(default: undefined)

=head3 tabs_prompt

If I<prompt> lines are folded, the option I<tabs_prompt> allows one to insert spaces at beginning of the folded lines.

The option I<tabs_prompt> expects a reference to an array with one or two elements:

- the first element (initial tab) sets the number of spaces inserted at beginning of paragraphs

- a second element (subsequent tab) sets the number of spaces inserted at the beginning of all broken lines apart
from the beginning of paragraphs

Allowed values: 0 or greater. Elements beyond the second are ignored.

(default: undefined)

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

C<new|choose> dies if passed invalid arguments.

=head2 carp

If pressing a key results in an undefined value C<choose> warns with C<EOT: $!> and returns I<undef> or an empty list in
list context.

=head1 REQUIREMENTS

=head2 Perl version

Requires Perl version 5.8.3 or greater.

=head2 Optional modules

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

By default ambiguous width characters are treated as half width. If the environment variable C<TC_AMBIGUOUS_WIDE> is set
to a true value, ambiguous width characters are treated as full width.

=head2 Escape sequences

By default C<Term::Choose> uses C<tput> to get the appropriate escape sequences. Setting the environment variable
C<TC_ANSI_ESCAPES> to a true value allows one to use ANSI escape sequences directly without calling C<tput>.

    BEGIN {
        $ENV{TC_ANSI_ESCAPES} = 1;
    }
    use Term::Choose qw( choose );

The escape sequences to enable the I<mouse> mode are always hardcoded.

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

Copyright (C) 2012-2020 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
