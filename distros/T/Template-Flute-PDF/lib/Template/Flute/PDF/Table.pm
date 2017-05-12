package Template::Flute::PDF::Table;

use strict;
use warnings;

use Template::Flute::PDF::Box;

=head1 NAME

Template::Flute::PDF::Table - Class for examining HTML tables for PDF

=head1 CONSTRUCTOR

=head2 new

Creates Template::Flute::PDF::Table object.

=cut

sub new {
	my ($proto, @args) = @_;
	my ($class, $self);

	$class = ref($proto) || $proto;
	$self = {@args};

	$self->{rows} = 0;
	$self->{cells} = 0;
	$self->{cell_widths} = [];
		
	bless ($self, $class);
}

=head2 walk

Walks HTML table and adjust sizes of the cells.

=cut

sub walk {
	my ($self, $box) = @_;
	my ($elt, $elt_cell, $gi, $row_pos, $cell_pos, @data, $i, $j, $width,
        $row_box, @row_boxes, %args, @row_heights);

	$i = $j = 0;
	
	for $elt ($box->{elt}->children()) {
		if ($elt->gi() eq 'tr') {
			# table row
            my $max_h = 0;
                            
            $args{pdf} = $self->{pdf};
            $args{elt} = $elt;
            $args{bounding} = $box->{window};
            
            $row_box = Template::Flute::PDF::Box->new(%args);
            
            for $elt_cell ($elt->children()) {
				$gi = $elt_cell->gi();
				
				# table cell
				if ($gi eq 'th' || $gi eq 'td') {
                    # create box
                    my ($cell_box, $colspan);

                    $args{pdf} = $self->{pdf};
                    $args{elt} = $elt_cell;
                    $args{parent} = $row_box;
                    $args{bounding} = $box->{window};
                    
                    $cell_box = Template::Flute::PDF::Box->new(%args);
                    $cell_box->calculate;

                    # determine colspan for table cell
                    $colspan = $elt_cell->att('colspan') || 1;

                    if ($colspan == 1) {
                        if (@{$self->{cell_widths}} == $j
                            || ($cell_box->{box}->{width} > $self->{cell_widths}->[$j])) {
                            $self->{cell_widths}->[$j] = $cell_box->{box}->{width};
                        }                    				
                    }
                    
                    if ($cell_box->{box}->{height} > $max_h) {
                        # adjust maximum row height
                        $max_h = $cell_box->{box}->{height};
                    }
                        
					$data[$i][$j] = {text => $elt_cell->text(),
                                       box => $cell_box};

                    $j += $colspan;
                    
                    $row_box->{eltmap}->{$elt_cell} = $cell_box;
                    push @{$row_box->{eltstack}}, $cell_box;
				}

			}

			if ($j > $self->{cells}) {
				$self->{cells} = $j;
			}

            $row_heights[$i] = $max_h;
            
			$i++;
			$j = 0;

            push (@row_boxes, $row_box);
		}
	}

	$self->{rows} = $i;
	$self->{data} = \@data;

    # adjusting cell widths and attaching to table box element
    for my $i (0 .. $self->{rows} - 1) {
        $box->{eltmap}->{$row_boxes[$i]->{elt}} = $row_boxes[$i]; 

        for my $j (0 .. @{$data[$i]} - 1) {
            $data[$i]->[$j]->{box}->{box}->{width} = $self->{cell_widths}->[$j];
            $data[$i]->[$j]->{box}->{box}->{height} = $row_heights[$i];
            
            $data[$i]->[$j]->{bounding}->{max_w} = $self->{cell_widths}->[$j];
            $data[$i]->[$j]->{bounding}->{max_h} = $row_heights[$i];
        }
    }
    
    $self->{info} = {rows => $self->{rows},
                     cells => $self->{cells},
                     row_heights => \@row_heights,
                     cell_widths => $self->{cell_widths},
    };

    $box->{eltstack} = \@row_boxes;
    
	return $self->{info};
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
