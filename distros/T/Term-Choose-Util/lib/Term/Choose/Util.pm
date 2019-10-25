package Term::Choose::Util;

use warnings;
use strict;
use 5.008003;

our $VERSION = '0.104';
use Exporter 'import';
our @EXPORT_OK = qw( choose_a_directory choose_a_file choose_directories choose_a_number choose_a_subset settings_menu
                     insert_sep get_term_size get_term_width get_term_height unicode_sprintf
                     choose_a_dir choose_dirs ); # 21.09.2019    # after transition -> remove

use Carp                  qw( croak );
use Cwd                   qw( realpath );
use Encode                qw( decode encode );
use File::Basename        qw( dirname );
use File::Spec::Functions qw( catdir catfile );
use List::Util            qw( sum );

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

    ############################################################### 21.09.2019 # after transition -> remove,
    if ( ! defined $opt->{init_dir} && defined $opt->{dir} ) {
        $opt->{init_dir} = $opt->{dir};
    }
    if ( ! defined $opt->{parent_dir} && defined $opt->{up} ) {
        $opt->{parent_dir} = $opt->{up};
    }
    if ( ! defined $opt->{current_selection_label} && defined $opt->{name} ) {
        $opt->{current_selection_label} = $opt->{name};
    }
    if ( ! defined $opt->{alignment} && defined $opt->{justify} ) {
        $opt->{alignment} = $opt->{justify};
    }
    if ( ! defined $opt->{thousands_separator} && defined $opt->{thsd_sep} ) {
        $opt->{thousands_separator} = $opt->{thsd_sep};
    }
    if ( ! defined $opt->{current_selection_begin} && defined $opt->{sofar_begin} ) {
        $opt->{current_selection_begin} = $opt->{sofar_begin};
    }
    if ( ! defined $opt->{current_selection_separator} && defined $opt->{sofar_separator} ) {
        $opt->{current_selection_separator} = $opt->{sofar_separator};
    }
    if ( ! defined $opt->{current_selection_end} && defined $opt->{sofar_end} ) {
        $opt->{current_selection_end} = $opt->{sofar_end};
    }
    ###############################################################

    if ( %$opt ) {
        my $sub =  ( caller( 1 ) )[3];
        $sub =~ s/^.+::(?:__)?([^:]+)\z/$1/;
        validate_options( _valid_options( $sub ), $opt );
        for my $key ( keys %$opt ) {
            $self->{$key} = $opt->{$key} if defined $opt->{$key};
        }
    }
}


sub _valid_options {
    my ( $caller ) = @_;
    my %valid = (
        all_by_default => '[ 0 1 ]',
        clear_screen   => '[ 0 1 ]',
        color          => '[ 0 1 ]',
        decoded        => '[ 0 1 ]',
        enchanted      => '[ 0 1 ]',
        hide_cursor    => '[ 0 1 ]',
        index          => '[ 0 1 ]',
        keep_chosen    => '[ 0 1 ]',
        mouse          => '[ 0 1 2 3 4 ]',     # 05.09.2019    # after transition -> '[ 0 1 ]',
        order          => '[ 0 1 ]',
        show_hidden    => '[ 0 1 ]',
        small_first    => '[ 0 1 ]',
        alignment      => '[ 0 1 2 ]',
        layout         => '[ 0 1 2 3 ]',
        lf             => 'ARRAY',
        mark           => 'ARRAY',
        info           => 'Str',
        init_dir       => 'Str',
        add_dir        => 'Str',
        back           => 'Str',
        show_files     => 'Str',
        confirm        => 'Str',
        parent_dir     => 'Str',
        prefix         => 'Str',
        prompt         => 'Str',
        reset          => 'Str',
        current_selection_begin     => 'Str',
        current_selection_end       => 'Str',
        current_selection_label     => 'Str',
        current_selection_separator => 'Str',
        thousands_separator         => 'Str',
        ####################### 21.09.2019    # after transition -> remove
        dir             => 'Str',
        name            => 'Str',
        up              => 'Str',
        justify         => '[ 0 1 2 ]',
        thsd_sep        => 'Str',
        sofar_begin     => 'Str',
        sofar_end       => 'Str',
        sofar_separator => 'Str',
        #######################
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
        all_by_default => 1,
        clear_screen   => 0,
        color          => 0,
        decoded        => 1,
        enchanted      => 1,
        hide_cursor    => 1,
        index          => 0,
        #info          => undef,
        #init_dir      => undef
        keep_chosen    => 0,
        layout         => 1,
        #lf            => undef,
        add_dir        => 'ADD_DIR',
        back           => 'BACK',
        show_files     => 'SHOW_FILES',
        confirm        => 'CONFIRM',
        parent_dir     => 'PARENT_DIR',
        #mark          => undef,
        mouse          => 0,
        order          => 1,
        prefix         => '',
        #prompt        => undef,
        reset          => 'reset',
        show_hidden    => 1,
        small_first    => 0,
        current_selection_begin     => '',
        current_selection_end       => '',
        #current_selection_label    => undef,
        current_selection_separator => ', ',
        thousands_separator         => ',',

    };
};


sub _routine_options {
    my ( $caller ) = @_;
    my @every = ( qw( info prompt clear_screen mouse hide_cursor confirm back color lf current_selection_label
                  dir name justify up thsd_sep sofar_begin sofar_end sofar_separator ) ); # 21.09.2019    # after transition remove: dir name justify up thsd_sep sofar_begin sofar_end sofar_separator
    my $options;
    if ( $caller eq 'choose_directories' ) {
        $options = [ @every, qw( init_dir layout order alignment enchanted show_hidden parent_dir decoded add_dir ) ];
    }
    elsif ( $caller eq 'choose_a_directory' ) {
        $options = [ @every, qw( init_dir layout order alignment enchanted show_hidden parent_dir decoded ) ];
    }
    elsif ( $caller eq 'choose_a_file' ) {
        $options = [ @every, qw( init_dir layout order alignment enchanted show_hidden parent_dir decoded show_files ) ];
    }
    elsif ( $caller eq 'choose_a_number' ) {
        $options = [ @every, qw( small_first reset thousands_separator) ];
    }
    elsif ( $caller eq 'choose_a_subset' ) {
        $options = [ @every, qw( layout order alignment enchanted keep_chosen index prefix all_by_default current_selection_begin current_selection_end current_selection_separator mark ) ];
    }
    elsif ( $caller eq 'settings_menu' ) {
        $options = [ @every ];
    }
    return $options;
}


sub __prepare_path {
    my ( $self ) = @_;
    my $init_dir;
    if ( $self->{decoded} ) {
        $init_dir = encode( 'locale_fs', $self->{init_dir} );
    }
    else {
        $init_dir = $self->{init_dir};
    }
    if ( defined $init_dir && ! -d $init_dir ) {
        my $prompt = "Could not find the directory \"$init_dir\". Falling back to the home directory.";
        choose(
            [ 'Press ENTER to continue' ],
            { prompt => $prompt, hide_cursor => $self->{hide_cursor}, mouse => $self->{mouse} }
        );
        $init_dir = File::HomeDir->my_home();
    }
    if ( ! defined $init_dir ) {
        $init_dir = File::HomeDir->my_home();
    }
    if ( ! -d $init_dir ) {
        die "Could not find the home directory.";
    }
    return $init_dir;
}


sub _prepare_string { decode( 'locale_fs', shift ) }


############################################################################# 21.09.2019    # after transition -> remove
sub choose_dirs {
    croak "'choose_dirs' is not a method and deprecated. Use 'choose_directories' instead." if ref $_[0] eq __PACKAGE__;
    my $ob = __PACKAGE__->new();
    delete $ob->{backup_instance_defaults};
    return $ob->choose_directories( @_ );
}
sub choose_a_dir {
    croak "'choose_a_dir' is not a method and deprecated. Use 'choose_a_directory' instead." if ref $_[0] eq __PACKAGE__;
    my $ob = __PACKAGE__->new();
    delete $ob->{backup_instance_defaults};
    return $ob->choose_a_directory( @_ );
}
########################################################################################################################


sub choose_directories {
    if ( ref $_[0] ne __PACKAGE__ ) {
        my $ob = __PACKAGE__->new();
        delete $ob->{backup_instance_defaults};
        return $ob->choose_directories( @_ );
    }
    my ( $self, $opt ) = @_;
    $self->__prepare_opt( $opt );
    my $init_dir = $self->__prepare_path();
    my $new = [];
    my $dir = realpath $init_dir;
    my $prev_encoded = $dir;
    my @pre = ( undef, $self->{confirm}, $self->{add_dir}, $self->{parent_dir} );
    my $default_idx = $self->{enchanted}  ? $#pre : 0;

    while ( 1 ) {
        my ( $dh, @dirs );
        if ( ! eval {
            opendir( $dh, $dir ) or die $!;
            1 }
        ) {
            print "$@";
            choose(
                [ 'Press Enter:' ],
                { prompt => '', hide_cursor => $self->{hide_cursor}, mouse => $self->{mouse} }
            );
            $dir = dirname $dir;
            next;
        }
        while ( my $file = readdir $dh ) {
            next if $file =~ /^\.\.?\z/;
            next if $file =~ /^\./ && ! $self->{show_hidden};
            push @dirs, decode( 'locale_fs', $file ) if -d catdir $dir, $file;
        }
        closedir $dh;
        my @tmp;
        if ( ! defined $self->{current_selection_label} ) {
            $self->{current_selection_label} = 'Dirs: ';
        }
        push @tmp, $self->{current_selection_label} . join( ', ', map { s/ /\ /g; $_ } @$new ) . '    <<-add-dir-' . decode( 'locale_fs', "[ $prev_encoded ]" );
        if ( length $self->{prompt} ) {
            push @tmp, $self->{prompt};
        }
        my $lines = join( "\n", @tmp );
        # Choose
        my $choice = choose(
            [ @pre, sort( @dirs ) ],
            { info => $self->{info}, prompt => $lines, default => $default_idx, alignment => $self->{alignment},
              layout => $self->{layout}, order => $self->{order}, mouse => $self->{mouse},
              clear_screen => $self->{clear_screen}, hide_cursor => $self->{hide_cursor},
              color => $self->{color}, lf => $self->{lf}, undef => $self->{back} }
        );
        if ( ! defined $choice ) {
            if ( @$new ) {
                pop @$new;
                $default_idx = 0;
                next;
            }
            $self->__restore_defaults();
            return;
        }
        $default_idx = $self->{enchanted}  ? $#pre : 0;
        if ( $choice eq $self->{confirm} ) {
            $self->__restore_defaults();
            return $new;
        }
        elsif ( $choice eq $self->{add_dir} ) {
            if ( $self->{decoded} ) {
                push @$new, decode( 'locale_fs', $prev_encoded );
            }
            else {
                push @$new, $prev_encoded;
            }
            $dir = dirname $dir;
            $default_idx = 0 if $prev_encoded eq $dir;
            $prev_encoded = $dir;
            next;
        }
        $dir = $choice eq $self->{parent_dir} ? dirname( $dir ) : catdir( $dir, encode 'locale_fs', $choice );
        $default_idx = 0 if $prev_encoded eq $dir;
        $prev_encoded = $dir;
    }
}


sub choose_a_directory {
    if ( ref $_[0] ne __PACKAGE__ ) {
        my $ob = __PACKAGE__->new();
        delete $ob->{backup_instance_defaults};
        return $ob->choose_a_directory( @_ );
    }
    my ( $self, $opt ) = @_;
    $self->__prepare_opt( $opt );
    my $init_dir = $self->__prepare_path();
    return $self->__choose_a_path( $init_dir, 0 );
}

sub choose_a_file {
    if ( ref $_[0] ne __PACKAGE__ ) {
        my $ob = __PACKAGE__->new();
        delete $ob->{backup_instance_defaults};
        return $ob->choose_a_file( @_ );
    }
    my ( $self, $opt ) = @_;
    $self->__prepare_opt( $opt );
    my $init_dir = $self->__prepare_path();
    return $self->__choose_a_path( $init_dir, 1 );
}

sub __choose_a_path {
    my ( $self, $dir, $a_file ) = @_;
    my @pre = ( undef, ( $a_file ? $self->{show_files} : $self->{confirm} ), $self->{parent_dir} );
    my $default_idx = $self->{enchanted}  ? 2 : 0;
    my $prev_encoded = $dir;
    my $wildcard = ' ? ';

    while ( 1 ) {
        my ( $dh, @dirs );
        if ( ! eval {
            opendir( $dh, $dir ) or die $!;
            1 }
        ) {
            print "$@";
            choose(
                [ 'Press Enter:' ],
                { prompt => '', hide_cursor => $self->{hide_cursor}, mouse => $self->{mouse} }
            );
            $dir = dirname $dir;
            next;
        }
        while ( my $file = readdir $dh ) {
            next if $file =~ /^\.\.?\z/;
            next if $file =~ /^\./ && ! $self->{show_hidden};
            push @dirs, decode( 'locale_fs', $file ) if -d catdir $dir, $file;
        }
        closedir $dh;
        my @tmp;
        if ( ! defined $self->{current_selection_label} ) {
            $self->{current_selection_label} = $a_file ? 'File: ' : 'Dir: ';
        }
        if ( $a_file ) {
            push @tmp, $self->{current_selection_label} . _prepare_string( catfile $dir, $wildcard );
        }
        else {
            push @tmp, $self->{current_selection_label} . _prepare_string( $dir );
        }
        if ( defined $self->{prompt} && length $self->{prompt} ) {
            push @tmp, $self->{prompt};
        }
        my $lines = join( "\n", @tmp );
        # Choose
        my $choice = choose(
            [ @pre, sort( @dirs ) ],
            { info => $self->{info}, prompt => $lines, default => $default_idx, alignment => $self->{alignment},
              layout => $self->{layout}, order => $self->{order}, mouse => $self->{mouse},
              clear_screen => $self->{clear_screen}, hide_cursor => $self->{hide_cursor},
              color => $self->{color}, lf => $self->{lf}, undef => $self->{back} }
        );
        if ( ! defined $choice ) {
            $self->__restore_defaults();
            return;
        }
        elsif ( $choice eq $self->{confirm} ) {
            my $returned_dir;
            if ( $self->{decoded} ) {
                $returned_dir = decode 'locale_fs', $prev_encoded
            }
            else {
                $returned_dir = $prev_encoded;
            }
            $self->__restore_defaults();
            return $returned_dir;
        }
        elsif ( $choice eq $self->{show_files} ) {
            my $file = $self->__a_file( $dir, $wildcard );
            next if ! length $file;
            my $returned_file;
            if ( $self->{decoded} ) {
                $returned_file = decode 'locale_fs', $file;
            }
            else {
                $returned_file = $file;
            }
            $self->__restore_defaults();
            return $returned_file;
        }
        $choice = encode( 'locale_fs', $choice );
        if ( $choice eq $self->{parent_dir} ) {
            $dir = dirname $dir;
        }
        else {
            $dir = catdir $dir, $choice;
        }
        if ( $prev_encoded eq $dir ) {
            $default_idx = 0;
        }
        else {
            $default_idx = $self->{enchanted}  ? 2 : 0;
        }
        $prev_encoded = $dir;
    }
}


sub __a_file {
    my ( $self, $dir, $wildcard ) = @_;
    my $prev_encoded = '';
    my $chosen_file;

    while ( 1 ) {
        my ( $dh, @files );
        if ( ! eval {
            opendir( $dh, $dir ) or die $!;
            1 }
        ) {
            print "$@";
            choose(
                [ 'Press Enter:' ],
                { prompt => '', hide_cursor => $self->{hide_cursor}, mouse => $self->{mouse} }
            );
            return;
        }
        while ( my $file = readdir $dh ) {
            next if $file =~ /^\.\.?\z/;
            next if $file =~ /^\./ && ! $self->{show_hidden};
            push @files, decode( 'locale_fs', $file ) if -f catdir $dir, $file;
        }
        closedir $dh;
        if ( ! @files ) {
            my $prompt =  sprintf "No files in %s.", _prepare_string( $dir );
            choose(
                [ ' < ' ],
                { prompt => $prompt, hide_cursor => $self->{hide_cursor}, mouse => $self->{mouse} }
            );
            return;
        }
        my @tmp;
        if ( ! defined $self->{current_selection_label} ) {
            $self->{current_selection_label} = 'New: '; # file
        }
        push @tmp, $self->{current_selection_label} . _prepare_string( catfile $dir, length $prev_encoded ? $prev_encoded : $wildcard );
        if ( defined $self->{prompt} && length $self->{prompt} ) {
            push @tmp, $self->{prompt};
        }
        my $lines = join( "\n", @tmp );
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
              color => $self->{color}, lf => $self->{lf}, undef => $self->{back} }
        );
        if ( ! length $chosen_file ) {
            return;
        }
        elsif ( $chosen_file eq $self->{confirm} ) {
            return if ! length $prev_encoded;
            return catfile $dir, $prev_encoded;
        }
        else {
            $prev_encoded = encode( 'locale_fs', $chosen_file );
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
    my $tab        = '  -  ';
    my $tab_w = print_columns( $tab );
    my $sep_w;
    if ( $self->{color} ) {
        ( my $tmp_sep = $self->{thousands_separator} ) =~ s/\e\[[\d;]*m//msg;
        $sep_w = print_columns( $tmp_sep );
    }
    else {
        $sep_w = print_columns( $self->{thousands_separator} );
    }
    my $longest = $digits + int( ( $digits - 1 ) / 3 ) * $sep_w;
    my @choices_range = ();
    for my $di ( 0 .. $digits - 1 ) {
        my $begin = 1 . '0' x $di;
        $begin = 0 if $di == 0;
        $begin = insert_sep( $begin, $self->{thousands_separator} );
        ( my $end = $begin ) =~ s/^[01]/9/;
        unshift @choices_range, sprintf " %*s%s%*s", $longest, $begin, $tab, $longest, $end;
    }
    my ( $back_w, $confirm_w );
    if ( $self->{color} ) {
        ( my $tmp_back    = $self->{back}    ) =~ s/\e\[[\d;]*m//msg;
        ( my $tmp_confirm = $self->{confirm} ) =~ s/\e\[[\d;]*m//msg;
        $back_w    = print_columns( $tmp_back    );
        $confirm_w = print_columns( $tmp_confirm );
    }
    else {
        $back_w    = print_columns( $self->{back}    );
        $confirm_w = print_columns( $self->{confirm} );
    }
    my $back_tmp    = $self->{back}    . ' ' x ( $longest * 2 + $tab_w + 1 - $back_w );
    my $confirm_tmp = $self->{confirm} . ' ' x ( $longest * 2 + $tab_w + 1 - $confirm_w );
    if ( print_columns( "$choices_range[0]" ) > get_term_width() ) {
        @choices_range = ();
        for my $di ( 0 .. $digits - 1 ) {
            my $begin = 1 . '0' x $di;
            $begin = 0 if $di == 0;
            $begin = insert_sep( $begin, $self->{thousands_separator} );
            unshift @choices_range, sprintf "%*s", $longest, $begin;
        }
        $confirm_tmp = $self->{confirm};
        $back_tmp    = $self->{back};
    }
    my %numbers;
    my $result;
    if ( ! defined $self->{current_selection_label} ) {
        $self->{current_selection_label} = '> ';
    }

    NUMBER: while ( 1 ) {

        my $new_result = length $result ? $result : '';
        my $row = sprintf(  "%s%*s", $self->{current_selection_label}, $longest, $new_result );
        if ( print_columns( $row ) > get_term_width() ) {
            $row = $new_result;
        }
        my @tmp = ( $row );
        if ( length $self->{prompt} ) {
            push @tmp, $self->{prompt};
        }
        my $lines = join "\n", @tmp;
        my @pre = ( undef, $confirm_tmp ); # confirm if $result ?
        # Choose
        my $range = choose(
            $self->{small_first} ? [ @pre, reverse @choices_range ] : [ @pre, @choices_range ],
            { info => $self->{info}, prompt => $lines, layout => 3, alignment => 1, mouse => $self->{mouse},
              clear_screen => $self->{clear_screen}, hide_cursor => $self->{hide_cursor}, color => $self->{color},
              lf => $self->{lf}, undef => $back_tmp }
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
              color => $self->{color}, lf => $self->{lf}, undef => '<<' }
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
    my $new_idx =[];
    my $curr_avail = [ @$available ];
    my $bu = [];
    my @pre = ( undef, $self->{confirm} );

    while ( 1 ) {
        my @tmp;
        my $sofar;
        if ( defined $self->{current_selection_label} ) {
            $sofar .= $self->{current_selection_label};
        }
        #if ( @{$available}[@$new_idx] ) {
        if ( @$new_idx ) {
            $sofar .= $self->{current_selection_begin} . join( $self->{current_selection_separator}, map { defined $_ ? $_ : '' } @{$available}[@$new_idx] ) . $self->{current_selection_end};
        }
        elsif ( $opt->{all_by_default} ) {
            $sofar .= $self->{current_selection_begin} . '*' . $self->{current_selection_end};
        }
        if ( defined $sofar ) {
            @tmp = ( $sofar );
        }
        if ( length $self->{prompt} ) {
            push @tmp, $self->{prompt};
        }

        if ( defined $self->{mark} && @{$self->{mark}} ) {
            $self->{mark} = [ map { $_ + @pre } @{$self->{mark}} ];
        }
        my $lines = join "\n", @tmp;
        # Choose
        my @idx = choose(
            [ @pre, map { $self->{prefix} . ( defined $_ ? $_ : '' ) } @$curr_avail ],
            { info => $self->{info}, prompt => $lines, layout => $self->{layout}, index => 1,
              alignment => $self->{alignment}, order => $self->{order}, mouse => $self->{mouse},
              meta_items => [ 0 .. $#pre ], mark => $self->{mark}, include_highlighted => 2,
              clear_screen => $self->{clear_screen}, hide_cursor => $self->{hide_cursor},
              color => $self->{color}, lf => $self->{lf}, undef => $self->{back} }
        );
        $self->{mark} = undef;
        if ( ! defined $idx[0] || $idx[0] == 0 ) {
            if ( @$bu ) {
                ( $curr_avail, $new_idx ) = @{pop @$bu};
                next;
            }
            $self->__restore_defaults();
            return;
        }
        push @$bu, [ [ @$curr_avail ], [ @$new_idx ] ];
        my $ok = $idx[0] == 1 ? shift @idx : 0;
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
                $new_idx = [ 0 .. $#{$available} ];
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
    $self->{back}    = '  ' . $self->{back};
    $self->{confirm} = '  ' . $self->{confirm};
    my $longest = 0;
    my $new     = {};
    my $name_w  = {};
    for my $sub ( @$menu ) {
        my ( $key, $name ) = @$sub;
        if ( $self->{color} ) {
            ( my $tmp_name = $name ) =~ s/\e\[[\d;]*m//msg;
            $name_w->{$key} = print_columns( $tmp_name );
        }
        else {
            $name_w->{$key} = print_columns( $name );
        }
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
        if ( defined $self->{current_selection_label} ) {
            push @tmp, $self->{current_selection_label} . '' . join( ', ', map { "$_=$new->{$_}" } keys %$new ) . '';
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
              color => $self->{color}, lf => $self->{lf}, undef => $self->{back} }
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
    #my ( $unicode, $avail_width, $right_justify, $add_dots ) = @_;
    my $colwidth = print_columns( $_[0] );
    if ( $colwidth > $_[1] ) {
        if ( $_[3] ) {
            return cut_to_printwidth( $_[0], $_[1] - 3 ) . '...';
        }
        return cut_to_printwidth( $_[0], $_[1] );
    }
    elsif ( $colwidth < $_[1] ) {
        if ( $_[2] ) {
            return " " x ( $_[1] - $colwidth ) . $_[0];
        }
        else {
            return $_[0] . " " x ( $_[1] - $colwidth );
        }
    }
    else {
        return $_[0];
    }
}







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Choose::Util - TUI-related functions for selecting directories, files, numbers and subsets of lists.

=head1 VERSION

Version 0.104

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

Values: [0],1.

=item

color

Enables the support for color and text formatting escape sequences.

Values: [0],1.

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

current_selection_label

The value of I<current_selection_label> is a string which is placed in front of the "chosen so far" info output.

With C<settings_menu> the "chosen so far" info output is only shown if I<current_selection_label> is defined.

Defaults: C<choose_directories>: 'Dirs: ', C<choose_a_directory>: 'Dir: ', C<choose_a_file>: 'File: ', C<choose_a_number>: ' >',
C<choose_a_subset>: '', C<settings_menu>: undef

The "chosen so far" info output is placed between the I<info> string and the I<prompt> string.

=item

prompt

A string placed on top of the available choices.

Default: undef

=item

back

Customize the string of the menu entry "back".

Default: C<BACK>

=item

confirm

Customize the string of the menu entry "confirm".

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

- choose the "parent_dir" menu entry to move upwards.

To return the current working-directory as the chosen directory choose the "confirm" menu entry.

The "back" menu entry causes C<choose_a_directory> to return nothing.

Options:

=over

=item

alignment

Elements in columns are aligned to the left if set to 0, aligned to the right if set to 1 and centered if set to 2.

Values: [0],1,2.

=item

decoded

If enabled, the directory name is returned decoded with C<locale_fs> form L<Encode::Locale>.

Values: 0,[1].

=item

enchanted

If set to 1, the default cursor position is on the "parent_dir" menu entry. If the directory name remains the same after an
user input, the default cursor position changes to "back".

If set to 0, the default cursor position is on the "back" menu entry.

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

If set to 1, the items are ordered vertically else they are ordered horizontally.

This option has no meaning if I<layout> is set to 3.

Values: 0,[1].

=item

show_hidden

If enabled, hidden directories are added to the available directories.

Values: 0,[1].

=item

parent_dir

Customize the string of the menu entry "parent_dir".

Default: C<PARENT>

=back

=head2 choose_a_file

    $chosen_file = choose_a_file( { show_hidden => 0, ... } )

Browse the directory tree the same way as described for C<choose_a_directory>. Select the "show_files" menu entry to get the
files of the current directory. To return the chosen file select the "confirm" menu entry.

Options as in L</choose_a_directory> plus

=over

=item

show_files

Customize the string of the menu entry "show_files".

Default: C<SHOW_FILES>

=back

=head2 choose_directories

    $chosen_directories = choose_directories( { mouse => 1, ... } )

C<choose_directories> is similar to C<choose_a_directory> but it is possible to return multiple directories.

Use the  "add_dir" menu entry to add the current directory to the list of chosen directories.

To return the list of chosen directories (as an array reference) select the "confirm" menu entry.

The "back" menu entry removes the last added directory. If the list of chosen directories is empty, "back" causes
C<choose_directories> to return nothing.

Options as in L</choose_a_directory> plus

=over

=item

add_dir

Customize the string of the menu entry "add_dir".

Default: C<ADD_DIR>

=back

=head2 choose_a_number

    $new = choose_a_number( 5, { current_selection_label => 'Number: ', ... }  );

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

=head2 choose_a_subset

    $subset = choose_a_subset( \@available_items, { current_selection_label => 'new> ', ... } )

C<choose_a_subset> lets you choose a subset from a list.

The first argument is a reference to an array which provides the available list.

Options:

=over

=item

alignment

Elements in columns are aligned to the left if set to 0, aligned to the right if set to 1 and centered if set to 2.

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

If set to 1, the items are ordered vertically else they are ordered horizontally.

This option has no meaning if I<layout> is set to 3.

Values: 0,[1].

=item

prefix

I<prefix> expects as its value a string. This string is put in front of the elements of the available list in the menu.
The chosen elements are returned without this I<prefix>.

Default: empty string.

=item

current_selection_begin

Info output: the I<current_selection_begin> string is placed between the I<current_selection_label> string and the chosen elements as soon as an
element has been chosen.

Default: empty string

=item

current_selection_separator

Info output: I<current_selection_separator> is placed between the chosen list elements.

Default: C< ,>

=item

current_selection_end

Info output: as soon as elements have been chosen the I<current_selection_end> string is placed at the end of the chosen elements.

Default: empty string

=back

To return the chosen subset (as an array reference) select the "confirm" menu entry.

The "back" menu entry removes the last added chosen items. If the list of chosen items is empty, "back" causes
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

If the "back" menu entry is chosen, C<settings_menu> does not apply the made changes and returns nothing. If the
"confirm" menu entry is chosen, C<settings_menu> applies the made changes in place to the passed configuration
hash-reference (second argument) and returns the number of made changes.

Setting the option I<current_selection_label> to a defined value adds an info output line.

=head1 DEPRECATIONS

=head2 Functions

=over

=item

choose_a_dir

The function C<choose_a_dir> is deprecated. Use C<choose_a_directory> instead.

=item

choose_dirs

The function C<choose_dirs> is deprecated. Use C<choose_directories> instead.

=back

=head2 Options

=over

=item

justify

The option I<justify> is deprecated. Use I<alignment> instead.

=item

dir

The option I<dir> is deprecated. Use I<init_dir> instead.

=item

up

The option I<up> is deprecated. Use I<parent_dir> instead.

=item

name

The option I<name> is deprecated. Use I<current_selection_label> instead.

=item

thsd_sep

The option I<thsd_sep> is deprecated. Use I<thousands_separator> instead.

=item

sofar_begin

The option I<sofar_begin> is deprecated. Use I<current_selection_begin> instead.

=item

sofar_separator

The option I<sofar_separator> is deprecated. Use I<current_selection_separator> instead.

=item

sofar_end

The option I<sofar_end> is deprecated. Use I<current_selection_end> instead.

=back

Deprecated functions and options will be removed.

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

Copyright 2014-2019 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
