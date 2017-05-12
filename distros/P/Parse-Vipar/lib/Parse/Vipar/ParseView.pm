package Parse::Vipar::ParseView;
use Parse::Vipar::Common;
use Parse::Vipar::ParseTree;

BEGIN { *{__PACKAGE__."::new"} = \&Parse::Vipar::subnew; }

use strict;

sub layout {
    my $self = shift;
    my ($win) = @_;

    $win->{parse_t} = $win->{parse_f}->Scrolled('ParseTree',
                                                -width => PANEWIDTH,
                                                -columns => 2,
                                                -scrollbars => 'e')
        ->pack(-side => 'bottom', -fill => 'y', -expand => 1);

    $self->{_t} = $win->{parse_t};

    return $win;
}

sub push {
    my $self = shift;
    $self->{_t}->push(@_);
}

sub reduce {
    my $self = shift;
    $self->{_t}->reduce(@_);
}

1;
