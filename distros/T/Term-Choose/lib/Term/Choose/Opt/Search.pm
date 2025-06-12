package Term::Choose::Opt::Search;

use warnings;
use strict;
use 5.10.1;

our $VERSION = '1.775';

use Term::Choose::Constants qw( ROW COL );
use Term::Choose::Screen    qw( up clear_to_end_of_screen show_cursor hide_cursor );


sub __user_input {
    my ( $self, $prompt, $error, $default ) = @_;
    $self->{plugin}->__reset_mode( { mouse => $self->{mouse}, hide_cursor => $self->{hide_cursor} } );
    if ( $self->{l_margin} ) {
        $prompt = ( ' ' x $self->{l_margin} ) . $prompt;
    }
    my $string;
    if ( ! eval {
        require Term::Form::ReadLine;
        Term::Form::ReadLine->VERSION(0.544);
        my $term = Term::Form::ReadLine->new();
        $string = $term->readline(
            $prompt,
            { info => $error, default => $default, hide_cursor => 2, clear_screen => length $error ? 1 : 2,
              color => $self->{color} }
        );
        1 }
    ) {
        print "\r", clear_to_end_of_screen();
        if ( length $error ) {
            print $error, "\n\r";
        }
        print show_cursor() if ! $self->{hide_cursor};
        print $prompt;
        $string = <STDIN>;
        print hide_cursor() if ! $self->{hide_cursor};
        chomp $string;
    }
    $self->__init_term();
    return $string;
}


sub __search_begin {
    my ( $self ) = @_;
    my ($search_regex, $error, $default );

    USER_INPUT: while ( 1 ) {
        my $search_str = $self->Term::Choose::Opt::Search::__user_input( '> search-pattern: ', $error, $default );
        $error = '';
        if ( ! length $search_str ) {
            $self->Term::Choose::Opt::Search::__search_end();
            return;
        }
        if ( ! eval {
            if ( $self->{search} == 1 ) {
                $search_regex = qr/$search_str/i;
                $self->{search_info} = 'm/' . $search_str . '/i';
            }
            else {
                $search_regex = qr/$search_str/;
                $self->{search_info} = 'm/' . $search_str . '/';
            }
            'Teststring' =~ $search_regex;
            1 }
        ) {
            $error = $@;
            $default = $default eq $search_str ? '' : $search_str;
            next USER_INPUT;
        }
        last USER_INPUT;
    }
    $self->{map_search_list_index} = [];
    my $filtered_list = [];
    for my $i ( 0 .. $#{$self->{list}} ) {
        if ( $self->{list}[$i] =~ $search_regex ) {
            push @{$self->{map_search_list_index}}, $i;
            push @$filtered_list, $self->{list}[$i];
        }
    }
    if ( ! @$filtered_list ) {
        $filtered_list = [ 'No matches found.' ];
        $self->{map_search_list_index} = [ 0 ];
    }
    $self->{mark} = $self->__marked_rc2idx();
    $self->{backup_list} = [ @{$self->{list}} ];
    $self->{list} = $filtered_list;
    $self->{backup_width_elements} = [ @{$self->{width_elements}} ];
    $self->{backup_col_width} = $self->{col_width};
    $self->__length_list_elements();
    $self->{default} = 0;
    for my $opt ( qw(meta_items no_spacebar mark) ) {
        if ( defined $self->{$opt} ) {
            $self->{'backup_' . $opt} = [ @{$self->{$opt}} ];
            my $tmp = [];
            for my $orig_idx ( @{$self->{$opt}} ) {
                for my $i ( 0 .. $#{$self->{map_search_list_index}} ) {
                    if ( $self->{map_search_list_index}[$i] == $orig_idx ) {
                        push @$tmp, $i;
                    }
                }
            }
            $self->{$opt} = $tmp;
        }
    }
    my $up = $self->{i_row} + $self->{count_prompt_lines} + 1; # + 1 => readline
    print up( $up ) if $up;
    $self->__wr_first_screen();
}


sub __search_end {
    my ( $self ) = @_;
    $self->{search_info} = '';
    if ( @{$self->{map_search_list_index}||[]} ) {
        my $curr_idx = $self->{rc2idx}[ $self->{pos}[ROW] ][ $self->{pos}[COL] ];
        $self->{default} = $self->{map_search_list_index}[$curr_idx];
        $self->{mark} = $self->__marked_rc2idx();
        my $tmp_mark = [];
        for my $i ( @{$self->{mark}} ) {
            push @$tmp_mark, $self->{map_search_list_index}[$i];
        }
        my %seen;
        $self->{mark} = [ grep !$seen{$_}++, @$tmp_mark, defined $self->{backup_mark} ? @{$self->{backup_mark}} : () ];
    }
    delete $self->{map_search_list_index};
    delete $self->{backup_mark};
    for my $key ( qw(list width_elements col_width meta_items no_spacebar) ) {
        my $key_backup = 'backup_' . $key;
        $self->{$key} = $self->{$key_backup} if defined $self->{$key_backup};
        delete $self->{$key_backup};
    }
    my $up = $self->{i_row} + $self->{count_prompt_lines};
    print up( $up ) if $up;
    print "\r" . clear_to_end_of_screen();
    $self->__wr_first_screen();
}







1;

__END__
