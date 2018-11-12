package Pcore::Handle::DBI::Query::VALUES;

use Pcore -class;
use Pcore::Util::Scalar qw[is_ref is_plain_scalarref is_arrayref is_plain_arrayref is_plain_hashref is_blessed_hashref];

has _buf => ( required => 1 );    # ArrayRef

sub get_query ( $self, $dbh, $final, $i ) {
    my ( @sql, @idx );

    for my $token ( $self->{_buf}->@* ) {

        # skip undefined values
        next if !defined $token;

        # HashRef prosessed as values set
        if ( is_plain_hashref $token) {
            @idx = sort keys $token->%* if !@idx;

            my @row;

            for my $field (@idx) {

                # Scalar or blessed ArrayRef value is processed as parameter
                if ( !is_ref $token->{$field} || is_arrayref $token->{$field} ) {
                    push @row, $dbh->quote( $token->{$field} );
                }

                # object
                elsif ( is_blessed_hashref $token->{$field} ) {
                    push @row, $token->{$field}->get_quoted($dbh);
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
                    push @row, $dbh->quote($field);
                }

                # object
                elsif ( is_blessed_hashref $field ) {
                    push @row, $field->get_quoted($dbh);
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
        return '(' . join( ', ', map { $dbh->quote_id($_) } @idx ) . ') VALUES ' . join( ', ', @sql ), undef;
    }
    else {
        return 'VALUES ' . join( ', ', @sql ), undef;
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 8                    | Subroutines::ProhibitExcessComplexity - Subroutine "get_query" with high complexity score (21)                 |
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
