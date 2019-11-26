package Pcore::App::API::Role::Read;

use Pcore -const, -role, -sql, -res;
use Pcore::Util::Scalar qw[is_ref];

const our $DEFAULT_PAGE_SIZE => 100;

sub _read ( $self, $args, $total_sql, $main_sql, $where, $page_size = $DEFAULT_PAGE_SIZE ) {
    my $dbh = $self->{dbh};

    my $data;

    # get by id
    if ( exists $args->{id} ) {
        $data = $dbh->selectrow( is_ref $main_sql ? $main_sql : [ $main_sql, $where // () ] );
    }

    # get all matched rows
    else {
        my $total = $dbh->selectrow( is_ref $total_sql ? $total_sql : [ $total_sql, $where // () ] );

        # total query error
        if ( !$total ) {
            $data = $total;
        }

        # no results
        elsif ( !$total->{data}->{total} ) {
            $data = res 200,
              total   => 0,
              summary => { total => 0 };
        }

        # has results
        else {
            $args->{start} = 0          if !defined $args->{start} || $args->{start} < 0;
            $args->{limit} = $page_size if !$args->{limit}         || $args->{limit} > $page_size;

            $data = $dbh->selectall( is_ref $main_sql ? $main_sql : [ $main_sql, $where // (), ORDER_BY $args->{sort}, LIMIT $args->{limit}, OFFSET $args->{start} ] );

            if ($data) {
                $data->{total}   = $total->{data}->{total};
                $data->{summary} = $total->{data};
            }
        }
    }

    return $data;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 8                    | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 8                    | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_read' declared but not used        |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Role::Read

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
