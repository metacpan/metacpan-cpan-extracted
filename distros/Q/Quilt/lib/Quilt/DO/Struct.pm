#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Struct.pm,v 1.2 1997/12/07 01:02:51 ken Exp $
#

use Quilt;

use strict;

package Quilt::DO::Struct;
@Quilt::DO::Struct::ISA = qw{Quilt::Flow};

package Quilt::DO::Struct::Section;
@Quilt::DO::Struct::Section::ISA = qw{Quilt::DO::Struct};

sub type {
    my $self = shift;

    $self = $self->delegate;
    return (defined ($self->{'type'}) ? $self->{'type'} : "Section");
}

sub numbers {
    my $self = shift;
    my @rootpath = $self->rootpath;

    my (@sect_nums, $node);
    # XXX the following is an example of why `rootpath' (among other
    # selectors) should take a query argument
    foreach $node (@rootpath) {
	# XXX $node->is ('section')
	if (ref ($node) =~ /DO::Struct::Section/) {
	    my $type = $node->type;
	    # XXX $node->is ('preface')
	    if ($type eq 'Preface') {
		return ();
	    }
	    last;
	}
    }
    foreach $node (@rootpath) {
	if (ref ($node) =~ /DO::Struct::Section/) {
	    push (@sect_nums, $node->number);
	}
    }

    return @sect_nums;
}

sub number {
    my $self = shift;
    my $real_self = $self->delegate;
    my $number = 1;
    my $in_appendices = 0;

    my $contents = $self->parent->contents();
    my $ii;
    for ($ii = 0; $ii <= $#$contents; $ii ++) {
	last if $contents->[$ii] == $real_self;

	$number ++
	    if (ref ($contents->[$ii]) eq 'Quilt::DO::List::Item');
	if (ref ($contents->[$ii]) =~ /DO::Struct::Section/) {
	    my $type = $contents->[$ii]->type;
	    $number ++
		if $type ne 'Preface';
	    if (!$in_appendices && $type =~ /Appendix/) {
		$in_appendices = 1;
		$number = "A";
	    }
	}
    }

    return $number;
}

sub level {
    my $self = shift;

    my $sect_level = 0;
    my $node;
    my @rootpath = $self->rootpath;
    foreach $node (@rootpath) {
	if (ref ($node) =~ /Quilt::DO::Struct::Section/) {
	    $sect_level ++;
	}
    }

    return $sect_level;
}

package Quilt::DO::Struct::Section::Iter;

sub type    { goto &Quilt::DO::Struct::Section::type; }
sub level   { goto &Quilt::DO::Struct::Section::level; }
sub number  { goto &Quilt::DO::Struct::Section::number; }
sub numbers { goto &Quilt::DO::Struct::Section::numbers; }

1;
