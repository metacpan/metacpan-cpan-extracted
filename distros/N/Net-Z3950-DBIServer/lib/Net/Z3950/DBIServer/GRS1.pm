# $Header: /home/mike/cvs/mike/zSQLgate/lib/Net/Z3950/DBIServer/GRS1.pm,v 1.4 2005-04-11 18:48:20 mike Exp $

package Net::Z3950::DBIServer::GRS1;
use Net::Z3950::GRS1;
use strict;

=head1 NAME

Net::Z3950::DBIServer::GRS1 - build GRS-1 records for DBIServer

=head1 SYNOPSIS

	$rec = Net::Z3950::DBIServer::GRS1::format(
		{ title=>'Mr', forename=>'Eric', surname=>'1/2 Bee' },
		$config);

=head1 DESCRIPTION

This non-OO module exists only to provide a single function which
formats a set of fields as a GRS-1 record.

=head1 METHODS

=head2 format()

	$rec = Net::Z3950::DBIServer::GRS1::format($hashref, $config);

Creates and returns, as an unblessed string, a new GRS-1 record
containing the specified fields according to the configuration
specified in the database-and-record-syntax-specific configuration
segment I<$config>, of type C<Net::Z3950::DBIServer::Config::PerDB>.

Because of the way the underlying C<SimpleServer> module deals with
GRS-1 records, the record is returned as a human-readable string.
That's surprising - at least it surprises me.  But I've had to deal
with it, so I don't see why you shouldn't too.

=cut

sub format {
    my($hashref, $config) = @_;

    my $grs = new Net::Z3950::GRS1();
    foreach my $field ($config->fields()) {
	my $fieldName = $field->tagname();
	my $sqlField = $field->columnName();
	my $data = Net::Z3950::DBIServer::XML::make_data($sqlField, $hashref);
	next if !defined $data || $data eq "";
	my $tagpath = $field->tagpath();
	#{ use Data::Dumper; warn "tagpath($fieldName) = " . Dumper($tagpath) }

	# Actually, our internal record and the SimpleServer module's
	# GRS1 record object are not very good matches: the former
	# does not support sub-records and the latter does not support
	# tag-paths of more than one element.
	# ### We should implement long tag-paths with sub-records.
	my $first = $tagpath->[0];
	warn "ignoring second and subsequent elements of tagpath for '$fieldName'"
	    if @$tagpath > 1;
	$grs->AddElement(@$first, Net::Z3950::GRS1::ElementData::String,
			 $data);
    }

    # For reasons too bizarre to contemplate, we return the GRS-1
    # record rendered as a string, which is then re-parsed in
    # SimpleServer to yield a GRS-1 record in C structs.  Clearly we
    # should have a better arrangement.

    my $res;
    $grs->Render(POOL => \$res);
    #warn "Record is: '$res'";
    return $res;
}


=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

First version Tuesday 9th July 2002.

=head1 SEE ALSO

C<Net::Z3950::DBIServer>
is the module that uses this.

=cut


1;
