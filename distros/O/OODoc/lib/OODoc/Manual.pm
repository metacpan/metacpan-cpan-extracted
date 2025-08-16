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

package OODoc::Manual;{
our $VERSION = '3.02';
}

use parent 'OODoc::Object';

use strict;
use warnings;

use Log::Report    'oodoc';

use OODoc::Text::Chapter ();

use Scalar::Util  qw/blessed/;
use List::Util    qw/first/;

# Prefered order of all supported chapters
my @chapter_names = qw/
	Name
	Inheritance
	Synopsis
	Description
	Overload
	Methods
	Exports
	Details
	Diagnositcs
	References
/;

#--------------------

use overload '""' => sub { shift->name };
use overload bool => sub {1};


use overload cmp  => sub {$_[0]->name cmp "$_[1]"};

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args) or return;

	my $name = $self->{OM_package} = delete $args->{package}
		or error __x"package name is not specified";

	$self->{OM_source}   = delete $args->{source}
		or error __x"no source is specified for manual {name}", name => $name;

	$self->{OM_version}  = delete $args->{version}
		or error __x"no version is specified for manual {name}", name => $name;

	$self->{OM_distr}    = delete $args->{distribution}
		or error __x"no distribution specified for manual {name}", name=> $name;

	$self->{OM_parser}   = delete $args->{parser}    or panic;
	$self->{OM_stripped} = delete $args->{stripped};

	$self->{OM_pure_pod} = delete $args->{pure_pod} || 0;
	$self->{OM_chapter_hash} = {};
	$self->{OM_chapters}     = [];
	$self->{OM_subclasses}   = [];
	$self->{OM_realizers}    = [];
	$self->{OM_extra_code}   = [];
	$self->{OM_isa}          = [];
	$self;
}

#--------------------

sub package() {$_[0]->{OM_package}}


sub parser() {$_[0]->{OM_parser}}


sub source() {$_[0]->{OM_source}}


sub version() {$_[0]->{OM_version}}


sub distribution() {$_[0]->{OM_distr}}


sub stripped() {$_[0]->{OM_stripped}}


sub isPurePod() {$_[0]->{OM_pure_pod}}

#--------------------

sub chapter($)
{	my ($self, $it) = @_;
	$it or return;

	blessed $it
		or return $self->{OM_chapter_hash}{$it};

	$it->isa("OODoc::Text::Chapter") or panic "$it is not a chapter";

	my $name = $it->name;
	if(my $old = $self->{OM_chapter_hash}{$name})
	{	my ($fn,  $ln2) = $it->where;
		my ($fn2, $ln1) = $old->where;
		error __x"two chapters named {name} in {file} line {line1} and {line2}",
			name => $name, file => $fn, line1 => $ln2, line2 => $ln1;
	}

	$self->{OM_chapter_hash}{$name} = $it;
	push @{$self->{OM_chapters}}, $it;
	$it;
}


sub chapters(;$)
{	my $self = shift;
	if(@_)
	{	$self->{OM_chapters}     = [ @_ ];
		$self->{OM_chapter_hash} = { map +($_->name => $_), @_ };
	}
	@{$self->{OM_chapters}};
}


sub name()
{	my $self    = shift;
	defined $self->{OM_name} and return $self->{OM_name};

	my $chapter = $self->chapter('NAME')
		or error __x"no chapter NAME in scope of package {pkg} in {file}", pkg => $self->package, file => $self->source;

	my $text   = $chapter->description || '';
	$text =~ m/^\s*(\S+)\s*\-\s*(.+?)\s*$/
		or error __x"the NAME chapter does not have the right format in {file}", file => $self->source;

	$self->{OM_title} = $2;
	$self->{OM_name}  = $1;
}


sub title() { $_[0]->name; $_[0]->{OM_title} }


sub subroutines() { $_[0]->all('subroutines') }


sub subroutine($)
{	my ($self, $name) = @_;
	my $sub;

	my $package = $self->package;
	my @parts   = defined $package ? $self->manualsForPackage($package) : $self;

	foreach my $part (@parts)
	{	foreach my $chapter ($part->chapters)
		{	$sub = first { defined $_ } $chapter->all(subroutine => $name);
			defined $sub and return $sub;
		}
	}

	();
}


sub examples()
{	my $self = shift;
	( $self->all('examples'),
		map $_->examples, $self->subroutines
	);
}


sub diagnostics(%)
{	my ($self, %args) = @_;
	my @select = @{$args{select} || []};

	my @diag = map $_->diagnostics, $self->subroutines;
	@select or return @diag;

	my $select;
	{	local $" = '|';
		$select = qr/^(@select)$/i;
	}

	grep $_->type =~ $select, @diag;
}

#--------------------

sub superClasses(;@)
{	my $self = shift;
	push @{$self->{OM_isa}}, @_;
	@{$self->{OM_isa}};
}


sub realizes(;$)
{	my $self = shift;
	@_ ? ($self->{OM_realizes} = shift) : $self->{OM_realizes};
}


sub subClasses(;@)
{	my $self = shift;
	push @{$self->{OM_subclasses}}, @_;
	@{$self->{OM_subclasses}};
}


sub realizers(;@)
{	my $self = shift;
	push @{$self->{OM_realizers}}, @_;
	@{$self->{OM_realizers}};
}


sub extraCode()
{	my $self = shift;
	my $name = $self->name;

	$self->package eq $name
	? grep $_->name ne $name, $self->manualsForPackage($name)
	: ();
}


sub all($@)
{	my $self = shift;
	map $_->all(@_), $self->chapters;
}


sub inherited($) { $_[0]->name ne $_[1]->manual->name }


sub ownSubroutines
{	my $self = shift;
	my $me   = $self->name || return 0;
	grep ! $self->inherited($_), $self->subroutines;
}

#--------------------

sub collectPackageRelations()
{	my $self = shift;
	return () if $self->isPurePod;

	my $name = $self->package;
	my %tree;

	# The @ISA / use base / use parent
	{	no strict 'refs';
		$tree{isa} = [ @{"${name}::ISA"} ];
	}

	# Support for Object::Realize::Later
	$tree{realizes} = $name->willRealize if $name->can('willRealize');

	%tree;
}


sub expand()
{	my $self = shift;
	$self->{OM_is_expanded} and return $self;

	trace "expand manual $self";

	#
	# All super classes must be expanded first.  Manuals for
	# extra code are considered super classes as well.  Super
	# classes which are external are ignored.
	#

	# multiple inheritance, first isa wins
	my @supers  = reverse grep ref, $self->superClasses;
	$_->expand for @supers;

	#
	# Expand chapters, sections and subsections
	# Subsubsections are not merged, IMO the better choice.
	#

	my @chapters = $self->chapters;

	my $merge_subsections = sub {
		my ($section, $inherit) = @_;
		$section->extends($inherit);
		$section->subsections($self->mergeStructure(
			this      => [ $section->subsections ],
			super     => [ $inherit->subsections ],
			merge     => sub { $_[0]->extends($_[1]); $_[0] },
			container => $section,
		));
		$section;
	};

	my $merge_sections = sub {
		my ($chapter, $inherit) = @_;
		$chapter->extends($inherit);
		$chapter->sections($self->mergeStructure(
			this      => [ $chapter->sections ],
			super     => [ $inherit->sections ],
			merge     => $merge_subsections,
			container => $chapter,
		));
		$chapter;
	};

	foreach my $super (@supers)
	{
		$self->chapters($self->mergeStructure(
			this      => \@chapters,
			super     => [ $super->chapters ],
			merge     => $merge_sections,
			container => $self,
		));
	}

	#
	# Give all the inherited subroutines a new location in this manual.
	#

	my %extended  = map +($_->name => $_),
						map $_->subroutines,
							($self, $self->extraCode);

	my %used;  # items can be used more than once, collecting multiple inherit

	my @inherited = map $_->subroutines, @supers;
	my %location;

	foreach my $inherited (@inherited)
	{	my $name        = $inherited->name;
		if(my $extended = $extended{$name})
		{	# on this page and upper pages
			$extended->extends($inherited);

			unless($used{$name}++)    # add only at first appearance
			{	my $path = $self->mostDetailedLocation($extended);
				push @{$location{$path}}, $extended;
			}
		}
		else
		{	# only defined on higher level manual pages
			my $path = $self->mostDetailedLocation($inherited);
			push @{$location{$path}}, $inherited;
		}
	}

	while(my ($name, $item) = each %extended)
	{	next if $used{$name};
		push @{$location{$item->path}}, $item;
	}

	foreach my $chapter ($self->chapters)
	{	$chapter->setSubroutines(delete $location{$chapter->path});
		foreach my $section ($chapter->sections)
		{	$section->setSubroutines(delete $location{$section->path});
			foreach my $subsect ($section->subsections)
			{	$subsect->setSubroutines(delete $location{$subsect->path});
				foreach my $subsubsect ($subsect->subsubsections)
				{	$subsubsect->setSubroutines(delete $location{$subsubsect->path});
				}
			}
		}
	}

	warning __x"section without location in {manual}: {section}", manual => $self, section => $_
		for keys %location;

	$self->{OM_is_expanded} = 1;
	$self;
}


sub mergeStructure(%)
{	my ($self, %args) = @_;
	my @this      = defined $args{this}  ? @{$args{this}}  : ();
	my @super     = defined $args{super} ? @{$args{super}} : ();
	my $container = $args{container} or panic;

	my $equal     = $args{equal} || sub { "$_[0]" eq "$_[1]" };
	my $merge     = $args{merge} || sub { $_[0] };

	my @joined;

	while(@super)
	{	my $take = shift @super;
		unless(first {$equal->($take, $_)} @this)
		{	push @joined, $take->emptyExtension($container)
				unless @joined && $joined[-1]->path eq $take->path;
			next;
		}

		# A low-level merge is needed.

		my $insert;
		while(@this)      # insert everything until equivalents
		{	$insert = shift @this;
			last if $equal->($take, $insert);

			if(first {$equal->($insert, $_)} @super)
			{	my ($fn, $ln) = $insert->where;
				warning __x"order conflict: '{take}' before '{insert}' in {file} line {linenr}",
					take => $take, insert => $insert, file => $fn, linenr => $ln;
			}

			push @joined, $insert
				unless @joined && $joined[-1]->path eq $insert->path;
		}
		push @joined, $merge->($insert, $take);
	}

	(@joined, @this);
}


sub mostDetailedLocation($)
{	my ($self, $thing) = @_;

	my $inherit = $thing->extends
		or return $thing->path;

	my $path1   = $thing->path;
	my $path2   = $self->mostDetailedLocation($inherit);
	my ($lpath1, $lpath2) = (length($path1), length($path2));

	return $path1
		if $path1 eq $path2;

	return $path2
		if $lpath1 < $lpath2 && substr($path2, 0, $lpath1+1) eq "$path1/";

	return $path1
		if $lpath2 < $lpath1 && substr($path1, 0, $lpath2+1) eq "$path2/";

	warning __x"subroutine '{name}' location conflict:\n  {p1} in {man1}\n  {p2} in {man2}",
		name => "$thing", p1 => $path1, man1 => $thing->manual, p2 => $path2, man2 => $inherit->manual
		if $self eq $thing->manual;

	$path1;
}


sub createInheritance()
{	my $self = shift;
	my $has  = $self->chapter('INHERITANCE');
	return $has if defined $has;

	trace "create inheritance for $self";

	if($self->name ne $self->package)
	{	# This is extra code....
		my $from = $self->package;
		return "\n $self\n    contains extra code for\n    M<$from>\n";
	}

	my $output;
	my @supers  = $self->superClasses;

	if(my $realized = $self->realizes)
	{	$output .= "\n $self realizes a M<$realized>\n";
		@supers = $realized->superClasses if blessed $realized;
	}

	if(my @extras = $self->extraCode)
	{	$output .= "\n $self has extra code in\n";
		$output .= "   M<$_>\n" for sort @extras;
	}

	foreach my $super (@supers)
	{	$output .= "\n $self\n";
		$output .= $self->createSuperSupers($super);
	}

	if(my @subclasses = $self->subClasses)
	{	$output .= "\n $self is extended by\n";
		$output .= "   M<$_>\n" for sort @subclasses;
	}

	if(my @realized = $self->realizers)
	{	$output .= "\n $self is realized by\n";
		$output .= "   M<$_>\n" for sort @realized;
	}

	my $chapter = OODoc::Text::Chapter->new(name => 'INHERITANCE', manual => $self, linenr => -1, description => $output)
		if $output && $output =~ /\S/;

	$self->chapter($chapter);
}

sub createSuperSupers($)
{	my ($self, $package) = @_;
	my $output = $package =~ /^[aeio]/i ? "   is an M<$package>\n" : "   is a M<$package>\n";

	ref $package
		or return $output;  # only the name of the package is known

	if(my $realizes = $package->realizes)
	{	$output .= $self->createSuperSupers($realizes);
		return $output;
	}

	my @supers = $package->superClasses or return $output;
	$output   .= $self->createSuperSupers(shift @supers);

	foreach(@supers)
	{	$output .= "\n\n   $package also extends M<$_>\n";
		$output .= $self->createSuperSupers($_);
	}

	$output;
}

sub exportInheritance()
{	my $self = shift;

	trace "export inheritance for $self";

	$self->name eq $self->package
		or return +{ extra_code_for => $self->package };

	my %tree;
	my @supers  = $self->superClasses;

	if(my $realized = $self->realizes)
	{	$tree{realizes} = "$realized";
		@supers = $realized->superClasses if blessed $realized;
	}

	if(my @extras = $self->extraCode)
	{	$tree{extra_code_in} = [ sort map "$_", @extras ];
	}

	$tree{extends} = [ sort map "$_", @supers ] if @supers;

	if(my @subclasses = $self->subClasses)
	{	$tree{extended_by} = [ sort map "$_", @subclasses ];
	}

	if(my @realized = $self->realizers)
	{	$tree{realized_by} = [ sort map "$_", @realized ];
	}

	\%tree;
}

sub publish($%)
{	my ($self, $config, %args) = @_;
	my $manual   = $config->{manual} = $self;

	my $exporter = $config->{exporter};
	$exporter->processingManual($manual);

	my $p = $self->SUPER::publish($config);

	my @ch;
	foreach my $name (@chapter_names)
	{	my $chapter  = $self->chapter(uc $name) or next;
		push @ch, $chapter->publish($config)->{id};
	}

	$p->{name}         = $exporter->markupString($self->name);
	$p->{title}        = $exporter->markupString($self->title);
	$p->{package}      = $exporter->markup($self->package);
	$p->{distribution} = $exporter->markup($self->distribution);
	$p->{version}      = $exporter->markup($self->version);
	$p->{is_pure_pod}  = $exporter->boolean($self->isPurePod);
	$p->{chapters}     = \@ch;
	$p->{inheritance}  = $self->exportInheritance;

	$exporter->processingManual(undef);
	$p;
}


sub finalize(%)
{	my ($self, %args) = @_;

	trace "finalize manual $self";

	# Maybe the parser has still things to do
	$self->parser->finalizeManual($self, %args);

	$self;
}

#--------------------

sub stats()
{	my $self     = shift;
	my $chapters = $self->chapters || return;
	my $subs     = $self->ownSubroutines;
	my $options  = map $_->options, $self->ownSubroutines;
	my $diags    = $self->diagnostics;
	my $examples = $self->examples;
	my $manual   = $self->name;
	my $package  = $self->package;
	my $head     = $manual eq $package ? "manual $manual" : "manual $manual for $package";

	<<STATS;
$head
   chapters:               $chapters
   documented subroutines: $subs
   documented options:     $options
   documented diagnostics: $diags
   shown examples:         $examples
STATS
}


sub index()
{	my $self  = shift;
	my @lines;
	foreach my $chapter ($self->chapters)
	{	push @lines, $chapter->name;
		foreach my $section ($chapter->sections)
		{	push @lines, "  ".$section->name;
			push @lines, map "    ".$_->name, $section->subsections;
		}
	}
	join "\n", @lines, '';
}

1;
