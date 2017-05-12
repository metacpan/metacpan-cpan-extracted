package Pcore::Util::Term::Progress::Indicator;

use Pcore -role;
use POSIX qw[strftime];
use Time::HiRes qw[];

requires qw[_draw];

has id => ( is => 'lazy', isa => Int, required => 1 );

has network => ( is => 'ro', isa => Bool, default => 0 );

has message => ( is => 'lazy', isa => Str, writer => '_set_message', default => q[] );

has show_state => ( is => 'lazy', isa => Bool, default => 1 );    # show value/total/percent

has value => ( is => 'lazy', isa => PositiveOrZeroNum, writer => '_set_value', default => 0 );
has value_format => ( is => 'ro', isa => Str | CodeRef, default => q[%.0f] );
has _format_value => ( is => 'lazy', isa => CodeRef, init_arg => undef );

has total => ( is => 'lazy', isa => PositiveOrZeroNum, writer => '_set_total', default => 0 );
has total_format => ( is => 'ro', isa => Str | CodeRef, default => q[%.0f] );
has _format_total => ( is => 'lazy', isa => CodeRef, init_arg => undef );

has percent_format => ( is => 'lazy', isa => Str | CodeRef, default => q[%3.0f] );
has _format_percent => ( is => 'lazy', isa => CodeRef, init_arg => undef );

has show_speed => ( is => 'lazy', isa => Bool, default => 1 );
has speed_format => ( is => 'lazy', isa => Str | CodeRef, default => q[%.2f] );
has _format_speed => ( is => 'lazy', isa => CodeRef, init_arg => undef );
has unit          => ( is => 'lazy', isa => Str,     default  => q[] );

has show_time => ( is => 'lazy', isa => Bool, default => 1 );
has time_format => ( is => 'lazy', isa => Str | CodeRef, default => q[%M:%S] );
has _format_time => ( is => 'lazy', isa => CodeRef, init_arg => undef );

has size => ( is => 'ro', isa => PositiveInt );

has is_finished => ( is => 'rwp',  isa => Bool,              default => 0,          init_arg => undef );
has start_time  => ( is => 'rwp',  isa => Int,               default => 0,          clearer  => '_clear_start_time', init_arg => undef );
has end_time    => ( is => 'rwp',  isa => Int,               default => 0,          clearer  => '_clear_end_time', init_arg => undef );
has total_time  => ( is => 'rwp',  isa => Int,               default => 0,          clearer  => '_clear_total_time', init_arg => undef );
has eta         => ( is => 'lazy', isa => PositiveOrZeroNum, writer  => '_set_eta', default  => 0, init_arg => undef );                     # seconds, left to complete, 0 - unknown
has speed => ( is => 'rwp', isa => PositiveOrZeroNum, init_arg => undef );

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
    my $value_format = $self->value_format;

    if ( ref $value_format eq 'CODE' ) {
        return $value_format;
    }
    else {
        if ( $self->network ) {
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
    my $total_format = $self->total_format;

    if ( ref $total_format eq 'CODE' ) {
        return $total_format;
    }
    else {
        if ( $self->network ) {
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
    my $percent_format = $self->percent_format;

    if ( ref $percent_format eq 'CODE' ) {
        return $percent_format;
    }
    else {
        return sub {
            return sprintf $percent_format, $_[1];
        };
    }
}

sub _build__format_speed ($self) {
    my $speed_format = $self->speed_format;

    if ( ref $speed_format eq 'CODE' ) {
        return $speed_format;
    }
    else {
        if ( $self->network ) {
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
    my $time_format = $self->time_format;

    if ( ref $time_format eq 'CODE' ) {
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
    $self->_set_start_time(time);

    $self->_clear_end_time;

    $self->_clear_total_time;

    $self->_set_is_finished(0);

    return;
}

sub finish ($self) {
    my $time = time;

    $self->_set_end_time($time);

    $self->_set_total_time( ( $time - $self->start_time ) || 1 );

    $self->_set_is_finished(1);

    return;
}

sub update ( $self, %args ) {
    my $time = time;

    $self->_set_message( $args{message} ) if defined $args{message};

    $self->_set_total( $args{total} ) if defined $args{total};

    # do not allow value to be larger than total
    $args{value} = $self->total if $self->total && $args{value} && $args{value} > $self->total;

    $self->_set_value( $args{value} ) if defined $args{value};

    # automatically finish
    if ( $self->value == $self->total ) {
        $self->finish;
    }
    else {
        $self->_set_total_time( $time - $self->start_time );
    }

    # calculate speed
    if ( !defined $self->speed ) {
        $self->_set_speed( int( $args{value} / ( $self->total_time || 1 ) ) );
    }
    else {
        $self->_set_speed( int( ( $self->speed + ( $args{value} / ( $self->total_time || 1 ) ) ) / 2 ) );
    }

    # calculate ETA
    if ( $self->total ) {
        if ( !$self->speed ) {
            $self->_set_eta(0);
        }
        else {
            $self->_set_eta( int( ( $self->total - $args{value} ) / $self->speed ) || 1 );
        }
    }

    # redraw only every 0.5 sec., or if indicator is finished
    return if !$self->is_finished && $LAST_UPDATED && $LAST_UPDATED + 0.5 > Time::HiRes::time();

    Pcore::Util::Term::Progress::_update();

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
## |    3 | 235                  | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Term::Progress::Indicator

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
