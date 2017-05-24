package PGObject::Simple;

use 5.010;
use strict;
use warnings;
use Carp;
use PGObject;
use parent 'Exporter';

=head1 NAME

PGObject::Simple - Minimalist stored procedure mapper based on LedgerSMB's DBObject

=head1 VERSION

Version 3.0.1

=cut

our $VERSION = 3.000001;

=head1 SYNOPSIS

  use PGObject::Simple;
  my $obj = PGObject::Simple->new(%myhash);
  $obj->set_dbh($dbh); # Database connection

To call a stored procedure with enumerated arguments.

  my @results = $obj->call_procedure(
      funcname     => $funcname,
      funcschema   => $funcname,
      args         => [$arg1, $arg2, $arg3],
  );

You can add something like a running total as well:

  my @results = $obj->call_procedure(
      funcname      => $funcname,
      funcschema    => $funcname,
      args          => [$arg1, $arg2, $arg3],
      running_funcs => [{agg => 'sum(amount)', alias => 'total'}],
  );

To call a stored procedure with named arguments from a hashref.  This is 
typically done when mapping object properties in to stored procedure arguments.

  my @results = $obj->call_dbmethod(
      funcname      => $funcname,
      funcschema    => $funcname,
      running_funcs => [{agg => 'sum(amount)', alias => 'total'}],
  );

To call a stored procedure with named arguments from a hashref with overrides.

  my @results = $obj->call_dbmethod(
      funcname      => 'customer_save',
      funcschema    => 'public',
      running_funcs => [{agg => 'sum(amount)', alias => 'total'}],
      args          => { id => undef }, # force to create new!
  );


=head1 EXPORTS

We now allow various calls to be exported.  We recommend using the tags.

=head2 One-at-a-time Exports

=over

=item call_dbmethod

=item call_procedure

=item set_dbh

=item _set_funcprefix

=item _set_funcschema

=item _set_registry

=back

=head2 Export Tags

Below are the export tags listed including the leading ':' used to invoke them.

=over

=item :mapper
	    call_dbmethod, call_procedure, and set_dbh

=item :full
	    All methods that can be exported at once.

=back

=cut

our @EXPORT_OK = qw(call_dbmethod call_procedure set_dbh associate dbh
                   _set_funcprefix
                    _set_funcschema _set_registry);

our %EXPORT_TAGS = (mapper => [qw(call_dbmethod call_procedure set_dbh dbh)],
                    full => \@EXPORT_OK);

=head1 DESCRIPTION

PGObject::Simple a top-half object system for PGObject which is simple and
inspired by (and a subset functionally speaking of) the simple stored procedure
object method system of LedgerSMB 1.3. The framework discovers stored procedure
APIs and dispatches to them and can therefore be a base for application-specific
object models and much more.

PGObject::Simple is designed to be light-weight and yet robust glue between your
object model and the RDBMS's stored procedures. It works by looking up the
stored procedure arguments, stripping them of the conventional prefix 'in_', and
mapping what is left to object property names. Properties can be
overridden by passing in a hashrefs in the args named argument. Named arguments
there will be used in place of object properties.

This system is quite flexible, perhaps too much so, and it relies on the
database encapsulating its own logic behind self-documenting stored procedures
using consistent conventions. No function which is expected to be discovered can
be overloaded, and all arguments must be named for their object properties. For
this reason the use of this module fundamentally changes the contract of the
stored procedure from that of a fixed number of arguments in fixed types
contract to one where the name must be unique and the stored procedures must be
coded to the application's interface. This inverts the way we typically think
about stored procedures and makes them much more application friendly.

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

=head2 set_dbh($dbh)

Sets the database handle (needs DBD::Pg 2.0 or later) to $dbh

=cut

sub set_dbh {
    my ($self, $dbh) = @_;
    $self->{_dbh} = $dbh;
}

=head2 dbh

Returns the database handle for the object.

=cut

sub dbh {
    my ($self) = @_;
    return ($self->{_dbh} or $self->{_DBH});
}

=head2 associate($pgobject)

Sets the db handle to that from the $pgobject.

=cut

sub associate {
    my ($self, $other) = @_;
    $self->set_dbh($other->dbh);
}

=head2 _set_funcprefix

This sets the default funcprefix for future calls.  The funcprefix can still be
overridden by passing in an explicit '' in a call.  This is used to "claim" a 
certain set of stored procedures in the database for use by an object.

It is semi-private, intended to be called by subclasses directly, perhaps in 
constructors, but not from outside the object.

=cut

sub _set_funcprefix {
    my ($self, $funcprefix) = @_;
    $self->{_func_prefix} = $funcprefix;
}

=head2 _set_funcschema 

This sets the default funcschema for future calls.  This is overwridden by 
per-call arguments, (PGObject::Util::DBMethod provides for such overrides on a
per-method basis).

=cut

sub _set_funcschema {
    my ($self, $funcschema) = @_;
    $self->{_func_schema} = $funcschema;
}

=head2 _set_registry

This sets the registry for future calls.  The idea here is that this allows for
application object model wrappers to set which registry they are using, both for
predictability and ensuring that interoperability is possible.

=cut

sub _set_registry {
    my ($self, $registry) = @_;
    $self->{_registry} = $registry;
}

=head2 call_dbmethod

Does a straight-forward mapping (as described below) to the stored procedure 
arguments.  Stored procedure arguments are looked up, a leading 'in_' is 
stripped off where it exists, and the remaining string mapped back to an 
object property.  The $args{args} hashref can be used to override arguments by
name.  Unknown properties are handled simply by passing a NULL in, so the
stored procedures should be prepared to handle these.

As with call_procedure below, this returns a single hashref when called in a
scalar context, and a list of hashrefs when called in a list context.

NEW IN 2.0: We now give preference to functions of the same name over 
properties.  So $obj->foo() will be used before $obj->{foo}.  This enables
better data encapsulation.

=cut

sub _arg_defaults {
    my ($self, %args) = @_;
    local $@;
    if (ref $self) {
        $args{dbh} ||= eval { $self->dbh } ;
        $args{funcprefix} //= eval { $self->funcprefix } ;
        $args{funcschema} //= eval { $self->funcschema } ;
        $args{funcprefix} //= $self->{_func_prefix};
        $args{funcschema} //= $self->{_func_schema};
        $args{funcprefix} //= eval {$self->_get_prefix() };
    } else { 
	# see if we have package-level reader/factories
        $args{dbh} ||= "$self"->dbh; # if eval {"$self"->dbh};
        $args{funcschema} //= "$self"->funcschema if eval {"$self"->funcschema};
        $args{funcprefix} //= "$self"->funcprefix if eval {"$self"->funcprefix};
    }
    $args{funcprefix} //= '';

    return %args
}

sub _self_to_arg { # refactored from map call, purely internal
    my ($self, $args, $argname) = @_;
    my $db_arg;
    $argname =~ s/^in_//;
    local $@;
    if (ref $self and $argname){
        if (eval { $self->can($argname) } ) {
            eval { $db_arg = $self->can($argname)->($self) };
        } else {
            $db_arg = $self->{$argname};
        }
    }
    $db_arg = $args->{args}->{$argname} if exists $args->{args}->{$argname};
    $db_arg = $db_arg->to_db if eval {$db_arg->can('to_db')};
    $db_arg = { type => 'bytea', value => $db_arg} if $_->{type} eq 'bytea';

    return $db_arg;
}

sub call_dbmethod {
    my ($self) = shift @_;
    my %args = @_;
    croak 'No function name provided' unless $args{funcname};
    %args = _arg_defaults($self, %args);
    my $info = PGObject->function_info(%args);

    my $arglist = [];
    @{$arglist} = map { _self_to_arg($self, \%args, $_->{name}) } 
                  @{$info->{args}};
    $args{args} = $arglist;

    # The conditional return is necessary since the object may carry a registry
    # --CT
    return $self->call_procedure(%args) if ref $self;
    return __PACKAGE__->call_procedure(%args);
}

=head2 call_procedure 

This is a lightweight wrapper around PGObject->call_procedure which merely
passes the currently attached db connection in.  We use the previously set 
funcprefix and dbh by default but other values can be passed in to override the
default object's values.

This returns a single hashref when called in a scalar context, and a list of 
hashrefs when called in a list context.  When called in a scalar context it 
simply returns the single first row returned.

=cut

sub call_procedure {
    my ($self, %args) = @_;
    %args = _arg_defaults($self, %args);
    croak 'No DB handle provided' unless $args{dbh};
    my @rows = PGObject->call_procedure(%args);
    return shift @rows unless wantarray;
    return @rows;
}

=head1 WRITING CLASSES WITH PGObject::Simple

Unlike PGObject, which is only loosely tied to the functionality in question
and presumes that relevant information will be passed over a functional 
interface, PGObject is a specific framework for object-oriented coding in Perl.
It can therefore be used alone or with other modules to provide quite a bit of
functionality.

A PGObject::Simple object is a blessed hashref with no gettors or setters.  This
is thus ideal for cases where you are starting and just need some quick mappings
of stored procedures to hashrefs.  You reference properties simply with the
$object->{property} syntax.  There is very little encapsulation in objects, and 
very little abstraction except when it comes to the actual stored procedure 
interfaces.   In essence, PGObject::Simple generally assumes that the actual
data structure is essentially a public interface between the database and 
whatever else is going on with the application.

The general methods can then wrap call_procedure and call_dbmethod calls,
mapping out to stored procedures in the database.

Stored procedures must be written to relatively exacting specifications.  
Arguments must be named, with names prefixed optionally with 'in_' (if the 
property name starts with 'in_' properly one must also prefix it).

An example of a simple stored procedure might be:

   CREATE OR REPLACE FUNCTION customer_get(in_id int) returns customer 
   RETURNS setof customer language sql as $$

   select * from customer where id = $1;

   $$;

This stored procedure could then be called with any of:

   $obj->call_dbmethod(
      funcname => 'customer_get', 
   ); # retrieve the customer with the $obj->{id} id

   $obj->call_dbmethod(
      funcname => 'customer_get',
      args     => {id => 3 },
   ); # retrieve the customer with the id of 3 regardless of $obj->{id}

   $obj->call_procedure(
      funcname => 'customer_get',
      args     => [3],
   );

=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Simple/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013-2017 Chris Travers.

Redistribution and use in source and compiled forms with or without 
modification, are permitted provided that the following conditions are met:

=over

=item 

Redistributions of source code must retain the above
copyright notice, this list of conditions and the following disclaimer as the
first lines of this file unmodified.

=item 

Redistributions in compiled form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
source code, documentation, and/or other materials provided with the 
distribution.

=back

THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of PGObject::Simple
