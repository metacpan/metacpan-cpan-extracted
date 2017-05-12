package Net::Z3950::UDDI::Database::uddi;
our @ISA = qw(Net::Z3950::UDDI::Database);
use strict;
use warnings;

use UDDI::HalfDecent;


sub rebless {
    my $class = shift();
    my($this) = @_;

    my $config = $this->config();
    my $endpoint = $config->property("endpoint")
	or $this->_throw(1, "no endpoint specified for UDDI db '" .
			 $this->dbname() . "'");
    my $uddi = new UDDI::HalfDecent($endpoint);

    my $levels = $config->property("log");
    $uddi->loglevel(split /[,\s]+/, $levels)
	if defined $levels;

    my %data = $config->properties();
    foreach my $key (grep /^option-/, keys %data) {
	my $value = $data{$key};
	$key =~ s/^option-//;
	$uddi->option($key, $value);
    }

    $this->{_uddi} = $uddi;
    bless $this, $class;
}


sub search {
    my $this = shift();
    my($rpn) = @_;

    my $query = $rpn->{query};

    my @criteria;
    my $whichop = $this->_gather_criteria($query, \@criteria);

    # Generate, wrap and return the result-set
    my $rs;
    eval {
	if (!defined $whichop || $whichop == 1) {
	    $rs = $this->{_uddi}->find_business(@criteria);
	} elsif ($whichop == 2) {
	    $rs = $this->{_uddi}->find_service(@criteria);
	} elsif ($whichop == 3) {
	    $rs = $this->{_uddi}->find_binding(@criteria);
	} elsif ($whichop == 4) {
	    $rs = $this->{_uddi}->find_tModel(@criteria);
	} else {
	    $this->_throw(1024, "15=$whichop");
	}
    }; if ($@ && ref $@ && $@->isa("UDDIException")) {
	# Translate UDDIException into ZOOM::Exception.  It would be
	# nice if we could do a better job of making BIB-1 diagnostic
	# codes from some known values of $@->error()
	$this->_throw(100, "$@");
    } elsif ($@) {
	die $@;
    }

    return new Net::Z3950::UDDI::ResultSet::uddi($this, $rs);
}


sub _gather_criteria {
    my $this = shift();
    my($query, $cref) = @_;

    if ($query->isa("Net::Z3950::RPN::And")) {
	my $w1 = $this->_gather_criteria($query->[0], $cref);
	my $w2 = $this->_gather_criteria($query->[1], $cref);
	return $w1 || $w2;
    } elsif (!$query->isa("Net::Z3950::RPN::Term")) {
	### We should handle eligible subtrees consisting entirely of OR
	# using a findQualifier to specify the boolean.
	$this->_throw(6, "only AND booleans are supported");
    }

    ### Ignore attribute set for now
    my $attrs = $query->{attributes};
    my $ap = undef;
    my $whichop = undef;
    foreach my $attr (@$attrs) {
	my $type = $attr->{attributeType};
	my $value = $attr->{attributeValue};
	if ($type == 1) {
	    $ap = $value;
	} elsif ($type == 15) {
	    # Zebra defines extensions for types 7-14: see
	    # http://indexdata.com/zebra/doc/querymodel-zebra.tkl#querymodel-zebra-attr-search
	    $whichop = $value;
	} else {
	    ### Ignore all other attributes for now.  Eventually, some
	    # of them should be turned into additional qualifiers and
	    # other search criteria.
	}
    }
    $this->_throw(116) if !defined $ap;

    # For some reason, qualifiers must appear before the name: if not,
    # this is diagnosed by bizarre messages such as:
    #	JAXRPCTIE01: caught exception while handling request:
    #	deserialization error: unexpected XML reader state. expected:
    #	END but found: START: {urn:uddi-org:api_v3}findQualifiers
    # (This is from the GEOSS server.)
    my $qual = $this->config()->property("qualifiers");
    if (defined $qual) {
	push @$cref, qualifiers => [ split /[,\s]+/, $qual ];
    }

    # There is no "indexmap" property in the configuration for UDDI
    # databases, because the horrible UDDI schema requires
    # fundamentally different XML for different access points -- not
    # just differently named elements but differently structured --
    # and so the whole translation into UDDI has to be driven by code.
    my $term = $query->{term};
    if ($ap == 4) {
	# Title
	push @$cref, name => $term;
    } elsif ($ap == 29) {
	# Keywords: see GILS->UDDI crosswalk
	push @$cref, identifierBag => [ split /[\s,]+/, $term ];
    } elsif (grep { $ap eq $_ } (2002, 2074, 2036, 2061)) {
	# Subject and related indexes: again, see the crosswalk
	push @$cref, categoryBag => [ split /[\s,]+/, $term ];
    } elsif ($ap == 6000) {
	# Special UDDI-specific attributes
	push @$cref, businessKey => $term;
    } elsif ($ap == 6001) {
	push @$cref, serviceKey => $term;
    } elsif ($ap == 6002) {
	push @$cref, tModelBag => [ split /[\s,]+/, $term ];
    } else {
	$this->_throw(114, $ap);
    }

    return $whichop;
}


package Net::Z3950::UDDI::ResultSet::uddi;

use Net::Z3950::UDDI::ResultSet;
our @ISA = qw(Net::Z3950::UDDI::ResultSet);
use strict;
use warnings;
use Carp;

sub new {
    my $class = shift();
    my($db, $uddi_rs) = @_;

    confess "no UDDI result-set" if !defined $uddi_rs;
    my $this = $class->SUPER::new($db);
    $this->{uddi_rs} = $uddi_rs;
    bless $this, $class;
    return $this;
}

sub count {
    my $this = shift();

    return $this->{uddi_rs}->count();
}

sub record {
    my $this = shift();
    my($index0) = @_;

    # Generate, wrap and return the result-set
    my $rec;
    eval {
	$rec = $this->{uddi_rs}->record($index0);
    }; if ($@) {
	# Translate UDDIException into ZOOM::Exception.
	$this->_throw(100, "$@");
    }

    ### This currently records an unadorned back-end-specific record
    # object -- in this case, a UDDI::HalfDecent::Record.  In the name
    # of generality, this needs to be wrapped, like back-end-specific
    # result-sets.
    return $rec;
}

sub record_as_xml {
    my $this = shift();
    my($index0) = @_;

    my $rec = $this->record($index0);
    my $xml = $rec->as_xml();

    my $attrs = $this->{db}->config()->property("record-attrs");
    if (defined $attrs) {
	### This substitution is not super-rigorous, but can only fail
	# in the pathological case that the existing XML fragment's
	# top-level element has an attributes whose value contains an
	# embedded ">".  In any case, I'm not sure what else we could
	# do: we can't parse the fragment and insert the new
	# attributes in the resulting DOM, since our inability to
	# parse fragments that are missing required namespaces is the
	# reason we want to fix this up in the first place!
	$xml =~ s/>/ $attrs>/;
    }

    return $xml;
}

1;
