package Term::Form;

use warnings;
use strict;
use 5.008003;

our $VERSION = '0.316';

use Carp       qw( croak carp );
use Encode     qw( encode );
use List::Util qw( any );

use Encode::Locale    qw();
use Unicode::GCString qw();

use Term::Choose::LineFold qw( line_fold );

use Term::Form::Constants qw( :rl );

my $Plugin_Package;

BEGIN {
    if ( $^O eq 'MSWin32' ) {
        require Term::Form::Win32;
        $Plugin_Package = 'Term::Form::Win32';
    }
    else {
        require Term::Form::Linux;
        $Plugin_Package = 'Term::Form::Linux';
    }
}

sub ReadLine { 'Term::Form' }
sub IN {}
sub OUT {}
sub MinLine {}
sub Attribs { {} }
sub Features { { no_features => 1 } }
sub addhistory {}
sub ornaments {}


sub new {
    my $class = shift;
    my ( $name ) = @_;
    my $self = bless {
        name => $name,
    }, $class;
    $self->__set_defaults();
    $self->{plugin} = $Plugin_Package->new();
    my $backup_self = { map{ $_ => $self->{$_} } keys %$self };
    $self->{backup_self} = $backup_self;
    return $self;
}


sub DESTROY {
    my ( $self ) = @_;
    $self->__reset_term();
}


sub __set_defaults {
    my ( $self ) = @_;
    #$self->{compat}          = undef;
    #$self->{reinit_encoding} = undef;
    #$self->{no_echo}         = undef;
    $self->{default}          = '';
    $self->{clear_screen}     = 0;
    #$self->{info}            = undef;
    #$self->{prompt}          = undef;
    #$self->{mark_curr}       = undef;             # experimental
    $self->{auto_up}          = 0;
    $self->{back}             = '   BACK';
    $self->{confirm}          = 'CONFIRM';
    $self->{read_only}        = [];
}


sub __validate_options {
    my ( $self, $opt, $valid ) = @_;
    if ( ! defined $opt ) {
        $opt = {};
        return;
    }
    my $sub =  ( caller( 1 ) )[3];
    $sub =~ s/^.+::([^:]+)\z/$1/;
    for my $key ( keys %$opt ) {
        if ( ! exists $valid->{$key} ) {
            croak $sub . ": '$key' is not a valid option name";
        }
        if ( ! defined $opt->{$key} ) {
            next;
        }
        if ( ref $opt->{$key} ) {
            if ( $valid->{$key} eq 'ARRAY' ) {
                next;
            }
            croak $sub . ": option '$key' : a reference is not a valid value.";
        }
        if (  $valid->{$key} eq '' ) {
            next;
        }
        if ( $opt->{$key} !~ m/^$valid->{$key}\z/x ) {
            croak $sub . ": option '$key' : '$opt->{$key}' is not a valid value.";
        }
    }
}


sub __init_term {
    my ( $self, $hide_cursor ) = @_;
    $self->{plugin}->__set_mode( $hide_cursor );
    if ( $self->{reinit_encoding} ) {
        Encode::Locale::reinit( $self->{reinit_encoding} );
    }
}


sub __reset_term {
    my ( $self, $hide_cursor ) = @_;
    if ( defined $self->{plugin} ) {
        $self->{plugin}->__reset_mode( $hide_cursor );
    }
    if ( defined $self->{backup_self} ) {
        my $backup_self = delete $self->{backup_self};
        for my $key ( keys %$self ) {
            if ( defined $backup_self->{$key} ) {
                $self->{$key} = $backup_self->{$key};
            }
            else {
                delete $self->{$key};
            }
        }
    }
}


sub config { # DEPRECATED
    my ( $self, $opt ) = @_;
    if ( defined $opt ) {
        if ( ref $opt ne 'HASH' ) {
            croak "config: the (optional) argument must be a HASH reference";
        }
        my $valid = {
            auto_up         => '[ 0 1 2 ]',
            back            => '',
            clear_screen    => '[ 0 1 ]',
            compat          => '[ 0 1 ]',
            confirm         => '',
            default         => '',
            info            => '',
            no_echo         => '[ 0 1 2 ]',
            mark_curr       => '[ 0 1 ]',   # experimental
            prompt          => '',
            reinit_encoding => '',
            read_only       => 'ARRAY',
            ro              => 'ARRAY', ##
        };
        $self->__validate_options( $opt, $valid );
        for my $option ( keys %$opt ) {
            $self->{$option} = $opt->{$option};
        }
    }
}


sub readline {
    my ( $self, $prompt, $opt ) = @_;
    if ( defined $prompt ) {
        croak "readline: a reference is not a valid prompt." if ref $prompt;
    }
    else {
        $prompt = '';
    }
    if ( defined $opt ) {
        if ( ! ref $opt ) {
            $opt = { default => $opt };
        }
        elsif ( ref $opt ne 'HASH' ) {
            croak "readline: the (optional) second argument must be a string or a HASH reference";
        }
    }
    my $valid = {
        clear_screen => '[ 0 1 ]',
        default      => '',
        info         => '',
        no_echo      => '[ 0 1 2 ]',
    };
    $self->__validate_options( $opt, $valid );
    $opt->{default}      = $self->{default}      if ! defined $opt->{default};
    $opt->{no_echo}      = $self->{no_echo}      if ! defined $opt->{no_echo};
    $opt->{clear_screen} = $self->{clear_screen} if ! defined $opt->{clear_screen};
    $opt->{info}         = $self->{info}         if ! defined $opt->{info};
    $self->{i}{pre_text}        = $opt->{info};
    $self->{i}{sep}             = '';
    $self->{i}{curr_row}        = 0;
    $self->{i}{length_key}[0]   = Unicode::GCString->new( $prompt )->columns;
    $self->{i}{len_longest_key} = $self->{i}{length_key}[0];
    my $list = [ [ $prompt, $self->{default} ] ];
    my $str = Unicode::GCString->new( $opt->{default} );
    my $pos = $str->length();
    local $| = 1;
    $self->__init_term();
    $self->{plugin}->__clear_screen() if $opt->{clear_screen};
    $self->{i}{pre_text_row_count} = 0;

    while ( 1 ) {
        if ( $self->{i}{beep} ) {
            $self->{plugin}->__beep();
            $self->{i}{beep} = 0;
        }
        my ( $term_w, $term_h ) = $self->{plugin}->__term_buff_size();
        $self->{i}{avail_width} = $term_w - 1;
        if ( $self->{i}{len_longest_key} > $self->{i}{avail_width} / 3 ) {
            $self->{i}{len_longest_key} = int( $self->{i}{avail_width} / 3 );
        }
        $self->{i}{length_prompt} = $self->{i}{len_longest_key} + length $self->{i}{sep};
        $self->{i}{avail_width_value} = $self->{i}{avail_width} - $self->{i}{length_prompt};
        if ( defined $self->{i}{pre_text} ) { # empty info add newline
            $self->{plugin}->__up( $self->{i}{pre_text_row_count} );
            $self->{plugin}->__clear_lines_to_end_of_screen();
            $self->__pre_text_row_count();
            print "\r", $self->{i}{pre_text}, "\n";
        }
        $self->__print_readline( $opt, $list, $str, $pos );
        my $key = $self->{plugin}->__get_key();
        if ( ! defined $key ) {
            $self->__reset_term();
            carp "EOT: $!";
            return;
        }
        next if $key == NEXT_get_key;
        next if $key == KEY_TAB;
        if ( $key == KEY_BSPACE || $key == CONTROL_H ) {
            if ( $pos ) {
                $pos--;
                $str->substr( $pos, 1, '' );
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == CONTROL_U ) {
            if ( $pos ) {
                $str->substr( 0, $pos, '' );
                $pos = 0;
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == CONTROL_K ) {
            if ( $pos < $str->length() ) {
                $str->substr( $pos, $str->length() - $pos, '' );
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == VK_DELETE || $key == CONTROL_D ) {
            if ( $str->length() ) {
                if ( $pos < $str->length() ) {
                    $str->substr( $pos, 1, '' );
                }
                else {
                    $self->{i}{beep} = 1;
                }
            }
            else {
                print "\n";
                $self->__reset_term();
                return;
            }
        }
        elsif ( $key == VK_RIGHT || $key == CONTROL_F ) {
            if ( $pos < $str->length() ) {
                $pos++;
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == VK_LEFT  || $key == CONTROL_B ) {
            if ( $pos ) {
                $pos--;
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == VK_END   || $key == CONTROL_E ) {
            if ( $pos < $str->length() ) {
                $pos = $str->length();
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == VK_HOME  || $key == CONTROL_A ) {
            if ( $pos > 0 ) {
                $pos = 0;
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == VK_UP || $key == VK_DOWN ) {
            $self->{i}{beep} = 1;
        }
        else {
            $key = chr $key;
            utf8::upgrade $key;
            if ( $key eq "\n" || $key eq "\r" ) { #
                print "\n";
                $self->{plugin}->__up( $self->{i}{pre_text_row_count} + 1 );
                $self->{plugin}->__clear_lines_to_end_of_screen();
                $self->__reset_term();
                if ( $self->{compat} || ! defined $self->{compat} && $ENV{READLINE_SIMPLE_COMPAT} ) {
                    return encode( 'console_in', $str->as_string );
                }
                return $str->as_string;
            }
            else {
                $str->substr( $pos, 0, $key );
                $pos++;
            }
        }
    }
}


sub __print_readline {
    my ( $self, $opt, $list, $str, $pos ) = @_;
    my $print_str = $str->copy;
    my $print_pos = $pos;
    my $n = 1;
    my ( $b, $e );
    while ( $print_str->columns > $self->{i}{avail_width_value} ) {
        if ( $print_str->substr( 0, $print_pos )->columns > $self->{i}{avail_width_value} / 4 ) {
            $print_str->substr( 0, $n, '' );
            $print_pos -= $n;
            $b = 1;
        }
        else {
            $print_str->substr( -$n, $n, '' );
            $e = 1;
        }
    }
    if ( $b ) {
        $print_str->substr( 0, 1, '<' );
    }
    if ( $e ) {
        $print_str->substr( $print_str->length(), 1, '>' );
    }
    my $key = $self->__padded_or_trimed_key( $list, $self->{i}{curr_row} );
    $self->{plugin}->__clear_line();
    if ( $opt->{mark_curr} ) {
        $self->{plugin}->__mark_current();
        print "\r", $key;
        $self->{plugin}->__reset();
    }
    else {
        print "\r", $key;
    }
    my $sep = $self->{i}{sep};
    if ( defined $self->{i}{pre} && any { $_ == $self->{i}{curr_row} - @{$self->{i}{pre}} } @{$opt->{read_only}} ) { #
        $sep = $self->{i}{sep_ro};
    }
    if ( $opt->{no_echo} ) {
        if ( $opt->{no_echo} == 2 ) {
            print $sep;
            return;
        }
        print $sep, '*' x $print_str->length(), "\r";
    }
    else {
        print $sep, $print_str->as_string, "\r";
    }
    $self->{plugin}->__right( $self->{i}{length_prompt} + $print_str->substr( 0, $print_pos )->columns );

}


sub __length_longest_key {
    my ( $self, $list ) = @_;
    my $len = []; #
    my $longest = 0;
    for my $i ( 0 .. $#$list ) {
        my $gcs = Unicode::GCString->new( $list->[$i][0] );
        $len->[$i] = $gcs->columns;
        if ( $i < @{$self->{i}{pre}} ) {
            next;
        }
        $longest = $len->[$i] if $len->[$i] > $longest;
    }
    $self->{i}{len_longest_key} = $longest;
    $self->{i}{length_key} = $len;
}


sub __pre_text_row_count {
    my ( $self ) = @_;
    $self->{i}{pre_text_row_count} = 0;
    if ( ! defined $self->{i}{pre_text} ) {  # empty info add newline
        return;
    }
    $self->{i}{pre_text} = line_fold( $self->{i}{pre_text}, $self->{i}{avail_width}, 0, 0 );
    $self->{i}{pre_text_row_count} = $self->{i}{pre_text} =~ s/\n/\n/g;
    $self->{i}{pre_text_row_count} += 1;
}


sub __prepare_size {
    my ( $self, $opt, $list, $maxcols, $maxrows ) = @_;
    $self->{i}{avail_width} = $maxcols - 1;
    $self->{i}{avail_height} = $maxrows;
    if ( defined $self->{i}{pre_text} ) {
        $self->__pre_text_row_count();
        my $backup_height = $self->{i}{avail_height};
        $self->{i}{avail_height} -= $self->{i}{pre_text_row_count};
        my $min_avail_height = 5;
        if ( $self->{i}{avail_height} < $min_avail_height ) {
            if ( $backup_height > $min_avail_height ) {
                $self->{i}{avail_height} = $min_avail_height;
            }
            else {
                $self->{i}{avail_height} = $backup_height;
            }
        }
    }
    else {
        $self->{i}{pre_text_row_count} = 0;
    }
    if ( @$list > $self->{i}{avail_height} ) {
        $self->{i}{pages} = int @$list / ( $self->{i}{avail_height} - 1 );
        if ( @$list % ( $self->{i}{avail_height} - 1 ) ) {
            $self->{i}{pages}++;
        }
        $self->{i}{avail_height}--;
    }
    else {
        $self->{i}{pages} = 1;
    }
    return;
}


sub __gcstring_and_pos {
    my ( $self, $list ) = @_;
    my $default = $list->[$self->{i}{curr_row}][1];
    if ( ! defined $default ) {
        $default = '';
    }
    my $str = Unicode::GCString->new( $default );
    return $str, $str->length();
}


sub __print_current_row {
    my ( $self, $opt, $list, $str, $pos ) = @_;
    $self->{plugin}->__clear_line();
    if ( $self->{i}{curr_row} < @{$self->{i}{pre}} ) {
        $self->{plugin}->__reverse();
        print $list->[$self->{i}{curr_row}][0];
        $self->{plugin}->__reset();
    }
    else {
        $self->__print_readline( $opt, $list, $str, $pos );
        $list->[$self->{i}{curr_row}][1] = $str->as_string;
    }
}


sub __print_row {
    my ( $self, $opt, $list, $idx ) = @_;
    if ( $idx < @{$self->{i}{pre}} ) {
        return $list->[$idx][0];
    }
    else {
        my $val = defined $list->[$idx][1] ? $list->[$idx][1] : '';
        $val =~ s/\p{Space}/ /g;
        $val =~ s/\p{C}//g;
        my $sep = $self->{i}{sep};
        if ( any { $_ == $idx - @{$self->{i}{pre}} } @{$opt->{read_only}} ) {
            $sep = $self->{i}{sep_ro};
        }
        return
            $self->__padded_or_trimed_key( $list, $idx ) . $sep .
            $self->__unicode_trim( Unicode::GCString->new( $val ), $self->{i}{avail_width_value} );
    }
}


sub __write_screen {
    my ( $self, $opt, $list ) = @_;
    print join "\n", map { $self->__print_row( $opt, $list, $_ ) } $self->{i}{begin_row} .. $self->{i}{end_row};
    if ( $self->{i}{pages} > 1 ) {
        if ( $self->{i}{avail_height} - ( $self->{i}{end_row} + 1 - $self->{i}{begin_row} ) ) {
            print "\n" x ( $self->{i}{avail_height} - ( $self->{i}{end_row} - $self->{i}{begin_row} ) - 1 );
        }
        $self->{i}{page} = int( $self->{i}{end_row} / $self->{i}{avail_height} ) + 1;
        my $page_number = sprintf '- Page %d/%d -', $self->{i}{page}, $self->{i}{pages};
        if ( length $page_number > $self->{i}{avail_width} ) {
            $page_number = substr sprintf( '%d/%d', $self->{i}{page}, $self->{i}{pages} ), 0, $self->{i}{avail_width};
        }
        print "\n", $page_number;
        $self->{plugin}->__up( $self->{i}{avail_height} - ( $self->{i}{curr_row} - $self->{i}{begin_row} ) );
    }
    else {
        $self->{i}{page} = 1;
        my $up_curr = $self->{i}{end_row} - $self->{i}{curr_row};
        $self->{plugin}->__up( $up_curr );
    }
}


sub __write_first_screen {
    my ( $self, $opt, $list, $curr_row, $auto_up ) = @_;
    if ( $self->{i}{len_longest_key} > $self->{i}{avail_width} / 3 ) {
        $self->{i}{len_longest_key} = int( $self->{i}{avail_width} / 3 );
    }
    my $len_separator = Unicode::GCString->new( $self->{i}{sep} )->columns;
    if ( @{$opt->{read_only}} ) {
        my $tmp = Unicode::GCString->new( $self->{i}{sep_ro} )->columns;
        $len_separator = $tmp if $tmp > $len_separator;
    }
    $self->{i}{length_prompt} = $self->{i}{len_longest_key} + $len_separator;
    $self->{i}{avail_width_value} = $self->{i}{avail_width} - $self->{i}{length_prompt};
    $self->{i}{curr_row} = $auto_up == 2 ? $curr_row : @{$self->{i}{pre}};
    $self->{i}{begin_row} = 0;
    $self->{i}{end_row}  = ( $self->{i}{avail_height} - 1 );
    if ( $self->{i}{end_row} > $#$list ) {
        $self->{i}{end_row} = $#$list;
    }
    $self->{plugin}->__clear_screen() if $opt->{clear_screen};
    if ( defined $self->{i}{pre_text} ) {  # empty info add newline
        print $self->{i}{pre_text}, "\n";
    }
    $self->__write_screen( $opt, $list );
}


sub fill_form {
    my ( $self, $orig_list, $opt ) = @_;
    if ( ! defined $orig_list ) {
        croak "'fill_form' called with no argument.";
    }
    elsif ( ref $orig_list ne 'ARRAY' ) {
        croak "'fill_form' requires an ARRAY reference as its argument.";
    }
    if ( defined $opt && ref $opt ne 'HASH' ) {
        croak "'fill_form': the (optional) second argument must be a HASH reference";
    }
    return [] if ! @$orig_list; ##
    my $valid = {
        auto_up      => '[ 0 1 2 ]',
        back         => '',
        clear_screen => '[ 0 1 ]',
        confirm      => '',
        info         => '',
        mark_curr    => '[ 0 1 ]',
        prompt       => '',
        ro           => 'ARRAY', ##
        read_only    => 'ARRAY',
    };
    $self->__validate_options( $opt, $valid );
    $opt->{prompt}       = $self->{prompt}       if ! defined $opt->{prompt};
    $opt->{info}         = $self->{info}         if ! defined $opt->{info};
    $opt->{back}         = $self->{back}         if ! defined $opt->{back};
    $opt->{confirm}      = $self->{confirm}      if ! defined $opt->{confirm};
    $opt->{auto_up}      = $self->{auto_up}      if ! defined $opt->{auto_up};
    $opt->{read_only}    = $opt->{ro}            if ! defined $opt->{read_only};
    $opt->{read_only}    = $self->{read_only}    if ! defined $opt->{read_only};
    $opt->{clear_screen} = $self->{clear_screen} if ! defined $opt->{clear_screen};
    $self->{i}{pre_text}  = $opt->{info};
    if ( defined $opt->{prompt} ) {
        $self->{i}{pre_text} .= "\n" if defined $self->{i}{pre_text};
        $self->{i}{pre_text} .= $opt->{prompt};
    }
    $self->{i}{sep}         = ': ';
    $self->{i}{sep_ro}      = '| ';
    $self->{i}{pre}    = [ [$opt->{confirm}, ] ];
    if ( length $opt->{back} ) {
        unshift @{$self->{i}{pre}}, [ $opt->{back}, ];
    }
    my $list = [ @{$self->{i}{pre}}, map { [ @$_ ] } @$orig_list ];
    $self->__length_longest_key( $list );
    my $auto_up = $opt->{auto_up};
    $self->__init_term();
    local $| = 1;
    my ( $maxcols, $maxrows ) = $self->{plugin}->__term_buff_size();
    $self->__prepare_size( $opt, $list, $maxcols, $maxrows );
    $self->__write_first_screen( $opt, $list, 0, $auto_up );
    my ( $str, $pos ) = $self->__gcstring_and_pos( $list );
    my $k = 0;

    KEY: while ( 1 ) {
        my $locked = 0;
        if ( any { $_ == $self->{i}{curr_row} - @{$self->{i}{pre}} } @{$opt->{read_only}} ) {
            $locked = 1;
        }
        if ( $self->{i}{beep} ) {
            $self->{plugin}->__beep();
            $self->{i}{beep} = 0;
        }
        else {
            $self->__print_current_row( $opt, $list, $str, $pos );
        }
        my $key = $self->{plugin}->__get_key();
        if ( ! defined $key ) {
            $self->__reset_term();
            carp "EOT: $!";
            return;
        }
        next KEY if $key == NEXT_get_key;
        next KEY if $key == KEY_TAB;
        my ( $tmp_maxcols, $tmp_maxrows ) = $self->{plugin}->__term_buff_size();
        if ( $tmp_maxcols != $maxcols || $tmp_maxrows != $maxrows && $tmp_maxrows < ( @$list + 1 ) ) {
            ( $maxcols, $maxrows ) = ( $tmp_maxcols, $tmp_maxrows );
            $self->__prepare_size( $opt, $list, $maxcols, $maxrows );
            $self->{plugin}->__clear_screen();
            $self->__write_first_screen( $opt, $list, 1, $auto_up ); # 1
            ( $str, $pos ) = $self->__gcstring_and_pos( $list );
        }
        if ( $key == KEY_BSPACE || $key == CONTROL_H ) {
            $k = 1;
            if ( $locked ) {    # read_only
                $self->{i}{beep} = 1;
            }
            elsif ( $pos ) {
                $pos--;
                $str->substr( $pos, 1, '' );
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == CONTROL_U ) {
            $k = 1;
            if ( $locked ) {
                $self->{i}{beep} = 1;
            }
            elsif ( $pos ) {
                $str->substr( 0, $pos, '' );
                $pos = 0;
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == CONTROL_K ) {
            $k = 1;
            if ( $locked ) {
                $self->{i}{beep} = 1;
            }
            elsif ( $pos < $str->length() ) {
                $str->substr( $pos, $str->length() - $pos, '' );
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == VK_DELETE || $key == CONTROL_D ) {
            $k = 1;
            if ( $str->length() ) {
                if ( $locked ) {
                    $self->{i}{beep} = 1;
                }
                elsif ( $pos < $str->length() ) {
                    $str->substr( $pos, 1, '' );
                }
                else {
                    $self->{i}{beep} = 1;
                }
            }
            else {
                print "\n";
                $self->__reset_term();
                return;
            }
        }
        elsif ( $key == VK_RIGHT ) {
            $k = 1;
            if ( $pos < $str->length() ) {
                $pos++;
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == VK_LEFT ) {
            $k = 1;
            if ( $pos ) {
                $pos--;
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == VK_END   || $key == CONTROL_E ) {
            $k = 1;
            if ( $pos < $str->length() ) {
                $pos = $str->length();
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == VK_HOME  || $key == CONTROL_A ) {
            $k = 1;
            if ( $pos > 0 ) {
                $pos = 0;
            }
            else {
                $self->{i}{beep} = 1;
            }
        }
        elsif ( $key == VK_UP ) {
            $k = 1;
            if ( $self->{i}{curr_row} == 0 ) {
                $self->{i}{beep} = 1;
            }
            else {
                $self->{i}{curr_row}--;
                ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                if ( $self->{i}{curr_row} >= $self->{i}{begin_row} ) {
                    $self->__reset_previous_row( $opt, $list, $self->{i}{curr_row} + 1 );
                    $self->{plugin}->__up( 1 );
                }
                else {
                    $self->__print_previous_page( $opt, $list );
                }
            }
        }
        elsif ( $key == VK_DOWN ) {
            $k = 1;
            if ( $self->{i}{curr_row} == $#$list ) {
                $self->{i}{beep} = 1;
            }
            else {
                $self->{i}{curr_row}++;
                ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                if ( $self->{i}{curr_row} <= $self->{i}{end_row} ) {
                    $self->__reset_previous_row( $opt, $list, $self->{i}{curr_row} - 1 );
                    $self->{plugin}->__down( 1 );
                }
                else {
                    $self->{plugin}->__up( $self->{i}{end_row} - $self->{i}{begin_row} );
                    $self->__print_next_page( $opt, $list );
                }
            }
        }
        elsif (  $key == VK_PAGE_UP || $key == CONTROL_B ) {
            $k = 1;
            if ( $self->{i}{page} == 1 ) {
                if ( $self->{i}{curr_row} == 0 ) {
                    $self->{i}{beep} = 1;
                }
                else {
                    $self->__reset_previous_row( $opt, $list, $self->{i}{curr_row} );
                    $self->{plugin}->__up( $self->{i}{curr_row} );
                    $self->{i}{curr_row} = 0;
                    ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                }
            }
            else {
                $self->{plugin}->__up( $self->{i}{curr_row} - $self->{i}{begin_row} );
                $self->{i}{curr_row} = $self->{i}{begin_row} - $self->{i}{avail_height};
                ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                $self->__print_previous_page( $opt, $list );
            }
        }
        elsif (  $key == VK_PAGE_DOWN || $key == CONTROL_F ) {
            $k = 1;
            if ( $self->{i}{page} == $self->{i}{pages} ) {
                if ( $self->{i}{curr_row} == $#$list ) {
                    $self->{i}{beep} = 1;
                }
                else {
                    $self->__reset_previous_row( $opt, $list, $self->{i}{curr_row} );
                    $self->{plugin}->__down( $self->{i}{end_row} - $self->{i}{curr_row} );
                    $self->{i}{curr_row} = $self->{i}{end_row};
                    ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                }
            }
            else {
                $self->{plugin}->__up( $self->{i}{curr_row} - $self->{i}{begin_row} );
                $self->{i}{curr_row} = $self->{i}{end_row} + 1;
                ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                $self->__print_next_page( $opt, $list );
            }
        }
        else {
            $key = chr $key;
            utf8::upgrade $key;
            if ( $key eq "\n" || $key eq "\r" ) {                                                                       # ENTER
                $self->{i}{lock_ENTER} = 0 if $k;                                                                       # any previously pressed key other than ENTER removes lock_ENTER
                if ( $auto_up == 2 && $opt->{auto_up} == 1 && ! $self->{i}{lock_ENTER} ) {                              # a removed lock_ENTER resets "auto_up" from 2 to 1 if the 2 was originally a 1
                    $auto_up = 1;
                }
                if ( $auto_up == 1 && @$list - @{$self->{i}{pre}} == 1 ) {                                              # else auto_up 1 sticks on the last==first data row
                    $auto_up = 2;
                }
                $k = 0;                                                                                                 # if ENTER set $k to 0
                my $up = $self->{i}{curr_row} - $self->{i}{begin_row};
                $up += $self->{i}{pre_text_row_count} if $self->{i}{pre_text_row_count};
                if ( $list->[$self->{i}{curr_row}][0] eq $opt->{back} ) {                                               # if ENTER on   {back/0}: leave and return nothing
                    $self->{plugin}->__up( $up );
                    $self->{plugin}->__clear_lines_to_end_of_screen();
                    $self->__reset_term();
                    return;
                }
                elsif ( $list->[$self->{i}{curr_row}][0] eq $opt->{confirm} ) {                                         # if ENTER on {confirm/1}: leave and return result
                    $self->{plugin}->__up( $up );
                    $self->{plugin}->__clear_lines_to_end_of_screen();
                    splice @$list, 0, @{$self->{i}{pre}};
                    $self->__reset_term();
                    if ( $self->{compat} || ! defined $self->{compat} && $ENV{READLINE_SIMPLE_COMPAT} ) {
                        return [ map { [ $_->[0], encode( 'console_in', $_->[1] ) ] } @$list ];
                    }
                    return $list;
                }
                if ( $auto_up == 2 ) {                                                                                  # if ENTER && "auto_up" == 2 && any row: jumps {back/0}
                    $self->{plugin}->__up( $up );
                    $self->{plugin}->__clear_lines_to_end_of_screen();
                    my $cursor = 0; # cursor on {back}
                    $self->__write_first_screen( $opt, $list, $cursor, $auto_up );
                    ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                }
                elsif ( $self->{i}{curr_row} == $#$list ) {                                                             # if ENTER && {last row}: jumps to the {first data row/2}
                    $self->{plugin}->__up( $up );
                    $self->{plugin}->__clear_lines_to_end_of_screen();
                    my $cursor = scalar @{$self->{i}{pre}};                                                             # cursor on the first data row
                    $self->__write_first_screen( $opt, $list, $cursor, $auto_up );
                    ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                    $self->{i}{lock_ENTER} = 1;                                                                         # set lock_ENTER when jumped automatically from the {last row} to the {first data row/2}
                }
                else {
                    if ( $auto_up == 1 && $self->{i}{curr_row} == @{$self->{i}{pre}} && $self->{i}{lock_ENTER} ) {      # if ENTER && "auto_up" == 1 $$ "curr_row" == {first data row/2} && lock_ENTER is true:
                        $self->{i}{beep} = 1;                                                                           # set "auto_up" temporary to 2 so a second ENTER moves the cursor to {back/0}
                        $auto_up = 2;
                        next KEY;
                    }
                     $self->{i}{curr_row}++;
                    ( $str, $pos ) = $self->__gcstring_and_pos( $list );                                                # or go to the next row if not on the last row
                    if ( $self->{i}{curr_row} <= $self->{i}{end_row} ) {
                        $self->__reset_previous_row( $opt, $list, $self->{i}{curr_row} - 1 );
                        $self->{plugin}->__down( 1 );
                    }
                    else {
                        $self->{plugin}->__up( $up );                                                                   # or else to the next page
                        $self->__print_next_page( $opt, $list );
                    }
                }
            }
            else {
                $k = 1;
                if ( $locked ) {
                    $self->{i}{beep} = 1;
                }
                else {
                    $str->substr( $pos, 0, $key );
                    $pos++;
                }
            }
        }
    }
}


sub __reset_previous_row {
    my ( $self, $opt, $list, $idx ) = @_;
    $self->{plugin}->__clear_line();
    print $self->__print_row( $opt, $list, $idx );
}


sub __print_next_page {
    my ( $self, $opt, $list ) = @_;
    $self->{i}{begin_row} = $self->{i}{end_row} + 1;
    $self->{i}{end_row}   = $self->{i}{end_row} + $self->{i}{avail_height};
    $self->{i}{end_row}   = $#$list if $self->{i}{end_row} > $#$list;
    $self->{plugin}->__clear_lines_to_end_of_screen();
    $self->__write_screen( $opt, $list );
}


sub __print_previous_page {
    my ( $self, $opt, $list ) = @_;
    $self->{i}{end_row}   = $self->{i}{begin_row} - 1;
    $self->{i}{begin_row} = $self->{i}{begin_row} - $self->{i}{avail_height};
    $self->{i}{begin_row} = 0 if $self->{i}{begin_row} < 0;
    $self->{plugin}->__clear_lines_to_end_of_screen();
    $self->__write_screen( $opt, $list );
}


sub __padded_or_trimed_key {
    my ( $self, $list, $idx ) = @_;
    my $unicode;
    my $key_length = $self->{i}{length_key}[$idx];
    my $key = $list->[$idx][0];
    $key =~ s/\p{Space}/ /g;
    $key =~ s/\p{C}//g;
    if ( $key_length > $self->{i}{len_longest_key} ) {
        my $gcs = Unicode::GCString->new( $key );
        $unicode = $self->__unicode_trim( $gcs, $self->{i}{len_longest_key} );
    }
    elsif ( $key_length < $self->{i}{len_longest_key} ) {
        $unicode = " " x ( $self->{i}{len_longest_key} - $key_length ) . $key;
    }
    else {
        $unicode = $key;
    }
    return $unicode;
}


sub __unicode_trim {
    my ( $self, $gcs, $len ) = @_;
    if ( $gcs->columns <= $len ) {
        return $gcs->as_string;
    }
    my $pos = $gcs->pos;
    $gcs->pos( 0 );
    my $cols = 0;
    my $gc;
    my $dots = '...'; #
    $dots .= ' ' if $gcs->as_string =~ /\ \z/;
    while ( defined( $gc = $gcs->next ) ) {
        if ( ( $len - length( $dots ) ) < ( $cols += $gc->columns ) ) {
            my $ret = $gcs->substr( 0, $gcs->pos - 1 );
            $gcs->pos( $pos );
            return $ret->as_string . $dots;
        }
    }
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Form - Read lines from STDIN.

=head1 VERSION

Version 0.316

=cut

=head1 SYNOPSIS

    use Term::Form;

    my $new = Term::Form->new( 'name' );
    my $line = $new->readline( 'Prompt: ', { default => 'abc' } );


    my $aoa = [
        [ 'name'           ],
        [ 'year'           ],
        [ 'color', 'green' ],
        [ 'city'           ]
    ];
    my $modified_list = $new->fill_form( $aoa );

=head1 DESCRIPTION

C<readline> reads a line from STDIN. As soon as C<Return> is pressed C<readline> returns the read string without the
newline character - so no C<chomp> is required.

C<fill_form> reads a list of lines from STDIN.

This module is intended to cope with Unicode (multibyte character/grapheme cluster).

The output is removed after leaving the method, so the user can decide what remains on the screen.

=head2 Keys

C<BackSpace> or C<Strg-H>: Delete the character behind the cursor.

C<Delete> or C<Strg-D>: Delete  the  character at point. Return nothing if the input puffer is empty.

C<Strg-U>: Delete the text backward from the cursor to the beginning of the line.

C<Strg-K>: Delete the text from the cursor to the end of the line.

C<Right-Arrow>: Move forward a character.

C<Left-Arrow>: Move back a character.

C<Home> or C<Strg-A>: Move to the start of the line.

C<End> or C<Strg-E>: Move to the end of the line.

Only in C<fill_form>:

C<Up-Arrow>: Move up one row.

C<Down-Arrow>: Move down one row.

C<Page-Up> or C<Strg-B>: Move back one page.

C<Page-Down> or C<Strg-F>: Move forward one page.

=head1 METHODS

=head2 new

The C<new> method returns a C<Term::Form> object.

    my $new = Term::Form->new();

=head2 config DEPRECATED

This method is deprecated and will be removed.

The method C<config> overwrites the defaults for the current C<Term::Form> object.

    $new->config( \%options );

The available options are: the options from C<readline> and C<fill_form> and

=over

=item

compat

If I<compat> is set to C<1>, the return value of C<readline> is not decoded else the return value of C<readline>
is decoded. With C<fill_form> the second elements (values) of the arrays are returned encoded if I<compat> is set to
C<1>, else they are returned decoded.

Setting the environment variable READLINE_SIMPLE_COMPAT to a true value has the same effect as setting I<compat> to C<1>
unless I<compat> is defined. If I<compat> is defined, READLINE_SIMPLE_COMPAT has no meaning.

Allowed values: C<0> or C<1>.

default: no set

=item

reinit_encoding

To get the right encoding C<Term::Form> uses L<Encode::Locale>. Passing an encoding to I<reinit_encoding>
changes the encoding reported by C<Encode::Locale>. See L<Encode::Locale/reinit-encoding> for more details.

Allowed values: an encoding which is recognized by the L<Encode> module.

default: not set

=back

=head2 readline

C<readline> reads a line from STDIN.

    $line = $new->readline( $prompt, [ \%options ] );

The fist argument is the prompt string.

The optional second argument is the default string (see option I<default>) if it is not a reference. If the second
argument is a hash-reference, the hash is used to set the different options. The keys/options are

=over

=item

clear_screen

If enabled, the screen is cleared before the output.

default: disabled

=item

info

Expects as is value a string. If set, the string is printed on top of the output of C<readline>.

=item

default

Set a initial value of input.

=item

no_echo

- if set to C<0>, the input is echoed on the screen.

- if set to C<1>, "C<*>" are displayed instead of the characters.

- if set to C<2>, no output is shown apart from the prompt string.

default: C<0>

=back

=head2 fill_form

C<fill_form> reads a list of lines from STDIN.

    $new_list = $new->fill_form( $aoa, { prompt => 'Required:' } );

The first argument is a reference to an array of arrays. The arrays have 1 or 2 elements: the first element is the key
and the optional second element is the value. The key is used as the prompt string for the "readline", the value is used
as the default value for the "readline" (initial value of input).

The optional second argument is a hash-reference. The keys/options are

=over

=item

clear_screen

If enabled, the screen is cleared before the output.

default: disabled

=item

info

Expects as is value a string. If set, the string is printed on top of the output of C<fill_form>.

=item

prompt

If I<prompt> is set, a main prompt string is shown on top of the output.

default: undefined

=item

auto_up

With I<auto_up> set to C<0> or C<1> pressing C<ENTER> moves the cursor to the next line (if the cursor is not on the
"back" or "confirm" row). If the last row is reached, the cursor jumps to the first data row if C<ENTER> is pressed.
While with  I<auto_up> set to C<0> the cursor loops through the rows until a key other than C<ENTER> is pressed with
I<auto_up> set to C<1> after one loop an C<ENTER> moves the cursor to the top menu entry ("back") if no other
key than C<ENTER> was pressed.

With I<auto_up> set to C<2> an C<ENTER> moves the cursor to the top menu entry (except the cursor is on the "confirm"
row).

If I<auto_up> is set to C<0> or C<1> the initially cursor position is on the first data row while when set to C<2> the
initially cursor position is on the first menu entry ("back").

default: C<1>

=item

clear_screen

If enabled, the screen is cleared before the output.

default: disabled

=item

read_only

Set a form-row to read only.

Expected value: a reference to an array with the indexes of the rows which should be read only.

default: empty array

=item

confirm

Set the name of the "confirm" menu entry.

default: C<Confirm>

=item

back

Set the name of the "back" menu entry.

The "back" menu entry can be disabled by setting I<back> to an empty string.

default: C<Back>

=back

To close the form and get the modified list (reference to an array or arrays) as the return value select the
"confirm" menu entry. If the "back" menu entry is chosen to close the form, C<fill_form> returns nothing.

=head1 REQUIREMENTS

=head2 Perl version

Requires Perl version 5.8.3 or greater.

=head2 Terminal

It is required a terminal which uses a monospaced font.

Unless the OS is MSWin32 the terminal has to understand ANSI escape sequences.

=head2 Encoding layer

It is required to use appropriate I/O encoding layers. If the encoding layer for STDIN doesn't match the terminal's
character set, C<readline> will break if a non ascii character is entered.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::Form

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 CREDITS

Thanks to the L<Perl-Community.de|http://www.perl-community.de> and the people form
L<stackoverflow|http://stackoverflow.com> for the help.

=head1 LICENSE AND COPYRIGHT

Copyright 2014-2018 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
