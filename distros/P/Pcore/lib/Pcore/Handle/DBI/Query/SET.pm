package Pcore::Handle::DBI::Query::SET;

use Pcore -class;
use Pcore::Util::Scalar qw[is_ref is_plain_scalarref is_arrayref is_plain_hashref is_blessed_hashref];

has _buf => ( required => 1 );    # ArrayRef

sub GET_SQL_QUERY ( $self, $dbh, $i ) {
    my ( @sql, @bind );

    for my $token ( $self->{_buf}->@* ) {

        # skip undefined values
        next if !defined $token;

        # Scalar value is processed as SQL
        if ( !is_ref $token ) {
            push @sql, $token;
        }

        # ScalarRef value is processed as parameter
        elsif ( is_plain_scalarref $token ) {
            push @sql, '$' . $i->$*++;

            push @bind, $token->$*;
        }

        # ArrayRef value is processed as parameter with type
        elsif ( is_arrayref $token ) {
            push @sql, '$' . $i->$*++;

            push @bind, $token;
        }

        # HashRf value
        elsif ( is_plain_hashref $token ) {
            my @sql1;

            for my $field ( keys $token->%* ) {

                # Scalar or blessed ArrayRef values are processed as parameters
                if ( !is_ref $token->{$field} || is_arrayref $token->{$field} ) {
                    push @sql1, $dbh->quote_id($field) . ' = $' . $i->$*++;

                    push @bind, $token->{$field};
                }

                # object
                elsif ( is_blessed_hashref $token->{$field} ) {
                    my ( $sql, $bind ) = $token->{$field}->GET_SQL_QUERY( $dbh, $i );

                    if ($sql) {
                        push @sql1, $dbh->quote_id($field) . ' = ' . $sql;

                        push @bind, $bind->@* if $bind;
                    }
                }
                else {
                    die 'Unsupported ref type';
                }
            }

            if (@sql1) {
                $sql[-1] .= ',' if @sql;

                push @sql, join ', ', @sql1;
            }
        }
        else {
            die 'Unsupported ref type';
        }
    }

    if ( !@sql ) {
        return;
    }
    else {
        return 'SET ' . join( $SPACE, @sql ), \@bind;
    }
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI::Query::SET

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
