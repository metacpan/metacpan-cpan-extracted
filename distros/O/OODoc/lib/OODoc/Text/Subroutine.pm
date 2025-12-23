# This code is part of Perl distribution OODoc version 3.05.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package OODoc::Text::Subroutine;{
our $VERSION = '3.05';
}

use parent 'OODoc::Text';

use strict;
use warnings;

use Log::Report    'oodoc';
use Scalar::Util   qw/blessed/;

#--------------------

sub init($)
{	my ($self, $args) = @_;

	exists $args->{name} or panic;
	$self->SUPER::init($args) or return;

	$self->{OTS_param}    = delete $args->{parameters};
	$self->{OTS_options}  = {};
	$self->{OTS_defaults} = {};
	$self->{OTS_diags}    = [];
	$self;
}

sub _call($)
{	my ($self, $exporter) = @_;
	my $type       = $self->type;
	my $unique     = $self->unique;
	my $style      = $exporter->markupStyle;

	my $name       = $exporter->markupString($self->name);
	my $paramlist  = $exporter->markupString($self->parameters);

	### Also implemented in the formatters...

	if($style eq 'html')
	{	my $call       = qq[<b><a name="$unique">$name</a></b>];
		$type eq 'tie'
			and return qq[tie $call, $paramlist];

		$call         .= "(&nbsp;$paramlist&nbsp;)" if length $paramlist;

		return
			$type eq 'i_method' ? qq[\$obj-&gt;$call]
		  : $type eq 'c_method' ? qq[\$class-&gt;$call]
		  : $type eq 'ci_method'? qq[\$any-&gt;$call]
		  : $type eq 'overload' ? qq[overload: $call]
		  : $type eq 'function' ? qq[$call]
		  :    panic "Type $type? for $call";
	}

	if($style eq 'pod')
	{	$type eq 'tie'
			and return qq[tie B<$name>, $paramlist];

		my $params = !length $paramlist ? '()' :
			$paramlist =~ m/^[\[<]|[\]>]$/ ? "( $paramlist )" : "($paramlist)";

		return
			$type eq 'i_method' ? qq[\$obj-E<gt>B<$name>$params]
		  : $type eq 'c_method' ? qq[\$class-E<gt>B<$name>$params]
		  : $type eq 'ci_method'? qq[\$any-E<gt>B<$name>$params]
		  : $type eq 'function' ? qq[B<$name>$params]
		  : $type eq 'overload' ? qq[overload: B<$name>]
		  :    panic $type;
	}

	panic $style;
}

sub publish($)
{	my ($self, $args) = @_;
	my $exporter = $args->{exporter} or panic;

	my $p      = $self->SUPER::publish($args);
	$p->{call} = $self->_call($exporter);

	my $opts   = $self->collectedOptions; # = [ [ $option, $default ], ... ]
	if(keys %$opts)
	{	my @options = map +[ map $_->publish($args)->{id}, @$_ ],
			sort { $a->[0]->name cmp $b->[0]->name }
				values %$opts;

		$p->{options}= \@options;
	}

	my @d = map $_->publish($args)->{id}, $self->diagnostics;
	$p->{diagnostics} = \@d if @d;
	$p;
}



sub extends($)
{	my $self  = shift;
	@_ or return $self->SUPER::extends;

	my $super = shift;
	if($self->type ne $super->type)
	{	my ($fn1, $ln1) = $self->where;
		my ($fn2, $ln2) = $super->where;
		my ($t1,  $t2 ) = ($self->type, $super->type);

		warning __x"subroutine {name}() extended by different type:\n  {type1} in {file1} line {line1}\n  {type2} in {file2} line {line2}",
			name => "$self",
			type1 => $t1, file1 => $fn1, line1 => $ln1,
			type2 => $t2, file2 => $fn2, line2 => $ln2;
	}

	$self->SUPER::extends($super);
}

#--------------------

sub parameters() { $_[0]->{OTS_param} }



sub location($)
{	my ($self, $manual) = @_;
	my $container = $self->container;
	my $super     = $self->extends
		or return $container;

	my $superloc  = $super->location;
	my $superpath = $superloc->path;
	my $mypath    = $container->path;

	return $container if $superpath eq $mypath;

	if(length $superpath < length $mypath)
	{	return $container
			if substr($mypath, 0, length($superpath)+1) eq "$superpath/";
	}
	elsif(substr($superpath, 0, length($mypath)+1) eq "$mypath/")
	{	return $self->manual->chapter($superloc->name)
			if $superloc->isa("OODoc::Text::Chapter");

		my $chapter = $self->manual->chapter($superloc->chapter->name);

		return $chapter->section($superloc->name)
			if $superloc->isa("OODoc::Text::Section");

		my $section = $chapter->section($superloc->section->name);

		return $section->subsection($superloc->name)
			if $superloc->isa("OODoc::Text::SubSection");

		my $subsection = $section->subsection($superloc->subsection->name);

		return $subsection->subsubsection($superloc->name)
			if $superloc->isa("OODoc::Text::SubSubSection");

		panic $superloc;
	}

	unless($manual->inherited($self))
	{	my ($myfn, $myln)       = $self->where;
		my ($superfn, $superln) = $super->where;

		warning __x"subroutine {name}() location conflict:\n  {path1} in {file1} line {line1}\n  {path2} in {file2} line {line2}",
			name => "$self",
			path1 => $mypath, file1 => $myfn, line1 => $myln,
			path2 => $superpath, file2 => $superfn, line2 => $superln;
	}

	$container;
}


sub path() { $_[0]->container->path }

#--------------------

sub default($)
{	my ($self, $it) = @_;
	blessed $it
		or return $self->{OTS_defaults}{$it};

	my $name = $it->name;
	$self->{OTS_defaults}{$name} = $it;
	$it;
}


sub defaults() { values %{ $_[0]->{OTS_defaults}} }


sub option($)
{	my ($self, $it) = @_;
	blessed $it
		or return $self->{OTS_options}{$it};

	my $name = $it->name;
	$self->{OTS_options}{$name} = $it;
	$it;
}


sub findOption($)
{	my ($self, $name) = @_;
	my $option = $self->option($name);
	return $option if $option;

	my $extends = $self->extends or return;
	$extends->findOption($name);
}


sub options() { values %{ $_[0]->{OTS_options}} }


sub diagnostic($)
{	my ($self, $diag) = @_;
	push @{$self->{OTS_diags}}, $diag;
	$diag;
}


sub diagnostics() { @{ $_[0]->{OTS_diags}} }


sub collectedOptions(@)
{	my ($self, %args) = @_;
	my @extends   = $self->extends;
	my %options;
	foreach my $base ($self->extends)
	{	my $options = $base->collectedOptions(%args);
		@options{keys %$options} = values %$options;
	}

	$options{$_->name}[0] = $_ for $self->options;

	foreach my $default ($self->defaults)
	{	my $name = $default->name;

		unless(exists $options{$name})
		{	my ($fn, $ln) = $default->where;
			warning __x"no option {name} for default in {file} line {linenr}", name => $name, file => $fn, linenr => $ln;
			next;
		}
		$options{$name}[1] = $default;
	}

	foreach my $option ($self->options)
	{	my $name = $option->name;
		next if defined $options{$name}[1];

		my ($fn, $ln) = $option->where;
		warning __x"no default for option {name} defined in {file} line {linenr}", name => $name, file => $fn, linenr => $ln;

		my $default = $options{$name}[1] =
			OODoc::Text::Default->new(name => $name, value => 'undef', subroutine => $self, linenr => $ln);

		$self->default($default);
	}

	\%options;
}

1;
