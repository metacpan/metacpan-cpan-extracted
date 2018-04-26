package Pcore::Handle::DBI::Query::WHERE;

use Pcore -const, -class;
use Pcore::Util::Scalar qw[is_ref is_plain_scalarref is_arrayref is_plain_arrayref is_plain_hashref is_blessed_arrayref is_blessed_hashref];

use overload    #
  q[&] => sub {
    my $w0_is_empty = !$_[0]->_is_not_empty;
    my $w1_is_empty = !$_[1]->_is_not_empty;

    if ( $w0_is_empty && $w1_is_empty ) {
        return $_[0];
    }
    elsif ( !$w0_is_empty && $w1_is_empty ) {
        return $_[0];
    }
    elsif ( $w0_is_empty && !$w1_is_empty ) {
        return $_[1];
    }
    else {
        return bless { _is_not_empty => 1, _buf => [ $_[0], 'AND', $_[1] ] }, __PACKAGE__;
    }
  },
  q[|] => sub {
    my $w0_is_empty = !$_[0]->_is_not_empty;
    my $w1_is_empty = !$_[1]->_is_not_empty;

    if ( $w0_is_empty && $w1_is_empty ) {
        return $_[0];
    }
    elsif ( !$w0_is_empty && $w1_is_empty ) {
        return $_[0];
    }
    elsif ( $w0_is_empty && !$w1_is_empty ) {
        return $_[1];
    }
    else {
        return bless { _is_not_empty => 1, _buf => [ $_[0], 'OR', $_[1] ] }, __PACKAGE__;
    }
  },
  fallback => undef;

has _buf => ( is => 'ro', isa => ArrayRef, required => 1 );
has _is_not_empty => ( is => 'lazy', isa => Bool );

const our $SQL_COMPARISON_OPERATOR => {
    '<'      => '<',
    '<='     => '<=',
    '='      => '=',
    '>='     => '>=',
    '>'      => '>',
    '!='     => '!=',
    'like'   => 'LIKE',
    'in'     => 'IN',
    'not in' => 'NOT IN',

    # TODO not yet supported
    'is null'     => undef,    # 'IS NULL', # automatically use this operator, if value in undef
    'is not null' => undef,    # 'IS NOT NULL',
};

sub _build__is_not_empty ($self) {
    return if !defined $self->{_buf} || !$self->{_buf}->@*;

    for ( $self->{_buf}->@* ) {
        next if !defined;

        # empty HashRef
        next if is_plain_hashref $_ && !keys $_->%*;

        return 1;
    }

    return;
}

sub get_query ( $self, $dbh, $final, $i ) {
    my ( @sql, @bind );

    for my $token ( $self->{_buf}->@* ) {

        # skip undefined values
        next if !defined $token;

        # Scalar value is processed as SQL
        if ( !is_ref $token ) {
            push @sql, $token;
        }

        # ScalarRef value is processed as parameter
        elsif ( is_plain_scalarref $token) {
            push @sql, '$' . $i->$*++;

            push @bind, $token->$*;
        }

        # ArrayRef value is processed as parameter with type
        elsif ( is_arrayref $token) {
            push @sql, '$' . $i->$*++;

            push @bind, $token;
        }

        # HashRef value
        elsif ( is_plain_hashref $token) {
            my @buf;

            for my $field ( keys $token->%* ) {

                # quote field name
                my $quoted_field = $dbh->quote_id($field);

                # Scalar and blessed ArrayRef value is processed as parameter
                if ( !is_ref $token->{$field} || is_blessed_arrayref $token->{$field} ) {
                    push @buf, $quoted_field . ' = $' . $i->$*++;

                    push @bind, $token->{$field};
                }

                # Object is expanded to SQL
                elsif ( is_blessed_hashref $token->{$field} ) {
                    my ( $sql, $bind ) = $token->{$field}->get_query( $dbh, 0, $i );

                    if ( defined $sql ) {
                        push @buf, "$quoted_field = $sql";

                        push @bind, $bind->@* if defined $bind;
                    }
                }

                # plain ArrayRef value is processed as [ $operator, $parameter ]
                elsif ( is_plain_arrayref $token->{$field} ) {
                    my ( $op, $val );

                    if ( $token->{$field}->@* == 1 ) {
                        $op = '=';

                        \$val = \$token->{$field}->[0];
                    }
                    else {

                        # validate operator
                        $op = $token->{$field}->@* == 1 ? '=' : $SQL_COMPARISON_OPERATOR->{ lc $token->{$field}->[0] } or die qq[SQL opertaor "$token->{$field}->[0]" is not allowed];

                        \$val = \$token->{$field}->[1];
                    }

                    if ( $op eq 'IN' ) {
                        my $in = Pcore::Handle::DBI::Const::IN($val);

                        my ( $in_sql, $in_bind ) = $in->get_query( $dbh, $final, $i );

                        if ($in_sql) {
                            push @buf, "$quoted_field $in_sql";

                            push @bind, $in_bind->@*;
                        }
                    }

                    elsif ( $op eq 'NOT IN' ) {
                        my $in = Pcore::Handle::DBI::Const::IN($val);

                        my ( $in_sql, $in_bind ) = $in->get_query( $dbh, $final, $i );

                        if ($in_sql) {
                            push @buf, "$quoted_field NOT $in_sql";

                            push @bind, $in_bind->@*;
                        }
                    }

                    # expand value
                    elsif ( !is_ref $val || is_arrayref $val) {
                        push @buf, "$quoted_field $op \$" . $i->$*++;

                        push @bind, $val;
                    }

                    # object
                    elsif ( is_blessed_hashref $val) {
                        my ( $sql, $bind ) = $val->get_query( $dbh, 0, $i );

                        if ( defined $sql ) {
                            push @buf, "$quoted_field $op $sql";

                            push @bind, $bind->@* if defined $bind;
                        }
                        else {
                            die 'Invalid SQL syntax';
                        }
                    }
                    else {
                        die 'Unsupported ref type';
                    }
                }
                else {
                    die 'Unsupported ref type';
                }
            }

            push @sql, '(' . join( ' AND ', @buf ) . ')' if @buf;
        }

        # Object
        elsif ( is_blessed_hashref $token) {
            my ( $sql, $bind ) = $token->get_query( $dbh, 0, $i );

            if ( defined $sql ) {
                push @sql, $sql;

                push @bind, $bind->@* if defined $bind;
            }
        }
        else {
            die 'Unsupported ref type';
        }
    }

    if (@sql) {
        return ( $final ? 'WHERE (' : '(' ) . join( q[ ], @sql ) . ')', \@bind;
    }
    else {
        return;
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 77                   | Subroutines::ProhibitExcessComplexity - Subroutine "get_query" with high complexity score (38)                 |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 153, 165, 183        | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI::Query::WHERE

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
