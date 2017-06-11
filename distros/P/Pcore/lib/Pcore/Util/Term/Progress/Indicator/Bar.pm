package Pcore::Util::Term::Progress::Indicator::Bar;

use Pcore -class, -ansi;

with qw[Pcore::Util::Term::Progress::Indicator];

our $PROGRESS_BAR_CHAR = q[■];
our $MESS_COLOR        = $BOLD . $YELLOW;
our $BAR_COLOR         = $YELLOW;

sub _draw ($self) {
    my $info = q[];

    # state
    if ( $self->show_state ) {

        # precent, only if total is known
        if ( $self->total ) {
            $info .= q[ ] . $self->_format_percent->( $self, int( $self->value / $self->total * 100 ) ) . q[%];
        }

        # value
        my ( $value, $value_unit ) = $self->_format_value->( $self, $self->value );

        $info .= q[  ] . $value;

        $value_unit ||= $self->unit;

        $info .= q[ ] . $value_unit if $value_unit;

        # total
        if ( $self->total ) {
            my ( $total, $total_unit ) = $self->_format_total->( $self, $self->total );

            $info .= q[ / ] . $total;

            $total_unit ||= $self->unit;

            $info .= q[ ] . $total_unit if $total_unit;
        }
    }

    # speed
    if ( $self->show_speed ) {
        my ( $speed, $speed_unit ) = $self->_format_speed->( $self, $self->speed );

        $info .= q[  ] . $speed;

        $speed_unit ||= $self->unit;

        if ($speed_unit) {
            $speed_unit =~ s[(.+?)(\s*)\z][$1/s$2]smg;

            $info .= q[ ] . $speed_unit;
        }
        else {
            $info .= q[/s];
        }
    }

    # time
    if ( $self->show_time ) {
        $info .= q[  ];

        if ( $self->is_finished ) {
            $info .= $self->_format_time->( $self, $self->total_time );
        }
        elsif ( $self->total ) {
            $info .= $self->_format_time->( $self, $self->eta );
        }
    }

    my $bar = q[];

    # bar
    if ( $self->total ) {
        my $bar_size = $self->size - length($info) - 2;

        my $current_pos = int $bar_size * $self->value / $self->total;

        # progress bar
        $bar .= '[';

        my $mess = $self->message;

        # truncate mess
        $mess = substr $mess, 0, $bar_size if length $mess > $bar_size;

        if ($current_pos) {
            if ( length $mess == $current_pos ) {    # hl full mess
                $bar .= $MESS_COLOR;

                $bar .= $mess;

                $bar .= $RESET;

                $bar .= q[ ] x ( $bar_size - $current_pos );
            }
            elsif ( length $mess < $current_pos ) {    # hl full mess + bar symbols
                if ($mess) {
                    $bar .= $MESS_COLOR;

                    $bar .= $mess;

                    $bar .= $RESET;
                }

                $bar .= $BAR_COLOR;

                $bar .= $PROGRESS_BAR_CHAR x ( $current_pos - length $mess );

                $bar .= $RESET;

                $bar .= q[ ] x ( $bar_size - $current_pos );
            }
            else {    # hl mess part
                my $mess_hl = substr $mess, 0, $current_pos, q[];

                $bar .= $MESS_COLOR;

                $bar .= $mess_hl;

                $bar .= $RESET;

                $bar .= $mess;

                $bar .= q[ ] x abs $bar_size - length $self->message;
            }
        }
        else {
            if ($mess) {
                $bar .= sprintf qq[%-${bar_size}s], $mess;
            }
            else {
                $bar .= q[ ] x $bar_size;
            }
        }

        $bar .= ']';
    }

    # clear entire line, cursor position does not change
    return "\e[2K" . $bar . $info;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 11                   | Subroutines::ProhibitExcessComplexity - Subroutine "_draw" with high complexity score (25)                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 11                   | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_draw' declared but not used        |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Term::Progress::Indicator::Bar

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
