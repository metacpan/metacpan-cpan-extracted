package Search::Z3950::ResultSet;

use strict;

use MARC::Record;

sub new {
    my ($cls, $zrs) = @_;
    bless { 'zrs' => $zrs }, $cls;
}

sub count    { shift->zrs->size        }
sub prefetch { shift->zrs->present(@_) }
sub errcode  { shift->zrs->errcode(@_) }
sub errmsg   { shift->zrs->errmsg(@_)  }
sub addinfo  { shift->zrs->addinfo(@_) }
sub option   { shift->zrs->option(@_)  }

sub record {
	my ($self, $i) = @_;
	die "Invalid record number ($i)"
	    unless defined $i and $i =~ /^\d+$/;
	die "Record numbers begin with 1, not 0"
	    if $i == 0;
	die "Record number ($i) is greater than the number of matches"
	    unless $i <= $self->count;
	my $zrs = $self->zrs;
	my $rec = $zrs->record($i);
	unless (defined $rec) {
	    die sprintf(<<'EOS', $i, $zrs->errcode, $zrs->errmsg, $zrs->addinfo);
Matching record (%s) couldn't be retrieved:
  error code:    %s
  error message: %s
  add'l info:    %s
EOS
	}
	return MARC::Record->new_from_usmarc($rec->rawdata)
	    if UNIVERSAL::isa($rec, 'Net::Z3950::Record::USMARC');
	return $rec;
}

# --- Get or set the underlying Net::Z3950::ResultSet object
sub zrs { scalar(@_) > 1 ? $_[0]->{'zrs'} = $_[1] : $_[0]->{'zrs'} }


1;


=head1 NAME

Search::Z3950::ResultSet - Z39.50 search results

=head1 SYNOPSIS

    $n = $rs->count;
    $rs->prefetch(1, $n) if $n > 0 and $n <= 20;
    foreach my $i (1..$n) {
        my $rec = $rs->record($i);
        if ($rec->isa('MARC::Record')) {
            my $title = $rec->title;
            my $author = $rec->author;
            ...
        }
        ...
    }

=head1 DESCRIPTION

L<Search::Z3950::ResultSet|Search::Z3950::ResultSet> provides access to the
records found in a search using L<Search::Z3950|Search::Z3950>.

=head1 PUBLIC METHODS

=head2 new

    $rs = Search::Z3950::ResultSet->new($zrs);

Construct a new L<Search::Z3950::ResultSet|Search::Z3950::ResultSet>.  The
single parameter is the Z39.50 result set (an instance of
L<Net::Z3950::ResultSet|Net::Z3950::ResultSet>).

This method should normally be called only by L<Search::Z3950|Search::Z3950>.

=head2 count

    $n = $rs->count;

The number of matching records.

=head2 record

    $rec = $rs->record($i);

Retrieve a matching record.  This will be a L<MARC::Record|MARC::Record>
when possible (i.e., when the underlying object returned by
L<Net::3950::ResultSet|Net::3950::ResultSet> C<isa>
L<Net::3950::Record::USMARC|Net::3950::Record::USMARC>); otherwise,
it will be an instance of a class in the
L<Net::3950::Record|Net::3950::Record> hierarchy.

The single parameter is the record number, which starts at 1 (not zero).

C<record> throws an error if the record couldn't be fetched (e.g.,
if the server connection has just been lost).

B<NOTE:> the record numbers start at 1.

Did I mention that the record numbers start at 1?

=head2 prefetch

    $rs->prefetch($i, $n);

Pre-fetch records C<$i> to C<$i+$n-1> (inclusive) from the
Z39.50 server.  Call this method (before calling C<record>)
to reduce the number of record requests sent over the network
to the server.

(If you're only interested in the first matching record, it
probably makes no difference whether you call C<prefetch> or not.)

Returns a true value if the record(s) were successfully
retrieved, or a false value otherwise.  The retrieved records are
B<not> returned.

(As currently implemented, this method simply invokes the C<present>
method on the Search::Z3950 object's L<Net::Z3950|Net::Z3950> object.)

=head1 PRIVATE METHODS

These methods are for the internal use of C<Search::Z3950::ResultSet>
(and its subclasses, if any).

=head2 zrs

    $zrs = $rs->zrs;
    $rs->zrs($zrs);

Get or set the Z39.50 result set (an instance of
L<Net::Z3950::ResultSet|Net::Z3950::ResultSet>).

=head1 BUGS

None that I know of.  You might check L<http://rt.cpan.org> to
see if others have reported any bugs.

=head1 TO DO

=over 4

=item *

Allow user to specify whether errors should be thrown.

=item *

Instead of relying on the undocumented C<prefetch> option in
L<Net::Z3950|Net::Z3950>, use C<prefetch> behind the scenes
to speed up 

=item *

Optionally return raw data?  Probably not needed.

=item *

Add C<records> method to retrieve all records at once?
Probably not needed.

=item *

Generally, make Search::Z3950 taste less Z39.50-ish (without eliminating
its expressiveness).

=back

=head1 SEE ALSO

L<Search::Z3950|Search::Z3950>, L<Net::Z3950::ResultSet|Net::Z3950::ResultSet>,
L<MARC::Record|MARC::Record>.

=head1 AUTHOR

Paul Hoffman <nkuitse AT cpan DOT org>

=head1 COPYRIGHT

Copyright 2003-2004 Paul M. Hoffman. All rights reserved.

This program is free software; you can redistribute it
and modify it under the same terms as Perl itself. 
