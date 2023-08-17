package Term::Form::ReadLine;

use warnings;
use strict;
use 5.10.0;

our $VERSION = '0.554';
use Exporter 'import';
our @EXPORT_OK = qw( read_line );

use parent qw( Term::Form );

use Carp       qw( croak );
use List::Util qw( none any );

use Term::Choose::LineFold        qw( line_fold print_columns );
use Term::Choose::Constants       qw( :all );
use Term::Choose::Screen          qw( :all );
use Term::Choose::Util            qw( get_term_width get_term_height );
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


sub new {
    my $class = shift;
    croak "new: called with " . @_ . " arguments - 0 or 1 arguments expected." if @_ > 1;
    my ( $opt ) = @_;
    my $instance_defaults = _defaults();
    if ( defined $opt ) {
        croak "new: The (optional) argument is not a HASH reference." if ref $opt ne 'HASH';
        my $caller = 'new';
        validate_options( _valid_options(), $opt, $caller );
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
        codepage_mapping => '[ 0 1 ]',
        show_context     => '[ 0 1 ]',
        clear_screen     => '[ 0 1 2 ]',
        color            => '[ 0 1 2 ]',
        hide_cursor      => '[ 0 1 2 ]',       # hide_cursor == 2 # documentation
        no_echo          => '[ 0 1 2 ]',
        page             => '[ 0 1 2 ]',       # undocumented
        history          => 'Array_Str',
        default          => 'Str',
        footer           => 'Str',             # undocumented
        info             => 'Str',
    };
}


sub _defaults {
    return {
        clear_screen       => 0,
        codepage_mapping   => 0,
        color              => 0,
        default            => '',
        footer             => '',
        hide_cursor        => 1,
        history            => [],
        info               => '',
        no_echo            => 0,
        page               => 1,
        show_context       => 0,
    };
}


sub __before_readline {
    my ( $self, $m, $term_w ) = @_;
    if ( $self->{show_context} ) {
        my @pre_text_array;
        if ( $m->{diff} ) {
            my $line = '';
            my $line_w = 0;
            for my $i ( reverse( 0 .. $m->{diff} - 1 ) ) {
                if ( $line_w + $m->{str}[$i][1] > $term_w ) {
                    unshift @pre_text_array, $line;
                    $line   = $m->{str}[$i][0];
                    $line_w = $m->{str}[$i][1];
                }
                else {
                    $line   = $m->{str}[$i][0] . $line;
                    $line_w = $m->{str}[$i][1] + $line_w;
                }
            }
            my $top_pre_line_w = $self->{i}{max_key_w} + $line_w;
            if ( $top_pre_line_w <= $term_w ) {
                my $empty_w = $term_w - $top_pre_line_w;
                unshift @pre_text_array, $self->{i}{prompt} . ( ' ' x $empty_w ) . $line;
            }
            else {
                my $empty_w = $term_w - $line_w;
                unshift @pre_text_array, ' ' x $empty_w . $line;
                unshift @pre_text_array, $self->{i}{prompt};
            }
            $self->{i}{keys}[0] = '';
        }
        else {
            if ( ( $m->{str_w} + $self->{i}{max_key_w} ) <= $term_w ) {
                $self->{i}{keys}[0] = $self->{i}{prompt};
            }
            else {
                if ( length $self->{i}{prompt} ) { #
                    unshift @pre_text_array, $self->{i}{prompt};
                }
                $self->{i}{keys}[0] = '';
            }
        }
        $self->{i}{pre_text} = join "\n", @pre_text_array;
        $self->{i}{pre_text_row_count} = scalar @pre_text_array;
    }
    else {
        $self->{i}{keys}[0] = $self->{i}{prompt};
    }
}


sub __after_readline {
    my ( $self, $m, $term_w ) = @_;
    my $count_chars_after = @{$m->{str}} - ( @{$m->{p_str}} + $m->{diff} );
    if ( ! $self->{show_context} || ! $count_chars_after ) {
        $self->{i}{post_text} = '';
        $self->{i}{post_text_row_count} = 0;
        return;
    }
    my @post_text_array;
    my $line = '';
    my $line_w = 0;
    for my $i ( ( @{$m->{str}} - $count_chars_after ) .. $#{$m->{str}} ) {
        if ( $line_w + $m->{str}[$i][1] > $term_w ) {
            push @post_text_array, $line;
            $line = $m->{str}[$i][0];
            $line_w = $m->{str}[$i][1];
            next;
        }
        $line = $line . $m->{str}[$i][0];
        $line_w = $line_w + $m->{str}[$i][1];
    }
    if ( $line_w ) {
        push @post_text_array, $line;
    }
    $self->{i}{post_text} = join "\n", @post_text_array;
    $self->{i}{post_text_row_count} = scalar @post_text_array;
}


sub __print_footer {
    my ( $self ) = @_;
    my $empty = get_term_height() - $self->{i}{info_row_count} - 1;
    my $footer_line = sprintf $self->{i}{footer_fmt}, $self->{i}{page_count};
    if ( $empty > 0 ) {
        print "\n" x $empty;
        print $footer_line;
        print up( $empty );
    }
    else {
        if ( get_term_height >= 2 ) { ##
            print "\n";
            print $footer_line;
            print up( 1 );
        }
    }
}


sub __modify_readline_options {
    my ( $self ) = @_;
    if ( length $self->{footer} && $self->{page} != 2 ) {
        $self->{page} = 2;
    }
    if ( $self->{page} == 2 && $self->{clear_screen} != 1 ) {
        $self->{clear_screen} = 1;
    }
    $self->{history} = [ reverse grep { length } @{$self->{history}} ];
}


sub __select_history {
    my ( $self, $m, $prompt, $history_up ) = @_;
    if ( ! @{$self->{history}} ) {
        return $m;
    }
    my $current = join '', map { $_->[0] } @{$m->{str}};
    if ( none { $_ eq $current } @{$self->{history}} ) {
        $self->{i}{curr_string} = $current;
    }
    my @history;
    if ( any { $_ eq $current } @{$self->{i}{prev_filtered_history}//[]} ) {
        @history = @{$self->{i}{prev_filtered_history}}
    }
    elsif ( any { $_ =~ /^\Q$current\E/i && $_ ne $current } @{$self->{history}} ) {
        @history = grep { $_ =~ /^\Q$current\E/i && $_ ne $current } @{$self->{history}};
        @{$self->{i}{prev_filtered_history}} = @history;
        $self->{i}{history_idx} = @history;
    }
    else {
        @history = @{$self->{history}};
        if ( @{$self->{i}{prev_filtered_history}//[]} ) {
            $self->{i}{prev_filtered_history} = [];
            $self->{i}{history_idx} = @history;
        };
        if ( ! defined $self->{i}{history_idx} ) {
            $self->{i}{history_idx} = @history;
        }
    }
    if ( ! defined $self->{i}{history_idx} ) {
        $self->{i}{history_idx} = @history;
        # first up-key pressed -> last history entry and not curr_string
    }
    push @history, $self->{i}{curr_string} // '';
    if ( $history_up ) {
        if ( $self->{i}{history_idx} == 0 ) {
            $self->{i}{beep} = 1;
        }
        else {
            --$self->{i}{history_idx};
        }
    }
    else {
        if ( $self->{i}{history_idx} >= $#history ) {
            $self->{i}{beep} = 1;
        }
        else {
            ++$self->{i}{history_idx};
        }
    }
    my $list = [ [ $prompt, $history[$self->{i}{history_idx}] ] ];
    $m = $self->__string_and_pos( $list );
    return $m;
}


sub __prepare_prompt {
    my ( $self, $term_w, $prompt ) = @_;
    if ( ! length $prompt ) {
        $self->{i}{prompt} = '';
        $self->{i}{max_key_w} = 0;
        return;
    }
    my @color;
    if ( $self->{color} ) {
        $prompt =~ s/\x{feff}//g;
        $prompt =~ s/(\e\[[\d;]*m)/push( @color, $1 ) && "\x{feff}"/ge;
    }
    $prompt = $self->__sanitized_string( $prompt );
    $self->{i}{max_key_w} = print_columns( $prompt );
    if ( $self->{i}{max_key_w} > $term_w / 3 ) {
        $self->{i}{max_key_w} = int( $term_w / 3 );
        $prompt = $self->__unicode_trim( $prompt, $self->{i}{max_key_w} );
    }
    if ( @color ) {
        $prompt =~ s/\x{feff}/shift @color/ge;
        $prompt .= normal();
    }
    $self->{i}{prompt} = $prompt;
}


sub __init_readline {
    my ( $self, $term_w, $prompt ) = @_;
    if ( $self->{clear_screen} == 0 ) {
        print "\r" . clear_to_end_of_screen();
    }
    elsif ( $self->{clear_screen} == 1 ) {
        print clear_screen();
    }
    if ( length $self->{info} ) {
        my $info_w = $term_w;
        if ( $^O ne 'MSWin32' && $^O ne 'cygwin' ) {
            $info_w += WIDTH_CURSOR;
        }
        my @info = line_fold( $self->{info}, $info_w, { color => $self->{color}, join => 0 } );
        $self->{i}{info_row_count} = @info;
        if ( $self->{clear_screen} == 2 ) {
            print clear_to_end_of_line();
            print join( "\n" . clear_to_end_of_line(), @info ), "\n";
        }
        else {
            print join( "\n", @info ), "\n";
        }
    }
    else {
        $self->{i}{info_row_count} = 0;
    }
    $self->{i}{seps}[0] = $self->{i}{sep} = ''; # in __readline
    $self->{i}{curr_row} = 0; # in __readlline and __string_and_pos
    $self->{i}{pre_text_row_count} = 0;
    $self->{i}{post_text_row_count} = 0;
    $self->__prepare_prompt( $term_w, $prompt );
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
        $self->__available_width( $term_w );
    }
    $self->__threshold_width();
    if ( $self->{page} == 2 ) {
        $self->{i}{page_count} = 1;
        $self->{i}{print_footer} = 1;
        $self->__prepare_footer_fmt( $term_w );
        $self->__print_footer();
    }
    else {
        $self->{i}{print_footer} = 0;
    }
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
        my $caller = 'readline';
        validate_options( _valid_options( $caller ), $opt, $caller );
        for my $key ( keys %$opt ) {
            $self->{$key} = $opt->{$key} if defined $opt->{$key};
        }
    }
    $self->__modify_readline_options();
    if ( $^O eq "MSWin32" ) {
        print $self->{codepage_mapping} ? "\e(K" : "\e(U";
    }
    local $| = 1;
    local $SIG{INT} = sub {
        $self->__reset(); #
        print "^C\n";
        exit;
    };
    $self->__init_term();
    my $term_w = get_term_width();
    my $m = $self->__init_readline( $term_w, $prompt );
    my $big_step = 10;
    my $up_before = 0;

    CHAR: while ( 1 ) {
        if ( $self->{i}{beep} ) {
            print bell();
            $self->{i}{beep} = 0;
        }
        my $tmp_term_w = get_term_width();
        if ( $tmp_term_w != $term_w ) {
            $term_w = $tmp_term_w;
            $self->{default} = join( '', map { $_->[0] } @{$m->{str}} );
            $m = $self->__init_readline( $term_w, $prompt );
        }
        if ( $self->{show_context} ) {
            if ( ( $self->{i}{pre_text_row_count} + 2 + $self->{i}{post_text_row_count} ) >= get_term_height() ) { ##
                $self->{show_context} = 0;
                $up_before = 0;
                $self->{default} = join( '', map { $_->[0] } @{$m->{str}} );
                $m = $self->__init_readline( $term_w, $prompt );
            }
            $self->{i}{context_count} = $self->{i}{pre_text_row_count} + $self->{i}{post_text_row_count};
        }
        if ( $up_before ) {
            print up( $up_before );
        }
        my $p = "\r" . clear_to_end_of_line();
        if ( $self->{i}{prev_context_count} || $self->{i}{context_count} ) {
            my $count = $self->{i}{prev_context_count} // 0 > $self->{i}{context_count} // 0
                            ? $self->{i}{prev_context_count}
                            : $self->{i}{context_count};
            ++$count; # Home
            $p .= ( down( 1 ) . clear_to_end_of_line() ) x $count;
            $p .= up( $count );
        }
        print $p;
        $self->__before_readline( $m, $term_w );
        $up_before = $self->{i}{pre_text_row_count};
        if ( $self->{hide_cursor} ) {
            print hide_cursor();
        }
        if ( length $self->{i}{pre_text} ) {
            print $self->{i}{pre_text}, "\n";
        }

        $self->__after_readline( $m, $term_w );
        if ( length $self->{i}{post_text} ) {
            print "\n" . $self->{i}{post_text};
        }
        if ( $self->{i}{post_text_row_count} ) {
            print up( $self->{i}{post_text_row_count} );
        }
        $self->{i}{prev_context_count} = $self->{i}{context_count};
        $self->__print_readline( $m );
        my $char = $self->{plugin}->__get_key_OS();
        if ( ! defined $char ) {
            $self->__reset();
            warn "EOT: $!";
            return;
        }
        # reset $m->{avail_w} to default:
        $m->{avail_w} = $self->{i}{avail_w};
        $self->__threshold_char_count( $m );
        if    ( $char == NEXT_get_key                       ) { next CHAR }
        elsif ( $char == KEY_TAB                            ) { next CHAR }
        elsif ( $char == VK_PAGE_UP   || $char == CONTROL_P ) { for ( 1 .. $big_step ) { last if $m->{pos} == 0; $self->__left( $m  ) } }
        elsif ( $char == VK_PAGE_DOWN || $char == CONTROL_N ) { for ( 1 .. $big_step ) { last if $m->{pos} == @{$m->{str}}; $self->__right( $m ) } }
        elsif (                          $char == CONTROL_U ) { $self->__ctrl_u( $m ) }
        elsif (                          $char == CONTROL_K ) { $self->__ctrl_k( $m ) }
        elsif ( $char == VK_RIGHT     || $char == CONTROL_F ) { $self->__right(  $m ) }
        elsif ( $char == VK_LEFT      || $char == CONTROL_B ) { $self->__left(   $m ) }
        elsif ( $char == VK_END       || $char == CONTROL_E ) { $self->__end(    $m ) }
        elsif ( $char == VK_HOME      || $char == CONTROL_A ) { $self->__home(   $m ) }
        elsif ( $char == KEY_BSPACE   || $char == CONTROL_H ) { $self->__bspace( $m ) }
        elsif ( $char == VK_DELETE    || $char == CONTROL_D ) { $self->__delete( $m ) }
        elsif ( $char == VK_UP        || $char == CONTROL_S ) { $m = $self->__select_history( $m, $prompt, 1 ) }
        elsif ( $char == VK_DOWN      || $char == CONTROL_T ) { $m = $self->__select_history( $m, $prompt, 0 ) }
        elsif (                          $char == CONTROL_X ) {
            if ( @{$m->{str}} ) {
                my $list = [ [ $prompt, '' ] ];
                $m = $self->__string_and_pos( $list );
            }
            else {
                $self->__reset( $self->{i}{info_row_count} + $self->{i}{pre_text_row_count} );
                return;
            }
        }
        elsif ( $char == VK_INSERT ) {
            $self->{i}{beep} = 1;
        }
        elsif ( $char == LINE_FEED || $char == CARRIAGE_RETURN ) {
            # LINE_FEED == CONTROL_J, CARRIAGE_RETURN == CONTROL_M
            $self->__reset( $self->{i}{info_row_count} + $self->{i}{pre_text_row_count} );
            return join( '', map { $_->[0] } @{$m->{str}} );
        }
        else {
            $char = chr $char;
            utf8::upgrade $char;
            $self->__add_char( $m, $char );
        }
    }
}


1;

__END__


=pod

=encoding UTF-8

=head1 NAME

Term::Form::ReadLine - Read a line from STDIN.

=head1 VERSION

Version 0.554

=cut

=head1 SYNOPSIS

    # Object-oriented interface:

    use Term::Form::ReadLine;

    my $new = Term::Form::ReadLine->new();

    my $line = $new->readline( 'Prompt: ', { default => 'abc' } );

    # Functional interface:

    use Term::Form::ReadLine qw( read_line );

    my $line = read_line( 'Prompt: ', { default => 'abc' } );

=head1 DESCRIPTION

C<readline> reads a line from STDIN. As soon as C<Return> is pressed, C<readline> returns the read string without a
trailing newline character.

The output is removed after leaving the method, so the user can decide what remains on the screen.

=head2 Keys

C<BackSpace> or C<Ctrl-H>: Delete the character behind the cursor.

C<Delete> or C<Ctrl-D>: Delete  the  character at point.

C<Ctrl-U>: Delete the text backward from the cursor to the beginning of the line.

C<Ctrl-K>: Delete the text from the cursor to the end of the line.

C<Right-Arrow> or C<Ctrl-F>: Move forward a character.

C<Left-Arrow> or C<Ctrl-B>: Move back a character.

C<Home> or C<Ctrl-A>: Move to the start of the line.

C<End> or C<Ctrl-E>: Move to the end of the line.

C<Page-Up> or C<Ctrl-P>: Move back 10 characters.

C<Page-Down> or C<Ctrl-N>: Move forward 10 characters.

C<Ctrl-X>: If the input puffer is not empty, the input puffer is cleared, else C<Ctrl-X> returns nothing (undef).

C<Up-Arrow> or C<Ctrl-S>: History up.

C<Down-Arrow> or C<Ctrl-T>: History down.

=head1 METHODS

=head2 new

The C<new> method returns a C<Term::Form::ReadLine> object.

    my $new = Term::Form::ReadLine->new();

To set the different options it can be passed a reference to a hash as an optional argument.

=head2 readline

C<readline> reads a line from STDIN.

    $line = $new->readline( $prompt, \%options );

The fist argument is the prompt string.

The optional second argument is the default string (see option I<default>) if it is not a reference. If the second
argument is a hash-reference, the hash is used to set the different options. The hash-keys/options are:

=head3 clear_screen

0 - clears from the current position to the end of screen

1 - clears the entire screen

2 - clears only the rows used by readline

default: C<0>

=head3 codepage_mapping

This option has only meaning if the operating system is MSWin32.

If the OS is MSWin32, L<Win32::Console::ANSI> is used. By default C<Win32::Console::ANSI> converts the characters from
Windows code page to DOS code page (the so-called ANSI to OEM conversion). This conversation is disabled by default in
C<Term::Choose>, but one can enable it by setting this option.

0 - disables the automatic codepage mapping (default)

1 - keeps the automatic codepage mapping

default: C<0>

=head3 color

Enables the support for color and text formatting escape sequences for the prompt string and the I<info> text.

0 - off

1 - on

default: C<0>

=head3 default

Set a initial value of input.

=head3 hide_cursor

0 - disabled

1 - enabled

default: C<1>

=head3 history

This option allows one to pass a C<readline> history as a reference to an array.

If the entered string matches the beginning of one or more history entries, only these matched history entries are
offered.

See L</Keys> for how to move through the history.

default: empty

=head3 info

Expects as is value a string. If set, the string is printed on top of the output of C<readline>.

=head3 no_echo

0 - the input is echoed on the screen.

1 - "C<*>" are displayed instead of the characters.

2 - no output is shown apart from the prompt string.

default: C<0>

=head3 show_context

Display the input that does not fit into the "readline" before or after the "readline".

0 - disabled

1 - enabled

default: C<0>

=head1 REQUIREMENTS

=head2 Perl version

Requires Perl version 5.10.0 or greater.

=head2 Terminal

It is required a terminal which uses a monospaced font.

Unless the OS is MSWin32 the terminal has to understand ANSI escape sequences.

=head2 Encoding layer

It is required to use appropriate I/O encoding layers. If the encoding layer for STDIN doesn't match the terminal's
character set, C<readline> will break if a non ascii character is entered.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::Form::ReadLine

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 CREDITS

Thanks to the L<Perl-Community.de|http://www.perl-community.de> and the people form
L<stackoverflow|http://stackoverflow.com> for the help.

=head1 LICENSE AND COPYRIGHT

Copyright 2022-2023 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
