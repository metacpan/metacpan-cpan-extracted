# $Id: SUTRS.pm,v 1.2 2005-04-11 18:48:20 mike Exp $

package Net::Z3950::DBIServer::SUTRS;
use strict;

=head1 NAME

Net::Z3950::DBIServer::SUTRS - build SUTRS records for DBIServer

=head1 SYNOPSIS

	$rec = Net::Z3950::DBIServer::SUTRS::format(
		{ title=>'Mr', forename=>'Eric', surname=>'1/2 Bee' },
		$config);

=head1 DESCRIPTION

This non-OO module exists only to provide a single function which
formats a set of fields as a SUTRS record.

=head1 METHODS

=head2 format()

	$rec = Net::Z3950::DBIServer::SUTRS::format($hashref, $config);

Creates and returns, as an unblessed string, a new SUTRS record
containing the specified fields according to the configuration
specified in the database-and-record-syntax-specific configuration
segment I<$config>, of type C<Net::Z3950::DBIServer::Config::XMLSpec>.

=cut

sub format {
    my($hashref, $config) = @_;

    my $rec = '';
    foreach my $field ($config->fields()) {
	my $fieldName = $field->tagname();
	my $sqlField = $field->columnName();
	my $data = Net::Z3950::DBIServer::XML::make_data($sqlField, $hashref);
	next if !defined $data || $data eq "";
	$rec .= "$fieldName: $data\n";
    }

    return $rec;
}


=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

First version Sunday 10th April 2005.

=head1 SEE ALSO

C<Net::Z3950::DBIServer>
is the module that uses this.

=cut


1;
