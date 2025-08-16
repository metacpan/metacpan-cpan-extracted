# This code is part of Perl distribution OODoc version 3.02.
# The POD got stripped from this file by OODoc version 3.02.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package OODoc::Format;{
our $VERSION = '3.02';
}

use parent 'OODoc::Object';

use strict;
use warnings;

use Log::Report    'oodoc';

use OODoc::Manifest ();

our %formatters =
( pod   => 'OODoc::Format::Pod',
	pod2  => 'OODoc::Format::Pod2',
	pod3  => 'OODoc::Format::Pod3',
	html  => 'OODoc::Format::Html',
	html2 => 'OODoc::Format::Html2'   # not (yet) included in the OODoc release
);

#--------------------

sub new($%)
{	my ($class, %args) = @_;

	$class eq __PACKAGE__
		or return $class->SUPER::new(%args);

	my $format = $args{format}
		or error __x"no formatter specified.";

	my $pkg = $formatters{$format} || $format;

	eval "require $pkg";
	$@ and error __x"formatter {name} has compilation errors: {err}", name => $format, err => $@;

	$pkg->new(%args);
}

sub init($)
{	my ($self, $args) = @_;

	$self->SUPER::init($args) or return;
	$self->{OF_format}   = delete $args->{format};

	my $name = $self->{OF_project} = delete $args->{project}
		or error __x"formatter knows no project name";

	$self->{OF_version}  = delete $args->{version}
		or error __x"formatter for {name} does not know the version", name => $name;

	$self->{OF_workdir}  = delete $args->{workdir}
		or error __x"no working directory specified for {name}", name => $name;

	$self->{OF_manifest} = delete $args->{manifest} || OODoc::Manifest->new;
	$self;
}

sub publish { panic }

#--------------------

sub project() { $_[0]->{OF_project} }


sub version()  { $_[0]->{OF_version} }
sub workdir()  { $_[0]->{OF_workdir} }
sub manifest() { $_[0]->{OF_manifest} }
sub format()   { $_[0]->{OF_format} }

#--------------------

sub createPages(%)
{	my ($self, %args) = @_;

	my $sel = $args{select} || sub { 1 };
	my $select = ref $sel eq 'CODE' ? $sel : sub { $_[0]->name =~ $sel };

	# Manual knowledge is global

	my $options = $args{manual_format} || [];
	foreach my $package (sort $self->packageNames)
	{
		foreach my $manual ($self->manualsForPackage($package))
		{	$select->($manual) or next;

			unless($manual->chapters)
			{	trace "  skipping $manual: no chapters";
				next;
			}

			trace "  creating manual $manual with ".(ref $self);

			$self->createManual(
				manual   => $manual,
				template => $args{manual_templates},
				append   => $args{append},
				@$options
			);
		}
	}

	#
	# Create other pages
	#

	trace "creating other pages";
	$self->createOtherPages(source => $args{other_templates}, process => $args{process_files});

	1;
}


sub createManual(@) {panic}


sub cleanup($$%) { ... }


sub showChapter(@)
{	my ($self, %args) = @_;
	my $chapter  = $args{chapter} or panic;
	my $manual   = $args{manual}  or panic;

	my $show_inh = $args{show_inherited};
	my $show_ch  = $args{show_inherited_chapter}    || $show_inh;
	my $show_sec = $args{show_inherited_section}    || $show_inh;
	my $show_ssec  = $args{show_inherited_subsection}    || $show_inh;
	my $show_sssec = $args{show_inherited_subsubsection} || $show_inh;

	my $show_examples = $args{show_examples} || 'EXPAND';

	if($manual->inherited($chapter))
	{	return $self if $show_ch eq 'NO';
		$self->showStructureRefer(%args, structure => $chapter);
		return $self;
	}

	$self->showStructureExpanded(%args, structure => $chapter,
		show_examples => $args{show_chapter_examples} || $show_examples,
	);

	foreach my $section ($chapter->sections)
	{	if($manual->inherited($section))
		{	next if $show_sec eq 'NO';
			if($show_sec ne 'REFER')
			{	$self->showStructureRefer(%args, structure => $section);
				next;
			}
		}

		$self->showStructureExpanded(%args, structure => $section,
			show_examples => $args{show_section_examples} || $show_examples,
		);

		foreach my $subsection ($section->subsections)
		{	if($manual->inherited($subsection))
			{	next if $show_ssec eq 'NO';
				if($show_ssec ne 'REFER')
				{	$self->showStructureRefer(%args, structure => $subsection);
					next;
				}
			}

			$self->showStructureExpanded(%args, structure => $subsection,
				show_examples => $args{show_subsection_examples} || $show_examples,
			);

			foreach my $subsubsection ($subsection->subsubsections)
			{	if($manual->inherited($subsubsection))
				{	next if $show_sssec eq 'NO';
					if($show_sssec ne 'REFER')
					{	$self->showStructureRefer(%args, structure => $subsubsection);
						next;
					}
				}

				$self->showStructureExpanded(%args, structure => $subsubsection,
					show_examples => $args{show_subsubsection_examples} || $show_examples,
				);
			}
		}
	}
}


sub showStructureExpanded(@) {panic}


sub showStructureRefer(@) {panic}

sub chapterName(@)        { $_[0]->showRequiredChapter(NAME        => @_) }
sub chapterSynopsis(@)    { $_[0]->showOptionalChapter(SYNOPSIS    => @_) }
sub chapterInheritance(@) { $_[0]->showOptionalChapter(INHERITANCE => @_) }
sub chapterDescription(@) { $_[0]->showRequiredChapter(DESCRIPTION => @_) }
sub chapterOverloaded(@)  { $_[0]->showOptionalChapter(OVERLOADED  => @_) }
sub chapterMethods(@)     { $_[0]->showOptionalChapter(METHODS     => @_) }
sub chapterExports(@)     { $_[0]->showOptionalChapter(EXPORTS     => @_) }
sub chapterDiagnostics(@) { $_[0]->showOptionalChapter(DIAGNOSTICS => @_) }
sub chapterDetails(@)     { $_[0]->showOptionalChapter(DETAILS     => @_) }
sub chapterReferences(@)  { $_[0]->showOptionalChapter(REFERENCES  => @_) }
sub chapterCopyrights(@)  { $_[0]->showOptionalChapter(COPYRIGHTS  => @_) }


sub showRequiredChapter($%)
{	my ($self, $name, %args) = @_;
	my $manual  = $args{manual} or panic;

	my $chapter = $manual->chapter($name)
		or (error __x"missing required chapter {name} in {manual}", name => $name, manual => $manual), return;

	$self->showChapter(chapter => $chapter, %args);
}


sub showOptionalChapter($@)
{	my ($self, $name, %args) = @_;
	my $manual  = $args{manual} or panic;
	my $chapter = $manual->chapter($name) or return;
	$self->showChapter(chapter => $chapter, %args);
}


sub createOtherPages(@) { $_[0] }


sub showSubroutines(@)
{	my ($self, %args) = @_;

	my @subs   = $args{subroutines} ? sort @{$args{subroutines}} : [];
	@subs or return $self;

	my $manual = $args{manual} or panic;
	my $output = $args{output}    || select;

	# list is also in ::Pod3
	$args{show_described_options} ||= 'EXPAND';
	$args{show_described_subs}    ||= 'EXPAND';
	$args{show_diagnostics}       ||= 'NO';
	$args{show_examples}          ||= 'EXPAND';
	$args{show_inherited_options} ||= 'USE';
	$args{show_inherited_subs}    ||= 'USE';
	$args{show_option_table}      ||= 'ALL';
	$args{show_subs_index}        ||= 'NO';

	$self->showSubsIndex(%args, subroutines => \@subs);

	for(my $index=0; $index<@subs; $index++)
	{	my $subroutine = $subs[$index];
		my $show = $manual->inherited($subroutine) ? $args{show_inherited_subs} : $args{show_described_subs};

		$self->showSubroutine(
			%args,
			subroutine      => $subroutine,
			show_subroutine => $show,
			last            => ($index==$#subs),
		);
	}
}


sub showSubroutine(@)
{	my ($self, %args) = @_;

	my $subroutine = $args{subroutine} or panic;
	my $manual = $args{manual} or panic;
	my $output = $args{output} || select;

	#
	# Method use
	#

	my $use    = $args{show_subroutine} || 'EXPAND';
	my ($show_use, $expand)
	  = $use eq 'EXPAND' ? ('showSubroutineUse',  1)
	  : $use eq 'USE'    ? ('showSubroutineUse',  0)
	  : $use eq 'NAMES'  ? ('showSubroutineName', 0)
	  : $use eq 'NO'     ? (undef,                0)
	  :   error __x"illegal value for show_subroutine: {value}", value => $use;

	$self->$show_use(%args, subroutine => $subroutine)
		if defined $show_use;

	$expand or return;

	$args{show_inherited_options} ||= 'USE';
	$args{show_described_options} ||= 'EXPAND';

	#
	# Subroutine descriptions
	#

	my $descr       = $args{show_sub_description} || 'DESCRIBED';
	my $description = $subroutine->findDescriptionObject;
	my $show_descr  = 'showSubroutineDescription';

		if($descr eq 'NO') { $show_descr = undef }
	elsif($descr eq 'REFER')
	{	$show_descr = 'showSubroutineDescriptionRefer'
			if $description && $manual->inherited($description);
	}
	elsif($descr eq 'DESCRIBED')
	{	$show_descr = 'showSubroutineDescriptionRefer'
			if $description && $manual->inherited($description);
	}
	elsif($descr eq 'ALL') {;}
	else { error __x"illegal value for show_sub_description: {value}", value => $descr}

	$self->$show_descr(%args, subroutine => $description // $subroutine)
		if defined $show_descr;

	#
	# Options
	#

	my $options = $subroutine->collectedOptions;

	my $opttab  = $args{show_option_table} || 'NAMES';
	my @options = @{$options}{ sort keys %$options };

	# Option table

	my @opttab
	  = $opttab eq 'NO'       ? ()
	  : $opttab eq 'DESCRIBED'? (grep not $manual->inherits($_->[0]), @options)
	  : $opttab eq 'INHERITED'? (grep $manual->inherits($_->[0]), @options)
	  : $opttab eq 'ALL'      ? @options
	  :   error __x"illegal value for show_option_table: {value}", value => $opttab;

	$self->showOptionTable(%args, options => \@opttab) if @opttab;

	# Option expanded

	my @optlist;
	foreach (@options)
	{	my ($option, $default) = @$_;
		my $check = $manual->inherited($option) ? $args{show_inherited_options} : $args{show_described_options};
		push @optlist, $_ if $check eq 'USE' || $check eq 'EXPAND';
	}

	$self->showOptions(%args, options => \@optlist)
		if @optlist;

	# Examples

	my @examples = $subroutine->examples;
	my $show_ex  = $args{show_examples} || 'EXPAND';
	$self->showExamples(%args, examples => \@examples)
		if $show_ex eq 'EXPAND';

	# Diagnostics

	my @diags    = $subroutine->diagnostics;
	my $show_diag= $args{show_diagnostics} || 'NO';
	$self->showDiagnostics(%args, diagnostics => \@diags)
		if $show_diag eq 'EXPAND';
}


sub showExamples(@) { $_[0] }


sub showSubroutineUse(@) { $_[0] }


sub showSubroutineName(@) { $_[0] }


sub showSubroutineDescription(@) { $_[0] }


sub showOptionTable(@)
{	my ($self, %args) = @_;
	my $options = $args{options} or panic;
	my $manual  = $args{manual}  or panic;
	my $output  = $args{output}  or panic;

	my @rows;
	foreach (@$options)
	{	my ($option, $default) = @$_;
		my $optman = $option->manual;
		push @rows, [
			$self->cleanup($manual, $option->name, tag => 'option_name'),
			($manual->inherited($option) ? $self->link(undef, $optman) : ''),
			$self->cleanup($manual, $default->value, tag => 'option_default'),
		];
	}

	my @header  = ('Option', 'Defined in', 'Default');
	unless(grep length $_->[1], @rows)
	{	# removed empty "defined in" column
		splice @$_, 1, 1 for @rows, \@header;
	}

	$output->print("\n");
	$self->writeTable(output => $output, header => \@header, rows => \@rows, widths => [undef, 15, undef]);
	$self;
}


sub showOptions(@)
{	my ($self, %args) = @_;

	my $options = $args{options} or panic;
	my $manual  = $args{manual}  or panic;

	foreach (@$options)
	{	my ($option, $default) = @$_;
		my $show = $manual->inherited($option) ? $args{show_inherited_options} : $args{show_described_options};

		my $action
		  = $show eq 'USE'   ? 'showOptionUse'
		  : $show eq 'EXPAND'? 'showOptionExpand'
		  :   error __x"illegal show option choice: {value}", value => $show;

		$self->$action(%args, option => $option, default => $default);
	}
	$self;
}


sub showOptionUse(@) { $_[0] }


sub showOptionExpand(@) { $_[0] }

1;
