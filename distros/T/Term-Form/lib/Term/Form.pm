package Term::Form;

use warnings;
use strict;
use 5.008003;

our $VERSION = '0.525';
use Exporter 'import';
our @EXPORT_OK = qw( fill_form read_line );

use Carp       qw( croak carp );
use List::Util qw( any );

use Term::Choose::LineFold        qw( line_fold print_columns cut_to_printwidth );
use Term::Choose::Constants       qw( :keys );
use Term::Choose::Screen          qw( :all );
use Term::Choose::Util            qw( unicode_sprintf );
use Term::Choose::ValidateOptions qw( validate_options );

my $Plugin;

BEGIN {
    if ( $^O eq 'MSWin32' ) {
        require Term::Choose::Win32;
        require Win32::Console::ANSI;
        $Plugin = 'Term::Choose::Win32';
    }
    else {
        require Term::Choose::Linux;
        $Plugin = 'Term::Choose::Linux';
    }
}


sub ReadLine { 'Term::Form' }


sub new {
    my $class = shift;
    croak "new: called with " . @_ . " arguments - 0 or 1 arguments expected." if @_ > 1;
    my ( $opt ) = @_;
    my $instance_defaults = _defaults();
    if ( defined $opt ) {
        croak "new: The (optional) argument is not a HASH reference." if ref $opt ne 'HASH';
        validate_options( _valid_options( 'new' ), $opt );
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
    my ( $caller ) = @_;
    if ( $caller eq 'new' ) {
        return {
            clear_screen     => '[ 0 1 ]',
            codepage_mapping => '[ 0 1 ]',
            show_context     => '[ 0 1 ]',
            auto_up          => '[ 0 1 2 ]',
            color            => '[ 0 1 2 ]',
            hide_cursor      => '[ 0 1 2 ]',
            no_echo          => '[ 0 1 2 ]',
            read_only        => 'ARRAY',
            back             => 'Str',
            confirm          => 'Str',
            default          => 'Str',
            extra            => 'Str', # experimental
            info             => 'Str',
            prompt           => 'Str',
        };
    }
    if ( $caller eq 'readline' ) {
        return {
            clear_screen     => '[ 0 1 ]',
            codepage_mapping => '[ 0 1 ]',
            show_context     => '[ 0 1 ]',
            color            => '[ 0 1 2 ]',
            hide_cursor      => '[ 0 1 2 ]',
            no_echo          => '[ 0 1 2 ]',
            default          => 'Str',
            info             => 'Str',
        };
    }
    if ( $caller eq 'fill_form' ) {
        return {
            clear_screen     => '[ 0 1 ]',
            codepage_mapping => '[ 0 1 ]',
            auto_up          => '[ 0 1 2 ]',
            color            => '[ 0 1 2 ]',
            hide_cursor      => '[ 0 1 2 ]',
            read_only        => 'ARRAY',
            back             => 'Str',
            confirm          => 'Str',
            extra            => 'Str', # experimental
            info             => 'Str',
            prompt           => 'Str',
        };
    }
}


sub _defaults {
    return {
        auto_up          => 0,
        back             => '   BACK',
        clear_screen     => 0,
        codepage_mapping => 0,
        color            => 0,
        confirm          => 'CONFIRM',
        default          => '',
        extra            => '', # experimental
        hide_cursor      => 1,
        info             => '',
        no_echo          => 0,
        prompt           => '',
        read_only        => [],
        show_context     => 0,
    };
}


sub __init_term {
    my ( $self ) = @_;
    $self->{plugin}->__set_mode( { mode => 'cbreak', hide_cursor => 0 } );
}


sub __reset_term {
    my ( $self, $up ) = @_;
    if ( defined $self->{plugin} ) {
        $self->{plugin}->__reset_mode();
    }
    if ( $up ) {
        print up( $up );
    }
    print "\r" . clear_to_end_of_screen();
    if ( $self->{hide_cursor} == 1 ) {
        print show_cursor();
    }
    elsif ( $self->{hide_cursor} == 2 ) { # documentation
        print hide_cursor();
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


sub _sanitized_string {
    my ( $str ) = @_;
    if ( defined $str ) {
        $str =~ s/\t/ /g;
        $str =~ s/[\x{000a}-\x{000d}\x{0085}\x{2028}\x{2029}]+/\ \ /g;
        $str =~ s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]//g;
    }
    else {
        $str = '';
    }
    return $str;
}


sub __calculate_threshold {
    my ( $self, $m ) = @_;
    $m->{th_l} = 0;
    $m->{th_r} = 0;
    my ( $tmp_w, $count ) = ( 0, 0 );
    for ( @{$m->{p_str}} ) {
        $tmp_w += $_->[1];
        ++$count;
        if ( $tmp_w > $self->{i}{th} ) {
            $m->{th_l} = $count;
            last;
        }
    }
    ( $tmp_w, $count ) = ( 0, 0 );
    for ( reverse @{$m->{p_str}} ) {
        $tmp_w += $_->[1];
        ++$count;
        if ( $tmp_w > $self->{i}{th} ) {
            $m->{th_r} = $count;
            last;
        }
    }
}


sub __before_readline {
    my ( $self, $m ) = @_;
    my @info = split /\n/, line_fold( $self->{info}, $self->{i}{term_w}, { color => $self->{color} } ), -1;
    if ( $self->{show_context} ) {
        my @before_lines;
        if ( $m->{diff} ) {
            my $line = '';
            my $line_w = 0;
            for my $i ( reverse( 0 .. $m->{diff} - 1 ) ) {
                if ( $line_w + $m->{str}[$i][1] > $self->{i}{term_w} ) {
                    unshift @before_lines, $line;
                    $line   = $m->{str}[$i][0];
                    $line_w = $m->{str}[$i][1];
                    next;
                }
                $line   = $m->{str}[$i][0] . $line;
                $line_w = $m->{str}[$i][1] + $line_w;
            }
            my $total_first_line_w = $self->{i}{max_key_w} + $line_w;
            if ( $total_first_line_w <= $self->{i}{term_w} ) {
                my $empty_w = $self->{i}{term_w} - $total_first_line_w;
                unshift @before_lines, $self->__get_prompt() . ( ' ' x $empty_w ) . $line;
            }
            else {
                my $empty_w = $self->{i}{term_w} - $line_w;
                unshift @before_lines, ' ' x $empty_w . $line;
                unshift @before_lines, $self->__get_prompt();
            }
            $self->{i}{keys}[0] = '';
        }
        else {
            if ( ( $m->{str_w} + $self->{i}{max_key_w} ) <= $self->{i}{term_w} ) {
                $self->{i}{keys}[0] = $self->{i}{prompt};
            }
            else {
                if ( length $self->{i}{prompt} ) { #
                    unshift @before_lines, $self->__get_prompt();
                }
                $self->{i}{keys}[0] = '';
            }
        }
        $self->{i}{pre_text} = join "\n", @info, @before_lines;
    }
    else {
        $self->{i}{keys}[0] = $self->__get_prompt();
        $self->{i}{pre_text} = join "\n", @info;
    }
    $self->{i}{pre_text_row_count} = $self->{i}{pre_text} =~ tr/\n//;
    if ( length $self->{i}{pre_text} ) {
        ++$self->{i}{pre_text_row_count};
    }
}

sub __get_prompt {
    my ( $self ) = @_;
    my $prompt = $self->{i}{prompt};
    if ( exists $self->{i}{prompt_colors} && @{$self->{i}{prompt_colors}} ) {
        my @color = @{$self->{i}{prompt_colors}};
        $prompt =~ s/\x{feff}/shift @color/ge;
        $prompt .= normal();
    }
    return $prompt;
}


sub __after_readline {
    my ( $self, $m ) = @_;
    my $count_chars_after = @{$m->{str}} - ( @{$m->{p_str}} + $m->{diff} );
    if (  ! $self->{show_context} || ! $count_chars_after ) {
        $self->{i}{post_text} = '';
        $self->{i}{post_text_row_count} = 0;
        return;
    }
    my @after_lines;
    my $line = '';
    my $line_w = 0;
    for my $i ( ( @{$m->{str}} - $count_chars_after ) .. $#{$m->{str}} ) {
        if ( $line_w + $m->{str}[$i][1] > $self->{i}{term_w} ) {
            push @after_lines, $line;
            $line = $m->{str}[$i][0];
            $line_w = $m->{str}[$i][1];
            next;
        }
        $line = $line . $m->{str}[$i][0];
        $line_w = $line_w + $m->{str}[$i][1];
    }
    if ( $line_w ) {
        push @after_lines, $line;
    }
    $self->{i}{post_text} = join "\n", @after_lines;
    if ( length $self->{i}{post_text} ) {
        $self->{i}{post_text_row_count} = $self->{i}{post_text} =~ tr/\n//;
        ++$self->{i}{post_text_row_count};
    }
}


sub __init_readline {
    my ( $self, $term_w, $prompt ) = @_;
    $self->{i}{term_w} = $term_w;
    $self->{i}{seps}[0] = ''; # in __readline
    $self->{i}{curr_row} = 0; # in __readlline and __string_and_pos
    if ( $self->{color} ) {
        my @color;
        $prompt =~ s/\x{feff}//g;
        $prompt =~ s/(\e\[[\d;]*m)/push( @color, $1 ) && "\x{feff}"/ge;
        $self->{i}{prompt_colors} = [ @color ];
    }
    $prompt = _sanitized_string( $prompt );
    $self->{i}{max_key_w} = print_columns( $prompt );
    if ( $self->{i}{max_key_w} > $term_w / 3 ) {
        $self->{i}{max_key_w} = int( $term_w / 3 );
        $self->{i}{prompt} = $self->__unicode_trim( $prompt, $self->{i}{max_key_w} );
    }
    else {
        $self->{i}{prompt} = $prompt;
    }
    if ( $self->{show_context} ) {
        $self->{i}{arrow_left}  = '';
        $self->{i}{arrow_right} = '';
        $self->{i}{arrow_w} = 0;
        $self->{i}{avail_w} = $term_w;
    }
    else {
        $self->{i}{arrow_left}  = '<';
        $self->{i}{arrow_right} = '>';
        $self->{i}{arrow_w} = 1;
        $self->{i}{avail_w} = $term_w - ( $self->{i}{max_key_w} + $self->{i}{arrow_w} );
        # arrow_w: see comment in __prepare_width
    }
    $self->{i}{th} = int( $self->{i}{avail_w} / 5 );
    $self->{i}{th} = 40 if $self->{i}{th} > 40;
    my $list = [ [ $prompt, $self->{default} ] ];
    my $m = $self->__string_and_pos( $list );
    return $m;
}


sub read_line {
    if ( ref $_[0] eq __PACKAGE__ ) {
        croak "\"read_line\" is a function. The method is called \"readline\"";
    }
    my $ob = __PACKAGE__->new();
    delete $ob->{backup_instance_defaults};
    return $ob->readline( @_ );
}


sub readline {
    my ( $self, $prompt, $opt ) = @_;
    $prompt = ''                                         if ! defined $prompt;
    croak "readline: a reference is not a valid prompt." if ref $prompt;
    $opt = {}                                            if ! defined $opt;
    if ( ! ref $opt ) {
        $opt = { default => $opt };
    }
    elsif ( ref $opt ne 'HASH' ) {
        croak "readline: the (optional) second argument must be a string or a HASH reference";
    }
    if ( %$opt ) {
        validate_options( _valid_options( 'readline' ), $opt );
        for my $key ( keys %$opt ) {
            $self->{$key} = $opt->{$key} if defined $opt->{$key};
        }
    }
    if ( $^O eq "MSWin32" ) {
        print $self->{codepage_mapping} ? "\e(K" : "\e(U";
    }
    local $| = 1;
    local $SIG{INT} = sub {
        $self->__reset_term();
        print "^C\n";
        exit;
    };
    $self->__init_term();
    my $term_w = ( get_term_size() )[0];
    my $m = $self->__init_readline( $term_w, $prompt );
    my $big_step = 10;
    my $up_before = 0;
    if ( $self->{clear_screen} ) {
        print clear_screen();
    }

    CHAR: while ( 1 ) {
        if ( $self->{i}{beep} ) {
            print bell();
            $self->{i}{beep} = 0;
        }
        my $tmp_term_w = ( get_term_size() )[0];
        if ( $tmp_term_w != $term_w ) {
            $term_w = $tmp_term_w;
            $m = $self->__init_readline( $term_w, $prompt );
        }
        if ( $up_before ) {
            print up( $up_before );
        }
        print "\r" . clear_to_end_of_screen();
        $self->__before_readline( $m );
        $up_before = $self->{i}{pre_text_row_count};
        if ( $self->{hide_cursor} ) {
            print hide_cursor();
        }
        if ( length $self->{i}{pre_text} ) {
            print $self->{i}{pre_text}, "\n";
        }
        $self->__after_readline( $m );
        if ( length $self->{i}{post_text} ) {
            print "\n" . $self->{i}{post_text};
            print up( $self->{i}{post_text_row_count} );
        }
        $self->__print_readline( $m );
        my $char = $self->{plugin}->__get_key_OS();
        if ( ! defined $char ) {
            $self->__reset_term();
            carp "EOT: $!";
            return;
        }
        # reset $m->{avail_w} to default:
        $m->{avail_w} = $self->{i}{avail_w};
        $self->__calculate_threshold( $m );
        if    ( $char == NEXT_get_key ) { next CHAR }
        elsif ( $char == KEY_TAB      ) { next CHAR }
        elsif ( $char == VK_UP   ) {
            for ( 1 .. $big_step ) { last if $m->{pos} == 0; $self->__left( $m  ) }
        }
        elsif ( $char == VK_DOWN ) {
            for ( 1 .. $big_step ) { last if $m->{pos} == @{$m->{str}}; $self->__right( $m ) }
        }
        elsif ( $char == CONTROL_U                        ) { $self->__ctrl_u( $m ) }
        elsif ( $char == CONTROL_K                        ) { $self->__ctrl_k( $m ) }
        elsif ( $char == VK_RIGHT   || $char == CONTROL_F ) { $self->__right(  $m ) }
        elsif ( $char == VK_LEFT    || $char == CONTROL_B ) { $self->__left(   $m ) }
        elsif ( $char == VK_END     || $char == CONTROL_E ) { $self->__end(    $m ) }
        elsif ( $char == VK_HOME    || $char == CONTROL_A ) { $self->__home(   $m ) }
        elsif ( $char == KEY_BSPACE || $char == CONTROL_H ) { $self->__bspace( $m ) }
        elsif ( $char == VK_DELETE  || $char == CONTROL_D ) { $self->__delete( $m ) }
        elsif ( $char == CONTROL_X ) {
            if ( @{$m->{str}} ) {
                my $list = [ [ $prompt, '' ] ];
                $m = $self->__string_and_pos( $list );
            }
            else {
                $self->__reset_term( $self->{i}{pre_text_row_count} );
                return;
            }
        }
        elsif ( $char == VK_PAGE_UP || $char == VK_PAGE_DOWN || $char == VK_INSERT ) {
            $self->{i}{beep} = 1;
        }
        elsif ( $char == LINE_FEED || $char == CARRIAGE_RETURN ) {
            $self->__reset_term( $self->{i}{pre_text_row_count} );
            return join( '', map { $_->[0] } @{$m->{str}} );
        }
        else {
            $char = chr $char;
            utf8::upgrade $char;
            $self->__add_char( $m, $char );
        }
    }
}


sub __string_and_pos {
    my ( $self, $list ) = @_;
    my $default = $list->[$self->{i}{curr_row}][1];
    if ( ! defined $default ) {
        $default = '';
    }
    my $m = {
        avail_w => $self->{i}{avail_w},
        th_l    => 0,
        th_r    => 0,
        str     => [],
        str_w   => 0,
        pos     => 0,
        p_str   => [],
        p_str_w => 0,
        p_pos   => 0,
        diff    => 0,
    };
    for ( $default =~ /\X/g ) {
        my $char_w = print_columns( $_ );
        push @{$m->{str}}, [ $_, $char_w ];
        $m->{str_w} += $char_w;
    }
    $m->{pos}  = @{$m->{str}};
    $m->{diff} = $m->{pos};
    _unshift_till_avail_w( $m, [ 0 .. $#{$m->{str}} ] );
    return $m;
}


sub __left {
    my ( $self, $m ) = @_;
    if ( $m->{pos} ) {
        $m->{pos}--;
        # '<=' and not '==' because th_l could change and fall behind p_pos
        while ( $m->{p_pos} <= $m->{th_l} && $m->{diff} ) {
            _unshift_element( $m, $m->{pos} - $m->{p_pos} );
        }
        if ( ! $m->{diff} ) { # no '<'
            $m->{avail_w} = $self->{i}{avail_w} + $self->{i}{arrow_w};
            _push_till_avail_w( $m, [ $#{$m->{p_str}} + 1 .. $#{$m->{str}} ] );
        }
        $m->{p_pos}--;
    }
    else {
        $self->{i}{beep} = 1;
    }
}


sub __right {
    my ( $self, $m ) = @_;
    if ( $m->{pos} < $#{$m->{str}} ) {
        $m->{pos}++;
        # '>=' and not '==' because th_r could change and fall in front of p_pos
        while ( $m->{p_pos} >= $#{$m->{p_str}} - $m->{th_r} && $#{$m->{p_str}} + $m->{diff} != $#{$m->{str}} ) {
            _push_element( $m );
        }
        $m->{p_pos}++;
    }
    elsif ( $m->{pos} == $#{$m->{str}} ) {
        #rec w if vw
        $m->{pos}++;
        $m->{p_pos}++;
        # cursor now behind the string at the end posistion
    }
    else {
        $self->{i}{beep} = 1;
    }
}

sub __bspace {
    my ( $self, $m ) = @_;
    if ( $m->{pos} ) {
        $m->{pos}--;
        # '<=' and not '==' because th_l could change and fall behind p_pos
        while ( $m->{p_pos} <= $m->{th_l} && $m->{diff} ) {
            _unshift_element( $m, $m->{pos} - $m->{p_pos} );
        }
        $m->{p_pos}--;
        if ( ! $m->{diff} ) { # no '<'
            $m->{avail_w} = $self->{i}{avail_w} + $self->{i}{arrow_w};
        }
        _remove_pos( $m );
    }
    else {
        $self->{i}{beep} = 1;
    }
}

sub __delete {
    my ( $self, $m ) = @_;
    if ( $m->{pos} < @{$m->{str}} ) {
        if ( ! $m->{diff} ) { # no '<'
            $m->{avail_w} = $self->{i}{avail_w} + $self->{i}{arrow_w};
        }
        _remove_pos( $m );
    }
    else {
        return;
    }
}

sub __ctrl_u {
    my ( $self, $m ) = @_;
    if ( $m->{pos} ) {
        for my $removed ( splice ( @{$m->{str}}, 0, $m->{pos} ) ) {
            $m->{str_w} -= $removed->[1];
        }
        # diff always 0     # never '<'
        $m->{avail_w} = $self->{i}{avail_w} + $self->{i}{arrow_w};
        _fill_from_begin( $m );
    }
    else {
        $self->{i}{beep} = 1;
    }
}

sub __ctrl_k {
    my ( $self, $m ) = @_;
    if ( $m->{pos} < @{$m->{str}} ) {
        for my $removed ( splice ( @{$m->{str}}, $m->{pos}, @{$m->{str}} - $m->{pos} ) ) {
            $m->{str_w} -= $removed->[1];
        }
        _fill_from_end( $m );
    }
    else {
        $self->{i}{beep} = 1;
    }
}

sub __home {
    my ( $self, $m ) = @_;
    if ( $m->{pos} > 0 ) {
        # diff always 0     # never '<'
        $m->{avail_w} = $self->{i}{avail_w} + $self->{i}{arrow_w};
        _fill_from_begin( $m );
    }
    else {
        $self->{i}{beep} = 1;
    }
}

sub __end {
    my ( $self, $m ) = @_;
    if ( $m->{pos} < @{$m->{str}} ) {
        _fill_from_end( $m );
    }
    else {
        $self->{i}{beep} = 1;
    }
}

sub __add_char {
    my ( $self, $m, $char ) = @_;
    my $char_w = print_columns( $char );
    splice( @{$m->{str}}, $m->{pos}, 0, [ $char, $char_w ] );
    $m->{pos}++;
    splice( @{$m->{p_str}}, $m->{p_pos}, 0, [ $char, $char_w ] );
    $m->{p_pos}++;
    $m->{p_str_w} += $char_w;
    $m->{str_w}   += $char_w;
    # no '<' if:
    if ( ! $m->{diff} && $m->{p_pos} < $self->{i}{avail_w} + $self->{i}{arrow_w} ) {
        $m->{avail_w} = $self->{i}{avail_w} + $self->{i}{arrow_w};
    }
    while ( $m->{p_pos} < $#{$m->{p_str}} ) {
        if ( $m->{p_str_w} <= $m->{avail_w} ) {
            last;
        }
        my $tmp = pop @{$m->{p_str}};
        $m->{p_str_w} -= $tmp->[1];
    }
    while ( $m->{p_str_w} > $m->{avail_w} ) {
        my $tmp = shift @{$m->{p_str}};
        $m->{p_str_w} -= $tmp->[1];
        $m->{p_pos}--;
        $m->{diff}++;
    }
}


sub _unshift_element {
    my ( $m, $pos ) = @_;
    my $tmp = $m->{str}[$pos];
    unshift @{$m->{p_str}}, $tmp;
    $m->{p_str_w} += $tmp->[1];
    $m->{diff}--;
    $m->{p_pos}++;
    while ( $m->{p_str_w} > $m->{avail_w} ) {
        my $tmp = pop @{$m->{p_str}};
        $m->{p_str_w} -= $tmp->[1];
    }
}

sub _push_element {
    my ( $m ) = @_;
    my $tmp = $m->{str}[$#{$m->{p_str}} + $m->{diff} + 1];
    push @{$m->{p_str}}, $tmp;
    if ( defined $tmp->[1] ) {
        $m->{p_str_w} += $tmp->[1];
    }
    while ( $m->{p_str_w} > $m->{avail_w} ) {
        my $tmp = shift @{$m->{p_str}};
        $m->{p_str_w} -= $tmp->[1];
        $m->{diff}++;
        $m->{p_pos}--;
    }
}

sub _unshift_till_avail_w {
    my ( $m, $idx ) = @_;
    for ( @{$m->{str}}[reverse @$idx] ) {
        if ( $m->{p_str_w} + $_->[1] > $m->{avail_w} ) {
            last;
        }
        unshift @{$m->{p_str}}, $_;
        $m->{p_str_w} += $_->[1];
        $m->{p_pos}++;  # p_pos stays on the last element of the p_str
        $m->{diff}--;   # diff: difference between p_pos and pos; pos is always bigger or equal p_pos
    }
}

sub _push_till_avail_w {
    my ( $m, $idx ) = @_;
    for ( @{$m->{str}}[@$idx] ) {
        if ( $m->{p_str_w} + $_->[1] > $m->{avail_w} ) {
            last;
        }
        push @{$m->{p_str}}, $_;
        $m->{p_str_w} += $_->[1];
    }
}

sub _remove_pos {
    my ( $m ) = @_;
    splice( @{$m->{str}}, $m->{pos}, 1 );
    my $tmp = splice( @{$m->{p_str}}, $m->{p_pos}, 1 );
    $m->{p_str_w} -= $tmp->[1];
    $m->{str_w}   -= $tmp->[1];
    _push_till_avail_w( $m, [ ( $#{$m->{p_str}} + $m->{diff} + 1 ) .. $#{$m->{str}} ] );
}

sub _fill_from_end {
    my ( $m ) = @_;
    $m->{pos}     = @{$m->{str}};
    $m->{p_str}   = [];
    $m->{p_str_w} = 0;
    $m->{diff}    = @{$m->{str}};
    $m->{p_pos}   = 0;
    _unshift_till_avail_w( $m, [ 0 .. $#{$m->{str}} ] );
}

sub _fill_from_begin {
    my ( $m ) = @_;
    $m->{pos}     = 0;
    $m->{p_pos}   = 0;
    $m->{diff}    = 0;
    $m->{p_str}   = [];
    $m->{p_str_w} = 0;
    _push_till_avail_w( $m, [ 0 .. $#{$m->{str}} ] );
}


sub __print_readline {
    my ( $self, $m ) = @_;
    print "\r" . clear_to_end_of_line();
    my $i = $self->{i}{curr_row};
    if ( $self->{no_echo} && $self->{no_echo} == 2 ) {
        print "\r" . $self->{i}{keys}[$i]; # no_echo only in readline -> in readline no separator
        return;
    }
    print "\r" . $self->{i}{keys}[$i] . $self->{i}{seps}[$i];
    my $print_str = '';
    # left arrow:
    if ( $m->{diff} ) {
        $print_str .= $self->{i}{arrow_left};
    }
    # input text:
    if ( $self->{no_echo} ) {
        $print_str .= ( '*' x @{$m->{p_str}} );
    }
    else {
        $print_str .= join( '', map { $_->[0] } @{$m->{p_str}} );
    }
    # right arrow:
    if ( @{$m->{p_str}} + $m->{diff} != @{$m->{str}} ) {
        $print_str .= $self->{i}{arrow_right};
    }
    my $back_to_pos = 0;
    for ( @{$m->{p_str}}[$m->{p_pos} .. $#{$m->{p_str}}] ) {
        $back_to_pos += $_->[1];
    }
    if ( $self->{hide_cursor} ) {
        print show_cursor();
    }
    print $print_str;
    if ( $back_to_pos ) {
        print left( $back_to_pos );
    }
}


sub __unicode_trim {
    my ( $self, $str, $len ) = @_;
    return $str if print_columns( $str ) <= $len;
    return cut_to_printwidth( $str, $len - 3, 0 ) . '...';
}


sub __length_longest_key {
    my ( $self, $list ) = @_;
    my $len = []; #
    my $longest = 0;
    for my $i ( 0 .. $#$list ) {
        $len->[$i] = print_columns( $list->[$i][0] );
        if ( $i < @{$self->{i}{pre}} ) {
            next;
        }
        $longest = $len->[$i] if $len->[$i] > $longest;
    }
    $self->{i}{max_key_w} = $longest;
    $self->{i}{key_w} = $len;
}


sub __prepare_width {
    my ( $self, $term_w ) = @_;
    $self->{i}{term_w} = $term_w;
    if ( $self->{i}{max_key_w} > $term_w / 3 ) {
        $self->{i}{max_key_w} = int( $term_w / 3 );
    }
    $self->{i}{avail_w} = $term_w - ( $self->{i}{max_key_w} + length( $self->{i}{sep} ) + $self->{i}{arrow_w} );
    # Subtract $self->{i}{arrow_w} for the '<' before the string.
    # In each case where no '<'-prefix is required (diff==0) $self->{i}{arrow_w} is added again.
    # Routins where $self->{i}{arrow_w} is added:  __left, __bspace, __home, __ctrl_u, __delete
    # The required space (1) for the cursor (or the '>') behind the string is already subtracted in get_term_size
    $self->{i}{th} = int( $self->{i}{avail_w} / 5 );
    $self->{i}{th} = 40 if $self->{i}{th} > 40;
}


sub __prepare_hight {
    my ( $self, $list, $term_w, $term_h ) = @_;
    $self->{i}{avail_h} = $term_h;
    if ( length $self->{i}{pre_text} ) {
        $self->{i}{pre_text} = line_fold( $self->{i}{pre_text}, $term_w, { color => $self->{color} } );
        $self->{i}{pre_text_row_count} = $self->{i}{pre_text} =~ tr/\n//;
        $self->{i}{pre_text_row_count} += 1;
        $self->{i}{avail_h} -= $self->{i}{pre_text_row_count};
        my $min_avail_h = 5;
        if (  $term_h < $min_avail_h ) {
            $min_avail_h =  $term_h;
        }
        if ( $self->{i}{avail_h} < $min_avail_h ) {
            $self->{i}{avail_h} = $min_avail_h;
        }
    }
    else {
        $self->{i}{pre_text_row_count} = 0;
    }
    if ( @$list > $self->{i}{avail_h} ) {
        $self->{i}{pages} = int @$list / ( $self->{i}{avail_h} - 1 );
        if ( @$list % ( $self->{i}{avail_h} - 1 ) ) {
            $self->{i}{pages}++;
        }
        $self->{i}{avail_h}--;
    }
    else {
        $self->{i}{pages} = 1;
    }
    return;
}


sub __print_current_row {
    my ( $self, $list, $m ) = @_;
    print "\r" . clear_to_end_of_line();
    if ( $self->{i}{curr_row} < @{$self->{i}{pre}} ) {
        print reverse_video();
        print $list->[$self->{i}{curr_row}][0];
        print normal();
    }
    else {
        $self->__print_readline( $m );
        $list->[$self->{i}{curr_row}][1] = join( '', map { defined $_->[0] ? $_->[0] : '' } @{$m->{str}} );
    }
}


sub __get_row {
    my ( $self, $list, $idx ) = @_;
    if ( $idx < @{$self->{i}{pre}} ) {
        return $list->[$idx][0];
    }
    if ( ! defined $self->{i}{keys}[$idx] ) {
        my $key = $list->[$idx][0];
        $self->{i}{keys}[$idx] = unicode_sprintf( $key, $self->{i}{max_key_w} );
    }
    if ( ! defined $self->{i}{seps}[$idx] ) {
        my $sep;
        if ( any { $_ == $idx } @{$self->{i}{read_only}} ) {
            $self->{i}{seps}[$idx] = $self->{i}{sep_ro};
        }
        else {
            $self->{i}{seps}[$idx] = $self->{i}{sep};
        }
    }
    my $val;
    if ( defined $list->[$idx][1] ) {
        $val = $self->__unicode_trim( $list->[$idx][1], $self->{i}{avail_w} );
    }
    else {
        $val = '';
    }
    if ( exists $self->{i}{key_colors} && @{$self->{i}{key_colors}[$idx]} ) {
        my @key_colors = @{$self->{i}{key_colors}[$idx]};
        $self->{i}{keys}[$idx] =~ s/\x{feff}/shift @key_colors/ge;
        $self->{i}{keys}[$idx] .= normal();
    }
    return $self->{i}{keys}[$idx] . $self->{i}{seps}[$idx] . $val;
}


sub __write_screen {
    my ( $self, $list ) = @_;
    my @rows;
    for my $idx ( $self->{i}{begin_row} .. $self->{i}{end_row} ) {
        push @rows, $self->__get_row( $list, $idx );
    }
    print join "\n", @rows;
    if ( $self->{i}{pages} > 1 ) {
        if ( $self->{i}{avail_h} - ( $self->{i}{end_row} + 1 - $self->{i}{begin_row} ) ) {
            print "\n" x ( $self->{i}{avail_h} - ( $self->{i}{end_row} - $self->{i}{begin_row} ) - 1 );
        }
        $self->{i}{page} = int( $self->{i}{end_row} / $self->{i}{avail_h} ) + 1;
        my $page_number = sprintf '- Page %d/%d -', $self->{i}{page}, $self->{i}{pages};
        if ( length $page_number > $self->{i}{term_w} ) {
            $page_number = substr sprintf( '%d/%d', $self->{i}{page}, $self->{i}{pages} ), 0, $self->{i}{term_w};
        }
        print "\n", $page_number;
        my $up = $self->{i}{avail_h} - ( $self->{i}{curr_row} - $self->{i}{begin_row} );
        print up( $up ) if $up;
    }
    else {
        $self->{i}{page} = 1;
        my $up = $self->{i}{end_row} - $self->{i}{curr_row};
        print up( $up ) if $up;
    }
}


sub __write_first_screen {
    my ( $self, $list, $curr_row, $auto_up ) = @_;
    if ( $auto_up == 2 ) {
        $self->{i}{curr_row} = $curr_row;
    }
    else {
        $self->{i}{curr_row} = @{$self->{i}{pre}};
    }
    $self->{i}{begin_row} = 0;
    $self->{i}{end_row}  = ( $self->{i}{avail_h} - 1 );
    if ( $self->{i}{end_row} > $#$list ) {
        $self->{i}{end_row} = $#$list;
    }
    $self->{i}{seps} = [];
    $self->{i}{keys} = [];
    if ( $self->{clear_screen} ) {
        print clear_screen();
    }
    else {
        print "\r" . clear_to_end_of_screen();
    }
    if ( $self->{hide_cursor} ) {
        print hide_cursor();
    }
    if ( length $self->{i}{pre_text} ) {
        print $self->{i}{pre_text} . "\n";
    }
    $self->__write_screen( $list );
}

sub __prepare_meta_menu_elements {
    my ( $self, $term_w ) = @_;
    my @meta_menu_elements = ( 'back', 'confirm' );
    if ( defined $self->{extra} && length $self->{extra} ) {
        unshift @meta_menu_elements, 'extra';
    }
    $self->{i}{pre} = [];
    for my $meta_menu_element ( @meta_menu_elements ) {
        my @color;
        my $tmp = $self->{i}{$meta_menu_element . '_orig'};
        if ( $self->{color} ) {
            $tmp =~ s/\x{feff}//g;
            $tmp =~ s/(\e\[[\d;]*m)/push( @color, $1 ) && "\x{feff}"/ge;
        }
        $tmp = _sanitized_string( $tmp );
        if ( print_columns( $tmp ) > $term_w ) {
            $tmp = cut_to_printwidth( $tmp, $term_w, 0 );
        }
        if ( @color ) {
            $tmp =~ s/\x{feff}/shift @color/ge;
            $tmp .= normal();
        }
        $self->{$meta_menu_element} = $tmp;
        push @{$self->{i}{pre}}, [ $self->{$meta_menu_element}, ];
    }
}


sub fill_form {
    if ( ref $_[0] ne __PACKAGE__ ) {
        my $ob = __PACKAGE__->new();
        delete $ob->{backup_instance_defaults};
        return $ob->fill_form( @_ );
    }
    my ( $self, $orig_list, $opt ) = @_;
    croak "'fill_form' called with no argument." if ! defined $orig_list;
    croak "'fill_form' requires an ARRAY reference as its argument." if ref $orig_list ne 'ARRAY';
    $opt = {} if ! defined $opt;
    croak "'fill_form': the (optional) second argument must be a HASH reference" if ref $opt ne 'HASH';
    return [] if ! @$orig_list; ##
    if ( %$opt ) {
        validate_options( _valid_options( 'fill_form' ), $opt );
        for my $key ( keys %$opt ) {
            $self->{$key} = $opt->{$key} if defined $opt->{$key};
        }
    }
    if ( $^O eq "MSWin32" ) {
        print $self->{codepage_mapping} ? "\e(K" : "\e(U";
    }
    my @tmp;
    push @tmp, $self->{info}   if length $self->{info};
    push @tmp, $self->{prompt} if length $self->{prompt};
    $self->{i}{pre_text} = join "\n", @tmp;
    $self->{i}{sep}    = ': ';
    $self->{i}{sep_ro} = '| ';
    die if length $self->{i}{sep} != length $self->{i}{sep_ro};
    $self->{i}{arrow_left}  = '<';
    $self->{i}{arrow_right} = '>';
    $self->{i}{arrow_w} = 1;
    local $| = 1;
    local $SIG{INT} = sub {
        $self->__reset_term();
        print "^C\n";
        exit;
    };
    $self->__init_term();
    my ( $term_w, $term_h ) = get_term_size();
    $self->{i}{extra_orig}   = $self->{extra};
    $self->{i}{back_orig}    = $self->{back};
    $self->{i}{confirm_orig} = $self->{confirm};
    $self->__prepare_meta_menu_elements( $term_w );
    $self->{i}{read_only} = [];
    if ( @{$self->{read_only}} ) {
        $self->{i}{read_only} = [ map { $_ + @{$self->{i}{pre}} } @{$self->{read_only}} ];
    }
    my $list;
    if ( $self->{color} ) {
        $list = [ @{$self->{i}{pre}} ];
        my $count = @{$self->{i}{pre}};
        for my $entry ( @$orig_list ) {
            my ( $key, $value ) = @$entry;
            my @color;
            $key =~ s/\x{feff}//g;
            $key =~ s/(\e\[[\d;]*m)/push( @color, $1 ) && "\x{feff}"/ge;
            $self->{i}{key_colors}[$count++] = [ @color ];
            push @$list, [ _sanitized_string( $key ), $value ];
        }
    }
    else {
        $list = [ @{$self->{i}{pre}}, map { [ _sanitized_string( $_->[0] ), $_->[1] ] } @$orig_list ];
    }
    my $auto_up = $self->{auto_up};
    my $back_row = 0;
    if ( $self->{extra} ) {
        $back_row = 1;
    }
    $self->__length_longest_key( $list );
    $self->__prepare_width( $term_w );
    $self->__prepare_hight( $list, $term_w, $term_h );
    $self->__write_first_screen( $list, $back_row, $auto_up );
    my $m = $self->__string_and_pos( $list );
    my $k = 0;

    CHAR: while ( 1 ) {
        my $locked = 0;
        if ( any { $_ == $self->{i}{curr_row} } @{$self->{i}{read_only}} ) {
            $locked = 1;
        }
        if ( $self->{i}{beep} ) {
            print bell();
            $self->{i}{beep} = 0;
        }
        else {
            if ( $self->{hide_cursor} ) {
                print hide_cursor();
            }
            $self->__print_current_row( $list, $m );
        }
        my $char = $self->{plugin}->__get_key_OS();
        if ( ! defined $char ) {
            $self->__reset_term();
            carp "EOT: $!";
            return;
        }
        next CHAR if $char == NEXT_get_key;
        next CHAR if $char == KEY_TAB;
        my ( $tmp_term_w, $tmp_term_h ) = get_term_size();
        if ( $tmp_term_w != $term_w || $tmp_term_h != $term_h && $tmp_term_h < ( @$list + 1 ) ) {
            my $up = $self->{i}{curr_row} + $self->{i}{pre_text_row_count};
            print up( $up ) if $up;
            ( $term_w, $term_h ) = ( $tmp_term_w, $tmp_term_h );
            $self->__prepare_meta_menu_elements( $term_w );
            $self->__length_longest_key( $list );
            $self->__prepare_width( $term_w );
            $self->__prepare_hight( $list, $term_w, $term_h );
            $self->__write_first_screen( $list, $back_row, $auto_up );
            $m = $self->__string_and_pos( $list );
        }
        # reset $m->{avail_w} to default:
        $m->{avail_w} = $self->{i}{avail_w};
        $self->__calculate_threshold( $m );
        if ( $char == KEY_BSPACE || $char == CONTROL_H ) {
            $k = 1;
            if ( $locked ) {    # read_only
                $self->{i}{beep} = 1;
            }
            else {
                $self->__bspace( $m );
            }
        }
        elsif ( $char == CONTROL_U ) {
            $k = 1;
            if ( $locked ) {
                $self->{i}{beep} = 1;
            }
            else {
                $self->__ctrl_u( $m );
            }
        }
        elsif ( $char == CONTROL_K ) {
            $k = 1;
            if ( $locked ) {
                $self->{i}{beep} = 1;
            }
            else {
                $self->__ctrl_k( $m );
            }
        }
        elsif ( $char == VK_DELETE || $char == CONTROL_D ) {
            $k = 1;
            $self->__delete( $m );
        }
        elsif ( $char == VK_RIGHT ) {
            $k = 1;
            $self->__right( $m );
        }
        elsif ( $char == VK_LEFT ) {
            $k = 1;
            $self->__left( $m );
        }
        elsif ( $char == VK_END   || $char == CONTROL_E ) {
            $k = 1;
            $self->__end( $m );
        }
        elsif ( $char == VK_HOME  || $char == CONTROL_A ) {
            $k = 1;
            $self->__home( $m );
        }
        elsif ( $char == VK_UP ) {
            $k = 1;
            if ( $self->{i}{curr_row} == 0 ) {
                $self->{i}{beep} = 1;
            }
            else {
                $self->{i}{curr_row}--;
                $m = $self->__string_and_pos( $list );
                if ( $self->{i}{curr_row} >= $self->{i}{begin_row} ) {
                    $self->__reset_previous_row( $list, $self->{i}{curr_row} + 1 );
                    print up( 1 );
                }
                else {
                    $self->__print_previous_page( $list );
                }
            }
        }
        elsif ( $char == VK_DOWN ) {
            $k = 1;
            if ( $self->{i}{curr_row} == $#$list ) {
                $self->{i}{beep} = 1;
            }
            else {
                $self->{i}{curr_row}++;
                $m = $self->__string_and_pos( $list );
                if ( $self->{i}{curr_row} <= $self->{i}{end_row} ) {
                    $self->__reset_previous_row( $list, $self->{i}{curr_row} - 1 );
                    print down( 1 );
                }
                else {
                    print up( $self->{i}{end_row} - $self->{i}{begin_row} );
                    $self->__print_next_page( $list );
                }
            }
        }
        elsif ( $char == VK_PAGE_UP || $char == CONTROL_B ) {
            $k = 1;
            if ( $self->{i}{page} == 1 ) {
                if ( $self->{i}{curr_row} == 0 ) {
                    $self->{i}{beep} = 1;
                }
                else {
                    $self->__reset_previous_row( $list, $self->{i}{curr_row} );
                    print up( $self->{i}{curr_row} );
                    $self->{i}{curr_row} = 0;
                    $m = $self->__string_and_pos( $list );
                }
            }
            else {
                my $up = $self->{i}{curr_row} - $self->{i}{begin_row};
                print up( $up ) if $up;
                $self->{i}{curr_row} = $self->{i}{begin_row} - $self->{i}{avail_h};
                $m = $self->__string_and_pos( $list );
                $self->__print_previous_page( $list );
            }
        }
        elsif ( $char == VK_PAGE_DOWN || $char == CONTROL_F ) {
            $k = 1;
            if ( $self->{i}{page} == $self->{i}{pages} ) {
                if ( $self->{i}{curr_row} == $#$list ) {
                    $self->{i}{beep} = 1;
                }
                else {
                    $self->__reset_previous_row( $list, $self->{i}{curr_row} );
                    my $rows = $self->{i}{end_row} - $self->{i}{curr_row};
                    print down( $rows );
                    $self->{i}{curr_row} = $self->{i}{end_row};
                    $m = $self->__string_and_pos( $list );
                }
            }
            else {
                my $up = $self->{i}{curr_row} - $self->{i}{begin_row};
                print up( $up ) if $up;
                $self->{i}{curr_row} = $self->{i}{end_row} + 1;
                $m = $self->__string_and_pos( $list );
                $self->__print_next_page( $list );
            }
        }
        elsif ( $char == CONTROL_X ) {
            my $up = $self->{i}{curr_row} - $self->{i}{begin_row};
            if ( @{$m->{str}} ) {
                $list->[$self->{i}{curr_row}][1] = '';
                $m = $self->__string_and_pos( $list );
            }
            elsif ( $list->[$self->{i}{curr_row}][0] eq $self->{back} ) {
                    $self->__reset_term( $up );
                    return;
            }
            else {
                print up( $up );
                print "\r" . clear_to_end_of_screen();
                $self->__write_first_screen( $list, $back_row, 2 );
                $m = $self->__string_and_pos( $list );
            }
        }
        elsif ( $char == VK_INSERT ) {
            $self->{i}{beep} = 1;
        }
        elsif ( $char == LINE_FEED || $char == CARRIAGE_RETURN ) {                                                  # ENTER
            $self->{i}{lock_ENTER} = 0 if $k;                                                                       # any previously pressed key other than ENTER removes lock_ENTER
            if ( $auto_up == 2 && $self->{auto_up} == 1 && ! $self->{i}{lock_ENTER} ) {                             # a removed lock_ENTER resets "auto_up" from 2 to 1 if the 2 was originally a 1
                $auto_up = 1;
            }
            if ( $auto_up == 1 && @$list - @{$self->{i}{pre}} == 1 ) {                                              # else auto_up 1 sticks on the last==first data row
                $auto_up = 2;
            }
            $k = 0;                                                                                                 # if ENTER set $k to 0
            my $up = $self->{i}{curr_row} - $self->{i}{begin_row};
            $up += $self->{i}{pre_text_row_count} if $self->{i}{pre_text_row_count};
            if ( $list->[$self->{i}{curr_row}][0] eq $self->{back} ) {                                              # if ENTER on   {back/0}: leave and return nothing
                $self->__reset_term( $up );
                return;
            }
            elsif ( $list->[$self->{i}{curr_row}][0] eq $self->{confirm} ) {                                        # if ENTER on {confirm/1}: leave and return result
                splice @$list, 0, @{$self->{i}{pre}};
                $self->__reset_term( $up );
                return [ map { [ $orig_list->[$_][0], $list->[$_][1] ] } 0 .. $#{$list} ];
            }
            elsif ( $list->[$self->{i}{curr_row}][0] eq $self->{extra} ) {
                $self->__reset_term( $up );
                return -1;
            }
            if ( $auto_up == 2 ) {                                                                                  # if ENTER && "auto_up" == 2 && any row: jumps {back/0}
                print up( $up );
                print "\r" . clear_to_end_of_screen();
                $self->__write_first_screen( $list, $back_row, $auto_up );                                                  # cursor on {back}
                $m = $self->__string_and_pos( $list );
            }
            elsif ( $self->{i}{curr_row} == $#$list ) {                                                             # if ENTER && {last row}: jumps to the {first data row/2}
                print up( $up );
                print "\r" . clear_to_end_of_screen();
                $self->__write_first_screen( $list, scalar( @{$self->{i}{pre}} ), $auto_up );                       # cursor on the first data row
                $m = $self->__string_and_pos( $list );
                $self->{i}{lock_ENTER} = 1;                                                                         # set lock_ENTER when jumped automatically from the {last row} to the {first data row/2}
            }
            else {
                if ( $auto_up == 1 && $self->{i}{curr_row} == @{$self->{i}{pre}} && $self->{i}{lock_ENTER} ) {      # if ENTER && "auto_up" == 1 $$ "curr_row" == {first data row/2} && lock_ENTER is true:
                    $self->{i}{beep} = 1;                                                                           # set "auto_up" temporary to 2 so a second ENTER moves the cursor to {back/0}
                    $auto_up = 2;
                    next CHAR;
                }
                $self->{i}{curr_row}++;
                $m = $self->__string_and_pos( $list );
                if ( $self->{i}{curr_row} <= $self->{i}{end_row} ) {                                                # or go to the next row if not on the last row
                    $self->__reset_previous_row( $list, $self->{i}{curr_row} - 1 );
                    print down( 1 );
                }
                else {
                    print up( $up );                                                                                 # or else to the next page
                    $self->__print_next_page( $list );
                }
            }
        }
        else {
            $k = 1;
            if ( $locked ) {
                $self->{i}{beep} = 1;
            }
            else {
                $char = chr $char;
                utf8::upgrade $char;
                $self->__add_char( $m, $char );
            }
        }
    }
}


sub __reset_previous_row {
    my ( $self, $list, $idx ) = @_;
    print "\r" . clear_to_end_of_line();
    print $self->__get_row( $list, $idx );
}


sub __print_next_page {
    my ( $self, $list ) = @_;
    $self->{i}{begin_row} = $self->{i}{end_row} + 1;
    $self->{i}{end_row}   = $self->{i}{end_row} + $self->{i}{avail_h};
    $self->{i}{end_row}   = $#$list if $self->{i}{end_row} > $#$list;
    print "\r" . clear_to_end_of_screen();
    $self->__write_screen( $list );
}


sub __print_previous_page {
    my ( $self, $list ) = @_;
    $self->{i}{end_row}   = $self->{i}{begin_row} - 1;
    $self->{i}{begin_row} = $self->{i}{begin_row} - $self->{i}{avail_h};
    $self->{i}{begin_row} = 0 if $self->{i}{begin_row} < 0;
    print "\r" . clear_to_end_of_screen();
    $self->__write_screen( $list );
}





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Form - Read lines from STDIN.

=head1 VERSION

Version 0.525

=cut

=head1 SYNOPSIS

    my $aoa = [
        [ 'name'           ],
        [ 'year'           ],
        [ 'color', 'green' ],
        [ 'city'           ]
    ];

    # Object-oriented interface:

    use Term::Form;

    my $new = Term::Form->new();

    my $line = $new->readline( 'Prompt: ', { default => 'abc' } );

    my $modified_list = $new->fill_form( $aoa );

    # Functional interface:

    use Term::Form qw( read_line fill_form );

    my $line = read_line( 'Prompt: ', { default => 'abc' } );

    my $modified_list = fill_form( $aoa );

=head1 DESCRIPTION

C<readline> reads a line from STDIN. As soon as C<Return> is pressed C<readline> returns the read string without the
newline character - so no C<chomp> is required.

C<fill_form> reads a list of lines from STDIN.

This module is intended to cope with Unicode (multibyte character/grapheme cluster).

The output is removed after leaving the method, so the user can decide what remains on the screen.

=head2 Keys

C<BackSpace> or C<Ctrl-H>: Delete the character behind the cursor.

C<Delete> or C<Ctrl-D>: Delete  the  character at point.

C<Ctrl-U>: Delete the text backward from the cursor to the beginning of the line.

C<Ctrl-K>: Delete the text from the cursor to the end of the line.

C<Right-Arrow>: Move forward a character.

C<Left-Arrow>: Move back a character.

C<Home> or C<Ctrl-A>: Move to the start of the line.

C<End> or C<Ctrl-E>: Move to the end of the line.

C<Up-Arrow>: in C<fill_form> move up one row, in C<readline> move back 10 characters.

C<Down-Arrow>: in C<fill_form> move down one row, in C<readline> move forward 10 characters.

C<Ctrl-X>: If the input puffer is not empty, the input puffer is cleared, else C<Ctrl-X> returns nothing (undef).

Only in C<fill_form>:

C<Page-Up> or C<Ctrl-B>: Move back one page.

C<Page-Down> or C<Ctrl-F>: Move forward one page.

=head1 METHODS

=head2 new

The C<new> method returns a C<Term::Form> object.

    my $new = Term::Form->new();

To set the different options it can be passed a reference to a hash as an optional argument.

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

0 - off

1 - on

default: C<0>

=item

color

Enables the support for color and text formatting escape sequences for the prompt string and the I<info> text.

0 - off

1 - on

default: C<0>

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

=item

show_context

Display the input that does not fit into the "readline" before or after the "readline".

0 - disable I<show_context>

1 - enable I<show_context>

default: C<0>

=item

codepage_mapping

This option has only meaning if the operating system is MSWin32.

If the OS is MSWin32, L<Win32::Console::ANSI> is used. By default C<Win32::Console::ANSI> converts the characters from
Windows code page to DOS code page (the so-called ANSI to OEM conversion). This conversation is disabled by default in
C<Term::Choose> but one can enable it by setting this option.

Setting this option to C<1> enables the codepage mapping offered by L<Win32::Console::ANSI>.

0 - disable automatic codepage mapping (default)

1 - keep automatic codepage mapping

default: C<0>

=item

hide_cursor

0 - disabled

1 - enabled

default: C<1>

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

0 - off

1 - on

default: C<0>

=item

color

Enables the support for color and text formatting escape sequences for the form-keys, the "back"-string, the
"confirm"-string, the I<info> text and the I<prompt> text.

0 - off

1 - on

default: C<0>

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

=item

codepage_mapping

This option has only meaning if the operating system is MSWin32.

If the OS is MSWin32, L<Win32::Console::ANSI> is used. By default C<Win32::Console::ANSI> converts the characters from
Windows code page to DOS code page (the so-called ANSI to OEM conversion). This conversation is disabled by default in
C<Term::Choose> but one can enable it by setting this option.

Setting this option to C<1> enables the codepage mapping offered by L<Win32::Console::ANSI>.

0 - disable automatic codepage mapping (default)

1 - keep automatic codepage mapping

default: C<0>

=item

hide_cursor

0 - disabled

1 - enabled

default: C<1>

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

Copyright 2014-2020 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
