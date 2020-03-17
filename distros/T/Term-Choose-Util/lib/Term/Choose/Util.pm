package Term::Choose::Util;

use warnings;
use strict;
use 5.008003;

our $VERSION = '0.119';
use Exporter 'import';
our @EXPORT_OK = qw( choose_a_directory choose_a_file choose_directories choose_a_number choose_a_subset settings_menu
                     insert_sep get_term_size get_term_width get_term_height unicode_sprintf );

use Carp                  qw( croak );
use Cwd                   qw( realpath );
use Encode                qw( decode encode );
use File::Basename        qw( basename dirname );
use File::Spec::Functions qw( catdir catfile );
use List::Util            qw( sum any );

use Encode::Locale qw();
use File::HomeDir  qw();

use Term::Choose                  qw( choose );
use Term::Choose::LineFold        qw( line_fold cut_to_printwidth print_columns );
use Term::Choose::ValidateOptions qw( validate_options );


sub new {
    my $class = shift;
    my ( $opt ) = @_;
    my $instance_defaults = _defaults();
    if ( defined $opt ) {
        croak "Options have to be passed as a HASH reference." if ref $opt ne 'HASH';
        validate_options( _valid_options( 'new' ), $opt );
        for my $key ( keys %$opt ) {
            $instance_defaults->{$key} = $opt->{$key} if defined $opt->{$key};
        }
    }
    my $self = bless $instance_defaults, $class;
    $self->{backup_instance_defaults} = { %$instance_defaults };
    return $self;
}


sub __restore_defaults {
    my ( $self ) = @_;
    if ( exists $self->{backup_instance_defaults} ) {
        my $instance_defaults = $self->{backup_instance_defaults};
        for my $key ( keys %$self ) {
            if ( $key eq 'backup_instance_defaults' ) {
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


sub __prepare_opt {
    my ( $self, $opt ) = @_;
    if ( ! defined $opt ) {
        $opt = {};
    }
    croak "Options have to be passed as a HASH reference." if ref $opt ne 'HASH';
    if ( %$opt ) {
        my $sub =  ( caller( 1 ) )[3];
        $sub =~ s/^.+::(?:__)?([^:]+)\z/$1/;
        validate_options( _valid_options( $sub ), $opt );
        my $defaults = _defaults();
        for my $key ( keys %$opt ) {
            if ( ! defined $opt->{$key} && defined $defaults->{$key} ) {
                $self->{$key} = $defaults->{$key};
            }
            else {
                $self->{$key} = $opt->{$key};
            }
        }
    }
}


sub _valid_options {
    my ( $caller ) = @_;
    my %valid = (
        all_by_default      => '[ 0 1 ]',
        clear_screen        => '[ 0 1 ]',
        decoded             => '[ 0 1 ]',
        enchanted           => '[ 0 1 ]',
        hide_cursor         => '[ 0 1 ]',
        index               => '[ 0 1 ]',
        keep_chosen         => '[ 0 1 ]',
        mouse               => '[ 0 1 2 3 4 ]',     # 05.09.2019    # after transition -> '[ 0 1 ]',
        order               => '[ 0 1 ]',
        show_hidden         => '[ 0 1 ]',
        small_first         => '[ 0 1 ]',
        alignment           => '[ 0 1 2 ]',
        color               => '[ 0 1 2 ]',
        layout              => '[ 0 1 2 3 ]',
        mark                => 'ARRAY',
        solo                => 'ARRAY',     # experimental
        tabs_info           => 'ARRAY',
        tabs_prompt         => 'ARRAY',
        busy_string         => 'Str',
        info                => 'Str',
        init_dir            => 'Str',
        add_dirs            => 'Str',
        back                => 'Str',
        filter              => 'Str',
        show_files          => 'Str',
        confirm             => 'Str',
        parent_dir          => 'Str',
        prefix              => 'Str',
        prompt              => 'Str',
        reset               => 'Str',
        cs_begin            => 'Str',
        cs_end              => 'Str',
        cs_label            => 'Str',
        cs_separator        => 'Str',
        thousands_separator => 'Str',
    );
    my $options;
    if ( $caller eq 'new' ) {
        $options = [ keys %valid ];
    }
    else {
        $options = _routine_options( $caller );
    }
    return { map { $_ => $valid{$_} } @$options };
};


sub _defaults {
    return {
        alignment      => 0,
        all_by_default => 0,
        #busy_string   => undef,
        clear_screen   => 0,
        color          => 0,
        decoded        => 1,
        enchanted      => 1,
        hide_cursor    => 1,
        index          => 0,
        #info          => undef,
        #init_dir      => undef,
        #filter        => undef,
        keep_chosen    => 0,
        layout         => 1,
        #tabs_info     => undef,
        #tabs_prompt   => undef,
        add_dirs       => '[Choose-Dirs]',
        back           => 'BACK',
        show_files     => '[Show-Files]',
        confirm        => 'CONFIRM',
        parent_dir     => '..',
        #mark          => undef,
        mouse          => 0,
        order          => 1,
        prefix         => '',
        #prompt        => undef,
        reset          => 'reset',
        show_hidden    => 1,
        small_first    => 0,
        #solo          => undef,    # experimental
        cs_begin       => '',
        cs_end         => '',
        #cs_label      => undef,
        cs_separator   => ', ',
        thousands_separator => ',',
    };
};


sub _routine_options {
    my ( $caller ) = @_;
    my @every = ( qw( info prompt clear_screen mouse hide_cursor confirm back color tabs_info tabs_prompt cs_label ) );
    my $options;
    if ( $caller eq 'choose_directories' ) {
        $options = [ @every, qw( init_dir layout order alignment enchanted show_hidden parent_dir decoded add_dirs ) ];
    }
    elsif ( $caller eq 'choose_a_directory' ) {
        $options = [ @every, qw( init_dir layout order alignment enchanted show_hidden parent_dir decoded ) ];
    }
    elsif ( $caller eq 'choose_a_file' ) {
        $options = [ @every, qw( init_dir layout order alignment enchanted show_hidden parent_dir decoded show_files filter ) ];
    }
    elsif ( $caller eq 'choose_a_number' ) {
        $options = [ @every, qw( small_first reset thousands_separator ) ];
    }
    elsif ( $caller eq 'choose_a_subset' ) {
        $options = [ @every, qw( layout order alignment enchanted keep_chosen index prefix all_by_default cs_begin cs_end cs_separator mark busy_string solo ) ];
    }
    elsif ( $caller eq 'settings_menu' ) {
        $options = [ @every ];
    }
    return $options;
}


sub __prepare_path {
    my ( $self ) = @_;
    my $init_dir_fs;
    if ( $self->{decoded} ) {
        $init_dir_fs = encode 'locale_fs', $self->{init_dir};
    }
    else {
        $init_dir_fs = $self->{init_dir};
    }
    if ( defined $init_dir_fs && ! -d $init_dir_fs ) {
        my $prompt = 'Could not find the directory "';
        $prompt .= decode 'locale_fs', $init_dir_fs;
        $prompt .= '". Falling back to the home directory.';
        choose(
            [ 'Press ENTER to continue' ],
            { prompt => $prompt, hide_cursor => $self->{hide_cursor}, mouse => $self->{mouse} }
        );
        $init_dir_fs = File::HomeDir->my_home();
    }
    if ( ! defined $init_dir_fs ) {
        $init_dir_fs = File::HomeDir->my_home();
    }
    if ( ! -d $init_dir_fs ) {
        die "Could not find the home directory.";
    }
    return $init_dir_fs;
}


sub __available_dirs {
    my ( $self, $dir_fs ) = @_;
    my $dh;
    if ( ! eval {
        opendir( $dh, $dir_fs ) or die $!;
        1 }
    ) {
        print "$@";
        choose(
            [ 'Press Enter:' ],
            { prompt => '', hide_cursor => $self->{hide_cursor}, mouse => $self->{mouse} }
        );
        $dir_fs = dirname $dir_fs;
        next;
    }
    my @dirs_fs;
    while ( my $file_fs = readdir $dh ) {
        next if $file_fs =~ /^\.\.?\z/;
        next if $file_fs =~ /^\./ && ! $self->{show_hidden};
        push @dirs_fs, $file_fs if -d catdir $dir_fs, $file_fs;
    }
    closedir $dh;
    return [ sort @dirs_fs ];
}


sub choose_directories {
    if ( ref $_[0] ne __PACKAGE__ ) {
        my $ob = __PACKAGE__->new();
        delete $ob->{backup_instance_defaults};
        return $ob->choose_directories( @_ );
    }
    my ( $self, $opt ) = @_;
    if ( ! defined $opt->{cs_label} ) {
        $opt->{cs_label} = 'Dirs: ';
    }
    $self->__prepare_opt( $opt );
    my $init_dir_fs = $self->__prepare_path();
    my $dir_fs = realpath $init_dir_fs;
    my $chosen_dirs_fs = [];
    my ( $browse, $add_dirs ) = ( 'Browse', 'Add_Dirs' );
    my $mode = $browse;
    my @bu;

    while ( 1 ) {
        if ( $mode eq $browse ) {
            ( $dir_fs, my $to_add_dirs ) = $self->__choose_a_path( $dir_fs, { chosen_dirs_fs => $chosen_dirs_fs } );
            if ( ! defined $dir_fs ) {
                if ( @bu ) {
                    ( $dir_fs, $chosen_dirs_fs ) = @{pop @bu};
                    next;
                }
                $self->__restore_defaults();
                return;
            }
            elsif ( defined $to_add_dirs ) {
                $mode = $add_dirs;
                next;
            }
            else {
                my $chosen_dirs;
                if ( $self->{decoded} ) {
                    $chosen_dirs = [ map { decode 'locale_fs', $_ } @$chosen_dirs_fs ];
                }
                else {
                    $chosen_dirs = $chosen_dirs_fs;
                }
                $self->__restore_defaults();
                return $chosen_dirs;
            }
        }
        elsif ( $mode eq $add_dirs ) {
            my $avail_dirs_fs = $self->__available_dirs( $dir_fs );
            my $info = defined $self->{info} ? $self->{info} : '';
            if ( length $info ) {
                $info .= "\n";
            }
            my $cs_label_w = print_columns_ext( $self->{cs_label}, $self->{color} );
            $info .= line_fold(
                $self->{cs_label} . join( ', ', map { decode 'locale_fs', $_ } @$chosen_dirs_fs ), get_term_width(),
                { subseq_tab => ' ' x $cs_label_w, color => $self->{color}, join => 1 }
            );
            my $prompt = "\n" . 'CHOOSE directories in "' . decode( 'locale_fs', $dir_fs ) . '":' . "\n";
            my $bu_opt;
            my @used_options = qw(info prompt back confirm cs_label cs_begin index);
            for my $o ( @used_options ) {
                $bu_opt->{$o} = $self->{$o};
            }
            my $idxs = $self->choose_a_subset(
                [ sort map { decode 'locale_fs', $_ } @$avail_dirs_fs ],
                {   info => $info, prompt => $prompt, back => '<<', confirm => 'OK',
                    cs_begin => '+ ', cs_label => undef,
                    index => 1
                }
            );
            for my $o ( @used_options ) {
                $self->{$o} = $bu_opt->{$o};
            }
            if ( defined $idxs && @$idxs ) {
                push @bu, [ $dir_fs, [ @$chosen_dirs_fs ] ];
                push @$chosen_dirs_fs, map { catdir $dir_fs, $_ } @{$avail_dirs_fs}[@$idxs];
            }
            $mode = $browse;
            next;
        }
    }
}


sub choose_a_directory {
    if ( ref $_[0] ne __PACKAGE__ ) {
        my $ob = __PACKAGE__->new();
        delete $ob->{backup_instance_defaults};
        return $ob->choose_a_directory( @_ );
    }
    my ( $self, $opt ) = @_;
    if ( ! defined $opt->{cs_label} ) {
        $opt->{cs_label} = 'Dir: ';
    }
    $self->__prepare_opt( $opt );
    my $init_dir_fs = $self->__prepare_path();
    my $chosen_dir = $self->__choose_a_path( $init_dir_fs );
    $self->__restore_defaults();
    return $chosen_dir;
}


sub choose_a_file {
    if ( ref $_[0] ne __PACKAGE__ ) {
        my $ob = __PACKAGE__->new();
        delete $ob->{backup_instance_defaults};
        return $ob->choose_a_file( @_ );
    }
    my ( $self, $opt ) = @_;
    if ( ! defined $opt->{cs_label} ) {
        $opt->{cs_label} = 'File: ';
    }
    $self->__prepare_opt( $opt );
    my $init_dir_fs = $self->__prepare_path();
    my $chosen_file = $self->__choose_a_path( $init_dir_fs );
    $self->__restore_defaults();
    return $chosen_file;
}

sub __choose_a_path {
    my ( $self, $dir_fs, $opt ) = @_;
    my $sub =  ( caller( 1 ) )[3];
    $sub =~ s/^.+::(?:__)?([^:]+)\z/$1/;
    my @pre;
    my $enchanted_idx;
    if ( $sub eq 'choose_a_directory' ) {
        @pre = ( undef, $self->{confirm}, $self->{parent_dir} );
        $enchanted_idx = 2;
    }
    elsif ( $sub eq 'choose_a_file' ) {
        @pre = ( undef, $self->{show_files}, $self->{parent_dir} );
        $enchanted_idx = 2;
    }
    elsif ( $sub eq 'choose_directories' ) {
        @pre = ( undef, $self->{confirm}, $self->{add_dirs}, $self->{parent_dir} );
        $enchanted_idx = 3;
    }
    my $default_idx = $self->{enchanted} ? $enchanted_idx : 0;
    my $prev_dir_fs = $dir_fs;
    my $wildcard = ' ? ';

    while ( 1 ) {
        my ( $dh, @dirs );
        if ( ! eval {
            opendir( $dh, $dir_fs ) or die $!;
            1 }
        ) {
            print "$@";
            choose(
                [ 'Press Enter:' ],
                { prompt => '', hide_cursor => $self->{hide_cursor}, mouse => $self->{mouse} }
            );
            $dir_fs = dirname $dir_fs;
            next;
        }
        while ( my $file_fs = readdir $dh ) {
            next if $file_fs =~ /^\.\.?\z/;
            next if $file_fs =~ /^\./ && ! $self->{show_hidden};
            push @dirs, decode( 'locale_fs', $file_fs ) if -d catdir $dir_fs, $file_fs;
        }
        closedir $dh;
        my @tmp;
        if ( $sub eq 'choose_a_file' ) {
            push @tmp, $self->{cs_label} . decode( 'locale_fs', ( catfile $dir_fs, $wildcard ) );
            push @tmp, $self->{prompt} if defined $self->{prompt} && length $self->{prompt};
        }
        elsif ( $sub eq 'choose_directories' ) {
            my $cs_label_w = print_columns_ext( $self->{cs_label}, $self->{color} );
            push @tmp, line_fold(
                $self->{cs_label} . join( ', ', map { decode 'locale_fs', $_ } @{$opt->{chosen_dirs_fs}} ), get_term_width(),
                { subseq_tab => ' ' x $cs_label_w, color => $self->{color}, join => 0 }
            );
            my $prompt = defined $self->{prompt} ? $self->{prompt} : 'BROWSE directories';
            push @tmp, "\n" . $prompt . ' in "' . decode( 'locale_fs', $dir_fs ) . '":' . "\n";
        }
        else {
            push @tmp, $self->{cs_label} . decode( 'locale_fs', $dir_fs );
            push @tmp, $self->{prompt} if defined $self->{prompt} && length $self->{prompt};
        }
        my $lines = join( "\n", @tmp );
        # Choose
        my $choice = choose(
            [ @pre, sort( @dirs ) ],
            { info => $self->{info}, prompt => $lines, default => $default_idx, alignment => $self->{alignment},
              layout => $self->{layout}, order => $self->{order}, mouse => $self->{mouse},
              clear_screen => $self->{clear_screen}, hide_cursor => $self->{hide_cursor},
              color => $self->{color}, tabs_info => $self->{tabs_info}, tabs_prompt => $self->{tabs_prompt},
              undef => $self->{back} }
        );
        if ( ! defined $choice ) {
            return;
        }
        elsif ( $choice eq $self->{confirm} ) {
            return $self->{decode} ? decode( 'locale_fs', $prev_dir_fs ) : $prev_dir_fs;
        }
        elsif ( $choice eq $self->{show_files} ) {
            my $file_fs = $self->__a_file( $dir_fs, $wildcard );
            if ( ! length $file_fs ) {
                next;
            }
            return $self->{decode} ? decode( 'locale_fs', $file_fs ) : $file_fs;
        }
        elsif ( $choice eq $self->{add_dirs} ) {
            return $prev_dir_fs, 1;
        }
        if ( $choice eq $self->{parent_dir} ) {
            $dir_fs = dirname $dir_fs;
        }
        else {
            $dir_fs = catdir $dir_fs, encode( 'locale_fs', $choice )
        }
        if ( $prev_dir_fs eq $dir_fs ) {
            $default_idx = 0;
        }
        else {
            $default_idx = $self->{enchanted} ? $enchanted_idx : 0;
        }
        $prev_dir_fs = $dir_fs;
    }
}


sub __a_file {
    my ( $self, $dir_fs, $wildcard ) = @_;
    my $prev_dir_fs = '';
    my $chosen_file;

    while ( 1 ) {
        my @files_fs;
        if ( ! eval {
            if ( $self->{filter} ) {
                @files_fs = map { basename $_} grep { -e $_ } glob( catfile( $dir_fs, $self->{filter} ) );
            }
            else {
                opendir( my $dh, $dir_fs ) or die $!;
                @files_fs = readdir $dh;
                closedir $dh;
            }
        1 }
        ) {
            print "$@";
            choose(
                [ 'Press Enter:' ],
                { prompt => '', hide_cursor => $self->{hide_cursor}, mouse => $self->{mouse} }
            );
            return;
        }
        my @files;
        for my $file_fs ( @files_fs ) {
            next if $file_fs =~ /^\.\.?\z/;
            next if $file_fs =~ /^\./ && ! $self->{show_hidden};
            next if -d catdir $dir_fs, $file_fs; #
            push @files, decode( 'locale_fs', $file_fs );
        }
        my @tmp;
        if ( ! defined $self->{cs_label} ) {
            $self->{cs_label} = 'New: ';
        }
        push @tmp, $self->{cs_label} . decode( 'locale_fs', ( catfile $dir_fs, length $prev_dir_fs ? $prev_dir_fs : $wildcard ) );
        if ( defined $self->{prompt} && length $self->{prompt} ) {
            push @tmp, $self->{prompt};
        }
        my $lines = join( "\n", @tmp );
        if ( ! @files ) {
            my $prompt;
            if ( $self->{filter} ) {
                $prompt = 'No matches for "' .  $self->{filter} . '".';
            }
            else {
                $prompt = 'No files.';
            }
            choose(
                [ ' < ' ],
                { info => $self->{info}, prompt => "$lines\n$prompt", hide_cursor => $self->{hide_cursor},
                  mouse => $self->{mouse}, color => $self->{color} }
            );
            return;
        }
        my @pre = ( undef );
        if ( $chosen_file ) {
            push @pre, $self->{confirm};
        }
        # Choose
        $chosen_file = choose(
            [ @pre, sort( @files ) ],
            { info => $self->{info}, prompt => $lines, alignment => $self->{alignment},
              layout => $self->{layout}, order => $self->{order}, mouse => $self->{mouse},
              clear_screen => $self->{clear_screen}, hide_cursor => $self->{hide_cursor},
              color => $self->{color}, tabs_info => $self->{tabs_info}, tabs_prompt => $self->{tabs_prompt},
              undef => $self->{back} }
        );
        if ( ! length $chosen_file ) {
            if ( length $prev_dir_fs ) {
                $prev_dir_fs = '';
                next;
            }
            return;
        }
        elsif ( $chosen_file eq $self->{confirm} ) {
            return if ! length $prev_dir_fs;
            return catfile $dir_fs, $prev_dir_fs;
        }
        else {
            $prev_dir_fs = encode( 'locale_fs', $chosen_file );
        }
    }
}


sub choose_a_number {
    if ( ref $_[0] ne __PACKAGE__ ) {
        my $ob = __PACKAGE__->new();
        delete $ob->{backup_instance_defaults};
        return $ob->choose_a_number( @_ );
    }
    my ( $self, $digits, $opt ) = @_;
    if ( ref $digits ) {
        $opt = $digits;
        $digits = 7;
    }
    $self->__prepare_opt( $opt );
    my $tab   = '  -  ';
    my $tab_w = print_columns( $tab );
    my $sep_w = print_columns_ext( $self->{thousands_separator}, $self->{color} );
    my $longest = $digits + int( ( $digits - 1 ) / 3 ) * $sep_w;
    my @ranges = ();
    for my $di ( 0 .. $digits - 1 ) {
        my $begin = 1 . '0' x $di;
        $begin = 0 if $di == 0;
        $begin = insert_sep( $begin, $self->{thousands_separator} );
        ( my $end = $begin ) =~ s/^[01]/9/;
        unshift @ranges,  unicode_sprintf( $begin, $longest, { right_justify => 1, color => $self->{color} } )
                               . $tab
                               . unicode_sprintf( $end, $longest, { right_justify => 1, color => $self->{color} } );
    }
    my $back_tmp    = unicode_sprintf( $self->{back},    $longest * 2 + $tab_w + 1, { color => $self->{color} } );
    my $confirm_tmp = unicode_sprintf( $self->{confirm}, $longest * 2 + $tab_w + 1, { color => $self->{color} } );
    if ( print_columns_ext( $ranges[0], $self->{color} ) > get_term_width() ) {
        @ranges = ();
        for my $di ( 0 .. $digits - 1 ) {
            my $begin = 1 . '0' x $di;
            $begin = 0 if $di == 0;
            $begin = insert_sep( $begin, $self->{thousands_separator} );
            unshift @ranges, unicode_sprintf( $begin, $longest, { color => $self->{color} } );
        }
        $confirm_tmp = $self->{confirm};
        $back_tmp    = $self->{back};
    }
    my %numbers;
    my $result;

    NUMBER: while ( 1 ) {
        my $cs_row;
        if ( defined $self->{cs_label} || length $result ) {
            my $tmp_result = length $result ? $result : '';
            my $tmp_cs_label = defined $self->{cs_label} ? $self->{cs_label} : '';
            $cs_row = sprintf(  "%s%*s", $tmp_cs_label, $longest, $tmp_result );
            if ( print_columns( $cs_row ) > get_term_width() ) {
                $cs_row = $tmp_result;
            }
        }
        my @tmp;
        if ( defined $cs_row ) {
            push @tmp, $cs_row;
        }
        if ( length $self->{prompt} ) {
            push @tmp, $self->{prompt};
        }
        my $lines = join "\n", @tmp;
        my @pre = ( undef, $confirm_tmp ); # confirm if $result ?
        # Choose
        my $range = choose(
            $self->{small_first} ? [ @pre, reverse @ranges ] : [ @pre, @ranges ],
            { info => $self->{info}, prompt => $lines, layout => 3, alignment => 1, mouse => $self->{mouse},
              clear_screen => $self->{clear_screen}, hide_cursor => $self->{hide_cursor}, color => $self->{color},
              tabs_info => $self->{tabs_info}, tabs_prompt => $self->{tabs_prompt}, undef => $back_tmp }
        );
        if ( ! defined $range ) {
            if ( defined $result ) {
                $result = undef;
                %numbers = ();
                next NUMBER;
            }
            else {
                $self->__restore_defaults();
                return;
            }
        }
        if ( $range eq $confirm_tmp ) {
            if ( $self->{thousands_separator} ne '' && defined $result ) {
                $result =~ s/\Q$self->{thousands_separator}\E//g;
            }
            $self->__restore_defaults();
            return $result;
        }
        my $zeros = ( split /\s*-\s*/, $range )[0];
        $zeros =~ s/^\s*\d//;
        my $zeros_no_sep;
        if ( $self->{thousands_separator} eq '' ) {
            $zeros_no_sep = $zeros;
        }
        else {
            ( $zeros_no_sep = $zeros ) =~ s/\Q$self->{thousands_separator}\E//g;
        }
        my $count_zeros = length $zeros_no_sep;
        my @choices = $count_zeros ? map( $_ . $zeros, 1 .. 9 ) : ( 0 .. 9 );
        # Choose
        my $number = choose(
            [ undef, @choices, $self->{reset} ],
            { info => $self->{info}, prompt => $lines, layout => 1, alignment => 2, order => 0,
              mouse => $self->{mouse}, clear_screen => $self->{clear_screen}, hide_cursor => $self->{hide_cursor},
              color => $self->{color}, tabs_info => $self->{tabs_info}, tabs_prompt => $self->{tabs_prompt},
              undef => '<<' }
        );
        next if ! defined $number;
        if ( $number eq $self->{reset} ) {
            delete $numbers{$count_zeros};
        }
        else {
            $number =~ s/\Q$self->{thousands_separator}\E//g if $self->{thousands_separator} ne '';
            $numbers{$count_zeros} = $number;
        }
        $result = sum( @numbers{keys %numbers} );
        $result = insert_sep( $result, $self->{thousands_separator} );
    }
}


sub choose_a_subset {
    if ( ref $_[0] ne __PACKAGE__ ) {
        my $ob = __PACKAGE__->new();
        delete $ob->{backup_instance_defaults};
        return $ob->choose_a_subset( @_ );
    }
    my ( $self, $available, $opt ) = @_;
    $self->__prepare_opt( $opt );
    my $new_idx = [];
    my $curr_avail = [ @$available ];
    my $bu = [];
    my @pre = ( undef, $self->{confirm} );

    while ( 1 ) {
        my @tmp;
        my $cs;
        if ( defined $self->{cs_label} ) {
            $cs .= $self->{cs_label};
        }
        if ( @$new_idx ) {
            $cs .= $self->{cs_begin} . join( $self->{cs_separator}, map { defined $_ ? $_ : '' } @{$available}[@$new_idx] ) . $self->{cs_end};
        }
        elsif ( $opt->{all_by_default} ) {
            $cs .= $self->{cs_begin} . '*' . $self->{cs_end};
        }
        if ( defined $cs ) {
            @tmp = ( $cs );
        }
        if ( length $self->{prompt} ) {
            push @tmp, $self->{prompt};
        }
        my $mark;
        my $solo;
        if ( defined $self->{solo} ) {
            $solo = [ map { $_ + @pre } @{$self->{solo}} ];
            if ( defined $self->{mark} && @{$self->{mark}} ) {
                for my $m ( map { $_ + @pre } @{$self->{mark}} ) {
                    next if any { $m == $_ } @$solo;    # solo elements are not markable with the SpaceBar
                    push @$mark, $m;
                }
            }
        }
        else {
            if ( defined $self->{mark} && @{$self->{mark}} ) {
                $mark = [ map { $_ + @pre } @{$self->{mark}} ];
            }
        }
        my $meta_items = [ 0 .. $#pre, @{$solo||[]} ];
        my $lines = join "\n", @tmp;
        # Choose
        my @idx = choose(
            [ @pre, map { $self->{prefix} . ( defined $_ ? $_ : '' ) } @$curr_avail ],
            { info => $self->{info}, prompt => $lines, layout => $self->{layout}, index => 1,
              alignment => $self->{alignment}, order => $self->{order}, mouse => $self->{mouse},
              meta_items => $meta_items, mark => $mark, include_highlighted => 2,
              clear_screen => $self->{clear_screen}, hide_cursor => $self->{hide_cursor},
              color => $self->{color}, tabs_info => $self->{tabs_info}, tabs_prompt => $self->{tabs_prompt},
              undef => $self->{back}, busy_string => $self->{busy_string} }
        );
        $self->{mark} = $mark = undef;
        if ( ! defined $idx[0] || $idx[0] == 0 ) {
            if ( @$bu ) {
                ( $curr_avail, $new_idx ) = @{pop @$bu};
                next;
            }
            $self->__restore_defaults();
            return;
        }
        if ( defined $self->{solo} ) {
            my $solo_idx;
            for my $i ( @idx ) {                    # Experimental (may be removed):
                if ( any { $_ == $i } @$solo ) {    # If a solo element is chosen, it is returned solo. Only one solo
                    $solo_idx = $i - @pre;          # element can be chosen, because the SpaceBar doesn't work for solo
                    last;                           # elements. Other elements marked with the SpaceBar are ignored when
                }                                   # a solo element is chosen.
            }                                       # A chosen solo element returns immediately (without a CONFIRM)
            if ( defined $solo_idx ) {
                my $return_indexes = $self->{index}; # because __restore_defaults resets $self->{index}
                $self->__restore_defaults();
                return [ $return_indexes ? $solo_idx : $available->[ $solo_idx ] ];
            }
        }
        push @$bu, [ [ @$curr_avail ], [ @$new_idx ] ];
        my $ok;
        if ( $idx[0] == $#pre ) {
            $ok = shift @idx;
        }
        my @tmp_idx;
        for my $i ( reverse @idx ) {
            $i -= @pre;
            if ( ! $self->{keep_chosen} ) {
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
            if ( ! @$new_idx && $opt->{all_by_default} ) {
                if ( defined $self->{solo} ) {
                    for my $e ( 0 .. $#{$available} ) {
                        next if any { $e == $_ } @{$self->{solo}};
                        push @$new_idx, $e;
                    }
                }
                else {
                    $new_idx = [ 0 .. $#{$available} ];
                }
            }
            my $return_indexes = $self->{index}; # because __restore_defaults resets $self->{index}
            $self->__restore_defaults();
            return $return_indexes ? $new_idx : [ @{$available}[@$new_idx] ];
        }
    }
}


sub settings_menu {
    if ( ref $_[0] ne __PACKAGE__ ) {
        my $ob = __PACKAGE__->new();
        delete $ob->{backup_instance_defaults};
        return $ob->settings_menu( @_ );
    }
    my ( $self, $menu, $curr, $opt ) = @_;
    $self->__prepare_opt( $opt );
    if ( ! defined $self->{prompt} ) {
        $self->{prompt} = 'Choose:'; # choose default prompt
    }
    my $longest = 0;
    my $new     = {};
    my $name_w  = {};
    for my $sub ( @$menu ) {
        my ( $key, $name ) = @$sub;
        $name_w->{$key} = print_columns_ext( $name, $self->{color} );
        $longest      = $name_w->{$key} if $name_w->{$key} > $longest;
        $curr->{$key} = 0       if ! defined $curr->{$key};
        $new->{$key}  = $curr->{$key};
    }
    my @print_keys;
    for my $sub ( @$menu ) {
        my ( $key, $name, $values ) = @$sub;
        my $current = $values->[$new->{$key}];
        push @print_keys, $name . ( ' '  x ( $longest - $name_w->{$key} ) ) . " [$current]";
    }
    my @pre = ( undef, $self->{confirm} );
    $ENV{TC_RESET_AUTO_UP} = 0;
    my $default = 0;
    my $count = 0;

    while ( 1 ) {
        my @tmp;
        if ( defined $self->{cs_label} ) {
            push @tmp, $self->{cs_label} . '' . join( ', ', map { "$_=$new->{$_}" } keys %$new ) . '';
        }
        if ( defined $self->{prompt} && length $self->{prompt} ) {
            push @tmp, $self->{prompt};
        }
        my $lines = join( "\n", @tmp );
        # Choose
        my $idx = choose(
            [ @pre, @print_keys ],
            { info => $self->{info}, prompt => $lines, index => 1, default => $default, layout => 3, alignment => 0,
              mouse => $self->{mouse}, clear_screen => $self->{clear_screen}, hide_cursor => $self->{hide_cursor},
              color => $self->{color}, tabs_info => $self->{tabs_info}, tabs_prompt => $self->{tabs_prompt},
              undef => $self->{back} }
        );
        if ( ! $idx ) {
            $self->__restore_defaults();
            return;
        }
        elsif ( $idx == $#pre ) {
            my $change = 0;
            for my $sub ( @$menu ) {
                my $key = $sub->[0];
                if ( $curr->{$key} == $new->{$key} ) {
                    next;
                }
                $curr->{$key} = $new->{$key};
                $change++;
            }
            $self->__restore_defaults();
            return $change; #
        }
        my $i = $idx - @pre;
        my $key    = $menu->[$i][0];
        my $values = $menu->[$i][2];
        if ( $default == $idx ) {
            if ( $ENV{TC_RESET_AUTO_UP} ) {
                $count = 0;
            }
            elsif ( $count == @$values ) {
                $default = 0;
                $count = 0;
                next;
            }
        }
        else {
            $count = 0;
            $default = $idx;
        }
        ++$count;
        my $curr_value = $values->[$new->{$key}];
        $new->{$key}++;
        if ( $new->{$key} == @$values ) {
            $new->{$key} = 0;
        }
        my $new_value = $values->[$new->{$key}];
        $print_keys[$i] =~ s/  \[ \Q$curr_value\E \] \z /[$new_value]/x;
    }
}



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


sub get_term_size {
    require Term::Choose::Screen;
    return Term::Choose::Screen::get_term_size();
}


sub get_term_width {
    require Term::Choose::Screen;
    my $term_width = ( Term::Choose::Screen::get_term_size() )[0];
    return $term_width;
}

sub get_term_height {
    require Term::Choose::Screen;
    my $term_height = ( Term::Choose::Screen::get_term_size() )[1];
    return $term_height;
}


sub unicode_sprintf {
    my ( $str, $avail_w, $opt ) = @_;
    $opt ||= {};
    my $colwidth;
    if ( $opt->{color} ) {
        ( my $tmp = $str ) =~ s/\e\[[\d;]*m//g;
        $colwidth = print_columns( $tmp );
    }
    else {
        $colwidth = print_columns( $str );
    }
    #my $colwidth = print_columns_ext( $str, $opt->{color} );
    if ( $colwidth > $avail_w ) {
        if ( @{$opt->{mark_if_truncated}||[]} ) {
            return cut_to_printwidth( $str, $avail_w - $opt->{mark_if_truncated}[1] ) . $opt->{mark_if_truncated}[0];
        }
        return cut_to_printwidth( $str, $avail_w );
    }
    elsif ( $colwidth < $avail_w ) {
        if ( $opt->{right_justify} ) {
            return " " x ( $avail_w - $colwidth ) . $str;
        }
        else {
            return $str . " " x ( $avail_w - $colwidth );
        }
    }
    else {
        return $str;
    }
}


sub print_columns_ext {
    my ( $str, $color ) = @_;
    if ( $color ) {
        $str =~ s/\e\[[\d;]*m//g;
    }
    return print_columns( $str );
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Choose::Util - TUI-related functions for selecting directories, files, numbers and subsets of lists.

=head1 VERSION

Version 0.119

=cut

=head1 SYNOPSIS

Functional interface:

    use Term::Choose::Util qw( choose_a_directory );

    my $chosen_directory = choose_a_directory();

Object-oriented interface:

    use Term::Choose::Util;

    my $ob = Term::Choose->new ();

    my $chosen_directory = $ob->choose_a_directory();


See L</SUBROUTINES>.

=head1 DESCRIPTION

This module provides TUI-related functions for selecting directories, files, numbers and subsets of lists.

=head1 EXPORT

Nothing by default.

=head1 SUBROUTINES

Values in brackets are default values.

Options are passed as a hash reference. The options argument is the last (or the only) argument.

=head3 Options available for all subroutines

=over

=item

clear_screen

If enabled, the screen is cleared before the output.

Values: [0],1,2.

=item

color

Setting I<color> to C<1> enables the support for color and text formatting escape sequences except for the current
selected element. If set to C<2>, also for the current selected element the color support is enabled (inverted colors).

Values: [0],1,2.

=item

hide_cursor

Hide the cursor

Values: 0,[1].

=item

info

A string placed on top of of the output.

Default: undef

=item

mouse

Enable the mouse mode. An item can be chosen with the left mouse key, the right mouse key can be used instead of the
SpaceBar key.

Values: [0],1.

=item

cs_label

The value of I<cs_label> (current selection label) is a string which is placed in front of the current selection.

Defaults: C<choose_directories>: 'Dirs: ', C<choose_a_directory>: 'Dir: ', C<choose_a_file>: 'File: '. For
C<choose_a_number>, C<choose_a_subset> and C<settings_menu> the default is undefined.

The current selection output is placed between the I<info> string and the I<prompt> string.

=item

prompt

A string placed on top of the available choices.

Default: undef

=item

back

Customize the string of the menu entry "I<back>".

Default: C<BACK>

=item

confirm

Customize the string of the menu entry "I<confirm>".

Default: C<CONFIRM>.

=back

=head2 new

    $ob = Term::Choose::Util->new( { mouse => 1, ... } );

Returns a new Term::Choose::Util object.

Options: all

=head2 choose_a_directory

    $chosen_directory = choose_a_directory( { layout => 1, ... } )

With C<choose_a_directory> the user can browse through the directory tree and choose a directory which is then returned.

To move around in the directory tree:

- select a directory and press C<Return> to enter in the selected directory.

- choose the "I<parent_dir>" menu entry to move upwards.

To return the current working-directory as the chosen directory choose the "I<confirm>" menu entry.

The "I<back>" menu entry causes C<choose_a_directory> to return nothing.

Options:

=over

=item

alignment

Elements in columns are aligned to the left if set to C<0>, aligned to the right if set to C<1> and centered if set to
C<2>.

Values: [0],1,2.

=item

decoded

If enabled, the directory name is returned decoded with C<locale_fs> form L<Encode::Locale>.

Values: 0,[1].

=item

enchanted

If set to C<1>, the default cursor position is on the "I<parent_dir>" menu entry. If the directory name remains the same after an
user input, the default cursor position changes to "I<back>".

If set to C<0>, the default cursor position is on the "I<back>" menu entry.

Values: 0,[1].

=item

init_dir

Set the starting point directory. Defaults to the home directory.

If the option I<decoded> is enabled (default), I<init_dir> expects the directory path as a decoded string.

=item

layout

See the option I<layout> in L<Term::Choose>

Values: 0,[1],2,3.

=item

order

If set to C<1>, the items are ordered vertically else they are ordered horizontally.

This option has no meaning if I<layout> is set to C<3>.

Values: 0,[1].

=item

show_hidden

If enabled, hidden directories are added to the available directories.

Values: 0,[1].

=item

parent_dir

Customize the string of the menu entry "I<parent_dir>".

Default: C<..>

=back

=head2 choose_a_file

    $chosen_file = choose_a_file( { show_hidden => 0, ... } )

Browse the directory tree the same way as described for C<choose_a_directory>. Select the "I<show_files>" menu entry to get the
files of the current directory. To return the chosen file select the "I<confirm>" menu entry.

Options as in L</choose_a_directory> plus

=over

=item

filter

If set, the value of this option is used as a glob pattern. Only files matching this pattern will be displayed.

=item

show_files

Customize the string of the menu entry "I<show_files>".

Default: C<[Show-Files]>

=back

=head2 choose_directories

    $chosen_directories = choose_directories( { mouse => 1, ... } )

C<choose_directories> is similar to C<choose_a_directory> but it is possible to return multiple directories.

Selecting the  "I<add_dirs>" menu entry opens the add-directories sub menu: one can add there directories from the
current working directory to the list of chosen directories.

To return the list of chosen directories (as an array reference) select the "I<confirm>" entry in main menu.

The "I<back>" menu entry removes the last added directories. If the list of chosen directories is empty, "I<back>" causes
C<choose_directories> to return nothing.

Options as in L</choose_a_directory> plus

=over

=item

add_dirs

Customize the string of the menu entry "I<add_dirs>".

Default: C<[Choose-Dirs]>

=back

=head2 choose_a_number

    $new = choose_a_number( 5, { cs_label => 'Number: ', ... }  );

This function lets you choose/compose a number (unsigned integer) which is returned.

The fist argument is an integer and determines the range of the available numbers. For example setting the
first argument to 4 would offer a range from 0 to 9999.

Options:

=over

=item

small_first

Put the small number ranges on top.

=item

thousands_separator

Sets the thousands separator.

Default: C<,>

=back

The I<current-selection> line is shown if I<cs_label> is defined or as soon as a number has been chosen.

=head2 choose_a_subset

    $subset = choose_a_subset( \@available_items, { cs_label => 'new> ', ... } )

C<choose_a_subset> lets you choose a subset from a list.

The first argument is a reference to an array which provides the available list.

Options:

=over

=item

all_by_default

If enabled, all elements are selected if CONFIRM is chosen without any selected elements.

Values: [0],1.

=item

alignment

Elements in columns are aligned to the left if set to C<0>, aligned to the right if set to C<1> and centered if set to
C<2>.

Values: [0],1,2.

=item

index

If true, the index positions in the available list of the made choices are returned.

Values: [0],1.

=item

keep_chosen

If enabled, the chosen items are not removed from the available choices.

Values: [0],1;

=item

layout

See the option I<layout> in L<Term::Choose>.

Values: 0,1,2,[3].

=item

mark

Expects as its value a reference to an array with indexes. Elements corresponding to these indexes are pre-selected when
C<choose_a_subset> is called.

=item

order

If set to C<1>, the items are ordered vertically else they are ordered horizontally.

This option has no meaning if I<layout> is set to 3.

Values: 0,[1].

=item

prefix

I<prefix> expects as its value a string. This string is put in front of the elements of the available list in the menu.
The chosen elements are returned without this I<prefix>.

Default: empty string.

=item

cs_begin

Current selection: the I<cs_begin> string is placed between the I<cs_label> string and the chosen elements as soon as an
element has been chosen.

Default: empty string

=item

cs_separator

Current selection: the I<cs_separator> is placed between the chosen list elements.

Default: C< ,>

=item

cs_end

Current selection: as soon as elements have been chosen the I<cs_end> string is placed at the end of the chosen elements.

Default: empty string

=back

The current-selection line is shown if I<cs_label> is defined or as soon as elements have been chosen.

To return the chosen subset (as an array reference) select the "I<confirm>" menu entry.

The "I<back>" menu entry removes the last added chosen items. If the list of chosen items is empty, "I<back>" causes
C<choose_a_subset> to return nothing.

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

the unique name of the option

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

When C<settings_menu> is called, it displays for each array entry a row with the prompt string and the current value.
It is possible to scroll through the rows. If a row is selected, the set and displayed value changes to the next. After
scrolling through the list once the cursor jumps back to the top row.

If the "I<back>" menu entry is chosen, C<settings_menu> does not apply the made changes and returns nothing. If the
"I<confirm>" menu entry is chosen, C<settings_menu> applies the made changes in place to the passed configuration
hash-reference (second argument) and returns the number of made changes.

Setting the option I<cs_label> to a defined value adds an info output line.

=head1 REQUIREMENTS

=head2 Perl version

Requires Perl version 5.8.3 or greater.

=head2 Encoding layer

Ensure the encoding layer for STDOUT, STDERR and STDIN are set to the correct value.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::Choose::Util

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
