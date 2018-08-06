package Term::Choose::Util;

use warnings;
use strict;
use 5.008003;

our $VERSION = '0.067';
use Exporter 'import';
our @EXPORT_OK = qw( choose_a_dir choose_a_file choose_dirs choose_a_number choose_a_subset settings_menu insert_sep
                     length_longest print_hash term_size term_width unicode_sprintf unicode_trim );

use Cwd                   qw( realpath );
use Encode                qw( decode encode );
use File::Basename        qw( dirname );
use File::Spec::Functions qw( catdir catfile );
use List::Util            qw( sum );

use Encode::Locale qw();
use File::HomeDir  qw();

use Term::Choose           qw( choose );
use Term::Choose::LineFold qw( line_fold cut_to_printwidth print_columns );


BEGIN {
    if ( $^O eq 'MSWin32' ) {
        require Term::Choose::Win32;
    }
    else {
        require Term::Choose::Linux;
    }
}

sub choose_dirs {
    my ( $opt ) = @_;
    my ( $o, $start_dir ) = _prepare_opt_choose_path( $opt );
    if ( ! defined $o->{prompt} ) {
        $o->{prompt} = ' ';
    }
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
        my @tmp;
        if ( length $o->{info} ) {
            push @tmp, $o->{info};
        }
        if ( ! defined $o->{name} ) {
            $o->{name} = 'New: ';
        }
        push @tmp, $o->{name} . join( ', ', map { s/ /\ /g; $_ } @$new );
        push @tmp, ' ++' . decode( 'locale_fs', "[$previous]" );
        if ( length $o->{prompt} ) {
            push @tmp, $o->{prompt};
        }
        my $lines = join( "\n", @tmp );
        my $choice = choose(
            [ @pre, sort( @dirs ) ],
            { prompt => $lines, undef => $o->{back}, default => $default_idx, mouse => $o->{mouse}, lf => [ 0, length $o->{name} ],
              justify => $o->{justify}, layout => $o->{layout}, order => $o->{order}, clear_screen => $o->{clear_screen}, hide_cursor => $o->{hide_cursor} }
        );
        if ( ! defined $choice ) {
            if ( @$new ) {
                pop @$new;
                $default_idx = 0;
                next;
            }
            return;
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
        choose( [ 'Press ENTER to continue' ], { prompt => $prompt, hide_cursor => $opt->{hide_cursor} } );
        $dir = File::HomeDir->my_home();
    }
    $dir = File::HomeDir->my_home()                  if ! defined $dir;
    die "Could not find the home directory \"$dir\"" if ! -d $dir;
    my $defaults =  {
        info         => '',
        name         => undef,
        prompt       => undef,
        show_hidden  => 1,
        clear_screen => 0,
        mouse        => 0,
        layout       => 1,
        order        => 1,
        justify      => 0,
        hide_cursor  => 1,
        enchanted    => 1,
        confirm      => ' OK ',
        add_dir      => ' ++ ',
        up           => ' .. ',
        choose_file => ' >F ',
        back         => ' << ',
        decoded      => 1,
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


sub _prepare_string { decode( 'locale_fs', shift ) }


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
    my @pre = ( undef, ( $a_file ? $o->{choose_file} : $o->{confirm} ), $o->{up} );
    my $default_idx = $o->{enchanted}  ? 2 : 0;
    my $previous = $dir;
    my $wildcard = ' ? ';

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
        my @tmp;
        if ( length $o->{info} ) {
            push @tmp, $o->{info};
        }
        if ( ! defined $o->{name} ) {
            $o->{name} = 'New: '; # a_file
        }
        if ( $a_file ) {
            push @tmp, $o->{name} . _prepare_string( catfile $dir, $wildcard );
        }
        else {
            push @tmp, $o->{name} . _prepare_string( $dir );
        }
        if ( defined $o->{prompt} && length $o->{prompt} ) {
            push @tmp, $o->{prompt};
        }
        my $lines = join( "\n", @tmp );
        my $choice = choose(
            [ @pre, sort( @dirs ) ],
            { prompt => $lines, undef => $o->{back}, default => $default_idx, mouse => $o->{mouse}, hide_cursor => $o->{hide_cursor},
              justify => $o->{justify}, layout => $o->{layout}, order => $o->{order}, clear_screen => $o->{clear_screen} }
        );
        if ( ! defined $choice ) {
            return;
        }
        elsif ( $choice eq $o->{confirm} ) {
            return decode 'locale_fs', $previous if $o->{decoded};
            return $previous;
        }
        elsif ( $choice eq $o->{choose_file} ) {
            my $file = _a_file( $o, $dir, $wildcard );
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
    my ( $o, $dir, $wildcard ) = @_;
    my $previous = '';

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
            my $prompt =  sprintf "No files in %s.", _prepare_string( $dir );
            choose( [ ' < ' ], { prompt => $prompt } );
            return;
        }
        my @tmp;
        if ( length $o->{info} ) {
            push @tmp, $o->{info};
        }
        if ( ! defined $o->{name} ) {
            $o->{name} = 'New: '; # file
        }
        push @tmp, $o->{name} . _prepare_string( catfile $dir, length $previous ? $previous : $wildcard );
        if ( defined $o->{prompt} && length $o->{prompt} ) {
            push @tmp, $o->{prompt};
        }
        my $lines = join( "\n", @tmp );
        my @pre = ( undef, $o->{confirm} );
        my $choice = choose(
            [ @pre, sort( @files ) ],
            { prompt => $lines, undef => $o->{back}, mouse => $o->{mouse}, justify => $o->{justify}, layout => $o->{layout},
              order => $o->{order}, clear_screen => $o->{clear_screen}, hide_cursor => $o->{hide_cursor} }
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
    if ( ref $digits ) {
        $opt = $digits;
        $digits = 7;
    }
    $opt = {} if ! defined $opt;
    my $info        = defined $opt->{info}         ? $opt->{info}         : '';
    my $prompt      = defined $opt->{prompt}       ? $opt->{prompt}       : '';
    my $name        =         $opt->{name};
    my $clear       = defined $opt->{clear_screen} ? $opt->{clear_screen} : 0;
    my $small       = defined $opt->{small_on_top} ? $opt->{small_on_top} : 0;
    my $thsd_sep    = defined $opt->{thsd_sep}     ? $opt->{thsd_sep}     : ',';
    my $mouse       = defined $opt->{mouse}        ? $opt->{mouse}        : 0;
    my $back        = defined $opt->{back}         ? $opt->{back}         : '<<'; #'BACK';
    my $confirm     = defined $opt->{confirm}      ? $opt->{confirm}      : 'OK'; #'CONFIRM';
    my $hide_cursor = defined $opt->{hide_cursor}  ? $opt->{hide_cursor}  : 1;
    #-------------------------------------------#
    my $back_short = defined $opt->{back_short}   ? $opt->{back_short}   : '<<';
    my $reset      = defined $opt->{reset}        ? $opt->{reset}        : 'reset';
    my $tab        = '  -  ';
    my $len_tab = print_columns( $tab ); #
    my $longest = $digits + int( ( $digits - 1 ) / 3 ) * length $thsd_sep;
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
    if ( ! defined $name ) {
        $name = '> ';
    }

    NUMBER: while ( 1 ) {
        my @tmp;
        if ( length $info ) {
            push @tmp, $info;
        }
        my $new_result = length $result ? $result : '';
        my $row = sprintf(  "${name}%*s", $longest, $new_result );
        if ( print_columns( $row ) > term_width() ) {
            $row = $new_result;
        }
        push @tmp, $row;
        if ( length $prompt ) {
            push @tmp, $prompt;
        }
        my $lines = join "\n", @tmp;
        my @pre = ( undef, $confirm_tmp );
        # Choose
        my $range = choose(
            $small ? [ @pre, reverse @choices_range ] : [ @pre, @choices_range ],
            { prompt => $lines, layout => 3, justify => 1, mouse => $mouse,
              clear_screen => $clear, undef => $back_tmp, hide_cursor => $hide_cursor }
        );
        if ( ! defined $range ) {
            if ( defined $result ) {
                $result = undef;
                %numbers = ();
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
            { prompt => $lines, layout => 1, justify => 2, order => 0, hide_cursor => $hide_cursor,
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
    my $info          = defined $opt->{info}          ? $opt->{info}          : '';
    my $name          =         $opt->{name};
    my $prompt        = defined $opt->{prompt}        ? $opt->{prompt}        : '';
    my $fmt_chosen    = defined $opt->{fmt_chosen}    ? $opt->{fmt_chosen}    : 0;
    my $remove_chosen = defined $opt->{remove_chosen} ? $opt->{remove_chosen} : 1;
    my $mark          =         $opt->{mark};
    my $index         = defined $opt->{index}         ? $opt->{index}         : 0;
    my $clear         = defined $opt->{clear_screen}  ? $opt->{clear_screen}  : 0;
    my $mouse         = defined $opt->{mouse}         ? $opt->{mouse}         : 0;
    my $layout        = defined $opt->{layout}        ? $opt->{layout}        : 3;
    my $order         = defined $opt->{order}         ? $opt->{order}         : 1;
    my $prefix        = defined $opt->{prefix}        ? $opt->{prefix}        : ( $layout == 3 ? '  ' : '' );
    my $justify       = defined $opt->{justify}       ? $opt->{justify}       : 0;
    my $confirm       = defined $opt->{confirm}       ? $opt->{confirm}       : ( ' ' x length $prefix ) . '-OK-';
    my $back          = defined $opt->{back}          ? $opt->{back}          : ( ' ' x length $prefix ) . ' << ';
    my $hide_cursor   = defined $opt->{hide_cursor}   ? $opt->{hide_cursor}   : 1;
    #--------------------------------------#
    #my $subseq_tab = 4;
    #my $subseq_tab = print_columns( $name || '  ' );
    my $new_idx =[];
    my $curr_avail = [ @$available ];
    my $bu = [];

    while ( 1 ) {
        my @tmp;
        if ( length $info ) {
            push @tmp, $info;
        }
        if ( $fmt_chosen == 0 ) {
            $name = '> ' if ! defined $name;
            push @tmp,  $name . join( ', ', map { defined $_ ? $_ : '' } @{$available}[@$new_idx] );
        }
        else {
            push @tmp, $name if defined $name;
            push @tmp, join( "\n", map { ( ' ' x length $prefix ) . ( defined $_ ? $_ : '' ) } @{$available}[@$new_idx] ) if @{$available}[@$new_idx]; # prefix
        }
        if ( length $prompt ) {
            push @tmp, $prompt;
        }
        my @pre = ( undef, $confirm );
        if ( defined $mark && @$mark ) {
            $mark = [ map { $_ + @pre } @$mark ];
        }
        my $lines = join "\n", @tmp;
        # Choose
        my @idx = choose(
            [ @pre, map { $prefix . ( defined $_ ? $_ : '' ) } @$curr_avail ],
            { prompt => $lines, layout => $layout, mouse => $mouse, clear_screen => $clear, justify => $justify,
              index => 1, lf => [ 0, 2 ], order => $order, meta_items => [ 0 .. $#pre ], undef => $back,
              hide_cursor => $hide_cursor, mark => $mark, include_highlighted => 2 }
        );
        $mark = undef;
        if ( ! defined $idx[0] || $idx[0] == 0 ) {
            if ( @$bu ) {
                ( $curr_avail, $new_idx ) = @{pop @$bu};
                next;
            }
            return;
        }
        push @$bu, [ [ @$curr_avail ], [ @$new_idx ] ];
        my $ok = $idx[0] == 1 ? shift @idx : 0;
        my @tmp_idx;
        for my $i ( reverse @idx ) {
            $i -= @pre;
            if ( $remove_chosen ) {
                splice( @$curr_avail, $i, 1 );
                for my $used_i ( sort { $a <=> $b } @$new_idx ) {
                    last if $used_i > $i;
                    ++$i;
                }
            }
            push @tmp_idx, $i;
        }
        push @$new_idx, reverse @tmp_idx;
        if ( $ok ) {
            return $index ? $new_idx : [ @{$available}[@$new_idx] ];
        }
    }
}


sub settings_menu {
    my ( $menu, $curr, $opt ) = @_;
    $opt = {} if ! defined $opt;
    die "'in_place' is no longer a valid option!'" if exists $opt->{in_place} && defined $opt->{in_place}; ###
    my $info        = defined $opt->{info}         ? $opt->{info}         : '';
    my $prompt      = defined $opt->{prompt}       ? $opt->{prompt}       : 'Choose:';
    my $clear       = defined $opt->{clear_screen} ? $opt->{clear_screen} : 0;
    my $mouse       = defined $opt->{mouse}        ? $opt->{mouse}        : 0;
    my $confirm     = defined $opt->{confirm}      ? $opt->{confirm}      : 'CONFIRM';
    my $back        = defined $opt->{back}         ? $opt->{back}         : 'BACK';
    my $hide_cursor = defined $opt->{hide_cursor}  ? $opt->{hide_cursor}  : 1;
    $back    = '  ' . $back;
    $confirm = '  ' . $confirm;
    my $longest = 0;
    my $new     = {};
    for my $sub ( @$menu ) {
        my ( $key, $name ) = @$sub;
        my $name_w = print_columns( "$name" );
        $longest      = $name_w if $name_w > $longest;
        $curr->{$key} = 0       if ! defined $curr->{$key};
        $new->{$key}  = $curr->{$key};
    }
    my @tmp;
    if ( length $info ) {
        push @tmp, $info;
    }
    if ( length $prompt ) {
        push @tmp, $prompt;
    }
    my $lines;
    if ( @tmp ) {
        $lines = join( "\n", @tmp );
    }

    while ( 1 ) {
        my @print_keys;
        for my $sub ( @$menu ) {
            my ( $key, $name, $values ) = @$sub;
            my $current = $values->[$new->{$key}];
            push @print_keys, sprintf "%-*s [%s]", $longest, $name, $current;
        }
        my @pre = ( undef, $confirm );
        my $choices = [ @pre, @print_keys ];
        # Choose
        my $idx = choose(
            $choices,
            { prompt => $lines, index => 1, layout => 3, justify => 0, mouse => $mouse,
              clear_screen => $clear, undef => $back, hide_cursor => $hide_cursor }
        );
        return if ! defined $idx;
        my $choice = $choices->[$idx];
        return if ! defined $choice;
        if ( $choice eq $confirm ) {
            my $change = 0;
            for my $sub ( @$menu ) {
                my $key = $sub->[0];
                next if $curr->{$key} == $new->{$key};
                $curr->{$key} = $new->{$key};
                $change++;
            }
            return $change; #
        }
        my $key    = $menu->[$idx-@pre][0];
        my $values = $menu->[$idx-@pre][2];
        $new->{$key}++;
        $new->{$key} = 0 if $new->{$key} == @$values;
    }
}



# Removed documentation 08.02.2018:

sub insert_sep {
    my ( $number, $separator ) = @_;
    return           if ! defined $number;
    return $number   if ! length $number;
    $separator = ',' if ! defined $separator;
    return $number   if $number =~ /\Q$separator\E/;
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
    my $key_w        = defined $opt->{len_key}      ? $opt->{len_key}      : length_longest( $keys );
    my $maxcols      = $opt->{maxcols};
    my $clear        = defined $opt->{clear_screen} ? $opt->{clear_screen} : 0;
    my $mouse        = defined $opt->{mouse}        ? $opt->{mouse}        : 0;
    my $prompt       = defined $opt->{prompt}       ? $opt->{prompt}       : ( defined $opt->{preface} ? '' : 'Close with ENTER' );
    my $hide_cursor  = defined $opt->{hide_cursor}  ? $opt->{hide_cursor}  : 1;
    my $preface      = $opt->{preface};
    #-----------------------------------------------------------------#
    my $term_width = term_width();
    if ( ! $maxcols || $maxcols > $term_width  ) {
        $maxcols = $term_width - $right_margin;
    }
    $key_w += $left_margin;
    my $sep = ' : ';
    my $len_sep = print_columns( "$sep" );
    if ( $key_w + $len_sep > int( $maxcols / 3 * 2 ) ) {
        $key_w = int( $maxcols / 3 * 2 ) - $len_sep;
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
        my $pr_key = sprintf "%*.*s%*s", $key_w, $key_w, $key, $len_sep, $sep;
        my $text = line_fold( $pr_key . $val, $maxcols, '' , ' ' x ( $key_w + $len_sep ) );
        $text =~ s/\n+\z//;
        for my $val ( split /\n+/, $text ) {
            push @vals, $val;
        }
    }
    return join "\n", @vals if defined wantarray;
    choose(
        [ @vals ],
        { prompt => $prompt, layout => 3, justify => 0, mouse => $mouse, clear_screen => $clear, hide_cursor => $hide_cursor }
    );
}


sub term_size {
    #my ( $handle_out ) = defined $_[0] ? $_[0] : \*STDOUT;
    if ( $^O eq 'MSWin32' ) {
        return Term::Choose::Win32->__get_term_size();
    }
    return Term::Choose::Linux->__get_term_size();
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

Version 0.067

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

Options available for all functions:

=over

=item

clear_screen

If enabled, the screen is cleared before the output.

Values: [0],1.

=item

info

A string placed on top of of the output.

=item

mouse

See the option I<mouse> in L<Term::Choose>

Values: [0],1,2,3,4.

=item

hide_cursor

Hide the cursor

Values: 0,[1].

=item

prompt

A string placed on top of the available choices.

=item

back

Allows to overwrite the default string of the menu entry "back".

=item

confirm

Allows to overwrite the default string of the menu entry "confirm".

=back

=head2 choose_a_dir

    $chosen_directory = choose_a_dir( { layout => 1, ... } )

With C<choose_a_dir> the user can browse through the directory tree (as far as the granted rights permit it) and
choose a directory which is returned.

To move around in the directory tree:

- select a directory and press C<Return> to enter in the selected directory.

- choose the "up"-menu-entry (C< .. >) to move upwards.

To return the current working-directory as the chosen directory choose C< OK >.

The "back"-menu-entry (C< << >) causes C<choose_a_dir> to return nothing.

As an argument it can be passed a reference to a hash. With this hash the user can set the different options:

=over

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

order

If set to 1, the items are ordered vertically else they are ordered horizontally.

This option has no meaning if I<layout> is set to 3.

Values: 0,[1].

=item

show_hidden

If enabled, hidden directories are added to the available directories.

Values: 0,[1].

=item

up

Overwrite the default string (C< .. >) of the menu entry "up".

=back

=head2 choose_a_file

    $chosen_file = choose_a_file( { layout => 1, ... } )

Browse the directory tree the same way as described for C<choose_a_dir>. Select C<E<gt>F> (string can be changed with
the option I<choose_file>) to get the files of the current directory. To return the chosen file select C< OK >.

The options are passed as a reference to a hash. See L</choose_a_dir> for the different options

=head2 choose_dirs

    $chosen_directories = choose_dirs( { layout => 1, ... } )

C<choose_dirs> is similar to C<choose_a_dir> but it is possible to return multiple directories.

Different to C<choose_a_dir>:

C< ++ > (change with option I<add_dir>) adds the current directory to the list of chosen directories.

To return the chosen list of directories (as an array reference) select the "confirm"-menu-entry C< OK >.

The "back"-menu-entry ( C< << > ) removes the last added directory. If the list of chosen directories is empty,
C< << > causes C<choose_dirs> to return nothing.

C<choose_dirs> uses the same option as C<choose_a_dir>. The option I<prompt> can used to put empty lines between the
header row and the menu (I<prompt> set to a single space means one empty line).

=over

=back

=head2 choose_a_number

    $new = choose_a_number( 5, { name => 'Testnumber ' }  );

This function lets you choose/compose a number (unsigned integer) which is returned.

The fist argument - "digits" - is an integer and determines the range of the available numbers. For example setting the
first argument to 6 would offer a range from 0 to 999999.

The second and optional argument is a reference to a hash with these keys (options):

=over

=item

name

The value of I<name> is put in front of the composed number in the info-output.

Default: "> ";

=item

small_on_top

Put the small number ranges on top.

=item

thsd_sep

Sets the thousands separator.

Default: comma (,).

=back

=head2 choose_a_subset

    $subset = choose_a_subset( \@available_items, { name => 'new> ' } )

C<choose_a_subset> lets you choose a subset from a list.

As a first argument it is required a reference to an array which provides the available list.

The optional second argument is a hash reference. The following options are available:

=over

=item

fmt_chosen

If I<fmt_chosen> is set to C<1>, each chosen item gets its own line in the output on the screen.

Values: [0], 1;

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

mark

Expects as its value a reference to an array with indexes. Elements corresponding to these indexes are preselected when
C<choose_a_subset> is called.

=item

name

The value of I<name> is a string. It is placed in front of the chosen-subset-info-output.

=item

order

If set to 1, the items are ordered vertically else they are ordered horizontally.

This option has no meaning if I<layout> is set to 3.

Values: 0,[1].

=item

prefix

I<prefix> expects as its value a string. This string is put in front of the elements of the available list before
printing. The chosen elements are returned without this I<prefix>.

The default value is "  " if the I<layout> is 3 else the default is the empty string ("").

=item

remove_chosen

If enabled, the chosen items are remove from the available choices.

Values: [0], 1;

=back

To return the chosen subset (as an array reference) select the "confirm"-menu-entry C<-OK->.

The "back"-menu-entry (C< << >) removes the last added chosen items. If the list of chosen items is empty,
" << " causes C<choose_a_subset> to return nothing.

=head2 settings_menu

    $menu = [
        [ 'enable_logging', "- Enable logging", [ 'NO', 'YES' ]   ],
        [ 'case_sensitive', "- Case sensitive", [ 'NO', 'YES' ]   ],
        [ 'attempts',       "- Attempts"      , [ '1', '2', '3' ] ]
    ];

    $config = {
        'enable_logging' => 1,
        'case_sensitive' => 1,
        'attempts'       => 2
    };

    settings_menu( $menu, $config );

The first argument is a reference to an array of arrays. These arrays have three elements:

=over

=item

the name of the option

=item

the prompt string

=item

an array reference with the available values of the option.

=back

The second argument is a hash reference:

=over

=item

the keys are the option names

=item

the values (C<0> if not defined) are the indexes of the current value of the respective key/option.

=back

With the optional third argument can be passed the options.

When C<settings_menu> is called, it displays for each array entry a row with the prompt string and the current value.
It is possible to scroll through the rows. If a row is selected, the set and displayed value changes to the next. If the
end of the list of the values is reached, it begins from the beginning of the list.

If the "back"-menu-entry (C<BACK>) is chosen, C<settings_menu> does not apply the made changes and returns nothing. If
the "confirm"-menu-entry (C<CONFIRM>) is chosen, C<settings_menu> applies the made changes and returns the number of
made changes.

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

Copyright 2014-2018 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
