package Term::Form;

use warnings;
use strict;
use 5.008003;

our $VERSION = '0.310';

use Carp       qw( croak carp );
use Encode     qw( encode );
use List::Util qw( any );

use Encode::Locale    qw();
use Text::LineFold    qw();
use Unicode::GCString qw();

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
    return $self;
}


sub DESTROY {
    my ( $self ) = @_;
    $self->__reset_term();
}


sub __set_defaults {
    my ( $self ) = @_;
    # compat         : undef ok
    # reinit_encoding: undef ok
    # no_echo        : false ok
    $self->{default} = '';

    # prompt   : undef ok
    # mark_curr: false ok
    # back     : undef ok
    $self->{auto_up} = 0;
    $self->{back}    = '';
    $self->{confirm} = '<<';
    $self->{ro}      = [];
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
    my ( $self ) = @_;
    $self->{plugin}->__set_mode();
    if ( $self->{reinit_encoding} ) {
        Encode::Locale::reinit( $self->{reinit_encoding} );
    }
}


sub __reset_term {
    my ( $self ) = @_;
    delete $self->{enter_row} if exists $self->{enter_row};
    delete $self->{enter_col} if exists $self->{enter_col};
    if ( defined $self->{plugin} ) {
        $self->{plugin}->__reset_mode();
    }
}


sub config {
    my ( $self, $opt ) = @_;
    if ( defined $opt ) {
        if ( ref $opt ne 'HASH' ) {
            croak "config: the (optional) argument must be a HASH reference";
        }
        my $valid = {
            no_echo         => '[ 0 1 2 ]',
            compat          => '[ 0 1 ]',
            reinit_encoding => '',
            default         => '',
            prompt          => '',
            back            => '',
            confirm         => '',
            auto_up         => '[ 0 1 2 ]',
            mark_curr       => '[ 0 1 ]',
            ro              => 'ARRAY',
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
        no_echo => '[ 0 1 2 ]',
        default => '',
    };
    $self->__validate_options( $opt, $valid );
    $opt->{default} = $self->{default} if ! defined $opt->{default};
    $opt->{no_echo} = $self->{no_echo} if ! defined $opt->{no_echo};
    $self->{sep} = '';
    my $list = [ [ $prompt, $self->{default} ] ];
    $self->{curr_row} = 0;
    $self->{length_key}[0]   = Unicode::GCString->new( $prompt )->columns;
    $self->{len_longest_key} = $self->{length_key}[0];
    $self->{length_prompt}   = $self->{len_longest_key} + length $self->{sep};
    my $str = Unicode::GCString->new( $opt->{default} );
    my $pos = $str->length();
    local $| = 1;
    $self->__init_term();

    while ( 1 ) {
        if ( $self->{beep} ) {
            $self->{plugin}->__beep();
            $self->{beep} = 0;
        }
        my ( $term_width ) = $self->{plugin}->__term_buff_size();
        $self->{avail_width} = $term_width - 1;
        $self->{avail_width_value} = $self->{avail_width} - $self->{length_prompt};
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
                $self->{beep} = 1;
            }
        }
        elsif ( $key == CONTROL_U ) {
            if ( $pos ) {
                $str->substr( 0, $pos, '' );
                $pos = 0;
            }
            else {
                $self->{beep} = 1;
            }
        }
        elsif ( $key == CONTROL_K ) {
            if ( $pos < $str->length() ) {
                $str->substr( $pos, $str->length() - $pos, '' );
            }
            else {
                $self->{beep} = 1;
            }
        }
        elsif ( $key == VK_DELETE || $key == CONTROL_D ) {
            if ( $str->length() ) {
                if ( $pos < $str->length() ) {
                    $str->substr( $pos, 1, '' );
                }
                else {
                    $self->{beep} = 1;
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
                $self->{beep} = 1;
            }
        }
        elsif ( $key == VK_LEFT  || $key == CONTROL_B ) {
            if ( $pos ) {
                $pos--;
            }
            else {
                $self->{beep} = 1;
            }
        }
        elsif ( $key == VK_END   || $key == CONTROL_E ) {
            if ( $pos < $str->length() ) {
                $pos = $str->length();
            }
            else {
                $self->{beep} = 1;
            }
        }
        elsif ( $key == VK_HOME  || $key == CONTROL_A ) {
            if ( $pos > 0 ) {
                $pos = 0;
            }
            else {
                $self->{beep} = 1;
            }
        }
        elsif ( $key == VK_UP || $key == VK_DOWN ) {
            $self->{beep} = 1;
        }
        else {
            $key = chr $key;
            utf8::upgrade $key;
            if ( $key eq "\n" || $key eq "\r" ) { #
                print "\n";
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
    while ( $print_str->columns > $self->{avail_width_value} ) {
        if ( $print_str->substr( 0, $print_pos )->columns > $self->{avail_width_value} / 4 ) {
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
    my $key = $self->__padded_or_trimed_key( $list, $self->{curr_row} );
    $self->{plugin}->__clear_line();
    if ( $opt->{mark_curr} ) {
        $self->{plugin}->__mark_current();
        print "\r", $key;
        $self->{plugin}->__reset();
    }
    else {
        print "\r", $key;
    }
    my $sep = $self->{sep};
    if ( any { $_ == $self->{curr_row} - @{$self->{pre_list}} } @{$opt->{ro}} ) {
        $sep = $self->{sep_ro};
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
    $self->{plugin}->__right( $self->{length_prompt} + $print_str->substr( 0, $print_pos )->columns );

}


sub __length_longest_key {
    my ( $self, $list ) = @_;
    my $len = []; #
    my $longest = 0;
    for my $i ( 0 .. $#$list ) {
        my $gcs = Unicode::GCString->new( $list->[$i][0] );
        $len->[$i] = $gcs->columns;
        if ( $i < @{$self->{pre_list}} ) {
            next;
        }
        $longest = $len->[$i] if $len->[$i] > $longest;
    }
    $self->{len_longest_key} = $longest;
    $self->{length_key} = $len;
}


sub __prepare_size {
    my ( $self, $opt, $list, $maxcols, $maxrows ) = @_;
    $self->{avail_width} = $maxcols - 1;
    $self->{avail_height} = $maxrows;
    if ( defined $opt->{main_prompt} ) {
        $self->__nr_prompt_lines( $opt );
        my $backup_height = $self->{avail_height};
        $self->{avail_height} -= $self->{nr_prompt_lines};
        my $min_avail_height = 5;
        if ( $self->{avail_height} < $min_avail_height ) {
            if ( $backup_height > $min_avail_height ) {
                $self->{avail_height} = $min_avail_height;
            }
            else {
                $self->{avail_height} = $backup_height;
            }
        }
    }
    if ( @$list > $self->{avail_height} ) {
        $self->{pages} = int @$list / ( $self->{avail_height} - 1 );
        if ( @$list % ( $self->{avail_height} - 1 ) ) {
            $self->{pages}++;
        }
        $self->{avail_height}--;
    }
    else {
        $self->{pages} = 1;
    }
    return;
}


sub __nr_prompt_lines {
    my ( $self, $opt ) = @_;
    my $prompt = $opt->{main_prompt};
    if ( $prompt eq '' ) {
        $self->{nr_prompt_lines} = 0;
        return;
    }
    #$self->{main_prompt} =~ s/[^\n\P{Space}]/ /g;
    #$self->{main_prompt} =~ s/[^\n\P{C}]//g;
    if ( $prompt !~ /\n/ &&  Unicode::GCString->new( $prompt )->columns <= $self->{avail_width} ) {
        $self->{nr_prompt_lines} = 1;
    }
    else {
        my $line_fold = Text::LineFold->new(
            Charset=> 'utf-8',
            ColMax => $self->{avail_width},
            OutputCharset => '_UNICODE_',
            Urgent => 'FORCE'
        );
        #if ( defined $self->{lf} ) {
        #    $self->{prompt_copy} = $line_fold->fold( ' ' x $self->{lf}[0], ' ' x $self->{lf}[1], $self->{main_prompt} );
        #}
        #else {
            $opt->{main_prompt} = $line_fold->fold( $prompt, 'PLAIN' );
        #}
        $opt->{main_prompt} =~ s/\n\z//;
        $self->{nr_prompt_lines} = $opt->{main_prompt} =~ s/\n/\n\r/g; # #
        $self->{nr_prompt_lines} += 1;
    }
}


sub __gcstring_and_pos {
    my ( $self, $list ) = @_;
    my $default = $list->[$self->{curr_row}][1];
    if ( ! defined $default ) {
        $default = '';
    }
    my $str = Unicode::GCString->new( $default );
    return $str, $str->length();
}


sub __print_current_row {
    my ( $self, $opt, $list, $str, $pos ) = @_;
    $self->{plugin}->__clear_line();
    if ( $self->{curr_row} < @{$self->{pre_list}} ) {
        $self->{plugin}->__reverse();
        print $list->[$self->{curr_row}][0];
        $self->{plugin}->__reset();
    }
    else {
        $self->__print_readline( $opt, $list, $str, $pos );
        $list->[$self->{curr_row}][1] = $str->as_string;
    }
}


sub __print_row {
    my ( $self, $opt, $list, $idx ) = @_;
    if ( $idx < @{$self->{pre_list}} ) {
        return $list->[$idx][0];
    }
    else {
        my $val = defined $list->[$idx][1] ? $list->[$idx][1] : '';
        $val =~ s/\p{Space}/ /g;
        $val =~ s/\p{C}//g;
        my $sep = $self->{sep};
        if ( any { $_ == $idx - @{$self->{pre_list}} } @{$opt->{ro}} ) {
            $sep = $self->{sep_ro};
        }
        return
            $self->__padded_or_trimed_key( $list, $idx ) . $sep .
            $self->__unicode_trim( Unicode::GCString->new( $val ), $self->{avail_width_value} );
    }
}


sub __write_screen {
    my ( $self, $opt, $list ) = @_;
    print join "\n", map { $self->__print_row( $opt, $list, $_ ) } $self->{begin_row} .. $self->{end_row};
    if ( $self->{pages} > 1 ) {
        if ( $self->{avail_height} - ( $self->{end_row} + 1 - $self->{begin_row} ) ) {
            print "\n" x ( $self->{avail_height} - ( $self->{end_row} - $self->{begin_row} ) - 1 );
        }
        $self->{page} = int( $self->{end_row} / $self->{avail_height} ) + 1;
        my $page_number = sprintf '- Page %d/%d -', $self->{page}, $self->{pages};
        if ( length $page_number > $self->{avail_width} ) {
            $page_number = substr sprintf( '%d/%d', $self->{page}, $self->{pages} ), 0, $self->{avail_width};
        }
        print "\n", $page_number;
        $self->{plugin}->__up( $self->{avail_height} - ( $self->{curr_row} - $self->{begin_row} ) );
    }
    else {
        $self->{page} = 1;
        my $up_curr = $self->{end_row} - $self->{curr_row};
        $self->{plugin}->__up( $up_curr );
    }
}


sub __write_first_screen {
    my ( $self, $opt, $list, $curr_row ) = @_;
    if ( $self->{len_longest_key} > $self->{avail_width} / 3 ) {
        $self->{len_longest_key} = int( $self->{avail_width} / 3 );
    }
    my $len_separator = Unicode::GCString->new( $self->{sep} )->columns;
    if ( @{$opt->{ro}} ) {
        my $tmp = Unicode::GCString->new( $self->{sep_ro} )->columns;
        $len_separator = $tmp if $tmp > $len_separator;
    }
    $self->{length_prompt} = $self->{len_longest_key} + $len_separator;
    $self->{avail_width_value} = $self->{avail_width} - $self->{length_prompt};
    $self->{curr_row} = $opt->{auto_up} == 2 ? $curr_row : @{$self->{pre_list}};
    $self->{begin_row} = 0;
    $self->{end_row}  = ( $self->{avail_height} - 1 );
    if ( $self->{end_row} > $#$list ) {
        $self->{end_row} = $#$list;
    }
    if ( defined $opt->{main_prompt} ) {
        print $opt->{main_prompt}, "\n";
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
    my $valid = {
        prompt    => '',
        back      => '',
        confirm   => '',
        auto_up   => '[ 0 1 2 ]',
        mark_curr => '[ 0 1 ]',
        ro        => 'ARRAY',
####
        sep             => '', # remove
####
    };
    my $list = [ map { [ @$_ ] } @$orig_list ];
    $self->__validate_options( $opt, $valid );
    $opt->{prompt}  = $self->{prompt}  if ! defined $opt->{prompt};
    $opt->{back}    = $self->{back}    if ! defined $opt->{back};
    $opt->{confirm} = $self->{confirm} if ! defined $opt->{confirm};
    $opt->{auto_up} = $self->{auto_up} if ! defined $opt->{auto_up};
    $opt->{ro}      = $self->{ro}      if ! defined $opt->{ro};
    $opt->{main_prompt} = $opt->{prompt};
    $self->{sep}    = ': ';
    $self->{sep_ro} = '| ';
    $self->{pre_list} = [ [ $opt->{confirm} ] ];
    if ( length $opt->{back} ) {
        unshift @{$self->{pre_list}}, [ $opt->{back} ];
    }
    unshift @$list, @{$self->{pre_list}};
    $self->__length_longest_key( $list );
    $self->__init_term();
    local $| = 1;
    my ( $maxcols, $maxrows ) = $self->{plugin}->__term_buff_size();
    $self->__prepare_size( $opt, $list, $maxcols, $maxrows );
    $self->__write_first_screen( $opt, $list, 0 );
    my ( $str, $pos ) = $self->__gcstring_and_pos( $list );

    LINE: while ( 1 ) {
        my $locked = 0;
        if ( any { $_ == $self->{curr_row} - @{$self->{pre_list}} } @{$opt->{ro}} ) {
            $locked = 1;
        }
        if ( $self->{beep} ) {
            $self->{plugin}->__beep();
            $self->{beep} = 0;
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
        next if $key == NEXT_get_key;
        next if $key == KEY_TAB;
        my ( $tmp_maxcols, $tmp_maxrows ) = $self->{plugin}->__term_buff_size();
        if ( $tmp_maxcols != $maxcols || $tmp_maxrows != $maxrows && $tmp_maxrows < ( @$list + 1 ) ) {
            ( $maxcols, $maxrows ) = ( $tmp_maxcols, $tmp_maxrows );
            $self->__prepare_size( $opt, $list, $maxcols, $maxrows );
            $self->{plugin}->__clear_screen();
            $self->__write_first_screen( $opt, $list, 1 );
            ( $str, $pos ) = $self->__gcstring_and_pos( $list );
        }
        if ( $key == KEY_BSPACE || $key == CONTROL_H ) {
            if ( $locked ) {
                $self->{beep} = 1;
            }
            elsif ( $pos ) {
                $pos--;
                $str->substr( $pos, 1, '' );
            }
            else {
                $self->{beep} = 1;
            }
        }
        elsif ( $key == CONTROL_U ) {
            if ( $locked ) {
                $self->{beep} = 1;
            }
            elsif ( $pos ) {
                $str->substr( 0, $pos, '' );
                $pos = 0;
            }
            else {
                $self->{beep} = 1;
            }
        }
        elsif ( $key == CONTROL_K ) {
            if ( $locked ) {
                $self->{beep} = 1;
            }
            elsif ( $pos < $str->length() ) {
                $str->substr( $pos, $str->length() - $pos, '' );
            }
            else {
                $self->{beep} = 1;
            }
        }
        elsif ( $key == VK_DELETE || $key == CONTROL_D ) {
            if ( $str->length() ) {
                if ( $locked ) {
                    $self->{beep} = 1;
                }
                elsif ( $pos < $str->length() ) {
                    $str->substr( $pos, 1, '' );
                }
                else {
                    $self->{beep} = 1;
                }
            }
            else {
                print "\n";
                $self->__reset_term();
                return;
            }
        }
        elsif ( $key == VK_RIGHT ) {
            if ( $pos < $str->length() ) {
                $pos++;
            }
            else {
                $self->{beep} = 1;
            }
        }
        elsif ( $key == VK_LEFT ) {
            if ( $pos ) {
                $pos--;
            }
            else {
                $self->{beep} = 1;
            }
        }
        elsif ( $key == VK_END   || $key == CONTROL_E ) {
            if ( $pos < $str->length() ) {
                $pos = $str->length();
            }
            else {
                $self->{beep} = 1;
            }
        }
        elsif ( $key == VK_HOME  || $key == CONTROL_A ) {
            if ( $pos > 0 ) {
                $pos = 0;
            }
            else {
                $self->{beep} = 1;
            }
        }
        elsif ( $key == VK_UP ) {
            if ( $self->{curr_row} == 0 ) {
                $self->{beep} = 1;
            }
            else {
                $self->{curr_row}--;
                ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                if ( $self->{curr_row} >= $self->{begin_row} ) {
                    $self->__reset_previous_row( $opt, $list, $self->{curr_row} + 1 );
                    $self->{plugin}->__up( 1 );
                }
                else {
                    $self->__print_previous_page( $opt, $list );
                }
            }
        }
        elsif ( $key == VK_DOWN ) {
            if ( $self->{curr_row} == $#$list ) {
                $self->{beep} = 1;
            }
            else {
                $self->{curr_row}++;
                ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                if ( $self->{curr_row} <= $self->{end_row} ) {
                    $self->__reset_previous_row( $opt, $list, $self->{curr_row} - 1 );
                    $self->{plugin}->__down( 1 );
                }
                else {
                    $self->{plugin}->__up( $self->{end_row} - $self->{begin_row} );
                    $self->__print_next_page( $opt, $list );
                }
            }
        }
        elsif (  $key == VK_PAGE_UP || $key == CONTROL_B ) {
            if ( $self->{page} == 1 ) {
                if ( $self->{curr_row} == 0 ) {
                    $self->{beep} = 1;
                }
                else {
                    $self->__reset_previous_row( $opt, $list, $self->{curr_row} );
                    $self->{plugin}->__up( $self->{curr_row} );
                    $self->{curr_row} = 0;
                    ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                }
            }
            else {
                $self->{plugin}->__up( $self->{curr_row} - $self->{begin_row} );
                $self->{curr_row} = $self->{begin_row} - $self->{avail_height};
                ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                $self->__print_previous_page( $opt, $list );
            }
        }
        elsif (  $key == VK_PAGE_DOWN || $key == CONTROL_F ) {
            if ( $self->{page} == $self->{pages} ) {
                if ( $self->{curr_row} == $#$list ) {
                    $self->{beep} = 1;
                }
                else {
                    $self->__reset_previous_row( $opt, $list, $self->{curr_row} );
                    $self->{plugin}->__down( $self->{end_row} - $self->{curr_row} );
                    $self->{curr_row} = $self->{end_row};
                    ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                }
            }
            else {
                $self->{plugin}->__up( $self->{curr_row} - $self->{begin_row} );
                $self->{curr_row} = $self->{end_row} + 1;
                ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                $self->__print_next_page( $opt, $list );
            }
        }
        else {
            $key = chr $key;
            utf8::upgrade $key;
            if ( $key eq "\n" || $key eq "\r" ) { #
                my $up = $self->{curr_row} - $self->{begin_row};
                $up += $self->{nr_prompt_lines} if $self->{nr_prompt_lines};
                if ( $list->[$self->{curr_row}][0] eq $opt->{back} ) {
                    $self->{plugin}->__up( $up );
                    $self->{plugin}->__clear_lines_to_end_of_screen();
                    $self->__reset_term();
                    return;
                }
                elsif ( $list->[$self->{curr_row}][0] eq $opt->{confirm} ) {
                    $self->{plugin}->__up( $up );
                    $self->{plugin}->__clear_lines_to_end_of_screen();
                    $self->__reset_term();
                    splice @$list, 0, @{$self->{pre_list}};
                    if ( $self->{compat} || ! defined $self->{compat} && $ENV{READLINE_SIMPLE_COMPAT} ) {
                        return [ map { [ $_->[0], encode( 'console_in', $_->[1] ) ] } @$list ];
                    }
                    return $list;
                }
                if ( $opt->{auto_up} == 2 ) {
                    if ( $self->{curr_row} == 0 ) {
                        $self->{beep} = 1;
                    }
                    else {
                        $self->{plugin}->__up( $up );
                        $self->{plugin}->__clear_lines_to_end_of_screen();
                        ( $str, $pos ) = $self->__write_first_screen( $opt, $list, 0 );
                        ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                    }
                }
                elsif ( $self->{curr_row} == $#$list ) {
                    $self->{plugin}->__up( $up );
                    $self->{plugin}->__clear_lines_to_end_of_screen();
                    ( $str, $pos ) = $self->__write_first_screen( $opt, $list, scalar @{$self->{pre_list}} );
                    ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                    $self->{enter_col} = $pos;
                    $self->{enter_row} = $self->{curr_row};
                }
                else {
                    if ( $opt->{auto_up} == 1 ) {
                        if (    defined $self->{enter_row} && $self->{enter_row} == $self->{curr_row}
                             && defined $self->{enter_col} && $self->{enter_col} == $pos
                        ) {
                            $self->{beep} = 1;
                            next;
                        }
                        else {
                            delete $self->{enter_row};
                            delete $self->{enter_col};
                        }
                    }
                    $self->{curr_row}++;
                    ( $str, $pos ) = $self->__gcstring_and_pos( $list );
                    if ( $self->{curr_row} <= $self->{end_row} ) {
                        $self->__reset_previous_row( $opt, $list, $self->{curr_row} - 1 );
                        $self->{plugin}->__down( 1 );
                    }
                    else {
                        $self->{plugin}->__up( $up );
                        $self->__print_next_page( $opt, $list );
                    }
                }
            }
            else {
                if ( $locked ) {
                    $self->{beep} = 1;
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
    $self->{begin_row} = $self->{end_row} + 1;
    $self->{end_row}   = $self->{end_row} + $self->{avail_height};
    $self->{end_row}   = $#$list if $self->{end_row} > $#$list;
    $self->{plugin}->__clear_lines_to_end_of_screen();
    $self->__write_screen( $opt, $list );
}


sub __print_previous_page {
    my ( $self, $opt, $list ) = @_;
    $self->{end_row}   = $self->{begin_row} - 1;
    $self->{begin_row} = $self->{begin_row} - $self->{avail_height};
    $self->{begin_row} = 0 if $self->{begin_row} < 0;
    $self->{plugin}->__clear_lines_to_end_of_screen();
    $self->__write_screen( $opt, $list );
}


sub __padded_or_trimed_key {
    my ( $self, $list, $idx ) = @_;
    my $unicode;
    my $key_length = $self->{length_key}[$idx];
    my $key = $list->[$idx][0];
    $key =~ s/\p{Space}/ /g;
    $key =~ s/\p{C}//g;
    if ( $key_length > $self->{len_longest_key} ) {
        my $gcs = Unicode::GCString->new( $key );
        $unicode = $self->__unicode_trim( $gcs, $self->{len_longest_key} );
    }
    elsif ( $key_length < $self->{len_longest_key} ) {
        $unicode = " " x ( $self->{len_longest_key} - $key_length ) . $key;
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
    while ( defined( $gc = $gcs->next ) ) {
        if ( ( $len - 3 ) < ( $cols += $gc->columns ) ) {
            my $ret = $gcs->substr( 0, $gcs->pos - 1 );
            $gcs->pos( $pos );
            return $ret->as_string . '...';
        }
    }
}


# use utf8;
# use open qw( :std :utf8 );

# use Term::Form;
# use Term::ReadLine; # 1.14
# use Devel::Peek;

# my $default = 'ü';                    # "\x{fc}"
# character read with readline: 'ä'     # "\x{e4}"


#-----------------------------------------------------------

# my $tr = Term::ReadLine->new( 'Stub' );   # default not supported

#-----------------------------------------------------------

# my $tr = Term::ReadLine->new( 'Perl' );
# my $line = $tr->readline( ': ' );

###  Ã¤    "\303\244"\0

#-----------------------------------------------------------

# my $tr = Term::ReadLine->new( 'Perl' );
# my $line = $tr->readline( ': ', $default );

###  üÃ¤   "\303\274\303\203\302\244"\0 [UTF8 "\x{fc}\x{c3}\x{a4}"]

#-----------------------------------------------------------

# my $tr = Term::ReadLine->new( 'Perl', *STDIN, *STDOUT );
# my $line = $tr->readline( ': ', $default );

###  üä    "\303\274\303\244"\0 [UTF8 "\x{fc}\x{e4}"]

#-----------------------------------------------------------

# my $tr = Term::ReadLine->new( 'Gnu 1.26' );
# my $line = $tr->readline( ': ', $default );

###  Ã¼Ã¤  "\303\274\303\244"\0

#-----------------------------------------------------------

# my $tr = Term::ReadLine->new( 'Gnu 1.26', *STDIN, *STDOUT );
# my $line = $tr->readline( ': ', $default );

###  Ã¼Ã¤  "\303\274\303\244"\0

#-----------------------------------------------------------

# my $tr = Term::Form->new();
# $tr->config( { compat => 0 } );
# my $line = $tr->readline( ': ', $default );

###  üä    "\303\274\303\244"\0 [UTF8 "\x{fc}\x{e4}"]

#-----------------------------------------------------------

# my $tr = Term::Form->new();
# $tr->config( { compat => 1 } );
# my $line = $tr->readline( ': ', $default );

###  Ã¼Ã¤  "\303\274\303\244"\0


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Form - Read lines from STDIN.

=head1 VERSION

Version 0.310

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

=head2 config

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

prompt

If I<prompt> is set, a main prompt string is shown on top of the output.

default: undefined

=item

auto_up

With I<auto_up> set to C<0> or C<1> pressing C<ENTER> moves the cursor to the next line if the cursor is on a
"readline". If the last "readline" row is reached, the cursor jumps to the first "readline" row if C<ENTER> was pressed.
If after an C<ENTER> the cursor has jumped to the first "readline" row and I<auto_up> is set to C<1>, C<ENTER> doesn't
move the cursor to the next row until the cursor is moved with another key. If I<auto_up> is set to C<0> or C<1> the
initially cursor position is on the first "readline" menu entry.

With I<auto_up> set to C<2> C<ENTER> goes to the top menu entry if the cursor is on a "readline". The initially
cursor position is on the first menu entry.

default: C<0>

=item

ro

Set a form-row to readonly.

Expected value: a reference to an array with the indexes of the rows which should be readonly.

default: empty array

=item

confirm

Set the name of the "confirm" menu entry.

default: C<<<>

=item

back

Set the name of the "back" menu entry.

The "back" menu entry is not available if I<back> is not defined or set to an empty string.

default: undefined

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

Copyright 2014-2016 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
