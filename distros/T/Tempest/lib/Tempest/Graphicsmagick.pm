=head1 NAME

Tempest::Graphicsmagick - PerlMagick adapter for Tempest heat-map generator

=head1 DESCRIPTION

Implements L<Tempest|Tempest> image operations using the
L<Graphics::Magick|Graphics::Magick> module.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Evan Kaufman, all rights reserved.

This program is released under the MIT license.

L<http://www.opensource.org/licenses/mit-license.php>

=head1 ADDITIONAL LINKS

=over

=item GraphicsMagick:

L<http://graphicsmagick.org/>

=back

=cut

package Tempest::Graphicsmagick;

use strict;
use warnings;

use Carp;
use Graphics::Magick;

sub render {
    my $parent = shift;
    
    # load source image (in order to get dimensions)
    my $input_file = Graphics::Magick->new;
    $input_file->Read($parent->get_input_file());
    
    # create object for destination image
    my $output_file = Graphics::Magick->new;
    $output_file->Set( 'size' => join('x', $input_file->Get('width', 'height')) );
    $output_file->ReadImage('xc:white');
    
    # do any necessary preprocessing & transformation of the coordinates
    my $coordinates = $parent->get_coordinates();
    my $max_rep = 0;
    my %normal;
    for my $pair (@{$coordinates}) {
        # normalize repeated coordinate pairs
        my $pair_key = $pair->[0] . 'x' . $pair->[1];
        if(exists $normal{$pair_key}) {
            $normal{$pair_key}->[2]++;
        }
        else {
            $normal{$pair_key} = [$pair->[0], $pair->[1], 1];
        }
        # get the max repitition count of any single coord set in the data
        if($normal{$pair_key}->[2] > $max_rep) {
            $max_rep = $normal{$pair_key}->[2];
        }
    }
    $coordinates = [ values(%normal) ];
    undef %normal;
    
    # load plot image (presumably greyscale)
    my $plot_file = Graphics::Magick->new;
    $plot_file->Read($parent->get_plot_file());
    
    # calculate coord correction based on plot image size
    my @plot_correct = ( ($plot_file->Get('width') / 2), ($plot_file->Get('height') / 2) );
    
    # colorize opacity for how many times at most a point will be repeated
    my $colorize_percent = 100 - int(99 / $max_rep);
    if($colorize_percent > 99) { $colorize_percent = 99; }
    $plot_file->Colorize('fill' => 'white', 'opacity' => $colorize_percent . '%');
    
    # paste one plot for each coordinate pair
    for my $pair (@{$coordinates}) {
        my $x = ($pair->[0] - $plot_correct[0]);
        my $y = ($pair->[1] - $plot_correct[1]);
        
        # for how many times coord pair was repeated
        for(1..$pair->[2]) {
            # paste plot, centered on given coords
            $output_file->Composite('image' => $plot_file, 'compose' => 'Multiply', 'x' => $x, 'y' => $y );
        }
    }
    
    # destroy plot file, as we don't need it anymore
    undef $plot_file;
    
    # apply color lookup table with clut method if available

    # TBD: use hald-clut mogrification when support is implemented (not as of 1.4 from cvs 2009/10/05?)
    # get color lookup image
    my $color_file = Graphics::Magick->new;
    $color_file->Read($parent->get_color_file());
    # apply color lookup table
    my %cached_colors;
    my @output_size = $output_file->Get('width', 'height');
    my @color_size = $color_file->Get('width', 'height');
    for my $x (1..$output_size[0]) {
        for my $y (1..$output_size[1]) {
            # calculate color lookup location
            my $pixel_red = (split(',', $output_file->Get('pixel['.$x.','.$y.']')))[0];

            # cache colors as we look them up
            my $lookup_color;
            if(exists($cached_colors{$pixel_red})) {
                $lookup_color = $cached_colors{$pixel_red};
            }
            else {
                my $color_offset = ($pixel_red / 255) * ($color_size[1] - 1);
                $lookup_color = $color_file->Get('pixel[0,'.$color_offset.']');
                $cached_colors{$pixel_red} = $lookup_color;
            }

            # set new color from lookup table
            $output_file->Set('pixel['.$x.','.$y.']', $lookup_color);
        }
    }
    
    # overlay heatmap over source image
    if($parent->get_overlay()) {
        $input_file->Composite('image' => $output_file, 'compose' => 'Over', 'opacity' => 255 * ($parent->get_opacity() / 100) );
        undef $output_file;
        $output_file = $input_file;
    }
    
    # write destination image
    $output_file->Write($parent->get_output_file());
    
    # return true if successful
    return 1;
}

1;
