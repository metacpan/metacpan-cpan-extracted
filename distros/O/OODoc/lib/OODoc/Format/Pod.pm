# This code is part of Perl distribution OODoc version 3.03.
# The POD got stripped from this file by OODoc version 3.03.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package OODoc::Format::Pod;{
our $VERSION = '3.03';
}

use parent 'OODoc::Format';

use strict;
use warnings;

use Log::Report    'oodoc';

use File::Spec::Functions qw/catfile/;
use List::Util            qw/max/;
use Pod::Escapes          qw/e2char/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{format} //= 'pod';
	$self->SUPER::init($args);
}

#--------------------

sub cleanup($$%)
{	my ($self, $manual, $string, %args) = @_;
	$manual->parser->cleanupPod($manual, $string, %args,
		create_link => sub { $self->link(@_) },
	);
}


sub link($$;$$)
{	my ($any, $manual, $object, $text) = @_;

	$object = $object->subroutine if $object->isa('OODoc::Text::Option');
	$object = $object->subroutine if $object->isa('OODoc::Text::Default');
	$object = $object->container  if $object->isa('OODoc::Text::Example');
	$object = $object->container  if $object->isa('OODoc::Text::Subroutine');
	$text   = defined $text ? "$text|" : '';

	return "L<$text$object>"
		if $object->isa('OODoc::Manual');

	$object->isa('OODoc::Text::Structure')
		or error __x"cannot link to a {package}", package => ref $object;

	my $manlink = defined $manual ? $object->manual.'/' : '';
	qq(L<$text$manlink"$object">);
}


sub createManual($@)
{	my ($self, %args) = @_;
	my $manual   = $args{manual} or panic;
	my $podname  = $manual->source =~ s/\.pm$/.pod/r;
	my $tmpname  = $podname . 't';

	my $tmpfile  = catfile $self->workdir, $tmpname;
	my $podfile  = catfile $self->workdir, $podname;

	open my $output, '>:encoding(utf8)', $tmpfile
		or fault __x"cannot write prelimary pod manual to {file}", file => $tmpfile;

	$self->_formatManual(
		manual => $manual,
		output => $output,
		append => $args{append},
		%args
	);

	$output->close;

	$self->simplifyPod($tmpfile, $podfile);
	unlink $tmpfile;

	$self->manifest->add($podfile);

	$self;
}

sub _formatManual(@)
{	my $self = shift;
	$self->chapterName(@_);
	$self->chapterInheritance(@_);
	$self->chapterSynopsis(@_);
	$self->chapterDescription(@_);
	$self->chapterOverloaded(@_);
	$self->chapterMethods(@_);
	$self->chapterExports(@_);
	$self->chapterDetails(@_);
	$self->chapterDiagnostics(@_);
	$self->chapterReferences(@_);
	$self->chapterCopyrights(@_);
	$self->showAppend(@_);
	$self;
}

sub showAppend(@)
{	my ($self, %args) = @_;
	my $append = $args{append};

	   if(!defined $append)      { ; }
	elsif(ref $append eq 'CODE') { $append->(formatter => $self, %args) }
	else
	{	my $output = $args{output} or panic;
		$output->print($append);
	}

	$self;
}

sub showStructureExpanded(@)
{	my ($self, %args) = @_;

	my $examples = $args{show_examples} || 'EXPAND';
	my $text     = $args{structure} or panic;

	my $name     = $text->name;
	my $level    = $text->level;
	my $output   = $args{output}  or panic;
	my $manual   = $args{manual}  or panic;

	my $descr   = $self->cleanup($manual, $text->description);
	$output->print("\n=head$level $name\n\n$descr");

	$self->showSubroutines(%args, subroutines => [ $text->subroutines ]);
	$self->showExamples(%args, examples => [ $text->examples ])
		if $examples eq 'EXPAND';

	$self;
}

sub showStructureRefer(@)
{	my ($self, %args) = @_;
	my $text     = $args{structure} or panic;

	my $name     = $text->name;
	my $level    = $text->level;
	my $output   = $args{output}  or panic;
	my $manual   = $args{manual}  or panic;

	my $link     = $self->link($manual, $text);
	$output->print("\n=head$level $name\n\nSee $link.\n");
	$self;
}

sub chapterDescription(@)
{	my ($self, %args) = @_;

	$self->showRequiredChapter(DESCRIPTION => %args);

	my $manual  = $args{manual} or panic;
	my $details = $manual->chapter('DETAILS') // return $self;

	my $output  = $args{output} or panic;
	$output->print("\nSee L</DETAILS> chapter below\n");
	$self->showChapterIndex($output, $details, "   ");
	$self;
}

sub chapterDiagnostics(@)
{	my ($self, %args) = @_;
	my $manual  = $args{manual} or panic;

	my $diags   = $manual->chapter('DIAGNOSTICS');
	$self->showChapter(chapter => $diags, %args)
		if defined $diags;

	my @diags   = map $_->diagnostics, $manual->subroutines;
	return unless @diags;

	my $output  = $args{output} or panic;
	$diags
		or $output->print("\n=head1 DIAGNOSTICS\n");

	$output->print("\n=over 4\n\n");
	$self->showDiagnostics(%args, diagnostics => \@diags);
	$output->print("\n=back\n\n");
	$self;
}


sub showChapterIndex($$;$)
{	my ($self, $output, $chapter, $indent) = @_;
	$indent //= '';

	foreach my $section ($chapter->sections)
	{	$output->print($indent, $section->name, "\n");
		foreach my $subsection ($section->subsections)
		{	$output->print($indent, $indent, $subsection->name, "\n");
		}
	}
	$self;
}

sub showExamples(@)
{	my ($self, %args) = @_;
	my $examples = $args{examples} or panic;
	@$examples or return;

	my $manual    = $args{manual}  or panic;
	my $output    = $args{output}  or panic;

	foreach my $example (@$examples)
	{	my $name    = $self->cleanup($manual, $example->name);
		$output->print("\nexample: $name\n\n");
		$output->print($self->cleanup($manual, $example->description));
		$output->print("\n");
	}
	$self;
}

sub showDiagnostics(@)
{	my ($self, %args) = @_;
	my $diagnostics = $args{diagnostics} or panic;
	@$diagnostics or return;

	my $manual    = $args{manual}  or panic;
	my $output    = $args{output}  or panic;

	foreach my $diag (sort @$diagnostics)
	{	my $name    = $self->cleanup($manual, $diag->name);
		my $type    = $diag->type;
		$output->print("\n=item $type: $name\n\n");
		$output->print($self->cleanup($manual, $diag->description));
		$output->print("Cast by ", $diag->subroutine->name, "()\n");
		$output->print("\n");
	}
	$self;
}

sub showSubroutines(@)
{	my ($self, %args) = @_;
	my $subs = $args{subroutines} || [];
	@$subs or return;

	my $output = $args{output} or panic;

	$output->print("\n=over 4\n\n");
	$self->SUPER::showSubroutines(%args);
	$output->print("\n=back\n\n");
}

sub showSubroutine(@)
{	my $self = shift;
	$self->SUPER::showSubroutine(@_);

	my %args   = @_;
	my $output = $args{output} or panic;
	$output->print("\n");
	$self;
}

sub showSubroutineUse(@)
{	my ($self, %args) = @_;
	my $subroutine = $args{subroutine} or panic;
	my $manual     = $args{manual}     or panic;
	my $output     = $args{output}     or panic;

	my $use = $self->subroutineUse($manual, $subroutine);
	$use    =~ s/(.+)/=item $1\n\n/gm;

	$output->print($use);
	$output->print("Inherited, see ". $self->link($manual, $subroutine)."\n\n")
		if $manual->inherited($subroutine);

	$self;
}

sub subroutineUse($$)
{	my ($self, $manual, $subroutine) = @_;
	my $type       = $subroutine->type;
	my $name       = $self->cleanup($manual, $subroutine->name);
	my $paramlist  = $self->cleanup($manual, $subroutine->parameters);

	$type eq 'tie'
		and return qq[tie B<$name>, $paramlist];

	my $params     = !length $paramlist ? '()' :
		$paramlist =~ m/^[\[<]|[\]>]$/ ? "( $paramlist )" : "($paramlist)";

	my $class      = $manual->package;
	my $use
	  = $type eq 'i_method' ? qq[\$obj-E<gt>B<$name>$params]
	  : $type eq 'c_method' ? qq[\$class-E<gt>B<$name>$params]
	  : $type eq 'ci_method'? qq[\$any-E<gt>B<$name>$params]
	  : $type eq 'function' ? qq[B<$name>$params]
	  : $type eq 'overload' ? qq[overload: B<$name> $paramlist]
	  :    panic $type;

	$use;
}

sub showSubroutineName(@)
{	my ($self, %args) = @_;
	my $subroutine = $args{subroutine} or panic;
	my $manual     = $args{manual}     or panic;
	my $output     = $args{output}     or panic;
	my $name       = $subroutine->name;

	my $url = $manual->inherited($subroutine) ? "M<".$subroutine->manual."::$name>" : "M<$name>";
	$output->print( $self->cleanup($manual, $url), ($args{last} ? ".\n" : ",\n") );
}

sub showOptions(@)
{	my ($self, %args) = @_;
	my $output = $args{output} or panic;
	$output->print("\n=over 2\n\n");
	$self->SUPER::showOptions(%args);
	$output->print("\n=back\n\n");
}

sub showOptionUse(@)
{	my ($self, %args) = @_;
	my $output = $args{output} or panic;
	my $option = $args{option} or panic;
	my $manual = $args{manual}  or panic;

	my $params = $option->parameters =~ s/\s+$//r =~ s/^\s+//r;
	$params    = " => ".$self->cleanup($manual, $params) if length $params;

	$output->print("=item $option$params\n\n");
	$self;
}

sub showOptionExpand(@)
{	my ($self, %args) = @_;
	my $output = $args{output} or panic;
	my $option = $args{option} or panic;
	my $manual = $args{manual}  or panic;

	$self->showOptionUse(%args);

	my $where = $option->findDescriptionObject or return $self;
	my $descr = $self->cleanup($manual, $where->description);
	$output->print("\n$descr\n\n") if length $descr;
	$self;
}


sub writeTable($@)
{	my ($self, %args) = @_;

	my $head   = $args{header} or panic;
	my $output = $args{output} or panic;
	my $rows   = $args{rows}   or panic;
	@$rows or return;

	# Convert all elements to plain text, because markup is not
	# allowed in verbatim pod blocks.
	my @rows;
	foreach my $row (@$rows)
	{	push @rows, [ map {$self->removeMarkup($_)} @$row ];
	}

	# Compute column widths
	my @w      = (0) x @$head;

	foreach my $row ($head, @rows)
	{	$w[$_] = max $w[$_], length($row->[$_])
			foreach 0..$#$row;
	}

	if(my $widths = $args{widths})
	{	defined $widths->[$_] && $widths->[$_] > $w[$_] && ($w[$_] = $widths->[$_])
			for 0..$#$rows;
	}

	pop @w;   # ignore width of last column

	# Table head
	my $headf  = " -".join("--", map "\%-${_}s", @w)."--%s\n";
	$output->printf($headf, @$head);

	# Table body
	my $format = "  ".join("  ", map "\%-${_}s", @w)."  %s\n";
	$output->printf($format, @$_) for @rows;
}


sub removeMarkup($)
{	my ($self, $string) = @_;
	my $out = $self->_removeMarkup($string);
	for($out)
	{	s/^\s+//gm;
		s/\s+$//gm;
		s/\s{2,}/ /g;
		s/\[NB\]/ /g;
	}
	$out;
}

sub _removeMarkup($)
{	my ($self, $string) = @_;

	my $out = '';
	while($string =~ s/
			(.*?)         # before
			([BCEFILSXZ]) # known formatting codes
			([<]+)        # capture ALL starters
		//x)
	{	$out .= $1;
		my ($tag, $bracks, $brack_count) = ($2, $3, length($3));

		if($string !~ s/^(|.*?[^>])  # contained
						[>]{$brack_count}
						(?![>])
						//xs)
		{	$out .= "$tag$bracks";
			next;
		}

		my $container = $1;
		if($tag =~ m/[XZ]/) { ; }  # ignore container content
		elsif($tag =~ m/[BCI]/)    # cannot display, but can be nested
		{	$out .= $self->_removeMarkup($container);
		}
		elsif($tag eq 'E') { $out .= e2char($container) }
		elsif($tag eq 'F') { $out .= $container }
		elsif($tag eq 'L')
		{	if($container =~ m!^\s*([^/|]*)\|!)
			{	$out .= $self->_removeMarkup($1);
				next;
			}

			my ($man, $chapter) = ($container, '');
			if($container =~ m!^\s*([^/]*)/\"([^"]*)\"\s*$!)
			{	($man, $chapter) = ($1, $2);
			}
			elsif($container =~ m!^\s*([^/]*)/(.*?)\s*$!)
			{	($man, $chapter) = ($1, $2);
			}

			$out .=
			  ( !length $man     ? "section $chapter"
			  : !length $chapter ? $man
			  :                    "$man section $chapter"
			  );
		}
		elsif($tag eq 'S')
		{	my $clean = $self->_removeMarkup($container);
			$clean =~ s/ /[NB]/g;
			$out  .= $clean;
		}
	}

	$out . $string;
}

sub showSubroutineDescription(@)
{	my ($self, %args) = @_;
	my $manual  = $args{manual}         or panic;
	my $output  = $args{output}         or panic;
	my $subroutine = $args{subroutine}  or panic;

	# Z<> will cause an empty body when the description is missing, so there
	# will be a blank line to the next sub description.
	my $text    = $self->cleanup($manual, $subroutine->description);
	my $extends = $subroutine->extends;
	my $refer   = $extends ? $extends->findDescriptionObject : undef;
	$text     ||= $self->cleanup($manual, "Z<>\n") unless $refer;

	$output->print("\n", $text) if length $text;
	$output->print("Improves base, see ",$self->link($manual, $refer),"\n") if $refer;
}

sub showSubroutineDescriptionRefer(@)
{	my ($self, %args) = @_;
	my $manual  = $args{manual}         or panic;
	my $output  = $args{output}         or panic;
	my $subroutine = $args{subroutine}  or panic;
	$output->print("\nInherited, see ",$self->link($manual, $subroutine),"\n");
}

sub showSubsIndex() {;}


sub simplifyPod($$)
{	my ($self, $infn, $outfn) = @_;

	open my $in, "<:encoding(utf8)", $infn
		or fault __x"cannot read prelimary pod from {file}", file => $infn;

	open my $out, ">:encoding(utf8)", $outfn
		or fault __x"cannot write final pod to {file}", file => $outfn;

	my $last_is_blank = 1;
  LINE:
	while(my $l = $in->getline)
	{	if($l =~ m/^\s*$/s)
		{	next LINE if $last_is_blank;
			$last_is_blank = 1;
		}
		else
		{	$last_is_blank = 0;
		}

		$out->print($l);
	}

	$in->close;
	$out->close
		or fault __x"write to {file} failed", file => $outfn;

	$self;
}

#--------------------

1;
