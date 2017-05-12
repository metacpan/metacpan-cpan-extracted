# $Id: PQF.pm,v 1.8 2007/10/05 12:12:34 mike Exp $

package Net::Z3950::PQF;

use 5.006;
use strict;
use warnings;

use Net::Z3950::PQF::Node;

our $VERSION = '0.04';


=head1 NAME

Net::Z3950::PQF - Perl extension for parsing PQF (Prefix Query Format)

=head1 SYNOPSIS

 use Net::Z3950::PQF;
 $parser = new Net::Z3950::PQF();
 $node = $parser->parse('@and @attr 1=1003 kernighan @attr 1=4 unix');
 print $node->render(0);

=head1 DESCRIPTION

This library provides a parser for PQF (Prefix Query Format), an ugly
but precise string format for expressing Z39.50 Type-1 queries.  This
format is widely used behind the scenes of Z39.50 applications, and is
also used extensively with test-harness programs such as the YAZ
command-line client, C<yaz-client>.  A few particularly misguided
souls have been known to type it by hand.

Unlike PQF itself, this module
is simple to use.  Create a parser object, then pass PQF strings
into its C<parse()> method to yield parse-trees.  The trees are made
up of nodes whose types are subclasses of
C<Net::Z3950::PQF::Node>.
and have names of the form
C<Net::Z3950::PQF::somethingNode>.  You may find it helpful to use
C<Data::Dumper> to visualise the structure of the returned
parse-trees.

What is a PQF parse-tree good for?  Not much.  You can render a
human-readable version by invoking the top node's C<render()> method,
which is probably useful only for debugging.  Or you can turn it into
tree of nodes like those passed into SimpleServer search handlers
using C<toSimpleServer()>.  If you want to do anything useful, such as
implementing an actual query server that understands PQF, you'll have
to walk the tree.

=head1 METHODS

=head2 new()

 $parser = new Net::Z3950::PQF();

Creates a new parser object.

=cut

sub new {
    my $class = shift();

    return bless {
	text => undef,
	errmsg => undef,
    }, $class;
}


=head2 parse()

 $query = '@and @attr 1=1003 kernighan @attr 1=4 unix';
 $node = $parser->parse($query);
 if (!defined $node) {
     die "parse($query) failed: " . $parser->errmsg();
 }

Parses the PQF string provided as its argument.  If an error occurs,
then an undefined value is returned, and the error message can be
obtained by calling the C<errmsg()> method.  Otherwise, the top node
of the parse tree is returned.

 $node2 = $parser->parse($query, "zthes");
 $node3 = $parser->parse($query, "1.2.840.10003.3.13");

A second argument may be provided after the query itself.  If it is
provided, then it is taken to be either the name or the OID of a
default attribute set, which attributes specified in the query belong
to if no alternative attribute set is explicitly specified within the
query.  When this second argument is absent, the default attribute set
is BIB-1.

=cut

sub parse {
    my $this = shift();
    my($text, $attrset) = @_;
    $attrset = "bib-1" if !defined $attrset;

    $this->{text} = $text;
    return $this->_parse($attrset, {});
}


# PRIVATE to parse();
#
# Underlying parse function.  $attrset is the default attribute-set to
# use for attributes that are not specified with an explicit set, and
# $attrhash is hash of attributes (at most one per type per
# attribute-set) to be applied to all nodes below this point.  The
# keys of this hash are of the form "<attrset>:<type>" and the values
# are the corresponding attribute values.
#
sub _parse {
    my $this = shift();
    my($attrset, $attrhash) = @_;

    $this->{text} =~ s/^\s+//;

    ###	This rather nasty hack for quoted terms doesn't recognised
    #	backslash-quoted embedded double quotes.
    if ($this->{text} =~ s/^"(.*?)"//) {
	return $this->_leaf('term', $1, $attrhash);
    }

    # Also recognise multi-word terms enclosed in {curly braces}
    if ($this->{text} =~ s/^{(.*?)}//) {
	return $this->_leaf('term', $1, $attrhash);
    }

    my $word = $this->_word();
    if ($word eq '@attrset') {
	$attrset = $this->_word();
	return $this->_parse($attrset, $attrhash);

    } elsif ($word eq '@attr') {
	$word = $this->_word();
	if ($word !~ /=/) {
	    $attrset = $word;
	    $word = $this->_word();
	}
	my($type, $val) = ($word =~ /(.*)=(.*)/);
	my %h = %$attrhash;
	$h{"$attrset:$type"} = $val;
	return $this->_parse($attrset, \%h);

    } elsif ($word eq '@and' || $word eq '@or' || $word eq '@not') {
	my $sub1 = $this->_parse($attrset, $attrhash);
	my $sub2 = $this->_parse($attrset, $attrhash);
	if ($word eq '@and') {
	    return new Net::Z3950::PQF::AndNode($sub1, $sub2);
	} elsif ($word eq '@or') {
	    return new Net::Z3950::PQF::OrNode($sub1, $sub2);
	} elsif ($word eq '@not') {
	    return new Net::Z3950::PQF::NotNode($sub1, $sub2);
	} else {
	    die "Houston, we have a problem";
	}

    } elsif ($word eq '@prox') {
	return $this->_error("proximity not yet implemented");

    } elsif ($word eq '@set') {
	$word = $this->_word();
	return $this->_leaf('rset', $word, $attrhash);
    }

    # It must be a bareword
    return $this->_leaf('term', $word, $attrhash);
}


# PRIVATE to _parse();
sub _word {
    my $this = shift();

    $this->{text} =~ s/^\s+//;
    $this->{text} =~ s/^(\S+)//;
    return $1;
}


# PRIVATE to _parse();
sub _error {
    my $this = shift();
    my (@msg) = @_;

    $this->{errmsg} = join("", @msg);
    return undef;
}


# PRIVATE to _parse();
sub _leaf {
    my $this = shift();
    my($type, $word, $attrhash) = @_;

    my @attrs;
    foreach my $key (sort keys %$attrhash) {
	my($attrset, $type) = split /:/, $key;
	push @attrs, [ $attrset, $type, $attrhash->{$key} ];
    }

    if ($type eq 'term') {
	return new Net::Z3950::PQF::TermNode($word, @attrs);
    } elsif ($type eq 'rset') {
	return new Net::Z3950::PQF::RsetNode($word, @attrs);
    } else {
	die "_leaf() called with type='$type' (should be 'term' or 'rset')";
    }
}


=head2 errmsg()

 print $parser->errmsg();

Returns the last error-message generated by a failed attempt to parse
a query.

=cut

sub errmsg {
    my $this = shift();
    return $this->{errmsg};
}


=head1 SEE ALSO

The C<Net::Z3950::PQF::Node> module.

The definition of the Type-1 query in the Z39.50 standard, the
relevant section of which is on-line at
http://www.loc.gov/z3950/agency/markup/09.html#3.7

The documentation of Prefix Query Format in the YAZ Manual, the
relevant section of which is on-line at
http://indexdata.com/yaz/doc/tools.tkl#PQF

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Index Data ApS.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
