#
# $Id: Env.pm,v 0.1 2001/04/25 10:41:48 ram Exp $
#
#  Copyright (c) 2000-2001, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Env.pm,v $
# Revision 0.1  2001/04/25 10:41:48  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package Pod::PP::Env;

require Clone;
use vars qw(@ISA);
@ISA = qw(Clone);

use Cwd qw(abs_path);
use File::Basename;
use File::Spec;
use Carp::Datum;
use Log::Agent;
use Safe;

#
# ->make
#
# Creation routine
#
sub make {
	DFEATURE my $f_;
	my $self = bless {}, shift;
	my ($incpath, $symbols) = @_;
	$self->{incpath} = Clone::clone($incpath);
	$self->{symbols} = Clone::clone($symbols);
	$self->{parsed} = {};
	$self->{safe} = Safe->new;
	return DVAL $self;
}

#
# Attribute access
#

sub incpath		{ $_[0]->{incpath} }
sub symbols		{ $_[0]->{symbols} }
sub parsed		{ $_[0]->{parsed} }
sub safe		{ $_[0]->{safe} }

###
### Symbol processing
###

#
# ->is_defined
#
# Test whether symbol is defined
#
sub is_defined {
	DFEATURE my $f_;
	my $self = shift;
	my ($sym) = @_;

	return DVAL exists $self->symbols->{$sym};
}

#
# ->define
#
# Record symbol definition
#
sub define {
	DFEATURE my $f_;
	my $self = shift;
	my ($sym, $value) = @_;

	$self->symbols->{$sym} = $value;
	return DVOID;
}

#
# ->undefine
#
# Undefine symbol.
#
sub undefine {
	DFEATURE my $f_;
	my $self = shift;
	my ($sym) = @_;

	delete $self->symbols->{$sym};
	return DVOID;
}

#
# ->symbol_value
#
# Returns symbol value.
#
sub symbol_value {
	DFEATURE my $f_;
	my $self = shift;
	my ($sym) = @_;

	DREQUIRE $self->is_defined($sym), "symbol $sym defined";

	return DVAL $self->symbols->{$sym};
}

###
### Expression processing
###

#
# to_perl
#
# Transform an expression into an executable perl expression.
# Valid expressions are:
#
#   defined(SYM)          test for defined SYM
#   SYM+1                 arithmetic on SYM
#   SYM == 1              numeric test
#   SYM eq "abc"          string test
#   "string"              string, same as 'string' (no interpolation)
#   'string'              litteral string
#
# and combinations of things according to normal expression construction,
# with "&&", "||" and "!" as boolean connectors and "()" to change order of
# evaluation.
#
# This is a valid expression:
#
#   defined(SYM) || ((OTHER - THIS) ne FOOBAR && SYM <= 43)
#
# Returns expression that can be evaled.  All symbols are transformed into
# symbol lookups in $S, supposed to hold a HASH ref.
#
sub to_perl {
	DFEATURE my $f_;
	my $self = shift;
	my ($expr) = @_;

	logdbg 'debug', "Pod::PP expression: $expr";

	#
	# Remove all strings 'x' and "x", and protect string operators
	#

	my $idx = 0;
	my @strings;

	$strings[$idx++] = $1 while $expr =~ s/'(.*?)'/\01$idx\01/;
	$strings[$idx++] = $1 while $expr =~ s/"(.*?)"/\02$idx\02/;
	$strings[$idx++] = $1 while $expr =~ s/\b(eq|ne|ge|le|gt|lt)\b/\03$idx\03/;

	#
	# Perform translation into Perl: need only to transform "defined(SYM)"
	# and all occurrences of "SYM".
	#

	$expr =~ s/defined\s*\((\w+)\)/exists(\$S->{'$1'})/g;
	$expr =~ s/
		(
			^|						# start of line OR
			[(-+=*\/%^~\s]			# arithmetic symbol OR space
		)
		(?!exists\()				# not followed by "exists("
		([A-Za-z]\w*)				# but followed by identifier
		/$1\$S->{'$2'}/gx;

	#
	# Restore all strings 'x' and "x", as well as string operators.
	#

	$expr =~ s/\01(\d+)\01/"'" . $strings[$1] . "'"/ge;
	$expr =~ s/\02(\d+)\02/'"' . $strings[$1] . '"'/ge;
	$expr =~ s/\03(\d+)\03/ $strings[$1] /ge;

	logdbg 'debug', "Perl expression: $expr";

	return DVAL $expr;
}

#
# ->evaluate
#
# Evaluate Pod::PP boolean expression.
# Returns undef when expression does not evaluate properly
#
sub evaluate {
	DFEATURE my $f_;
	my $self = shift;
	my ($expr, $podinfo) = @_;

	my $perl = $self->to_perl($expr);		# Transform into Perl

	#
	# Evaluate the Perl expression within the Safe compartment.
	#
	# The expression expects variable $S to hold the HASH ref to the
	# symbol table.  The only way to share it with the Safe compartment
	# is by using a global...
	#

	my $safe = $self->safe;
	my $val;

	{
		no strict 'vars';

		local $S = $self->symbols;
		$safe->share('$S');
		$val = $safe->reval($perl);
	}

	if (chop $@) {
		my ($file, $line) = $podinfo->file_line();
		logerr "error in Pod:PP expression '%s' at \"%s\", line %d: %s",
			$expr, $file, $line, $@;
		return DVAL undef;
	}

	return DVAL $val ? 1 : 0;
}

###
### Include file processing
###

#
# ->is_parsed
#
# Check whether file was parsed.
# 
sub is_parsed {
	DFEATURE my $f_;
	my $self = shift;
	my ($path) = @_;

	my $absolute = $self->absolute_path($path);
	return DVAL exists $self->parsed->{$absolute};
}

#
# ->set_is_parsed
#
# Mark file as parsed.
#
sub set_is_parsed {
	DFEATURE my $f_;
	my $self = shift;
	my ($path) = @_;
	my $absolute = $self->absolute_path($path);

	DREQUIRE !$self->is_parsed($absolute), "file '$path' not parsed already";

	$self->parsed->{$absolute} = undef;
	return DVOID;
}

#
# ->lookup_file
#
# Lookup file to be included.
#
# File to include ($finc) is located from the current directory, which is the
# one where the including file ($fbase) is located.  If $finc is not found
# there, we follow the include path.
#
# Returns path of file we found, undef when not found.
#
sub lookup_file {
	DFEATURE my $f_;
	my $self = shift;
	my ($fbase, $finc) = @_;

	my $dir = dirname($fbase);
	my $path = $self->_locate($finc, [$dir]);
	$path = $self->_locate($finc, $self->incpath) unless defined $path;
	$path = $self->simplify_path($path) if defined $path;

	return DVAL $path;
}

#
# ->_locate
#
# Locate file through the specified directory list (given via array ref).
# Returns normalized path if found, undef otherwise.
#
sub _locate {
	DFEATURE my $f_;
	my $self = shift;
	my ($file, $locref) = @_;

	foreach my $dir (@$locref) {
		return DVAL $self->normalize_path("$dir/$file") if -f "$dir/$file";
	}

	return DVAL undef;
}

#
# ->normalize_path
#
# Normalize path by removing extra /'s or .'s.
#
sub normalize_path {
	DFEATURE my $f_;
	my $self = shift;
	my ($path) = @_;

	$path =~ tr|/||s;
	$path =~ s|^\./||g;
	$path =~ s|/\./||g;

	return DVAL $path;
}

#
# ->simplify_path
#
# Simplify paths by turning things like:
#
#   ../h/../h/../h/foo.h 
#
# into
#	../h/foo.h
#
# by removing .. and . in paths.
#
sub simplify_path {
	DFEATURE my $f_;
	my $self = shift;
	my ($path) = @_;
	my @path = split(m:/:, $path);
	my @cur;
	my $absolute = 0;
	$absolute++ if $path[0] eq '';
	foreach my $dir (@path) {
		next if $dir eq '' || $dir eq '.';
		if ($dir eq '..') {
			if (@cur == 0) {
				push(@cur, '..') unless $absolute;
			} elsif ($cur[$#cur] eq '..') {
				push(@cur, '..');
			} else {
				pop(@cur);
			}
		} else {
			push(@cur, $dir);
		}
	}
	my $simplified = ($absolute ? '/' : '') . join('/', @cur);
	return DVAL $simplified;
}

#
# ->absolute_path
#
# Return the absolute path of filename or directory.
#
sub absolute_path {
	DFEATURE my $f_;
	my $self = shift;
	my ($path) = @_;

	DREQUIRE -e $path, "entry '$path' exists on the filesystem";

	return DVAL abs_path($path) if -d $path;
	my $ap = File::Spec->catfile(abs_path(dirname $path), basename $path);
	return DVAL $ap;
}

1;

