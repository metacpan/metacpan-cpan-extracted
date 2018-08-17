package Term::Form;

use warnings;
use strict;
use 5.008003;

our $VERSION = '0.500';

use Carp       qw( croak carp );
use List::Util qw( any );

use Term::Choose::LineFold  qw( line_fold print_columns cut_to_printwidth );
use Term::Choose::Constants qw( :form );


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
    $self->{pg} = $Plugin_Package->new();
    return $self;
}


sub DESTROY {
    my ( $self ) = @_;
    $self->__reset_term();
}


sub __init_term {
    my ( $self, $hide_cursor ) = @_;
    $self->{pg}->__set_mode( $hide_cursor );
}


sub __reset_term {
    my ( $self, $hide_cursor ) = @_;
    if ( defined $self->{pg} ) {
        $self->{pg}->__reset_mode( $hide_cursor );
    }
    for my $key ( keys %$self ) {
        next if $key eq 'pg' || $key eq 'name';
        delete $self->{$key};
    }
    $self->__set_defaults();
}


sub __set_defaults {
    my ( $self ) = @_;
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
    my $sub =  ( caller( 1 ) )[3];
    $sub =~ s/^.+::([^:]+)\z/$1/;
    for my $k ( keys %$opt ) {
        croak $sub . ": '$k' is not a valid option name"                  if ! exists $valid->{$k};
        next                                                              if ! defined $opt->{$k};
        croak $sub . ": option '$k' : a reference is not a valid value."  if ref $opt->{$k} && $valid->{$k} ne 'ARRAY';
        next                                                              if $valid->{$k} eq '';
        croak $sub . ": option '$k' : '$opt->{$k}' is not a valid value." if $opt->{$k} !~ m/^$valid->{$k}\z/x;
    }
    for my $k ( keys %$valid ) {
        $opt->{$k} = $self->{$k} if ! defined $opt->{$k};
    }
    return $opt;
}


sub __prepare_width {
    my ( $self ) = @_;
    my ( $term_w, $term_h ) = $self->{pg}->__get_term_size();
    $self->{i}{term_w} = $term_w - 1;
        # - 1 for the '<' before the string. In each case where no '<'-prefix is required (diff==0) 1 is added to
        # avail_w in the code: __left, __bspace, __home, __ctrl_u
        # - 1 for the cursor (or the '>') behind the string already subtracted by __get_term_size
    if ( $self->{i}{max_key_w} > $self->{i}{term_w} / 3 ) {
        $self->{i}{max_key_w} = int( $self->{i}{term_w} / 3 );
    }
    $self->{i}{prompt_w} = $self->{i}{max_key_w} + print_columns( $self->{i}{sep} );
    $self->{i}{avail_w} = $self->{i}{term_w} - $self->{i}{prompt_w};
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
    my $valid = {
        clear_screen => '[ 0 1 ]',
        default      => '',
        info         => '',
        no_echo      => '[ 0 1 2 ]',
    };
    $opt = $self->__validate_options( $opt, $valid );
    $self->{i}{pre_text}  = $opt->{info};
    $self->{i}{key_w}[0]  = print_columns( $prompt );
    $self->{i}{max_key_w} = $self->{i}{key_w}[0];
    $self->{i}{sep}       = '';
    local $| = 1;
    $self->__init_term();
    $self->__prepare_width();
    $self->{i}{th} = int( $self->{i}{avail_w} / 5 );
    $self->{i}{th} = 35 if $self->{i}{th} > 35;
    my $list = [ [ $prompt, $opt->{default} ] ];
    $self->{i}{curr_row} = 0;
    my $m = $self->__string_and_pos( $list );
    $self->{pg}->__clear_screen() if $opt->{clear_screen};
    $self->{i}{pre_text_row_count} = 0;

    while ( 1 ) {
        if ( $self->{i}{beep} ) {
            $self->{pg}->__beep();
            $self->{i}{beep} = 0;
        }
        $self->__prepare_width();
        if ( defined $self->{i}{pre_text} ) { # empty info: add newline ?
            $self->{pg}->__up( $self->{i}{pre_text_row_count} );
            $self->{pg}->__clear_lines_to_end_of_screen();
            $self->__pre_text_row_count();
            print "\r", $self->{i}{pre_text}, "\n";
        }
        $m->{avail_w} = $self->{i}{avail_w}; # reset to default
        $self->__print_readline( $opt, $list, $m );
        my $key = $self->{pg}->__get_key_OS();
        if ( ! defined $key ) {
            $self->__reset_term();
            carp "EOT: $!";
            return;
        }
        #$m->{th} = $self->{i}{th};         # threshold number of chars
        $self->__calculate_threshold( $m ); # threshold print width
        if    ( $key == NEXT_get_key ) { next }
        elsif ( $key == KEY_TAB      ) { next }
        elsif ( $key == CONTROL_U                       ) { $self->__ctrl_u( $m ) }
        elsif ( $key == CONTROL_K                       ) { $self->__ctrl_k( $m ) }
        elsif ( $key == VK_RIGHT   || $key == CONTROL_F ) { $self->__right(  $m ) }
        elsif ( $key == VK_LEFT    || $key == CONTROL_B ) { $self->__left(   $m ) }
        elsif ( $key == VK_END     || $key == CONTROL_E ) { $self->__end(    $m ) }
        elsif ( $key == VK_HOME    || $key == CONTROL_A ) { $self->__home(   $m ) }
        elsif ( $key == KEY_BSPACE || $key == CONTROL_H ) { $self->__bspace( $m ) }
        elsif ( $key == VK_DELETE  || $key == CONTROL_D ) {
            my $leave = $self->__delete( $m, $key );
            if ( $leave ) {
                print "\n";
                $self->__reset_term();
                return;
            }
        }
        elsif ( $key == VK_UP || $key == VK_DOWN || $key == VK_PAGE_UP || $key == VK_PAGE_DOWN || $key == VK_INSERT ) {
            $self->{i}{beep} = 1;
        }
        else {
            $key = chr $key;
            utf8::upgrade $key;
            if ( $key eq "\n" || $key eq "\r" ) { #
                print "\n";
                $self->{pg}->__up( $self->{i}{pre_text_row_count} + 1 );
                $self->{pg}->__clear_lines_to_end_of_screen();
                $self->__reset_term();
                return join( '', map { $_->[0] } @{$m->{str}} );
            }
            else {
                $self->__add_char( $m, $key );
            }
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
        pos     => 0,
        p_str   => [],
        p_str_w => 0,
        p_pos   => 0,
        diff    => 0,
    };
    for ( $default =~ /\X/g ) { # \X == grapheme clusters
        my $char_w = print_columns( $_ );
        push @{$m->{str}}, [ $_, $char_w ];
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
        ## threshold number of chars:
        #if( $m->{p_pos} == $m->{th} && $m->{diff} ) {
        #    _unshift_element( $m, $m->{pos} - $m->{p_pos} );

        # threshold print width:
        # '<=' and not '==' because th_l could change and fall behind p_pos
        if( $m->{p_pos} <= $m->{th_l} && $m->{diff} ) {
             while ($m->{p_pos} <= $m->{th_l}) {
                _unshift_element( $m, $m->{pos} - $m->{p_pos} );
             }
            if ( ! $m->{diff} ) { # no '<'
                $m->{avail_w} = $self->{i}{avail_w} + 1;
                _push_till_avail_w( $m, [ $#{$m->{p_str}} + 1 .. $#{$m->{str}} ] );
            }
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
        ## threshold number of chars:
        #if(    $m->{p_pos} == $#{$m->{p_str}} - $m->{th}
        #    && $#{$m->{p_str}} + $m->{diff} != $#{$m->{str}}
        #) {
        #    _push_element( $m );

        # threshold print width:
        # '>=' and not '==' because th_r could change and fall in front of p_pos
        if(    $m->{p_pos} >= $#{$m->{p_str}} - $m->{th_r}
            && $#{$m->{p_str}} + $m->{diff} != $#{$m->{str}}
        ) {
            while ( $m->{p_pos} >= $#{$m->{p_str}} - $m->{th_r} ) {
                _push_element( $m );
            }
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
        ## threshold number of chars:
        #if( $m->{p_pos} == $m->{th} && $m->{diff} ) {
        #    _unshift_element( $m, $m->{pos} - $m->{p_pos} );

        # threshold print width:
        # '<=' and not '==' because th_l could change and fall behind p_pos
        if ( $m->{p_pos} <= $m->{th_l} && $m->{diff} ) {
            while ($m->{p_pos} <= $m->{th_l}) {
                _unshift_element( $m, $m->{pos} - $m->{p_pos} );
            }
        }
        $m->{p_pos}--;
        if ( ! $m->{diff} ) { # no '<'
            $m->{avail_w} = $self->{i}{avail_w} + 1;
            # _push_till_avail_w in _remove_pos
        }
        _remove_pos( $m );
    }
    else {
        $self->{i}{beep} = 1;
    }
}

sub __delete {
    my ( $self, $m, $key ) = @_;
    if ( $m->{pos} < @{$m->{str}} ) {
        _remove_pos( $m );
    }
    else {
        if ( defined $key && $key == CONTROL_D ) {
            return 1;
        }
        else {
            $self->{i}{beep} = 1;
            return
        }
    }
}

sub __ctrl_u {
    my ( $self, $m ) = @_;
    if ( $m->{pos} ) {
        splice ( @{$m->{str}}, 0, $m->{pos} );
        # diff always 0     # never '<'
        $m->{avail_w} = $self->{i}{avail_w} + 1;
        # _push_till_avail_w in _fill_from_begin
        _fill_from_begin( $m );
    }
    else {
        $self->{i}{beep} = 1;
    }
}

sub __ctrl_k {
    my ( $self, $m ) = @_;
    if ( $m->{pos} < @{$m->{str}} ) {
        splice ( @{$m->{str}}, $m->{pos}, @{$m->{str}} - $m->{pos} );
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
        $m->{avail_w} = $self->{i}{avail_w} + 1;
        # _push_till_avail_w in _fill_from_begin
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
    #_unshift_till_avail_w( $m, [ 0 .. $m->{diff} - 1 ] ); #
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
    #_unshift_till_avail_w( $m, [ 0 .. $pos - 1 ] ); #
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
    #_push_till_avail_w( $m, [ ( $#{$m->{p_str}} + $m->{diff} + 1 ) .. $#{$m->{str}} ] );
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
    _push_till_avail_w( $m, [ ( $#{$m->{p_str}} + $m->{diff} + 1 ) .. $#{$m->{str}} ] );
    #_unshift_till_avail_w( $m, [ 0 .. $m->{diff} - 1 ] ); #
}

sub _fill_from_end {
    my ( $m ) = @_;
    $m->{pos}      = @{$m->{str}};
    @{$m->{p_str}} = ();
    $m->{p_str_w}  = 0;
    $m->{diff}     = @{$m->{str}};
    $m->{p_pos}    = 0;
    _unshift_till_avail_w( $m, [ 0 .. $#{$m->{str}} ] );
}

sub _fill_from_begin {
    my ( $m ) = @_;
    $m->{pos}      = 0;
    $m->{p_pos}    = 0;
    $m->{diff}     = 0;
    @{$m->{p_str}} = ();
    $m->{p_str_w}  = 0;
    _push_till_avail_w( $m, [ 0 .. $#{$m->{str}} ] );
}


sub __print_readline {
    my ( $self, $opt, $list, $m ) = @_;
    my $key = $self->__padded_or_trimed_key( $list, $self->{i}{curr_row} );
    $self->{pg}->__clear_line();
    if ( $opt->{mark_curr} ) {
        $self->{pg}->__mark_current();
        print "\r", $key;
        $self->{pg}->__reset();
    }
    else {
        print "\r", $key;
    }
    my $sep = $self->{i}{sep};
    if ( defined $self->{i}{pre} && any { $_ == $self->{i}{curr_row} - @{$self->{i}{pre}} } @{$opt->{read_only}} ) { #
        $sep = $self->{i}{sep_ro};
    }
    my $tmp_prompt_w = $self->{i}{prompt_w};
    if ( $m->{diff} ) {
        $sep .= '<';
        $tmp_prompt_w++;
    }
    my $print_str = join( '', map { defined $_->[0] ? $_->[0] : '' } @{$m->{p_str}} );
    if ( @{$m->{p_str}} + $m->{diff} != @{$m->{str}} ) {
        $print_str .= '>';
    }
    if ( $opt->{no_echo} ) {
        if ( $opt->{no_echo} == 2 ) {
            print $sep;
            return;
        }
        print $sep, '*' x @{$m->{p_str}}, "\r";
    }
    else {
        print $sep, $print_str, "\r";
    }
    my $pre_pos_w = 0;
    for ( @{$m->{p_str}}[0..$m->{p_pos}-1] ) {
        $pre_pos_w += $_->[1];
    }
    $self->{pg}->__right( $tmp_prompt_w + $pre_pos_w );

}


sub __padded_or_trimed_key {
    my ( $self, $list, $idx ) = @_;
    my $unicode;
    my $key_length = $self->{i}{key_w}[$idx];
    my $key = $list->[$idx][0];
    $key =~ s/\p{Space}/ /g;
    $key =~ s/\p{C}//g;
    if ( $key_length > $self->{i}{max_key_w} ) {
        $unicode = $self->__unicode_trim( $key, $self->{i}{max_key_w} );
    }
    elsif ( $key_length < $self->{i}{max_key_w} ) {
        $unicode = " " x ( $self->{i}{max_key_w} - $key_length ) . $key;
    }
    else {
        $unicode = $key;
    }
    return $unicode;
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


sub __pre_text_row_count {
    my ( $self ) = @_;
    $self->{i}{pre_text_row_count} = 0;
    if ( ! defined $self->{i}{pre_text} ) {  # empty info add newline
        return;
    }
    $self->{i}{pre_text} = line_fold( $self->{i}{pre_text}, $self->{i}{term_w}, 0, 0 );
    $self->{i}{pre_text_row_count} = $self->{i}{pre_text} =~ s/\n/\n/g;
    $self->{i}{pre_text_row_count} += 1;
}


sub __prepare_size {
    my ( $self, $opt, $list, $maxcols, $maxrows ) = @_;
    $self->{i}{term_w} = $maxcols - 1;
    $self->{i}{avail_h} = $maxrows;
    if ( defined $self->{i}{pre_text} ) {
        $self->__pre_text_row_count();
        my $backup_height = $self->{i}{avail_h};
        $self->{i}{avail_h} -= $self->{i}{pre_text_row_count};
        my $min_avail_h = 5;
        if ( $self->{i}{avail_h} < $min_avail_h ) {
            if ( $backup_height > $min_avail_h ) {
                $self->{i}{avail_h} = $min_avail_h;
            }
            else {
                $self->{i}{avail_h} = $backup_height;
            }
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
    my ( $self, $opt, $list, $m ) = @_;
    $self->{pg}->__clear_line();
    if ( $self->{i}{curr_row} < @{$self->{i}{pre}} ) {
        $self->{pg}->__reverse();
        print $list->[$self->{i}{curr_row}][0];
        $self->{pg}->__reset();
    }
    else {
        $self->__print_readline( $opt, $list, $m );
        $list->[$self->{i}{curr_row}][1] = join( '', map { defined $_->[0] ? $_->[0] : '' } @{$m->{str}} );
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
            $self->__unicode_trim( $val, $self->{i}{avail_w} );
    }
}


sub __write_screen {
    my ( $self, $opt, $list ) = @_;
    print join "\n", map { $self->__print_row( $opt, $list, $_ ) } $self->{i}{begin_row} .. $self->{i}{end_row};
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
        $self->{pg}->__up( $self->{i}{avail_h} - ( $self->{i}{curr_row} - $self->{i}{begin_row} ) );
    }
    else {
        $self->{i}{page} = 1;
        my $up_curr = $self->{i}{end_row} - $self->{i}{curr_row};
        $self->{pg}->__up( $up_curr );
    }
}


sub __write_first_screen {
    my ( $self, $opt, $list, $curr_row, $auto_up ) = @_;
    if ( $self->{i}{max_key_w} > $self->{i}{term_w} / 3 ) {
        $self->{i}{max_key_w} = int( $self->{i}{term_w} / 3 );
    }
    my $len_separator = print_columns( $self->{i}{sep} );
    if ( @{$opt->{read_only}} ) {
        my $tmp = print_columns( $self->{i}{sep_ro} );
        $len_separator = $tmp if $tmp > $len_separator;
    }
    $self->{i}{prompt_w} = $self->{i}{max_key_w} + $len_separator;
    $self->{i}{avail_w} = $self->{i}{term_w} - $self->{i}{prompt_w};
    $self->{i}{curr_row} = $auto_up == 2 ? $curr_row : @{$self->{i}{pre}};
    $self->{i}{begin_row} = 0;
    $self->{i}{end_row}  = ( $self->{i}{avail_h} - 1 );
    if ( $self->{i}{end_row} > $#$list ) {
        $self->{i}{end_row} = $#$list;
    }
    $self->{pg}->__clear_screen() if $opt->{clear_screen};
    if ( defined $self->{i}{pre_text} ) {  # empty info add newline
        print $self->{i}{pre_text}, "\n";
    }
    $self->__write_screen( $opt, $list );
}


sub fill_form {
    my ( $self, $orig_list, $opt ) = @_;
    croak "'fill_form' called with no argument." if ! defined $orig_list;
    croak "'fill_form' requires an ARRAY reference as its argument." if ref $orig_list ne 'ARRAY';
    $opt = {} if ! defined $opt;
    croak "'fill_form': the (optional) second argument must be a HASH reference" if ref $opt ne 'HASH';
    return [] if ! @$orig_list; ##
    my $valid = {
        auto_up      => '[ 0 1 2 ]',
        back         => '',
        clear_screen => '[ 0 1 ]',
        confirm      => '',
        info         => '',
        mark_curr    => '[ 0 1 ]',
        prompt       => '',
        read_only    => 'ARRAY',
    };
    $opt = $self->__validate_options( $opt, $valid );
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
    my ( $maxcols, $maxrows ) = $self->{pg}->__get_term_size();
    $self->__prepare_size( $opt, $list, $maxcols, $maxrows );
    $self->__write_first_screen( $opt, $list, 0, $auto_up );
    my $m = $self->__string_and_pos( $list );
    $self->__calculate_threshold( $m ); #

    my $k = 0;

    KEY: while ( 1 ) {
        my $locked = 0;
        if ( any { $_ == $self->{i}{curr_row} - @{$self->{i}{pre}} } @{$opt->{read_only}} ) {
            $locked = 1;
        }
        if ( $self->{i}{beep} ) {
            $self->{pg}->__beep();
            $self->{i}{beep} = 0;
        }
        else {
            $self->__print_current_row( $opt, $list, $m );
        }
        my $key = $self->{pg}->__get_key_OS();
        if ( ! defined $key ) {
            $self->__reset_term();
            carp "EOT: $!";
            return;
        }
        next KEY if $key == NEXT_get_key;
        next KEY if $key == KEY_TAB;
        my ( $tmp_maxcols, $tmp_maxrows ) = $self->{pg}->__get_term_size();
        if ( $tmp_maxcols != $maxcols || $tmp_maxrows != $maxrows && $tmp_maxrows < ( @$list + 1 ) ) {
            ( $maxcols, $maxrows ) = ( $tmp_maxcols, $tmp_maxrows );
            $self->__prepare_size( $opt, $list, $maxcols, $maxrows );
            $self->{pg}->__clear_screen();
            $self->__write_first_screen( $opt, $list, 1, $auto_up ); # 1
            $m = $self->__string_and_pos( $list );
        }
        if ( $key == KEY_BSPACE || $key == CONTROL_H ) {
            $k = 1;
            if ( $locked ) {    # read_only
                $self->{i}{beep} = 1;
            }
            else {
                $self->__bspace( $m );
            }
        }
        elsif ( $key == CONTROL_U ) {
            $k = 1;
            if ( $locked ) {
                $self->{i}{beep} = 1;
            }
            else {
                $self->__ctrl_u( $m );
            }
        }
        elsif ( $key == CONTROL_K ) {
            $k = 1;
            if ( $locked ) {
                $self->{i}{beep} = 1;
            }
            else {
                $self->__ctrl_k( $m );
            }
        }
        elsif ( $key == VK_DELETE || $key == CONTROL_D ) {
            $k = 1;
            $self->__delete( $m );
        }
        elsif ( $key == VK_RIGHT ) {
            $k = 1;
            $self->__right( $m );
        }
        elsif ( $key == VK_LEFT ) {
            $k = 1;
            $self->__left( $m );
        }
        elsif ( $key == VK_END   || $key == CONTROL_E ) {
            $k = 1;
            $self->__end( $m );
        }
        elsif ( $key == VK_HOME  || $key == CONTROL_A ) {
            $k = 1;
            $self->__home( $m );
        }
        elsif ( $key == VK_UP ) {
            $k = 1;
            if ( $self->{i}{curr_row} == 0 ) {
                $self->{i}{beep} = 1;
            }
            else {
                $self->{i}{curr_row}--;
                $m = $self->__string_and_pos( $list );
                if ( $self->{i}{curr_row} >= $self->{i}{begin_row} ) {
                    $self->__reset_previous_row( $opt, $list, $self->{i}{curr_row} + 1 );
                    $self->{pg}->__up( 1 );
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
                $m = $self->__string_and_pos( $list );
                if ( $self->{i}{curr_row} <= $self->{i}{end_row} ) {
                    $self->__reset_previous_row( $opt, $list, $self->{i}{curr_row} - 1 );
                    $self->{pg}->__down( 1 );
                }
                else {
                    $self->{pg}->__up( $self->{i}{end_row} - $self->{i}{begin_row} );
                    $self->__print_next_page( $opt, $list );
                }
            }
        }
        elsif ( $key == VK_PAGE_UP || $key == CONTROL_B ) {
            $k = 1;
            if ( $self->{i}{page} == 1 ) {
                if ( $self->{i}{curr_row} == 0 ) {
                    $self->{i}{beep} = 1;
                }
                else {
                    $self->__reset_previous_row( $opt, $list, $self->{i}{curr_row} );
                    $self->{pg}->__up( $self->{i}{curr_row} );
                    $self->{i}{curr_row} = 0;
                    $m = $self->__string_and_pos( $list );
                }
            }
            else {
                $self->{pg}->__up( $self->{i}{curr_row} - $self->{i}{begin_row} );
                $self->{i}{curr_row} = $self->{i}{begin_row} - $self->{i}{avail_h};
                $m = $self->__string_and_pos( $list );
                $self->__print_previous_page( $opt, $list );
            }
        }
        elsif ( $key == VK_PAGE_DOWN || $key == CONTROL_F ) {
            $k = 1;
            if ( $self->{i}{page} == $self->{i}{pages} ) {
                if ( $self->{i}{curr_row} == $#$list ) {
                    $self->{i}{beep} = 1;
                }
                else {
                    $self->__reset_previous_row( $opt, $list, $self->{i}{curr_row} );
                    $self->{pg}->__down( $self->{i}{end_row} - $self->{i}{curr_row} );
                    $self->{i}{curr_row} = $self->{i}{end_row};
                    $m = $self->__string_and_pos( $list );
                }
            }
            else {
                $self->{pg}->__up( $self->{i}{curr_row} - $self->{i}{begin_row} );
                $self->{i}{curr_row} = $self->{i}{end_row} + 1;
                $m = $self->__string_and_pos( $list );
                $self->__print_next_page( $opt, $list );
            }
        }
        elsif ( $key == VK_INSERT ) {
            $self->{i}{beep} = 1;
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
                    $self->{pg}->__up( $up );
                    $self->{pg}->__clear_lines_to_end_of_screen();
                    $self->__reset_term();
                    return;
                }
                elsif ( $list->[$self->{i}{curr_row}][0] eq $opt->{confirm} ) {                                         # if ENTER on {confirm/1}: leave and return result
                    $self->{pg}->__up( $up );
                    $self->{pg}->__clear_lines_to_end_of_screen();
                    splice @$list, 0, @{$self->{i}{pre}};
                    $self->__reset_term();
                    return $list;
                }
                if ( $auto_up == 2 ) {                                                                                  # if ENTER && "auto_up" == 2 && any row: jumps {back/0}
                    $self->{pg}->__up( $up );
                    $self->{pg}->__clear_lines_to_end_of_screen();
                    my $cursor = 0; # cursor on {back}
                    $self->__write_first_screen( $opt, $list, $cursor, $auto_up );
                    $m = $self->__string_and_pos( $list );
                }
                elsif ( $self->{i}{curr_row} == $#$list ) {                                                             # if ENTER && {last row}: jumps to the {first data row/2}
                    $self->{pg}->__up( $up );
                    $self->{pg}->__clear_lines_to_end_of_screen();
                    my $cursor = scalar @{$self->{i}{pre}};                                                             # cursor on the first data row
                    $self->__write_first_screen( $opt, $list, $cursor, $auto_up );
                    $m = $self->__string_and_pos( $list );
                    $self->{i}{lock_ENTER} = 1;                                                                         # set lock_ENTER when jumped automatically from the {last row} to the {first data row/2}
                }
                else {
                    if ( $auto_up == 1 && $self->{i}{curr_row} == @{$self->{i}{pre}} && $self->{i}{lock_ENTER} ) {      # if ENTER && "auto_up" == 1 $$ "curr_row" == {first data row/2} && lock_ENTER is true:
                        $self->{i}{beep} = 1;                                                                           # set "auto_up" temporary to 2 so a second ENTER moves the cursor to {back/0}
                        $auto_up = 2;
                        next KEY;
                    }
                     $self->{i}{curr_row}++;
                    $m = $self->__string_and_pos( $list );                                                              # or go to the next row if not on the last row
                    if ( $self->{i}{curr_row} <= $self->{i}{end_row} ) {
                        $self->__reset_previous_row( $opt, $list, $self->{i}{curr_row} - 1 );
                        $self->{pg}->__down( 1 );
                    }
                    else {
                        $self->{pg}->__up( $up );                                                                       # or else to the next page
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
                    $self->__add_char( $m, $key );
                }
            }
        }
    }
}


sub __reset_previous_row {
    my ( $self, $opt, $list, $idx ) = @_;
    $self->{pg}->__clear_line();
    print $self->__print_row( $opt, $list, $idx );
}


sub __print_next_page {
    my ( $self, $opt, $list ) = @_;
    $self->{i}{begin_row} = $self->{i}{end_row} + 1;
    $self->{i}{end_row}   = $self->{i}{end_row} + $self->{i}{avail_h};
    $self->{i}{end_row}   = $#$list if $self->{i}{end_row} > $#$list;
    $self->{pg}->__clear_lines_to_end_of_screen();
    $self->__write_screen( $opt, $list );
}


sub __print_previous_page {
    my ( $self, $opt, $list ) = @_;
    $self->{i}{end_row}   = $self->{i}{begin_row} - 1;
    $self->{i}{begin_row} = $self->{i}{begin_row} - $self->{i}{avail_h};
    $self->{i}{begin_row} = 0 if $self->{i}{begin_row} < 0;
    $self->{pg}->__clear_lines_to_end_of_screen();
    $self->__write_screen( $opt, $list );
}





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Form - Read lines from STDIN.

=head1 VERSION

Version 0.500

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

C<Delete> or C<Strg-D>: Delete  the  character at point. C<readline> returns nothing if C<Strg-D> was pressed and the
input puffer is empty.

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
