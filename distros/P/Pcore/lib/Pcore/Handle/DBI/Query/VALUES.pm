package Pcore::Handle::DBI::Query::VALUES;

use Pcore -class, -const, -export;
use Pcore::Util::Scalar qw[is_ref is_bool is_plain_scalarref is_arrayref is_plain_arrayref is_plain_hashref is_blessed_hashref];

has _buf => ( required => 1 );    # ArrayRef

our $EXPORT = [qw[$SQL_VALUES_IDX_FIRST $SQL_VALUES_IDX_SCAN]];

# default behavior - get index from the first non-empty hash
const our $SQL_VALUES_IDX_FIRST => 1;    # treat first row as columns index, index row will be ignored
const our $SQL_VALUES_IDX_SCAN  => 2;    # full scan rows keys

sub GET_SQL_QUERY ( $self, $dbh, $i ) {
    my ( @sql, @idx, @bind, $ignore_idx );

    # create columns idx
    if ( !is_ref $self->{_buf}->[0] ) {
        if ( $self->{_buf}->[0] == $SQL_VALUES_IDX_FIRST ) {
            $ignore_idx = 2;

            if ( is_plain_hashref $self->{_buf}->[1] ) {
                @idx = sort keys $self->{_buf}->[1]->%*;
            }
            elsif ( is_plain_arrayref $self->{_buf}->[1] ) {
                @idx = $self->{_buf}->[1]->@*;
            }
            else {
                die;
            }
        }
        elsif ( $self->{_buf}->[0] == $SQL_VALUES_IDX_SCAN ) {
            $ignore_idx = 1;

            my $idx;

            for my $token ( $self->{_buf}->@* ) {

                # get hash with keys
                next if !is_plain_hashref $token || !$token->%*;

                $idx->@{ keys $token->%* } = ();
            }

            @idx = sort keys $idx->%*;
        }
        else {
            die;
        }

        die if !@idx;
    }

    for my $token ( $self->{_buf}->@* ) {
        next if $ignore_idx && $ignore_idx--;

        # skip undefined values
        next if !defined $token;

        # HashRef prosessed as values set
        if ( is_plain_hashref $token) {

            # create columns index
            if ( !@idx ) {
                for my $token ( $self->{_buf}->@* ) {

                    # get hash with keys
                    next if !is_plain_hashref $token || !$token->%*;

                    @idx = sort keys $token->%*;

                    last;
                }

                die q[unable to build columns index] if !@idx;
            }

            my @row;

            for my $field (@idx) {

                # Scalar or blessed ArrayRef value is processed as parameter
                if ( !is_ref $token->{$field} || is_arrayref $token->{$field} ) {
                    push @row, '$' . $i->$*++;

                    push @bind, $token->{$field};
                }

                # known boolean objects
                elsif ( is_bool $token->{$field} ) {
                    push @row, '$' . $i->$*++;

                    push @bind, $token->{$field};
                }

                # object
                elsif ( is_blessed_hashref $token->{$field} ) {
                    my ( $sql, $bind ) = $token->{$field}->GET_SQL_QUERY( $dbh, $i );

                    if ($sql) {
                        push @row, $sql;

                        push @bind, $bind->@* if $bind;
                    }
                }
                else {
                    die 'Unsupported ref type';
                }

            }

            push @sql, '(' . join( ', ', @row ) . ')' if @row;
        }

        # ArrayhRef prosessed as values set
        elsif ( is_plain_arrayref $token) {
            my @row;

            for my $field ( $token->@* ) {

                # Scalar or ArrayRef value is processed as parameter
                if ( !is_ref $field || is_arrayref $field ) {
                    push @row, '$' . $i->$*++;

                    push @bind, $field;
                }

                # known boolean objects
                elsif ( is_bool $field ) {
                    push @row, '$' . $i->$*++;

                    push @bind, $field;
                }

                # object
                elsif ( is_blessed_hashref $field ) {
                    my ( $sql, $bind ) = $field->GET_SQL_QUERY( $dbh, $i );

                    if ($sql) {
                        push @row, $sql;

                        push @bind, $bind->@* if $bind;
                    }
                }
                else {
                    die 'Unsupported ref type';
                }

            }

            push @sql, '(' . join( ', ', @row ) . ')' if @row;
        }
        else {
            die 'Unsupported ref type';
        }
    }

    if (@idx) {
        return '(' . join( ', ', map { $dbh->quote_id($_) } @idx ) . ') VALUES ' . join( ', ', @sql ), \@bind;
    }
    else {
        return 'VALUES ' . join( ', ', @sql ), \@bind;
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 14                   | Subroutines::ProhibitExcessComplexity - Subroutine "GET_SQL_QUERY" with high complexity score (44)             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI::Query::VALUES

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
