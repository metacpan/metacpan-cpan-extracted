package <: $module_name ~ "::API::v1::Admin::SystemLog" :>;

use Pcore -const, -class, -sql, -res;
use <: $module_name ~ "::Const qw[:PERMS]" :>;

extends qw[Pcore::App::API::Base];

with qw[Pcore::App::API::Role::Read];

const our $API_NAMESPACE_PERMS => [$PERMS_ADMIN];

sub API_read ( $self, $auth, $args ) {
    state $total_sql = 'SELECT COUNT(*) AS "total" FROM "system_log"';
    state $main_sql  = 'SELECT * FROM "system_log"';

    my $where;

    # get by id
    if ( exists $args->{id} ) {
        $where = WHERE [ '"id" = ', \$args->{id} ];
    }

    # get all matched rows
    else {

        # default sort
        $args->{sort} = [ [ 'created', 'DESC' ] ] if !$args->{sort};

        # filter search
        my $where1 = WHERE do {
            if ( my $search = delete $args->{filter}->{search} ) {
                my $val = "%$search->[1]%";

                [ '"title" ILIKE', \$val ];
            }
            else {
                undef;
            }
        };

        $where = $where1 & WHERE [ $args->{filter} ];
    }

    return $self->_read( $args, $total_sql, $main_sql, $where, 100 );
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
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1, 4                 | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 63                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 67 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::API::v1::Admin::SystemLog" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
