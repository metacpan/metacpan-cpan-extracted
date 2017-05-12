
package Paper::Specs::base::label;
use strict;
use base qw(Paper::Specs::base::sheet);

use vars qw($VERSION);
$VERSION=0.01;

sub type { return 'label' }

# No unit conversion support yet

sub gutter_cols {

    my $self=shift;
    return 0 if $self->label_cols <= 1;
    return ($self->sheet_width - $self->margin_left - $self->margin_right - $self->label_cols * $self->label_width ) 
        / ($self->label_cols - 1);

}

sub gutter_rows {

    my $self=shift;
    return 0 if $self->label_rows <= 1;
    return ($self->sheet_height - $self->margin_top - $self->margin_bottom - $self->label_rows * $self->label_height ) 
        / ($self->label_rows - 1);

}

sub margin_left   { Paper::Specs::convert ($_[0]->specs->{'margin_left'}  , $_[0]->specs->{'units'}) }
sub margin_right  { Paper::Specs::convert ($_[0]->specs->{'margin_right'} , $_[0]->specs->{'units'}) }
sub margin_top    { Paper::Specs::convert ($_[0]->specs->{'margin_top'}   , $_[0]->specs->{'units'}) }
sub margin_bottom { Paper::Specs::convert ($_[0]->specs->{'margin_bottom'}, $_[0]->specs->{'units'}) }

sub label_height  { Paper::Specs::convert ($_[0]->specs->{'label_height'},  $_[0]->specs->{'units'}) }
sub label_width   { Paper::Specs::convert ($_[0]->specs->{'label_width'},   $_[0]->specs->{'units'}) }

sub label_rows    { $_[0]->specs->{'label_rows'} }
sub label_cols    { $_[0]->specs->{'label_cols'}  }


sub label_location {

    my $self=shift;
    my ($r, $c) = @_;

    return () if $r > $self->label_rows || $r < 1;
    return () if $c > $self->label_cols || $c < 1;

    my $pos_row = $self->margin_top + ($self->label_height + $self->gutter_rows) * ( $r - 1 );
    my $pos_col = $self->margin_left + ($self->label_width + $self->gutter_cols) * ( $c - 1 );

    if ( Paper::Specs->layout eq 'pdf' ) {

        return ( $pos_col, $self->sheet_height - $pos_row );

    }

    return ($pos_col, $pos_row);


}

sub label_size {

    my $self=shift;

    if ( Paper::Specs->layout eq 'pdf' ) {
        return ( $self->label_width, -$self->label_height );
    } else {
        return ( $self->label_width, $self->label_height );
    }

}

1;
