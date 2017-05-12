package PGObject::Composite;

use 5.008;
use strict;
use warnings FATAL => 'all';

use Carp;
use PGObject;
use PGObject::Type::Composite;

=head1 NAME

PGObject::Composite - Composite Type Mapper for PGObject

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module provides a more object-oriented type of interface for writing 
stored procedures for PostgreSQL than the Simple mapper.  The Composite mapper
assumes that the object calling the call_dbmethod function usually wants its
type on the first argument.  Thus we provide an extra function where this is 
not the case (call_dbfunction).

So we given a cumposite type:

   CREATE TYPE foo AS (bar int, baz text);

and a stored procedure:

   CREATE OR REPLACE FUNCTION int(foo) returns int language sql as $$
     SELECT length($1.baz) + $1.bar;
   $$;

We can have a package:

  package mycomposite;
  use PGObject::Composite;
  sub new {
      my $pkg = shift;
      bless shift, $pkg;
  }

  sub to_int {
      my $self = shift;
      my ($ref) = $shelf->call_dbmethod(funcname => 'int');
      return shift values %$ref;
  }

=head1 SUBROUTINES/METHODS

=head2 call_dbmethod

Calls a mapped method with the current object as the argument named "self."

This allows for stored procedurs to differentiate what is related to a related
type and what is not.

=cut

my %defaults = (
    funcschema => 'public',
    funcprefix => '',
    registry   => 'default',    
);

sub _build_args {
    my ($self, $args) = @_;
    my %args = ((map {
                      my $funcname = "_get_$_";
                      eval { $self->can($funcname) } ?
                         ($_ => $self->$funcname()) :
                         ($_ => $defaults{$_});
                } qw(funcschema dbh funcprefix registry typename typeschema))
                , %$args);
    return %args;
}

sub call_dbmethod {
    my $self = shift;
    my %args = @_;
    %args = _build_args($self, \%args);

    my $funcinfo = PGObject->function_info(
               %args, (argtype1 => $args{typename}, 
                      argschema => $args{typeschema})
    );
    my @dbargs = (map { my $name = $_->{name};
                       $name =~ s/^in_//i;
                       $name eq 'self'? $self : $args{args}->{$name} ;
               } @{$funcinfo->{args}});
    my @rows = PGObject->call_procedure(%args, ( args => \@dbargs ));
    return shift @rows unless wantarray;
    return @rows;
} 

=head2 call_procedure

Maps to PGObject::call_procedure with appropriate defaults.

=cut

sub call_procedure {
    my ($self) = shift @_;
    my %args = @_;
    %args = _build_args($self, \%args);

    croak 'No DB handle provided' unless $args{dbh};
    my @rows = PGObject->call_procedure(%args);
    return shift @rows unless wantarray;
    return @rows;
}

=head1 INTERFACES TO OVERRIDE

=head2 _get_schema

Defaults to public.  This is the type's schema

=head2 _get_funcschema

defaults to public.

=head2 _get_typename

The name of the composite type.  Must be set.

=head2 _get_dbh

The database connection to use.  Must be set.

=head1 AUTHOR

Chris Travers, C<< <chris at efficito.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-composite at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Composite>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Composite


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Composite>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Composite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Composite>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Composite/>

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

1; # End of PGObject::Composite
