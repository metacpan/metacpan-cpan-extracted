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

package OODoc;{
our $VERSION = '3.04';
}

use parent 'OODoc::Object';

use strict;
use warnings;

our $VERSION = '3.04';  # needed here for own release process

use Log::Report    'oodoc';

use OODoc::Manifest ();
use OODoc::Format   ();
use OODoc::Index    ();

use File::Basename        qw/dirname/;
use File::Copy            qw/copy move/;
use File::Spec::Functions qw/catfile/;
use List::Util            qw/first/;
use Scalar::Util          qw/blessed reftype/;

#--------------------

sub init($)
{	my ($self, $args) = @_;

	$self->SUPER::init($args) or return;

	my $distribution   = $self->{O_distribution} = delete $args->{distribution}
		or error __x"the produced distribution needs a project description";

	$self->{O_project} = delete $args->{project} || $distribution;

	my $version        = delete $args->{version};
	unless(defined $version)
	{	my $fn         = -f 'version' ? 'version' : -f 'VERSION' ? 'VERSION' : undef;
		if(defined $fn)
		{	open my $v, '<:encoding(UTF-8)', $fn
				or fault __x"cannot read distribution version from file {file}", file=> $fn;
			$version = $v->getline;
			$version = $1 if $version =~ m/(\d+\.[\d\.]+)/;
			chomp $version;
		}
	}

	$self->{O_version} = $version
		or error __x"no version specified for distribution {dist}", dist  => $distribution;

	$self->{O_index}   = OODoc::Index->new;
	$self;
}

sub publish { panic }

#--------------------

sub distribution() { $_[0]->{O_distribution} }


sub version() { $_[0]->{O_version} }


sub project() { $_[0]->{O_project} }


sub index() { $_[0]->{O_index} }

#--------------------

sub selectFiles($@)
{	my ($self, $filter, @files) = @_;

	my $ftype = reftype $filter;
	my $select
	  = $ftype eq 'REGEXP' ? sub { $_[0] =~ $filter }
	  : $ftype eq 'CODE'   ? $filter
	  : $ftype eq 'ARRAY'  ? $filter
	  :     error __x"use regex, code reference or array for file selection, not {type}", type => $ftype;

	return ($select, [])
		if reftype $select eq 'ARRAY';

	my (@process, @copy);
	foreach my $fn (@files)
	{	if($select->($fn)) { push @process, $fn }
		else               { push @copy,    $fn }
	}

	( \@process, \@copy );
}


sub processFiles(@)
{	my ($self, %args) = @_;

	my $dest    = $args{workdir};
	my $source  = $args{source};
	my $distr   = $args{distribution} || $self->distribution;

	my $version = $args{version};
	unless(defined $version)
	{	my $fn  = defined $source ? catfile($source, 'version') : 'version';
		$fn     = -f $fn          ? $fn
				: defined $source ? catfile($source, 'VERSION')
				:                   'VERSION';
		if(defined $fn)
		{	open my $v, '<:encoding(UTF-8)', $fn
				or fault __x"cannot read version from {file}", file => $fn;
			$version = $v->getline;
			$version = $1 if $version =~ m/(\d+\.[\d\.]+)/;
			chomp $version;
		}
		elsif($version = $self->version) { ; }
		else
		{	error __x"there is no version defined for the source files";
		}
	}

	my $notice = '';
	if($notice = $args{notice})
	{	$notice =~ s/^([^#\n])/# $1/mg;       # put comments if none
	}

	#
	# Split the set of files into those who do need special processing
	# and those who do not.
	#

	my $manfile
	  = exists $args{manifest} ? $args{manifest}
	  : defined $source        ? catfile($source, 'MANIFEST')
	  :                          'MANIFEST';

	my $manifest = OODoc::Manifest->new(filename => $manfile);

	my $manout;
	if(defined $dest)
	{	my $manif = catfile $dest, 'MANIFEST';
		$manout   = OODoc::Manifest->new(filename => $manif);
		$manout->add($manif);
	}
	else
	{	$manout   = OODoc::Manifest->new(filename => undef);
	}

	my $select    = $args{select} || qr/\.(pm|pod)$/;
	my ($process, $copy) = $self->selectFiles($select, @$manifest);

	trace @$process." files to process and ".@$copy." files to copy";

	#
	# Copy all the files which do not contain pseudo doc
	#

	if(defined $dest)
	{	foreach my $filename (@$copy)
		{	my $fn = defined $source ? catfile($source, $filename) : $filename;

			my $dn = catfile $dest, $fn;
			unless(-f $fn)
			{	warning __x"no file {file} to include in the distribution", file => $fn;
				next;
			}

			unless(-e $dn && ( -M $dn < -M $fn ) && ( -s $dn == -s $fn ))
			{	$self->mkdirhier(dirname $dn);

				copy $fn, $dn
					or fault __x"cannot copy distribution file {from} to {to}", from => $fn, to => $dest;

				trace "  copied $fn to $dest";
			}

			$manout->add($dn);
		}
	}

	#
	# Create the parser
	#

	my $parser = $args{parser} || 'OODoc::Parser::Markov';

	unless(blessed $parser)
	{	$parser = 'OODoc::Parser::Markov' if $parser eq 'markov';

		eval "require $parser";
		$@ and error __x"cannot compile {pkg} class: {err}", pkg => $parser, err => $@;

		$parser = $parser->new(skip_links => delete $args{skip_links}, index => $self->index)
			or error __x"parser {name} could not be instantiated", name => $parser;
	}

	#
	# Now process the rest
	#

	foreach my $filename (@$process)
	{	my $fn = $source ? catfile($source, $filename) : $filename;

		-f $fn
			or warning(__x"no file {file} to include in the distribution", file => $fn), next;

		my $dn;
		if($dest)
		{	$dn = catfile $dest, $fn;
			$self->mkdirhier(dirname $dn);
			$manout->add($dn);
		}

		# do the stripping
		my @manuals = $parser->parse(
			input        => $fn,
			output       => $dn,
			distribution => $distr,
			version      => $version,
			notice       => $notice,
		);

		trace "stripped $fn into $dn" if defined $dn;
		trace $_->stats for @manuals;

		foreach my $man (@manuals)
		{	$self->index->addManual($man) if $man->chapters;
		}
	}

	$self;
}

#--------------------

sub finalize(%)
{	my ($self, %args) = @_;

	info "* collect package relations";
	$self->getPackageRelations;

	my @manuals = $self->index->manuals;

	info "* expand manual contents";
	$_->expand for @manuals;

	info "* create inheritance chapters";
	$_->createInheritance for @manuals;

	info "* finalize each manual";
	$_->finalize(%args) for @manuals;

	$self;
}

sub prepare() { panic "OODoc 3.01 renamed prepare() into finalize." }


sub getPackageRelations($)
{	my $self    = shift;
	my @manuals = $self->index->manuals;  # all

	info "compiling all packages";

	foreach my $manual (@manuals)
	{	next if $manual->isPurePod;
		trace "  require package $manual";

		eval "require $manual";
		warning __x"errors from {manual}: {err}", manual => $manual, err =>$@
			if $@ && $@ !~ /can't locate/i && $@ !~ /attempt to reload/i;
	}

	info "detect inheritance relationships";
	my $index = $self->index;

	foreach my $manual (@manuals)
	{
		trace "  relations for $manual";

		if($manual->name ne $manual->package)  # autoloaded code
		{	my $main = $index->mainManual("$manual");
			$main->extraCode($manual) if defined $main;
			next;
		}
		my %uses = $manual->collectPackageRelations;

		foreach (defined $uses{isa} ? @{$uses{isa}} : ())
		{	my $isa = $index->mainManual($_) || $_;

			$manual->superClasses($isa);
			$isa->subClasses($manual) if blessed $isa;
		}

		if(my $realizes = $uses{realizes})
		{	my $to  = $index->mainManual($realizes) || $realizes;

			$manual->realizes($to);
			$to->realizers($manual) if blessed $to;
		}
	}

	$self;
}


sub formatter($@)
{	my ($self, $format, %args) = @_;

	my $dest     = delete $args{workdir}
		or error __x"formatter() requires a directory to write the manuals to";

	# Start manifest

	my $manfile  = delete $args{manifest} // catfile($dest, 'MANIFEST');
	my $manifest = OODoc::Manifest->new(filename => $manfile);

	# Create the formatter

	return $format
		if blessed $format && $format->isa('OODoc::Format');

	OODoc::Format->new(
		%args,
		format      => $format,
		manifest    => $manifest,
		workdir     => $dest,
		project     => $self->distribution,
		version     => $self->version,
		index       => $self->index,
	);
}

sub create() { panic 'Interface change in 2.03: use $oodoc->formatter->createPages' }


sub stats()
{	my $self = shift;
	my @manuals  = $self->index->manuals;
	my $realpkg  = $self->index->packageNames;

	my $subs     = map $_->subroutines, @manuals;
	my @options  = map { map $_->options, $_->subroutines } @manuals;
	my $options  = scalar @options;
	my $examples = map $_->examples,    @manuals;
	my $diags    = map $_->diagnostics, @manuals;
	my $version  = $self->version;
	my $project  = $self->project;
	my $nr_mans  = @manuals;

	<<__STATS;
Project $project contains:
  Number of package manuals: $nr_mans
  Real number of packages:   $realpkg
  documented subroutines:    $subs
  documented options:        $options
  documented diagnostics:    $diags
  shown examples:            $examples
__STATS
}


sub mkdirhier($)
{	my $thing = shift;
	my @dirs  = File::Spec->splitdir(shift);
	my $path  = $dirs[0] eq '' ? shift @dirs : '.';

	while(@dirs)
	{	$path = File::Spec->catdir($path, shift @dirs);
		-d $path || mkdir $path
			or fault __x"cannot create {dir}", dir => $path;
	}

	$thing;
}

#--------------------

1;
