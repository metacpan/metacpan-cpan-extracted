package Term::Choose::Util;

use warnings;
use strict;
use 5.008003;

our $VERSION = '0.052';
use Exporter 'import';
our @EXPORT_OK = qw( choose_a_dir choose_a_file choose_dirs choose_a_number choose_a_subset settings_menu choose_multi
                     insert_sep length_longest print_hash term_size term_width unicode_sprintf unicode_trim );

use Cwd                   qw( realpath );
use Encode                qw( decode encode );
use File::Basename        qw( dirname );
use File::Spec::Functions qw( catdir catfile );
use List::Util            qw( sum );

use Encode::Locale         qw();
use File::HomeDir          qw();
use Term::Choose           qw( choose );
use Term::Choose::LineFold qw( line_fold cut_to_printwidth print_columns );
use Term::ReadKey          qw( GetTerminalSize ReadKey ReadMode );

use if $^O eq 'MSWin32', 'Win32::Console';
use if $^O eq 'MSWin32', 'Win32::Console::ANSI';



sub choose_multi {
    settings_menu( @_ );
}


sub stringify_array { join( ', ', map { "\"$_\"" } @_ ) }

sub choose_dirs {
    my ( $opt ) = @_;
    my ( $o, $start_dir ) = _prepare_opt_choose_path( $opt );
    my $new         = [];
    my $dir         = realpath $start_dir;
    my $previous    = $dir;
    my @pre         = ( undef, $o->{confirm}, $o->{add_dir}, $o->{up} );
    my $default_idx = $o->{enchanted}  ? $#pre : 0;

    while ( 1 ) {
        my ( $dh, @dirs );
        if ( ! eval {
            opendir( $dh, $dir ) or die $!;
            1 }
        ) {
            print "$@";
            choose( [ 'Press Enter:' ], { prompt => '' } );
            $dir = dirname $dir;
            next;
        }
        while ( my $file = readdir $dh ) {
            next if $file =~ /^\.\.?\z/;
            next if $file =~ /^\./ && ! $o->{show_hidden};
            push @dirs, decode( 'locale_fs', $file ) if -d catdir $dir, $file;
        }
        closedir $dh;

        my $prompt;
        $prompt .= $o->{prompt} . "\n" if $o->{prompt};
        my $len_key;
        if ( defined $o->{current} ) {
            $len_key = 9;
            $prompt .= sprintf "Current: %s\n",   stringify_array( @{$o->{current}} );
            $prompt .= sprintf "    New: %s\n", stringify_array( @$new );
        }
        else {
            $len_key = 5;
            $prompt .= sprintf "New: %s\n", stringify_array( @$new );
        }
        my $key_cwd = '>';
        $prompt  = line_fold( $prompt,                                     term_width(), '' , ' ' x $len_key );
        $prompt .= "\n";
        $prompt .= line_fold( $key_cwd . decode( 'locale_fs', $previous ), term_width(), '' , ' ' x length $key_cwd );
        $prompt .= "\n";
        $prompt .= $o->{prompt} if $o->{prompt}; ####
        my $choice = choose(
            [ @pre, sort( @dirs ) ],
            { prompt => $prompt, undef => $o->{back}, default => $default_idx, mouse => $o->{mouse},
              justify => $o->{justify}, layout => $o->{layout}, order => $o->{order}, clear_screen => $o->{clear_screen} }
        );
        if ( ! defined $choice ) {
            return if ! @$new;
            $new = [];
            next;
        }
        $default_idx = $o->{enchanted}  ? $#pre : 0;
        if ( $choice eq $o->{confirm} ) {
            return $new;
        }
        elsif ( $choice eq $o->{add_dir} ) {
            if ( $o->{decoded} ) {
                push @$new, decode( 'locale_fs', $previous );
            }
            else {
                push @$new, $previous;
            }
            $dir = dirname $dir;
            $default_idx = 0 if $previous eq $dir;
            $previous = $dir;
            next;
        }
        $dir = $choice eq $o->{up} ? dirname( $dir ) : catdir( $dir, encode 'locale_fs', $choice );
        $default_idx = 0 if $previous eq $dir;
        $previous = $dir;
    }
}

sub _prepare_opt_choose_path {
    my ( $opt ) = @_;
    $opt = {} if ! defined $opt;
    my $dir = encode( 'locale_fs', $opt->{dir} );
    if ( defined $dir && ! -d $dir ) {
        my $prompt = "Could not find the directory \"$dir\". Falling back to the home directory.";
        choose( [ 'Press ENTER to continue' ], { prompt => $prompt } );
        $dir = File::HomeDir->my_home();
    }
    $dir = File::HomeDir->my_home()                  if ! defined $dir;
    die "Could not find the home directory \"$dir\"" if ! -d $dir;
    my $defaults =  {
        show_hidden  => 1,
        clear_screen => 1,
        mouse        => 0,
        layout       => 1,
        order        => 1,
        justify      => 0,
        enchanted    => 1,
        confirm      => ' = ',
        add_dir      => ' . ',
        up           => ' .. ',
        file         => ' >F ',
        back         => ' < ',
        decoded      => 1,
        current      => undef,
        prompt       => undef,
    };
    #for my $opt ( keys %$opt ) {
    #    die "$opt: invalid option!" if ! exists $defaults->{$opt};
    #}
    my $o = {};
    for my $key ( keys %$defaults ) {
        $o->{$key} = defined $opt->{$key} ? $opt->{$key} : $defaults->{$key};
    }
    return $o, $dir;
}


sub prepare_string { '"' . decode( 'locale_fs', shift ) . '"' }


sub choose_a_dir {
    my ( $opt ) = @_;
    return _choose_a_path( $opt, 0 );
}

sub choose_a_file {
    my ( $opt ) = @_;
    return _choose_a_path( $opt, 1 );
}

sub _choose_a_path {
    my ( $opt, $a_file ) = @_;
    my ( $o, $dir ) = _prepare_opt_choose_path( $opt );
    my @pre = ( undef, ( $a_file ? $o->{file} : $o->{confirm} ), $o->{up} );
    my $default_idx = $o->{enchanted}  ? 2 : 0;
    my $curr     = encode 'locale_fs', $o->{current};
    my $previous = $dir;
    my $wildcard = '*';

    while ( 1 ) {
        my ( $dh, @dirs );
        if ( ! eval {
            opendir( $dh, $dir ) or die $!;
            1 }
        ) {
            print "$@";
            choose( [ 'Press Enter:' ], { prompt => '' } );
            $dir = dirname $dir;
            next;
        }
        while ( my $file = readdir $dh ) {
            next if $file =~ /^\.\.?\z/;
            next if $file =~ /^\./ && ! $o->{show_hidden};
            push @dirs, decode( 'locale_fs', $file ) if -d catdir $dir, $file;
        }
        closedir $dh;
        my $prompt = '';
        if ( $a_file ) {
            if ( $curr ) {
                $prompt .= sprintf "Current file: %s\n", prepare_string( $curr );
                $prompt .= sprintf "    New file: %s\n", prepare_string( catfile $dir, $wildcard );
            }
            else {
                $prompt .= sprintf "New file: %s\n", prepare_string( catfile $dir, $wildcard );
            }
        }
        else {
            if ( $curr ) {
                $prompt .= sprintf "Current dir: %s\n", prepare_string( $curr );
                $prompt .= sprintf "    New dir: %s\n", prepare_string( $dir );
            }
            else {
                $prompt .= sprintf "New dir: %s\n", prepare_string( $dir );
            }
        }
        $prompt .= $o->{prompt} if $o->{prompt};
        my $choice = choose(
            [ @pre, sort( @dirs ) ],
            { prompt => $prompt, undef => $o->{back}, default => $default_idx, mouse => $o->{mouse},
              justify => $o->{justify}, layout => $o->{layout}, order => $o->{order}, clear_screen => $o->{clear_screen} }
        );
        if ( ! defined $choice ) {
            return;
        }
        elsif ( $choice eq $o->{confirm} ) {
            return decode 'locale_fs', $previous if $o->{decoded};
            return $previous;
        }
        elsif ( $choice eq $o->{file} ) {
            my $file = _a_file( $o, $dir, $curr, $wildcard );
            next if ! length $file;
            return decode 'locale_fs', $file if $o->{decoded};
            return $file;
        }
        $choice = encode( 'locale_fs', $choice );
        if ( $choice eq $o->{up} ) {
            $dir = dirname $dir;
        }
        else {
            $dir = catdir $dir, $choice;
        }
        if ( $previous eq $dir ) {
            $default_idx = 0;
        }
        else {
            $default_idx = $o->{enchanted}  ? 2 : 0;
        }
        $previous = $dir;
    }
}

sub _a_file {
    my ( $o, $dir, $curr, $wildcard ) = @_;
    my $previous;

    while ( 1 ) {
        my ( $dh, @files );
        if ( ! eval {
            opendir( $dh, $dir ) or die $!;
            1 }
        ) {
            print "$@";
            choose( [ 'Press Enter:' ], { prompt => '' } );
            return;
        }
        while ( my $file = readdir $dh ) {
            next if $file =~ /^\.\.?\z/;
            next if $file =~ /^\./ && ! $o->{show_hidden};
            push @files, decode( 'locale_fs', $file ) if -f catdir $dir, $file;
        }
        closedir $dh;
        if ( ! @files ) {
            my $prompt =  sprintf "No files in %s.", prepare_string( $dir );
            choose( [ ' < ' ], { prompt => $prompt } );
            return;
        }
        my $prompt = '';
        if ( $curr ) {
            $prompt .= sprintf "Current file: %s\n", prepare_string( $curr );
            $prompt .= sprintf "    New file: %s\n", prepare_string( catfile $dir, $previous // $wildcard );
        }
        else {
            $prompt .= sprintf "New file: %s\n", prepare_string( catfile $dir, $previous // $wildcard );
        }
        $prompt .= "\n" . $o->{prompt} if $o->{prompt};
        my @pre = ( undef, $o->{confirm} );
        my $choice = choose(
            [ @pre, sort( @files ) ],
            { prompt => $prompt, undef => $o->{back}, mouse => $o->{mouse}, justify => $o->{justify},
            layout => $o->{layout}, order => $o->{order}, clear_screen => $o->{clear_screen} }
        );
        if ( ! length $choice ) {
            return;
        }
        elsif ( $choice eq $o->{confirm} ) {
            return if ! length $previous;
            return catfile $dir, encode 'locale_fs', $previous;
        }
        else {
            $previous = $choice;
        }
    }
}


sub choose_a_number {
    my ( $digits, $opt ) = @_;
    $opt = {} if ! defined $opt;
    #                $opt->{current}
    my $thsd_sep   = defined $opt->{thsd_sep}     ? $opt->{thsd_sep}     : ',';
    my $name       = defined $opt->{name}         ? $opt->{name}         : '';
    my $clear      = defined $opt->{clear_screen} ? $opt->{clear_screen} : 1;
    my $mouse      = defined $opt->{mouse}        ? $opt->{mouse}        : 0;
    #-------------------------------------------#
    my $back       = defined $opt->{back}         ? $opt->{back}         : 'BACK';
    my $back_short = defined $opt->{back_short}   ? $opt->{back_short}   : '<<';
    my $confirm    = defined $opt->{confirm}      ? $opt->{confirm}      : 'CONFIRM';
    my $reset      = defined $opt->{reset}        ? $opt->{reset}        : 'reset';
    my $tab        = '  -  ';
    my $len_tab = print_columns( $tab ); #
    my $longest    = $digits;
    $longest += int( ( $digits - 1 ) / 3 ) if $thsd_sep ne '';
    my @choices_range = ();
    for my $di ( 0 .. $digits - 1 ) {
        my $begin = 1 . '0' x $di;
        $begin = 0 if $di == 0;
        $begin = insert_sep( $begin, $thsd_sep );
        ( my $end = $begin ) =~ s/^[01]/9/;
        unshift @choices_range, sprintf " %*s%s%*s", $longest, $begin, $tab, $longest, $end;
    }
    my $confirm_tmp = sprintf "%-*s", $longest * 2 + $len_tab, $confirm;
    my $back_tmp    = sprintf "%-*s", $longest * 2 + $len_tab, $back;
    if ( print_columns( "$choices_range[0]" ) > term_width() ) {
        @choices_range = ();
        for my $di ( 0 .. $digits - 1 ) {
            my $begin = 1 . '0' x $di;
            $begin = 0 if $di == 0;
            $begin = insert_sep( $begin, $thsd_sep );
            unshift @choices_range, sprintf "%*s", $longest, $begin;
        }
        $confirm_tmp = $confirm;
        $back_tmp    = $back;
    }
    my %numbers;
    my $result;
    my $undef = '--';

    NUMBER: while ( 1 ) {
        my $new_result = defined $result ? $result : $undef;
        my $prompt = '';
        if ( exists $opt->{current} ) {
            $opt->{current} = defined $opt->{current} ? insert_sep( $opt->{current}, $thsd_sep ) : $undef;
            $prompt .= sprintf "%s%*s\n",   'Current ' . $name . ': ', $longest, $opt->{current};
            $prompt .= sprintf "%s%*s\n\n", '    New ' . $name . ': ', $longest, $new_result;
        }
        else {
            $prompt = sprintf "%s%*s\n\n", $name . ': ', $longest, $new_result;
        }
        my @pre = ( undef, $confirm_tmp );
        # Choose
        my $range = choose(
            [ @pre, @choices_range ],
            { prompt => $prompt, layout => 3, justify => 1, mouse => $mouse,
              clear_screen => $clear, undef => $back_tmp }
        );
        if ( ! defined $range ) {
            if ( defined $result ) {
                $result = undef;
                next NUMBER;
            }
            else {
                return;
            }
        }
        if ( $range eq $confirm_tmp ) {
            return if ! defined $result;
            $result =~ s/\Q$thsd_sep\E//g if $thsd_sep ne '';
            return $result;
        }
        my $zeros = ( split /\s*-\s*/, $range )[0];
        $zeros =~ s/^\s*\d//;
        my $zeros_no_sep;
        if ( $thsd_sep eq '' ) {
            $zeros_no_sep = $zeros;
        }
        else {
            ( $zeros_no_sep = $zeros ) =~ s/\Q$thsd_sep\E//g;
        }
        my $count_zeros = length $zeros_no_sep;
        my @choices = $count_zeros ? map( $_ . $zeros, 1 .. 9 ) : ( 0 .. 9 );
        # Choose
        my $number = choose(
            [ undef, @choices, $reset ],
            { prompt => $prompt, layout => 1, justify => 2, order => 0,
              mouse => $mouse, clear_screen => $clear, undef => $back_short }
        );
        next if ! defined $number;
        if ( $number eq $reset ) {
            delete $numbers{$count_zeros};
        }
        else {
            $number =~ s/\Q$thsd_sep\E//g if $thsd_sep ne '';
            $numbers{$count_zeros} = $number;
        }
        $result = sum( @numbers{keys %numbers} );
        $result = insert_sep( $result, $thsd_sep );
    }
}


sub choose_a_subset {
    my ( $available, $opt ) = @_;
    $opt = {} if ! defined $opt;
    #             $opt->{current}
    my $index   = defined $opt->{index}        ? $opt->{index}        : 0;
    my $clear   = defined $opt->{clear_screen} ? $opt->{clear_screen} : 1;
    my $mouse   = defined $opt->{mouse}        ? $opt->{mouse}        : 0;
    my $layout  = defined $opt->{layout}       ? $opt->{layout}       : 3;
    my $order   = defined $opt->{order}        ? $opt->{order}        : 1;
    my $prefix  = defined $opt->{prefix}       ? $opt->{prefix}       : ( $layout == 3 ? '- ' : '' );
    my $justify = defined $opt->{justify}      ? $opt->{justify}      : 0;
    my $prompt  = defined $opt->{prompt}       ? $opt->{prompt}       : 'Choose:';
    #--------------------------------------#
    my $confirm = defined $opt->{confirm}      ? $opt->{confirm}      : 'CONFIRM';
    my $back    = defined $opt->{back}         ? $opt->{back}         : 'BACK';
    my $key_cur = defined $opt->{p_curr}       ? $opt->{p_curr}       : 'Current > ';
    my $key_new = defined $opt->{p_new}        ? $opt->{p_new}        : '    New > ';
    if ( $prefix ) {
        my $len_prefix = print_columns( "$prefix" );
        $confirm = ( ' ' x $len_prefix ) . $confirm;
        $back    = ( ' ' x $len_prefix ) . $back;
    }
    my $len_cur = print_columns( "$key_cur" );
    my $len_new = print_columns( "$key_new" );
    my $len_key = $len_cur > $len_new ? $len_cur : $len_new;
    my $new_idx = [];
    my $new     = [];

    while ( 1 ) {
        my $lines = '';
        $lines .= $key_cur . join( ', ', map { "\"$_\"" } @{$opt->{current}} ) . "\n"   if defined $opt->{current};
        $lines .= $key_new . join( ', ', map { "\"$_\"" } @$new )              . "\n\n";
        $lines .= $prompt;
        my @pre = ( undef, $confirm );
        my @avail_with_prefix = map { $prefix . $_ } @$available;
        # Choose
        my @idx = choose(
            [ @pre, @avail_with_prefix  ],
            { prompt => $lines, layout => $layout, mouse => $mouse, clear_screen => $clear, justify => $justify,
              index => 1, lf => [ 0, $len_key ], order => $order, no_spacebar => [ 0 .. $#pre ], undef => $back }
        );
        if ( ! defined $idx[0] || $idx[0] == 0 ) {
            if ( @$new_idx ) {
                $new_idx = [];
                $new     = [];
                next;
            }
            else {
                return;
            }
        }
        if ( $idx[0] == 1 ) {
            shift @idx;
            push @$new,     map { $available->[$_ - @pre] } @idx;
            push @$new_idx, map { $_ - @pre }               @idx;
            return $index ? $new_idx : $new;
        }
        push @$new,     map { $available->[$_ - @pre] } @idx;
        push @$new_idx, map { $_ - @pre }               @idx;
    }
}


sub settings_menu {
    my ( $menu, $val, $opt ) = @_;
    $opt = {} if ! defined $opt;
    my $prompt   = defined $opt->{prompt}       ? $opt->{prompt}       : 'Choose:';
    my $in_place = defined $opt->{in_place}     ? $opt->{in_place}     : 1;
    my $clear    = defined $opt->{clear_screen} ? $opt->{clear_screen} : 1;
    my $mouse    = defined $opt->{mouse}        ? $opt->{mouse}        : 0;
    #---------------------------------------#
    my $confirm = defined $opt->{confirm}       ? $opt->{confirm}      : 'CONFIRM';
    my $back    = defined $opt->{back}          ? $opt->{back}         : 'BACK';
    $back    = '  ' . $back;
    $confirm = '  ' . $confirm;
    my $longest = 0;
    my $tmp     = {};
    for my $sub ( @$menu ) {
        my ( $key, $prompt ) = @$sub;
        my $length = print_columns( "$prompt" );
        $longest = $length if $length > $longest;
        if ( ! defined $val->{$key} ) {
            $val->{$key} = 0;
        }
        $tmp->{$key} = $val->{$key};
    }
    my $count = 0;

    while ( 1 ) {
        my @print_keys;
        for my $sub ( @$menu ) {
            my ( $key, $prompt, $avail ) = @$sub;
            my $current = $avail->[$tmp->{$key}];
            push @print_keys, sprintf "%-*s [%s]", $longest, $prompt, $current;
        }
        my @pre = ( undef, $confirm );
        my $choices = [ @pre, @print_keys ];
        # Choose
        my $idx = choose(
            $choices,
            { prompt => $prompt, index => 1, layout => 3, justify => 0,
              mouse => $mouse, clear_screen => $clear, undef => $back }
        );
        return if ! defined $idx;
        my $choice = $choices->[$idx];
        return if ! defined $choice;
        if ( $choice eq $confirm ) {
            my $change = 0;
            if ( $count ) {
                for my $sub ( @$menu ) {
                    my $key = $sub->[0];
                    next if $val->{$key} == $tmp->{$key};
                    if ( $in_place ) {
                        $val->{$key} = $tmp->{$key};
                    }
                    $change++;
                }
            }
            return if ! $change;
            return 1 if $in_place;
            return $tmp;
        }
        my $key   = $menu->[$idx-@pre][0];
        my $avail = $menu->[$idx-@pre][2];
        $tmp->{$key}++;
        $tmp->{$key} = 0 if $tmp->{$key} == @$avail;
        $count++;
    }
}


sub insert_sep {
    my ( $number, $separator ) = @_;
    return if ! defined $number;
    $separator = ',' if ! defined $separator;
    return $number if $number =~ /\Q$separator\E/;
    $number =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1$separator/g;
    # http://perldoc.perl.org/perlfaq5.html#How-can-I-output-my-numbers-with-commas-added?
    return $number;
}


sub length_longest {
    my ( $list ) = @_;
    my $len = [];
    my $longest = 0;
    for my $i ( 0 .. $#$list ) {
        $len->[$i] = print_columns( "$list->[$i]" );
        $longest = $len->[$i] if $len->[$i] > $longest;
    }
    return wantarray ? ( $longest, $len ) : $longest;
}


sub print_hash {
    my ( $hash, $opt ) = @_;
    $opt = {} if ! defined $opt;
    my $left_margin  = defined $opt->{left_margin}  ? $opt->{left_margin}  : 1;
    my $right_margin = defined $opt->{right_margin} ? $opt->{right_margin} : 2;
    my $keys         = defined $opt->{keys}         ? $opt->{keys}         : [ sort keys %$hash ];
    my $len_key      = defined $opt->{len_key}      ? $opt->{len_key}      : length_longest( $keys );
    my $maxcols      = $opt->{maxcols};
    my $clear        = defined $opt->{clear_screen} ? $opt->{clear_screen} : 1;
    my $mouse        = defined $opt->{mouse}        ? $opt->{mouse}        : 0;
    my $prompt       = defined $opt->{prompt}       ? $opt->{prompt}       : ( defined $opt->{preface} ? '' : 'Close with ENTER' );
    my $preface      = $opt->{preface};
    #-----------------------------------------------------------------#
    my $line_fold = defined $opt->{lf} ? $opt->{lf} : { Charset => 'utf-8', Newline => "\n", OutputCharset => '_UNICODE_', Urgent => 'FORCE' };
    my $term_width = term_width();
    if ( ! $maxcols || $maxcols > $term_width  ) {
        $maxcols = $term_width - $right_margin;
    }
    $len_key += $left_margin;
    my $sep = ' : ';
    my $len_sep = print_columns( "$sep" );
    if ( $len_key + $len_sep > int( $maxcols / 3 * 2 ) ) {
        $len_key = int( $maxcols / 3 * 2 ) - $len_sep;
    }
    my @vals = ();
    if ( defined $preface ) {
        for my $line ( split "\n", $preface ) {
            push @vals, split "\n", line_fold( $line, $maxcols, '', '' );
        }
    }
    for my $key ( @$keys ) {
        next if ! exists $hash->{$key};
        my $val;
        if ( ! defined $hash->{$key} ) {
            $val = '';
        }
        elsif ( ref $hash->{$key} eq 'ARRAY' ) {
            $val = '[ ' . join( ', ', map { defined $_ ? "\"$_\"" : '' } @{$hash->{$key}} ) . ' ]';
        }
        else {
            $val = $hash->{$key};
        }
        my $pr_key = sprintf "%*.*s%*s", $len_key, $len_key, $key, $len_sep, $sep;
        my $text = line_fold( $pr_key . $val, $maxcols, '' , ' ' x ( $len_key + $len_sep ) );
        $text =~ s/\n+\z//;
        for my $val ( split /\n+/, $text ) {
            push @vals, $val;
        }
    }
    return join "\n", @vals if defined wantarray;
    choose(
        [ @vals ],
        { prompt => $prompt, layout => 3, justify => 0, mouse => $mouse, clear_screen => $clear }
    );
}


sub term_size {
    my ( $handle_out ) = defined $_[0] ? $_[0] : \*STDOUT;
    if ( $^O eq 'MSWin32' ) {
        my ( $width, $height ) = Win32::Console->new()->Size();
        return $width - 1, $height;
    }
    return( ( GetTerminalSize( $handle_out ) )[ 0, 1 ] );
}


sub term_width {
    return( ( term_size( $_[0] ) )[0] );
}



sub unicode_sprintf {
    my ( $unicode, $avail_width, $right_justify ) = @_;
    my $colwidth = print_columns( "$unicode" );
    if ( $colwidth > $avail_width ) {
        return cut_to_printwidth( $unicode, $avail_width );
    }
    elsif ( $colwidth < $avail_width ) {
        if ( $right_justify ) {
            $unicode = " " x ( $avail_width - $colwidth ) . $unicode;
        }
        else {
            $unicode = $unicode . " " x ( $avail_width - $colwidth );
        }
    }
    return $unicode;
}



sub unicode_trim {
    my ( $unicode, $len ) = @_;
    return '' if $len <= 0;
    cut_to_printwidth( $unicode, $len );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Choose::Util - CLI related functions.

=head1 VERSION

Version 0.052

=cut

=head1 SYNOPSIS

See L</SUBROUTINES>.

=head1 DESCRIPTION

This module provides some CLI related functions required by L<App::DBBrowser>, L<App::YTDL> and L<Term::TablePrint>.

=head1 EXPORT

Nothing by default.

=head1 SUBROUTINES

Values in brackets are default values.

Unknown option names are ignored.

=head2 choose_a_dir

    $chosen_directory = choose_a_dir( { layout => 1, ... } )

With C<choose_a_dir> the user can browse through the directory tree (as far as the granted rights permit it) and
choose a directory which is returned.

To move around in the directory tree:

- select a directory and press C<Return> to enter in the selected directory.

- choose the "up"-menu-entry ("C< .. >") to move upwards.

To return the current working-directory as the chosen directory choose "C< = >".

The "back"-menu-entry ("C< < >") causes C<choose_a_dir> to return nothing.

As an argument it can be passed a reference to a hash. With this hash the user can set the different options:

=over

=item

clear_screen

If enabled, the screen is cleared before the output.

Values: 0,[1].

=item

current

If set, C<choose_a_dir> shows I<current> as the current directory.

=item

decoded

If enabled, the directory name is returned decoded with C<locale_fs> form L<Encode::Locale>.

=item

dir

Set the starting point directory. Defaults to the home directory or the current working directory if the home directory
cannot be found.

=item

enchanted

If set to 1, the default cursor position is on the "up" menu entry. If the directory name remains the same after an
user input, the default cursor position changes to "back".

If set to 0, the default cursor position is on the "back" menu entry.

Values: 0,[1].

=item

justify

Elements in columns are left justified if set to 0, right justified if set to 1 and centered if set to 2.

Values: [0],1,2.

=item

layout

See the option I<layout> in L<Term::Choose>

Values: 0,[1],2,3.

=item

mouse

See the option I<mouse> in L<Term::Choose>

Values: [0],1,2,3,4.

=item

order

If set to 1, the items are ordered vertically else they are ordered horizontally.

This option has no meaning if I<layout> is set to 3.

Values: 0,[1].

=item

show_hidden

If enabled, hidden directories are added to the available directories.

Values: 0,[1].

=back

=head2 choose_a_file

    $chosen_file = choose_a_file( { layout => 1, ... } )

Browse the directory tree the same way as described for C<choose_a_dir>. Select "C<E<gt>F>" to get the files of the
current directory. To return the chosen file select "=".

The options are passed as a reference to a hash. See L</choose_a_dir> for the different options. C<choose_a_file> has no
option I<current>.

=head2 choose_dirs

    $chosen_directories = choose_dirs( { layout => 1, ... } )

C<choose_dirs> is similar to C<choose_a_dir> but it is possible to return multiple directories.

Different to C<choose_a_dir>:

"C< . >" adds the current directory to the list of chosen directories.

To return the chosen list of directories (as an array reference) select the "confirm"-menu-entry "C< = >".

The "back"-menu-entry ( "C< < >" ) resets the list of chosen directories if any. If the list of chosen directories is
empty, "C< < >" causes C<choose_dirs> to return nothing.

C<choose_dirs> uses the same option as C<choose_a_dir>. The option I<current> expects as its value a reference to an
array (directories shown as the current directories).

=over

=back

=head2 choose_a_number

    for ( 1 .. 5 ) {
        $current = $new
        $new = choose_a_number( 5, { current => $current, name => 'Testnumber' }  );
    }

This function lets you choose/compose a number (unsigned integer) which is returned.

The fist argument - "digits" - is an integer and determines the range of the available numbers. For example setting the
first argument to 6 would offer a range from 0 to 999999.

The second and optional argument is a reference to a hash with these keys (options):

=over

=item

clear_screen

If enabled, the screen is cleared before the output.

Values: 0,[1].

=item

current

The current value. If set, two prompt lines are displayed - one for the current number and one for the new number.

=item

name

Sets the name of the number seen in the prompt line.

Default: empty string ("");

=item

mouse

See the option I<mouse> in L<Term::Choose>

Values: [0],1,2,3,4.

=item

thsd_sep

Sets the thousands separator.

Default: comma (,).

=back

=head2 choose_a_subset

    $subset = choose_a_subset( \@available_items, { current => \@current_subset } )

C<choose_a_subset> lets you choose a subset from a list.

As a first argument it is required a reference to an array which provides the available list.

The optional second argument is a hash reference. The following options are available:

=over

=item

clear_screen

If enabled, the screen is cleared before the output.

Values: 0,[1].

=item

current

This option expects as its value the current subset of the available list (a reference to an array). If set, two prompt
lines are displayed - one for the current subset and one for the new subset. Even if the option I<index> is true the
passed current subset is made of values and not of indexes.

The subset is returned as an array reference.

=item

index

If true, the index positions in the available list of the made choices is returned.

=item

justify

Elements in columns are left justified if set to 0, right justified if set to 1 and centered if set to 2.

Values: [0],1,2.

=item

layout

See the option I<layout> in L<Term::Choose>.

Values: 0,1,2,[3].

=item

mouse

See the option I<mouse> in L<Term::Choose>

Values: [0],1,2,3,4.

=item

order

If set to 1, the items are ordered vertically else they are ordered horizontally.

This option has no meaning if I<layout> is set to 3.

Values: 0,[1].

=item

prefix

I<prefix> expects as its value a string. This string is put in front of the elements of the available list before
printing. The chosen elements are returned without this I<prefix>.

The default value is "- " if the I<layout> is 3 else the default is the empty string ("").

=item

prompt

The prompt line before the choices.

Defaults to "Choose:".

=back

=head2 choose_multi DEPRECATED

Use C<settings_menu> instead. C<choose_multi> will be removed.

=head2 settings_menu

    $tmp = settings_menu( $menu, $config, { in_place => 0 } )
    if ( defined $tmp ) {
        for my $key ( keys %$tmp ) {
            $config->{$key} = $tmp->{$key};
        }
    }

The first argument is a reference to an array of arrays. These arrays have three elements:

=over

=item

the key/option name

=item

the prompt string

=item

an array reference with the available values of the key/option.

=back

The second argument is a hash reference:

=over

=item

the keys are the option names

=item

the values (C<0> if not defined) are the indexes of the current value of the respective key.

=back

    $menu = [
        [ 'enable_logging', "- Enable logging", [ 'NO', 'YES' ] ],
        [ 'case_sensitive', "- Case sensitive", [ 'NO', 'YES' ] ],
        ...
    ];

    $config = {
        'enable_logging' => 0,
        'case_sensitive' => 1,
        ...
    };

The optional third argument is a reference to a hash. The keys are

=over

=item

clear_screen

If enabled, the screen is cleared before the output.

Values: 0,[1].

=item

in_place

If enabled, the configuration hash (second argument) is edited in place.

Values: 0,[1].

=item

mouse

See the option I<mouse> in L<Term::Choose>

Values: [0],1,2,3,4.

=item

prompt

A prompt string used instead of the default prompt string.

=back

When C<settings_menu> is called, it displays for each array entry a row with the prompt string and the current value.
It is possible to scroll through the rows. If a row is selected, the set and displayed value changes to the next. If the
end of the list of the values is reached, it begins from the beginning of the list.

C<settings_menu> returns nothing if no changes are made. If the user has changed values and C<in_place> is set to 1,
C<settings_menu> modifies the hash passed as the second argument in place and returns 1. With the option C<in_place>
set to 0 C<settings_menu> does no in place modifications but modifies a copy of the configuration hash. A reference to
that modified copy is then returned.

=head2 insert_sep

    $integer = insert_sep( $number, $separator );

C<insert_sep> inserts thousands separators into the number and returns the number.

If the first argument is not defined, it is returned nothing.

If the first argument contains one or more characters equal to the thousands separator, C<insert_sep> returns the string
unchanged.

As a second argument it can be passed a character which will be used as the thousands separator.

The thousands separator defaults to the comma (C<,>).

=head2 length_longest

C<length_longest> expects as its argument a list of decoded strings passed a an array reference.

    $longest = length_longest( \@elements );

    ( $longest, $length ) = length_longest( \@elements );


In scalar context C<length_longest> returns the length of the longest string - in list context it returns a list where
the first item is the length of the longest string and the second is a reference to an array where the elements are the
length of the corresponding elements from the array (reference) passed as the argument.

I<Length> means here number of print columns as returned by the C<columns> method from  L<Unicode::GCString>.

=head2 print_hash

Prints a simple hash to STDOUT if called in void context. If not called in
void context, I<print_hash> returns the formatted hash as a string.

Nested hashes are not supported. If the hash has more keys than the terminal rows, the output is divided up on several
pages. The user can scroll through the single lines of the hash. In void context the output of the hash is closed when
the user presses C<Return>.

Empty strings are used instead of undefined hash values.

The first argument is the hash to be printed passed as a reference.

The optional second argument is also a hash reference which allows to set the following options:

=over

=item

clear_screen

If enabled, the screen is cleared before the output.

Values: 0,[1].

=item

keys

The keys which should be printed in the given order. The keys are passed with an array reference. Keys which don't exist
are ignored. If not set, I<keys> defaults to

    [ sort keys %$hash ]

=item

left_margin

I<left_margin> is added to I<len_key>. It defaults to 1.

=item

len_key

I<len_key> sets the available print width for the keys. The default value is the length (of print columns) of the
longest key.

If the remaining width for the values is less than one third of the total available width the keys are trimmed until the
available width for the values is at least one third of the total available width.

=item

maxcols

The maximum width of the output. If not set or set to 0 or set to a value higher than the terminal width, the maximum
terminal width is used instead.

Default: undefined.

=item

mouse

See the option I<mouse> in L<Term::Choose>

Values: [0],1,2,3,4.

=item

preface

With I<preface> it can be passed a string which is printed above the hash.

Default: undefined.

=item

prompt

Sets the prompt string

If I<preface> is defined, I<prompt> defaults to the empty string else the default is 'Close with ENTER'.

=item

right_margin

The I<right_margin> is subtracted from I<maxcols> if I<maxcols> is the maximum terminal width. The default value is
2.

=back

=head2 term_size

C<term_size> returns the current terminal width and the current terminal height.

    ( $width, $height ) = term_size()

If the OS is MSWin32, C<Size> from L<Win32::Console> is used to get the terminal width and the terminal height else
C<GetTerminalSize> form L<Term::ReadKey> is used.

On MSWin32 OS, if it is written to the last column on the screen the cursor goes to the first column of the next line.
To prevent this newline when writing to a Windows terminal C<term_size> subtracts 1 from the terminal width before
returning the width if the OS is MSWin32.

=head2 term_width

C<term_size> returns the current terminal width. See L</term_size> above.

=head2 unicode_sprintf

    $unicode = unicode_sprintf( $unicode, $available_width, $rightpad );

C<unicode_sprintf> expects 2 or 3 arguments: the first argument is a decoded string, the second argument is the
available width and the third and optional argument tells how to pad the string.

If the length of the string is greater than the available width, it is truncated to the available width. If the string
is equal to the available width, nothing is done with the string. If the string length is less than the available width,
C<unicode_sprintf> adds spaces to the string until the string length is equal to the available width. If the third
argument is set to a true value, the spaces are added at the beginning of the string else they are added at the end of
the string.

I<Length> or I<width> means here number of print columns as returned by the C<columns> method from L<Unicode::GCString>.

=head2 unicode_trim

    $unicode = unicode_trim( $unicode, $length )

The first argument is a decoded string, the second argument is the length.

If the string is longer than the passed length, it is trimmed to that length at the right site and returned else the
string is returned as it is.

I<Length> means here number of print columns as returned by the C<columns> method from  L<Unicode::GCString>.

=head1 REQUIREMENTS

=head2 Perl version

Requires Perl version 5.8.3 or greater.

=head2 Encoding layer

Ensure the encoding layer for STDOUT, STDERR and STDIN are set to the correct value.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::TablePrint

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
