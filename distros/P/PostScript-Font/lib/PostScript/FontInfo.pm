# RCS Status      : $Id: FontInfo.pm,v 1.12 2003-10-23 14:12:27+02 jv Exp $
# Author          : Johan Vromans
# Created On      : December 1998
# Last Modified By: Johan Vromans
# Last Modified On: Thu Oct 23 14:12:25 2003
# Update Count    : 57
# Status          : Released

################ Module Preamble ################

package PostScript::FontInfo;

use strict;

BEGIN { require 5.005; }

use IO qw(File);

use vars qw($VERSION);
$VERSION = "1.05";

sub new {
    my $class = shift;
    my $font = shift;
    my (%atts) = (error => 'die',
		  verbose => 0, trace => 0, debug => 0,
		  @_);
    my $self = { file => $font };
    bless $self, $class;

    return $self unless defined $font;

    $self->{debug}   = $atts{debug};
    $self->{trace}   = $self->{debug} || $atts{trace};
    $self->{verbose} = $self->{trace} || $atts{verbose};

    my $error = lc($atts{error});
    $self->{die} = sub {
	die(@_)     if $error eq "die";
	warn(@_)    if $error eq "warn";
    };

    eval {
	$self->_loadinfo;
    };

    if ( $@ ) {
	$self->_die($@);
	return undef;
    }

    $self;
}

sub FileName	{ my $self = shift; $self->{file};    }
sub FontName	{ my $self = shift; $self->{name};    }
sub FullName	{ my $self = shift; $self->{fullname};}
sub InfoData	{ my $self = shift; $self->{data};    }
sub FontFamily	{ my $self = shift; $self->{family};  }
sub Version	{ my $self = shift; $self->{version}; }
sub PCFileNamePrefix { my $self = shift; $self->{pcprefix}; }

sub _loadinfo ($) {

    my ($self) = shift;

    my $data;			# inf data

    eval {			# so we can use die

	my $fn = $self->{file};
	my $fh = new IO::File;	# font file
	my $sz = -s $fn;	# file size

	$fh->open ($fn) || $self->_die("$fn: $!\n");
	print STDERR ("$fn: Loading INF file\n") if $self->{verbose};

	# Read in the inf data.
	my $len = 0;
	while ( $fh->sysread ($data, 32768, $len) > 0 ) {
	    $len = length ($data);
	}
	$fh->close;
	print STDERR ("Read $len bytes from $fn\n") if $self->{trace};
	$self->_die("$fn: Expecting $sz bytes, got $len bytes\n") unless $sz == $len;

	# Normalise line endings.
	$data =~ s/\015\012?/\n/g;

	if ( $data !~ /^FontName\s+\(\S+\)$/m ) {
	    $self->_die("$fn: Not a recognizable INF file\n");
	}

    };

    $self->{name}    = $1 if $data =~ /^FontName\s+\((\S+)\)$/mi;
    $self->{fullname}= $1 if $data =~ /^FullName\s+\((.+?)\)$/mi;
    $self->{family}  = $1 if $data =~ /^FamilyName\s+\((.+)\)$/mi;
    $self->{version} = $1 if $data =~ /^Version\s+\((.+)\)$/mi;
    $self->{pcprefix}= lc($1)
      if $data =~ /^PCFileNamePrefix\s+\((.+)\)$/mi;
    $self->{data}    = $data;

    $self;
}

sub _die {
    my ($self, @msg) = @_;
    $self->{die}->(@msg);
}

1;

__END__

################ Documentation ################

=head1 NAME

PostScript::FontInfo - module to fetch data from PostScript font C<.inf> files

=head1 SYNOPSIS

  my $info = new PostScript::FontInfo (filename, options);
  print STDOUT ("Name = ", $info->name, "\n");

=head1 DESCRIPTION

This package allows font info files, so called C<.inf> files, to be
read and (partly) parsed.

=head1 CONSTRUCTOR

=over 4

=item new ( FILENAME [ , OPTIONS ] )

The constructor will read the file and parse its contents.

=back

=head1 OPTIONS

=over 4

=item error => [ 'die' | 'warn' | 'ignore' ]

B<DEPRECATED>. Please use 'eval { ... }' to intercept errors.

How errors must be handled. Default is to call die().
In any case, new() returns a undefined result.
Setting 'error' to 'ignore' may cause surprising results.

=item verbose => I<value>

Prints verbose info if I<value> is true.

=item trace => I<value>

Prints tracing info if I<value> is true.

=item debug => I<value>

Prints debugging info if I<value> is true.
Implies 'trace' and 'verbose'.

=back

=head1 INSTANCE METHODS

Each of these methods can return C<undef> if the corresponding
information could not be found in the file.

=over 4

=item FileName

The name of the file, e.g. 'tir_____.inf'.

=item FontName

The name of the font, e.g. 'Times-Roman'.

=item FullName

The full name of the font, e.g. 'Times Roman'.

=item FontFamily

The family name of the font, e.g. 'Times'.

=item Version

The version of the font, e.g. '001.007'.

=item PCFileNamePrefix

The prefix used to form MS-DOS compliant file names, e.g. 'tir__'.

=item InfoData

The complete contents of the file, normalised to Unix-style line endings.

=back

=head1 AUTHOR

Johan Vromans, Squirrel Consultancy <jvromans@squirrel.nl>

=head1 COPYRIGHT and DISCLAIMER

This program is Copyright 2003,1998 by Squirrel Consultancy. All
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
