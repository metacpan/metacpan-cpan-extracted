package Net::Z3950::UDDI::ResultSet;
use strict;
use warnings;

=head1 NAME

Net::Z3950::UDDI::ResultSet - back-end independent result-set for z2uddi

=head1 SYNOPSIS

 $rs = new Net::Z3950::UDDI::ResultSet::uddi($db, $uddi_rs); # for example
 $count = $rs->count();
 $record = $rs->record(0);

=head1 DESCRIPTION

A C<Net::Z3950::UDDI::ResultSet> object represents a result-set, the
result of search a backend database of some kind or another, but hides
the details of whether that database is a SOAP service or a UDDI
repostory (or something else again) by presenting a simple, generic
API.

=head1 METHODS

There is no constructor for C<ResultSet>, which is an abstract base
class.  Each subclass has its own constructor, which will be called on
the application's behalf by the C<search()> method of the subclass's
corresponding C<Net::Z3950::UDDI::Database> subclass.

=head2 count()

 $n = $rs->count();

Returns the number of records in the result-set, i.e. the number of
records found by the search that created the result-set.

=head2 record()

 foreach $i (0 .. $n-1) {
     $rec = $rs->record($i);
 }

Returns a single record from the result-set, indexed from zero.

=cut


# Do not call directly: subclasses invoked this as SUPER::new()
sub new {
    my $class = shift();
    my($db) = @_;

    return bless {
	db => $db,
    }, $class;
}


sub db { shift()->{db} }


# Delegate
sub _throw {
    my $this = shift();
    return $this->db()->_throw(@_);
}


=head1 SUBCLASSING

I<###> to be written

=head1 SEE ALSO

C<Net::Z3950::UDDI::Database>
is the module that immediately uses this.

=head1 AUTHOR, COPYRIGHT AND LICENSE

As for C<Net::Z3950::UDDI>.

=cut

1;
