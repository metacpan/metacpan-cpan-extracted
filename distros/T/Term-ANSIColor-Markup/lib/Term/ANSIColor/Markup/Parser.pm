package Term::ANSIColor::Markup::Parser;
use strict;
use warnings;
use Carp qw(croak);
use base qw(
    HTML::Parser
    Class::Accessor::Lvalue::Fast
);

# copied from Term::ANSIColor
our %TAGS = (
    clear      => 0,
    reset      => 0,
    bold       => 1,
    dark       => 2,
    faint      => 2,
    underline  => 4,
    underscore => 4,
    blink      => 5,
    reverse    => 7,
    concealed  => 8,

    black      => 30,   on_black   => 40,
    red        => 31,   on_red     => 41,
    green      => 32,   on_green   => 42,
    yellow     => 33,   on_yellow  => 43,
    blue       => 34,   on_blue    => 44,
    magenta    => 35,   on_magenta => 45,
    cyan       => 36,   on_cyan    => 46,
    white      => 37,   on_white   => 47,
);

__PACKAGE__->mk_accessors(qw(result stack));

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
       $self->result = '';
       $self->stack = [];
       $self;
}

sub start {
    my ($self, $tagname, $attr, $attrseq, $text) = @_;
    if (my $escape_sequence = $self->get_escape_sequence($tagname)) {
        push @{$self->stack}, $tagname;
        $self->result .= $escape_sequence;
    }
    else {
        $self->result .= $text;
    }
}

sub text {
    my ($self, $text) = @_;
    $self->result .= $self->unescape($text);
}

sub end {
    my ($self, $tagname, $text) = @_;
    if (my $color = $self->get_escape_sequence($tagname)) {
        my $top = pop @{$self->stack};
        croak "Invalid end tag was found: $text" if $top ne $tagname;
        $self->result .= $self->get_escape_sequence('reset');
        if (scalar @{$self->stack}) {
            $self->result .= $self->get_escape_sequence($self->stack->[-1]);
        }
    }
    else {
        $self->result .= $text;
    }
}

sub get_escape_sequence {
    my ($self, $name) = @_;
    my $escape_sequence  = '';
    for my $key (keys %TAGS) {
        if (lc $name eq lc $key) {
            $escape_sequence = sprintf "\e[%dm", $TAGS{$key};
            last;
        }
    }
    $escape_sequence;
}

sub unescape {
    my ($self, $text) = @_;
    return '' if !defined $text;
    $text =~ s/&lt;/</ig;
    $text =~ s/&gt;/>/ig;
    $text;
}

1;
