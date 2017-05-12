package PGObject::Composite::Role;

use 5.008;
use strict;
use warnings FATAL => 'all';

use Moo::Role;
use PGObject::Composite;

=head1 NAME

PGObject::Composite::Role - A Moo role interface for PGObject::Composite

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

A simple package with mapped stored procs:

  package myobj;
  use Moo;
  with 'PGObject::Composite::Role';
  use PGObject::Type::Composite;
  use PGObject::Util::DBMethod;

  sub _get_dbh { DBI->connect(...); }

  has foo (is => 'ro');
  has bar (is => 'ro');

  dbmethod save => (funcname => 'save', returns_objects => 1);
  
=head1 Properties and Builders

=head2 _dbh

This is the DBD::Pg database handle.  Must be overridden.

Built by _get_dbh which application classes should override either directly or
through an intermediate role.

=cut

has _dbh => (is => 'lazy', builder => '_get_dbh');

sub _get_dbh {
    die 'Must overload get_dbh!';
}

=head2 _funcschema

This is the default function schema.  Default is 'public'

=cut

has _funcschema => (is => 'lazy', builder => '_get_funcschema');

sub _get_funcschema { 'public' }

=head2 _typeschema

This is the schema under which the type is found.  Defaults to public

Builer is _get_schema

=cut

has _typeschema =>  (is => 'lazy', builder => '_get_schema');

sub _get_schema { 'public' };

=head2 _typename

Name of the type.  This should be overridden by subclasses directly.

The builder is _get_typename

=cut

has _typename =>  (is => 'lazy', builder => '_get_typename');

sub _get_typename { die 'Must override _get_typename' };

=head1 METHODS

=head2 call_procedure

Calls a stored procedure with set properties from the object (dbh, etc).

Must provide the following arguments:

=over

=item funcname

Name of function

=item args

arrayref of argument values

=back

=cut

sub call_procedure {
    my @rows = PGObject::Composite::call_procedure(@_);
    return @rows if wantarray;
    return shift @rows;
}

=head2 call_dbmethod

Calls a mapped method by arguments.  Handles things as per PGObject::Composite

=cut

sub call_dbmethod {
    my @rows = PGObject::Composite::call_dbmethod(@_);
    return @rows if wantarray;
    return shift @rows;
}

=head1 AUTHOR

Chris Travers, C<< <chris at efficito.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-composite-role at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Composite-Role>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Composite::Role


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Composite-Role>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Composite-Role>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Composite-Role>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Composite-Role/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Chris Travers.

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

1; # End of PGObject::Composite::Role
