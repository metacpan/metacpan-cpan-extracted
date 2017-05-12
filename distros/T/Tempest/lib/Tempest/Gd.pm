=head1 NAME

Tempest::Gd - GD adapter for Tempest heat-map generator

=head1 DESCRIPTION

Implements L<Tempest|Tempest> image operations using the L<GD|GD> module.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Evan Kaufman, all rights reserved.

This program is released under the MIT license.

L<http://www.opensource.org/licenses/mit-license.php>

=head1 ADDITIONAL LINKS

=over

=item LibGD:

L<http://www.libgd.org/>

=back

=cut

package Tempest::Gd;

use strict;
use warnings;

use Carp;
use GD;

sub render {

    my $parent = shift;
    
    # create truecolor images by default
    GD::Image->trueColor(1);
    
    # load source image (in order to get dimensions)
    my $input_file = GD::Image->new($parent->get_input_file());
    
    # create object for destination image
    my $output_file = GD::Image->newTrueColor($input_file->width, $input_file->height);
    my $white = $output_file->colorAllocate(255,255,255);
    $output_file->fill(0, 0, $white);
    
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
    my $plot_file = GD::Image->new($parent->get_plot_file());
    
    # calculate coord correction based on plot image size
    my @plot_correct = ( ($plot_file->width / 2), ($plot_file->height / 2) );
    
    # colorize opacity for how many times at most a point will be repeated
    my $colorize_percent = 99 / $max_rep;
    if($colorize_percent < 1) { $colorize_percent = 1; }
    colorize($plot_file, $colorize_percent);
    
    # paste one plot for each coordinate pair
    for my $pair (@{$coordinates}) {
        my $x = ($pair->[0] - $plot_correct[0]);
        my $y = ($pair->[1] - $plot_correct[1]);
        
        # for how many times coord pair was repeated
        for (1..$pair->[2]) {
            # paste plot, centered on given coords
            composite($output_file, $plot_file, $x, $y);
        }
    }
    
    # destroy plot file, as we don't need it anymore
    undef $plot_file;
    
    # open color lookup table
    my $color_file = GD::Image->new($parent->get_color_file());
    
    # apply color lookup table
    my %cached_colors;
    for my $x (0..$output_file->width) {
        for my $y (0..$output_file->height) {
            # calculate color lookup location
            my $pixel_red = ($output_file->rgb( $output_file->getPixel($x, $y) ))[0];
            
            # cache colors as we look them up
            my @lookup_color;
            if(exists($cached_colors{$pixel_red})) {
                @lookup_color = @{ $cached_colors{$pixel_red} };
            }
            else {
                my $color_offset = ($pixel_red / 255) * ($color_file->height - 1);
                @lookup_color = $color_file->rgb( $color_file->getPixel(0, $color_offset) );
                $cached_colors{$pixel_red} = \@lookup_color;
            }
            
            # allocate and set new color from lookup table
            my $new_color = $output_file->colorAllocate(@lookup_color);
            $output_file->setPixel($x, $y, $new_color);
            $output_file->colorDeallocate($new_color);
        }
    }
    
    # overlay heatmap over source image
    if($parent->get_overlay()) {
        $input_file->copyMerge($output_file, 0, 0, 0, 0, $output_file->width, $output_file->height, $parent->get_opacity());
        undef $output_file;
        $output_file = $input_file;
    }
    
    # write to output file
    write_image($output_file, $parent->get_output_file());
    
    return 1;
}

sub write_image {
    my $image_file = shift;
    my $filename = shift;
    
    my $filetype;
    
    if(($filetype) = $filename =~ m/\.(png|gif|jpe?g|gd2?|wbmp)$/i) {
        $filetype = lc($filetype);
        if($filetype eq 'jpe' || $filetype eq 'jpeg') {
            $filetype = 'jpg';
        }
        
        my $image_data = $image_file->$filetype;
        open(PNGFILE, '>', $filename) or croak("Failed to write output image: $!");
        binmode PNGFILE;
        print PNGFILE $image_data;
        close(PNGFILE);
        return;
    }
    croak("Failed to detect a supported file extension in file '$filename'");
}

sub composite {
    my($source_image, $composite_image, $x, $y) = @_;
    
    # set aside space to cache colors
    my %cached_colors;
    
    # for each pixel from x to x+composite_width
    my $composite_x = $composite_image->width - 1;
    my $composite_y = $composite_image->height - 1;
    foreach my $x_offset (0..$composite_x) {
        foreach my $y_offset (0..$composite_y) {
            my $source_x = ($x + $x_offset);
            my $source_y = ($y + $y_offset);
            
            # skip negative coordinates
            if($source_x < 0 || $source_y < 0) { next; }
            
            # get colors to composite together
            my @source_color = $source_image->rgb( $source_image->getPixel($source_x, $source_y) );
            my @composite_color = $composite_image->rgb( $composite_image->getPixel($x_offset, $y_offset) );
            
            # multiply colors together, caching them within the same composite call
            my $cache_key = join(',', @source_color) . 'x' . join(',', @composite_color);
            my @multiplied;
            if(exists($cached_colors{$cache_key})) {
                @multiplied = @{ $cached_colors{$cache_key} };
            }
            else {
                @multiplied = multiply(\@source_color, \@composite_color);
                $cached_colors{$cache_key} = \@multiplied;
            }
            
            # allocate and set new colors after multiplication
            my $color = $source_image->colorAllocate(@multiplied);
            $source_image->setPixel($source_x, $source_y, $color);
            $source_image->colorDeallocate($color);
        }
    }
}

sub colorize {
    my $image_file = shift;
    my $opacity = shift;
    
    # set aside space to cache colors
    my %cached_colors;
    
    # reduce percentage to fraction
    $opacity = (100 - $opacity) / 100;
    
    # get dimensions once
    my $image_width = ($image_file->width - 1);
    my $image_height = ($image_file->height - 1);
    
    # iterate through each pixel in given image
    for my $x (0..$image_width) {
        for my $y (0..$image_height) {
            # get color to colorize
            my @color = $image_file->rgb( $image_file->getPixel($x, $y) );
            
            # cache colors as we colorize them
            my $cache_key = join(',', @color);
            if(exists($cached_colors{$cache_key})) {
                @color = @{ $cached_colors{$cache_key} };
            }
            else {
                for my $i (0..2) {
                    $color[$i] = $color[$i] + ((255 - $color[$i]) * $opacity);
                }
                $cached_colors{$cache_key} = \@color;
            }
            
            # allocate and set new colors after colorization
            my $color = $image_file->colorAllocate(@color);
            $image_file->setPixel($x, $y, $color);
            $image_file->colorDeallocate($color);
        }
    }
}

sub multiply {
    my $color1 = shift;
    my $color2 = shift;
    my @product;
    
    for my $i (0..2) {
        $product[$i] = (($color1->[$i] / 255) * ($color2->[$i] / 255)) * 255;
    }
    
    return @product;
}

1;
