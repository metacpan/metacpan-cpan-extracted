#!/usr/bin/perl

# Created on: 2006-05-05 22:44:23
# Create by:  ivan
# $Id$
# # $Revision$, $HeadURL$, $Date$
# # $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Scalar::Util;
use Getopt::Long;
use Pod::Usage;
use Config::Std;
use Data::Dumper qw/Dumper/;
use SVG::Calendar;
use Path::Tiny;
use FindBin qw/$Bin/;

our $VERSION = version->new('0.3.13');

my %option = (
    moon     => {},
    date     => {},
    ical     => {},
    page     => {},
    image    => {},
    height   => 0.5,
    config   => "$ENV{HOME}/.svgcal",
    path     => undef,
    template => undef,
    verbose  => 0,
    man      => 0,
    help     => 0,
    VERSION  => 0,
);

if ( !@ARGV ) {
    pod2usage( -verbose => 1 );
}

main();
exit 0;

sub main {
    Getopt::Long::Configure('bundling');
    GetOptions(
        \%option,
        'moon|m=s%',
        'date|d=s%',
        'ical|c=s%',
        'page|p=s%',
        'image|i=s%',
        'calendar_height|height|h=s',
        'config|C=s',
        'path|P=s',
        'template|t=s',
        'out|o=s',
        'save|s',
        'show-template',
        'verbose|v!',
        'man',
        'help',
        'VERSION'
    ) or pod2usage(2);

    if ( $option{VERSION} ) {
        print "svgcal.pl Version = $VERSION\n";
        exit 1;
    }
    elsif ( $option{man} ) {
        pod2usage( -verbose => 2 );
    }
    elsif ( $option{help} ) {
        pod2usage( -verbose => 1 );
    }
    elsif ( !$option{date} ) {
        warn "No dates specified, nothing to do!\n";
        pod2usage( -verbose => 1 );
    }

    # do stuff here
    my $cal;

    if ( $option{save} && !-f $option{config} ) {
        open my $fh, '>', $option{config} or warn "Cannot create the configuration file '$option{config}': $!";  ## no critic
        if ($fh) {
            print {$fh} "\n" or print {*STDERR} "Cannot print to file '$option{config}': $!\n";
            close $fh or print {*STDERR} "Cannot close file '$option{config}': $!\n";
        }
    }

    if (@ARGV) {
        for my $img (grep {/=/} @ARGV) {
            my ($month, $src) = split /=/, $img, 2;
            $option{image}{$month} = $src;
        }
    }

    if (
        $option{image}{dir}
        && -d $option{image}{dir}
        && $option{date}
        && $option{date}{year}
    ) {
        my $year = $option{date}{year};
        for my $i ( 1 .. 12 ) {
            my $month = $i < 10 ? "0$i" : $i;
            $option{image}{"$year-$month"} = "$option{image}{dir}/$month.jpg";
        }
    }

    if ( $option{'show-template'} ) {
        show_template();
    }

    my %config = get_config();
    $cal = SVG::Calendar->new(%config);

    if ( $option{verbose} ) {
        $cal->{verbose} = $option{verbose};
    }

    if ( $option{date}{month} ) {
        $cal->output_month( $option{date}{month}, $option{out} || q/-/ );
    }
    else {
        die "No page output file name base specified!\n" if !$option{out};  ## no critic

        if ( $option{date}{year} ) {
            $cal->output_year( $option{date}{year}, $option{out} );
        }
        else {
            $cal->output_year( $option{date}{start}, $option{date}{end}, $option{out} );
        }
    }

    return;
}

sub show_template {

    require File::ShareDir;
    my $dir = path( eval { File::ShareDir::dist_dir('SVG-Calendar') } || ( $Bin, '..', 'templates' )  );
    print $dir->path('calendar.svg')->slurp;

    return exit 0;
}

sub get_config {
    if ( !-f $option{config} ) {
        template_config($option{config});
    }

    read_config $option{config} => my %config;

OPTION:
    for my $key ( keys %option ) {
        next OPTION if !ref $option{$key};

        for my $subkey ( keys %{ $option{$key} } ) {

            # override the config file settings
            $config{$key}{$subkey} = $option{$key}{$subkey};
        }
    }

    if ( $option{page} ) {
        $config{page} = $option{page};
    }
    if ( $option{path} ) {
        $config{path} = $option{path};
    }
    if ( $option{template} ) {
        $config{template} = $option{template};
    }
    if ( $option{image} ) {
        $config{image} = $option{image};
    }

    if ( $option{save} && -f $option{config} ) {
        write_config %config;
    }

    return %config;
}

sub template_config {
    my ($file) = @_;

    open my $fh, '>', $file or return;

    print {$fh} <<"CONFIG";
# this section configures the information about the images
[image]

# src
# This allows specifying one image file.
# src: image.jpg

# YYYY-MM
# This is the format for specifying a specific month's image
#2012-01: car.gif
#2012-02: horse.tiff

# dir
# This option allows the specifying of a directory to contain all the images
# for the months that calendars are going to be produced. The images should
# in the directory be specified as MM.[jpg|png] or month.[jpg|png] eg 01.jpg
# or January.png
#dir: .

# The page section sets up the SVG document size
[page]

# page
# This allows you to specify specific page sizes eg A4. Known page sizes
# include A0, A1, A2, A3, A4, A5, A6
#page: A4

# height
# If the svg document size is not one of the predefined sizes you can use
# this setting to set the height of the document. If no units are specified
# the height is in pixels.
#height: 200mm

# width
# Like height you set the SVG document size to an arbitart width
#width: 10cm

# This section controlls the displaying of the moon on the produced calendars
[moon]

# display
# Turn on displaying of the moon (requires Astro::Coord::ECI::Moon or
# Astro::MoonPhase to be installed)
#display: 1
display: 0

# quarters
# Toggles weather to only display the moon for the various quarters or to
# show what phase the moon is in for every day.
#quarters: 1
quarters: 0

# vpos
# Specifies weather the moon should be aligned with the top or bottom of the
# day's square.
#vpos: top

# hpos
# Specifies weather the moon should be aligned with the left or right hand
# side of the day's square.
#hpos: right

# xoffset, yoffset
# These parameters specify the x and y offsets of the moon, the units are
# relative units (ie page size independant) with the size of the dates square
# being approximatly 10x16
#xoffset: 10
#yoffset: 10

# radius
# This specifies the size of the moon in the date's square
#radius: 1.0

# image
# This option specifies an image file that will be used as the background for
# the moon.
#image: moon.jpg

CONFIG

    close $fh;

    return;
}

__DATA__

=head1 NAME

svgcal.pl - Creates the pages for a calendar in SVG format

=head1 VERSION

This documentation refers to svgcal.pl version 0.3.13.

=head1 SYNOPSIS

   svgcal.pl [option] --date {see below}
   svgcal.pl [--verbose | --VERSION | --help | --man]

 OPTIONS:
  -o --out=str   The base file name when out putting multiple months
  -d --date      Parameters that control the months displaied on the
                 calendar
    start=YYYY-MM   Start month
    end=YYYY-MM     End month
    year=YYYY       Year to base the whole calendar on (Default next year)
    month=YYYY-MM   Display only this month
  -m --moon      Moon parameters
    display=1       Display the moon on individual days
    quarters=1|0    Show only whole quarters
    vpos=top|bottom Specifies which quadrent the moon should appear in
    hpos=left|right as above
    xoffset=num     Precisly set the x position of moon
    yoffset=num     Precisly set the y position of moon
    radius=n%       The radius as a percentage of day box width
    image=url       An image of the moon to use as the fill background of
                    the moon
  -c --ical      ICal parameters
  -p --page      Specify a page type or a height or width of the page
    page=A0..A6     The page type
    height=size     The page height (with optional units)
    width=size      The page width (with optional units)
  -i --image     Specifies the images to be displayed on the calendar
    src=file        This image will be used for any image with out a specific
                    month image.
    dir=directory   Finds images in the directory named after the months
                    (eg 01-12 or January-December)
    YYYY-MM=file    Use this image for the specified month
  -h --height    The height on the page that the calendar shoud take up.
                 Either a fraction or a percent (Default 50%)
  -C --config    Location of the configuration file (Default ~/.svgcal)
  -P --path=template path
                 Specify a colon seperated path to find templates in
  -t --template=template_dir
                 The name of a template directory to use instead of the
                 default templates (expects to find a template there called
                 calendar.svg)
  -s --save      Save any other command line options to your config file
     --show-template
                 Displays the default template used by SVG::Calendar,
                 this is useful if you want to change the default template

  -v --verbose   Show more detailed option
     --version   Prints the version information
     --help      Prints this help information
     --man       Prints the full documentation for svgcal.pl

=head1 DESCRIPTION

This script provides a command line interface to the SVG::Calendar library. Most
of the functionality is exposed here.

=head2 Configuration

To make configuration using this tool options can be saved to thee ~/.svgcal
file. The format of the configuration file is similar to INI files. The
easiest way to start using the configuration file is once you have set up
the options that you like use the --save option which will write the current
configuration to the file. If you use --save again the file should be updated
leaving comments in place.

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2009 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW, Australia 2077)
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
