package Pangloss::Search::Filter::Keyword;

use base      qw( Pangloss::Search::Filter );
use accessors qw( text );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub text_re {
    my $self = shift;
    my $text = $self->text;
    return qr/$text/i;
}

# mimick Pg::Search::Filter::Base API
sub get   { shift->text; }
sub set   { shift->text( @_ ); }
sub unset { shift->text( undef ); }
sub is_empty  { ! shift->not_empty; }
sub not_empty { shift->text ? 1 : 0; }

sub applies_to {
    my $self   = shift;
    my $term   = shift;
    my $search = join( "\n", $term->name, $term->concept );
    my $re     = $self->text_re;
    return $search =~ /$re/;
}

1;
