package Pcore::Handle::DBI::Query::SQL;

use Pcore -class;
use Pcore::Util::Scalar qw[is_ref is_plain_scalarref is_arrayref is_blessed_hashref];

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
            if ( defined $i ) {
                push @sql, '$' . $i->$*++;

                push @bind, $token->$*;
            }
            else {
                push @sql, $dbh->quote( $token->$* );
            }
        }

        # ArrayRef value is processed as parameter with type
        elsif ( is_arrayref $token ) {
            if ( defined $i ) {
                push @sql, '$' . $i->$*++;

                push @bind, $token;
            }
            else {
                push @sql, $dbh->quote($token);
            }
        }

        # object
        elsif ( is_blessed_hashref $token ) {
            my ( $sql, $bind ) = $token->GET_SQL_QUERY( $dbh, $i );

            if ($sql) {
                push @sql, $sql;

                push @bind, $bind->@* if $bind;
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
        return join( $SPACE, @sql ), \@bind;
    }
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI::Query::SQL

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
