package SQL::OOP;
use strict;
use warnings;
use Scalar::Util qw(blessed);
use SQL::OOP::Base;
use 5.005;
our $VERSION = '0.21';

sub new {
    my $class = shift;
    return SQL::OOP::Base->new(@_);
}

sub quote_char {
    my $class = shift;
    return SQL::OOP::Base->quote_char(@_);
}

sub escape_code_ref {
    my $class = shift;
    return SQL::OOP::Base->escape_code_ref(@_);
}

1;

__END__

=head1 NAME

SQL::OOP - Yet another SQL Generator

=head1 SYNOPSIS

    my $select = SQL::OOP::Select->new;
    
    $select->set(
        $select->ARG_FIELDS => '*',
        $select->ARG_FROM   => SQL::OOP::ID->new('public', 'master'),
        $select->ARG_WHERE  => sub {
            my $where = SQL::OOP::Where->new;
            return $where->and(
                $where->cmp('=', 'a', 1),
                $where->cmp('=', 'b', 1),
            )
        },
        $select->GROUP_BY => 'field1',
        $select->ARG_LIMIT => 10,
    );

=head1 DESCRIPTION

SQL::OOP provides an object oriented interface for generating SQL statements.
This is an alternative to SQL::Abstract but doesn't require any complex
syntactical hash structure. All you have to do
is to call well-readable OOP methods. Moreover, if you use IDE for coding Perl,
the auto completion and call tips may work well with this.

SQL::OOP distribution consists of following modules. The indentation indicates
the hierarchy of inheritance.
    
    SQL::OOP::Base [abstract]
        SQL::OOP::Array [abstract]
            SQL::OOP::ID
                SQL::OOP::IDArray
            SQL::OOP::Order
            SQL::OOP::Dataset
            SQL::OOP::Command [abstract]
                SQL::OOP::Select
                SQL::OOP::Insert
                SQL::OOP::Update
                SQL::OOP::Delete
            SQL::OOP::Order
    SQL::OOP::Where [factory]

=head2 Base architecture

Any instance of the classes above are capable of to_string() and bind().
These methods returns similar values as SQL::Abstract, which can be thrown at
DBI methods. 

    my $string = $any->to_string;
    my @values = $any->bind
    
Most class inherits SQL::OOP::Array which can contain array of SQL::OOP::Base.
This means they can recursively contain any others. For example, SELECT command
instance can be part of other SELECT command. Since the instances are
well-encapsulated, you can manipulate them flexibly.

All class of this distribution inherits SQL::OOP::Base class.

    my $snippet1 = SQL::OOP::Base->new('a = ?', [1]);
    my $snippet2 = SQL::OOP::Base->new('b = ?', [2]);

Any instance can be part of any others.
    
    my $array1 = SQL::OOP::Array->new($snippet1, $snippet2);
    $array1->set_sepa(', ');
    
    warn $array1->to_string; ## a = ?, b = ?
    warn join ',', $array1->bind; ## 1,2

Even arrays can contain arrays.
    
    my $array2 = SQL::OOP::Array->new($array1, $snippet1);
    $array2->set_sepa(', ');
    
    warn $array2->to_string; ## (a = ?, b = ?), a = ?
    warn join ',', $array2->bind; ## 1,2,1

This is an example of WHERE clause.

    my $util = SQL::OOP::Where->new; ## for convenience
    
    my $cond1 = $util->cmp('<', 'price', '100');
    my $cond2 = $util->cmp('=', 'category', 'book');
    my $and = $util->and($cond1, $cond2);
    
    my $sql1 = $and->to_string # price < ? AND category = ?

$cond1 and $cond2 are SQL::OOP::Base instances. $and which is a SQL::OOP::Array
instance can contain $cond1 and $cond2.
    
    my $cond3 = $util->cmp('like', 'title', '%Perl%');
    my $or = $util->or($and, $cond3);
    
    my $sql2 = $and->to_string # (price < ? AND category = ?) OR title like ?

$or is a SQL::OOP::Array instance which can contain both SQL::OOP::Base and
SQL::OOP::Array.

=head2 Code reference for arguments

All new constructors, append methods for array sub classes, and set methods for
command sub classes are capable of code refs for arguments instead of string or
objects so that you can encapsulate temporary things inside of it.
    
    $select->set(
        $select->ARG_WHERE  => sub {
            if ($cond_exist) {
                my $tmp = $cond_exist;
                
                # DO SOMETHING to $tmp
                
                return SQL::OOP::Where->cmp('=', 'field', $tmp);
            } else {
                return;
            }
        },
    );

=head2 Undefined values

This module doesn't always output undef for undef in input.
Following example indicates undef in bind value doesn't appear in output but
to_string returns right string.

    my $elem = SQL::OOP::Base->new('field', undef);
    
    print $elem->to_string; ## field
    print scalar $elem->bind; ## 0

On the other hand, undef values for array elements are totally omitted. 

    my $elem1 = SQL::OOP::Base->new('field1', 1);
    my $elem2 = undef;
    my $elem3 = SQL::OOP::Base->new('field3', 3);
    my $array = SQL::OOP::Array->new($elem1, $elem2, $elem3);
    print $array->to_string; ## field1field3
    print $array->bind; ## 13

WHERE factory methods omits undef for field names.

    my $util = SQL::OOP::Where->new;
    my $cond = $util->cmp('=', undef, '1'); ## undef

This system makes things easy. The following two functions works well and you
don't have to worry about undef.

    generate_where(1,2,3)
    generate_where(1,2)
    generate_where(1)
    
    sub generate_where {
        my ($value1, $value2, $value3) = @_;
        my $util = SQL::OOP::Where->new;
        my $cond1 = $util->cmp('=', 'field', $value1); ## This may be undef
        my $cond2 = $util->cmp('=', 'field', $value2); ## This may be undef
        my $cond3 = $util->cmp('=', 'field', $value3); ## This may be undef
        my $and = $util->and($cond1, $cond2, $cond3);
        return $and;
    }
    
    generate_select(generate_where(1), 50)
    generate_select(generate_where(1))
    generate_select(50)
    
    sub generate_select {
        my ($where, $limit) = @_;
        my $select = SQL::OOP::Select->new;
        $select->set(
            $select->ARG_FIELDS => '*',
            $select->ARG_FROM   => 'main',
            $select->ARG_WHERE  => $where,  ## This may be undef
            $select->ARG_LIMIT  => $limit,  ## This may be undef
        );
        return $select;
    }

If you need to compare something to NULL in WHERE clause, you can use specific
methods.

    my $cond1 = $util->is_null('field');
    my $cond2 = $util->is_not_null('field');

The Only exception is the Dataset class for this system. Dataset can contain
undef for value and explicitly output undefs to make DBI treats them as NULL.

=head2 Room for extreme complexity

If you need very complex SQL generation such as functions or conditional
branches, you can always resort to string.

    $select->set(
        $select->ARG_FIELDS     => '*', 
        $select->ARG_FROM       => 'main', 
        $select->ARG_ORDERBY    => q{
            abs(date("timestamp") - date('now')) DESC
        }
    );

The following is use of string in WHERE element.

    my $util = SQL::OOP::Where->new;
    my $cond1 = $util->cmp('=', 'a','b');
    my $cond2 = $util->cmp('=', 'a','b');
    my $cond3 = 'date("t1") > date("t2")';
    my $and = $util->and($cond1, $cond2, $cond3);
    warn $and->to_string; ## "a" = ? AND "a" = ? AND date("t1") > date("t2")

=head1 METHODS

The following methods are all aliases to SQL::OOP::Base class methods.

=head2 SQL::OOP->new

This is an alias for SQL::OOP::Base->new

=head2 SQL::OOP->quote_char

This is an alias for SQL::OOP::Base->quote_char

=head2 SQL::OOP->escape_code_ref

This is an alias for SQL::OOP::Base->escape_code_ref

=head1 SEE ALSO

L<DBI>, L<SQL::Abstract>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jamadam.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
