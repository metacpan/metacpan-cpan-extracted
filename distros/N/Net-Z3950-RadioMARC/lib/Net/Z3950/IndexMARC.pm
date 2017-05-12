# $Id: IndexMARC.pm,v 1.19 2005/04/27 10:41:14 mike Exp $

package Net::Z3950::IndexMARC;

use 5.008;
use strict;
use warnings;

use MARC::Record;
use Net::Z3950::PQF 0.03;


=head1 NAME

Net::Z3950::IndexMARC - Comprehensive but inefficent index for MARC records

=head1 SYNOPSIS

 $file = MARC::File::USMARC->in($filename);
 $index = new Net::Z3950::IndexMARC();
 while ($marc = $file->next()) {
     $index->add($marc);
 }
 $index->dump(\*STDOUT);
 $hashref = $index->find('@attr 1=4 dinosaur');
 foreach $i (keys %$hashref) {
    $rec = $index->fetch($i);
    print $rec->as_formatted();
 }

=head1 DESCRIPTION

This module provides a comprehensive inverted index across a set of
MARC records, allowing simple keyword retrieval down to the level of
individual field and subfields.  However, it does this by building a
big Perl data-structure (hash of hashes of arrays) in memory, and
makes no efforts whatsoever towards optimisation.  So this is only
appropriate for small collections of records.

=head1 METHODS

=cut


=head2 new()

 $index = new Net::Z3950::IndexMARC();

Creates a new IndexMARC object.  Takes no parameters, and returns the
new object.

=cut

sub new {
    my $class = shift();

    return bless {
	records => [],
	index => {},		# maps queryable terms into records[]
	pqf => undef,		# PQF parser, created on demand
    }, $class;
}


=head2 add()

 $record = new MARC::Record();
 $record->append_fields(...);
 $index->add($record);

Adds a single MARC record to the specified index.  A reference to the
record itself is also added, so the record object will not be garbage
collected until (at least) the index goes out of scope.  The record
passed in must be of the type MARC::Record.

An opaque token representing the new record is returned.  This may
subsequently be passed to C<fetch()> to retrieve the record.

=cut

sub add {
    my $this = shift();
    my($marc) = @_;

    my $reccount = @{ $this->{records} };
    push @{ $this->{records} }, $marc;
    my $index = $this->{index};

    foreach my $field ($marc->fields()) {
	my $tag = $field->tag();
	if ($tag < "010") {
	    # Control fields must be handled separately, or ignored
	    next;
	}

	my @subfields = $field->subfields();
	foreach my $ref (@subfields) {
	    my($subtag, $value) = @$ref;

	    ### We might consider a more sophisticated word-parsing scheme
	    my @words = (lc($value)); # the whole field is word zero
	    $value =~ s/^\s+//;
	    push @words, split(/[\s,\.:\/]+/, $value);

	    for (my $pos = 0; $pos < @words; $pos++) {
		my $word = $words[$pos];
		my $indexentry = [ $tag, $subtag, $pos ];

		$word = lc($word); # case-insensitive indexing
		my $wordref = $index->{$word};
		if (!defined $wordref) {
		    # It's the first we've seen this word in any record
		    $index->{$word} = { $reccount => [ $indexentry ] };
		    next;
		}

		my $recref = $wordref->{$reccount};
		if (!defined $recref) {
		    # First time we've seen the word in this record
		    $wordref->{$reccount} = [ $indexentry ];
		    next;
		}

		# Second or subsequent occurrence of word in record
		push @$recref, $indexentry;
	    }
	}
    }

    return $reccount;
}


=head2 dump()

 $index->dump(\*STDOUT);

Dumps the contents of the specified index to the specified
stream in human-readable form.  Takes no arguments.  Should only be
used for debugging.

=cut

sub dump {
    my $this = shift();
    my($stream) = @_;

    my $index = $this->{index};
    foreach my $word (sort keys %$index) {
	my $wordref = $index->{$word};
	my $gotWord = 0;
	foreach my $reccount (sort { $a <=> $b } keys %$wordref) {
	    print $stream sprintf("%-30s", $gotWord++ ? "" : "'$word'");
	    my $recref = $wordref->{$reccount};
	    my $gotRec = 0;
	    foreach my $indexentry (@$recref) {
		print $stream sprintf("%-8s",
				      $gotRec++ ? " " x 38 : "rec $reccount");
		my($tag, $subtag, $pos) = @$indexentry;
		print $stream "$tag\$$subtag word $pos\n";
	    }
	}
    }
}


=head2 find()

 $hithash = $index->find("@and fruit fish");

Finds records satisfying the specified PQF query, and returns a
reference to a hash consisting of one element for each matching
record.

Each key in the returned hash is an opaque token representing a
record, which may be fed to C<fetch()> to retrieve the record itself.
The corresponding value contains details of the hits in that record.
The hit details consist of an array of arbitrary length, one element
per occurrence of the searched-for term.  Each element of this array
is itself an array of three elements: the tag of the field in which
the term exists [0], the tag of the subfield [2], and the word-number
within the field, starting from word 1 [3].

PQF is Prefix Query Format, as described in the ``Tools'' section of
the YAZ manual; however, this module does not perform field-specific
searching since to do so would necessarily involve a mapping between
Type-1 query access points and MARC fields, which we want to avoid
having to assume anything about.  Accordingly, use attributes are
ignored.  Further, at present boolean operations are also refused, and
only the single-term queries are supported.

=cut

sub find {
    my $this = shift();
    my($pqf) = @_;

    return { 0 => [] } if @{$this->{records}} == 1;

    $this->{pqf} = new Net::Z3950::PQF()
	if !defined $this->{pqf};

    my $parser = $this->{pqf};
    my $node = $parser->parse($pqf);
    ### Should have a nicer way to report this error
    die "Can't parse PQF '$pqf': " . $parser->errmsg()
	if !defined $node;

    return $this->_find($node);
}


sub _find {
    my $this = shift();
    my($node) = @_;

    if ($node->isa("Net::Z3950::PQF::TermNode")) {
	return $this->_find_term($node);
    } if ($node->isa("Net::Z3950::PQF::BooleanNode")) {
	return $this->_find_boolean($node);
    } else {
	die "unsupported node type $node";
    }
}


sub _find_term {
    my $this = shift();
    my($term) = @_;

    ### This is a very clumsy way to handle truncation etc.
    my $rs = {};
    my $index = $this->{index};
    foreach my $key (keys %$index) {
	my $hits = $index->{$key};
	if ($this->_match($term, $key, $hits)) {
	    foreach my $recnum (keys %$hits) {
		push @{ $rs->{$recnum} }, @{ $hits->{$recnum} };
	    }
	}
    }

    return $rs;
}


sub _match {
    my $this = shift();
    my($term, $key, $hits) = @_;

    my($trunc, $comp);
    foreach my $attr (@{ $term->{attrs} }) {
	my($set, $type, $val) = @$attr;
	# In BIB-1, type 5 is truncation and 6 is completeness
	$trunc = $val if $type == 5;
	$comp = $val if $type == 6;
    }

    my $value = lc($term->{value});
    if (defined $comp && ($comp == 2 || $comp == 3)) {
	# Complete subfield or field
	use Data::Dumper;
	#print "*whole-field match against '$value': key='$key', hits=", Dumper($hits);
    }

    my $vlen = length($value);
    if (!defined $trunc || $trunc == 100) {
	# No truncation
	return $value eq $key;
    } elsif ($trunc == 1) {
	# Right truncation
	#print "*testing '$value*' against '$key'\n";
	return $value eq substr($key, 0, $vlen);
    } elsif ($trunc == 2) {
	# Left truncation
	#print "*testing '*$value' against '$key'\n";
	return $value eq substr($key, -$vlen, $vlen);
    } elsif ($trunc == 3) {
	# Left and right truncation ... sigh
	my $klen = length($key);
	#print "*testing '*$value*' against '$key'; vlen=$vlen, klen=$klen\n";
	for (my $i = 0; $i <= $klen-$vlen; $i++) {
	    #print " *comparing '$value' to '", substr($key, $i, $vlen), "'\n";
	    return 1 if $value eq substr($key, $i, $vlen);
	}
	return 0;
    }

    die "unsupported truncation value $trunc";
}


sub _find_boolean {
    my $this = shift();
    my($node) = @_;

    my @subres = map { $this->_find($_) } @{ $node->{sub} };
    my($s1, $s2) = @subres;
    my $final = {};

    if ($node->isa("Net::Z3950::PQF::AndNode")) {
	foreach my $key (keys %$s1) {
	    if (defined $s2->{$key}) {
		$final->{$key} = $this->_merge_info($s1->{$key}, $s2->{$key});
	    }
	}

    } elsif ($node->isa("Net::Z3950::PQF::OrNode")) {
	my %c2 = %$s2;
	foreach my $key (keys %$s1) {
	    if (defined $c2{$key}) {
		$final->{$key} = $this->_merge_info($s1->{$key}, $c2{$key});
		delete $c2{$key};
	    } else {
		$final->{$key} = $s1->{$key};
	    }
	}
	foreach my $key (keys %c2) {
	    $final->{$key} = $c2{$key};
	}

    } elsif ($node->isa("Net::Z3950::PQF::NotNode")) {
	foreach my $key (keys %$s1) {
	    if (!defined $s2->{$key}) {
		$final->{$key} = $s1->{$key};
	    }
	}

    } else {
	die "Unknown boolean node-type: $node";
    }

    return $final;
}


sub _merge_info {
    my $this = shift();
    my($info1, $info2) = @_;

    if (0) {
	use Data::Dumper;
	print("_merge_info: ",
	      "info1=", Dumper($info1),
	      "info2=", Dumper($info2),
	      "\n");
    }

    ### Should do much, much better!
    return 1;
}


=head2 fetch()

 $marc = $index->fetch($token);

Returns the MARC::Record object corresponding to the specified record
token, as returned from C<add()> or C<find()>.

=cut

sub fetch {
    my $this = shift();
    my($num) = @_;

    my $records = $this->{records};
    my $count = scalar(@$records);
    die "record number $num out of range 0.." . ($count-1)
	if $num < 0 || $num >= $count;
    return $records->[$num];
}


=head1 PROVENANCE

This module is part of the Net::Z3950::RadioMARC distribution.  The
copyright, authorship and licence are all as for the distribution.

=cut


1;
