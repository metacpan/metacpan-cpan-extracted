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
#oorestyle: use of deprecated IO::Scalar: use open(my)


package OODoc::Format::Pod2;{
our $VERSION = '3.02';
}

use parent 'OODoc::Format::Pod', 'OODoc::Format::TemplateMagic';

use strict;
use warnings;

use Log::Report    'oodoc';

use Template::Magic ();
use File::Spec      ();

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{format} //= 'pod2';
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
	$self->SUPER::createManual(%args) or return;
}

sub _formatManual(@)
{	my ($self, %args) = @_;
	my $output    = delete $args{output};

	my %permitted =
	( chapter     => sub {$self->templateChapter(shift, \%args) },
		diagnostics => sub {$self->templateDiagnostics(shift, \%args) },
		append      => sub {$self->templateAppend(shift, \%args) },
		comment     => sub { '' }
	);

	my $template = Template::Magic->new({ -lookups => \%permitted });
	my $layout   = ${$self->{OFP_template}};        # Copy needed by template!
	my $created  = $template->output(\$layout);
	$output->print($$created);
}


sub templateChapter($$)
{	my ($self, $zone, $args) = @_;
	my $contained = $zone->content;
	defined $contained && length $contained
		or warning __x"no meaning for container {tags} in chapter block", tags => $contained;

	my $attrs = $zone->attributes;
	my $name  = $attrs =~ s/^\s*(\w+)\s*\,?// ? $1 : undef;

	defined $name
		or (error __x"chapter without name in template"), return '';

	my @attrs = $self->zoneGetParameters($attrs);

	open my $output, '>', \(my $out);
	$self->showOptionalChapter($name, %$args, output => $output, @attrs);
	$out;
}

sub templateDiagnostics($$)
{	my ($self, $zone, $args) = @_;
	open my $output, '>', \(my $out);
	$self->chapterDiagnostics(%$args, output => $output);
	$out;
}

sub templateAppend($$)
{	my ($self, $zone, $args) = @_;
	open my $output, '>', \(my $out);
	$self->showAppend(%$args, output => $output);
	$out;
}

1;

__DATA__
=encoding utf8

{chapter NAME}
{chapter INHERITANCE}
{chapter SYNOPSIS}
{chapter DESCRIPTION}
{chapter OVERLOADED}
{chapter METHODS}
{chapter FUNCTIONS}
{chapter CONSTANTS}
{chapter EXPORTS}
{chapter DETAILS}
{diagnostics}
{chapter REFERENCES}
{chapter COPYRIGHTS}
{comment In stead of append you can also add texts directly}
{append}
