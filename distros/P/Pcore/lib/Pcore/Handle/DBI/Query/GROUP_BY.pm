package Pcore::Handle::DBI::Query::GROUP_BY;

use Pcore -const, -class;
use Pcore::Lib::Scalar qw[is_ref];

has _buf => ( required => 1 );    # ArrayRef

sub get_query ( $self, $dbh, $final, $i ) {
    my @sql;

    for my $token ( $self->{_buf}->@* ) {

        # skip undefined values
        next if !defined $token;

        # Scalar value is processed as SQL
        if ( !is_ref $token) {
            push @sql, $dbh->quote_id($token);
        }
        else {
            die 'Unsupported ref type';
        }
    }

    return @sql ? ( 'GROUP BY ' . join( q[, ], @sql ), undef ) : ( undef, undef );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI::Query::GROUP_BY

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
