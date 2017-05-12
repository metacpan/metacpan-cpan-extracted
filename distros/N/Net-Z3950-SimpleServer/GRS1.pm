## This file is part of simpleserver
## Copyright (C) 2000-2015 Index Data.
## All rights reserved.
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions are met:
##
##     * Redistributions of source code must retain the above copyright
##       notice, this list of conditions and the following disclaimer.
##     * Redistributions in binary form must reproduce the above copyright
##       notice, this list of conditions and the following disclaimer in the
##       documentation and/or other materials provided with the distribution.
##     * Neither the name of Index Data nor the names of its contributors
##       may be used to endorse or promote products derived from this
##       software without specific prior written permission.
##
## THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
## EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
## WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
## DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
## DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
## (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
## LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
## ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
## (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
## THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package Net::Z3950::GRS1;

use strict;
use IO::Handle;
use Carp;

sub new {
	my ($class, $href, $map) = @_;
	my $self = {};

	$self->{ELEMENTS} = [];
	$self->{FH} = *STDOUT;				## Default output handle is STDOUT
	$self->{MAP} = $map;
	bless $self, $class;
	if (defined($href) && ref($href) eq 'HASH') {
		if (!defined($map)) {
			croak 'Usage: new Net::Z3950::GRS1($href, $map);';
		}
		$self->Hash2grs($href, $map);
	}

	return $self;
}


sub Hash2grs {
	my ($self, $href, $mapping) = @_;
	my $key;
	my $content;
	my $aref;
	my $issue;

	$mapping = defined($mapping) ? $mapping : $self->{MAP};
	$self->{MAP} = $mapping;
	foreach $key (keys %$href) {
		$content = $href->{$key};
		next unless defined($content);
		if (!defined($aref = $mapping->{$key})) {
			print STDERR "Hash2grs: Unmapped key: '$key'\n";
			next;
		}
		if (ref($content) eq 'HASH') {					## Subtree?
			my $subtree = new Net::Z3950::GRS1($content, $mapping);
			$self->AddElement($aref->[0], $aref->[1], &Net::Z3950::GRS1::ElementData::Subtree, $subtree);
		} elsif (!ref($content)) {					## Regular string?
			$self->AddElement($aref->[0], $aref->[1], &Net::Z3950::GRS1::ElementData::String, $content);
		} elsif (ref($content) eq 'ARRAY') {
			my $issues = new Net::Z3950::GRS1;
			foreach $issue (@$content) {
				my $entry = new Net::Z3950::GRS1($issue, $mapping);
				$issues->AddElement(5, 1, &Net::Z3950::GRS1::ElementData::Subtree, $entry);
			}
			$self->AddElement($aref->[0], $aref->[1], &Net::Z3950::GRS1::ElementData::Subtree, $issues);
		} else {
			print STDERR "Hash2grs: Unsupported content type\n";
			next;
		}
	}
}


sub GetElementList {
	my $self = shift;

	return $self->{ELEMENTS};
}


sub CreateTaggedElement {
	my ($self, $type, $value, $element_data) = @_;
	my $tagged = {};

	$tagged->{TYPE} = $type;
	$tagged->{VALUE} = $value;
	$tagged->{OCCURANCE} = undef;
	$tagged->{META} = undef;
	$tagged->{VARIANT} = undef;
	$tagged->{ELEMENTDATA} = $element_data;

	return $tagged;
}


sub GetTypeValue {
	my ($self, $TaggedElement) = @_;

	return ($TaggedElement->{TYPE}, $TaggedElement->{VALUE});
}


sub GetElementData {
	my ($self, $TaggedElement) = @_;

	return $TaggedElement->{ELEMENTDATA};
}


sub CheckTypes {
	my ($self, $which, $content) = @_;

	if ($which == &Net::Z3950::GRS1::ElementData::String) {
		if (ref($content) eq '') {
			return 1;
		} else {
			croak "Wrong content type, expected a scalar";
		}
	} elsif ($which == &Net::Z3950::GRS1::ElementData::Subtree) {
		if (ref($content) eq __PACKAGE__) {
			return 1;
		} else {
			croak "Wrong content type, expected a blessed reference";
		}
	} else {
		croak "Content type currently not supported";
	}
}


sub CreateElementData {
	my ($self, $which, $content) = @_;
	my $ElementData = {};

	$self->CheckTypes($which, $content);
	$ElementData->{WHICH} = $which;
	$ElementData->{CONTENT} = $content;

	return $ElementData;
}


sub AddElement {
	my ($self, $type, $value, $which, $content) = @_;
	my $Elements = $self->GetElementList;
	my $ElmData = $self->CreateElementData($which, $content);
	my $TaggedElm = $self->CreateTaggedElement($type, $value, $ElmData);

	push(@$Elements, $TaggedElm);
}


sub _Indent {
	my ($self, $level) = @_;
	my $space = "";

	foreach (1..$level - 1) {
		$space .= "    ";
	}

	return $space;
}


sub _RecordLine {
	my ($self, $level, $pool, @args) = @_;
	my $fh = $self->{FH};
	my $str = sprintf($self->_Indent($level) . shift(@args), @args);

	print $fh $str;
	if (defined($pool)) {
		$$pool .= $str;
	}
}


sub Render {
	my $self = shift;
	my %args = (
			FORMAT	=>	&Net::Z3950::GRS1::Render::Plain,
			FILE	=>	'/dev/null',
			LEVEL	=>	0,
			HANDLE	=>	undef,
			POOL	=>	undef,
			@_ );
	my @Elements = @{$self->GetElementList};
	my $TaggedElement;
	my $fh = $args{HANDLE};
	my $level = ++$args{LEVEL};
	my $ref = $args{POOL};

	if (!defined($fh) && defined($args{FILE})) {
		open(FH, '> ' . $args{FILE}) or croak "Render: Unable to open file '$args{FILE}' for writing: $!";
		FH->autoflush(1);
		$fh = *FH;
	}
	$self->{FH} = defined($fh) ? $fh : $self->{FH};
	$args{HANDLE} = $fh;
	foreach $TaggedElement (@Elements) {
		my ($type, $value) = $self->GetTypeValue($TaggedElement);
		if ($self->GetElementData($TaggedElement)->{WHICH} == &Net::Z3950::GRS1::ElementData::String) {
			$self->_RecordLine($level, $ref, "(%s,%s) %s\n", $type, $value, $self->GetElementData($TaggedElement)->{CONTENT});
		} elsif ($self->GetElementData($TaggedElement)->{WHICH} == &Net::Z3950::GRS1::ElementData::Subtree) {
			$self->_RecordLine($level, $ref, "(%s,%s) {\n", $type, $value);
			$self->GetElementData($TaggedElement)->{CONTENT}->Render(%args);
			$self->_RecordLine($level, $ref, "}\n");
		}
	}
	if ($level == 1) {
		$self->_RecordLine($level, $ref, "(0,0)\n");
	}
}


package Net::Z3950::GRS1::ElementData;

## Define some constants according to the GRS-1 specification

sub Octets		{ 1 }
sub Numeric		{ 2 }
sub Date		{ 3 }
sub Ext			{ 4 }
sub String		{ 5 }
sub TrueOrFalse		{ 6 }
sub OID			{ 7 }
sub IntUnit		{ 8 }
sub ElementNotThere	{ 9 }
sub ElementEmpty	{ 10 }
sub NoDataRequested	{ 11 }
sub Diagnostic		{ 12 }
sub Subtree		{ 13 }


package Net::Z3950::GRS1::Render;

## Define various types of rendering formats

sub Plain		{ 1 }
sub XML			{ 2 }
sub Raw			{ 3 }


1;

__END__


=head1 NAME

Net::Z3950::Record::GRS1 - Perl package used to encode GRS-1 records.

=head1 SYNOPSIS

  use Net::Z3950::GRS1;

  my $a_grs1_record = new Net::Z3950::Record::GRS1;
  my $another_grs1_record = new Net::Z3950::Record::GRS1;

  $a_grs1_record->AddElement($type, $value, $content);
  $a_grs1_record->Render();

=head1 DESCRIPTION

This Perl module helps you to create and manipulate GRS-1 records (generic record syntax).
So far, you have only access to three methods:

=head2 new

Creates a new GRS-1 object,

  my $grs1 = new Net::Z3950::GRS1;

=head2 AddElement

Lets you add entries to a GRS-1 object. The method should be called this way,

  $grs1->AddElement($type, $value, $which, $content);

where $type should be an integer, and $value is free text. The $which argument should
contain one of the constants listed in Appendix A. Finally, $content contains the "thing"
that should be stored in this entry. The structure of $content should match the chosen
element data type. For

  $which == Net::Z3950::GRS1::ElementData::String;

$content should be some kind of scalar. If on the other hand,

  $which == Net::Z3950::GRS1::ElementData::Subtree;

$content should be a GRS1 object.

=head2 Render

This method digs through the GRS-1 data structure and renders the record. You call it
this way,

  $grs1->Render();

If you want to access the rendered record through a variable, you can do it like this,

  my $record_as_string;
  $grs1->Render(POOL => \$record_as_string);

If you want it stored in a file, Render should be called this way,

  $grs1->Render(FILE => 'record.grs1');

When no file name is specified, you can choose to stream the rendered record, for instance,

  $grs1->Render(HANDLE => *STDOUT);		## or
  $grs1->Render(HANDLE => *STDERR);		## or
  $grs1->Render(HANDLE => *MY_HANDLE);

=head2 Hash2grs

This method converts a hash into a GRS-1 object. Scalar entries within the hash are converted
into GRS-1 string elements. A hash entry can itself be a reference to another hash. In this case,
the new referenced hash will be converted into a GRS-1 subtree. The method is called this way,

  $grs1->Hash2grs($href, $mapping);

where $href is the hash to be converted and $mapping is referenced hash specifying the mapping
between keys in $href and (type, value) pairs in the $grs1 object. The $mapping hash could
for instance look like this,

  my $mapping =	{
			title	=>	[2, 1],
			author	=>	[1, 1],
			issn	=>	[3, 1]
		};

If the $grs1 object contains data prior to the invocation of Hash2grs, the new data represented
by the hash is simply added.


=head1 APPENDIX A

These element data types are specified in the Z39.50 protocol:

  Net::Z3950::GRS1::ElementData::Octets
  Net::Z3950::GRS1::ElementData::Numeric
  Net::Z3950::GRS1::ElementData::Date
  Net::Z3950::GRS1::ElementData::Ext
  Net::Z3950::GRS1::ElementData::String			<---
  Net::Z3950::GRS1::ElementData::TrueOrFalse
  Net::Z3950::GRS1::ElementData::OID
  Net::Z3950::GRS1::ElementData::IntUnit
  Net::Z3950::GRS1::ElementData::ElementNotThere
  Net::Z3950::GRS1::ElementData::ElementEmpty
  Net::Z3950::GRS1::ElementData::NoDataRequested
  Net::Z3950::GRS1::ElementData::Diagnostic
  Net::Z3950::GRS1::ElementData::Subtree		<---

Only the '<---' marked types are so far supported in this package.

=head1 AUTHOR

Anders Sønderberg Mortensen <sondberg@indexdata.dk>
Index Data ApS, Copenhagen, Denmark.
2001/03/09

=head1 SEE ALSO

Specification of the GRS-1 standard, for instance in the Z39.50 protocol specification.

=cut
