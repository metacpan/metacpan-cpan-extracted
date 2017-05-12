package SQL::TwoWay;
use strict;
use warnings FATAL => 'recursion';
use 5.010001; # Named capture
our $VERSION = "0.05";
use Carp ();
use Scalar::Util qw(reftype);

use parent qw(Exporter);

our @EXPORT = qw(two_way_sql);

our ($TOKEN_STR2ID, $TOKEN_ID2STR);
BEGIN {
    $TOKEN_STR2ID = +{
        VARIABLE => 1,
        SQL      => 2,
        IF       => 3,
        ELSE     => 4,
        END_     => 5,
    };
    $TOKEN_ID2STR = +{ reverse %$TOKEN_STR2ID };
}
use constant $TOKEN_STR2ID;

sub token2str {
    $TOKEN_ID2STR->{+shift}
}

sub two_way_sql {
    my ($sql, $params) = @_;

    my $tokens = tokenize_two_way_sql($sql);
    my $ast = parse_two_way_sql($tokens);
    my ($generated_sql, @binds) = process_two_way_sql($ast, $params);
    return ($generated_sql, @binds);
}

sub process_two_way_sql {
    my ($ast, $params) = @_;
    my ($sql, @binds);
    for my $node (@$ast) {
        if ($node->[0] eq IF) {
            my $name = $node->[1];
            unless (exists $params->{$name}) {
                Carp::croak("Unknown parameter for IF stmt: $name");
            }
            if ($params->{$name}) {
                my ($is, @ib) = process_two_way_sql($node->[2], $params);
                $sql .= $is;
                push @binds, @ib;
            } else {
                my ($is, @ib) = process_two_way_sql($node->[3], $params);
                $sql .= $is;
                push @binds, @ib;
            }
        } elsif ($node->[0] eq VARIABLE) {
            my $name = $node->[1];
            unless (exists $params->{$name}) {
                Carp::croak("Unknown parameter: $name");
            }

            if (reftype($params->{$name}) eq 'ARRAY') {
                $sql .= '('. join(',', ('?')x@{$params->{$name}}) .')';
                push @binds, @{$params->{$name}};
            } else {
                $sql .= '?';
                push @binds, $params->{$name};
            }
        } elsif ($node->[0] eq SQL) {
            $sql .= $node->[1];
        } else {
            Carp::croak("Unknown node: " . token2str($node->[0]));
        }
    }
    return ($sql, @binds);
}

sub parse_two_way_sql {
    my ($tokens) = @_;
    my @ast;
    while (@$tokens > 0) {
        push @ast, _parse_stmt($tokens);
    }
    return \@ast;
}

sub _parse_statements {
    my ($tokens) = @_;

    my @stmts;
    while (@$tokens && (
            $tokens->[0]->[0] == SQL
        ||  $tokens->[0]->[0] == VARIABLE
        ||  $tokens->[0]->[0] == IF
    )) {
        push @stmts, _parse_stmt($tokens);
    }
    return \@stmts;
}

sub _parse_stmt {
    my ($tokens) = @_;

    if ($tokens->[0]->[0] eq SQL || $tokens->[0]->[0] eq VARIABLE) {
        my $token = shift @$tokens;
        return [
            $token->[0],
            $token->[1]
        ];
    } elsif ($tokens->[0]->[0] eq IF) {
        return _parse_if_stmt($tokens);
    } else {
        Carp::croak("Unexpected token: " . token2str($tokens->[0]->[0]));
    }
}

sub _parse_if_stmt {
    my ($tokens) = @_;

    # IF
    my $if = shift @$tokens;

    # Parse statements
    my $if_block = _parse_statements($tokens);

    # ELSE block
    my $else_block = [];
    if ($tokens->[0]->[0] eq ELSE) {
        shift @$tokens; # remove ELSE
        $else_block = _parse_statements($tokens);
    }

    # And, there is END_
    unless ($tokens->[0]->[0] eq END_) {
        Carp::croak("Unexpected EOF in IF statement");
    }
    shift @$tokens; # remove END_

    return [
        IF, $if->[1], $if_block, $else_block
    ];
}

sub tokenize_two_way_sql {
    my $sql = shift;

    my @ret;
    my $NUMERIC_LITERAL = "-? [0-9.]+";
    my $STRING_LITERAL = q{ (?:
                                "
                                    (?:
                                        \\\\"
                                        | ""
                                        | [^"]
                                    )*
                                "
                                |
                                '
                                    (?:
                                        \\\\'
                                        | ''
                                        | [^']
                                    )*
                                '
                            ) };
    my $LITERAL = "(?: $STRING_LITERAL | $NUMERIC_LITERAL )";
    my $SINGLE_SLASH = '/ (?! \*)';
    $sql =~ s!
        # Variable /* $var */3
        (
            /\* \s+ \$ (?<variable> [A-Za-z0-9_-]+) \s+ \*/
            (?:
                # (3,2,4)
                $LITERAL | \(
                    (?: \s* $LITERAL \s* , \s* )*
                    $LITERAL
                \)
            )
        )
        |
        (?:
            /\* \s+ IF \s+ \$ (?<ifcond> [A-Za-z0-9_-]+) \s+ \*/
        )
        |
        (?<else>
            /\* \s+ ELSE \s+ \*/
        )
        |
        (?<end>
            /\* \s+ END \s+ \*/
        )
        |
        # Normal SQL strings
        (?<sql1> [^/]+ )
        |
        # Single slash character
        (?<sql2> $SINGLE_SLASH )
    !
        if (defined $+{variable}) {
            push @ret, [VARIABLE, $+{variable}]
        } elsif (defined $+{ifcond}) {
            push @ret, [IF, $+{ifcond}]
        } elsif (defined $+{else}) {
            push @ret, [ELSE]
        } elsif (defined $+{end}) {
            push @ret, [END_]
        } elsif (defined $+{sql1}) {
            push @ret, [SQL, $+{sql1}]
        } elsif (defined $+{sql2}) {
            push @ret, [SQL, $+{sql2}]
        } else {
            Carp::croak("Invalid sql: $sql");
        }
        ''
    !gex;

    return \@ret;
}

1;
__END__

=head1 NAME

SQL::TwoWay - Run same SQL in valid SQL and DBI placeholder.

=head1 SYNOPSIS

    use SQL::TwoWay;

    my $name = 'STARTING OVER';
    my ($sql, @binds) = two_way_sql(
        q{SELECT *
        FROM cd
        WHERE name=/* $name */"MASTERPIECE"}, {
        name => $name,
    });

    # $sql: SELECT * FROM cd WHERE name=?
    # $binds[0] = 'STARTING OVER'

=head1 DESCRIPTION

SQL::TwoWay is a way to support 2way SQL.

I guess building complex SQL using O/R Mapper or SQL builder, like SQL::Abstract is worth.
When you writing complex SQL, you should write SQL by your hand.

And then, you got a issue: "I can't run my query on MySQL console!". Yes.
A query like C<< SELECT * FROM cd WHERE name=? >> is not runnable on console because that contains placeholder.

So, the solution is SQL::TwoWay.

You can write a query like this.

    SELECT * FROM cd WHERE name=/* $name */"MASTERPIECE";

This query is 100% valid SQL.

And you can make C<<$sql>> and C<<@binds>> from this query. C<< SQL::TwoWay::two_way_sql() >> function convert this query.

Here is a example code:

    my ($sql, @binds) = two_way_sql(
        q{SELECT * FROM cd WHERE name=/* $name */"MASTERPIECE"},
        {
            name => 'STARTING OVER'
        }
    );

C<< $sql >> is:

    SELECT * FROM cd WHERE name=?;

And C<< @binds >> is:

    ('STARTING OVER')

So, you can use same SQL in MySQL console and Perl code. It means B<2way SQL>.

=head1 SYNTAX

=over 4

=item /* $var */4

=item /* $var */(1,2,3)

=item /* $var */"String"

Replace variables.

=item /* IF $cond */n=3/* ELSE */n=5/* END */

=item /* IF $cond */n=3/* END */

=back

=head1 PSEUDO BNF

    if : /* IF $var */
    else : /* ELSE */
    end : /* END */
    variable : /* $var */ literal
    literal: TBD
    sql : .

    root = ( stmt )+
    stmt = sql | variable | if_stmt
    if_stmt = "IF" statement+ "ELSE" statement+ "END"
            | "IF" statement+ "END"

=head1 LICENSE

Copyright (C) tokuhirom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<s2dao|http://s2dao.seasar.org/en/index.html> supports 2 way SQL in Java.

