package Storm;
{
  $Storm::VERSION = '0.240';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

use Storm::Aeolus;
use Storm::LiveObjects;
use Storm::Query::Delete;
use Storm::Query::DeleteWhere;
use Storm::Query::Insert;
use Storm::Query::Lookup;
use Storm::Query::Refresh;
use Storm::Query::Select;
use Storm::Query::Update;
use Storm::Source;
use Storm::Transaction;

use Storm::Types qw( StormAeolus StormLiveObjects StormPolicyObject StormSource );
use MooseX::Types::Moose qw( CodeRef ClassName Str Object );


has 'aeolus' => (
    is => 'rw',
    isa => StormAeolus,
    lazy => 1,
    default => sub { Storm::Aeolus->new( storm => $_[0] ) },
);

has 'live_objects' => (
    is  => 'ro',
    isa => StormLiveObjects,
    default => sub { Storm::LiveObjects->new },
);

has 'policy' => (
    is  => 'rw',
    isa => StormPolicyObject,
    default => sub { Storm::Policy::Object->new },
    coerce => 1,
);

has 'source' => (
    is  => 'rw',
    isa => StormSource,
    coerce => 1,
);

has 'table_prefix' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

# returns an active database handle
sub dbh {
    $_[0]->source->dbh;
}

sub delete {
    my ( $self, @objects ) = @_;
    my %queries;
    
    for my $o ( @objects ) {
        my $class = ref $o;
        $queries{$class} ||= $self->delete_query( $class );
        $queries{$class}->delete( $o );
    }
    
    return 1;
}

sub delete_query {
    my ( $self, $class ) = @_;
    confess "$class is not a valid classname" if ! is_ClassName( $class );
    Storm::Query::Delete->new( $self, $class );
}

sub delete_where {
    my ( $self, $class ) = @_;
    confess "$class is not a valid classname" if ! is_ClassName( $class );
    Storm::Query::DeleteWhere->new( $self, $class );
}



sub do_transaction {
    my ( $self, $code ) = @_;
    $self->new_transaction($code)->commit;
}



sub insert  {
    my ( $self, @objects ) = @_;
    
    my %queries;
    
    for my $o ( @objects ) {
        my $class = ref $o;
        $queries{$class} ||= $self->insert_query( $class );
        $queries{$class}->insert( $o );
    }
    
    return 1;
}



sub insert_query {
    my ( $self, $class ) = @_;
    confess "$class is not a valid classname" if ! is_ClassName( $class );
    Storm::Query::Insert->new( $self, $class );
}



sub lookup  {
    my ( $self, $class, @ids ) = @_;
    confess "$class is not a valid classname" if ! is_ClassName( $class );
    
    my $q = $self->lookup_query( $class );
    my @objects = map { $q->lookup( $_ ) } @ids;
    
    if ( @objects > 1 ) {
        return @objects;
    }
    else {
        return wantarray ? @objects : $objects[0];
    }
}

sub lookup_query {
    my ( $self, $class ) = @_;
    confess "$class is not a valid classname" if ! is_ClassName( $class );
    Storm::Query::Lookup->new( $self, $class );
}


sub new_scope {
    my ( $self ) = @_;
    $self->live_objects->new_scope;
}


sub new_transaction {
    my ( $self, $code ) = @_;
    Storm::Transaction->new( $self, $code );
}


sub refresh  {
    my ( $self, @objects ) = @_;
    my %queries;
    
    for my $o ( @objects ) {
        my $class = ref $o;
        $queries{$class} ||= $self->refresh_query( $class );
        $queries{$class}->refresh( $o );
    }
    
    return 1;
}



sub refresh_query {
    my ( $self, $class ) = @_;
    confess "$class is not a valid classname" if ! is_ClassName( $class );
    Storm::Query::Refresh->new( $self, $class );
}



sub select {
    my ( $self, $class, @options ) = @_;
    confess "$class is not a valid classname" if ! is_ClassName( $class );
    $self->select_query( $class );
}



sub select_query {
    my ( $self, $class ) = @_;
    confess "$class is not a valid classname" if ! is_ClassName( $class );
    Storm::Query::Select->new( $self, $class );
}

sub table {
    my ( $self, $arg ) = @_;
    $self->meta->throw_error( "Must pass in a \$class or \$table_name" ) if ! defined $arg;
    
    if ( is_ClassName $arg || is_Object $arg ) {
        return $self->table_prefix . $arg->meta->storm_table->name;
    }
    if ( is_Str $arg ) {
        return $self->table_prefix . $arg;
    }
}



sub update {
    my ( $self, @objects ) = @_;
    my %queries;
    
    for my $o ( @objects ) {
        my $class = ref $o;
        $queries{$class} ||= $self->update_query( $class );
        $queries{$class}->update( $o );
    }
    
    return 1;
}

sub update_query {
    my ( $self, $class ) = @_;
    confess "$class is not a valid classname" if ! is_ClassName( $class );
    Storm::Query::Update->new( $self, $class );
}

no Moose;
1;




__END__

=pod

=head1 NAME

Storm - Object-relational mapping

=head1 TUTORIAL

If you're new to L<Storm> check out L<Storm::Tutorial>.

=head1 SYNOPSIS

    package Foo;

    use Storm::Object;

    storm_table('Foo');

    has 'id' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );

    has 'label' => ( is => 'rw' );



    # and then ....

    package main;

    use Storm;

    # connect to a database
    $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );

    $o = Foo->new( label => 'Storm Enabled Object' );

    # store object
    $storm->insert( $o );

    # update object
    $o->label( 'Updated Object' );
    $storm->update( $o );

    # sync object with database
    $storm->refresh( $o );

    # lookup object in database
    $o = $storm->lookup( 'Foo', 1 );

    # search for objects in database
    $query = $storm->select( 'Foo' );
    $query->where( '.label', '=', 'Updated Object' )
    $iter  = $query->results;
    @results = $iter->all;

    # delete objects
    $storm->delete( $o );

    
=head1 DESCRIPTION

L<Storm> is a Moose based library for storing and retrieving objects over a
L<DBI> connection.

=head1 ATTRIBUTES

=over 4

=item aeolus

Read-only.

A L<Storm::Aeolus> object for installing/uninstalling database tables.

=item live_objects

Read-only.

A L<Storm::LiveObjects> object for tracking the set of live objects. Creates
scope objects to help ensure that objects are not garbage collected. This is
used internally and you typically shouldn't need to access it yourself. It
is documented here for completeness.

=item policy

The policy determines how types are defined in the database and can be used
to customize how types are inflated/deflated. See L<Storm::Policy> for more
details.

=item source

Required.

The L<Storm::Source> object responsible for spawning active database handles. A
Storm::Source object will be coerced from a ArrayRef or Hashref.

=item table_prefix

The prefix to add to table names.

=back

=head1 METHODS

=over 4

=item delete @objects

Deletes the objects from the database.

=item delete_query $class

Returns a L<Storm::Query::Delete> instance for deleting objects of type $class
from the database.

=item delete_where $class

Returns a L<Storm::Query::DeleteWhere> instance for deleting objects of type
$class from the database using a where clause.

=item do_transaction \&func

Creates and commits a L<Storm::Transaction>. The \&func will be called within
the transaction.

=item insert @objects
  
Insert objects into the database.

=item insert_query $class
  
Returns a L<Storm::Query::Insert> instance for inserting objects of type $class
into the database.

=item lookup $class, @ids
  
Retrieve objects from the database.

=item lookup_query $class
  
Returns a L<Storm::Query::Lookup> instance for retrieving objects of type $class
from the database.

=item new_transaction \&func
  
Returns a new transaction. \&func is the code to be called within the
transaction.

=item refresh @objects
  
Update the @objects with data from the database. 

=item refresh_query $class
  
Returns a L<Storm::Query::Refresh> instance for refresh objects of type $class.

=item select $class, @objects
  
Synonamous with C<select_query>. Provided for consistency.

=item select_query $class
  
Returns a L<Storm::Query::Select> instance for selecting objects from the
database.

=item table ClassName | Str

Returns the name of the table with the C<table_prefix> prepended for the given C<ClassName>.
Prepends C<table_prefix> to argument if it is a string.

=item update @objects

Update the @objects in the database.

=item update_query

Returns a L<Storm::Query::Select> instance for updating objects in the
database.

=back

=head1 SEE ALSO

=head2 Similar modules

=over 4

=item L<KiokuDB>

=item L<Fey::ORM>

=item L<Pixie>

=item L<DBM::Deep>

=item L<OOPS>

=item L<Tangram>

=item L<DBIx::Class>

=item L<MooseX::Storage>

=back

=head1 CAVEATS/LIMITATIONS

=head2 Databases

L<Storm> has only been tested using MySQL and SQLite.

=head1 BUGS

Please report bugs on CPAN.

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

Dave Rolsky E<lt>autarch@urth.orgE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

Special thanks to Yuval Kogman and Dave Rolsky, for who without their talented
work and this library would not be possible.

The code for managing the live object set and the scope relies on modified
code written by Yuval Kogman for L<KiokuDB>. Documentation for this feature was
also taken from L<KiokuDB>.

The code for managing the policy and generating sql statements relies on
modified code written by Dave Rolsky for L<Fey>.

=head1 COPYRIGHT

    Copyright (c) 2010-2012 Jeffrey Ray Hallock.

    Copyright (c) 2010-2011 Dave Rolsky.

    Copyright (c) 2008, 2009 Yuval Kogman, Infinity Interactive.

    This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=cut








