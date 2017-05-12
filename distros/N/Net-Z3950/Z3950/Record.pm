# $Header: /home/cvsroot/NetZ3950/Z3950/Record.pm,v 1.14 2004/11/22 22:41:47 mike Exp $

package Net::Z3950::Record;
use strict;


=head1 NAME

Net::Z3950::Record - base class for records retrieved from a Z39.50 server

=head1 SYNOPSIS

	$rs = $conn->resultSet();
	$rec = $rs->record($n);
	print $rec->render();

=head1 DESCRIPTION

A Record object represents a record retrieved from a Z39.50 server.
In fact, the C<Net::Z3950::Record> class itself is never instantiated:
instead, the Net::Z3950 module creates objects of subclasses such as
C<Net::Z3950::Record::SUTRS>, C<Net::Z3950::Record::GRS1>,
C<Net::Z3950::Record::USMARC> and C<Net::Z3950::Record::XML>.
This class defines a common interface which must be supported by all
such subclasses.

=head1 METHODS

=cut


=head2 nfields()

	$count = $rec->nfields();

Returns the number of fields in the record I<$rec>.

=cut

sub nfields {
    return "[can't count fields of a Net::Z3950::Record]\n";
}


=head2 render()

	print $rec->render();

Returns a human-readable string representing the content of the record
I<$rec> in a form appropriate to its specific type.

=cut

sub render {
    return "[can't render a Net::Z3950::Record]\n";
}


=head2 rawdata()

	$raw = $rec->rawdata();

Returns the raw form of the data in the record, which will in general
be different in form for different record syntaxes.

=cut

sub rawdata {
    return "[can't return raw data for a Net::Z3950::Record]\n";
}


#   ###	Should each subclass be implemented in a file of its own?
#	Perhaps that will prove more appropriate as the number of
#	supported record syntaxes, and the number of methods defined
#	for each, increase.  For now, though, it would probably be
#	overkill.

=head1 SUBCLASSES

=cut


=head2 Net::Z3950::Record::SUTRS

Represents a a record using the Simple Unstructured Text Record
Syntax (SUTRS) - a simple flat string containing the record's data in
a form suitable for presentation to humans (so that the C<render()>
and C<rawdata()> methods return the same thing.)

See Appendix REC.2 (Simple Unstructured Text Record Syntax) of the
Z39.50 Standard for more information.

=cut

package Net::Z3950::Record::SUTRS;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::Record);

sub nfields {
    return 1;			# by definition
}

sub render {
    my $this = shift();
    return $$this;
}

sub rawdata {
    my $this = shift();
    return $$this;
}


=head2 Net::Z3950::Record::GRS1

Represents a record using Generic Record Syntax 1 (GRS1) - a list of
tagged fields where each tag is made up of a tag type and tag value,
and each field may be of any type, including numeric, string, and
recursively contained sub-record.  Fields may also be annotated with
metadata, variant information I<etc.>

See Appendix REC.5 (Generic Record Syntax 1) of the Z39.50 Standard
for more information.

=cut

package Net::Z3950::Record::GRS1;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::Record);

sub nfields {
    my $this = shift();
    return scalar @$this;
}

sub render {
    my $this = shift();

    return $this->nfields() . " fields:\n" . $this->_render1(0);
}

# PRIVATE to the render() method
sub _render1 {
    my $this = shift();
    my($level) = @_;

    my $res = '';
    for (my $i = 0; $i < $this->nfields(); $i++) {
	my $fld = $this->[$i];
	{
	    my $type = 'Net::Z3950::APDU::TaggedElement';
	    if (!$fld->isa($type)) {
		die "expected $type, got " . ref($fld);
	    }
	}
	$res .= '    ' x $level;
	$res .= "(" . $fld->tagType() . "," . $fld->tagValue() . ")";
	my $occurrence = $fld->tagOccurrence();
	$res .= "[" . $occurrence . "]" if defined $occurrence;
	$res .= " " . _render_content($level, $fld->content());
    }

    return $res;
}

# PRIVATE to the _render1() method
sub _render_content {
    my($level, $val) = @_;

    my $which = $val->which();
    if ($which == Net::Z3950::ElementData::Numeric) {
	return $val->numeric() . "\n";
    } elsif ($which == Net::Z3950::ElementData::String) {
	return '"' . $val->string() . '"' . "\n";
    } elsif ($which == Net::Z3950::ElementData::OID) {
	return $val->oid() . "\n";
    } elsif ($which == Net::Z3950::ElementData::Subtree) {
	#   ###	This re-blessing is an ugly way to cope with $val
	#	being The Wrong Kind Of GRS1 Object, since it has the
	#	naughty (if not particularly malignant) side-effect of
	#	permanently changing the type of a part of the tree.
	my $sub = $val->subtree();
	bless $sub, 'Net::Z3950::Record::GRS1';
	return "{\n" . $sub->_render1($level+1) . '    ' x $level . "}\n";
    } else {
	use Data::Dumper;
	die "unknown ElementData which $which in data " . Dumper($val);
    }
}

sub rawdata {
    my $this = shift();
    return $this;		# just return the structure itself.
}


=head2 Net::Z3950::Record::USMARC, Net::Z3950::Record::UKMARC, Net::Z3950::Record::NORMARC, Net::Z3950::Record::LIBRISMARC, Net::Z3950::Record::DANMARC, Net::Z3950::Record::UNIMARC

Represents a record using the appropriate MARC (MAchine Readable
Catalogue) format - binary formats used extensively in libraries.

For further information on the MARC formats, see the Library of
Congress Network Development and MARC Standards Office web page at
http://lcweb.loc.gov/marc/ and the MARC module in Ed Summers's
directory at CPAN,
http://cpan.valueclick.com/authors/id/E/ES/ESUMMERS/

=cut

package Net::Z3950::Record::USMARC;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::Record);

sub nfields {
    return 1;			# This is not really true - a record
				# is made up of several fields, but
				# here we perpetrate the illusion of a
				# single flat block, so that it can
				# easily be fed to external MARC-aware
				# software.
}

# Thanks to Dave Burgess <burgess@mitre.org> for supplying this code.
# We pull in the MARC module with "require" rather than "use" so that
# there's no dependency for non-MARC clients.
#
sub render {
    my $this = shift();

    require MARC::Record;
    my $rec = MARC::Record->new_from_usmarc($this->rawdata());
    return $rec->as_formatted();
}

sub rawdata {
    my $this = shift();
    return $$this;		# Return the whole record ``as is''.
}


package Net::Z3950::Record::UKMARC;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::Record);
sub nfields { return 1 }
sub rawdata { return ${ shift() } }

package Net::Z3950::Record::NORMARC;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::Record);
sub nfields { return 1 }
sub rawdata { return ${ shift() } }

package Net::Z3950::Record::LIBRISMARC;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::Record);
sub nfields { return 1 }
sub rawdata { return ${ shift() } }

package Net::Z3950::Record::DANMARC;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::Record);
sub nfields { return 1 }
sub rawdata { return ${ shift() } }

package Net::Z3950::Record::UNIMARC;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::Record);
sub nfields { return 1 }
sub rawdata { return ${ shift() } }


=head2 Net::Z3950::Record::XML

Represents a a record using XML (Extended Markup Language), as defined
by the W3C.  Rendering is not currently defined: this module treats
the record as a single opaque lump of data, to be parsed by other
software.

For more information about XML, see http://www.w3.org/XML/

=cut

package Net::Z3950::Record::XML;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::Record);

sub nfields {
    return 1;			### not entirely true
}

sub render {
    my $this = shift();
    return $$this;
}

sub rawdata {
    my $this = shift();
    return $$this;
}


=head2 Net::Z3950::Record::HTML

Represents a a record using HTML (HyperText Markup Language), as
defined by the W3C.  Rendering is not currently defined: this module
treats the record as a single opaque lump of data, to be handled by
other software.

For more information about HTML, see http://www.w3.org/MarkUp/

=cut

package Net::Z3950::Record::HTML;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::Record);

sub nfields {
    return 1;			### not entirely true
}

sub render {
    return "[can't render a Net::Z3950::Record::HTML - not yet implemented]\n";
}

sub rawdata {
    my $this = shift();
    return $$this;
}


=head2 Net::Z3950::Record::OPAC

Represents a a record using the OPAC (Online Public Access Catalogue)
record syntax, as defined in Appendix 5 (REC) of the Z39.50 standard
at http://lcweb.loc.gov/z3950/agency/asn1.html#RecordSyntax-opac

=cut

package Net::Z3950::Record::OPAC;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::Record);

sub nfields {
    return 1;			### not entirely true
}

sub render {
    my $this = shift();

    my $res;
    my $bib = $this->{bibliographicRecord};
    if (defined $bib) {
	$res = "* Bibliographic record:\n";
	$res .= $bib->render();
    } else {
	$res = "[no bibliographic record]\n";
    }

    my $n = $this->{num_holdingsData};
    my $h = $this->{holdingsData};
    foreach my $i (1 .. $n) {
	my $hr = $h->[$i-1];
	$res .= "* Holdings record $i of $n:\n";
	foreach my $label (qw(typeOfRecord encodingLevel format
			      receiptAcqStatus generalRetention
			      completeness dateOfReport nucCode
			      localLocation shelvingLocation
			      callNumber shelvingData copyNumber
			      publicNote reproductionNote
			      termsUseRepro enumAndChron)) {
	    $res .= _maybeValue(1, $hr, $label);
	}
	
	my $cd = $hr->{circulationData};
	my $n = @$cd;
	foreach my $i (1 .. $n) {
	    my $cr = $cd->[$i-1];
	    $res .= "\t* Circulation record $i of $n:\n";
	    foreach my $label (qw(availableNow availablityDate
				  availableThru restrictions itemId
				  renewable onHold enumAndChron
				  midspine temporaryLocation)) {
		$res .= _maybeValue(2, $cr, $label);
	    }
	}

	my $vols = $hr->{volumes};
	$n = @$vols;
	foreach my $i (1 .. $n) {
	    my $vol = $vols->[$i-1];
	    $res .= "\t* Volume record $i of $n:\n";
	    foreach my $label (qw(enumeration chronology
				  enumAndChron)) {
		$res .= _maybeValue(2, $vol, $label);
	    }
	}
    }

    return $res;
}

sub _maybeValue {
    my($level, $hr, $label) = @_;

    my $val =  $hr->{$label};
    return defined $val ? ("\t" x $level . "$label: $val\n") : "";
}

sub rawdata {
    my $this = shift();
    return $this;
}


=head2 Net::Z3950::Record::MAB

Represents a record using the MAB record syntax (Maschinelles
Austauschformat fuer Bibliotheken, ftp://ftp.ddb.de/pub/mab/); an
interchange format defined by Die Deutsche Bibliothek (German National
Library).

=cut

package Net::Z3950::Record::MAB;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::Record);

sub nfields {
    my $this = shift();
    return $$this =~ tr/\x1E/\x1E/;
}

sub render {
    my $this = shift();
    my $in = $$this;

    # Chop off 24-character preface
    my $out = "### " . substr($in, 0, 24) . "\n";
    $in = substr($in, 24);

    # \x1D is the record separator: discard it
    $in =~ s/\x1D$//;

    # \x1E is the field separator
    my @fields = split /\x1E/, $in;

    foreach my $field (@fields) {
	# If a database uses two $ instead of the correct subfield
	# separator code \x1F we reset this.
	$field =~ s/\$\$/\x1F/g;
	$field =~ s/\x1F/\$/g;
	$out .= "$field\n";
    }

    return $out;
}

sub rawdata {
    my $this = shift();
    return $$this;
}


=head2 ### others, not yet supported

=cut


=head1 AUTHOR

Mike Taylor E<lt>mike@indexdata.comE<gt>

First version Sunday 4th May 2000.

=cut

1;
