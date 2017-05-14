package POE::Wheel::VimColor;
use strict;
use warnings;
use POE;
use POE::Wheel::Run;
use Text::VimColor;
use base 'POE::Wheel';

our $run_wheel;

sub new {
    my ($class, %args) = @_;
    return bless [
        $args{DoneEvent},
        POE::Wheel::allocate_wheel_id(),
    ], $class;
}

sub put {
    my ($self, $text, $type) = @_;
    my $event = $self->[0];
    $SIG{CHLD} = 'IGNORE';
    $run_wheel = POE::Wheel::Run->new(
        Program => sub { vim_color($text, $type) },
        StdoutEvent => $event,
    );
    return;
}

sub vim_color {
    my ($text, $type) = @_;
    $text = "" unless defined $text;
    $type = "text" unless defined $type;
    my $html = eval {
        Text::VimColor->new(string => $text, filetype => $type)->html
    };
    print "$html";
}

sub DESTROY {
    $run_wheel->kill if defined $run_wheel;
    $run_wheel = undef;
    POE::Wheel::free_wheel_id($_[0]->[1]);
}

1;
