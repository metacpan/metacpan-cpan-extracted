package Search::Query::Dialect;
use Moo;
use Carp;
use Data::Dump qw( dump );
use overload
    '""'     => sub { $_[0]->stringify; },
    'bool'   => sub {1},
    fallback => 1;

use Data::Transformer;
use Scalar::Util qw( blessed );
use Types::Standard qw( Int Undef );
use Type::Utils qw( declare as where coerce inline_as from );
use namespace::autoclean;

my $PositiveInt = declare
    as Int,
    where { defined($_) and $_ >= 0 },
    inline_as {"defined($_) and $_ =~ /^[0-9]\$/ and $_ >= 0"};

coerce $PositiveInt, from Int, q{ abs( $_ || $ENV{PERL_DEBUG} || 0) },
    from Undef, q{ 0 };

has default_field => ( is => 'rw' );
has parser        => ( is => 'ro' );
has debug         => (
    is      => 'rw',
    isa     => $PositiveInt,
    lazy    => 1,
    coerce  => $PositiveInt->coercion,
    builder => '_init_debug',
);

sub _init_debug { $ENV{PERL_DEBUG} || 0 }

our $VERSION = '0.307';

=head1 NAME

Search::Query::Dialect - abstract base class for query language dialects

=head1 SYNOPSIS

 my $query = Search::Query->parser->parse('foo');
 print $query;

=head1 DESCRIPTION

Search::Query::Dialect is the base class from which all query dialects
inherit.

A Dialect subclass must implement at least two methods:

=over

=item stringify

Returns the serialized query tree.

=item stringify_clause( I<leaf> )

Returns one clause of a serialized query tree.

=back

See Search::Query::Dialect::Native for a working example.

=head1 METHODS

=head2 debug

Get/set flag.

=head2 default_field

Standard attribute accessor. Default value is undef.

=head2 init 

B<DEPRECATED>. Use BUILD() instead.

=cut

sub init {
    my $self = shift;
    confess "Use BUILD() instead of init()";
}

=head2 stringify

All subclasses must override this method. The default behavior is to croak.

=cut

sub stringify { croak "must implement stringify() in $_[0]" }

=head2 tree

Returns the query Dialect instance as a hashref structure, similar
to that of Search::QueryParser.

=cut

sub tree {
    my $self = shift;
    my $clause_class
        = $self->parser
        ? $self->parser->clause_class
        : 'Search::Query::Clause';
    my $dialect_class = blessed($self);
    my %tree;

    #warn "before tree: " . dump($self);
    foreach my $prefix ( '+', '', '-' ) {
        next if !exists $self->{$prefix};
        my @clauses;
        for my $clause ( @{ $self->{$prefix} } ) {

            if ( !blessed($clause) ) {
                croak "unblessed clause in Dialect object: " . dump($clause);
            }

            if ( $clause->can('tree') ) {

                #warn "clause isa Dialect: " . dump($clause);
                push @clauses, $clause->tree;
            }
            elsif ( blessed( $clause->value ) ) {

                #warn "clause->value isa Dialect: " . dump($clause);
                my $clause_ref = {%$clause};
                $clause_ref->{value} = $clause->{value}->tree;
                push @clauses, $clause_ref;
            }
            else {

                #warn "clause isa Clause: " . dump($clause);
                push @clauses, {%$clause};
            }
        }
        $tree{$prefix} = \@clauses;
    }

    #warn "after tree: " . dump( \%tree );

    return \%tree;
}

=head2 walk( I<CODE> )

Traverse a Dialect object, calling I<CODE> on each Clause.
The I<CODE> reference should expect 4 arguments:

=over

=item

The Clause object.

=item

The Dialect object.

=item

The I<CODE> reference.

=item

The prefix ("+", "-", and "") for the Clause.

=back

=cut

sub walk {
    my $self = shift;
    my $code = shift;
    if ( !$code or !ref($code) or ref($code) ne 'CODE' ) {
        croak "CODE ref required";
    }
    my $tree = shift || $self;
    foreach my $prefix ( '+', '', '-' ) {
        next if !exists $tree->{$prefix};
        for my $clause ( @{ $tree->{$prefix} } ) {

            #warn "clause: " . dump $clause;
            $code->( $clause, $tree, $code, $prefix );
        }
    }
    return $tree;
}

=head2 translate_to( I<dialect> )

Translate from one Dialect to another. Returns an object
blessed into the I<dialect> class.

=cut

sub translate_to {
    my $self         = shift;
    my $dialect      = shift or croak "Dialect required";
    my $query_class  = Search::Query->get_dialect($dialect);
    my $copy         = $self->tree;
    my $new_dialect  = bless( $copy, $query_class );
    my $clause_class = $self->parser->clause_class;
    my $code         = sub {
        my ( $clause, $dialect, $sub, $prefix ) = @_;

        #warn "before: " . dump($clause);
        if ( exists $clause->{field} ) {

            #warn "clause: " . dump $clause;
            $clause = bless( $clause, $clause_class );
        }
        else {
            $clause = bless( $clause, $query_class );
            $clause->walk($sub);
        }

        #warn "after : " . dump($clause);
    };
    $new_dialect->walk($code);
    return $new_dialect;
}

=head2 add_or_clause( I<clause> )

Add I<clause> as an "or" leaf to the Dialect object.

=cut

sub add_or_clause {

    # DO NOT shift
    my $self   = $_[0];
    my $clause = $_[1] or croak "Clause object required";
    my $str    = "($self) OR ($clause)";
    $_[0] = $self->parser->parse($str);
    return $_[0];
}

=head2 add_and_clause( I<clause> )

Add I<clause> as an "and" leaf to the Dialect object.

=cut

sub add_and_clause {

    # DO NOT shift
    my $self   = $_[0];
    my $clause = $_[1] or croak "Clause object required";
    my $str    = "($self) AND ($clause)";
    $_[0] = $self->parser->parse($str);
    return $_[0];
}

=head2 add_not_clause( I<clause> )

Add I<clause> as a "not" leaf to the Dialect object.

=cut

sub add_not_clause {

    # DO NOT shift
    my $self   = $_[0];
    my $clause = $_[1] or croak "Clause object required";
    my $str    = "($self) NOT ($clause)";
    $_[0] = $self->parser->parse($str);
    return $_[0];
}

=head2 add_sub_clause( I<clause> )

Add I<clause> as a sub clause to the Dialect object. In this
case, I<clause> should also be a Dialect object.

=cut

sub add_sub_clause {

    # DO NOT shift
    my $self     = $_[0];
    my $self_ref = \$_[0];
    my $clause   = $_[1];
    if (   !$clause
        or !blessed($clause)
        or !$clause->isa('Search::Query::Dialect') )
    {
        croak "Dialect object required";
    }
    my %methods = (
        ""  => 'add_or_clause',
        "+" => 'add_and_clause',
        "-" => 'add_not_clause',
    );
    $clause->walk(
        sub {
            my ( $subclause, $dialect, $code, $prefix ) = @_;
            my $method = $methods{$prefix};
            $$self_ref = $self->$method($subclause);
        }
    );

}

=head2 field_class

Should return the name of the Field class associated with the Dialect.
Default is 'Search::Query::Field'.

=cut

sub field_class {'Search::Query::Field'}

=head2 get_default_field

Returns the default field for this Dialect.

=cut

sub get_default_field {
    my $self  = shift;
    my $field = $self->default_field;
    $field = $self->parser->default_field unless defined $field;
    if ( !defined $field ) {
        confess "must define a default_field";
    }
    return ref $field ? $field : [$field];
}

=head2 get_field( I<field_name> )

Returns a Field object instance for I<field_name>. The object
will be an instance of B<field_class>.

This is a shorthand wrapper around the method of the same
name in the internal B<parser> object.

=cut

sub get_field {
    my $self  = shift;
    my $name  = shift or croak "field name required";
    my $field = $self->parser->get_field($name);
    if ( !$field ) {
        if ( $self->parser->croak_on_error ) {
            confess "invalid field name: $name";
        }
        my $field_class = $self->field_class;
        $field = $field_class->new( name => $name );
    }
    return $field;
}

=head2 preprocess( I<query_string> )

Called by Parser in parse() before actually building the Dialect object
from I<query_string>.

This allows for any "cleaning up" or other munging of I<query_string>
to support the official Parser syntax.

The default just returns I<query_string> untouched. Subclasses should
return a parseable string.

=cut

sub preprocess { return $_[1] }

=head2 parser

Returns the Search::Query::Parser object that generated the Dialect
object.

=cut

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-query at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Query>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Query


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Query>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Query>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Query>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Query/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
