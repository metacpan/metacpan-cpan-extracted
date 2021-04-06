package Term::Choose::Opt::Search;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.730';

use Term::Choose::Constants qw( :index );
use Term::Choose::Screen    qw( up clear_to_end_of_screen );


sub __user_input {
    my ( $self, $prompt ) = @_;
    $self->{plugin}->__reset_mode( { mouse => $self->{mouse}, hide_cursor => $self->{hide_cursor} } );
    my $string;
    if ( ! eval {
        require Term::Form;
        Term::Form->VERSION(0.530);
        my $term = Term::Form->new();
        $string = $term->readline( $prompt, { hide_cursor => 2, clear_screen => 2, color => $self->{color} } );
        1 }
    ) {
        print "\r", clear_to_end_of_line();
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
    $self->{search} = 1;
    $self->{map_search_list_index} = [];
    my $search_str = $self->Term::Choose::Opt::Search::__user_input( '> search-pattern: ' );
    if ( ! length $search_str ) {
        $self->Term::Choose::Opt::Search::__search_end();
        return;
    }
    if ( $self->{f3} == 1 ) {
        $search_str = '(?i)' . $search_str;
    }
    $self->{backup_list} = [ @{$self->{list}} ];
    my $filtered_list = [];
    for my $i ( 0 .. $#{$self->{list}} ) {
        if ( $self->{list}[$i] =~ /$search_str/ ) {
            push @{$self->{map_search_list_index}}, $i;
            push @$filtered_list, $self->{list}[$i];
        }
    }
    if ( ! @$filtered_list ) {
        $filtered_list = [ 'No matches found.' ];
        $self->{map_search_list_index} = [ 0 ];
    }
    $self->{mark} = $self->__marked_rc2idx();
    $self->{list} = $filtered_list;
    $self->{backup_length} = [ @{$self->{length}} ];
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
    if ( defined $self->{map_search_list_index} && @{$self->{map_search_list_index}} ) {
        $self->{default} = $self->{map_search_list_index}[$self->{rc2idx}[$self->{pos}[ROW]][$self->{pos}[COL]]];
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
    for my $key ( qw(list length col_width meta_items no_spacebar) ) {
        my $key_backup = 'backup_' . $key;
        $self->{$key} = $self->{$key_backup} if defined $self->{$key_backup};
        delete $self->{$key_backup};
    }
    $self->{search} = 0;
    my $up = $self->{i_row} + $self->{count_prompt_lines};
    print up( $up ) if $up;
    print "\r" . clear_to_end_of_screen();
    $self->__wr_first_screen();
}







1;

__END__
