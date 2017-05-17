package PGObject::Util::Catalog::Types;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Carp;
use Memoize;

use Exporter 'import';
our @EXPORT_OK = qw(get_attributes);

=head1 NAME

PGObject::Util::Catalog::Types - Utilities for working with Composite types

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';



=head1 SYNOPSIS

To get the attributes of a composite type:

   use PGObject::Util::Catalog::Types;
   my $dbh = DBI->connect(...);
   my @attributes = get_attributes(
          typename => 'foo', 
        typeschema => 'public',
               dbh => $dbh);

=head1 OPTIONALLY EXPORTED FUNCTIONS

=over

=item get_attributes

=back

=head1 SUBROUTINES/METHODS

=head2 get_attributes

This takes a list of args as a hash and returns a list of hashrefs, one for 
each attribute in order.  This function may be memoized, so it is not safe to
alter any part of the returned data structure in any way.

Arguments are:

=over

=item typename

Name of type

=item typeschema

Schema to look in.  This is required

=item dbh

Database handle to use.  This allows different dbs to be used simultaneously 
with different type definitions.

=back

Each hashref includes the following fields:

=over

=item attname 

The attribute name

=item atttype

The name of the type

=back

=cut

sub get_attributes {
    my %args = @_;
    croak 'No DB Handle Provided' unless $args{dbh};
    croak 'No schema provided' unless $args{typeschema};

    my $query = "
       SELECT attname, typname as atttype
         FROM pg_attribute a
         JOIN pg_class r ON a.attrelid = r.oid
         JOIN pg_type t ON t.oid = a.atttypid
         JOIN pg_namespace n ON r.relnamespace = n.oid
        WHERE relname = ? AND nspname = ? and attnum > 0
     ORDER BY a.attnum
     ";
     my $sth = $args{dbh}->prepare($query);
     $sth->execute($args{typename}, $args{typeschema});
     my @cols;
     while (my $ref = $sth->fetchrow_hashref('NAME_lc')){
         push @cols, $ref;
     }
     return grep {defined $_->{attname}} @cols;
}

=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-util-catalog-types at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Util-Catalog-Types>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Util::Catalog::Types


You can also look for information at:

=over

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Util-Catalog-Types>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Util-Catalog-Types>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Util-Catalog-Types>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Util-Catalog-Types/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014-2017 Chris Travers.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Chris Travers's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of PGObject::Util::Catalog::Types
