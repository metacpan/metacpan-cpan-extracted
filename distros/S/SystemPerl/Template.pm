# SystemC - SystemC Perl Interface
# See copyright, etc in below POD section.
######################################################################

package SystemC::Template;
use Class::Struct;
use IO::File;
use File::Basename;
use File::Spec;
use Carp;

use Verilog::Netlist::Subclass;
@ISA = qw(SystemC::Template::Struct
	Verilog::Netlist::Subclass);
use strict;
use vars qw ($Debug $Default_Self $VERSION);

$VERSION = '1.344';

structs('_new_base',
	'SystemC::Template::Struct'
	=>[name		=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Line number (for warning messages)
	   logger	=> '$', #'	# Error logger object
	   #
	   verbose	=> '$', #'	# If true, tell when the file is written
	   ppline	=> '$', #'	# If true, put out #line directives
	   keep_timestamp=> '$', #'	# If true, don't write the file if it didn't change
	   # From _read
	   src_text	=> '$',	#'	# ARRAYREF: Lines of text from src
	   # For _write
	   out_text	=> '$',	#'	# ARRAYREF: Lines of text to output
	   ]);

######################################################################
######################################################################
#### Creation

sub new {
    my $class = shift;
    my $self = $class->_new_base
	(ppline => 0,
	 verbose => 0,
	 src_text => [],
	 out_text => [],
	 @_);
    $Default_Self = $self;
    return $self;
}

######################################################################
######################################################################
#### Reading

sub read {
    my $self = shift or croak "%Error: Not called as a method\n";
    $Default_Self = $self;
    my %params = (@_);	# filename=>

    my $filename = $params{filename} or croak "%Error: ".__PACKAGE__."::read (filename=>) parameter required, stopped";

    print __PACKAGE__."::read $filename\n" if $Debug;
    (-r $filename) or die "%Error: Cannot open $filename\n";

    # For speed, we don't use the accessor function each loop
    my @text = ();

    my $fh = IO::File->new ("<$filename") or die "%Error: $! $filename\n";
    while (defined (my $line = $fh->getline())) {
	push @text, [$self, $filename, $., $line];
    }
    $fh->close;

    $self->src_text(\@text);
    return $self;
}

######################################################################
######################################################################
# WRITE UTILITIES

sub src_print_ln {
    my $self;
    if (ref $_[0]) {$self=shift;} else {$self=$Default_Self;};	# Allow calling as $self->... or not
    my $filename = shift;
    my $lineno = shift;
    my $outtext = join('',@_);
    push @{$self->src_text()}, [$self, $filename, $lineno, $outtext];
}
sub src_print {
    my $self;
    if (ref $_[0]) {$self=shift;} else {$self=$Default_Self;};	# Allow calling as $self->... or not
    $self->src_print_ln(undef, -1, join('',@_));
}

sub print_ln {
    my $self;
    if (ref $_[0]) {$self=shift;} else {$self=$Default_Self;};	# Allow calling as $self->... or not
    my $filename = shift;
    my $lineno = shift;
    my $outtext = join('',@_);
    push @{$self->out_text()}, [$self, $filename, $lineno, $outtext];
}

sub print {
    my $self;
    if (ref $_[0]) {$self=shift;} else {$self=$Default_Self;};	# Allow calling as $self->... or not
    $self->print_ln(undef, -1, join('',@_));
}

sub printf {
    my $self;
    if (ref $_[0]) {$self=shift;} else {$self=$Default_Self;};	# Allow calling as $self->... or not
    my $fmt = shift;
    my $outtext = sprintf ($fmt,@_);
    $self->print($outtext);
}

######################################################################
######################################################################
# WRITING

sub write {
    my $self = shift;  ref $self or croak "%Error: Call as \$ref->".__PACKAGE__."::write, stopped";
    $Default_Self = $self;
    my %params = (ppline => $self->ppline(),
		  keep_timestamp =>  $self->keep_timestamp(),
		  @_);

    $self->verbose(1) if $Debug;

    my $filename = $params{filename} or croak "%Error: ".__PACKAGE__."::write (filename=>) parameter required, stopped";
    my $keepstamp = $params{keep_timestamp};

    # Read the old file, so we can tell if it changes
    my @old_text;	# Old file contents
    if ($keepstamp) {
	my $fh = IO::File->new ("<$filename");
	if ($fh) {
	    @old_text = $fh->getlines();
	    $fh->close();
	} else {
	    $keepstamp = 0;
	}
    }

    # Inside _write
    my @gen_text	= ();	# Lines of text being sent
    my $gen_lineno	= 1;	# Line number being outputted
    my $gcc_filename	= "";	# File name GCC thinks we are on
    my $gcc_lineno	= -1;	# Line number GCC thinks we are on
    my $src_copying	= $filename;	# If true, copy source text to output

    foreach my $line (@{$self->out_text}) {
	# [self(ignored), filename, lineno, text]
	my $src_filename = $line->[1] || $filename; # File name of source code, undef = get from source
	my $src_lineno = $line->[2] || -1; # Line number of source code, -1 = get from output
	my $text = $line->[3];
	#print "LL $src_filename:$src_lineno: $text";
	next if !defined $text;

	if ($params{ppline}) {
	    my $lineno   = $src_lineno;
	    $lineno = $gen_lineno if $src_lineno < 0;
	    $src_filename = basename($src_filename,"^") if $params{ppline} eq 'basename';
	    if ($gcc_filename ne $src_filename
		|| $gcc_lineno != $lineno) {
		#push @gen_text, "//LL '$gcc_lineno'  '$lineno' '$gcc_filename' '$src_filename':  ";
		$lineno += 2 if $src_lineno < 0;  # +2 accounts for lines that #line will insert
		$gcc_lineno = $lineno;
		# We may not be on a empty line, so we add a CR
		# Note no $src_lineno++, we don't want the src line number to change
		if (defined $src_filename && $gcc_filename ne $src_filename) {
		    $gcc_filename = $src_filename;
		    my $abs_filename = $gcc_filename;
		    $abs_filename = File::Spec->rel2abs($abs_filename) if $params{absolute_filenames};
		    push @gen_text, "\n#line ${gcc_lineno} \"${abs_filename}\"\n";
		    $gen_lineno+=2;
		} else {
		    push @gen_text, "\n#line ${gcc_lineno}\n";
		    $gen_lineno+=2;
		}
	    }
	}

	push @gen_text, $text;
	while ($text =~ /\n/g) {
	    $gen_lineno++;
	    $gcc_lineno++;
	}
    }

    # Write the file
    if (!$keepstamp
	|| (join ('',@old_text) ne join ('',@gen_text))) {
	print "Write $filename\n" if $self->verbose;
	my $fh = IO::File->new (">$filename.tmp") or die "%Error: $! $filename.tmp\n";
	# When Verilog-Perl 3.041 is the minimum supported version,
	# this should become $self->logger->unlink_if_error
        $self->unlink_if_error ("$filename.tmp");
	print $fh @gen_text;
	$fh->close();
	rename "$filename.tmp", $filename;
    } else {
	print "Same $filename\n" if $self->verbose;
    }
    unlink "$filename.tmp";
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Template - Replace text in a file with new text

=head1 SYNOPSIS

  use SystemC::Template;

  my $tpl = new SystemC::Template;
  $tpl->read (filename=>'filename',
	      ppline=>1,
	      );

  $tpl->print_ln ("newfilename", 100, "inserted: This is line 100 of newfile\n");
  foreach my $lref (@{$tpl->src_text()}) {
    $tpl->print_ln ($lref->[1], $lref->[2], $lref->[3]);
  }

  $tpl->write (filename=>'new_filename',);

=head1 DESCRIPTION

SystemC::Template is the class that SystemC uses to read
files and write the file .sp files and expand the contents of them.

It is similar to Text::Template, but uses arrays for speed, understands how
to create #line comments for the C preprocessor, and not to write the file
if nothing has changed.

First $read is called, which loads the $self->src_text() as a array of
[$self, filename, lineno, text] structures.  The external code then
manipulates this array and loads $self->out_text() probably using
$self->printf().  $self->write() is then called to write the results.

For convenience, most methods can be called as non-method calls, this will
use the template that was most recently called with write.  (This enables
functions to simply call SystemC::Template::print and not need to pass the
class around.)

=head1 ACCESSORS

=over 4

=item $self->name

The filename read.

=item $self->ppline

Insert #line comments for GCC.  If set to 'basename' strip the directory off the filename.

=back

=head1 MEMBER FUNCTIONS

=over 4

=item $self->read

Pass a hash of parameters.  Reads the filename=> filename parameter and
loads the internal structures.

=item $self->write

Pass a hash of parameters.  Writes the filename=> parameter with the
contents of the out_text() array.

=item $self->print_ln (I<filename>, I<lineno>, I<text...>)

Adds to the out_text the filename, line and given text.

=item $self->print (I<text...>)

Adds to the out_text the given text.

=item $self->printf (I<format>, I<params...>)

Adds to the out_text the given formatted text.

=back

=head1 DISTRIBUTION

SystemPerl is part of the L<http://www.veripool.org/> free SystemC software
tool suite.  The latest version is available from CPAN and from
L<http://www.veripool.org/systemperl>.

Copyright 2001-2014 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License
Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<SystemC::Netlist>,
L<SystemC::Netlist::File>,
L<Text::Template>

=cut
