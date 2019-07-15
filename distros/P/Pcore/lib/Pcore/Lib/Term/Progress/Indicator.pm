package Pcore::Lib::Term::Progress::Indicator;

use Pcore -role;
use POSIX qw[strftime];
use Time::HiRes qw[];
use Pcore::Lib::Scalar qw[is_plain_coderef];

requires qw[_draw];

has id => ( required => 1 );

has network => ();    # Bool

has message => $EMPTY;    # Str

has show_state => (1);    # Bool, show value/total/percent

has value         => 0;                                      # PositiveOrZeroNum
has value_format  => '%.0f';                                 # Str | CodeRef
has _format_value => ( is => 'lazy', init_arg => undef );    # CodeRef

has total         => 0;                                      # PositiveOrZeroNum
has total_format  => '%.0f';                                 # Str | CodeRef
has _format_total => ( is => 'lazy', init_arg => undef );    # CodeRef

has percent_format  => '%3.0f';                              # Str | CodeRef
has _format_percent => ( is => 'lazy', init_arg => undef );  # CodeRef

has show_speed    => 1;                                      # Bool
has speed_format  => '%.2f';                                 # Str | CodeRef
has _format_speed => ( is => 'lazy', init_arg => undef );    # CodeRef
has unit          => $EMPTY;                                 # Str

has show_time    => 1;                                       # Bool
has time_format  => '%M:%S';                                 # Str | CodeRef
has _format_time => ( is => 'lazy', init_arg => undef );     # CodeRef

has size => ();                                              # PositiveInt

has is_finished => 0, init_arg => undef;                     # Bool
has start_time  => 0, init_arg => undef;                     # Int
has end_time    => 0, init_arg => undef;                     # Int
has total_time  => 0, init_arg => undef;                     # Int
has eta         => 0, init_arg => undef;                     # PositiveOrZeroNum, seconds, left to complete, 0 - unknown
has speed => ( init_arg => undef );                          # PositiveOrZeroNum

my $TERM_WIDTH = P->term->width;

our $DEFAULT_SIZE = $TERM_WIDTH ? $TERM_WIDTH - 5 : 80;

my $LAST_UPDATED;

sub BUILDARGS ( $self, $args ) {
    $args->{size} = !exists $args->{size} ? $DEFAULT_SIZE : $args->{size} > $DEFAULT_SIZE ? $DEFAULT_SIZE : $args->{size};

    return $args;
}

sub BUILD ( $self, $args ) {
    $self->start;

    say $self->_draw;

    return;
}

sub _build__format_value ($self) {
    my $value_format = $self->{value_format};

    if ( is_plain_coderef $value_format ) {
        return $value_format;
    }
    else {
        if ( $self->{network} ) {
            return \&_format_network_unit;
        }
        else {
            return sub {
                return sprintf $value_format, $_[1];
            };
        }
    }
}

sub _build__format_total ($self) {
    my $total_format = $self->{total_format};

    if ( is_plain_coderef $total_format ) {
        return $total_format;
    }
    else {
        if ( $self->{network} ) {
            return \&_format_network_unit;
        }
        else {
            return sub {
                return sprintf $total_format, $_[1];
            };
        }
    }
}

sub _build__format_percent ($self) {
    my $percent_format = $self->{percent_format};

    if ( is_plain_coderef $percent_format ) {
        return $percent_format;
    }
    else {
        return sub {
            return sprintf $percent_format, $_[1];
        };
    }
}

sub _build__format_speed ($self) {
    my $speed_format = $self->{speed_format};

    if ( is_plain_coderef $speed_format ) {
        return $speed_format;
    }
    else {
        if ( $self->{network} ) {
            return \&_format_network_unit;
        }
        else {
            return sub {
                return sprintf $speed_format, $_[1] || 0;
            };
        }
    }
}

sub _build__format_time ($self) {
    my $time_format = $self->{time_format};

    if ( is_plain_coderef $time_format ) {
        return $time_format;
    }
    else {
        return sub {
            my $time = strftime $time_format, $_[1], 0, 0, 0, 0, 0, 0, 0, 0;

            $time =~ tr/0/?/ unless $_[1];

            return $time;
        };
    }
}

sub _format_network_unit ( $self, $value ) {
    $value ||= 0;

    if ( $value < 1000 ) {
        return sprintf( '%6.0f', $value ), q[B ];
    }
    elsif ( $value < 1_000_000 ) {
        return sprintf( '%6.2f', $value / 1_000 ), q[kB];
    }
    elsif ( $value < 1_000_000_000 ) {
        return sprintf( '%6.2f', $value / 1_000_000 ), q[MB];
    }
    elsif ( $value >= 1_000_000_000_000 ) {
        return sprintf( '%6.2f', $value / 1_000_000_000 ), q[GB];
    }
    else {
        return sprintf( '%6.2f', $value / 1_000_000_000_000 ), q[TB];
    }
}

sub start ($self) {
    $self->{start_time} = time;

    delete $self->{end_time};

    delete $self->{total_time};

    $self->{is_finished} = 0;

    return;
}

sub finish ($self) {
    my $time = time;

    $self->{end_time} = $time;

    $self->{total_time} = ( $time - $self->{start_time} ) || 1;

    $self->{is_finished} = 1;

    return;
}

sub update ( $self, %args ) {
    my $time = time;

    $self->{message} = $args{message} if defined $args{message};

    $self->{total} = $args{total} if defined $args{total};

    # do not allow value to be larger than total
    $args{value} = $self->{total} if $self->{total} && $args{value} && $args{value} > $self->{total};

    $self->{value} = $args{value} if defined $args{value};

    # automatically finish
    if ( $self->{value} == $self->{total} ) {
        $self->finish;
    }
    else {
        $self->{total_time} = $time - $self->{start_time};
    }

    # calculate speed
    if ( !defined $self->{speed} ) {
        $self->{speed} = int( $args{value} / ( $self->{total_time} || 1 ) );
    }
    else {
        $self->{speed} = int( ( $self->{speed} + ( $args{value} / ( $self->{total_time} || 1 ) ) ) / 2 );
    }

    # calculate ETA
    if ( $self->{total} ) {
        if ( !$self->{speed} ) {
            $self->{eta} = 0;
        }
        else {
            $self->{eta} = int( ( $self->{total} - $args{value} ) / $self->{speed} ) || 1;
        }
    }

    # redraw only every 0.5 sec., or if indicator is finished
    return if !$self->{is_finished} && $LAST_UPDATED && $LAST_UPDATED + 0.5 > Time::HiRes::time();

    Pcore::Lib::Term::Progress::_update();

    $LAST_UPDATED = Time::HiRes::time();

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 236                  | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::Term::Progress::Indicator

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
