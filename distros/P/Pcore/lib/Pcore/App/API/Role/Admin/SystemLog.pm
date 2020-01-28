package Pcore::App::API::Role::Admin::SystemLog;

use Pcore -role, -sql;

with qw[Pcore::App::API::Role::Read];

has max_limit        => 100;
has default_order_by => sub { [ [ 'created', 'DESC' ] ] };

sub API_read ( $self, $auth, $args ) {
    my $where = WHERE;

    # get by id
    if ( exists $args->{id} ) {
        $where &= WHERE [ '"id" = ', \$args->{id} ];
    }

    # get all matched rows
    else {

        # filter search
        if ( my $search = delete $args->{where}->{search} ) {
            my $val = "%$search->[1]%";

            $where &= WHERE [ '"title" ILIKE', \$val ];
        }

        $where &= WHERE [ $args->{where} ];
    }

    my $total_query = [ 'SELECT COUNT(*) AS "total" FROM "system_log"', $where ];

    my $main_query = [ 'SELECT * FROM "system_log"', $where ];

    return $self->_read( $total_query, $main_query, $args );
}

sub API_delete ( $self, $auth, $args ) {
    return 400 if !$args->{id};

    state $q1 = $self->{dbh}->prepare('DELETE FROM "system_log" WHERE "id" = ?');

    return $self->{dbh}->do( $q1, [ $args->{id} ] );
}

sub API_delete_all ( $self, $auth ) {
    my $dbh = $self->{dbh};

    return $dbh->do('DELETE FROM "system_log"');
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Role::Admin::SystemLog

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
