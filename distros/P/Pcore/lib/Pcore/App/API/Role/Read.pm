package Pcore::App::API::Role::Read;

use Pcore -const, -role, -sql, -res;

const our $DEFAULT_PAGE_SIZE => 100;

sub _read ( $self, $req, $args, $total_sql, $main_sql, $where, $page_size = $DEFAULT_PAGE_SIZE ) {
    my $dbh = $self->{dbh};

    my $data;

    # get by id
    if ( exists $args->{id} ) {
        $data = $dbh->selectrow( [ $main_sql, $where // () ] );
    }

    # get all matched rows
    else {
        $args->{start} = 0          if !defined $args->{start} || $args->{start} < 0;
        $args->{limit} = $page_size if !$args->{limit}         || $args->{limit} > $page_size;

        my $total = $dbh->selectrow( [ $total_sql, $where // () ] );

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
            $data = $dbh->selectall( [ $main_sql, $where // (), ORDER_BY $args->{sort}, LIMIT $args->{limit}, OFFSET $args->{start} ] );

            if ($data) {
                $data->{total}   = $total->{data}->{total};
                $data->{summary} = $total->{data};
            }
        }
    }

    $req->($data);

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 7                    | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 7                    | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_read' declared but not used        |
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
