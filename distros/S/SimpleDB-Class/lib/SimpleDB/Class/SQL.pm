package SimpleDB::Class::SQL;
BEGIN {
  $SimpleDB::Class::SQL::VERSION = '1.0503';
}

=head1 NAME

SimpleDB::Class::SQL - SQL generation tools for SimpleDB.

=head1 VERSION

version 1.0503

=head1 DESCRIPTION

This class is used to generate the SQL needed for the Select operation on SimpleDB's web service.

=head1 METHODS

The following methods are available from this class.

=cut

use Moose;
use JSON;
use DateTime;
use DateTime::Format::Strptime;
use Clone qw(clone);

#--------------------------------------------------------

=head2 new ( params )

Constructor. 

=head3 params

A hash of options you can pass in to the constructor.

=head4 item_class

A L<SimpleDB::Class::Item> subclass name. This is required.

=head4 simpledb

A reference to the L<SimpleDB::Class> object. This is required.

=head4 output

Defaults to '*'. Alternatively you can pass a string of 'count(*)' or an attribute. Or you can pass an array ref of attributes.

=head4 where

A hash reference containing a series of clauses. Here are some examples and what the resulting queries would be. You can of course combine all these options to create your own queries.

B<NOTE:> If you want to search on an item's id (or ItemName) then you should use the C<itemName()> function as the id doesn't actually exist in the item's data.

Direct comparison.

 { foo => 1 }

 select * from domain where foo=1

 { foo => 1, bar => 2 }

 select * from domain where foo=1 and bar=2

 { foo => [ '>', 5 ] } # '=', '!=', '>', '<', '<=', '>='

 select * from domain where foo > 5

Direct comparison with an or clause.

 { -or => {  foo => 1, bar => 2 } }
 
 select * from domain where (foo=1 or bar=2)

Find all items where these attributes intersect.

 { -intersection => {  foo => 1, bar => 2 } }
 
 select * from domain where (foo=1 intersection bar=2)

Combining OR and AND.

 { -or => {  foo => 1, -and => { this => 'that', bar => 2 } }
 
 select * from domain where (foo=1 or ( this='that' and bar=2 ))

Finding within a range.

 { foo=>['between', 5, 10] }

 select * from domain where foo between 5 and 10

Finding within a set.

 { foo => ['in', 1, 3, 5, 7 ] }

 select * from domain where foo in (1, 3, 5, 7)

Finding in a set where every item returned matches all members of the set.

 { foo => ['every', 1, 3, 5, 7 ] }

 select * from domain where every(foo) in (1, 3, 5, 7)

String comparisons. You can match on either side of the string ('%this', 'that%') or both ('%this%'). Note that matching at the beginning or both sides of the string is a slow operation.

 { foo => [ 'like', 'this%' ] } # 'not like'

 select * from domain where foo like 'this%'

Null comparisons. These are very slow. Try inserting 'Null' or 'None' into a field and do string comparisons rather than null comparisons.

 { foo => 'is null' } # 'is not null'

 select * from domain where foo is null

=head4 order_by

An attribute to order the result set by, defaults to ascending order. Can also pass in an array ref containing an attribute and 'desc' or 'asc'. If an array ref is passed in containing only an attribute name it is an implied descending order.

 "foo"

 ["foo","desc"]

 ["foo"]

=head4 limit

An integer of a number of items to limit the result set to.

=cut

#--------------------------------------------------------

=head2 output ()

Returns what was passed into the constructor for the output field.

=cut

has output => (
    is              => 'ro',
    default         => '*',
);

#--------------------------------------------------------

=head2 simpledb ()

Returns the reference passed into the constructor.

=cut

has simpledb => (
    is          => 'ro',
    required    => 1,
);

#--------------------------------------------------------

=head2 item_class ()

Returns what was passed into the constructor for the item_class field.

=cut

has item_class => (
    is              => 'ro',
    required        => 1,
);

#--------------------------------------------------------

=head2 where ()

Returns what was passed into the constructor for the where field.

=head2 has_where()

Returns a boolean indicating whether a where clause has been set.

=cut

has where => (
    is              => 'ro',
    predicate       => 'has_where',
);

#--------------------------------------------------------

=head2 order_by ()

Returns what was passed into the constructor for the output field.

=head2 has_order_by ()

Returns a boolean indicating whether an order by clause has been set.

=cut

has order_by => (
    is              => 'ro',
    predicate       => 'has_order_by',
);

#--------------------------------------------------------

=head2 limit ()

Returns what was passed into the constructor for the output field.

=head2 has_limit ()

=cut

has limit => (
    is              => 'ro',
    predicate       => 'has_limit',
);

#--------------------------------------------------------

=head2 quote_value ( string )

Escapes ' and " in values.  If C<itemName()> is what's passed in, it will not be quoted.


=head3 string

The value to escape.

=cut

sub quote_value {
    my ($self, $string) = @_;
    $string =~ s/'/''/g;
    $string =~ s/"/""/g;
    return "'".$string."'";
}

#--------------------------------------------------------

=head2 quote_attribute ( string )

Escapes an attribute with so that it can contain spaces and other special characters by wrapping it in backticks `. If C<itemName()> is what's passed in, it will not be quoted.

=head3 string

The attribute name to escape.

=cut

sub quote_attribute {
    my ($self, $string) = @_;
    if ($string eq 'itemName()') {
        return $string;
    }
    $string =~ s/`/``/g;
    return "`".$string."`";
}

#--------------------------------------------------------

=head2 recurese_where ( constraints, [ op ] )

Traverses a where() hierarchy and returns a stringified SQL version of the where clause.

=head3 constraints

A portion of a where hierarchy, perhaps broken off from the main for detailed analysis.

=head3 op

If it's a chunk broken off, -and, -or, -intersection then the operator will be passed through here. 

=cut

sub recurse_where {
    my ($self, $constraints, $op) = @_;
    $op ||= ' and ';
    my @sets;
    foreach my $key (keys %{$constraints}) {
        if ($key eq '-and') {
            push @sets, '('.$self->recurse_where($constraints->{$key}, ' and ').')';
        }
        elsif ($key eq '-or') {
            push @sets, '('.$self->recurse_where($constraints->{$key}, ' or ').')';
        }
        elsif ($key eq '-intersection') {
            push @sets, '('.$self->recurse_where($constraints->{$key}, ' intersection ').')';
        }
        else {
            my $value = $constraints->{$key};
            my $item_class = $self->item_class;
            my $attribute = $self->quote_attribute($key);
            if (ref $value eq 'ARRAY') {
                my $cmp = shift @{$value};
                if ($cmp eq '>') {
                    push @sets, $attribute.' > '.$self->quote_value($item_class->stringify_value($key, $value->[0]));
                }
                elsif ($cmp eq '<') {
                    push @sets, $attribute.' < '.$self->quote_value($item_class->stringify_value($key, $value->[0]));
                }
                elsif ($cmp eq '<=') {
                    push @sets, $attribute.' <= '.$self->quote_value($item_class->stringify_value($key, $value->[0]));
                }
                elsif ($cmp eq '>=') {
                    push @sets, $attribute.' >= '.$self->quote_value($item_class->stringify_value($key, $value->[0]));
                }
                elsif ($cmp eq '!=') {
                    push @sets, $attribute.' != '.$self->quote_value($item_class->stringify_value($key, $value->[0]));
                }
                elsif ($cmp eq 'like') {
                    push @sets, $attribute.' like '.$self->quote_value($item_class->stringify_value($key, $value->[0]));
                }
                elsif ($cmp eq 'not like') {
                    push @sets, $attribute.' not like '.$self->quote_value($item_class->stringify_value($key, $value->[0]));
                }
                elsif ($cmp eq 'in') {
                    my @values = map {$self->quote_value($item_class->stringify_value($key, $_))} @{$value};
                    push @sets, $attribute.' in ('.join(', ', @values).')';
                }
                elsif ($cmp eq 'every') {
                    my @values = map {$self->quote_value($item_class->stringify_value($key, $_))} @{$value};
                    push @sets, 'every('.$attribute.') in ('.join(', ', @values).')';
                }
                elsif ($cmp eq 'between') {
                    push @sets, $attribute.' between '.$self->quote_value($item_class->stringify_value($key, $value->[0]))
                        .' and '.$self->quote_value($item_class->stringify_value($key, $value->[1]));
                }
            }
            else {
                my $value = $constraints->{$key};
                if ($value eq 'is null') {
                    push @sets, $attribute.' is null';
                }
                elsif ($value eq 'is not null') {
                    push @sets, $attribute.' is not null';
                }
                else {
                    push @sets, $attribute.' = '.$self->quote_value($item_class->stringify_value($key, $value));
                }
            }
        }
    }
    return join($op, @sets);
}

#--------------------------------------------------------

=head2 to_sql ( ) 

Returns the entire query as a stringified SQL version.

=cut

sub to_sql {
    my ($self) = @_;

    # output
    my $output = $self->output;
    if (ref $output eq 'ARRAY') {
        my @fields = map {$self->quote_attribute($_)} @{$output};
        $output = join ', ', @fields;
    }
    elsif ($output ne '*' && $output ne 'count(*)') {
        $output = $self->quote_attribute($output);
    }

    # where
    my $where='';
    if ($self->has_where) {
        $where = $self->recurse_where(clone($self->where));
        if ($where ne '') {
            $where = ' where '.$where;
        }
    }

    # sort
    my $sort='';
    if ($self->has_order_by) {
        my $by = $self->order_by;
        my $direction = 'asc';
        if (ref $by eq 'ARRAY') {
            ($by, $direction) = @{$by};
            $direction ||= 'desc';
        }
        $sort = ' order by '.$self->quote_attribute($by).' '.$direction;
    }

    # limit
    my $limit='';
    if ($self->has_limit) {
        $limit = ' limit '.$self->limit;
    }

    return 'select '.$output.' from '.$self->quote_attribute($self->simpledb->add_domain_prefix($self->item_class->domain_name)).$where.$sort.$limit;
}


=head1 LEGAL

SimpleDB::Class is Copyright 2009-2010 Plain Black Corporation (L<http://www.plainblack.com/>) and is licensed under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;