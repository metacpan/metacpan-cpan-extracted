package Socialtext::Wikrad::Listbox;
use strict;
use warnings;
use base 'Curses::UI::Listbox';
use Curses qw/KEY_ENTER/;
use Socialtext::Wikrad qw/$App/;

sub new {
    my $class = shift;
    my %args = (
        -border => 1,
        -wraparound => 1,
        -x => 5,
        -y => 2,
        -width => 50,
        @_,
    );
    die 'must be a title' unless $args{-title};
    die 'must be values' unless $args{-values};

    my $cb = delete $args{change_cb};
    $args{-onchange} = sub {
        my $w = shift;
        my $link = $w->get;
        $App->{win}->delete('listbox');
        $App->{win}->draw;
        $cb->($link) if $cb;
    };
    my $self  = $class->SUPER::new(%args);
    $self->set_binding( sub { 
        $App->{win}->delete('listbox');
        $App->{win}->draw;
    }, 'q' );

    return $self;
}

1;
