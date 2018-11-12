package Pcore::Handle::DBI::Query::OFFSET;

use Pcore -class;
use Pcore::Util::Scalar qw[is_ref is_plain_scalarref];

has _buf => ( required => 1 );    # ArrayRef

sub get_query ( $self, $dbh, $final, $i ) {
    my @bind;

    if ( defined $self->{_buf} ) {

        # Scalar value is processed as parameter
        if ( !is_ref $self->{_buf} ) {
            push @bind, $self->{_buf};
        }

        # ScalarRef value is processed as parameter
        elsif ( !is_plain_scalarref $self->{_buf} ) {
            push @bind, $self->{_buf}->$* if defined $self->{_buf}->$*;
        }

        else {
            die 'Unsupported ref type';
        }
    }

    return @bind ? ( 'OFFSET $' . $i->$*++, \@bind ) : ( undef, undef );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI::Query::OFFSET

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
