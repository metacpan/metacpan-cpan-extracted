# $Id: MARC.pm,v 1.5 2005-04-11 18:48:20 mike Exp $

package Net::Z3950::DBIServer::MARC;
use MARC::Record;
use strict;

=head1 NAME

Net::Z3950::DBIServer::MARC - build MARC records for DBIServer

=head1 SYNOPSIS

	$rec = Net::Z3950::DBIServer::MARC::format(
		{ title=>'Mr', forename=>'Eric', surname=>'1/2 Bee' },
		$config);

=head1 DESCRIPTION

This non-OO module exists only to provide a single function which
formats a set of fields as a MARC record.

=head1 METHODS

=head2 format()

	$rec = Net::Z3950::DBIServer::MARC::format($hashref, $config);

Creates and returns, as an unblessed string, a new MARC record
containing the specified fields according to the configuration
specified in the database-and-record-syntax-specific configuration
segment I<$config>, of type C<Net::Z3950::DBIServer::Config::XMLSpec>.

=cut

sub format {
    my($hashref, $config) = @_;

    my @fields;			# List of fields, in the order
				# specified in the configuration.
    my %current;		# Maps tags to references into @fields
    foreach my $field ($config->fields()) {
	my $sqlField = $field->columnName();
	my $data = Net::Z3950::DBIServer::XML::make_data($sqlField, $hashref);
	next if !defined $data || $data eq "";

	my($tag, $i1, $i2, $subtag) = ($field->tagname(), "", "");
	if ($tag =~ s/\$(.*)//) {
	    $subtag = $1;
	}
	if ($tag =~ s/\/(.*)//) {
	    $i1 = $1;
	    if ($i1 =~ s/\/(.*)//) {
		$i2 = $1;
	    }
	}

	if ($tag =~ /^00/) {
	    # Control fields (no subfields or indicators involved)
	    push @fields, MARC::Field->new($tag, $data);
	    next;
	}

	if (!defined $current{$tag} ||
	    defined $current{$tag}->subfield($subtag)) {
	    # Either it's the first time we've has data for this
	    # field, or we've already created this subfield within the
	    # specified field, so we need to create a new field with
	    # the same tag to hold the new subfield.
	    #print "*** creating new field '$tag' with '$subtag'='$data'\n";
	    my $marcfield = MARC::Field->new($tag, $i1, $i2, $subtag => $data);
	    push @fields, $marcfield;
	    $current{$tag} = $marcfield;
	} else {
	    # The already have this field, but the subfield is new within it.
	    #print "*** adding subfield '$subtag' to '$tag': ='$data'\n";
	    $current{$tag}->add_subfields($subtag => $data);
	}
    }

    my $rec = new MARC::Record();
    my $leader = $config->recordName();
    $rec->leader($leader) if defined $leader;
    $rec->append_fields(@fields);

    return $rec->as_usmarc();
}


=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

First version Thursdat 11th November 2004.

=head1 SEE ALSO

C<Net::Z3950::DBIServer>
is the module that uses this.

=cut


1;
