package SQL::Abstract::Query;
{
  $SQL::Abstract::Query::VERSION = '0.03';
}
use Moose;
use namespace::autoclean;

=head1 NAME

SQL::Abstract::Query - An advanced SQL generator.

=head1 SYNOPSIS

    use SQL::Abstract::Query;
    
    # Create a new query object by specifying the SQL dialect:
    my $query = SQL::Abstract::Query->new( $dbh );
    my $query = SQL::Abstract::Query->new( 'mysql' );
    my $query = SQL::Abstract::Query->new( $dialect );
    my $query = SQL::Abstract::Query->new();
    
    # Use the flexible OO interface:
    my $statement = $query->insert( $table, \@fields );
    my $statement = $query->update( $table, \@fields, \%where );
    my $statement = $query->select( \@fields, \@from, \%where, \%attributes );
    my $statement = $query->delete( $table, \%where );
    
    my $sth = $dbh->prepare( $statement->sql() );
    $sth->execute( $statement->values( \%field_values ) );
    
    # Use the simpler procedural interface:
    my ($sql, @bind_values) = $query->insert( $table, \%field_values );
    my ($sql, @bind_values) = $query->update( $table, \%field_values, \%where );
    my ($sql, @bind_values) = $query->select( \@fields, \@from, \%where, \%attributes );
    my ($sql, @bind_values) = $query->delete( $table, \%where );
    
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind_values );

=head1 DESCRIPTION

This library provides the ability to generate SQL using database-independent Perl
data structures, is built upon the proven capabilities of L<SQL::Abstract>, and
robust and extendable thanks to L<Moose>.

Much of the inspiration for this library came from such modules as
L<SQL::Abstract::Limit>, L<SQL::Maker>, and L<SQL::Abstract::More>.

=over

=item * Queries are constructed as objects which can be re-used.

=item * Supports explicit JOINs.

=item * GROUP BY is supported.

=item * LIMIT/OFFSET is supported (with cross-database compatibility) and uses placeholders.

=item * Easy to extend with Moose subclassing, traits, and roles.

=item * The API has been designed in such a way that extending the functionality in the
future should be less likely to break backwards compatibility.

=item * Re-using a statement via prepare/execute is trivial and can be done with for all
statement types (even UPDATE ... WHERE ...).

=back

=cut

use SQL::Abstract;
use SQL::Dialect;
use Moose::Util::TypeConstraints;

use SQL::Abstract::Query::Insert;
use SQL::Abstract::Query::Update;
use SQL::Abstract::Query::Select;
use SQL::Abstract::Query::Delete;

=head1 CONSTRUCTOR

    # Auto-detect the appropriate dialect from a DBI handle:
    my $query = SQL::Abstract::Query->new( $dbh );
    
    # Explicitly set the dialect that you want:
    my $query = SQL::Abstract::Query->new( 'oracle' );
    
    # Pass a pre-created SQL::Dialect object:
    my $query = SQL::Abstract::Query->new( $dialect );
    
    # The "standard" dialect is the default:
    my $query = SQL::Abstract::Query->new();

=cut

around 'BUILDARGS' => sub{
    my $orig = shift;
    my $self = shift;

    if (@_ == 1 and ref($_[0]) ne 'HASH') {
        return $self->$orig( dialect => $_[0] );
    }

    return $self->$orig( @_ );
};

=head1 ARGUMENTS

=head2 dialect

Each implementation, or dialect, of SQL has quirks that slightly (or in some cases
drastically) change the way that the SQL must be written to get a particular task
done.  In order for this module to know which particular set of quirks a dialect
must be declared.  See the documentation for L<SQL::Dialect> to see how this works.

The dialect can be set via a string (the dialect name), a $dbh (the dialect is
auto-detected), or you can pass a SQL::Dialect object that you created yourself.

The dialect is optional.  If none is specified then a simple, default, dialect will
be used.

=cut

subtype 'SQL::Abstract::Query::Types::Dialect',
    as class_type('SQL::Dialect');

coerce 'SQL::Abstract::Query::Types::Dialect',
    from 'Defined',
    via { SQL::Dialect->new( $_ ) };

has dialect => (
    is         => 'ro',
    isa        => 'SQL::Abstract::Query::Types::Dialect',
    coerce     => 1,
    lazy_build => 1,
);
sub _build_dialect {
    return SQL::Dialect->new();
}

=head1 ATTRIBUTES

=head2 abstract

The underlying L<SQL::Abstract> object that will be used to generate
much of the SQL for this module.  There really isn't much need for you
to set this attribute yourself unless you are doing something really
crazy.

=cut

has abstract => (
    is         => 'ro',
    isa        => 'SQL::Abstract',
    lazy_build => 1,
);
sub _build_abstract {
    my ($self) = @_;
    return SQL::Abstract->new(
        quote_char => $self->dialect->quote_char(),
        name_sep   => $self->dialect->sep_char(),
    );
}

=head1 STATEMENT METHODS

New statement objects should be created using these methods.  Each
statement class has their own documentation that explains the
various arguments that they accept, which ones are optional, and
the intricacies of how they work.

All the satement classes apply the L<SQL::Abstract::Query::Statement>
role.  Look there to see all the shared features which all statement
objects posses.

=head2 insert

    my $insert = $query->insert( $table, \@fields );
    
    my ($sql, @bind_values) = $query->insert( $table, \%field_values );

See L<SQL::Abstract::Query::Insert>.

=cut

sub insert {
    my $self = shift;
    if (wantarray()) { return SQL::Abstract::Query::Insert->call( $self, @_ ); }
    else { return SQL::Abstract::Query::Insert->new( $self, @_ ); }
}

=head2 update

    my $update = $query->update( $table, \@fields, \%where );
    
    my ($sql, @bind_values) = $query->update( $table, \%field_values, \%where );

See L<SQL::Abstract::Query::Update>.

=cut

sub update {
    my $self = shift;
    if (wantarray()) { return SQL::Abstract::Query::Update->call( $self, @_ ); }
    else { return SQL::Abstract::Query::Update->new( $self, @_ ); }
}

=head2 select

    my $select = $query->select( \@fields, \@from, \%where, \%arguments );
    
    my ($sql, @bind_values) = $query->select( \@fields, \@from, \%where, \%arguments );

See L<SQL::Abstract::Query::Select>.

=cut

sub select {
    my $self = shift;
    if (wantarray()) { return SQL::Abstract::Query::Select->call( $self, @_ ); }
    else { return SQL::Abstract::Query::Select->new( $self, @_ ); }
}

=head2 delete

    my $delete = $query->delete( $table, \%where );
    
    my ($sql, @bind_values) = $query->delete( $table, \%where );

See L<SQL::Abstract::Query::Delete>.

=cut

sub delete {
    my $self = shift;
    if (wantarray()) { return SQL::Abstract::Query::Delete->call( $self, @_ ); }
    else { return SQL::Abstract::Query::Delete->new( $self, @_ ); }
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAMED PLACEHOLDERS

In this module placeholders have an additional use.  In order to re-use queries
placeholder values must be named so that the L<SQL::Abstract::Query::Statement/values>
method may work correctly. In L<SQL::Abstract> you must generate a new UPDATE statement for
every update you want to execute.  In this module this is much simplified by using named
placeholders:

    my $update = $query->update('customer', ['email', 'active'], {customer_id => 'id'});
    my $sth = $dbh->prepare( $update->sql() );
    
    $sth->execute( $update->values({ email=>'b@e.com', active=>1, id=>1 }) );
    $sth->execute( $update->values({ email=>'j@e.com', active=>1, id=>2 }) );
    $sth->execute( $update->values({ email=>'n@e.com', active=>1, id=>3 }) );

All statement types support named placeholders for use with values().  In any spot of
a statement where you would normally pass a value you can instead pass a name, then
when you call values() you use that name as the key.

Here's an example that uses this feature to provide contextual information in the
placeholder names:

    my $select = $query->select(
        'user_id',
        'users',
        {
            posts => {-between => ['min_posts', 'max_posts']},
            role => 'moderator',
        },
    );
    
    my $sth = $dbh->prepare( $select->sql() );
    
    my $one_star_moderators = $sth->fetchcol_arrayhref( $select->values({
        min_posts => 0,
        max_posts => 10,
    }) );
    
    my $two_star_moderators = $sth->fetchrow_hashref( $select->values({
        min_posts => 11,
        max_posts => 50,
    }) );

Named placeholders can be mixed with non-named placeholders, as in the above
example with the role=>'moderator' check.

=head1 APPENDIX

=head2 Why Yet Another SQL Generator?

There are quite a few SQL generators out there, including:

=over

=item * L<SQL::Abstract>

=item * L<SQL::Maker>

=item * L<SQL::Generator>

=item * L<SQL::OOP>

=item * L<SQL::Entity>

=back

By far the most popular and battle tested is SQL::Abstract.  This module
takes the great things about SQL::Abstract and makes them better.  Others
have tried to do this, but with limited success, so this module aims to do
it right.

=head2 API Stability

This module is currently in a working draft state.  I am confident that
the current implementation is complete, well thought-out, and well
tested.  But, I still need to receive some input from the perl community
before I can say the API is 100% stable.  Until then it is possible that
changes will be made that break backwards compatibility.

If you use this module then please contact the author describing your
experience and any thoughts you may have.

If this statement concerns you then you should also send the author an
e-mail asking about the API stability.  It may very well be that the
API can now be considered stable but a release of this library has not
yet been made that states as much.

=head2 Compatibility

This module aims to be compatible with the core L<SQL::Abstract> API as much
as possible, but not at the expense of degrading quality.  There are
parts of the SQL::Abstract API that are difficult to extend, others
that are sub-optimal but cannot be changed due to backwards compatibility
requirements, and still others that just don't make sense due to the drastic
design difference of this module.  These aspects of SQL::Abstract will not
be reproduced in this module.

Here is a list of the current differences between this module's API and SQL
generation and what SQL::Abstract does:

=over

=item * The select() method takes the fields as the first argument rather
than the second argument.  This better matches how SQL is written and
is more natural.

=item * All identifiers are quoted by default since not doing so will
cause SQL that has identifiers which look like reserved words to fail.

=item * The fourth argument to select() is not $order as it is in
SQL::Abstract, instead it is a hash of L<SQL::Abstract::Query::Select>
attributes where one of the attributes may be order_by.

=item * SQL::Abstract is not being used to generate the ORDER BY clause.
This is partly due to other clauses needing to gain access to the SQL
before the ORDER BY is appended to it, and also because SQL::Abstract's
implementation of ORDER BY is a bit convoluted.

=item * Many of SQL::Abstract's methods and attributes are not reproduced.
Some of these may be made available at a later date, but likely not unless
someone has a use-case for needing them.

=item * SQL::Abstract supports *very* complex arguments, which is great, but
some of them seem to be supported because they can be, rather than because
someone actually needs it.  For example, the ability to provide a reference
of an array reference as the source for a select.  Also, by not supporting
all the multitudes of variations of arguments this module has much more room
to grow and take advantage of these available argument formats for different
purposes.

=item * The insert() method does not accept field values as an array reference.
This is by design - SQL that depends on the order of the columns in the
database is brittle and will eventually break.  Also, due to the need for the
statement objects to be re-useable the array ref form of fields has been re-purposed.
That being said, perhaps there is a use case where this would be useful.  If so,
thunk the author on the head and let him know.

=item * The insert() method does not yet accept a returning option.  This
may change if a flexible implementation is developed.

=back

If there is something in SQL::Abstract that you think this module should
support then please let the author know.

=head1 EXTENDING

Guidelines for extending the functionality of this module using plugins, or
otherwise, have not yet been developed as the internal workings of this
module are still in flux.  There are several entries in the TODO section
that reflect this.

For now, just shoot the author an e-mail.

=head1 CONTRIBUTING

If you'd like to contribute bug fixes, enhancements, additional test covergage,
or documentation to this module then by all means do so.  You can fork this
repository using L<github|https://github.com/bluefeet/SQL-Abstract-Query> and
then send the author a pull request.

Please contact the author if you are considering doing this and discuss your ideas.

=head1 SUPPORT

Currently there is no particular mailing list or IRC channel for this project.
You can shoot the author an e-mail if you have a question.

If you'd like to report an issue you can use github's
L<issue tracker|https://github.com/bluefeet/SQL-Abstract-Query/issues>.

=head1 TODO

=over

=item * The fields() argument of the select statement should support the ability
to assign aliases to columns.  Currently the only way to do this with SQL::Abstract
is by providing a verbatim string where the fields sql must be manually built.

=item * Document all the various ways this module can be used, possibly as a
cookbook.  Show how sub-queries can be used, for example.

=item * Create a unit test that compares the output of this module compared to
SQL::Abstract, proving that this module is at least as capable.

=item * Support more dialects of SQL (and thus more DBD drivers).  Help from
generous volunteers encouraged and appreciated!

=item * Support the ability to extend the SQL generation logic by hooking in to
various stages of the SQL generation and alter the behavior.  This would, for
example, allow the LIMIT logic to be moved out of SQL::Abstract::Query::Select
and in to SQL::Abstract::Query::Select::Limit.  This would also allow other
people to write their own modules that modify SQL generation without having to
write brittle hacks.

=item * In addition to the above it would be nice if just a portion of a SQL query
could be generated, such as just the GROUP BY clause, etc.  This would be similar
to SQL::Abstracts's where() method but the API would likely be very different.

=item * Allow for more join types.  Currently only JOIN and LEFT JOIN work.  This
should be trivial to add.

=item * Support UPDATE ... SELECT.

=item * Possibly support more SQL commands such as TRUNCATE, ALTER, CREATE, DROP, etc.

=back

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 CONTRIBUTORS

=over

=item * Terrence Brannon

=back

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

