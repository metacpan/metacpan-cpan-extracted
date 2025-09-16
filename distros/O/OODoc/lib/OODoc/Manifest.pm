# This code is part of Perl distribution OODoc version 3.04.
# The POD got stripped from this file by OODoc version 3.04.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package OODoc::Manifest;{
our $VERSION = '3.04';
}

use parent 'OODoc::Object';

use strict;
use warnings;

use Log::Report    'oodoc';

use File::Basename 'dirname';

#--------------------

use overload '@{}' => sub { [ shift->files ] };
use overload bool  => sub {1};

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args) or return;

	my $filename = $self->{OM_filename} = delete $args->{filename};

	$self->{OM_files} = {};
	$self->read if defined $filename && -e $filename;
	$self->modified(0);
	$self;
}

#--------------------

sub filename() { $_[0]->{OM_filename} }

#--------------------

sub files() { keys %{ $_[0]->{OM_files}} }


sub add(@)
{	my $self = shift;
	while(@_)
	{	my $add = $self->relative(shift);
		$self->modified(1) unless exists $self->{O_file}{$add};
		$self->{OM_files}{$add}++;
	}
	$self;
}

#--------------------

sub read()
{	my $self = shift;
	my $filename = $self->filename;

	open my $file, "<:encoding(utf8)", $filename
		or fault __x"cannot read manifest file {file}", file => $filename;

	my @dist = $file->getlines;
	$file->close;

	s/\s+.*\n?$// for @dist;
	$self->{OM_files}{$_}++ foreach @dist;
	$self;
}


sub modified(;$)
{	my $self = shift;
	@_ ? $self->{OM_modified} = @_ : $self->{OM_modified};
}


sub write()
{	my $self = shift;
	return unless $self->modified;
	my $filename = $self->filename || return $self;

	open my $file, ">:encoding(utf8)", $filename
		or fault __x"cannot write manifest {file}", file => $filename;

	$file->print($_, "\n") foreach sort $self->files;
	$file->close;

	$self->modified(0);
	$self;
}

sub DESTROY() { $_[0]->write }


sub relative($)
{	my ($self, $filename) = @_;

	my $dir = dirname $self->filename;
	return $filename if $dir eq '.';

	# normalize path for windows
	s!\\!/!g for $filename, $dir;

	if(substr($filename, 0, length($dir)+1) eq "$dir/")
	{	substr $filename, 0, length($dir)+1, '';
		return $filename;
	}

	warning __x"MANIFEST file {file} lists filename outside (sub)directory: {out}", file => $self->filename, out => $filename;

	$filename;
}

1;
