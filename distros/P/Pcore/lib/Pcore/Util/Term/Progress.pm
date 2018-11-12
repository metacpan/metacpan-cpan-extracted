package Pcore::Util::Term::Progress;

use Pcore;
use Pcore::Util::Scalar qw[weaken];

my $INDICATOR       = {};
my $INDICATOR_ORDER = 0;

sub get_indicator (%args) {
    my $all_finished = 1;

    for my $id ( sort keys $INDICATOR->%* ) {
        if ( defined $INDICATOR->{$id} && !$INDICATOR->{$id}->{is_finished} ) {
            $all_finished = 0;

            last;
        }
    }

    $INDICATOR = {} if $all_finished;

    my $indicator = P->class->load( $args{type} // 'Bar', ns => 'Pcore::Util::Term::Progress::Indicator' )->new( { %args, id => $INDICATOR_ORDER++ } );    ## no critic qw[ValuesAndExpressions::ProhibitCommaSeparatedStatements]

    $INDICATOR->{ $indicator->{id} } = $indicator;

    weaken $INDICATOR->{ $indicator->{id} };

    return $indicator;
}

sub _update {

    # go to beginning of the output
    my $buffer = "\e[" . scalar( keys $INDICATOR->%* ) . 'A';

    for my $id ( sort keys $INDICATOR->%* ) {
        if ( !defined $INDICATOR->{$id} ) {
            $buffer .= $LF;    # move cursor to the next line, skip rendering
        }
        else {
            $buffer .= $INDICATOR->{$id}->_draw . $LF;
        }
    }

    print $buffer;

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 31                   | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_update' declared but not used      |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Term::Progress

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
