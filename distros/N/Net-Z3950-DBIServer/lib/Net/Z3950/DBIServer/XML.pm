# $Id: XML.pm,v 1.26 2009-03-05 17:20:16 mike Exp $

package Net::Z3950::DBIServer::XML;
use strict;

=head1 NAME

Net::Z3950::DBIServer::XML - build XML records for DBIServer

=head1 SYNOPSIS

	$rec = Net::Z3950::DBIServer::XML::format(
		{ title=>'Mr', forename=>'Eric', surname=>'1/2 Bee' },
		$config);

=head1 DESCRIPTION

This non-OO module exists only to provide a single function which
formats a set of fields as an XML record.

=head1 METHODS

=head2 format()

	$rec = Net::Z3950::DBIServer::XML::format($hashref, $config);

Creates and returns, as an unblessed string, a new XML record
containing the specified fields according to the configuration
specified in the database-and-record-syntax-specific configuration
segment I<$config>, of type C<Net::Z3950::DBIServer::Config::XMLSpec>.

=cut

### Should we use a proper XML-writing module from CPAN?
sub format {
    my($hashref, $config) = @_;

    my $type = $config->recordName();
    my $attrs = $config->recordAttrs();
    my $schema = $config->recordSchema();
    if (defined $attrs) {
	$attrs = " $attrs";
    } else {
	$attrs = "";
    }
    my $rec = '';
    foreach my $field ($config->fields()) {
	my $fieldName = $field->tagname();
	my $sqlField = $field->columnName();
	my $data = make_data($sqlField, $hashref);
	next if !defined $data || $data eq "";
	$rec .= " <$fieldName>" . _quote($data) . "</$fieldName>\n";
    }

    return (_maybe_transform($config, "<$type$attrs>\n$rec</$type>\n"), $schema);
}


# SHARED with ...::MARC.pm and ...::GRS1.pm
sub make_data {
    my($spec, $hashref) = @_;

    if ($spec =~ s/^\*//) {
	return $spec;
    }

    if ($spec !~ /%/) {
	my $allow_skip = ($spec =~ s/^\?//);
	my $data = $hashref->{$spec};
	if (defined $data) {
	    return $data;
	} else {
	    if (0 && !$allow_skip) {
		warn("Looking for field '$spec' but all we have is:\n" .
		     join("\n", map { my $v = $hashref->{$_};
				defined $v ? "\t$_ -> '$v'" : "\t$_ undefined" }
			  sort keys %$hashref));
		die new Net::Z3950::DBIServer::Exception(100,
		    "misconfiguration: top-level field '$spec' not defined");
	    }
	    return undef;
	}
    }

    my $res = "";
    while ($spec =~ s/(.*?)%\{(.*?)\}//s) {
	my($prefix, $fieldname) = ($1, $2);
	my $allow_skip = ($fieldname =~ s/^\?//);
	my $data = $hashref->{$fieldname};
	if (defined $data) {
	    $res .= $prefix . $data;
	} else {
	    die new Net::Z3950::DBIServer::Exception(100,
		"misconfiguration: embedded field '$fieldname' not defined")
		if !$allow_skip;
	}
    }

    return $res . $spec;
}


# PRIVATE to format()
sub _quote {
    my($s) = @_;

    return '' if !defined $s;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;

    return $s
}


# PRIVATE to format()
sub _maybe_transform {
    my($config, $text) = @_;

    my $xslFile = $config->recordTransform();
    return $text if !defined $xslFile;

    eval {
	# Don't require these until we need them; that way,
	# applications that don't need XSL transformations don't
	# require their developers to install all the supportXML stuff.
	require XML::LibXML;
	require XML::LibXSLT;
    }; if ($@) {
	# System error in presenting records
	die new Net::Z3950::DBIServer::Exception(14, <<__EOT__
Oops.  It looks like this zSQLgate installation doesn't have XSL
support.  Contact the server providers and let them know!  They'll
find what they need at http://sql.z3950.org/xslt

$@
__EOT__
);
    }

    my $parser = new XML::LibXML();
    my $xslt = new XML::LibXSLT();

    my($doc, $style_doc);
    eval {
	#warn "about to parse result document";
	$doc = $parser->parse_string($text);
	#warn "about to parse stylesheet document";
	$style_doc = $parser->parse_file($xslFile);
	#warn "parsed both documents";
    }; if ($@) {
	die new Net::Z3950::DBIServer::Exception(14, $@);
    }

    #warn "about to compile stylesheet";
    my $stylesheet;
    eval {
	$stylesheet = $xslt->parse_stylesheet($style_doc);
    }; if ($@) {
	# By inspection of the XML/LibXSLT.pm code, it looks like this
	# function can never call die(), despite what the manual says
	# unless the underlying XS code, _parse_stylesheet() somehow
	# apes it.  Which is a shame for us, but then nearly all XSLT
	# errors are caught by the earlier call to parse_file()
	# anyway.  However, parse_stylesheet() _does_ emit some
	# warning messages on stderr, and there doesn't, seem to be a
	# sensible way to catch them.  Things like:
	#	compilation error: file default.xsl element value-of
	#	xsltParseStylesheetTop: ignoring unknown value-of element
	#	compilation error: file default.xsl element text
	#	misplaced text element: 'x'
	# Best just to keep an eye on zSQLgate's error-log, then.
	warn "Aha!  And I thought parse_stylesheet() could never die!  $@";
	die new Net::Z3950::DBIServer::Exception(14, $@);
    } elsif (!defined $stylesheet) {
	# Again, error messages are produced on standard error,
	# e.g. "document is not a stylesheet", but there is no
	# sensible way to catch them.
	die new Net::Z3950::DBIServer::Exception(14,
		"Document may be well-formed XML that is not a stylesheet?");
    }

    #warn "about to transform";
    my $result;
    eval {
	$result = $stylesheet->transform($doc);
    }; if ($@) {
	# I've not been able to find an error that provokes
	# $stylesheet->transform() die, and by brief reading of
	# LibXSLT.xs suggests that only incorrect invocation (e.g. an
	# odd number of additional parameters) will do so.  But this
	# handler is here out of paranoia.
	warn "Aha!  And I thought transform() could never die!  $@";
	die new Net::Z3950::DBIServer::Exception(14, $@);
    }

    #warn "done transform: returning";
    return $stylesheet->output_string($result);
}


=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

First version Sunday 24th February 2002.

=head1 SEE ALSO

C<Net::Z3950::DBIServer>
is the module that uses this.

=cut


1;
