package Net::Z3950::UDDI::Database::soap;
our @ISA = qw(Net::Z3950::UDDI::Database);
use strict;
use warnings;

sub _on_fault_die {
    my($soap, $som) = @_;

    my $msg = ref $som ? $som->faultstring : $soap->transport->status;
    # We have no UDDI or Database object to invoke _throw() on, so we
    # have to use the fully-qualified function-call form.
    Net::Z3950::UDDI::_throw(100, "SOAP error: $msg");
}

sub _on_fault_warn {
    my($soap, $som) = @_;

    warn ref $som ? $som->faultstring : $soap->transport->status;
}

use SOAP::Lite on_fault => \&_on_fault_die;


sub rebless {
    my $class = shift();
    my($this) = @_;

    my $soap = new SOAP::Lite;
    foreach my $property (qw(service proxy uri)) {
	my $val = $this->config()->property("$property");
	$soap->$property($val) if defined $val;
    }

    my $params = $this->config()->{params};
    my $soap_fault = $params->property("soap-fault");
    if (defined $soap_fault) {
	#warn "soap_fault='$soap_fault'";
	if ($soap_fault eq "die") {
	    $soap->on_fault(\&_on_fault_die);
	} elsif ($soap_fault eq "warn") {
	    $soap->on_fault(\&_on_fault_warn);
	} elsif ($soap_fault eq "ignore") {
	    $soap->on_fault(undef);
	} else {
	    $this->_throw(1, "unrecognised soap-fault value " .
			  "'$soap_fault' [die|warn|ignore]");
	}
    }

    my $soap_debug = $params->property("soap-debug");
    if (defined $soap_debug) {
	#warn "soap_debug='$soap_debug'";
	SOAP::Lite->import(+trace => [ split /[,\s]+/, $soap_debug ]);
    }

    $this->{_soap} = $soap;
    bless $this, $class;
}


sub _soap { shift()->{_soap} }


sub search {
    my $this = shift();
    my($rpn) = @_;

    my $query = $rpn->{query};
    $this->_throw(6, "only single-term queries are supported for now")
	if ref $query ne "Net::Z3950::RPN::Term";

    ### Ignore attribute set for now
    ### Ignore all attributes apart from access point, for now
    my $attrs = $query->{attributes};
    my $ap = undef;
    foreach my $attr (@$attrs) {
	$ap = $attr->{attributeValue} if $attr->{attributeType} == 1;
    }
    $this->_throw(116) if !defined $ap;

    my $map = $this->config()->property("indexmap");
    my $bib1map = $map->{"bib-1"};
    my $method = $bib1map->{$ap};
    $this->_throw(114, $ap) if !defined $method;

    my $term = $query->{term};
    my $som = $this->_soap()->call($method, $term);
    return new Net::Z3950::UDDI::ResultSet::soap($this, $som);
}


package Net::Z3950::UDDI::ResultSet::soap;

use Net::Z3950::UDDI::ResultSet;
our @ISA = qw(Net::Z3950::UDDI::ResultSet);
use strict;
use warnings;

sub new {
    my $class = shift();
    my($db, $som) = @_;

    my $this = $class->SUPER::new($db);
    $this->{som} = $som;
    $this->{count} = undef;
    $this->{records} = [];
    bless $this, $class;

    ### Parse the SOM and extract count and records!

    return $this;
}

sub count {
    my $this = shift();

    return 12345; $this->{count};
}

sub record {
    my $this = shift();
    my($index0) = @_;

    return $this->{records}->[$index0];
}


1;
