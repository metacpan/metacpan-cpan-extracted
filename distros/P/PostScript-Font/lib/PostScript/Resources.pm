# RCS Status      : $Id: Resources.pm,v 1.12 2004/12/18 16:40:52 jv Exp $# Author          : Johan Vromans
# Created On      : Januari 1999
# Last Modified By: Johan Vromans
# Last Modified On: Thu Oct 23 14:11:52 2003
# Update Count    : 187
# Status          : Released

################ Module Preamble ################

package PostScript::Resources;

use strict;

BEGIN { require 5.005; }

use IO qw(File);
use File::Basename;
use File::Spec;

use vars qw($VERSION);
$VERSION = "1.03";

my $ResourcePath = ".";		# default standard resource path
my $defupr = "PSref.upr";	# principal resource file
my $fn;				# file currently being loaded
my $fh;				# handle of file currently being loaded
my $section;			# section currently being loaded
my $exclusive;			# last loaded file was exclusive
my $rscidx;			# current resource index

my $trace;
my $debug;
my $verbose;
my $error;

sub new {
    my $class = shift;
    my (%atts) = (path    => $ENV{"PSRESOURCEPATH"} || "::",
		  stdpath => $ResourcePath,
		  error   => 'die',	# 'die', 'warn' or 'ignore'
		  verbose => 0,
		  trace   => 0,
		  debug   => 0,
		  @_);

    $debug   =           lc($atts{debug});
    $trace   = $debug || lc($atts{trace});
    $verbose = $trace || lc($atts{verbose});
    $error   = lc($atts{error});

    my $self = {};
    bless $self, $class;

    # Get the resource paths.
    my $path = $atts{path};
    $path =~ s|::|:$atts{stdpath}:|g;
    $path =~ s|^:||;

    # According to the specs, the file names are either literal,
    # absolute or relative. In the latter case, the current prefix
    # (which defaults to the directory of the .upr file) must be
    # appended.
    # To avoid lots of unnecessary file name parsing, each prefix
    # will be stored in a prefix array, and the index in this array
    # will be prepended to each file name entry.
    # The costly filename manipulation will only be done when a
    # filename needs to be returned (sub _buildfilename).

    # Create the prefix array and reset the index.
    $self->{prefix} = [];
    $rscidx = 0;

    # Process the entries in the list.
    foreach my $rsc ( split (":", $path) ) {

	print STDERR ("rsc#$rscidx: $rsc <file>\n") if $debug;

	if ( -d $rsc ) {
	    print STDERR ("rsc#$rscidx: $rsc <dir>\n") if $debug;

	    # Directory.
	    $exclusive = 0;

	    # First check for a PSres.upr, and load it if possible.
	    $fn = File::Spec->catfile ($rsc, "PSres.upr");
	    if ( -f $fn ) {
		print STDERR ("rsc#$rscidx: load $fn\n") if $debug;
		$rscidx++;
		eval { _loadFile ($self) };
		if ( $@ ) {
		    die ($@)  if $error eq "die";
		    warn ($@) if $error eq "warn";
		    next;
		}
	    }

	    # Unless PSres.upr was an exclusive resource, load all
	    # files with .upr extension.
	    unless ( $exclusive ) {
		my $dh = do { local *DH };
		opendir ($dh, $rsc);
		my @files = grep (/\.upr$/, readdir ($dh));
		closedir ($dh);
		foreach my $file ( @files ) {
		    # Skip the PSres.upr. It is already loaded.
		    next if $file eq "PSres.upr";

		    $fn = File::Spec->catfile ($rsc, $file);
		    print STDERR ("rsc#$rscidx: load $fn\n") if $debug;
		    $rscidx++;
		    eval { _loadFile ($self) };
		    if ( $@ ) {
			die ($@)  if $error eq "die";
			warn ($@) if $error eq "warn";
			next;
		    }
		}
	    }
	}
	else {

	    # File. This is _not_ defined in the specs.

	    $fn = $rsc;
	    print STDERR ("rsc#$rscidx: load $fn\n") if $debug;
	    $rscidx++;
	    eval { _loadFile ($self) };
	    if ( $@ ) {
		die ($@)  if $error eq "die";
		warn ($@) if $error eq "warn";
		next;
	    }
	}
    }

    $self;
}

sub FontAFM ($$) {
    my ($self, $font) = @_;
    return _buildfilename ($self, $font)
      if defined ($font = $self->{FontAFM}->{$font});
    undef;
}

sub FontOutline ($$) {
    my ($self, $font) = @_;
    return _buildfilename ($self, $font)
      if defined ($font = $self->{FontOutline}->{$font});
    undef;
}

sub _buildfilename ($$) {
    my ($self, $name) = @_;
    my $i;
    ($i, $name) = unpack ("IA*", $name);
    return $1 if $name =~ /^=(.*)$/;
    return $name if File::Spec->file_name_is_absolute ($name);
    File::Spec->canonpath (File::Spec->catfile ($self->{prefix}->[$i], $name));
}

sub _loadFile ($) {

    my ($self) = @_;

    my $data;			# data

    eval {			# so we can use die

	$fh = new IO::File;	# font file
	my $sz = -s $fn;	# file size

	$fh->open ($fn) || die ("$fn: $!\n");
	print STDERR ($fn, ": Loading Resources\n") if $verbose;

	# Read in the data.
	my $line = <$fh>;
	die ($fn."[$.]: Unrecognized file format\n")
	  unless $line =~ /^PS-Resources-(Exclusive-)?([\d.]+)/;
	$exclusive = defined $1;
	my $version = $2;

	# The resources file is organised in sections, each starting
	# with the section name and terminated by a line with just
	# a period.
	# Following the first PS-Resources line, the sections are
	# enumerated, e.g.:
	#
	#  PS-Resources-1.0
	#  FontAFM
	#  FontOutlines
	#  FontFamily
	#  FontPrebuilt
	#  FontBDF
	#  FontBDFSizes
	#  .
	#
	# Optionally, the name of the resource directory follows. It
	# is preceded with a slash, e.g.:
	#
	#  //usr/share/psresources
	#
	# This is then followed by each of the sections, e.g.:
	#
	#  FontAFM
	#  ... afm info ...
	#  .
	#  FontOutlines
	#  ... outlines info ...
	#  .
	#  FontFamily
	#  ... family info ...
	#  .
	#
	# Backslash escapes are NOT handled, except for continuation.
	#
	# We have a _loadXXX subroutine for each section, where XXX is
	# the section name. Flexible and extensible.
	#
	# The current approach is to ignore the first section.

	$self->_skipSection ($fh);

	# Then, load the sections from the file, skipping unknown ones.

	my $checkdir = 1;
	while ( defined ($section = _readLine ($self, $fh)) ) {
	    chomp ($section);
	    if ( $checkdir && $section =~ /^\/(.*)/ ) {
		$self->{prefix}->[$rscidx] = $1;
		$checkdir = 0;
		next;
	    }
	    $checkdir = 0;
	    my $loader = defined &{"_load$section"} ? "_load$section" :
	      "_skipSection";
	    no strict 'refs';
	    die ($fn."[$.]: Premature end of $section section\n")
	      if $fh->eof || !$loader->($self);
	}

    };

    # Set the dfeault value for the directory prefix, if necessary.
    $self->{prefix}->[$rscidx] ||= dirname ($fn);

    $fh->close;
    die ($@) if $@;
    $self;
}

sub _readLine () {
    # Read a line, handling continuation lines.
    my $line;
    while ( 1 ) {
	return undef if $fh->eof;
	$line .= <$fh>;
	if ( $line =~ /^(.*)\\$/ ) {
	    $line = $1;
	    redo;
	}
	$line = $1 if $line =~ /^(.*)%/; # remove comments
	$line =~ s/\s+$//;		# remove trailing blanks
	next unless $line =~ /\S/;	# skip empty lines
	return $line;
    }
    continue { $line = "" }
    undef;
}

sub _loadFontAFM ($) {
    my ($self) = @_;
    print STDERR ($fn, "[$.]: Loading section $section\n") if $trace;

    my $afm;
    $afm = $self->{FontAFM} = {}
      unless defined ($afm = $self->{FontAFM});

    my $line;
    my $rscidx = pack ("I", $rscidx);
    while ( defined ($line = _readLine ()) ) {
	return 1 if $line =~ /^\.$/;

	# PostScriptName=the/file.afm
	if ( $line =~ /^([^=]+)=(.*)$/ ) {
	    $afm->{$1} = $rscidx.$2 unless $afm->{$1};
	    next;
	}
	warn ($fn, "[$.]: Invalid FontAFM entry\n")
	  unless $error eq "ignore";
    }
    return 1;
}

sub x_loadFontFamily ($) {
    my ($self) = @_;
    print STDERR ($fn, "[$.]: Loading section $section\n") if $trace;

    my $fam;
    $fam = $self->{FontFamily} = {}
      unless defined ($fam = $self->{FontFamily});

    my $line;
    while ( defined ($line = _readLine ()) ) {
	return 1 if $line =~ /^\.$/;

	# Familiyname=Type1,PostScriptName1,Type2,PostScriptName2,...
	if ( $line =~ /^([^=]+)==?(.*)$/ ) {
	    $fam->{$1} = { split (',', $2) };
	    next;
	}
	warn ($fn, "[$.]: Invalid FontFamily entry\n")
	  unless $error eq "ignore";
    }
    return 1;
}

sub _loadFontOutline ($) {
    my ($self) = @_;
    print STDERR ($fn, "[$.]: Loading section $section\n") if $trace;

    my $pfa;
    $pfa = $self->{FontOutline} = {}
      unless defined ($pfa = $self->{FontOutline});

    my $line;
    my $rscidx = pack ("I", $rscidx);
    while ( defined ($line = _readLine ()) ) {
	return 1 if $line =~ /^\.$/;

	# PostScriptName=the/file.pfa
	if ( $line =~ /^([^=]+)=(.*)$/ ) {
	    $pfa->{$1} = $rscidx.$2 unless $pfa->{$1};
	    next;
	}
	warn ($fn, "[$.]: Invalid FontOutline entry\n")
	  unless $error eq "ignore";
    }
    return 1;
}

sub _skipSection ($) {
    my ($self) = (@_);
    $section ||= "list";
    print STDERR ($fn, "[$.]: Skipping section $section\n") if $trace;

    my $line;
    while ( defined ($line = _readLine ()) ) {
	return 1 if $line =~ /^\.$/;
    }
    return 1;
}

1;

__END__

################ Documentation ################

=head1 NAME

PostScript::Resources - module to fetch data from Unix PostScript Resource 'C<.upr>' files

=head1 SYNOPSIS

  my $rsc = new PostScript::Resources (options);
  print STDOUT $rsc->FontAFM ("Times-Roman"), "\n";

=head1 DESCRIPTION

This package allows Unix font resource files, so called 'C<.upr>'
files, to be read and parsed.

=head1 CONSTRUCTOR

=over 4

=item new ( OPTIONS )

The constructor will initialise the PostScript resource context
by loading all resource files.

=back

=head1 OPTIONS

=over 4

=item path => I<path>

I<path> is a colon-separated list of locations where resource files
are kept. It defaults to the value of the environment variable
C<PSRESOURCEPATH>, which defaults to 'C<::>'.

Two adjacent colons in the path represent the list of default places
in which a component looks for resources. This is also the default
value for users who have not installed private resources. Users with
private resources should end the path with a double colon if they want
their resources to override the system defaults, or begin it with a
double colon if they don't want to override system defaults.

On Unix systems, resource files end with the suffix 'C<.upr>' (for
Unix PostScript resources). The principal resource file in a directory
is named 'C<PSres.upr>'.

If the first line of a principal resource file is
'C<PS-Resources-Exclusive-1.0>', only this file will be loaded and
processing continues with the next entry from the path.

If, however, the first line of the principal resource file is
'C<PS-Resources-1.0>', or if there is no such file, all files in the
directory with the suffix 'C<.upr>' will be loaded.

=item stdpath => I<path>

The standard locations for resource files.

=item error => [ 'die' | 'warn' | 'ignore' ]

How errors must be handled.

Invalid entries in the file are always reported unless the error
handling strategy is set to 'ignore'.

=item verbose => I<value>

Prints verbose info if I<value> is true.

=item trace => I<value>

Prints tracing info if I<value> is true.
trace' and 'Implies 'verbose'.

=item debug => I<value>

Prints debugging info if I<value> is true.
Implies 'trace' and 'verbose'.

=back

=head1 INSTANCE METHODS

Each of these methods can return C<undef> if the corresponding
information could not be found in the file.

=over 4

=item FontAFM ( FONTNAME )

The name of the Adobe Font Metrics (.afm) file for the named font.

=item FontOutline ( FONTNAME )

The name of the PostScript Font program for the named font.

=back

=head1 ENVIRONMENT VARIABLES

=over 4

=item PSRESOURCEPATH

The list of directories where resource files are kept. Semantics are
as defined in appendix A of I<Display PostScript Toolkit for X>, Adobe
Technical Note C<DPS.refmanuals.TK.pdf>.

=back

=head1 KNOWN BUGS AND LIMITATIONS

Only FontAFM and FontOutline resources are implemented. All other resource sections are ignored.

All info is loaded in memory structures. This is okay for small
files or if several lookups are done on the same file.

Backslash escape processing is not yet implemented, except for the
handling of line continuation.

This module is intended to be used on Unix systems only.
Your mileage on other platforms may vary.

=head1 SEE ALSO

=over 4

=item http://partners.adobe.com/asn/developer/PDFS/TN/DPS.refmanuals.TK.pdf

The specification of the Adobe Display PostScript Toolkit for X. The
format of the font resources file is described in appendix A of this
document.

=back

=head1 AUTHOR

Johan Vromans, Squirrel Consultancy <jvromans@squirrel.nl>

=head1 COPYRIGHT and DISCLAIMER

This program is Copyright 2000,1999 by Squirrel Consultancy. All
rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either: a) the GNU General Public License as
published by the Free Software Foundation; either version 1, or (at
your option) any later version, or b) the "Artistic License" which
comes with Perl.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either the
GNU General Public License or the Artistic License for more details.

=cut
