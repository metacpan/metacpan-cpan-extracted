package SQL::Dialect;
{
  $SQL::Dialect::VERSION = '0.02';
}
use Moose;
use namespace::autoclean;

=head1 NAME

SQL::Dialect - Auto-detection of SQL quirks.

=head1 SYNOPSIS

    use SQL::Dialect;
    
    my $dialect = SQL::Dialect->new( $dbh );
    
    if ($dialect->supports('limit-xy')) { ... }
    print $dialect->quote_char();
    ...

=head1 DESCRIPTION

This module detects the SQL dialect of a L<DBI> database handle and
exposes a handful of properties describing the features and quirks of
that dialect.

=cut

use Moose::Util::TypeConstraints;
use List::MoreUtils qw( uniq );

=head1 CONSTRUCTOR

    # Auto-detect the appropriate dialect from a DBI handle:
    my $dialect = SQL::Dialect->new( $dbh );
    
    # Explicitly set the dialect that you want:
    my $dialect = SQL::Dialect->new( 'oracle' );
    
    # The "default" dialect is the default:
    my $dialect = SQL::Dialect->new();

Each implementation, or dialect, of SQL has quirks that slightly (or in some cases
drastically) change the way that the SQL must be written to get a particular task
done.  In order for this module to work a dialect must be declared.  The dialect
will default to "default" which is very limited and only declares the bare minimum
of features.

Currently a dialect type can be one of:

    default
    mysql
    oracle
    postgresql
    sqlite

When declaring the dialect type that you want you can either specify one of the dialects
above, or you can just pass a DBI handle ($dbh) and it will be auto-detected.  Currently
the list of supported DBI Driver is limited to:

    DBD::mysql  (mysql)
    DBD::Oracle (oracle)
    DBD::Pg     (postgresql)
    DBD::PgPP   (postgresql)
    DBD::SQLite (sqlite)

If the driver that you are using is not in the above list then please contact the
author and work with them to get it added.

=cut

around 'BUILDARGS' => sub{
    my $orig = shift;
    my $self = shift;

    if (@_ == 1) {
        return $self->$orig( type => $_[0] );
    }

    return $self->$orig( @_ );
};

my $dbd_dialects = {
    'mysql'  => 'mysql',
    'Oracle' => 'oracle',
    'Pg'     => 'postgresql',
    'PgPP'   => 'postgresql',
    'SQLite' => 'sqlite',
};

my $dialects = {
    default => {
        quote_char          => q["],
        sep_char            => q[.],
    },
    mysql => {
        limit               => 'xy',
        last_insert_id      => 1,
        quote_char          => q[`],
        sep_char            => q[.],
    },
    postgresql => {
        limit               => 'offset',
        sequences           => 1,
        returning           => 'select',
        quote_char          => q["],
        sep_char            => q[.],
    },
    oracle => {
        sequences           => 1,
        returning           => 'into',
        rownum              => 1,
        quote_char          => q["],
        sep_char            => q[.],
    },
    sqlite => {
        last_insert_rowid   => 1,
        limit               => 'offset',
        quote_char          => q["],
        sep_char            => q[.],
    },
};

subtype 'SQL::Dialect::Types::Type',
    as enum([ keys %$dialects ]);

coerce 'SQL::Dialect::Types::Type',
    from class_type('DBI::db'),
    via { $dbd_dialects->{ $_->{Driver}->{Name} } };

has type => (
    is       => 'ro',
    isa      => 'SQL::Dialect::Types::Type',
    coerce   => 1,
    default  => 'default',
    init_arg => 'type',
);

=head1 STATEMENT PROPERTIES

=head2 limit

The dialect of the LIMIT clause.

    offset (postgresql, sqlite)
    xy     (mysql)

=head2 returning

The dialect of INSERT/UPDATE/DELETE ... RETURNING syntax.

    into   (oracle)
    select (postgresql)

=head1 DATABASE PROPERTIES

=head2 sequences

Whether the database supports sequences.

    postgresql
    oracle

=head1 FUNCTION PROPERTIES

=head2 last_insert_id

Whether the LAST_INSERT_ID() function is supported.

    mysql

=head2 last_insert_rowid

Whether the LAST_INSERT_ROWID() function is supported.

    sqlite

=head1 OTHER PROPERTIES

=head2 rownum

Returns true if the dialect supports the rownum pseudo column.

    oracle

=head2 quote_char

The character that is used to quote identifiers, such as table and column
names.

=head2 sep_char

The character that is used to separate linked identifiers, such as
a table name followed by a column name.

=cut

{
    my $feature_quirks = {};
    foreach my $dialect (values %$dialects) {
        while (my($feature, $quirk) = each %$dialect) {
            my $quirks = $feature_quirks->{$feature} ||= [];
            push @$quirks, $quirk;
        }
    }

    my $meta = __PACKAGE__->meta();
    while (my($feature, $quirks) = each %$feature_quirks) {
        $quirks = [ uniq sort @$quirks ];

        my $type = "SQL::Dialect::FeatureTypes::$feature";
        if (@$quirks == 1) {
            subtype $type,
                as 'Str',
                where { $_ eq $quirks->[0] };
        }
        else {
            subtype $type,
                as enum( $quirks );
        }

        $meta->add_attribute(
            $feature,
            is         => 'ro',
            isa        => "Maybe[$type]",
            lazy_build => 1,
        );

        $meta->add_method(
            "_build_$feature",
            sub{
                my ($self) = @_;
                return $dialects->{ $self->type() }->{ $feature };
            },
        );
    }
}

=head1 METHODS

=head2 supports

    # Do something if the dialect supports any form of limit and
    # only the select flavor of returning:
    if ($dialect->supports('limit', 'returning-select')) { ... }

Given a list of feature names, optionally dash-suffixed with a specific quirk, this will
return true or false if the dialect supports them all.

=cut

sub supports {
    my ($self, @strings) = @_;

    foreach my $string (@strings) {
        my ($feature, $wanted_quirk) = split(/-/, $string);

        my $actual_quirk = $self->$feature();

        if (!$wanted_quirk) {
            return 0 if !defined $actual_quirk;
        }
        else {
            next unless defined($wanted_quirk) or defined($actual_quirk);
            return 0 if !defined($wanted_quirk);
            return 0 if !defined($actual_quirk);
            return 0 if $wanted_quirk ne $actual_quirk;
        }
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 TODO

=over

=item * A more complete test suite.

=item * Add more dialects and supported DBI drivers!  If anyone wants
to help with this I'd greatly appreciate it.

=item * Add more information about other quirks that the dialects have,
such as whether PLSQL is supported, what kind of bulk loading interface
is available (MySQL's LOAD INFILE versus O;racle SQL*Loader, etc), information
about what functions to use for date math, which DBD drivers return the
number of records inserted/deleted/selected, etc.

=back

=head1 CONTRIBUTING

If you'd like to contribute bug fixes, enhancements, additional test covergage,
or documentation to this module then by all means do so.  You can fork this
repository using L<github|https://github.com/bluefeet/SQL-Dialect> and
then send the author a pull request.

Please contact the author if you are considering doing this and discuss your ideas.

=head1 SUPPORT

Currently there is no particular mailing list or IRC channel for this project.
You can shoot the author an e-mail if you have a question.

If you'd like to report an issue you can use github's
L<issue tracker|https://github.com/bluefeet/SQL-Dialect/issues>.

=head1 REFERENCES

=over

=item * L<Comparison of different SQL implementations|http://troels.arvin.dk/db/rdbms/>

=item * L<SQL (Wikipedia)|http://en.wikipedia.org/wiki/Sql>

=item * L<The SQL-92 Standard|http://www.contrib.andrew.cmu.edu/~shadow/sql/sql1992.txt>

=back

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

