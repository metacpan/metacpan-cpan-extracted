#!/usr/bin/perl -w
# $Id: pmd_grapher.plx 6643 2006-07-12 20:23:31Z timbo $

use strict;
use Getopt::Std;
use Module::Dependency::Info;
use Module::Dependency::Grapher;
use Data::Dumper;

### EDIT THIS LINE - New versions of GD do not support GIF
### Set this to 'GIF' or 'PNG' depending on what your GD can handle, or in fact use any of the available formats
### This program will try to guess the format from the filename: this
### value is used when no guess can be made
use constant DEFAULT_FORMAT => 'PNG';

use vars qw/$VERSION $IMGFILE
    $opt_h $opt_t $opt_o $opt_s $opt_r $opt_b $opt_f $opt_m $opt_n
    $kind
    /;

*Module::Dependency::Grapher::TRACE = \*TRACE;

getopts('hto:m:n:s:rbf:');
if ($opt_h) { usage(); }

$VERSION = (q$Revision: 6643 $ =~ /(\d+)/g)[0];

$IMGFILE = shift || usage();

Module::Dependency::Grapher::setIndex($opt_o) if $opt_o;

# what modules/scripts will be included
my $objlist;
my $title;
$kind = 'child';
if ($opt_s) {
    TRACE("Trying to start tree with $opt_s");

    my $plural = '';
    if ( index( $opt_s, ',' ) > -1 ) {
        $objlist = [ split( /,\s*/, $opt_s ) ];
        $plural = 's';
    }
    else {
        $objlist = [$opt_s];
    }

    if ($opt_b) {
        $kind  = 'both';
        $title = "Parent & child dependencies for package$plural $opt_s";
    }
    elsif ($opt_r) {
        $kind  = 'parent';
        $title = "Parent dependencies for package$plural $opt_s";
    }
    else {
        $title = "Dependencies for package$plural $opt_s";
    }
}
else {
    TRACE("Trying to start tree with all scripts");
    $title   = 'Dependencies for all scripts';
    $objlist = Module::Dependency::Info::allScripts();
}

# deduce format
my $format;
if ($opt_f) {
    $format = uc($opt_f);
}
else {
    if ( $IMGFILE =~ /\.gif$/i ) {
        $format = 'GIF';
    }
    elsif ( $IMGFILE =~ /\.png$/i ) {
        $format = 'PNG';
    }
    elsif ( $IMGFILE =~ /\.ps$/i ) {
        $format = 'PS';
    }
    elsif ( $IMGFILE =~ /\.eps$/i ) {
        $format = 'EPS';
    }
    elsif ( $IMGFILE =~ /\.txt$/i ) {
        $format = 'TEXT';
    }
    elsif ( $IMGFILE =~ /\.svg$/i ) {
        $format = 'SVG';
    }
    elsif ( $IMGFILE =~ /\.s?html?$/i ) {
        $format = 'HTML';
    }
    else {
        $format = DEFAULT_FORMAT;
    }
}

TRACE("Format deduced to be $format");

if ( $format eq 'TEXT' ) {
    Module::Dependency::Grapher::makeText( $kind, $objlist, $IMGFILE,
        { Title => $title, IncludeRegex => $opt_m, ExcludeRegex => $opt_n } );
}
elsif ( $format eq 'HTML' ) {
    Module::Dependency::Grapher::makeHtml( $kind, $objlist, $IMGFILE,
        { Title => $title, IncludeRegex => $opt_m, ExcludeRegex => $opt_n } );
}
elsif ( $format eq 'SVG' ) {
    Module::Dependency::Grapher::makeSvg( $kind, $objlist, $IMGFILE,
        { Title => $title, IncludeRegex => $opt_m, ExcludeRegex => $opt_n } );
}
elsif ( $format eq 'PS' ) {
    Module::Dependency::Grapher::makePs( $kind, $objlist, $IMGFILE,
        { Title => $title, Format => 'PS', IncludeRegex => $opt_m, ExcludeRegex => $opt_n } );
}
elsif ( $format eq 'EPS' ) {
    Module::Dependency::Grapher::makePs( $kind, $objlist, $IMGFILE,
        { Title => $title, IncludeRegex => $opt_m, ExcludeRegex => $opt_n } );
}
else {
    Module::Dependency::Grapher::makeImage( $kind, $objlist, $IMGFILE,
        { Title => $title, Format => $format, IncludeRegex => $opt_m, ExcludeRegex => $opt_n } );
}

TRACE("Done!");

### END OF MAIN

sub usage {
    while (<DATA>) { last if / NAME/; }
    while (<DATA>) {
        last if / DESCRIPTION/;
        s/^\t//;
        s/^=head1 //;
        print;
    }
    exit;
}

sub TRACE {
    return unless $opt_t;
    my $msg = shift;
    print STDERR "> $msg\n";
}

__DATA__

=head1 NAME

pmd_grapher - display Module::Dependency info in a graphical manner

=head1 SYNOPSIS

	pmd_grapher.plx [-h] [-t]
		[-f FORMAT] [-o <datafile>]
		[-m REGEX] [-n REGEX] [-s START_AT [-r] [-b]]
		<filename>

	-h Displays this help
	-t Displays tracing messages
	-f Choose an output format - default is 'png'
	   'text' - Output with the makeText method to emit a plaintext tree.
	   'html' - Output with the makeHtml method to emit an HTML fragment.
	   'gif'/'png' - Output an image.
	   'ps'/'eps' - Output (Encapsulated) PostScript (requires PostScript::Simple)
	   'svg' - Scalable Vector Graphic
	-o the location of the datafile (default is $ENV{PERL_PMD_DB} or /var/tmp/dependence/unified.dat)
	-m Optional regular expression - only show dependencies that match this expression
	-n Optional regular expression - do not show dependencies that match this expression
	-s Starts the dependency tree at this script/module
	   Default is to start with ALL scripts
	   Can be like 'foo,bar' to start with a list of items.
	-r Reverse dependency, i.e. show the things that depend upon
	   a package, not the things a package depends upon.
	   The default is to show forward dependencies only.
	-b Both ways dependency - show parents and children.
	<filename> The file where you want to send the output.
	   Use - for STDOUT.
	
	NB: If no -f option is supplied we guess the format by looking at the
	filename. If we still can't guess then the default is used - PNG.

=head1 EXAMPLE

	pmd_grapher.plx -t -s Module::Dependency::Info -o ./unified.dat foo.gif

=head1 DESCRIPTION

The best way to show and understand dependency relations is using a tree diagram.
This program creates a visual dependency tree, going in both directions if required 
to give parent and/or child relationships.

=head1 VERSION

$Id: pmd_grapher.plx 6643 2006-07-12 20:23:31Z timbo $

=cut


