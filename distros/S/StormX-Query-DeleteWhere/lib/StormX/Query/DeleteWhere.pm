package StormX::Query::DeleteWhere;
{
  $StormX::Query::DeleteWhere::VERSION = '0.200';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

with 'Storm::Role::Query';
with 'Storm::Role::Query::HasBindParams';
with 'Storm::Role::Query::HasWhereClause';
with 'Storm::Role::Query::IsExecutable';


has 'safe_mode' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

sub _sql {
    my ( $self ) = @_;
    my $table = $self->class->meta->storm_table->sql;
    my $column = $self->class->meta->primary_key->column->sql;
    return  join q[ ], qq[DELETE FROM $table], $self->_where_clause;
}


sub delete  {
    my ( $self, @args ) = @_;

    if ( $self->safe_mode && $self->_has_no_where_elements ) {
        confess qq[could not perform query: you did not specify a where clause];
    }
    
    my @params = $self->_combine_bind_params_and_args( [$self->bind_params], \@args );
    $self->_sth->execute( @params );
    return 1;
}



sub bind_params {
    my ( $self ) = @_;
    return
        ( map { $_->bind_params() }
          grep { $_->can('bind_params') }
          $self->where_clause_elements
        );
}


no Moose;
__PACKAGE__->meta->make_immutable;


1;

__END__

=head1 NAME

StormX::Query::DeleteWhere - A delete query with a where clause

=head1 SYNOPSIS

    use Storm;

    use StormX::Query::DeleteWhere;

    $storm = Storm->new( ... );
    
    $q = StormX::Query::DeleteWhere->new( $storm, 'My::Object::Class' );

    $q->where( '.expired', '<=', '?' );

    $q->delete( '2012-12-21' );


=head1 DESCRIPTION

Delete objects that you do not have instantiated locally by using a delete query
with a where clause.

=head2 ROLES

=over 4

=item L<Storm::Role::Query::HasBindParams>

=item L<Storm::Role::Query::HasWhereClause>

=item L<Storm::Role::Query::IsExecutable>

=back

=head2 PROVIDED ATTRIBUTES

=over 4

=item safe_mode

This attribute must be set to true to delete all records from a table in a
single query.

=over 4

=item is rw

=item isa Bool

=item default 1

=back

=back

=head2 PROVIDED METHODS

=over 4

=item b<new $storm, $class, [@params]>

This method instantiates a new L<StormX::Query::DeleteWhere> query. C<$storm> is
the Storm instance to operate on, and C<$class> is the class of objects you wish
to delete from the database. Both C<$storm> and <$class> are required. Any
additional paramaters will be used to query attributes.

=item b<delete [@args]>

Execute the query, deleting objects from the database. If the where clause of
your query used placholders ('?'), they will be replaced with the C<@args>
supplied.

=head2 WHERE CLAUSE

The following methods are provided via L<Storm::Role::Query::HasWhereClause>.
Read L<Storm::Tutorial> for more information on how to use these methods.

=over 4

=item where

=item and

=item or

=item group_start

=item group_end

=back

=head2 SAFE MODE

By default, L<StormX::Query::DeleteWhere> queries are in "safe-mode". This is
to safequard your data from programming errors.

The following query has no where clause. If ran, it will produce an error
instead of deleting all the objects in the table. (Which is what would happen
with an SQL delete query with no where clause.)


    $q = StormX::Query::DeleteWhere->new( $storm, 'My::Object::Class' );

    $q->delete;


You may disable "safe_mode" and enable clearing of all records from a table like this:

    $q = StormX::Query::DeleteWhere->new( $storm, 'My::Object::Class', safe_mode => 0 );

or

    $q = StormX::Query::DeleteWhere->new( $storm, 'My::Object::Class' );

    $q->set_safe_mode( 0 );

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2012 Jeffrey Ray Hallock.
    
    This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
    
=cut













