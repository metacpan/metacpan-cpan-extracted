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

package OODoc::Format::Pod3;{
our $VERSION = '3.03';
}

use parent 'OODoc::Format::Pod';

use strict;
use warnings;

use Log::Report      'oodoc';

use OODoc::Template  ();
use List::Util       qw/first/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{format} //= 'pod3';
	$self->SUPER::init($args);
}

#--------------------

my $default_template;
{	local $/;
	$default_template = <DATA>;
	close DATA;
}

sub createManual(@)
{	my ($self, %args) = @_;
	$self->{OFP_template} = delete $args{template} || \$default_template;
	$self->SUPER::createManual(%args);
}

sub _formatManual(@)
{	my ($self, %args) = @_;
	my $output    = delete $args{output};

	my $template  = OODoc::Template->new(
		markers       => [ '<{', '}>' ],
		manual_obj    => delete $args{manual},
		chapter_order => [ qw/
			NAME INHERITANCE SYNOPSIS DESCRIPTION OVERLOADED METHODS
			FUNCTIONS CONSTANTS EXPORTS DIAGNOSTICS DETAILS REFERENCES
			COPYRIGHTS
		/ ],
		%args,
	);

	$output->print(scalar $template->process(
		$self->{OFP_template},
		manual         => sub { shift; ( {}, @_ ) },
		chapters       => sub { $self->chapters($template, @_) },
		sections       => sub { $self->sections($template, @_) },
		subsections    => sub { $self->subsections($template, @_) },
		subsubsections => sub { $self->subsubsections($template, @_) },
		subroutines    => sub { $self->subroutines($template, @_) },
		diagnostics    => sub { $self->diagnostics($template, @_) },
	));
}

sub structure($$$)
{	my ($self, $template, $type, $object) = @_;

	my $manual = $template->valueFor('manual_obj');
	my $descr  = $self->cleanup($manual, $object->description);
	my $name   = $object->name;

	$descr =~ s/\n*$/\n\n/
		if defined $descr && length $descr;

	my @examples;
	foreach my $example ($object->examples)
	{	my $title = $example->name || 'Example';
		$title = "Example: $example" if $title !~ /example/i;
		$title =~ s/\s+$//;

		push @examples, +{
			title => $title,
			descr => $self->cleanup($manual, $example->description)
		};
	}

	my @extends;
	@extends = map +{manual => $_->manual, header => $name}, $object->extends
		if $name ne 'NAME' && $name ne 'SYNOPSIS';

	+{	$type        => $name,
		$type.'_obj' => $object,
		description  => $descr,
		examples     => \@examples,
		extends      => \@extends,
	 };
}

sub chapters($$$$$)
{	my ($self, $template, $tag, $attrs, $then, $else) = @_;
	my $manual   = $template->valueFor('manual_obj');
	my @chapters = map $self->structure($template, chapter => $_), $manual->chapters;

	if(my $order = $attrs->{order})
	{	my @order = ref $order eq 'ARRAY' ? @$order : split( /\,\s*/, $order);
		my %order;

		# first the pre-defined names, then the other
		my $count = 1;
		$order{$_} = $count++ for @order;
		$order{$_->{chapter}} ||= $count++ for @chapters;

		@chapters = sort { $order{$a->{chapter}} <=> $order{$b->{chapter}} } @chapters;
	}

	( \@chapters, $attrs, $then, $else );
}

sub sections($$$$$)
{	my ($self, $template, $tag, $attrs, $then, $else) = @_;
	my $chapter = $template->valueFor('chapter_obj');

	first {!$_->isEmpty} $chapter->sections
		or return ([], $attrs, $then, $else);

	my @sections = map $self->structure($template, section => $_), $chapter->sections;

	( \@sections, $attrs, $then, $else );
}

sub subsections($$$$$)
{	my ($self, $template, $tag, $attrs, $then, $else) = @_;
	my $section = $template->valueFor('section_obj');

	first {!$_->isEmpty} $section->subsections
		or return ([], $attrs, $then, $else);

	my @subsections = map $self->structure($template, subsection => $_), $section->subsections;

	( \@subsections, $attrs, $then, $else );
}

sub subsubsections($$$$$)
{	my ($self, $template, $tag, $attrs, $then, $else) = @_;
	my $subsection = $template->valueFor('subsection_obj');

	first {!$_->isEmpty} $subsection->subsubsections
		or return ([], $attrs, $then, $else);

	my @subsubsections = map $self->structure($template, subsubsection => $_), $subsection->subsubsections;

	( \@subsubsections, $attrs, $then, $else );
}

sub subroutines($$$$$$)
{	my ($self, $template, $tag, $attrs, $then, $else) = @_;

	my $parent
	= $template->valueFor('subsubsection_obj')
	|| $template->valueFor('subsection_obj')
	|| $template->valueFor('section_obj')
	|| $template->valueFor('chapter_obj');

	defined $parent
		or return ();

	my $out  = '';
	open my $fh, '>:encoding(utf8)', \$out;

	my @show = map +($_ => scalar $template->valueFor($_)), qw/
		show_described_options show_described_subs show_diagnostics
		show_examples show_inherited_options show_inherited_subs
		show_option_table show_subs_index
	/;

	# This is quite weak: the whole POD section for a sub description
	# is produced outside the template.  In the future, this may get
	# changed: if there is a need for it: of course, we can do everything
	# in the template system.

	$self->showSubroutines(
		subroutines => [ $parent->subroutines ],
		manual      => $parent->manual,
		output      => $fh,
		@show,
	);

	$fh->close;
	length $out or return ();

	$out =~ s/\n*$/\n\n/;
	($out);
}

sub diagnostics($$$$$$)
{	my ($self, $template, $tag, $attrs, $then, $else) = @_;
	my $manual = $template->valueFor('manual_obj');

	my $out  = '';
	open my $fh, '>:encoding(utf8)', \$out;
	$self->chapterDiagnostics(%$attrs, manual => $manual, output => $fh);
	$fh->close;

	$out =~ s/\n*$/\n\n/;
	($out);
}

1;

__DATA__
=encoding utf8

<{macro name=structure}>\
    <{description}>\
    <{extends}>\
Extends L<"<{header}>" in <{manual}>|<{manual}>/"<{header}>">.

\
    <{/extends}>\
    <{template macro=examples}>\
    <{subroutines}>\
<{/macro}>\


<{macro name=examples}>\
<{examples}>\
    <{template macro=example}>

<{/examples}>\
<{/macro}>\


<{macro name=example}>\
B<. <{title}>>

<{descr}>
<{/macro}>\


<{manual}>\
<{chapters order=$chapter_order}>\

=head1 <{chapter}>

\
    <{template macro=structure}>\
    <{sections}>\

=head2 <{section}>

\
    <{template macro=structure}>\
    <{subsections}>\

=head3 <{subsection}>

\
        <{template macro=structure}>\
        <{subsubsections}>\

=head4 <{subsubsection}>

\
        <{template macro=structure}>\
        <{/subsubsections}>\

    <{/subsections}>\

    <{/sections}>\

<{/chapters}>\

<{diagnostics}>\
<{append}>\

<{/manual}>
