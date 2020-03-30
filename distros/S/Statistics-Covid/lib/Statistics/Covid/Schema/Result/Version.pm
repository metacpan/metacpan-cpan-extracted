package Statistics::Covid::Schema::Result::Version;

use strict;
use warnings;

our $VERSION = '0.23';

use base qw/DBIx::Class::Core/;

# the input parameter is exactly the same as described in
# Statistics::Covid::IO::DualBase (the contents of 'db-specific')
use Statistics::Covid::Version::Table;

print __PACKAGE__ . ": preparing table ".$Statistics::Covid::Version::Table::SCHEMA->{'tablename'}."\n";

if( ! __PACKAGE__->table($Statistics::Covid::Version::Table::SCHEMA->{'tablename'}) ){ die "call to table() has failed for table name '".$Statistics::Covid::Version::Table::SCHEMA->{'tablename'}."'." }
my $sc = $Statistics::Covid::Version::Table::SCHEMA->{'schema'};
die "there is no schema!" unless defined $sc;

for my $acolname (@{$Statistics::Covid::Version::Table::SCHEMA->{'column-names'}}) {
	if( ! exists $sc->{$acolname} or ! defined $sc->{$acolname} ){ warn "column '$acolname' exists in DBCOLUMNS_NAMES but not in DBCOLUMNS_SPEC" }
	# not sure if it returns error!
	if( __PACKAGE__->add_column($acolname => $sc->{$acolname}) ){ die "call to add_column() has failed for column '$acolname', spec: ".join(",", map { $_.'=>'.$sc->{$acolname}->{$_} } (keys %{$sc->{$acolname}}))."." }
	#print "added column $acolname\n";
}
if( ! __PACKAGE__->set_primary_key(@{$Statistics::Covid::Version::Table::SCHEMA->{'column-names-for-primary-key'}}) ){ die "call to set_primary_key() has failed for: ".join(',',@{$Statistics::Covid::Version::Table::SCHEMA->{'column-names-for-primary-key'}})."." }

1;
__END__
# end program, below is the POD
=pod

=encoding UTF-8


=head1 NAME

Statistics::Covid::Schema::Result::Version - Version is a table in our database of collected Covid statistics and this module initialises this table using DBIx::Class


=head1 VERSION

Version 0.23



Whenever a new table is to be created, call it ABC, then you
must copy this file


=head1 DESCRIPTION
This module is not to be used directly. It creates the table Version
with information, such as tablename, table schema,
primary key columns, etc., stored in L<Statistics::Covid::Version::Table>.
The procedure to create a new table, call it ABC, is as follows:

=over 2

=item Create Statistics::Covid::ABC::Table to contain the schema of
the new table, by copying L<Statistics::Covid::Version::Table>
and modifying it.

=item Create Statistics::Covid::Schema::Result::ABC modelled on
this current module. The basic action performed by this module
is to create a table, its columns using the specific table schema
which you will see its format in L<Statistics::Covid::Version::Table>,
and the column name(s) to form the primary key.

=item Insert this

    use Statistics::Covid::Schema;

in every module you want to access this and every other table you already created.
Then follow L<DBIx::Class> guidelines on how to deploy the database and
interact with these tables. Something along these lines:

    my $dsn = 'dbi:SQLite:dbname=MyDB.sqlite';
    my $shemahandle = Statistics::Covid::Schema->connect($dsn, "", "", $dbparams);
    # create the table, will die if table exists
    $shemahandle->deploy();
    # find rows for the given table and where condition ...
    my $resultset = $shemahandle->('Version')->search({name=>'Samarkand'});
    # ... and act on them
    $resultset->delete();
    $shemahandle->disconnect();

=back


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>, C<< <andreashad2 at gmail.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-Covid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Covid>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Covid::Schema::Result::Version


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Covid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Covid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Covid>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Covid/>

=item * Information about the basis module DBIx::Class

L<http://search.cpan.org/dist/DBIx-Class/>

=back


=head1 DEDICATIONS

Almaz


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2020 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=cut

