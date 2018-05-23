package Pcore::Handle::DBI::Query::IN;

use Pcore -class;
use Pcore::Util::Scalar qw[is_ref is_plain_scalarref is_blessed_arrayref];

has _buf => ();    # ( is => 'ro', isa => ArrayRef, required => 1 );

sub get_query ( $self, $dbh, $final, $i ) {
    my ( @sql, @bind );

    for my $token ( $self->{_buf}->@* ) {

        # Scalar or blessed ArrayRef values are processed as parameters
        if ( !is_ref $token || is_blessed_arrayref $token) {
            push @sql, '$' . $i->$*++;

            push @bind, $token;
        }
        else {
            die 'Unsupported ref type';
        }
    }

    return @sql ? ( 'IN (' . join( q[, ], @sql ) . ')', \@bind ) : ( undef, undef );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI::Query::IN

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
