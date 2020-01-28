package Pcore::Handle::DBI::Query::LIMIT;

use Pcore -class;
use Pcore::Util::Scalar qw[is_ref is_plain_scalarref];

has max     => ();
has default => ();

has _buf => ( required => 1 );    # ArrayRef

sub GET_SQL_QUERY ( $self, $dbh, $i ) {
    my $val;

    if ( defined $self->{_buf} ) {

        # Scalar value is processed as parameter
        if ( !is_ref $self->{_buf} ) {
            $val = $self->{_buf};
        }

        # ScalarRef value is processed as parameter
        elsif ( !is_plain_scalarref $self->{_buf} ) {
            $val = $self->{_buf}->$* if defined $self->{_buf}->$*;
        }

        else {
            die 'Unsupported ref type';
        }
    }

    if ( !$val ) {
        $val = $self->{default} || $self->{max};
    }
    elsif ( my $max = $self->{max} ) {
        $val = $max if $val > $max;
    }

    if ($val) {
        return 'LIMIT $' . $i->$*++, [$val];
    }
    else {
        return;
    }
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI::Query::LIMIT

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
