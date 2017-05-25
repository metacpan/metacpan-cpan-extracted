package PGObject::Composite;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Carp;
use PGObject;
use PGObject::Type::Composite; # needed to import routines
use parent 'Exporter', 'PGObject::Type::Composite';

our @EXPORT_OK = qw(call_procedure to_db from_db call_dbmethod
                   _get_dbh _get_funcschema _get_funcprefix _get_schema
                   _get_registry _get_typename _get_typeschema
                   default_dbh default_schema default_prefix default_registry);
our %EXPORT_TAGS = (all => \@EXPORT_OK,
                    mapper => [qw{call_procedure to_db from_db call_dbmethod
                                 default_dbh default_schema default_prefix
                                 default_registry}],
                   );

=head1 NAME

PGObject::Composite - Composite Type Mapper for PGObject

=head1 VERSION

Version 1.0.2

=cut

our $VERSION = 1.000002;


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

=head2 new

This constructs a new object.  Basically it copies the incoming hash (one level
deep) and then blesses it.  If the hash passed in has a dbh member, the dbh 
is set to that.  This does not set the function prefix, as this is assumed to 
be done implicitly by subclasses.

=cut

sub new {
    my ($self) = shift @_;
    my %args = @_;
    my $ref = {};
    $ref->{$_} = $args{$_} for keys %args;
    bless ($ref, $self);
    $ref->set_dbh($ref->{dbh});
    $ref->_set_funcprefix($ref->{_funcprefix});
    $ref->_set_funcschema($ref->{_funcschema});
    $ref->_set_registry($ref->{_registry});
    $ref->associate($self) if ref $self;
    return $ref;
}

sub _set_funcprefix {
    my ($self, $prefix) = @_;
    $self->{_funcprefix} = $prefix;
}

sub _set_funcschema {
    my ($self, $schema) = @_;
    $self->{_funcschema} = $schema;
}

sub _set_registry {
    my ($self, $registry) = @_;
    $self->{_registry} = $registry;
}

=head2 set_dbh

Sets the database handle

=cut

sub set_dbh {
    my ($self, $dbh) = @_;
    $self->{_dbh} = $dbh;
}

sub _set_dbh {
    my ($self, $dbh) = @_;
    $self->set_dbh($dbh);
}

=head2 dbh

returns the dbh of the object

=cut

sub dbh {
    my ($self) = @_;
    return $self->_get_dbh;
}

sub _get_dbh {
    my ($self) = @_;
    return $self->{_dbh} if ref $self and $self->{_dbh};
    return $self->default_dbh if ref $self;
    return "$self"->default_dbh;
}

=head2 associate

Assocates the current object with another PGObject-based class

=cut

sub associate {
    my ($self, $other) = @_;
    $self->set_dbh($other->dbh);
}

=head2 default_dbh

returns the dbh used by default.  Subclasses must override.

=cut

sub default_dbh {
    croak 'Must override default dbh factory';
}

sub _get_funcschema {
    my ($self) = @_;
    return $self->{_funcschema} if ref $self and $self->{_funcschema};
    return $self->default_schema if ref $self;
    return "$self"->default_schema;
}

=head2 default_schema

returns the schema used by default.  defaalt is 'public'

=cut

sub default_schema { 'public' }

sub _get_funcprefix {
    my ($self) = @_;
    return $self->{_funcprefix} if ref $self and $self->{_funcprefix};
    return $self->default_prefix;
    return "$self"->default_prefix;
}

sub _get_schema {
    my ($self) = @_;
    return $self->{_funcprefix} if ref $self and $self->{_funcprefix};
    return $self->default_schema;
    return "$self"->default_schema;
}

sub _get_typeschema {
    my ($self) = @_;
    return $self->{_funcprefix} if ref $self and $self->{_funcprefix};
    return $self->default_schema;
    return "$self"->default_schema;
}
    

sub _set_schema {
    my ($self, $schema);
    $self->{_schema} = $schema;
}

=head2 default_prefix

returns the prefix used by default.  Default is empty string

=cut

sub default_prefix { '' }

sub _get_registry {
    my ($self) = @_;
    return $self->{_registry} if ref $self and $self->{_registry};
    return $self->default_registry if ref $self;
    return "$self"->default_registry;
}

=head2 default_registry

Returns the registry used by default.  Default is 'default'

=cut

sub default_registry { 'default' }

=head2 call_dbmethod

Calls a mapped method with the current object as the argument named "self."

This allows for stored procedurs to differentiate what is related to a related
type and what is not.

=cut

sub _build_args {
    my ($self, $args) = @_;
    delete $args->{$_} for qw(typename typeschema); # invariants
    my %args;
    %args = (map {
                 my $f = "_get_$_";
                 $_ => (ref $self ? $self->$f() : "$self"->$f() )
               }  
               qw(funcschema dbh funcprefix registry typename typeschema));
    %args = (%args, %$args) if ref $args;
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
