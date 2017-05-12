package Pangloss::Search::Filter::Document;

use base      qw( Pangloss::Search::Filter::Keyword );
use accessors qw( text );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.3 $ '))[2];

sub applies_to {
    my $self = shift;
    my $term = shift;
    return $self->does_text_contain( $term->concept );
}

sub does_text_contain {
    my $self = shift;
    my $text = shift || return;
    $text    = quotemeta( $text );
    $self->text =~ /$text/i;
}

1;
