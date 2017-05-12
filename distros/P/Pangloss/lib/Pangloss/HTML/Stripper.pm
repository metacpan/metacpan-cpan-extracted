package Pangloss::HTML::Stripper;

# shamelessly stolen from HTML::Parser's 'htext' example and adapted.

use strict;

use HTML::Parser 3.00 ();

use base qw( Pangloss::Object );

sub strip {
    my $self = shift;
    my $html = shift;
    $html    = $$html if ref($html);

    $self->{inside} = {};

    HTML::Parser->new(
		      api_version => 3,
		      handlers    => [
				      start => [sub {$self->tag(@_)},  "tagname, '+1'"],
				      end   => [sub {$self->tag(@_)},  "tagname, '-1'"],
				      text  => [sub {$self->text(@_)}, "dtext"],
				     ],
		      marked_sections => 1,
		     )->parse($html);

    return delete $self->{text};
}

sub tag {
    my ($self, $tag, $num) = @_;
    $self->{inside}->{$tag} += $num;
    $self->{text} .= ' ' unless $self->{text} =~ /\s\z/;
}

sub text {
    my ($self, $text) = @_;
    return if $self->{inside}->{script} || $self->{inside}->{style};
    $self->{text} .= $text;
}

1;
