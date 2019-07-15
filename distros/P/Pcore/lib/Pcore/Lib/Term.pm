package Pcore::Lib::Term;

use Pcore;
use Term::ReadKey qw[];

sub width {
    state $init = do {
        require Term::Size::Any;

        Term::Size::Any::_require_any();

        1;
    };

    return scalar Term::Size::Any::chars();
}

sub pause {
    my %args = (
        msg     => 'Press any key to continue...',
        timeout => 0,
        @_,
    );

    print $args{msg};

    Term::ReadKey::ReadMode(3);

    Term::ReadKey::ReadKey( $args{timeout} );

    Term::ReadKey::ReadMode(1);

    print "\n";

    return;
}

sub prompt ( $msg, $opt, @ ) {
    my %args = (
        default => undef,
        enter   => 0,       # user should press ENTER
        echo    => 1,
        timeout => 0,       # timeout, after the default value will be accepted
        splice @_, 2,
    );

    my $index = {};

    my @opt;

    my $default_match;

    # index opt, remove duplicates
    for my $val ( $opt->@* ) {
        next if exists $index->{$val};

        $index->{$val} = 1;

        push @opt, $val;

        $default_match = 1 if defined $args{default} && $args{default} eq $val;
    }

    die q[Invalid default value] if defined $args{default} && !$default_match;

    die q[Default value should be specified if timeout is used] if $args{timeout} && !defined $args{default};

    print $msg, ' (', join( q[|], @opt ), ')';

    print " [$args{default}]" if defined $args{default};

    print ': ';

  READ:
    my @possible = ();

    my $input = read_input(
        edit       => 1,
        echo       => $args{echo},
        echo_char  => undef,
        timeout    => $args{timeout},
        clear_echo => 1,
        on_read    => sub ( $input, $char ) {
            @possible = ();

            # stop reading if ENTER is pressed and has default value
            return if !defined $char && $input eq $EMPTY && defined $args{default};

            # scan possible input values
            for my $val (@opt) {
                push @possible, $val if !index $val, $input, 0;
            }

            # say dump [ \@possible, $input, $char ];

            if ( !@possible ) {
                return 0;    # reject last char
            }
            elsif ( @possible > 1 ) {
                if ( !defined $char ) {
                    return -1;    # clear input on ENTER
                }
                else {
                    return 1;     # accept last char
                }
            }
            else {
                if ( $args{enter} ) {
                    if ( !defined $char ) {
                        return;    # ENTER pressed, accept input
                    }
                    else {
                        return 1;    # waiting for ENTER
                    }
                }
                else {
                    return;          # accept input and exit
                }
            }
        }
    );

    $possible[0] = $args{default} if $input eq $EMPTY;    # timeout, no user input

    print $possible[0];

    print "\n";

    return $possible[0];
}

sub read_password {
    my %args = (
        msg       => 'Enter password',
        echo      => 1,
        echo_char => q[*],
        @_,
    );

    print $args{msg}, ': ';

    my $input = read_input(
        edit      => 1,
        echo      => $args{echo},
        echo_char => $args{echo_char},
    );

    print "\n";

    return $input;
}

# NOTE on_read callback should return:
# undef - accept input and return;
# -1    - clear input and continue reading;
# 0     - reject last char and continue reading;
# 1     - accept last char and continue reading;
sub read_input {
    my %args = (
        edit       => 1,
        echo       => 1,
        echo_char  => undef,
        timeout    => 0,
        clear_echo => 0,       # clear echo on return
        on_read    => undef,
        @_,
    );

    my $input = $EMPTY;

    my $add_char = sub ($char) {
        print $args{echo_char} // $char if $args{echo};

        $input .= $char;

        return;
    };

    my $delete_char = sub {
        if ( length $input ) {
            print "\e[1D\e[K" if $args{echo};

            substr $input, -1, 1, $EMPTY;
        }

        return;
    };

    my $clear_echo = sub {
        if ( $args{echo} && defined $input && ( my $len = length $input ) ) {
            print "\e[${len}D\e[K";
        }

        return;
    };

    my $clear_input = sub {
        $clear_echo->();

        $input = $EMPTY;

        return;
    };

    Term::ReadKey::ReadMode(3);

  READ:
    my $key = Term::ReadKey::ReadKey( $args{timeout} );

    if ( !defined $key ) {    # timeout
        $input = $EMPTY;
    }
    else {
        $args{timeout} = 0;    # drop timout if user start enter something

        $key =~ s/[\r\n]//smg;

        if ( $key eq $EMPTY ) {    # ENTER
            if ( $args{on_read} ) {
                my $on_read = $args{on_read}->( $input, undef );

                if ( defined $on_read ) {
                    $clear_input->() if $on_read == -1;

                    goto READ;
                }
            }
        }
        elsif ( $key =~ /\e/sm ) {    # ESC seq.
            while ( Term::ReadKey::ReadKey(0) ne q[~] ) { }    # read and ignore the rest of the ESC seq.

            goto READ;
        }
        elsif ( $key =~ /[[:cntrl:]]/sm ) {                    # control char
            if ( $args{edit} && ord($key) == 8 || ord($key) == 127 ) {    # BACKSPACE, DELETE
                $delete_char->();
            }

            goto READ;
        }
        else {
            $key = Encode::decode( $Pcore::CON_ENC, $key ) if !utf8::is_utf8($key);

            if ( $args{on_read} ) {
                my $on_read = $args{on_read}->( $input . $key, $key );

                if ( defined $on_read ) {
                    if ( $on_read == -1 ) {    # clear input
                        $clear_input->();
                    }
                    elsif ( $on_read == 1 ) {    # accept last character
                        $add_char->($key);
                    }

                    goto READ;
                }
                else {                           # accept last char and return
                    $add_char->($key);
                }
            }
            else {
                $add_char->($key);

                goto READ;
            }

        }
    }

    $clear_echo->() if $args{clear_echo};

    Term::ReadKey::ReadMode(1);

    return $input;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 10                   | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 |                      | Subroutines::ProhibitExcessComplexity                                                                          |
## |      | 38                   | * Subroutine "prompt" with high complexity score (25)                                                          |
## |      | 158                  | * Subroutine "read_input" with high complexity score (28)                                                      |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=head1 NAME

Pcore::Lib::Term

=head1 METHODS

=head2 prompt

Prompting for user input and returns received value.

    my $res = Pcore::Lib::Prompt::prompt($query, \@answers, %options);

=over

=item * OPTIONS

=over

=item * default - default value, returned if enter pressed with no input;

=item * confirm - if true, user need to confirm input with enter;

=back

=back

=head2 pause

Blocking wait for any key pressed.

    Pcore::Lib::Prompt::pause([$message], %options);

=over

=item * OPTIONS

=over

=item * timeout - timeout in seconds;

=back

=back

=cut
